package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters

// -------------------------------
// VM Address Bundle
// -------------------------------
class VecAddrBundle(implicit p: Parameters) extends VLSUBundle {
  val set  = UInt(log2Ceil(bankDep).W)
  val bank = UInt(log2Ceil(bankNum).W)
}

// --------------------------------
// Memory Access Req
// --------------------------------
class RivaReqFull(implicit p: Parameters) extends VLSUBundle {
  val reqId    = UInt(reqIdBits.W)
  val mop      = UInt( 2.W)
  val baseAddr = UInt(axi4Params.addrBits.W)
  val wid      = UInt( 2.W)
  val vd       = UInt( 5.W)
  val stride   = UInt(32.W) // rs2/imm5
  val al       = UInt(log2Ceil(ALEN).W)
  val vl       = UInt(log2Ceil(VLEN).W)
  val tilen    = UInt(tilenBits.W)
  val vstart   = UInt(log2Ceil(VLEN).W)
  val isLoad   = Bool()
}

class RivaReqPtl(implicit p: Parameters) extends VLSUBundle {
  val reqId    = UInt(reqIdBits.W)
  val mop      = UInt( 2.W)
  val baseAddr = UInt(axi4Params.addrBits.W)
  val wid      = UInt( 2.W)
  val vd       = UInt( 5.W)
  val stride   = UInt(32.W) // rs2/imm5
  val len      = UInt(log2Ceil(maxNrElems).W) // Length, it equals alen when requesting AM and vlen when requesting VM.
  val tilen    = UInt(tilenBits.W)
  val vstart   = UInt(log2Ceil(VLEN).W)
  val isLoad   = Bool()

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
  }

  def getEW: UInt = (1.U << (this.wid + 2.U)).asUInt
}

// TODO: 这些好像不需要了
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

// --------------------------------
// CSR
// --------------------------------
class CsrBundle(implicit p: Parameters) extends VLSUBundle {
  private val lenBits = log2Ceil(VLEN)

  val vlen   = UInt(lenBits.W) // For VM
  val alen   = UInt(lenBits.W) // For AM
  val tilen  = UInt(log2Ceil(maxTilen).W) // We don't need so many bits as vlen and alen
  val vstart = UInt(log2Ceil(NrLanes ).W)
}

class VecMopOH extends Bundle {
  val isIncr = Bool()
  val isStrd = Bool()
  val rmTwoD = Bool() // row major
  val cmTwoD = Bool() // cln major

  def isOH(): Bool = PopCount(this.asUInt) === 1.U

  def is2D: Bool = this.rmTwoD || this.cmTwoD
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

// --------------------------------
// Data Control Bundle
// --------------------------------
class DataCtrlBundle(implicit p: Parameters) extends VLSUBundle {
  val meta = new MetaCtrlInfo()
  val axi  = new AxiCtrlInfo()
}

// --------------------------------
// Lane Load and Store Bundle
// --------------------------------
class LoadLaneSide(implicit p: Parameters) extends VLSUBundle {
  val reqId   = UInt(reqIdBits.W)
  val vecAddr = UInt(new VecAddrBundle()(p).getWidth.W)
  val data    = UInt(SLEN.W)
  val hbe     = UInt((SLEN/8).W) // half byte enable

  def vaddr: VecAddrBundle = this.vecAddr.asTypeOf(new VecAddrBundle()(p))
}

class StoreLaneSide(implicit p: Parameters) extends VLSUBundle {
  val data = UInt(SLEN.W)
}

class LaneSide(implicit p: Parameters) extends VLSUBundle {
  val tx = Decoupled(new LoadLaneSide)
  val rx = Flipped(Decoupled(new StoreLaneSide))
}

