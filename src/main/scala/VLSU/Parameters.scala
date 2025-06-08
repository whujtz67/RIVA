package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.{Field, Parameters}
import protocols.AXI.spec.AXI4Params

case object  VLSUParametersKey extends Field[VLSUParamters]

case class VLSUParamters(
  NrLanes   : Int = 4,
  NrVInsns  : Int = 8,
  NrVregs   : Int = 16,
  NrAregs   : Int = 16,
  NrVmBanks : Int = 8,
  SLEN      : Int = 128,    // slice len, lane memory Interface data width (bits)
  VLEN      : Int = 8192,   // vector register length
  ALEN      : Int = 16384,  // accu register length
  maxTilen  : Int = 16,
  axi4Params: AXI4Params = AXI4Params(),
  reqBufDep : Int = 4,
  metaBufDep: Int = 4,
  wBufDep   : Int = 4,
  txnCtrlNum: Int = 4,
  concurrent: Boolean = false,
  debug     : Boolean = true
) {
  require(NrLanes > 0)
  require(NrVInsns > 0)
  require(wBufDep > 1, "should be a ping-pong buffer")

  // The VLSU processes addresses in nibble (4-bit) units,
  // therefore the address bit width requires an additional bit compared to byte-aligned addressing.
  val vlsuAddrBits = axi4Params.addrBits + 1

  val reqIdBits  = log2Ceil(NrVInsns)
  val maxNrElems = VLEN.max(ALEN)  // max Data Segment length. We call the 1D Transfer in INCR and 2D mode a segment.

  val busBits    = axi4Params.dataBits
  val busBytes   = busBits / 8
  val busNibbles = busBits / 4
  val busSize    = log2Ceil(busBytes)  // The meaning of 'size' here is similar to that of AXI size.
  val busNSize   = log2Ceil(busNibbles)
  
  val maxLen   = axi4Params.maxTxnBytes / busBytes // Max AXI Burst Len
  val maxSize  = log2Ceil(busBytes)

  val EWs = Seq(4, 8, 16, 32)

  val maxTxnPerReq  = VLEN / EWs.min    // The max axi transaction num that a mem access req may cause. TODO: Determined by stride mode or tilen?
  val allElen       = SLEN * NrLanes
  val allElenByte   = allElen / 8
  val dataBufWidth  = allElen.max(busBits) // We want to ensure that the data buffer can accommodate the maximum amount of data that all lanes can output simultaneously in a single cycle.
                                           // Additionally, if this amount is smaller than the bus width, we prefer to accumulate data until it reaches the full bus width before transmitting.
  val maxDataBytes  = VLEN * EWs.max / 8

  private val vmBits = VLEN * 16
  private val amBits = ALEN * 16

  private val vregSramDepth = (VLEN / NrLanes / (NrVmBanks * SLEN)) * NrVregs
  private val aregSramDepth = (ALEN / NrLanes / (NrVmBanks * SLEN)) * NrAregs
  val vmSramDepth = vregSramDepth + aregSramDepth

  val tilenBits = 16 // TODO: confirm tilen width

}

trait HasVLSUParams {
  implicit val p: Parameters
  lazy val vlsuParams = p(VLSUParametersKey)

  // input parameters
  lazy val NrLanes    = vlsuParams.NrLanes
  lazy val NrVInsns   = vlsuParams.NrVInsns
  lazy val NrVregs    = vlsuParams.NrVregs
  lazy val NrAregs    = vlsuParams.NrAregs
  lazy val NrVmBanks  = vlsuParams.NrVmBanks
  lazy val SLEN       = vlsuParams.SLEN
  lazy val VLEN       = vlsuParams.VLEN
  lazy val ALEN       = vlsuParams.ALEN
  lazy val maxTilen   = vlsuParams.maxTilen
  lazy val axi4Params = vlsuParams.axi4Params
  lazy val reqBufDep  = vlsuParams.reqBufDep
  lazy val metaBufDep = vlsuParams.metaBufDep
  lazy val wBufDep    = vlsuParams.wBufDep
  lazy val txnCtrlNum = vlsuParams.txnCtrlNum
  lazy val concurrent = vlsuParams.concurrent
  lazy val debug      = vlsuParams.debug

  // derived parameters
  lazy val vlsuAddrBits = vlsuParams.vlsuAddrBits
  lazy val reqIdBits    = vlsuParams.reqIdBits
  lazy val maxNrElems   = vlsuParams.maxNrElems
  lazy val busBits      = vlsuParams.busBits
  lazy val busBytes     = vlsuParams.busBytes
  lazy val busNibbles   = vlsuParams.busNibbles
  lazy val busSize      = vlsuParams.busSize
  lazy val busNSize     = vlsuParams.busNSize
  lazy val maxLen       = vlsuParams.maxLen
  lazy val maxSize      = vlsuParams.maxSize
  lazy val EWs          = vlsuParams.EWs
  lazy val maxTxnPerReq = vlsuParams.maxTxnPerReq
  lazy val allElen      = vlsuParams.allElen
  lazy val dataBufWidth = vlsuParams.dataBufWidth
  lazy val maxDataBytes = vlsuParams.maxDataBytes
  lazy val vmSramDepth  = vlsuParams.vmSramDepth
  lazy val tilenBits    = vlsuParams.tilenBits

}

class VLSUBundle (implicit val p: Parameters) extends Bundle with HasVLSUParams

class VLSUModule (implicit val p: Parameters) extends Module with HasVLSUParams