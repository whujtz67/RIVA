package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters

// -------------------------------
// VM Address Bundle
// -------------------------------
class VAddrBundle(implicit p: Parameters) extends VLSUBundle {
  val set  = UInt(log2Ceil(vmSramDepth).W) // MSB
  val bank = UInt(log2Ceil(NrVmBanks).W)   // LSB

  def init(vd: UInt, vstart: UInt, eew: UInt): Unit = {
    val setPerVReg = VLEN / NrLanes / SLEN / NrVmBanks
    val setPerAReg = ALEN / NrLanes / SLEN / NrVmBanks
    val aregBaseSet = setPerVReg * NrVregs
    val vd_msb = log2Ceil(NrVregs)

    val vd_base_set: UInt = Mux(
      vd(vd_msb),
      aregBaseSet.U + (vd(vd_msb - 1, 0) << log2Ceil(setPerAReg)).asUInt,
      (vd(vd_msb - 1, 0) << log2Ceil(setPerVReg)).asUInt
    )
    // vstart elem index in the targeted vector/accumulator regfile
    val start_elem_in_vd = vstart >> log2Ceil(NrLanes)

    // The initialization logic is the same as ara.
    require(eew.getWidth == 2, "We only support eew.getWidth == 2! Otherwise, there will be errors when calculating (b11.U(2.W) - eew).")
    this := (vd_base_set + (start_elem_in_vd >> ("b11".U(2.W) - eew)).asUInt).asTypeOf(this)

    assert(this.set < vmSramDepth.U)
    assert(this.bank < NrVmBanks.U)
  }
}

// --------------------------------
// Memory Access Req
// --------------------------------
class RivaReqFull(implicit p: Parameters) extends VLSUBundle {
  val reqId    = UInt(reqIdBits.W)
  val mop      = UInt( 2.W)
  val baseAddr = UInt(axi4Params.addrBits.W) // scalar op
  val eew      = UInt( 2.W)
  val vd       = UInt( 5.W)
  val stride   = UInt(axi4Params.addrBits.W) // rs2/imm5
  val al       = UInt(log2Ceil(ALEN).W)
  val vl       = UInt(log2Ceil(VLEN).W)
  val tilen    = UInt(tilenBits.W)
  val vstart   = UInt(log2Ceil(VLEN).W)
  val isLoad   = Bool()
  val vm       = Bool() // consider mask or not?   false.B: consider true.B: not consider
}

class RivaReqPtl(implicit p: Parameters) extends VLSUBundle {
  val reqId    = UInt(reqIdBits.W)
  val mop      = UInt( 2.W)
  val baseAddr = UInt(axi4Params.addrBits.W) // scalar op
  val eew      = UInt( 2.W)
  val vd       = UInt( 5.W)
  val stride   = UInt(axi4Params.addrBits.W) // rs2/imm5
  val len      = UInt(log2Ceil(maxNrElems).W) // Length, it equals alen when requesting AM and vlen when requesting VM.
  val vstart   = UInt(log2Ceil(maxNrElems).W)
  val isLoad   = Bool()
  val vm       = Bool()

  def init(full: RivaReqFull): Unit = {
    this.reqId    := full.reqId
    this.mop      := full.mop
    this.baseAddr := full.baseAddr
    this.eew      := full.eew
    this.vd       := full.vd
    this.stride   := full.stride
    this.len      := Mux(full.vd(4), full.al, full.vl)
    this.vstart   := full.vstart
    this.isLoad   := full.isLoad
    this.vm       := full.vm
  }

  def getEW: UInt = (1.U << (this.eew + 2.U)).asUInt
}

class VecMopOH extends Bundle {
  val cln2D = Bool() // cln major: MSB
  val row2D = Bool() // row major
  val Strd  = Bool()
  val Incr  = Bool() // LSB

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
  val nbe   = UInt((SLEN/4).W) // half byte enable

  // Generally, we choose to define I/O signals as complete UInt types to minimize the number of generated I/O signals and simplify connections with external modules.
  // However, internally, we typically split UInt signals into Vec to enable finer-grained processing.
  // This will reduce about 3000 lines in generated verilog file when NrLanes = 8.
  // The same principle applies to RxLane.
  def nbs : Vec[UInt] = this.data.asTypeOf(Vec(SLEN/4, UInt(4.W)))
  def nbes: Vec[Bool] = this.nbe.asTypeOf(Vec(SLEN/4, Bool()))
}

class RxLane(implicit p: Parameters) extends VLSUBundle {
  val data = UInt(SLEN.W)

  def nbs : Vec[UInt] = this.data.asTypeOf(Vec(SLEN/4, UInt(4.W)))
}

class LaneSide(implicit p: Parameters) extends VLSUBundle {
  val txs = Vec(NrLanes, Decoupled(new TxLane()))
  val rxs = Vec(NrLanes, Flipped(Decoupled(new RxLane())))
}

