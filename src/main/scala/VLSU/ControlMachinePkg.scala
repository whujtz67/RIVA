package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters

// The global information is decoded from the RIVA Req.
// Most of the vals remain unchanged throughout the request process.
class global(implicit p: Parameters) extends VLSUBundle {
  val reqId    = UInt(reqIdBits.W)
  val mode     = new VecMopOH()
  val baseAddr = UInt(vlsuAddrBits.W)
  val vd       = UInt(5.W)
  val eew      = UInt(2.W) // The element width is encoded as 2-bit binary value: 00 01 10 11
  val EW       = UInt(6.W) // Original element width:                              4  8 16 32
  val nrElem   = UInt(vlenBits.W)
  val stride   = UInt(axi4Params.addrBits.W)
  val vm       = Bool()
  val vstart   = UInt(vlenBits.W) // The start element index in the request.
  val rmnGrp   = UInt(log2Ceil(maxVecLEN/SLEN).W) // Txn will be divided into several groups in 2D cln mode, otherwise rmnGrp = 0. TODO: The width should be further considerated.
  val rmnSeg   = UInt(vlenBits.W) // Remain seg number (remain -> rmn)
  val isLoad   = if (concurrent) None else Some(Bool())
  /*
   * 'CmtCnt' represents the number of times shfBuf is committed to either the lane or seqBuf,
   * calculated by dividing the total data volume of the current request by NrLanes * SLEN.
   * 'CmtCnt' is used to decide when to deq metaBuf.
   * 'CmtCnt' is the actual count - 1 (just like axi len)
   */
  // maxCmtCnt = maxDataPerReq / (SLEN * NrLanes) = (VLEN * maxEW * NrLanes(2D Row)) / (SLEN * NrLanes) = VLEN * maxEW / SLEN
  val cmtCnt = UInt(log2Ceil(maxVecLEN / (SLEN * NrLanes)).W)

  def init(req: RivaReqPtl): Unit = {
    val elemNum = req.len - req.vstart

    this.reqId    := req.reqId
    this.mode     := (1.U << req.mop).asTypeOf(this.mode)
    this.baseAddr := (req.baseAddr << 1).asUInt
    this.vd       := req.vd
    this.eew      := req.eew
    this.EW       := req.getEW
    this.nrElem   := elemNum
    this.vm       := req.vm
    this.stride   := req.stride
    this.vstart  := req.vstart
    this.rmnGrp  := Mux(this.mode.cln2D, ((req.len << req.eew).asUInt - 1.U) >> log2Ceil(SLEN/4), 0.U)
    this.rmnSeg  := PriorityMux(Seq(  // do '-1'
      this.mode.Incr  -> 0.U,
      this.mode.Strd  -> (elemNum - 1.U),
      this.mode.row2D -> (req.len - 1.U),
      this.mode.cln2D -> (NrLanes - 1).U
    ))

    if (this.isLoad.isDefined) this.isLoad.get := req.isLoad

    // The tot_half_byte_number can also be obtained using segLen * rmnSeg * EW / (NrLanes * SLEN),
    // but that would result in a 14-bit multiplier, which is too costly.
    // TODO: The timing of this combinational logic may be suboptimal.
    //       Consider moving it into the FSM's idle initialization logic in DataCtrl,
    //       or refactoring this logic for better timing closure.

    // Compute total number of half-bytes (nibbles) to be committed
    val tot_half_byte_number = Mux(
      this.mode.is2D,
      req.len << this.eew << log2Ceil(NrLanes),
      (elemNum << this.eew).asUInt +
        (req.vstart << req.eew).asUInt(log2Ceil(NrLanes * SLEN / 4) - 1, 0) // Remember to consider vstart here!
    ).asUInt

    // Initialize commit counter (cmtCnt)
    this.cmtCnt := (tot_half_byte_number - 1.U) >> log2Ceil(NrLanes * SLEN / 4)

    assert(req.len > req.vstart, "vlen/alen must > vstart. Otherwise, the request is meaningless")

    assert(!(req.baseAddr & (((1.U << req.eew).asUInt - 1.U) >> 1).asUInt).orR, "baseAddr should be aligned to EW!")
  }

  // Update when Segment Finish
  def update(r: global): Unit = {
    this := r

    when(r.isLastSeg) {
      // ONLY 2D cln will cause more than 1 groups.
      // There is no need to include '&& !r.isLastGrp' here, because we do not perform an update when reqIssueDone is triggered.
      // Therefore, by the time execution reaches this point, r.isLastGrp is implicitly false.
      when(r.mode.cln2D) {
        this.baseAddr := r.baseAddr + (SLEN / 4).U // TODO: 这边是不对非对齐传输作特殊处理的，如果128 bits跨了总线地址边界，会被拆成2拍，可能会导致一些性能的损失
        this.rmnSeg   := (NrLanes - 1).U // Re-initialize rmnSeg. It is quit easy here because only cln2D will cause several grps.
        this.rmnGrp   := r.rmnGrp - 1.U
      }
    }.otherwise {
      this.rmnSeg := r.rmnSeg - 1.U
    }
  }

  def isLastSeg: Bool = !this.rmnSeg.orR

  def isLastGrp: Bool = !this.rmnGrp.orR
}

class segLevel(implicit p: Parameters) extends VLSUBundle {
  val segBaseAddr = UInt(vlsuAddrBits.W)
  val txnNum      = UInt(log2Ceil(maxVecLEN*EWs.max/8/4096 + 1).W) // +1 for unaligned situations, which will cause an additional txn
  val txnCnt      = UInt(log2Ceil(maxVecLEN*EWs.max/8/4096 + 1).W)
  val ltN         = UInt(14.W) // last Txn Nibbles WITH pageOff (max = 4096 * 2, whose width is 14 instead of 13!)

  /*** Initialize the seg Level info.
   *
   * @param glb_r The seg level info is initialized the next cycle of the global info initialization.
   *              As a result, the input global info should be glb_r.
   * @param valid
   */
  def init(glb_r: global): Unit = {
    val nextAddr = PriorityMux(Seq(
      glb_r.mode.Incr -> (glb_r.baseAddr + (glb_r.vstart << glb_r.eew).asUInt),
      // By aligning both stride and address to 4-bit boundaries, the segBaseAddr calculation in stride access mode is simplified.
      glb_r.mode.Strd -> (glb_r.baseAddr + glb_r.vstart * glb_r.stride), // This section involves adders and multipliers, TIMING crucial
      glb_r.mode.is2D -> glb_r.baseAddr  // We don't take vstart into consideration in 2D modes at present.
    )).suggestName("seglv_init_next_addr")
    this.seglv_init_common(nextAddr, glb_r)
  }

  /*** switch between groups
   *
   * @note Only 2D cln mode will lead to several groups.
   */
  def switchGrpInit(glb_nxt: global): Unit = {
    val nextAddr = glb_nxt.baseAddr
    this.seglv_init_common(nextAddr, glb_nxt)
  }


  /*** switch between different segs in the SAME group.
   *
   * @param glb_r The main payloads of glb info remain unchanged when switching seg, so that the input is '_r'.
   * @note Only Stride and 2D mode will lead to seg switch.
   */
  def switchSegInit(r: segLevel, glb_r: global): Unit = {
    val nextAddr = r.segBaseAddr + glb_r.stride
    this.seglv_init_common(nextAddr, glb_r)
  }

  /*** The common parts shared by init, switchGrpInit, and switchSegInit
   *
   * @param nextAddr
   * @param glb
   */
  private def seglv_init_common(nextAddr: UInt, glb: global): Unit = {
    val nr_seg_nbs_row_major = (PriorityMux(Seq(
      glb.mode.Incr  -> glb.nrElem,
      glb.mode.Strd  -> 1.U,
      glb.mode.row2D -> NrLanes.U
    )) << glb.eew).asUInt

    val nr_seg_nbs_cln_major = Mux(
      glb.isLastGrp,
      Mux(
        (glb.nrElem << glb.eew).asUInt(log2Ceil(SLEN/4)-1, 0) === 0.U,
        (SLEN / 4).U,
        (glb.nrElem << glb.eew).asUInt(log2Ceil(SLEN/4)-1, 0)
      ),
      (SLEN / 4).U
    )

    val nr_seg_nbs = Mux(glb.mode.cln2D, nr_seg_nbs_cln_major, nr_seg_nbs_row_major)

    this.segBaseAddr := nextAddr

    val pageOff  = this.segBaseAddr(12, 0)
    val seg_nibbles_with_pageOff = pageOff + nr_seg_nbs

    this.txnNum := (seg_nibbles_with_pageOff - 1.U) >> 13
    this.txnCnt := 0.U

    // In the TxnCtrlInfo module, the value of "txn_nibbles_with_pageOff" is calculated as 8192 ('pageOff-inclusive') when the current transaction is not the final beat,
    // otherwise it equals ltN. Therefore, ltN must also adopt a 'pageOff-inclusive' format.
    this.ltN := Mux(
      seg_nibbles_with_pageOff(12, 0).orR,
      seg_nibbles_with_pageOff(12, 0),
      8192.U
    )

    dontTouch(pageOff)
    dontTouch(seg_nibbles_with_pageOff)
  }

  // simple update in seg
  def update(r: segLevel): Unit = {
    val nxt = this

    nxt.txnCnt := r.txnCnt + 1.U

    assert(nxt.txnCnt <= r.txnNum, s"[ReqFragmenter seglv simple update] nxt.txnCnt(%d) has exceeded r.txnNum(%d)!", nxt.txnCnt, r.txnCnt)
  }

  // isHead txn in the segment, not head seg!!!
  def isHeadTxn: Bool = !this.txnCnt.orR

  def isLastTxn: Bool = this.txnCnt === this.txnNum
}

class MetaCtrlInfo(implicit p: Parameters) extends VLSUBundle {
  // ---------------------------------------------------- MetaCtrlInfo Fields ---------------------------------------------------- //
  val glb = new global()
  val seg = new segLevel()

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
    val nxt = this
    
    // default connection
    nxt := r

    val isFinalTxn = WireDefault(r.isFinalTxn)

    // When 'reqIssueDone' is triggered alongside 'doUpdate',
    // it signifies that the last Txn of the request has been fully issued,
    // meaning the entire request has entered the processing pipeline.
    //
    // NOTE: The register storing 'MetaCtrlInfo' for this request MUST NOT be released immediately.
    // It should remain active until the completion of the final data transfer cycle before being deallocated.
    when(doUpdate && !isFinalTxn) {
      when (r.seg.isLastTxn) {
        // update global info (isLastSeg and isLastGrp is already considered in glb.update)
        nxt.glb.update(r.glb)

        // update seg Level info (switch seg / group)
        when(r.glb.isLastSeg) { // Last Segment but not the last group, switch GROUP
          nxt.seg.switchGrpInit(nxt.glb)
        }.otherwise {           // Not the last seg, switch Segment
          nxt.seg.switchSegInit(r.seg, nxt.glb)
        }
      }.otherwise {
        nxt.seg.update(r.seg)
      }
    }

    dontTouch(isFinalTxn)
  }

  /*** The isFinalTxn signal indicates that the Txn currently being issued is the final one of the entire request.
   *
   * @note The ReqFragmenter will be released after reqIssueDone. However, it DOES NOT indicates that the request is all Done.
   */
  def isFinalTxn: Bool = this.glb.isLastGrp && this.glb.isLastSeg && this.seg.isLastTxn

}

/** Transaction control info saved in TxnCtrlUnit
 *
 * TxnCtrlInfo is derived from MetaCtrlInfo.segLevel info
 */
class TxnCtrlInfo(implicit p: Parameters) extends VLSUBundle {
  val reqId      = if (debug) Some(UInt(reqIdBits.W)) else None
  val addr       = UInt(vlsuAddrBits.W)
  val size       = UInt(3.W)
  val rmnBeat    = UInt(log2Ceil(4096/busBytes).W) // The width not need to "+ 1" like txnNum of segInfo does.
  val lbN        = UInt((busNSize + 1).W) // last Beat nibbles WITH busOff (max lbN = busNibbles.U, whose width is busNSize + 1!)
  val isHead     = Bool()
  val isLoad     = if (concurrent) None else Some(Bool()) // Don't need for concurrent mode.
  val isFinalTxn = Bool() // Used for the DataController to determine current Txn is the final Txn of the riva Req.
                          // Note: This method is only applicable when the TxnCtrlUnit processes requests sequentially.

  // The first Txn Ctrl Unit will be initiated in the next cycle following the initialization of the metadata.
  def init(meta_r: MetaCtrlInfo): Unit = {
    val nxt = this

    val seg_r = meta_r.seg

    if (nxt.reqId.isDefined) nxt.reqId.get := meta_r.glb.reqId

    nxt.addr := Mux(
      seg_r.isHeadTxn,
      seg_r.segBaseAddr,
      ((seg_r.segBaseAddr >> 13).asUInt + seg_r.txnCnt) << 13
    )
    nxt.size := busSize.U

    // We need to avoid the impact of pageOff when calculating the number of bytes in the transaction (txn),
    // while still taking busOff into account. Therefore, we need 'pageOff_without_busOff'.
    // 'pageOff_without_busOff' is always 0 when this is not the first txn.
    val pageOff = nxt.addr(12, 0)
    val busOffMask = (((1 << 13) - 1) - ((1 << busNSize) - 1)).U(13.W)
    val pageOff_without_busOff = pageOff & busOffMask.asUInt

    val txn_nibbles_with_pageOff = Mux(
      seg_r.isLastTxn,
      seg_r.ltN, // PageOff is included in ltN
      8192.U
    )
    // The subtraction of pageOff_without_busOffset is designed to account for initialization adjustments when the current transaction is the first in a sequence.
    // For all subsequent transactions, this term is inherently zero, ensuring no impact on the final result.
    val txn_nibbles_with_busOff = txn_nibbles_with_pageOff - pageOff_without_busOff

    nxt.rmnBeat := (txn_nibbles_with_busOff - 1.U) >> busNSize

    // TODO: optimize it
    // lbN should be busNibbles.U instead of 0.U when all bytes are valid (in this case txnBytes(busNSize - 1, 0) = 0)!
    nxt.lbN := Mux(
      txn_nibbles_with_busOff(busNSize - 1, 0).orR,
      txn_nibbles_with_busOff(busNSize - 1, 0),
      busNibbles.U
    )

    nxt.isHead     := true.B
    if (nxt.isLoad.isDefined) nxt.isLoad.get := meta_r.glb.isLoad.get
    nxt.isFinalTxn := meta_r.isFinalTxn

    assert(txn_nibbles_with_pageOff >= pageOff_without_busOff,
      s"txn_nibbles_with_pageOff should >= pageOff_without_busOff, got txn_nibbles_with_pageOff = %d, pageOff_without_busOff = %d",
      txn_nibbles_with_pageOff, pageOff_without_busOff
    )
    assert(txn_nibbles_with_busOff <= 8192.U, s"txn_nibbles_with_busOff should in range(0, 8192). However, got %d\n", txn_nibbles_with_busOff)

    dontTouch(pageOff)
    dontTouch(txn_nibbles_with_busOff)
    dontTouch(txn_nibbles_with_pageOff)
    dontTouch(pageOff_without_busOff)

  }
  
  def update(r: TxnCtrlInfo): Unit = {
    val nxt = this
    
    nxt.rmnBeat := r.rmnBeat - 1.U
    nxt.isHead  := false.B
  }

  def isLastBeat: Bool = !this.rmnBeat.orR

  // is the final beat of the riva req.
  def isFinalBeat: Bool = this.isFinalTxn && this.isLastBeat
}