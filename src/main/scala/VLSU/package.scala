import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters

package object vlsu {
  /**
   * Meta Control Information Hierarchy:
   *
   * 1. Global Level
   *    - Scope : Full request (single/multi-segment)
   *    - Init  : Receiving a new RIVA request
   *    - Update: Won't update, persists throughout the entire request lifecycle
   *    - Usage : Contains static parameters. The RIVA request is made up of severl segments.
   *
   * 2. Segment Level
   *    - Scope : single/multi-DataSegment caused by a RIVA request
   *    - Init  : Receiving a new RIVA request
   *    - Update: Reinitialized on segment boundary crossing
   *    - Usage : Contains iterable parameters describing the current segment. The data segment is made up of several txns because max txn data=4KB.
   *
   * 3. Transaction Level (TXN)
   *    - Scope : Individual AXI transaction unit within a segment
   *    - Init  : Receiving a new RIVA request OR switching segment
   *    - Update: Finishing ejecting the Txn Info into the txnCtrl.
   *    - Usage : Contains iterable parameters describing the current transaction.
   *
   * Hierarchy Invariant: Global -> Segment -> TXN (top-down initialization)
   */
  class MetaCtrlInfo(implicit p: Parameters) extends VLSUBundle {
    // Global Info of a riva request.
    // Some of them might change between segments in the context of 2D transfers.
    class global(implicit p: Parameters) extends VLSUBundle {
      val reqId  = UInt(reqIdBits.W)
      val mode   = new VecMopOH
      val ew     = UInt(6.W)                   // element Width = 4/8/16/32 TODO: 可能单位不需要是bits
      val stride = UInt(32.W)
      val sglen  = UInt(log2Ceil(maxSegLen).W) // It is insufficient to solely save 'illuSglenB' at this point, as 'illuSglenB' may vary across different segments in the context of 2D transfers.
      val vstart = UInt(log2Ceil(VLEN).W)

      def init(req: RivaReqPtl, valid: Bool): Unit = {
        this.reqId  := req.reqId
        this.mode.decode(req, valid)
        this.ew     := req.getEW
        this.stride := req.stride
        this.sglen  := req.sglen
        this.vstart := req.vstart

        when (valid) {
          // Addr is always aligned when EW = 4/8 bits.
          when ((this.ew >> 4).asUInt.orR) {assert(!(req.baseAddr & ((1.U << (this.ew >> 4).asUInt).asUInt - 1.U)).orR, "Base addr of riva_req need to be aligned with EW!" )}
        }
      }
    }
    class segmental(implicit p: Parameters) extends VLSUBundle {
      val rmnSgm   = UInt(tilenBits.W) // Remain segment TODO: width of tilen?
      val illuHead = Bool()    // illu: illusion
      val illuTail = Bool()
      val isHead   = Bool()

      def init(req: RivaReqPtl, glob: global, valid: Bool): Unit = {
        this.rmnSgm   := req.tilen
        this.illuHead := req.vstart(0) && glob.ew(2)                   // Head is illusory when vstart is odd.
        this.illuTail := (req.vstart(0) ^ !req.sglen(0)) && glob.ew(2) // Tail is illusory when one of vstart and sglen is odd. '!req.sglen(0)' because the actual sglen is sglen + 1. '&& glob.ew(2)' means ew is 4 bits.
        this.isHead   := true.B
      }

      def isLast: Bool = !this.rmnSgm.orR
    }

    class transactional(implicit p: Parameters) extends VLSUBundle {
      val addr     = UInt(axi4Params.addrBits.W)
      val rmnTxn   = UInt(log2Ceil(maxTxnPerReq).W)
      val ltB      = UInt(12.W) // lastTxnBytes
      val isHead   = Bool()

      def init(req: RivaReqPtl, glob: global, segm: segmental, valid: Bool): Unit = {
        // EW=4 bits may cause the AXI interface to perceive 4-8 bits more valid data than the actual amount.
        // We refer to this phenomenon as an 'illusion'. As a result, we call the vlenB here an 'illuSglenB'.
        val illuSglenB = Wire(UInt((log2Ceil(VLEN/8)+1).W))
        val offset     = Wire(UInt(12.W))

        // TODO: different logic when segment is not Head.
        this.addr   := req.baseAddr + (glob.vstart << glob.ew(5, 3)).asUInt >> 1 // NOTE: If vstart is odd and EW = 4 bits, the calculated addr will be 4 bits smaller than the actual starting address.

        // intermediate variables
        illuSglenB  := ((glob.sglen + 1.U) << glob.ew(5, 3) >> 1).asUInt + segm.illuTail
        offset      := this.addr(11, 0)
        val allBytes = offset + illuSglenB

        // TODO: consider other modes
        this.rmnTxn   := allBytes >> 12
        this.ltB      := allBytes(11, 0)

        this.isHead   := true.B

        dontTouch(illuSglenB)
        dontTouch(offset)
        dontTouch(allBytes) // TODO: 看一看这个信号的位宽
      }

      // Only updates in the same segment will call this function.
      def update(r: MetaCtrlInfo): Unit = {
        this.addr   := ((r.txn.addr >> 12).asUInt + 1.U) << 12 // addr_nxt is always the start addr of next page.
        this.rmnTxn := r.txn.rmnTxn - 1.U
        this.isHead := false.B
        assert(!r.txn.isLast, "Should not update when current txn is already the last txn in this segment!")
      }

      def isLast: Bool = !this.rmnTxn.orR
    }

    val glb = new global()
    val sgm = new segmental()
    val txn = new transactional()

    def init(req: RivaReqPtl, valid: Bool): Unit = {
      this.glb.init(req, valid)
      this.sgm.init(req, this.glb, valid)
      this.txn.init(req, this.glb, this.sgm, valid)
    }

    def update(r: MetaCtrlInfo): Unit = {
      // TODO: 更新时只需要更新sgm和txn即可，glb一直保持不变，所以不需要额外的写入逻辑
      when(r.isLast) {
        this := 0.U.asTypeOf(this) // Already the last beat of rivaReq, clear 'this'.
      }.elsewhen(r.txn.isLast) {
        // 2D transfer control logic:
        // Current data segment's last beat, prepare for next segment (current segment is NOT the last segment).
        // TODO： 此处segment update，txn会init（需要修改init函数）
        this := r
      }.otherwise {
        // Not the last and txn:
        // iteration in a segment (applicable for iteration in segments of 1D and 2D reqs).
        this := r
        this.txn.update(r)
      }
    }

    def is4Bits: Bool = this.glb.ew(2)

    def isLast: Bool = this.sgm.isLast && this.txn.isLast
  }

  /** AXI Control Information (AxiCtrlInfo)
   *
   *  This class stores and manages information related to an AXI transaction.
   *  It includes the transaction address, size, remaining beats, and other relevant attributes.
   *  The class also provides methods to initialize and update transaction information.
   *
   *  Fields:
   *  @param addr    The starting address of the current AXI transaction.
   *  @param size    The size of the transaction in bytes, typically equal to the AXI bus width.
   *  @param rmnBeat The remaining beats (data bursts) in the current transaction.
   *  @param lbB     The number of valid bytes in the last beat of the transaction.
   *  @param isHead  Indicates whether this is the first transaction in a request sequence.
   */
  class AxiCtrlInfo(implicit p: Parameters) extends VLSUBundle {
    val addr    = UInt(axi4Params.addrBits.W)
    val size    = UInt(3.W)
    val rmnBeat = UInt(8.W)
    val lbB     = UInt(log2Ceil(busBytes).W)
    val isHead  = Bool()

    def init(meta: MetaCtrlInfo): Unit = {
      this := 0.U.asTypeOf(this)

      val offset = meta.txn.addr(11, 0)
      this.addr   := meta.txn.addr
      this.isHead := true.B

      when (meta.glb.mode.isIncr) {
        // aligned Last Txn Bytes takes offset into consideration
        val busOffset       = meta.txn.addr(busSize - 1, 0)
        this.size          := busSize.U

        when (meta.txn.isLast) {
          // The current transaction (Txn) is the last one, so 'txn.lastTxnBytes' must be considered.
          // Additionally, to handle cases where the request results in only one AX transaction, we include 'busOffset'.
          val alnLastTxnBytes = busOffset + meta.txn.ltB

          // Calculate the remaining beats for this transaction.
          this.rmnBeat       := alnLastTxnBytes >> busSize
          // Determine the byte count for the last beat.
          this.lbB := alnLastTxnBytes(busSize - 1, 0)
        }.otherwise {
          // The current transaction is not the last one.
          // It might be the first transaction in the sequence, so 'offset' must be considered.
          // For middle transactions, 'offset' is zero, ensuring correctness.
          this.rmnBeat       := ((4096 / busBytes).U - (offset >> busSize).asUInt) - 1.U

          // Due to the 4KB page boundary restriction, the first AX transaction may contain only one beat (initial length = 0).
          // In this case, 'lastBeatBytes' should subtract 'busOffset'.
          // Otherwise, for non-final transactions, 'lastBeatBytes' remains constant.
          this.lbB := Mux(this.isLast, busBytes.U - busOffset - 1.U, (busBytes - 1).U)
        }
      }
    }

    def update(r: AxiCtrlInfo): Unit = {
      this := r
      this.rmnBeat       := r.rmnBeat - 1.U
      this.isHead        := false.B
    }

    def isLast: Bool = !this.rmnBeat.orR
  }

}