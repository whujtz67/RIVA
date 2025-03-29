package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import protocols.AXI.spec.Axi4Bundle

class VLSU(implicit p: Parameters) extends VLSUModule {
// ------------------------------------------ IO Declaration ---------------------------------------------- //
  val rivaReq = IO(Flipped(Decoupled(new RivaReqFull)))
  val axi     = IO(new Axi4Bundle(axi4Params))
//  val lanes   = IO(Vec(NrLanes, new LaneSide)) // TODO: Temp
  val coreStPending = IO(Input(Bool()))

  // TODO: Only to test the correctness of ControlMachine.
  val infoL = IO(Valid(new Bundle {
    val meta = new MetaCtrlInfo()
    val axi  = new AxiCtrlInfo()
  }))
  val updateL = IO(Input(Bool())) // update is asserted when an Axi Data Beat is committed(R) / sent(W).
  val infoS = IO(Valid(new Bundle {
    val meta = new MetaCtrlInfo()
    val axi  = new AxiCtrlInfo()
  }))
  val updateS = IO(Input(Bool())) // update is asserted when an Axi Data Beat is committed(R) / sent(W).

// ------------------------------------------ Module Declaration ---------------------------------------------- //
  private val reqBuf = Module(new Queue(new RivaReqPtl, reqBufDep, flow = true)) // TODO: 看看如何做到一个Ctrl满了不阻塞另一个Ctrl
  private val StoreCtrl = Module(new ControlMachine(false))
  private val LoadCtrl  = Module(new ControlMachine(true))

// ------------------------------------------ Main Logics ---------------------------------------------- //
  reqBuf.io.enq.bits.init(rivaReq.bits)
  reqBuf.io.enq.valid := rivaReq.valid
  rivaReq.ready := reqBuf.io.enq.ready

  // TODO: Add STU and LDU and reqBroadcast
  LoadCtrl.rivaReq.bits   := reqBuf.io.deq.bits
  StoreCtrl.rivaReq.bits  := reqBuf.io.deq.bits
  LoadCtrl.rivaReq.valid  := reqBuf.io.deq.bits.isLoad && rivaReq.valid
  StoreCtrl.rivaReq.valid := !reqBuf.io.deq.bits.isLoad && rivaReq.valid
  reqBuf.io.deq.ready     := (!reqBuf.io.deq.bits.isLoad && StoreCtrl.rivaReq.ready) || (reqBuf.io.deq.bits.isLoad && LoadCtrl.rivaReq.ready)

  LoadCtrl.info <> infoL
  StoreCtrl.info <> infoS
  LoadCtrl.update := updateL
  StoreCtrl.update := updateS
  LoadCtrl.coreStPending := coreStPending
  StoreCtrl.coreStPending := coreStPending

  axi.aw <> StoreCtrl.ax
  axi.ar <> LoadCtrl.ax
  axi.b  <> StoreCtrl.b.get

  axi.w.bits  := DontCare
  axi.w.valid := DontCare
  axi.r.ready := DontCare

}

