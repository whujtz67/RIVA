package vlsu

import chisel3._
import chisel3.util._

object VecMemOp {
  val INCR = 0.U
  val STRD = 1.U
  val RM2D = 2.U // row major 2D
  val CM2D = 3.U // cln major 2D
}

object MtxMemOp {

}