package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters

// -------------------------------
// VM Address Bundle
// -------------------------------
class VAddrBundle(implicit p: Parameters) extends VLSUBundle {
  val set  = UInt(log2Ceil(bankDep).W)
  val bank = UInt(log2Ceil(bankNum).W)

  def init(meta: MetaBufBundle): Unit = {
    val setPerVReg = VLEN / NrLanes / SLEN / bankNum
    val setPerAReg = ALEN / NrLanes / SLEN / bankNum
    val aregBaseSet = setPerVReg * 16

    this.set := Mux(
      meta.vd(4),
      aregBaseSet.U + (meta.vd << log2Ceil(setPerAReg)).asUInt + (meta.vstart >> log2Ceil(bankNum)).asUInt,
      (meta.vd << log2Ceil(setPerVReg)).asUInt + (meta.vstart >> log2Ceil(bankNum)).asUInt
    )
    this.bank := meta.vstart(log2Ceil(bankNum) - 1, 0)
  }
}

// --------------------------------
// Memory Access Req
// --------------------------------
class RivaReqFull(implicit p: Parameters) extends VLSUBundle {
  val reqId    = UInt(reqIdBits.W)
  val mop      = UInt( 2.W)
  val baseAddr = UInt(axi4Params.addrBits.W) // scalar op
  val wid      = UInt( 2.W)
  val vd       = UInt( 5.W)
  val stride   = UInt(axi4Params.addrBits.W) // rs2/imm5
  val al       = UInt(log2Ceil(ALEN).W)
  val vl       = UInt(log2Ceil(VLEN).W)
  val tilen    = UInt(tilenBits.W)
  val vstart   = UInt(log2Ceil(VLEN).W)
  val isLoad   = Bool()
  val vm       = Bool() // consider mask or not?        false.B: consider true.B: not consider
}

class RivaReqPtl(implicit p: Parameters) extends VLSUBundle {
  val reqId    = UInt(reqIdBits.W)
  val mop      = UInt( 2.W)
  val baseAddr = UInt(axi4Params.addrBits.W) // scalar op
  val wid      = UInt( 2.W)
  val vd       = UInt( 5.W)
  val stride   = UInt(axi4Params.addrBits.W) // rs2/imm5
  val len      = UInt(log2Ceil(maxNrElems).W) // Length, it equals alen when requesting AM and vlen when requesting VM.
  val tilen    = UInt(tilenBits.W)
  val vstart   = UInt(log2Ceil(maxNrElems).W)
  val isLoad   = Bool()
  val vm       = Bool()

  def init(full: RivaReqFull): Unit = {
    this.reqId    := full.reqId
    this.mop      := full.mop
    this.baseAddr := full.baseAddr
    this.wid      := full.wid
    this.vd       := full.vd
    this.stride   := full.stride
    this.len      := Mux(full.vd(4), full.al, full.vl)
    this.tilen    := full.tilen
    this.vstart   := full.vstart
    this.isLoad   := full.isLoad
    this.vm       := full.vm
  }

  def getEW: UInt = (1.U << (this.wid + 2.U)).asUInt
}

class VecMopOH extends Bundle {
  val Incr  = Bool()
  val Strd  = Bool()
  val row2D = Bool() // row major
  val cln2D = Bool() // cln major

  def isOH: Bool = PopCount(this.asUInt) === 1.U

  def is2D: Bool  = this.row2D || this.cln2D

  def isGather: Bool = false.B // We currently don't support gather mode.
}

// --------------------------------
// Lane Load and Store Bundle
// --------------------------------
// TODO: splitFlit
class TxLane(implicit p: Parameters) extends VLSUBundle {
  require(SLEN % 4 == 0, "SLEN must be divisible by 4")

  val reqId = UInt(reqIdBits.W) // TODO: 其实并不需要所有lane都给reqId和vaddr，因为都是相同的
  val vaddr = new VAddrBundle()
  val data  = UInt(SLEN.W)
  val hbe   = UInt((SLEN/4).W) // half byte enable

  // Generally, we choose to define I/O signals as complete UInt types to minimize the number of generated I/O signals and simplify connections with external modules.
  // However, internally, we typically split UInt signals into Vec to enable finer-grained processing.
  // This will reduce about 3000 lines in generated verilog file when NrLanes = 8.
  // The same principle applies to RxLane.
  def hbs : Vec[UInt] = this.data.asTypeOf(Vec(SLEN/4, UInt(4.W)))
  def hbes: Vec[Bool] = this.hbe.asTypeOf(Vec(SLEN/4, Bool()))
}

class RxLane(implicit p: Parameters) extends VLSUBundle {
  val data = UInt(SLEN.W)

  def hbs : Vec[UInt] = this.data.asTypeOf(Vec(SLEN/4, UInt(4.W)))
}

class LaneSide(implicit p: Parameters) extends VLSUBundle {
  val txs = Vec(NrLanes, Decoupled(new TxLane()))
  val rxs = Vec(NrLanes, Flipped(Decoupled(new RxLane())))
}

