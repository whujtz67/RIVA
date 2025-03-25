package Utils

import chisel3._
import chisel3.util._

abstract class FastArbiterBase[T <: Data](val gen: T, val n: Int) extends Module {
  val io = IO(new ArbiterIO[T](gen, n))

  // Convert the mask to one-hot encoding by retaining only the lowest bit that is set to 1.
  // e.g. mask 0101 0110 1100 ...
  //      OH   0001 0010 0100 ...
  def maskToOH(seq: Seq[Bool]) = {
    seq.zipWithIndex.map{
      case (b, 0) => b
      case (b, i) => b && !Cat(seq.take(i)).orR
    }
  }
}

class FastArbiter[T <: Data](gen: T, n: Int) extends FastArbiterBase[T](gen, n) {

  val chosenOH = Wire(UInt(n.W))
  val valids = VecInit(io.in.map(_.valid)).asUInt
  // Save the requests that are valid but we didn't choose in last cycle in 'pendingMask'
  val pendingMask = RegEnable(
    valids & (~chosenOH).asUInt, // make IDEA happy ...
    0.U(n.W),
    io.out.fire
  )
  // select a req from pending reqs by RR
  /*
       chosenOH     0001 0010 0100 1000
       rrGrantMask  1110 1100 1000 0000
   */
  val rrGrantMask = RegEnable(VecInit((0 until n) map { i =>
    if(i == 0) false.B else chosenOH(i - 1, 0).orR
  }).asUInt, 0.U(n.W), io.out.fire)
  val rrSelOH = VecInit(maskToOH((rrGrantMask & pendingMask).asBools)).asUInt
  val firstOneOH = VecInit(maskToOH(valids.asBools)).asUInt
  val rrValid = (rrSelOH & valids).orR
  chosenOH := Mux(rrValid, rrSelOH, firstOneOH)

  io.out.valid := valids.orR
  io.out.bits := Mux1H(chosenOH, io.in.map(_.bits))

  io.in.map(_.ready).zip(chosenOH.asBools).foreach{
    case (rdy, grant) => rdy := grant && io.out.ready
  }

  io.chosen := OHToUInt(chosenOH)

}

/**
 * 'Dec' means DecoupledIO
 * 'Val' means ValidIO. In ValidIO, ready is always high.
 */
object FastArb {
  def fastArbDec2Dec[T <: Bundle](in: Seq[DecoupledIO[T]], out: DecoupledIO[T], name: Option[String] = None): Unit = {
    val arb = Module(new FastArbiter[T](chiselTypeOf(out.bits), in.size))
    if (name.nonEmpty) {
      arb.suggestName(s"${name.get}_arb")
    }
    for ((a, req) <- arb.io.in.zip(in)) {
      a <> req
    }
    out <> arb.io.out
  }

  def fastArbDec[T <: Bundle](in: Seq[DecoupledIO[T]], name: Option[String] = None): DecoupledIO[T] = {
    val arb = Module(new FastArbiter[T](chiselTypeOf(in(0).bits), in.size))
    if (name.nonEmpty) {
      arb.suggestName(s"${name.get}_arb")
    }
    for ((a, req) <- arb.io.in.zip(in)) {
      a <> req
    }
    arb.io.out
  }

  def fastArbDec2Val[T <: Bundle](in: Seq[DecoupledIO[T]], out: ValidIO[T], name: Option[String] = None): Unit = {
    val arb = Module(new FastArbiter[T](chiselTypeOf(out.bits), in.size))
    if (name.nonEmpty) {
      arb.suggestName(s"${name.get}_arb")
    }
    for ((a, req) <- arb.io.in.zip(in)) {
      a <> req
    }
    arb.io.out.ready := true.B
    out.bits := arb.io.out.bits
    out.valid := arb.io.out.valid
  }

  def fastPriorityArbDec2Val[T <: Bundle](in: Seq[DecoupledIO[T]], out: ValidIO[T], name: Option[String] = None): Unit = {
    val arb = Module(new Arbiter[T](chiselTypeOf(out.bits), in.size))
    if (name.nonEmpty) {
      arb.suggestName(s"${name.get}_arb")
    }
    for ((a, req) <- arb.io.in.zip(in)) {
      a <> req
    }
    arb.io.out.ready := true.B
    out.bits := arb.io.out.bits
    out.valid := arb.io.out.valid
  }

  def fastPriorityArbDec[T <: Bundle](in: Seq[DecoupledIO[T]], name: Option[String] = None): DecoupledIO[T] = {
    val arb = Module(new Arbiter[T](chiselTypeOf(in(0).bits), in.size))
    if (name.nonEmpty) {
      arb.suggestName(s"${name.get}_arb")
    }
    for ((a, req) <- arb.io.in.zip(in)) {
      a <> req
    }
    arb.io.out
  }
}