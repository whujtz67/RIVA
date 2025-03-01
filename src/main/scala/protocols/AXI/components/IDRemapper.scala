package protocols.AXI.components

import chisel3._
import chisel3.util._

import Utils.DeltaCounter

import Math._
import protocols.AXI.spec._

/**
 * 
 */
class IDRemapper(spNum: Int, maxTxnNum: Int, axi4Params: AXI4Params) extends Module {
// ------------------------------------------ Parameters ---------------------------------------------- //
  // -------------------- Get Params from MeshModule ------------------ //
  private val IDWidth_o = axi4Params.idBits // For remapper, input ID is wider than output ID
  // --------------------- Constant Calculation ------------------------ //
  private val counterNum   = pow(2, IDWidth_o).toInt
  private val counterWidth = log2Up(maxTxnNum)
  private val IDWidth_i    = IDWidth_o + log2Up(spNum)

// ------------------------------------------ IO Declaration ---------------------------------------------- //
  val io = IO(new Bundle {
    // Push will increase ID Counter (Push the same cycle as query successful?)
    val push = new Bundle {
      val id      = Input(UInt(IDWidth_i.W)) // The ID to be pushed
      val en      = Input(Bool())

      val rmpID   = Output(UInt(IDWidth_o.W)) // remapped ID
    }

    // Pop will decrease ID Counter
    val pop = new Bundle {
      val id      = Input(UInt(IDWidth_o.W)) // The ID to be popped
      val en      = Input(Bool())

      val orgID   = Output(UInt(IDWidth_i.W)) // get the original ID
    }

    // TODO: inject for ATOP

    // Query whether the ID is occupied by other Txn targeting different master port
    val query = new Bundle {
      val id      = Input (UInt(IDWidth_i.W))
      val forward = Output(Bool()) 
    }
    
    
  })

// ------------------------------------------ Declarations ---------------------------------------------- //
  // --------------------- Module declaration ------------------------ //
  val idCounters = Seq.fill(counterNum) { Module(new DeltaCounter(counterWidth, true)) } // each ID has a counter

  // --------------------- Wire/Reg declaration ------------------------ //
  val table = Reg(Vec(counterNum, UInt(IDWidth_i.W))) // _GEN_3

  val inTables  = Wire(Vec(counterNum, Bool())) // represent whether the queried ID is in table. If is in, which blank does it occupied.
  val Fulls     = Wire(Vec(counterNum, Bool())) // represent whether each ID Counter is full 
  val Empties   = Wire(Vec(counterNum, Bool())) // represent whether each ID Counter is empty
  val Occupies  = Wire(Vec(counterNum, Bool())) // represent whether each ID Counter is occupied

  val enPushOH = WireInit(0.U(counterNum.W)) // There should be only one txn push or pop at the same time, so we use OH to describe it.
  val enPopOH  = WireInit(0.U(counterNum.W))

// ------------------------------------------ Main Logics ---------------------------------------------- //
  // --------------------- Query ------------------------ //
  table.zipWithIndex.foreach {
    case (t, i) =>
      // To deal with optional empty. TODO: solve this
      idCounters(i).io.out.empty.foreach {emp => 
        Empties (i) := emp
        Occupies(i) := !emp
      }
      inTables(i) := (t === io.query.id) && !Empties(i) // counter not empty and query id in table means query id is in table
      Fulls   (i) := idCounters(i).io.out.full
      
  }

  io.query.forward := ((!inTables.reduce(_ || _) && !Occupies.reduce(_ && _)) // not in table and there is space
                   ||  (inTables.reduce(_ || _)) && !Fulls(OHToUInt(inTables.asUInt)))  // in table and that blank of table is not full

  // --------------------- Push ------------------------ //
  when (io.push.en) {
    // Get remapped ID
    when (!inTables.reduce(_ || _)) { // Not in table
      io.push.rmpID := PriorityEncoder(~Occupies.asUInt) // find the smallest empty ID
      table(io.push.rmpID) := io.push.id
    } .otherwise { // In table
      io.push.rmpID := OHToUInt(inTables.asUInt)
    }
  } .otherwise {
    io.push.rmpID := 0.U
  }

  enPushOH := Mux(io.push.en, 1.U << io.push.rmpID, 0.U)
  

  // --------------------- Pop ------------------------ //
  // io.pop.orgID shouldn't be decided by pop en, because that will cause combinational cycle.
  // io.pop.orgID can decide mux b channel output ready, so that io.pop.orgID shouldn't be decided by pop en (mux b channel output handshake).
  io.pop.orgID := table(io.pop.id)

  enPopOH  := Mux(io.pop.en, 1.U << io.pop.id, 0.U)


  // --------------------- ID count ------------------------ //
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
  }

  // ------------------------------------------  Assertions ---------------------------------------------- //
  // TODO: inTable should be OneHot.

}

object IDRemapper {
  def wrapper(in: Axi4Bundle, out: Axi4Bundle, spNum: Int, maxTxnNum: Int, axi4Params: AXI4Params): Unit = {
    // conn all first 
    out <> in

  // ------------------------------------------ Declarations ---------------------------------------------- //
    // --------------------- Module declaration ------------------------ //
    val wrRmp = Module(new IDRemapper(spNum, maxTxnNum, axi4Params))
    val rdRmp = Module(new IDRemapper(spNum, maxTxnNum, axi4Params))

  // ------------------------------------------ Main Logics ---------------------------------------------- //
    // --------------------- Write Remapper ------------------------ //
    IDRemapper.conn_push(in .aw, out.aw, wrRmp)
    IDRemapper.conn_pop (out.b , in .b , wrRmp)

    // --------------------- Read Remapper ------------------------ //
    IDRemapper.conn_push(in .ar, out.ar, rdRmp)
    IDRemapper.conn_pop (out.r , in .r , rdRmp, false)
    rdRmp.io.pop.en := in.r.fire && in.r.bits.last // for read, pop when last occurs.
  }

  def conn_push[T <: AddrReqFlitBase](req_i: DecoupledIO[T], req_o: DecoupledIO[T], remapper: IDRemapper): Unit = {
    val allowPush = WireInit(false.B)
    // Query
    remapper.io.query.id := req_i.bits.id
    allowPush            := remapper.io.query.forward

    // Push
    remapper.io.push.id  := req_i.bits.id
    remapper.io.push.en  := req_o.fire
    req_o.bits.id   := remapper.io.push.rmpID

    // handshake
    req_o.valid := req_i.valid && allowPush
    req_i.ready := req_o.ready && allowPush
  }

  def conn_pop[T <: RespFlitBase](resp_i: DecoupledIO[T], resp_o: DecoupledIO[T], remapper: IDRemapper, isWr: Boolean = true): Unit = {
    remapper.io.pop.id := resp_i.bits.id
    if (isWr) {
      remapper.io.pop.en := resp_o.fire 
    }
    resp_o.bits.id     := remapper.io.pop.orgID
  }
}