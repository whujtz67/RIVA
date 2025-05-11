package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import protocols.AXI.spec.Axi4Bundle

class VLSU_NC(implicit p: Parameters) extends VLSUModule {
  require(!concurrent)

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
  private val IQ = Module(new Queue(new RivaReqPtl, reqBufDep, flow = true))

  // Control Machine
  private val cm  = Module(new ControlMachineNC())

  // Data Controller
  private val LDC = Module(new DataCtrlLoad())
  private val SDC = Module(new DataCtrlStore())

  // ------------------------------------------ Main Logics ---------------------------------------------- //
  // req broadcast to Instruction Queues
  IQ.io.enq.bits.init(rivaReq.bits)
  IQ.io.enq.valid := rivaReq.valid

  rivaReq.ready := IQ.io.enq.ready

  // Instruction Queue <-> LoadCtrl.io.rivaReq
  cm.io.rivaReq  <> IQ.io.deq

  // coreStPending
  cm.io.coreStPending  := coreStPending
  // CM <-> DC
  LDC.metaInfo.bits  := cm.io.metaCtrl.bits
  LDC.metaInfo.valid := cm.io.metaCtrl.valid && cm.io.metaCtrl.bits.glb.isLoad.get
  LDC.txnInfo.bits   := cm.io.txnCtrl.bits
  LDC.txnInfo.valid  := cm.io.txnCtrl.valid && cm.io.txnCtrl.bits.isLoad.get

  SDC.metaInfo.bits  := cm.io.metaCtrl.bits
  SDC.metaInfo.valid := cm.io.metaCtrl.valid && !cm.io.metaCtrl.bits.glb.isLoad.get
  SDC.txnInfo.bits   := cm.io.txnCtrl.bits
  SDC.txnInfo.valid  := cm.io.txnCtrl.valid && !cm.io.txnCtrl.bits.isLoad.get

  /*
   * The metaInfo.ready signal from the Data Controller (DC) is determined by the fullness of its metaBuffer.
   * Since request processing is strictly sequential, if one DC's metaBuffer is full (indicating pending requests),
   * the other DC is inherently blocked from proceeding.
   * Thus, combining their ready signals via an AND operation incurs no performance penalty.
   *
   * In fact, since request processing is strictly sequential, it is very hard for metaBuffer to be full.
   */
  cm.io.metaCtrl.ready := LDC.metaInfo.ready && SDC.metaInfo.ready
  cm.io.update := LDC.txnInfo.ready || SDC.txnInfo.ready

  // CM <-> AXI[AW/AR/B]
  axi.aw <> cm.aw
  axi.ar <> cm.ar
  cm.b   <> axi.b

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