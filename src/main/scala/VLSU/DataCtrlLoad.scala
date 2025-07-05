package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import protocols.AXI.spec.RFlit

class DataCtrlLoad(implicit p: Parameters) extends VLSUModule {
  def isLoad: Boolean = true

// ------------------------------------------ IO Declaration ------------------------------------------------- //
  // R Channel Input
  val r = IO(Flipped(Decoupled(new RFlit(axi4Params)))).suggestName("io_r")

  // Output to Lane Entries
  val txs = IO(Vec(NrLanes, Decoupled(new TxLane()))).suggestName("io_txs") // to Lane

  // Input from Control Machine
  val txnInfo = IO(Flipped(Decoupled(new TxnCtrlInfo()))).suggestName("io_txnInfo")
  val metaInfo = IO(Flipped(Decoupled(new MetaCtrlInfo()))).suggestName("io_metaInfo")

  // Mask from mask unit
  val mask      = IO(Vec(NrLanes, Flipped(Valid(UInt((SLEN/4).W))))).suggestName("io_mask")
  val maskReady = IO(Output(Bool())).suggestName("io_mask_ready")

// ------------------------------------------ Module Instantiation ------------------------------------------------- //
  private val metaBroadcast = Module(new MetaInfoBroadcast())
  private val seqLd = Module(new SequentialLoad())
  private val shfu = Module(new ShuffleUnit())

// ------------------------------------------ Connections ------------------------------------------------- //
  // Connect metaInfo to broadcast module
  metaBroadcast.metaInfo <> metaInfo

  // Connect broadcast outputs to modules
  metaBroadcast.seq <> seqLd.metaInfo
  metaBroadcast.shf <> shfu.metaInfo

  // Connect R channel to SequentialLoad
  seqLd.r <> r

  // Connect txnInfo to SequentialLoad
  seqLd.txnInfo <> txnInfo

  // Connect SequentialLoad to ShuffleUnit
  seqLd.txShfu <> shfu.rxSeqLoad

  // Connect mask to ShuffleUnit
  shfu.mask <> mask
  maskReady := shfu.maskReady

  // Connect ShuffleUnit to output txs
  shfu.txs <> txs
} 