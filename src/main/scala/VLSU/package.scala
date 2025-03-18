import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters

package object vlsu {
  /** BaseCtrlInfo refers to the information that is initialized upon the arrival of a request.
   ** Most of them remains unchanged throughout the entire request processing cycle.
   */
  class BaseCtrlInfo(implicit p: Parameters) extends VLSUBundle {
    val mode  = new VecMopOH
    val reqId = UInt(1.W)                       // TODO: width?
    val ew    = UInt(6.W)                       // element Width = 4/8/16/32 TODO: 可能单位不需要是bits
    val csr   = new CsrBundle                   // csr info should be saved TODO: maybe can be saved separately
    val vlenB = UInt(log2Ceil(maxDataBytes).W)  // The total number of bytes occupied by 'vlen' elements with a width of EW.
    val tilen = UInt(log2Ceil(VLEN).W)          // width of tilen?

    def is4Bits: Bool = this.ew(2)

    def init(req: RivaReq, csr: CsrBundle, valid: Bool): Unit = {
      this.mode.decode(req, valid)
      this.reqId := req.base.id
      this.ew    := req.base.getEW
      this.csr   := csr
      this.vlenB := ((csr.vlen + 1.U) << this.ew(5, 3)) >> 1
      this.tilen := csr.tilen

      when (valid) {
        assert(csr.vstart === 0.U, "We currently don't support vstart > 0!") // TODO: support it.
  
        when ((this.ew >> 4).asUInt.orR) {
          assert(!(req.base.baseAddr & ((1.U << (this.ew >> 3).asUInt).asUInt - 1.U)).orR, "Base addr of riva_req need to be aligned!" )
        }
      }
    }
  }

  class TxnCtrlInfo(implicit p: Parameters) extends VLSUBundle {
    val addr         = UInt(axi4Params.addrBits.W)     // Starts with the base address and increments each time an AXI request is allocated.
    val rmnTxn       = UInt(log2Ceil(maxTxnPerReq).W)  // rmnTxn is the number of remaining Ax txn caused by a memory access.
    val lastTxnBytes = UInt(log2Ceil(axi4Params.maxTxnBytes).W)
    val isHead       = Bool()     // TODO: useless?

    def init(req: RivaReq, base: BaseCtrlInfo): Unit = {
      val offset = req.base.baseAddr(11, 0) // TODO: take vstart into consideration

      this.addr   := req.base.baseAddr
      this.isHead := true.B

      when (base.mode.isIncr) {
        val allBytes = base.vlenB + offset + base.is4Bits // This is actually the offset of end addr.
        dontTouch(allBytes) // TODO: 看一看这个信号的位宽

        // The calculation of rmnTxn has already taken 4KB (Page size) into consideration.
        this.rmnTxn := allBytes >> 12
        this.lastTxnBytes := allBytes(11, 0)
      }
      // TODO: other modes
      .otherwise {
        this.rmnTxn := 0.U
        this.lastTxnBytes := 0.U
      }
    }

    def update(r: TxnCtrlInfo): Unit = {
      this.addr         := ((r.addr >> 12).asUInt + 1.U) << 12
      this.rmnTxn       := r.rmnTxn - 1.U
      this.lastTxnBytes := r.lastTxnBytes
      this.isHead       := false.B
    }

    def isLast: Bool = !this.rmnTxn.orR
  }

  class DataCtrlInfo(implicit p: Parameters) extends VLSUBundle {
    val addr          = UInt(axi4Params.addrBits.W)
    val size          = UInt(3.W)
    val rmnBeat       = UInt(8.W)
    val lastBeatBytes = UInt(log2Ceil(busBytes).W)
    val isHead        = Bool()

    def init(base: BaseCtrlInfo, txn: TxnCtrlInfo): Unit = {
      val offset = txn.addr(11, 0)

      this.addr   := txn.addr
      this.isHead := true.B

      when (base.mode.isIncr) {
        // aligned Last Txn Bytes takes offset into consideration
        val busOffset       = txn.addr(busSize - 1, 0)
        this.size          := busSize.U

        when (txn.isLast) {
          // The current transaction (Txn) is the last one, so 'txn.lastTxnBytes' must be considered.
          // Additionally, to handle cases where the request results in only one AX transaction, we include 'busOffset'.
          val alnLastTxnBytes = busOffset + txn.lastTxnBytes

          // Calculate the remaining beats for this transaction.
          this.rmnBeat       := alnLastTxnBytes >> busSize
          // Determine the byte count for the last beat.
          this.lastBeatBytes := alnLastTxnBytes(busSize - 1, 0)
        }.otherwise {
          // The current transaction is not the last one.
          // It might be the first transaction in the sequence, so 'offset' must be considered.
          // For middle transactions, 'offset' is zero, ensuring correctness.
          this.rmnBeat       := ((4096 / busBytes).U - (offset >> busSize).asUInt) - 1.U

          // Due to the 4KB page boundary restriction, the first AX transaction may contain only one beat (initial length = 0).
          // In this case, 'lastBeatBytes' should subtract 'busOffset'.
          // Otherwise, for non-final transactions, 'lastBeatBytes' remains constant.
          this.lastBeatBytes := Mux(this.isLast, busBytes.U - busOffset - 1.U, (busBytes - 1).U)
        }
      }
    }

    def update(r: DataCtrlInfo): Unit = {
      this.addr          := r.addr  // TODO: maybe need to be iterated.
      this.size          := r.size
      this.rmnBeat       := r.rmnBeat - 1.U
      this.lastBeatBytes := r.lastBeatBytes
      this.isHead        := false.B
    }

    def isLast: Bool = !this.rmnBeat.orR
  }

  /** 'CtrlInfo' represents a bundle containing the necessary INFORMATION for handling the iteration of an entire memory access request.
   *
   * The infos are UInt.
   */
  class CtrlInfo(implicit p: Parameters) extends VLSUBundle {
    val base   = new BaseCtrlInfo
    val txn    = new TxnCtrlInfo
    val data   = new DataCtrlInfo

    // When the request fire, the request will be decoded and saved as CtrlInfo.
    def init(req: RivaReq, csr: CsrBundle, valid: Bool): Unit = {
      this.base.init(req, csr, valid)
      this.txn.init(req, this.base)
      this.data := 0.U.asTypeOf(this.data) // data info will be initialized next cycle
    }
  }

  /** Due to the complexity of VLSU's state transitions, the CM does not employ a traditional FSM (Finite State Machine) design.
   **  Instead, it utilizes a design similar to an 'operation set' or 'micro-operations.'
   **  The STATEs here represents the state of this CM, and they are of the Bool type.
   */
  class CtrlState(implicit p: Parameters) extends VLSUBundle {
    val todo = Bool()

    private def initLoad(): Unit = {

    }

    private def initStore(): Unit = {

    }
    
    def init(req: RivaReq): Unit = {
      when(req.base.isLoad) {
        this.initLoad()
      }.otherwise {
        this.initStore()
      }
    }
  }

  class CtrlPayload(implicit p: Parameters) extends VLSUBundle {
    val info  = new CtrlInfo
    val state = new CtrlState
    val cnt   = UInt(log2Ceil(maxTxnPerReq).W) // Whenever the cm's states are fully completed, the counter is decremented. When cnt = 0, it indicates that the memory access request has been completed.

    // when 'valid', all assertions are enabled.
    def init(req: RivaReq, csr: CsrBundle, valid: Bool): Unit = {
      this.info.init(req, csr, valid)
    }

  }

}