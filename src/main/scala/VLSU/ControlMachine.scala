package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import protocols.AXI.spec.{AxFlit, BFlit, Burst, Cache}

import xs.utils.{CircularQueuePtr, HasCircularQueuePtrHelper}

/** ReqFragmenter
 *
 * @param p
 */
class ReqFragmenter(implicit p: Parameters) extends VLSUModule {
  val io = IO(new Bundle {
    val rivaReq         = Flipped(Decoupled(new RivaReqPtl()))
    val coreStPending   = Input(Bool())
    val meta            = Decoupled(new MetaCtrlInfo())  // 'meta.ready' means a TxnCtrlInfo can be injected to a free tc
    val metaBufFull     = Input(Bool())
    val metaBufEnqValid = Output(Bool())
  })

  private val s_idle :: s_seg_lv_init :: s_fragmenting :: s_stall :: Nil = Enum(4)
  private val state_nxt   = WireInit(s_idle)
  private val state_r     = RegNext(state_nxt)
  private val idle        = state_r === s_idle
  private val seg_lv_init = state_r === s_seg_lv_init
  private val fragmenting = state_r === s_fragmenting
  private val stall       = state_r === s_stall

  private val meta_nxt = WireInit(0.U.asTypeOf(new MetaCtrlInfo()))
  private val meta_r   = RegNext(meta_nxt)

  // io.meta.valid is always asserted during fragmentation, which will leads to
  // duplicated payloads in data control meta buffer if 'metaBufEnqValid := io.meta.valid'.
  // As a result, there should be a signal which is only asserted at the first cycle of 'fragmenting' state.
  //
  // We shouldn't connect data control meta buffer with riva req buffer,
  // because meta buffer need 'cmtCnt', which is calculated in reqFragmenter.
  //
  // TODO: maybe can put the decode of global info outside reqFragmenter.
  private val start_fragmenting = RegInit(false.B)

  private val doUpdate = io.meta.ready
  private val finalTxnIssued = WireDefault(meta_r.isFinalTxn && doUpdate) // The final Txn of the riva Req is issued to the tc

  // FSM state switch
  when (idle) {
    state_nxt := Mux(io.rivaReq.valid, s_seg_lv_init, s_idle)
  }.elsewhen(seg_lv_init) {
    state_nxt := Mux(io.coreStPending || io.metaBufFull, s_stall, s_fragmenting)
  }.elsewhen(fragmenting) {
    state_nxt := Mux(finalTxnIssued, s_idle, s_fragmenting)
  }.elsewhen(stall){
    state_nxt := Mux(io.coreStPending || io.metaBufFull, s_stall, s_fragmenting)
  }.otherwise {
    state_nxt := state_r
  }

  // FSM Outputs
  meta_nxt := meta_r
  when (idle) {
    when (io.rivaReq.valid) {
      meta_nxt.glb.init(io.rivaReq.bits)
      // Won't initialize seg level info in this state.
    }
  }.elsewhen(seg_lv_init) {
    meta_nxt.seg.init(meta_r.glb)

    start_fragmenting := !(io.coreStPending || io.metaBufFull)
  }.elsewhen(fragmenting) {
    meta_nxt.resolve(meta_r, doUpdate)

    // We expect there to always be empty spaces in the data control meta buffer during fragmentation,
    // so we don't need to wait for the meta buffer to fire.
    start_fragmenting := false.B
  }.elsewhen(stall) {
    start_fragmenting := !(io.coreStPending || io.metaBufFull)
  }

  io.meta.bits  := meta_r
  io.meta.valid := fragmenting

  // In the IDLE state, the valid information from the instruction is stored in MetaCtrlInfo.glb.
  // After this storage, the instruction information is no longer needed.
  // Therefore, during the IDLE state, the Instruction Queue can be dequeued.
  io.rivaReq.ready := idle

  io.metaBufEnqValid := start_fragmenting

// ------------------------------------------ Don't Touch ---------------------------------------------- //
  dontTouch(idle)
  dontTouch(seg_lv_init)
  dontTouch(fragmenting)
  dontTouch(stall)
  dontTouch(state_nxt)

  dontTouch(meta_r)
  dontTouch(meta_nxt)

  dontTouch(start_fragmenting)
}

/** TxnControlUnit
 *
 * @param isLoad
 * @param p
 */
class TxnControlUnit(isLoad: Boolean)(implicit p: Parameters) extends VLSUModule with HasCircularQueuePtrHelper {
// ------------------------------------------ Parameters ---------------------------------------------- //
  private val addrChnlName = if (isLoad) "ar" else "aw"
  private val dataChnlName = if (isLoad) "r"  else "w"

  override def desiredName: String = if (isLoad) "TxnCtrlLoad" else "TxnCtrlStore"

// ------------------------------------------ CircularQueuePtr ---------------------------------------------- //
  class CirQTxnCtrlPtr extends CircularQueuePtr[CirQTxnCtrlPtr](txnCtrlNum)

// ------------------------------------------ IO Declaration ---------------------------------------------- //
  val io = IO(new Bundle {
    val meta     = Flipped(Decoupled(new MetaCtrlInfo())) // inward
    val txnCtrl  = Valid(new TxnCtrlInfo())               // outward. For convenience in the code, all TxnCtrlInfo is directly output.
                                                          // However, in practice, only a subset of these signals will be utilized.
                                                          // Unused signals are expected to be optimized away by the synthesis tool.
    val update   = Input(Bool())
  })
  val ax = IO(Decoupled(new AxFlit(axi4Params))).suggestName(s"$addrChnlName")
  val b  = if (isLoad) None else Some(IO(Flipped(Decoupled(new BFlit(axi4Params))))) // Only STU has b channel

// ------------------------------------------ Wire/Reg Declaration ---------------------------------------------- //
  // single txn controls are actually a series of registers.
  private val tcs_nxt = Wire(Vec(txnCtrlNum, new TxnCtrlInfo()))
  private val tcs_r = RegNext(Vec(txnCtrlNum, new TxnCtrlInfo()))

  // Pointers
  private val enqPtr  = RegInit(0.U.asTypeOf(new CirQTxnCtrlPtr))
  private val deqPtr  = RegInit(0.U.asTypeOf(new CirQTxnCtrlPtr))  // B Ptr is not needed because deqPtr can serves as B Ptr when storing.
  private val axPtr   = RegInit(0.U.asTypeOf(new CirQTxnCtrlPtr)).suggestName(s"${addrChnlName}Ptr") // Ax Txn with info of which TxnCtrl is sending
  private val dataPtr = RegInit(0.U.asTypeOf(new CirQTxnCtrlPtr)).suggestName(s"${dataChnlName}Ptr") // Pointing to the information of the transaction being processed by the Data Transformer.

  // empty and full
  private val empty = WireDefault(isEmpty(enqPtr, deqPtr))
  private val full  = WireDefault(isFull (enqPtr, deqPtr))

// ------------------------------------------ Main Logics ---------------------------------------------- //
  //
  // tc initialize and update logics
  //
  tcs_nxt := tcs_r
  tcs_nxt.zipWithIndex.foreach {
    case (tc, i) =>
      /* Do Init (enq) when:
       * 1. EnqPtr is pointing to the current tc.
       * 2. The Queue is not full
       * 3. Meta info is valid, which means reqFragmenter is fragmenting a request.
       */
      when (enqPtr.value === i.U && !full && io.meta.valid) {
        tc.init(io.meta.bits)
      }

      /* Do Update when:
       * 1. DataPtr is pointing to the current tc.
       * 2. The update from dataController is true.
       * 3. Current beat is not the last beat.
       *
       * NOTE: We assume that update will never be true when TC is empty.
       */
      when (dataPtr.value === i.U && io.update  && !tcs_r(i).isLastBeat) {
        tc.update(tcs_r(i))
      }
  }

  //
  // Pointer update logics
  //
  private val dataPtrAdd = tcs_r(dataPtr.value).isLastBeat && io.update // add data ptr when last beat done.
  private val do_enq     = WireDefault(io.meta.fire)
  private val do_deq     = WireDefault(if (isLoad) dataPtrAdd else b.get.fire) // dataPtr and deqPtr is always synchronous

  when (do_enq)     { enqPtr  := enqPtr  + 1.U }
  when (do_deq)     { deqPtr  := deqPtr  + 1.U }
  when (ax.fire)    { axPtr   := axPtr   + 1.U }
  when (dataPtrAdd) { dataPtr := dataPtr + 1.U }

  //
  // Output logics
  //
  ax.bits.set(
    id    = 0.U,  // DONT SUPPORT out-of-order. TODO: support it in the next generation.
    addr  = (tcs_r(axPtr.value).addr >> 1).asUInt,
    len   = tcs_r(axPtr.value).rmnBeat, // RmnBeat is dynamic, but it shouldn't be a problem because the update signal will not be issued ahead of the transmission of the Ax request.
    size  = tcs_r(axPtr.value).size,
    burst = Burst.Incr,
    cache = Cache.Modifiable
  )

  io.txnCtrl.bits := tcs_r(dataPtr.value) // NOTE: Should be dataPtr here.


  //
  // Handshake logics
  //
  io.meta.ready    := !full
  io.txnCtrl.valid := !empty
  ax.valid         := !isEmpty(enqPtr, axPtr) // isEmpty(enqPtr, axPtr) means all the valid ax txn has been issued.
  if (b.isDefined) b.get.ready := !empty

// ------------------------------------------ Assertions ---------------------------------------------- //
  when(io.update) { assert(!empty, "should not update when there are no control information in TC") }

  if (b.isDefined) {
    when(b.get.valid) { assert(!empty, "should be at least one valid tc when b valid!") }
  }
  
  // 'isNotAfter' means 'left' <= 'right'
  assert(isNotAfter(axPtr  , enqPtr ) || isFull(axPtr , enqPtr ), s"${addrChnlName}Ptr should not go before enqPtr")
  assert(isNotAfter(dataPtr, enqPtr ) || isFull(dataPtr, enqPtr ), "dataPtr should not go before enqPtr")
  // There is no strict ordering required between txnPtr and dataPtr,
  // because W transactions are allowed to arrive before AW,
  // as long as the slave is able to block W when there is no corresponding valid AW transaction.
  assert(isNotAfter(deqPtr , dataPtr) || isFull(deqPtr , dataPtr) , "deqPtr should not go before dataPtr")
}



/** A Control Machine that applies to both Load and Store Process.
 *
 * @param isLoad This Control Machine served for load or store.
 *
 * 'ControlMachine' is made up of 'ReqFragmenter' and 'TxnControlUnit'.
 * The ControlMachine primarily instantiates these two modules without incorporating any additional logic.
 */
class ControlMachine(isLoad: Boolean)(implicit p: Parameters) extends VLSUModule {
// ------------------------------------------ Parameters ---------------------------------------------- //
  private val addrChnlName = if (isLoad) "ar" else "aw"
  private val dataChnlName = if (isLoad) "r"  else "w"
  private val directStr = if (isLoad) "Load" else "Store"
  override def desiredName: String = if (isLoad) "CtrlMachineLoad" else "CtrlMachineStore"

// ------------------------------------------ IO Declarations ---------------------------------------------- //
  val io = IO(new Bundle {
    // requester side
    val rivaReq = Flipped(Decoupled(new RivaReqPtl()))
    val coreStPending  = Input(Bool())

    // data controller side
    val metaCtrl = Decoupled(new MetaCtrlInfo())
    val txnCtrl  = Valid(new TxnCtrlInfo())
    val update   = Input(Bool()) // update txnCtrlInfo
  })
  val ax     = IO(Decoupled(new AxFlit(axi4Params))).suggestName(s"$addrChnlName")
  val b      = if (isLoad) None else Some(IO(Flipped(Decoupled(new BFlit(axi4Params))))) // Only STU has b channel

// ------------------------------------------ Module Declaration ---------------------------------------------- //
  private val rf  = Module(new ReqFragmenter()).suggestName("ReqFragmenter")
  private val tc  = Module(new TxnControlUnit(isLoad)).suggestName(s"${directStr}_TC")

// ------------------------------------------ Main Logics ---------------------------------------------- //
  //
  // IO Connection
  //
  rf.io.rivaReq <> io.rivaReq
  rf.io.coreStPending := io.coreStPending

  tc.io.update      := io.update
  io.txnCtrl        <> tc.io.txnCtrl
  io.metaCtrl.bits  := rf.io.meta.bits
  io.metaCtrl.valid := rf.io.metaBufEnqValid
  rf.io.metaBufFull := !io.metaCtrl.ready // metaCtrl.ready is metaBuf's enq.ready

  ax       <> tc.ax

  if (!isLoad) tc.b.get <> b.get

  //
  // Connection Between RF and TC
  //
  tc.io.meta <> rf.io.meta
}