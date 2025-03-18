package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters

// --------------------------------
// Memory Access Req
// --------------------------------
class RivaReqBase extends Bundle {
  val id       = UInt( 1.W) // TODO: width?
  val mop      = UInt( 2.W) // memory access type
  val baseAddr = UInt(32.W) // rs1
  val wid      = UInt( 3.W) // TODO：2 bits or 3 bits?
  val stride   = UInt(32.W) // rs2/imm5
  val isLoad   = Bool()
  val isMatrix = Bool()     // Vector Type or Matrix Type

  def isUnitStrd: Bool = this.mop === VecMemOp.INCR

  def getEW     : UInt = (1.U << (this.wid + 2.U)).asUInt

  def getSize: UInt = Mux(!this.mop(1), 0.U, Mux(this.mop === 2.U, 1.U, 2.U))
}

class RivaReqVec extends Bundle {
  val destIdx  = UInt(5.W) // destination register Index, vd is 0-15, ad is 16-31
}

class RivaReqMtx extends Bundle {
  val fpad    = Bool()
  val bpad    = Bool()
  val pad     = UInt(2.W) // pad value
  val mregIdx = UInt(2.W) // matrix reg Index
}

class RivaReq extends Bundle {
  val base = new RivaReqBase()
  val vec  = new RivaReqVec()
  val mtx  = new RivaReqMtx()
}

// --------------------------------
// CSR
// --------------------------------
class CsrBundle(implicit p: Parameters) extends VLSUBundle {
  private val lenBits = log2Ceil(VLEN)

  val vlen   = UInt(lenBits.W) // For VM
  val alen   = UInt(lenBits.W) // For AM
  val tilen  = UInt(log2Ceil(maxTilen).W) // We don't need so many bits as vlen and alen
  val vstart = UInt(log2Ceil(laneNum ).W)
}

class VecMopOH extends Bundle {
  val isIncr = Bool()
  val isStrd = Bool()
  val rmTwoD = Bool() // row major
  val cmTwoD = Bool() // cln major

  def isOH(): Bool = PopCount(this.asUInt) === 1.U

  def is2D: Bool = this.rmTwoD || this.cmTwoD

  def decode(req: RivaReq, valid: Bool): Unit = {
    val mop = req.base.mop

    this.isIncr := mop === 0.U
    this.isStrd := mop === 1.U
    this.rmTwoD := mop === 2.U
    this.cmTwoD := mop === 3.U

    when(valid) {
      assert(PopCount(this.asUInt) === 1.U, "mopOH should be OneHot!")
    }
  }
}

class AGUReq(implicit p: Parameters) extends VLSUBundle {
  val baseAddr = UInt(axi4Params.addrBits.W)
  val stride   = UInt(32.W)                        // in units of bytes
  val size     = UInt(3.W)                         // for aligning only
  val totBeat  = UInt(log2Ceil(maxTxnPerReq).W)    // It is not the Ax len, it is the num of Ax Req needed to finish a memory access Req. TODO: find a better Name.
  val mopOH    = new VecMopOH
}

class AGUResp(implicit p: Parameters) extends VLSUBundle {
  val addr   = UInt(axi4Params.addrBits.W)
  val offset = UInt(log2Ceil(busBytes).W)
  val last   = Bool() // TODO: maybe put the counter in CM?
}