package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import protocols.AXI.spec.WFlit

class DataCtrlStore(implicit p: Parameters) extends VLSUModule {
// ------------------------------------------ IO Declaration ------------------------------------------------- //
  // W Channel Output
  val w = IO(Decoupled(new WFlit(axi4Params))).suggestName("io_w")

  // Input from Lane Exits
  val rxs = IO(Vec(NrLanes, Flipped(Decoupled(new RxLane())))).suggestName("io_rxs")

  // Meta info from Control Machine
  val metaInfo = IO(Flipped(Decoupled(new MetaCtrlInfo()))).suggestName("io_metaInfo")
  val txnInfo = IO(Flipped(Decoupled(new TxnCtrlInfo()))).suggestName("io_txnInfo")

  // Mask from mask unit
  val mask = IO(Vec(NrLanes, Flipped(Valid(UInt((SLEN/4).W))))).suggestName("io_mask")
  val maskReady = IO(Output(Bool())).suggestName("io_mask_ready")

// ------------------------------------------ Module Instantiation ------------------------------------------------- //
  private val metaBroadcast = Module(new MetaInfoBroadcast())
  private val deshfu = Module(new DeShuffleUnit())
  private val seqSt = Module(new SequentialStore())

// ------------------------------------------ Connections ------------------------------------------------- //
  // Connect metaInfo to broadcast module
  metaBroadcast.metaInfo <> metaInfo

  // Connect broadcast outputs to modules
  metaBroadcast.seq <> seqSt.metaInfo
  metaBroadcast.shf <> deshfu.metaInfo

  // Connect rxs to DeShuffleUnit
  deshfu.rxs <> rxs

  // Connect txnInfo to SequentialStore
  seqSt.txnInfo <> txnInfo

  // Connect mask to DeShuffleUnit
  deshfu.mask <> mask
  maskReady := deshfu.maskReady

  // Connect seqBuf between DeShuffleUnit and SequentialStore
  deshfu.txSeqStore <> seqSt.rxDeshfu

  // Connect w output from SequentialStore
  w <> seqSt.w
}