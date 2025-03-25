package Utils

import chisel3._


// Delta Counter can do not only +1, but can plus or subtract any num (delta).
// TODO: maybe put this in utils, this Module might not extends MeshModule, Because it might be used in somewhere beside Mesh.
class DeltaCounter(width: Int, hasEmp: Boolean = false) extends Module {
  val io = IO(new Bundle {
    val in = new Bundle {
      val en       = Input(Bool())         // enable counter
      val decr     = Input(Bool())         // count down, default is up
      val delta    = Input(UInt(width.W))
    }

    val out = new Bundle {
      val nowCount = Output(UInt(width.W)) // current Count
      val full     = Output(Bool())        // Has reached Maximum count

      val empty = if (hasEmp) Some(Output(Bool())) else None
    }
  })

  val count    = RegInit(0.U(width.W))
  //  val maxCount = ((1 << width) - 1).U


  when (io.in.en) {
    when(io.in.decr) {
      count := count - io.in.delta
    }.otherwise {
      count := count + io.in.delta
    }
  }

  io.out.nowCount := count
  io.out.full     := count.andR // every bit is 1 when full
  
  // foreach can deal with Option type signal properly.
  io.out.empty.foreach {emp =>
    emp := !count.orR
  }

  // ------------------------------------------  Assertions ---------------------------------------------- //
  assert(!(io.out.full && io.in.en && !io.in.decr), "Error: full and push en should not be high at the same time")
  // TODO：suppor delta > 1 (should deal with overflow, can learn from pulp platform)(那个对overflow的处理其实不本质，因为它只考虑了delta = 2的情况)
  assert(io.in.delta <= 1.U, "Error: We dont support delta > 1 by now, it will be supported in the future")

  assert(!(!count.orR && io.in.decr), "Error: decr when count = 0!")
}