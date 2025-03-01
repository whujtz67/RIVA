package protocols.AXI.components

import chisel3._
import chisel3.util._
import Utils.{FastArb, LogicDemux}
import protocols.AXI.spec.{AXI4Params, Axi4Bundle}

class ChannelDemux(mpNum: Int, maxTxnNum: Int, awQueueDepth: Int, axi4Params: AXI4Params) extends Module {
// ------------------------------------------ Parameters ---------------------------------------------- //
  // --------------------- Constant Calculation ------------------------ //
  private val selWidth     = mpNum
  private val IDWidth      = axi4Params.idBits

// ------------------------------------------ IO Declaration ---------------------------------------------- //
  val io = IO(new Bundle {
    val in = new Bundle {
      val slvPort = Flipped(new Axi4Bundle(axi4Params))
      val awSel   = Input(UInt(selWidth.W))
      val arSel   = Input(UInt(selWidth.W))
    }
    val out = new Bundle{
      val mstPorts = Vec(mpNum, new Axi4Bundle(axi4Params))
    }
  })

// ------------------------------------------ Declarations ---------------------------------------------- //
  // --------------------- Module declaration ------------------------ //
  val awIDCounter = Module(new IDCounters(IDWidth, maxTxnNum, mpNum))
  val arIDCounter = Module(new IDCounters(IDWidth, maxTxnNum, mpNum))

  // LDemux: Logic Demux
  val awLDemux    = Module(new LogicDemux(chiselTypeOf(io.in.slvPort.aw.bits), mpNum, Some("AW")))
  val wLDemux     = Module(new LogicDemux(chiselTypeOf(io.in.slvPort.w .bits), mpNum, Some("W")))
  val arLDemux    = Module(new LogicDemux(chiselTypeOf(io.in.slvPort.ar.bits), mpNum, Some("AR")))

  // awQueue
  /**
   * awQueue's role is similar to that of W_counter in pp. However, it can deal with new AW reqs when handling previous W reqs.
   * awQueue saves target port info of AW. awQueue is actually awSelQueue
   *
   * En-Queue valid is enabled when:
   * (1) input AW valid is asserted;
   * (2) Query AW ID Counter and forward is allowed.
   *
   * De-Queue valid is enabled when:
   * (1) input W valid is high;
   * (2) LDemux W ready is high; (1 + 2 means W fired)
   * (3) Current beat is the last beat. (Note that awQueue deq won't wait for b fire, aw IDCounter will wait for it !!)
   */
  val awQueue = Module(new Queue(UInt(selWidth.W), awQueueDepth, flow = true))

  // --------------------- Reg/Wire declaration ------------------------ //
  // ID Counter Wires
  val awCntPushEn = WireInit(false.B)
  val awCntPopEn  = WireInit(false.B)
  val allowAW     = WireInit(false.B)
  val arCntPushEn = WireInit(false.B)
  val arCntPopEn  = WireInit(false.B)
  val allowAR     = WireInit(false.B)

  dontTouch(allowAW)
  dontTouch(allowAR)

  // W tx
  val nowWriteTgtPort = WireInit(0.U(selWidth.W)) // Target port of the now running W Transaction

  // awQueue
  val awQLatched = RegInit(false.B) // TODO: Maybe we do not need it after we use awQueue.io.enq.valid := awLDemux.io.in.slvPort.fire && !awQLatched

  // TODO: AW/AR Valid Lock

// ------------------------------------------ Main Logic ---------------------------------------------- //
  // --------------------- Handshake flow ------------------------ //
  /***** AR *****/
  // AR Logic Demux input valid has two conditions:
  // 1. Demux input upstream valid is set
  // 2. We have queried the ID Counter and ID Counter allow the request to forward
  arLDemux.io.in.slvPort.valid := io.in.slvPort.ar.valid && allowAR
  io.in.slvPort.ar.ready := arLDemux.io.in.slvPort.fire // Logic Demux Input Handshake means that the request is accepted by Downstream Mux.

  /***** R *****/
  // R's Handshake flow is that of rr Arbiter

  /***** AW *****/
  //// AW handshake logics are more complex than that of AR
  // awLDemux handshake flow
  awLDemux.io.in.slvPort.valid := io.in.slvPort.aw.valid && (awQLatched || awQueue.io.enq.ready) && allowAW
  io.in.slvPort.aw.ready := awLDemux.io.in.slvPort.ready && (awQLatched || awQueue.io.enq.ready) && allowAW // Logic Demux Input Handshake means that the request is accepted by Downstream Mux.

  // AW Queue (AW Sel Queue)
  awQueue.io.enq.bits  := io.in.awSel
  awQueue.io.enq.valid := awLDemux.io.in.slvPort.fire && !awQLatched
  awQueue.io.deq.ready := wLDemux.io.in.slvPort.fire && io.in.slvPort.w.bits.last
  nowWriteTgtPort      := awQueue.io.deq.bits

  // Latch awQueue
  when (awQueue.io.enq.fire) { awQLatched := true.B }
  when (awLDemux.io.in.slvPort.fire) { awQLatched := false.B }

  /***** W *****/
  wLDemux.io.in.slvPort.valid := io.in.slvPort.w.valid && awQueue.io.deq.valid // Block W if we do not have an AW destination by taking awQueue.io.deq.valid into consideration
  io.in.slvPort.w.ready := wLDemux.io.in.slvPort.ready && awQueue.io.deq.valid
  /***** B *****/

  // --------------------- ID Counter Logics ---------g--------------- //
  /***** Push *****/
  arCntPushEn := arLDemux.io.in.slvPort.fire
    // Rocketchip thinks awCntPushEn should be asserted when awLDemux input fired.
    // However, pp thinks we should set push enable the same time awLDemux.io.in.slvPort.valid is asserted, regardless of ready.
  awCntPushEn := awLDemux.io.in.slvPort.fire

  /***** Pop *****/
  arCntPopEn  := io.in.slvPort.r.fire && io.in.slvPort.r.bits.last // connects to the output of RR Arbiter
  awCntPopEn  := io.in.slvPort.b.fire

  /***** Connections *****/
  IDCounters.pushConn (awIDCounter, io.in.slvPort.aw.bits.id, io.in.awSel, awCntPushEn)
  IDCounters.popConn  (awIDCounter, io.in.slvPort.b .bits.id, awCntPopEn)
  IDCounters.queryConn(awIDCounter, io.in.slvPort.aw.bits.id, io.in.awSel, allowAW    ) // Query AW ID Counter
  IDCounters.pushConn (arIDCounter, io.in.slvPort.ar.bits.id, io.in.arSel, arCntPushEn)
  IDCounters.popConn  (arIDCounter, io.in.slvPort.r .bits.id, arCntPopEn)
  IDCounters.queryConn(arIDCounter, io.in.slvPort.ar.bits.id, io.in.arSel, allowAR    ) // Query AR ID Counter

  // --------------------- RR Arbiter ------------------------ //
  FastArb.fastArbDec2Dec(io.out.mstPorts.map(_.r), io.in.slvPort.r, Some("demux_r"))
  FastArb.fastArbDec2Dec(io.out.mstPorts.map(_.b), io.in.slvPort.b, Some("demux_b"))


// ------------------------------------------ Connections ---------------------------------------------- //
  /*************** input to Logic Demux ***************/
  arLDemux.io.in.slvPort.bits := io.in.slvPort.ar.bits
  awLDemux.io.in.slvPort.bits := io.in.slvPort.aw.bits
  wLDemux .io.in.slvPort.bits := io.in.slvPort.w .bits

  arLDemux.io.in.sel := io.in.arSel
  awLDemux.io.in.sel := io.in.awSel
  wLDemux .io.in.sel := nowWriteTgtPort

  /*************** Logic Demux to output ***************/
  // AR
  io.out.mstPorts.zip(arLDemux.io.out.mstPorts).foreach {
    case (mp, ldmp) => ldmp <> mp.ar
  }
  // AW
  io.out.mstPorts.zip(awLDemux.io.out.mstPorts).foreach {
    case (mp, ldmp) => ldmp <> mp.aw
  }
  // W
  io.out.mstPorts.zip(wLDemux.io.out.mstPorts).foreach {
    case (mp, ldmp) => ldmp <> mp.w
  }




// ------------------------------------------ Assertions ---------------------------------------------- //

}


