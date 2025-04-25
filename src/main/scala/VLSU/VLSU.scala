package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import protocols.AXI.spec.Axi4Bundle

class VLSU(implicit p: Parameters) extends VLSUModule {
// ------------------------------------------ IO Declaration ---------------------------------------------- //
  val rivaReq        = IO(Flipped(Decoupled(new RivaReqFull))).suggestName("io_riva_req_full")
  val axi            = IO(new Axi4Bundle(axi4Params)).suggestName("io_axi")
  val laneSide       = IO(new LaneSide).suggestName("io_lane")
  val coreStPending  = IO(Input(Bool())).suggestName("io_coreStPending")
  // TODO: maybe need two groups of mask? or different valid?
  val mask           = IO(Vec(NrLanes, Flipped(Valid(UInt((SLEN/4).W))))).suggestName("io_mask")
  val loadMaskReady  = IO(Output(Bool())).suggestName("io_load_mask_ready")
  val storeMaskReady = IO(Output(Bool())).suggestName("io_store_mask_ready")

// ------------------------------------------ Module Declaration ---------------------------------------------- //
  // Instruction Queue
  // If the instruction is enqueued while the ReqFragmenter happens to be in an idle state,
  // the instruction will be consumed immediately without the need for storage in the queue.
  // Therefore, the "flow" option should be set to true.
  private val LIQ = Module(new Queue(new RivaReqPtl, reqBufDep, flow = true))
  private val SIQ = Module(new Queue(new RivaReqPtl, reqBufDep, flow = true))

  // Control Machine
  private val LoadCtrl  = Module(new ControlMachine(true))
  private val StoreCtrl = Module(new ControlMachine(false))

  // Data Controller
  private val LDC = Module(new DataCtrlLoad())
  private val SDC = Module(new DataCtrlStore())

// ------------------------------------------ Main Logics ---------------------------------------------- //
  // req broadcast to Instruction Queues
  LIQ.io.enq.bits.init(rivaReq.bits)
  LIQ.io.enq.valid := rivaReq.valid && rivaReq.bits.isLoad

  SIQ.io.enq.bits.init(rivaReq.bits)
  SIQ.io.enq.valid := rivaReq.valid && !rivaReq.bits.isLoad

  rivaReq.ready := Mux(rivaReq.bits.isLoad, LIQ.io.enq.ready, SIQ.io.enq.ready)

  // Instruction Queue <-> LoadCtrl.io.rivaReq
  LoadCtrl.io.rivaReq  <> LIQ.io.deq
  StoreCtrl.io.rivaReq <> SIQ.io.deq

  // coreStPending
  LoadCtrl.io.coreStPending  := coreStPending
  StoreCtrl.io.coreStPending := coreStPending

  // CM <-> DC
  LDC.metaInfo       <> LoadCtrl.io.metaCtrl
  LDC.txnInfo.bits   := LoadCtrl.io.txnCtrl.bits
  LDC.txnInfo.valid  := LoadCtrl.io.txnCtrl.valid
  LoadCtrl.io.update := LDC.txnInfo.ready

  SDC.metaInfo        <> StoreCtrl.io.metaCtrl
  SDC.txnInfo.bits    := StoreCtrl.io.txnCtrl.bits
  SDC.txnInfo.valid   := StoreCtrl.io.txnCtrl.valid
  StoreCtrl.io.update := SDC.txnInfo.ready

  // CM <-> AXI[AW/AR/B]
  axi.aw <> StoreCtrl.ax
  axi.ar <> LoadCtrl.ax
  axi.b  <> StoreCtrl.b.get

  // DC <-> AXI[W/R]
  axi.w <> SDC.w
  LDC.r <> axi.r

  // DC <-> lane
  laneSide.txs <> LDC.txs
  SDC.rxs      <> laneSide.rxs

  // DC <-> mask Unit
  LDC.mask <> mask
  SDC.mask <> mask
  loadMaskReady  := LDC.maskReady
  storeMaskReady := SDC.maskReady

}

