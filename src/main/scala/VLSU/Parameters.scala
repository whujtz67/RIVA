package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.{Field, Parameters}
import protocols.AXI.spec.AXI4Params

case object  VLSUParametersKey extends Field[VLSUParamters]

case class VLSUParamters(
  NrLanes   : Int = 8,
  NrVInsn   : Int = 8,
  sliceBits : Int = 128,    // lane memory Interface data width (bits)
  VLEN      : Int = 8192,   // vector register length
  ALEN      : Int = 16384,  // accu register length
  maxTilen  : Int = 16,
  axi4Params: AXI4Params = AXI4Params(),
  reqBufDep : Int = 2,
  txnCtrlNum: Int = 4,
) {
  val reqIdBits = log2Ceil(NrVInsn)
  val maxSegLen = VLEN.max(ALEN)  // max Data Segment length. We call the 1D Transfer in INCR and 2D mode a segment.

  val busBits   = axi4Params.dataBits
  val busBytes  = busBits / 8
  val busSize   = log2Ceil(busBytes)  // The meaning of 'size' here is similar to that of AXI size.
  
  val maxLen   = axi4Params.maxTxnBytes / busBytes // Max AXI Burst Len
  val maxSize  = log2Ceil(busBytes)

  private val minEW = 4               // minimum element width is 4 bits (4-32)
  private val maxEW = 32

  val maxTxnPerReq  = VLEN / minEW    // The max axi transaction num that a mem access req may cause. TODO: Determined by stride mode or tilen?
  val allElen       = sliceBits * NrLanes
  val allElenByte   = allElen / 8
  val dataBufWidth  = allElen.max(busBits) // We want to ensure that the data buffer can accommodate the maximum amount of data that all lanes can output simultaneously in a single cycle.
                                           // Additionally, if this amount is smaller than the bus width, we prefer to accumulate data until it reaches the full bus width before transmitting.
  val maxDataBytes  = VLEN * maxEW / 8

  private val vmBits = VLEN * 16
  private val amBits = ALEN * 16
  val bankNum        = VLEN / NrLanes / sliceBits
  private val vtmBitsPerLane = (vmBits + amBits) / NrLanes // vtm: Vector Type Memory, including VM and AM
  private val bankBits       = vtmBitsPerLane / bankNum
  val bankDep        = bankBits / sliceBits

  val tilenBits = 16 // TODO: confirm tilen width

  val EWs = Seq(4, 8, 16, 32)
}

trait HasVLSUParams {
  implicit val p: Parameters
  lazy val vlsuParams = p(VLSUParametersKey)

  // input parameters
  lazy val NrLanes    = vlsuParams.NrLanes
  lazy val sliceBits  = vlsuParams.sliceBits
  lazy val VLEN       = vlsuParams.VLEN
  lazy val ALEN       = vlsuParams.ALEN
  lazy val maxTilen   = vlsuParams.maxTilen
  lazy val axi4Params = vlsuParams.axi4Params
  lazy val reqBufDep  = vlsuParams.reqBufDep
  lazy val txnCtrlNum = vlsuParams.txnCtrlNum

  // derived parameters
  lazy val reqIdBits    = vlsuParams.reqIdBits
  lazy val maxSegLen    = vlsuParams.maxSegLen
  lazy val busBits      = vlsuParams.busBits
  lazy val busBytes     = vlsuParams.busBytes
  lazy val busSize      = vlsuParams.busSize
  lazy val maxLen       = vlsuParams.maxLen
  lazy val maxSize      = vlsuParams.maxSize
  lazy val maxTxnPerReq = vlsuParams.maxTxnPerReq
  lazy val allElen      = vlsuParams.allElen
  lazy val dataBufWidth = vlsuParams.dataBufWidth
  lazy val maxDataBytes = vlsuParams.maxDataBytes
  lazy val bankNum      = vlsuParams.bankNum
  lazy val bankDep      = vlsuParams.bankDep
  lazy val tilenBits    = vlsuParams.tilenBits
  lazy val EWs          = vlsuParams.EWs
}

class VLSUBundle (implicit val p: Parameters) extends Bundle with HasVLSUParams

class VLSUModule (implicit val p: Parameters) extends Module with HasVLSUParams