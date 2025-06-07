package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import protocols.AXI.spec.{AWFlit, ARFlit, BFlit, Burst, Cache}

import xs.utils.{CircularQueuePtr, HasCircularQueuePtrHelper}

/** Non-concurrent TxnControlUnit
 *
 * @param p
 */
class TxnControlUnitNC(implicit p: Parameters) extends VLSUModule with HasCircularQueuePtrHelper {
  override def desiredName: String = "TxnCtrl_NonConcurrent"

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
  val aw = IO(Decoupled(new AWFlit(axi4Params)))
  val ar = IO(Decoupled(new ARFlit(axi4Params)))
  val b  = IO(Flipped(Decoupled(new BFlit(axi4Params))))

  // ------------------------------------------ Wire/Reg Declaration ---------------------------------------------- //
  // single txn controls are actually a series of registers.
  private val tcs_nxt = Wire(Vec(txnCtrlNum, new TxnCtrlInfo()))
  private val tcs_r = RegNext(tcs_nxt)

  // Pointers
  private val enqPtr  = RegInit(0.U.asTypeOf(new CirQTxnCtrlPtr))
  private val deqPtr  = RegInit(0.U.asTypeOf(new CirQTxnCtrlPtr))  // B Ptr is not needed because deqPtr can serves as B Ptr when storing.
  private val txnPtr  = RegInit(0.U.asTypeOf(new CirQTxnCtrlPtr)) // Ax Txn with info of which TxnCtrl is sending
  private val dataPtr = RegInit(0.U.asTypeOf(new CirQTxnCtrlPtr)) // Pointing to the information of the transaction being processed by the Data Transformer.

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
       *
       * NOTE: We assume that update will never be true when TC is empty.
       */
      when (dataPtr.value === i.U && io.update) {
        tc.update(tcs_r(i))
      }
  }

  //
  // Pointer update logics
  //
  private val dataPtrAdd = tcs_r(dataPtr.value).isLastBeat && io.update // add data ptr when last beat done.
  private val do_enq     = WireDefault(io.meta.fire)
  // dataPtr and deqPtr is always synchronous for Load. TODO: Don't need dataPtr for Load.
  // TODO: Maybe do not need to wait for b because Ax id is the same. （当然保守起见还是可以先这么写，ara中，b通道收到后会返回一个信号）
  private val do_deq     = Mux(tcs_r(deqPtr.value).isLoad.get, dataPtrAdd, b.fire)

  when (do_enq)             { enqPtr  := enqPtr  + 1.U }
  when (do_deq)             { deqPtr  := deqPtr  + 1.U }
  when (aw.fire || ar.fire) { txnPtr  := txnPtr  + 1.U }
  when (dataPtrAdd)         { dataPtr := dataPtr + 1.U }

  //
  // Handshake logics
  //
  /*
   * (1) Non-concurrent mode:
   *    To prevent address range overlap between transactions, all transactions (both Load and Store) must be sequentially issued,
   *  ensuring the current transaction is fully completed before initiating the next.
   *
   * (2) Concurrent mode:
   *    Issue Ax Txn as long as there is a valid Txn in the Txn Ctrl.
   */
  private val axValid = (txnPtr === deqPtr) && !empty
  io.meta.ready    := !full
  io.txnCtrl.valid := !empty
  aw.valid         := axValid && !tcs_r(txnPtr.value).isLoad.get
  ar.valid         := axValid && tcs_r(txnPtr.value).isLoad.get
  b.ready          := !empty

  //
  // Output logics
  //
  when(aw.fire) {
    aw.bits.set(
      id    = 0.U,  // DONT SUPPORT out-of-order. TODO: support it in the next generation.
      addr  = (tcs_r(txnPtr.value).addr >> 1).asUInt,
      len   = tcs_r(txnPtr.value).rmnBeat, // RmnBeat is dynamic, but it shouldn't be a problem because the update signal will not be issued ahead of the transmission of the Ax request.
      size  = tcs_r(txnPtr.value).size,
      burst = Burst.Incr,
      cache = Cache.Modifiable
    )
  }.otherwise {
    aw.bits := 0.U.asTypeOf(aw.bits)
  }

  when(ar.fire) {
    ar.bits.set(
      id    = 0.U,  // DONT SUPPORT out-of-order. TODO: support it in the next generation.
      addr  = (tcs_r(txnPtr.value).addr >> 1).asUInt,
      len   = tcs_r(txnPtr.value).rmnBeat, // RmnBeat is dynamic, but it shouldn't be a problem because the update signal will not be issued ahead of the transmission of the Ax request.
      size  = tcs_r(txnPtr.value).size,
      burst = Burst.Incr,
      cache = Cache.Modifiable
    )
  }.otherwise {
    ar.bits := 0.U.asTypeOf(ar.bits)
  }

  io.txnCtrl.bits := tcs_r(dataPtr.value) // NOTE: Should be dataPtr here, because deqPtr will wait for b resp.

  // ------------------------------------------ Assertions ---------------------------------------------- //
  when(io.update) { assert(!empty, "should not update when there are no control information in TC") }

  when(b.valid) { assert(!empty, "should be at least one valid tc when b valid!") }

  // deqPtr <= dataPtr <= txnPtr <= enqPtr
  // 'isNotAfter' means 'left' <= 'right'
  assert(isNotAfter(txnPtr , enqPtr ), "axPtr should not go before enqPtr")
  assert(isNotAfter(dataPtr, txnPtr ), "dataPtr should not go before axPtr")
  assert(isNotAfter(deqPtr , dataPtr), "deqPtr should not go before dataPtr")
}

/** Non-concurrent ControlMachine
 *
 * @param p
 */
class ControlMachineNC(implicit p: Parameters) extends VLSUModule {
  // ------------------------------------------ Parameters ---------------------------------------------- //
  override def desiredName: String = "CtrlMachine_NonConcurrent"

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
  val aw = IO(Decoupled(new AWFlit(axi4Params)))
  val ar = IO(Decoupled(new ARFlit(axi4Params)))
  val b  = IO(Flipped(Decoupled(new BFlit(axi4Params))))

  // ------------------------------------------ Module Declaration ---------------------------------------------- //
  private val rf  = Module(new ReqFragmenter()).suggestName("ReqFragmenter")
  private val tc  = Module(new TxnControlUnitNC()).suggestName(s"TxnCtrlUnit")

  // ------------------------------------------ Main Logics ---------------------------------------------- //
  //
  // IO Connection
  //
  rf.io.rivaReq <> io.rivaReq
  rf.io.coreStPending := io.coreStPending

  tc.io.update      := io.update
  io.txnCtrl        <> tc.io.txnCtrl
  io.metaCtrl.bits  := rf.io.meta.bits
  io.metaCtrl.valid := rf.io.meta.valid
  rf.io.metaBufFull := !io.metaCtrl.ready // metaCtrl.ready is metaBuf's enq.ready

  aw <> tc.aw
  ar <> tc.ar

  tc.b <> b

  //
  // Connection Between RF and TC
  //
  tc.io.meta <> rf.io.meta
}