package protocols.AXI.components

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config._

import Utils.DeltaCounter

import Math._


/**
 * Each ID has a counter, the width of which is decided by the maxInflight number.
 * Each Demux has 2 IDCounters, one for read and one for write.
 *
 * *** ID Counter has to be integrated in Demux to avoid dealing with valid/ready by itself. (Or let Demux use IO to query ID Counter?) ***
 */
class IDCounters(IDWidth: Int, maxTxnNum: Int, mpNum: Int) extends Module {
// ------------------------------------------ Parameters ---------------------------------------------- //
  // --------------------- Constant Calculation ------------------------ //
  private val counterNum   = pow(2, IDWidth).toInt // TODO: How to write pow?
  private val counterWidth = log2Up(maxTxnNum)
  private val selWidth     = mpNum

// ------------------------------------------ IO Declaration ---------------------------------------------- //
  val io = IO(new Bundle {
    // Push will increase ID Counter (Push the same cycle as query successful?)
    val push = new Bundle {
      val id      = Input(UInt(IDWidth .W)) // The ID to be pushed
      val tgtPort = Input(UInt(selWidth.W)) // Record the target Port Index of the Txn with this ID
      val en      = Input(Bool())
    }

    // Pop will decrease ID Counter
    val pop = new Bundle {
      val id      = Input(UInt(IDWidth.W)) // The ID to be popped
      val en      = Input(Bool())
    }

    // TODO: inject for ATOP

    // Query whether the ID is occupied by other Txn targeting different master port
    val query = new Bundle {
      val id      = Input (UInt(IDWidth .W)) // The ID to be queried
      val tgtPort = Input (UInt(selWidth.W)) // The target Port Index of the Txn we want to query
      val forward = Output(Bool())               // Forward the txn when the ID is not occupied by another Txn targeting different master port
    }
  })



// ------------------------------------------ Declarations ---------------------------------------------- //
  // --------------------- Module declaration ------------------------ //
  val idCounters = Seq.fill(counterNum) { Module(new DeltaCounter(counterWidth)) } // each ID has a counter

  // --------------------- Wire/Reg declaration ------------------------ //
  val enPushOH = WireInit(0.U(counterNum.W)) // There should be only one txn push or pop at the same time, so we use OH to describe it.
  val enPopOH  = WireInit(0.U(counterNum.W))
  val occupied = VecInit(Seq.fill(counterNum)(false.B))
  val idFulls  = VecInit(Seq.fill(counterNum)(false.B))
  // record target port of now running Txn for each ID (mst_select_q of pp platform)
  val tgtPortRecords = VecInit((0 until counterNum).map { i =>
    RegEnable(io.push.tgtPort, 0.U(selWidth.W), enPushOH(i)) // there will be only 1 bit of push_ens to be high, so tgtPortRecords can always connect to io.push.tgtPort
  })

// ------------------------------------------ Logics ---------------------------------------------- //
  // --------------------- ID count Logic ------------------------ //
  idCounters.zipWithIndex.foreach {
    case(c, i) =>
      // increase/decrease count (Note that push and pop can be concurrent!)
      val en_case = Cat(enPushOH(i), enPopOH(i))
      /// push/pop FSM
      when (en_case === "b10".U) { // push Enable
        c.io.in.delta := 1.U
        c.io.in.decr  := false.B
        c.io.in.en    := true.B
      } .elsewhen(en_case === "b01".U) { // pop Enable
        c.io.in.delta := 1.U
        c.io.in.decr  := true.B
        c.io.in.en    := true.B
      } // en_case === "b11".U, count +1 -1 = 0, dont care
        .otherwise {
        c.io.in.delta := 0.U
        c.io.in.decr  := false.B
        c.io.in.en    := false.B
      }
      occupied(i) := c.io.out.nowCount.orR
      idFulls (i) := c.io.out.full
  }

  // --------------------- Push Logic ------------------------ //
  enPushOH := Mux(io.push.en, 1.U << io.push.id, 0.U)

  // --------------------- Pop Logic ------------------------ //
  enPopOH  := Mux(io.pop.en, 1.U << io.pop.id, 0.U)

  // --------------------- Query Logic ------------------------ //
  /**
   * There are some differences with pp platform here.
   * Forward the Txn in two cases when ID counter is not full:
   * 1. There are no txns with the same ID inflight.
   * 2. Or there are txns with the same ID inflight, but the target master port of the inflight txn is the same as the querying txn.
   */
  io.query.forward := !idFulls(io.query.id) && (!occupied(io.query.id) || (io.query.tgtPort === tgtPortRecords(io.query.id)))
}

object IDCounters {
  def pushConn(counter: IDCounters, id: UInt, sel: UInt, en: Bool): Unit = {
    counter.io.push.id      := id
    counter.io.push.tgtPort := sel
    counter.io.push.en      := en
  }

  def popConn(counter: IDCounters, id: UInt, en: Bool): Unit = {
    counter.io.pop.id      := id
    counter.io.pop.en      := en
  }

  def queryConn(counter: IDCounters, id: UInt, sel: UInt, forward: Bool): Unit = {
    counter.io.query.id      := id
    counter.io.query.tgtPort := sel
    forward                  := counter.io.query.forward
  }
}
