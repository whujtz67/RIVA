package protocols.AXI.spec

import chisel3._

object Burst {
  val width = 2

  val Fixed = "b00".U(width.W)
  val Incr  = "b01".U(width.W)
  val Wrap  = "b10".U(width.W)
  val Rsvd  = "b11".U(width.W)
}

object Cache {
  val width = 4

  // TODO: There are still other states
  val AllDisable = "b0000".U(width.W)
  val Bufferable = "b0001".U(width.W)
  val Modifiable = "b0010".U(width.W)
  val RdAlloc    = "b0100".U(width.W)
  val WrAlloc    = "b1000".U(width.W)
}

object Prot {
  // TODO
}

object Resp {
  val width = 2

  val Okay   = "b00".U(width.W)
  val ExOkay = "b01".U(width.W)
  val SlvErr = "b10".U(width.W)
  val DecErr = "b11".U(width.W)
}