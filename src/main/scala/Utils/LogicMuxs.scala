package Utils

import chisel3._
import chisel3.util._
import freechips.rocketchip.rocket.CSRs.instret

// --------------------------------------------
// The basic logic of an 1-N De-multiplexer
// --------------------------------------------
class LogicDemux[T <: Bundle](gen: T, mstPortNum: Int, chnl: Option[String] = None) extends Module {
  private val selWidth = mstPortNum

  private val myName = if (chnl.nonEmpty) {
    s"LogicDemux_${chnl.get}"
  } else {
    super.desiredName
  }
  override def desiredName: String = myName

// --------------------- IO declaration ------------------------//
  val io = IO(new Bundle {
    val in = new Bundle {
      val slvPort  = Flipped(Decoupled(gen))
      val sel      = Input(UInt(selWidth.W))
    }

    val out = new Bundle {
      val mstPorts = Vec(mstPortNum, Decoupled(gen))
    }
  })

  val readys = Seq.fill(mstPortNum) {WireInit(false.B)}
// --------------------- Logics --------------------------- //
  // Connection
  io.out.mstPorts.zipWithIndex.foreach {
    case (mp, i) =>
      // bits connection
      mp.bits := io.in.slvPort.bits  // Always connect the bits together, using valid to control the routing logic

      // valid connection
      when (io.in.slvPort.valid && io.in.sel(i)) { // should be valid here instead of fire because valid should Not be decided by ready
        mp.valid := true.B
      } .otherwise {
        mp.valid := false.B
      }

      readys(i) := mp.ready && io.in.sel(i)
  }

  // ready connection, the Demux slave port ready is decided by the selected master port ready.
  io.in.slvPort.ready := readys.reduce(_ || _)

}

// --------------------------------------------
// The basic logic of an N-1 Multiplexer
// --------------------------------------------
class LogicMux[T <: Bundle](gen: T, slvPortNum: Int, chnl: Option[String] = None) extends Module {
  // Note that sel is no longer a one-hot code here, 
  // because the Mux receives the sel signal as the higher bits of the AW transaction ID, 
  // which represents the port number.
  private val selWidth = log2Up(slvPortNum)

  private val myName = if (chnl.nonEmpty) {
    s"LogicMux_${chnl.get}"
  } else {
    super.desiredName
  }
  override def desiredName: String = myName

  // --------------------- IO declaration ------------------------//
  val io = IO(new Bundle {
    val in = new Bundle {
      val slvPorts  = Vec(slvPortNum, Flipped(Decoupled(gen)))
      val sel       = Input(UInt(selWidth.W))
    }

    val out = new Bundle {
      val mstPort = Decoupled(gen)
    }
  })

  // --------------------- Logics --------------------------- //
  // Connection
  io.in.slvPorts.zipWithIndex.foreach {
    case (sp, i) =>

      // valid connection
      when (io.in.sel === i.U) { // should be valid here instead of fire because valid should Not be decided b
        sp.ready := io.out.mstPort.ready
      } .otherwise {
        sp.ready := false.B
      }

  }

  io.out.mstPort.bits  := io.in.slvPorts(io.in.sel).bits
  io.out.mstPort.valid := io.in.slvPorts(io.in.sel).valid

}

object LogicDemux {
  def conn_selOH[T <: Bundle](in: DecoupledIO[T], outs: Seq[DecoupledIO[T]], sel: Bits, chnl: Option[String] = None): Unit = {
    val demux = Module(new LogicDemux[T](chiselTypeOf(in.bits), outs.size, chnl))

    demux.io.in.slvPort <> in
    demux.io.in.sel     := sel

    demux.io.out.mstPorts.zip(outs).foreach {
      case (dout, out) =>
        out <> dout // <> will do ID Truncate automatically if width of in.addr > outs(i).addr
    }
  }

  def conn_selUInt[T <: Bundle](in: DecoupledIO[T], outs: Seq[DecoupledIO[T]], sel: UInt, chnl: Option[String] = None): Unit = {
    LogicDemux.conn_selOH(in, outs, UIntToOH(sel), chnl)
  }
}

object LogicMux {
  def conn_selUInt[T <: Bundle](ins: Seq[DecoupledIO[T]], out: DecoupledIO[T], sel: UInt, chnl: Option[String] = None): Unit = {
    val mux = Module(new LogicMux[T](chiselTypeOf(out.bits), ins.size, chnl))

    out <> mux.io.out.mstPort
    mux.io.in.sel := sel

    mux.io.in.slvPorts.zip(ins).foreach {
      case (min, in) =>
        min <> in
    }
  }
}