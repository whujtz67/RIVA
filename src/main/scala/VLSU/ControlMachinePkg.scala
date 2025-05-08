package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters

// The global information is decoded from the RIVA Req.
// Most of the vals remain unchanged throughout the request process.
class global(implicit p: Parameters) extends VLSUBundle {
  val reqId    = UInt(reqIdBits.W)
  val mode     = new VecMopOH()
  val baseAddr = UInt(axi4Params.addrBits.W)
  val vd       = UInt(5.W)
  val eew      = UInt(2.W) // The element width is encoded as 2-bit binary value: 00 01 10 11
  val EW       = UInt(6.W) // Original element width:                              4  8 16 32
  val stride   = UInt(axi4Params.addrBits.W)
  val vm       = Bool()
  val nrClns   = UInt(log2Ceil(maxNrElems).W) // Number of column, which is the element number in a row (won't '-1' like axi len)
  val vstart   = UInt(log2Ceil(maxNrElems).W) // The start element index in the request.
  val rmnGrp   = UInt(log2Ceil(maxNrElems*EWs.max/SLEN).W) // Txn will be divided into several groups in 2D cln mode, otherwise rmnGrp = 0
  val rmnRow   = UInt(log2Ceil(maxNrElems).W) // Remain row number (remain -> rmn)
  // 'CmtCnt' represents the number of times shfBuf is committed to either the lane or seqBuf,
  // calculated by dividing the total data volume of the current request by NrLanes * SLEN.
  // 'CmtCnt' is used to decide when to deq metaBuf.
  // 'CmtCnt' is the actual count - 1 (just like axi len)
  // maxCmtCnt = maxDataPerReq / (SLEN * NrLanes) = (VLEN * maxEW * NrLanes(2D Row)) / (SLEN * NrLanes) = VLEN * maxEW / SLEN
  val cmtCnt = UInt(log2Ceil(maxNrElems*EWs.max/SLEN).W)

  def init(req: RivaReqPtl): Unit = {
    val elemNum = req.len - req.vstart

    this.reqId    := req.reqId
    this.mode     := (1.U << req.mop).asTypeOf(this.mode)
    this.baseAddr := req.baseAddr
    this.eew      := req.eew
    this.EW       := req.getEW
    this.vm       := req.vm
    this.stride   := req.stride
    this.nrClns   := PriorityMux(Seq( // wont '-1'
      this.mode.Incr  -> elemNum,
      this.mode.Strd  -> 1.U,
      this.mode.row2D -> NrLanes.U,
      this.mode.cln2D -> ((SLEN / 4).U >> req.eew) // 'nrClns' is used to determine the txnNum in a row, so that it should not be 'req.len' in 2D cln mode.
    ))
    this.vstart  := req.vstart
    this.rmnGrp  := Mux(this.mode.cln2D, (req.len - 1.U) << req.eew >> log2Ceil(SLEN/4), 0.U) // Use '(req.len - 1.U)' instead of '(req.len << req.eew) - 1.U' to reduce the bits of subtractor.
    this.rmnRow  := PriorityMux(Seq(  // do '-1'
      this.mode.Incr  -> 0.U,
      this.mode.Strd  -> (elemNum - 1.U),
      this.mode.row2D -> (req.len - 1.U),
      this.mode.cln2D -> (NrLanes - 1).U
    ))

    // The cmtCnt can also be obtained using nrCln * rmnRow * EW / (NrLanes * SLEN),
    // but that would result in a 14-bit multiplier, which is too costly.
    this.cmtCnt := PriorityMux(Seq(  // do '-1'
      (this.mode.Incr || this.mode.Strd) -> ((elemNum << (this.eew + 2.U))),
      this.mode.row2D -> ((req.len << log2Ceil(NrLanes) << (this.eew + 2.U))),
      this.mode.cln2D -> (req.len << log2Ceil(NrLanes))
    )) >> log2Ceil(NrLanes * SLEN)

    val LOG2_MAX_SEW_BYTE = log2Ceil(EWs.max / 8)
    assert(req.len > req.vstart, "vlen/alen must > vstart. Otherwise, the request is meaningless")
    assert(!(req.baseAddr(LOG2_MAX_SEW_BYTE - 1, 0) & Mux(this.eew(1), Mux(this.eew(0), 3.U, 1.U), 0.U)).orR, "baseAddr should be aligned to EW!")
  }

  // Update when Row Finish
  def update(r: global): Unit = {
    this := r

    when(r.isLastRow) {
      // ONLY 2D cln will cause more than 1 groups.
      // There is no need to include '&& !r.isLastGrp' here, because we do not perform an update when reqIssueDone is triggered.
      // Therefore, by the time execution reaches this point, r.isLastGrp is implicitly false.
      when(r.mode.cln2D) {
        this.baseAddr := r.baseAddr + 16.U // TODO: 这边是不对非对齐传输作特殊处理的，如果128 bits跨了总线地址边界，会被拆成2拍，可能会导致一些性能的损失
        this.rmnRow   := (NrLanes - 1).U // Re-initialize rmnRow. It is quit easy here because only cln2D will cause several grps.
        this.rmnGrp   := r.rmnGrp - 1.U
      }
    }.otherwise {
      this.rmnRow := r.rmnRow - 1.U
    }
  }

  def isLastRow: Bool = !this.rmnRow.orR

  def isLastGrp: Bool = !this.rmnGrp.orR
}

class rowLevel(implicit p: Parameters) extends VLSUBundle {
  val rowBaseAddr = UInt(axi4Params.addrBits.W)
  val illuHead    = Bool()
  val illuTail    = Bool()
  val txnNum      = UInt(log2Ceil(maxNrElems*EWs.max/8/4096 + 1).W) // +1 for unaligned situations
  val txnCnt      = UInt(log2Ceil(maxNrElems*EWs.max/8/4096 + 1).W)
  val ltB         = UInt(12.W) // last Txn Bytes

  /*** Initialize the row Level info.
   *
   * @param glb_r The row level info is initialized the next cycle of the global info initialization.
   *              As a result, the input global info should be glb_r.
   * @param valid
   */
  def init(glb_r: global): Unit = {
    this.rowBaseAddr := PriorityMux(Seq(
      glb_r.mode.Incr -> (glb_r.baseAddr + (glb_r.vstart << glb_r.eew).asUInt >> 1),
      glb_r.mode.Strd -> (glb_r.baseAddr + (glb_r.vstart >> 1).asUInt * glb_r.stride + Mux(glb_r.vstart(0), (glb_r.stride >> 1).asUInt, 0.U)), // This section involves adders and multipliers, TIMING crucial
      glb_r.mode.is2D -> glb_r.baseAddr  // We don't take vstart into consideration in 2D modes at present.
    ))
    this.illuHead := PriorityMux(Seq(
      glb_r.mode.Incr -> (glb_r.vstart(0) && !glb_r.eew.orR),
      glb_r.mode.Strd -> (glb_r.vstart(0) && glb_r.stride(0)), // the unit of stride is half bytes, so we don't need to take EW into consideration.
      glb_r.mode.is2D -> false.B  // We don't take vstart into consideration in 2D modes at present.
    ))
    this.illuTail := Mux(!glb_r.eew.orR, this.illuHead ^ glb_r.nrClns(0), this.illuHead)  // = this.illuHead ^ (glb_r.nrClns(0) && glb_r.EW(2))

    val offset   = this.rowBaseAddr(11, 0)
    val allBytes = (glb_r.nrClns << glb_r.eew >> 1).asUInt + (this.illuTail || this.illuHead) + offset // TODO: maybe put into the next cycle to avoid long timing path?

    this.txnNum := allBytes >> 12
    this.txnCnt := 0.U
    this.ltB    := allBytes(11, 0)
  }

  /*** switch between groups
   *
   * @note Only 2D cln mode will lead to several groups.
   */
  def switchGrpInit(glb_nxt: global): Unit = {
    this.rowBaseAddr := glb_nxt.baseAddr
    this.illuHead    := false.B  // always false when switching group
    this.illuTail    := false.B  // always false because nrCln is always even in this case

    val offset   = this.rowBaseAddr(11, 0)
    val allBytes = (glb_nxt.nrClns << glb_nxt.eew >> 1).asUInt + (this.illuTail || this.illuHead) + offset

    this.txnNum := allBytes >> 12
    this.txnCnt := 0.U
    this.ltB    := allBytes(11, 0) // Since "pageOff_without_busOff" will be subtracted later, we can assign the value like this.
  }


  /*** switch between different rows in the SAME group.
   *
   * @note Only Stride and 2D mode will lead to row switch.
   */
  def switchRowInit(r: rowLevel, glb_r: global): Unit = {
    this.rowBaseAddr := r.rowBaseAddr + (glb_r.stride >> 1).asUInt + r.illuHead.asUInt
    this.illuHead    := r.illuHead ^ glb_r.stride(0)
    this.illuTail    := Mux(!glb_r.eew.orR, this.illuHead ^ glb_r.nrClns(0), this.illuHead)

    val offset   = this.rowBaseAddr(11, 0)
    val rowBytes = (glb_r.nrClns << glb_r.eew >> 1).asUInt + (this.illuTail || this.illuHead).asUInt
    val allBytes = rowBytes + offset

    this.txnNum := allBytes >> 12
    this.txnCnt := 0.U
    this.ltB    := allBytes(11, 0) // Since "pageOff_without_busOff" will be subtracted later, we can assign the value like this.
  }

  // update in row
  def update(r: rowLevel) = {
    this.txnCnt := r.txnCnt + 1.U
  }

  // isHead txn, not head row!!!
  def isHeadTxn: Bool = !this.txnCnt.orR

  def isLastTxn: Bool = this.txnCnt === this.txnNum
}

class MetaCtrlInfo(implicit p: Parameters) extends VLSUBundle {
  // ---------------------------------------------------- MetaCtrlInfo Fields ---------------------------------------------------- //
  val glb = new global()
  val row = new rowLevel()

  // ---------------------------------------------------- MetaCtrlInfo Functions ---------------------------------------------------- //

  /*** The 'resolve' function is active during the 'FRAGMENTING' state of the 'ReqFragmenter'.
   *   While in the FRAGMENTING state, it executes every cycle.
   *   The function checks the 'doUpdate' signal to determine whether to update the meta information
   *   and then assesses the state of meta_r to decide how to perform the update.
   *
   * @param r The MetaCtrlInfo stored in a register.
   * @param doUpdate Update the MetaCtrlInfo every time a set of information is injected into the TxnCtrlUnit.
   */
  def resolve(r: MetaCtrlInfo, doUpdate: Bool): Unit = {
    // default connection
    this := r

    // When 'reqIssueDone' is triggered alongside 'doUpdate',
    // it signifies that the last Txn of the request has been fully issued,
    // meaning the entire request has entered the processing pipeline.
    //
    // NOTE: The register storing 'MetaCtrlInfo' for this request MUST NOT be released immediately.
    // It should remain active until the completion of the final data transfer cycle before being deallocated.
    when(doUpdate && !r.isFinalTxn) {
      when (r.row.isLastTxn) {
        // update global info (isLastRow and isLastGrp is already considered in glb.update)
        this.glb.update(r.glb)

        // update row Level info (switch row / group)
        when(r.glb.isLastRow) { // Last Row but not the last group, switch GROUP
          this.row.switchGrpInit(this.glb)
        }.otherwise {           // Not the last row, switch ROW
          this.row.switchRowInit(r.row, this.glb)
        }
      }
      this.row.update(r.row)
    }
  }

  /*** The isFinalTxn signal indicates that the Txn currently being issued is the final one of the entire request.
   *
   * @note The ReqFragmenter will be released after reqIssueDone. However, it DOES NOT indicates that the request is all Done.
   */
  def isFinalTxn: Bool = this.glb.isLastGrp && this.glb.isLastRow && this.row.isLastTxn

}

/** Transaction control info saved in TxnCtrlUnit
 *
 * TxnCtrlInfo is derived from MetaCtrlInfo.rowLevel info
 */
class TxnCtrlInfo(implicit p: Parameters) extends VLSUBundle {
  val addr       = UInt(axi4Params.addrBits.W)
  val size       = UInt(3.W)
  val rmnBeat    = UInt(log2Ceil(4096/busBytes).W)
  val lbB        = UInt((busSize + 1).W) // last Beat Bytes. NOTE: The width of lbB should be "busSize + 1" because it could be busByte, whose width is "busSize + 1".
  val illuHead   = Bool()
  val illuTail   = Bool()
  val isHead     = Bool()
  val isFinalTxn = Bool() // Used for the DataController to determine current Txn is the final Txn of the riva Req.
                          // Note: This method is only applicable when the TxnCtrlUnit processes requests sequentially.

  // The first Txn Ctrl Unit will be initiated in the next cycle following the initialization of the metadata.
  def init(meta_r: MetaCtrlInfo): Unit = {
    this.addr := ((meta_r.row.rowBaseAddr >> 12).asUInt + meta_r.row.txnCnt) << 12
    this.size := busSize.U

    // We need to avoid the impact of pageOff when calculating the number of bytes in the transaction (txn),
    // while still taking busOff into account. Therefore, we need 'pageOff_without_busOff'.
    // 'pageOff_without_busOff' is always 0 when this is not the first txn.
    val pageOff_without_busOff = (this.addr(11, busSize) << busSize).asUInt(11, 0)

    val txnBytes = Mux(
      meta_r.row.isLastTxn,
      meta_r.row.ltB, // Current txn is the last txn in the row.
      4096.U
    ) - pageOff_without_busOff // '- pageOff_without_busOff' to take the first txn into consideration.

    this.rmnBeat    := txnBytes >> busSize
    // busOff has already been accounted for in txn.lbB!
    this.lbB        := Mux(txnBytes(busSize - 1, 0).asUInt.orR, txnBytes(busSize - 1, 0).asUInt, busBytes.U) // lbB should be busBytes.U instead of 0.U when all bytes are valid (in this case txnBytes(busSize - 1, 0) = 0)!
    this.illuHead   := meta_r.row.illuHead && meta_r.row.isHeadTxn
    this.illuTail   := meta_r.row.illuTail && meta_r.row.isLastTxn

    this.isHead     := true.B
    this.isFinalTxn := meta_r.isFinalTxn
  }

  def update(r: TxnCtrlInfo): Unit = {
    this.rmnBeat := r.rmnBeat - 1.U
    this.isHead  := false.B
  }

  def isLastBeat: Bool = !this.rmnBeat.orR

  // is the final beat of the riva req.
  def isFinalBeat: Bool = this.isFinalTxn && this.isLastBeat
}