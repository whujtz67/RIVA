package protocols.AXI.spec

import chisel3._
import chisel3.util.{Decoupled, DecoupledIO}

// -------------------------------------
// Standard AXI4
// -------------------------------------
//
// Abstract Classes
//
abstract class RespFlitBase extends Bundle {
  val id     : UInt
  val resp   : UInt
}

abstract class AddrReqFlitBase extends Bundle {
  val id     : UInt
  val addr   : UInt
}

abstract class AbstrAxi4Bundle extends Bundle {
  val aw: Data
  val w : Data
  val b : Data
  val ar: Data
  val r : Data
}

//
// Classes
//
case class AXI4Params(
                      addrBits: Int = 32 ,
                      idBits  : Int = 4  , // should not be too large. Otherwise, there will be too many ID Counters in mesh.
                      userBits: Int = 0  ,
                      dataBits: Int = 512
                    ) {
  val maxTxnBytes = 4096

  override def toString: String = {
    s"""
		|   Addr Width: $addrBits
		|   ID   Width: $idBits
    |   Data Width: $dataBits
		|   User Width: $userBits\n }
		|""".stripMargin
  }
}

class AxFlit(params: AXI4Params) extends AddrReqFlitBase {
  val id     = UInt(params.idBits.W)
  val addr   = UInt(params.addrBits.W)
  val len    = UInt(8.W)
  val size   = UInt(3.W)
  val burst  = UInt(2.W)
  val lock   = UInt(2.W)
  val cache  = UInt(4.W)
  val prot   = UInt(3.W)
  val qos    = UInt(4.W)
  val region = UInt(4.W)
  val user   = UInt(params.userBits.W)

  def set(
    id    : UInt = 0.U,
    addr  : UInt = 0.U,
    len   : UInt = 0.U,
    size  : UInt = 0.U,
    burst : UInt = 0.U,
    cache : UInt = 0.U
  ): Unit = {
    this.id     := id
    this.addr   := addr
    this.len    := len
    this.size   := size
    this.burst  := burst
    this.lock   := 0.U  // always 0 for AXI4
    this.cache  := cache
    this.prot   := 0.U
    this.qos    := 0.U
    this.region := 0.U
    this.user   := 0.U
  }
}

class AWFlit(params: AXI4Params) extends AxFlit(params)

class ARFlit(params: AXI4Params) extends AxFlit(params)

class WFlit(params: AXI4Params) extends Bundle {
  val data   = UInt(params.dataBits.W)
  val strb   = UInt((params.dataBits / 8).W)
  val last   = Bool()
  val user   = UInt(params.userBits.W)
}

class RFlit(params: AXI4Params) extends RespFlitBase {
  val id     = UInt(params.idBits.W)
  val data   = UInt(params.dataBits.W)
  val resp   = UInt(2.W)
  val last   = Bool()
  val user   = UInt(params.userBits.W)
}

class BFlit(params: AXI4Params) extends RespFlitBase {
  val id     = UInt(params.idBits.W)
  val resp   = UInt(2.W)
  val user   = UInt(params.userBits.W)
}

class Axi4Bundle(val params: AXI4Params) extends AbstrAxi4Bundle {
  val aw     =         Decoupled(new AWFlit(params)) // bits are OutPut
  val ar     =         Decoupled(new ARFlit(params))
  val w      =         Decoupled(new WFlit (params))
  val b      = Flipped(Decoupled(new BFlit (params)))
  val r      = Flipped(Decoupled(new RFlit (params)))
}

// bidirectional Axi4Bundle
class BidAxi4Bundle(params: AXI4Params, hasMp: Boolean = true, hasSp: Boolean = true, mpName: Option[String] = None, spName: Option[String] = None) extends Bundle{
  val mp = if (hasMp) Some(new Axi4Bundle(params)) else None
  val sp = if (hasSp) Some(Flipped(new Axi4Bundle(params))) else None
}

// Flexible AXI4Bundle
class FlexAxi4Bundle[awT <: Bundle, wT <: Bundle, bT <: Bundle, arT <: Bundle, rT <: Bundle](
  genAW: awT,
  genW : wT ,
  genB : bT ,
  genAR: arT,
  genR : rT
) extends Bundle {
  val aw =         Decoupled(genAW)  // bits are OutPut
  val ar =         Decoupled(genW )
  val w  =         Decoupled(genB )
  val b  = Flipped(Decoupled(genAR))
  val r  = Flipped(Decoupled(genR ))
}



// -------------------------------------
// Protocol Correctness Check for AXI4
// -------------------------------------
object AXI4ProtocolCheck {
  def checkStableValid(valid: Bool, ready: Bool, name: String) = {
    val validLastCycle = RegNext(valid)
    when (validLastCycle && !ready) {
      assert(valid === true.B, s"Channel $name valid is deasserted when ready = 0")
    }
  }

  def checkStableBits[T <: Bundle](bits: T, valid: Bool, ready: Bool, name: String) = {
    val bitsLastCycle = RegNext(bits)
    when (valid && !ready) {
      assert(bitsLastCycle === bits, s"Channel $name bits are unstable with valid set")
    }
  }
}