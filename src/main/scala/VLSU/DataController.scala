package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import protocols.AXI.spec.{WFlit, RFlit}

trait DataCtrlHelper {
  // Can only be inherited by classes or traits that inherit from VLSUModule
  self: VLSUModule =>

  val hBNum      : Int = (sliceBits / 4) * NrLanes // halfByte number in sliceBits * NrLanes
  val hBIdxBits  : Int = log2Ceil(hBNum)
  val laneIdBits : Int = log2Ceil(NrLanes)
  val laneOffBits: Int = log2Ceil(sliceBits/4)



  /** After the data is SHUFFLED, it will be evenly distributed among the lanes to
   *  'maximize the utilization' of hardware resources and 'improve parallelism'.
   *
   * The shuffle function has 2 Inputs and 2 Outputs:
   *
   *        EW ----> |-----------------| ----> lane
   *                 |    shuffle      |
   *       idx ----> |-----------------| ----> laneOffset
   *
   * @param EW: OntHot EW = 4/8/16/32
   * @param idx: The half byte index before shuffling
   * @param lane: In which lane does the half byte locate after shuffling
   * @param laneOffset: Half byte's offset in the lane
   *
   * Idx is composed of the following parts (Doesn't have elemOff when ew = 4):
   *      | <-------------------   hBIdxBits    --------------------> |
   *      | <- elemIdxBits -> | <- laneIdBits -> |  <- elemOffBits -> |
   *
   * Idx: |      elemIdx      |      laneId      |       elemOff      |
   *
   *                          | <----------- laneIdOff -------------> |
   *
   */
  def shuffle(EW: UInt, idx: UInt, lane: UInt, laneOffset: UInt): Unit = {

    // Helper Function
    def elemOffBits(ew: Int): Int = {
      require(EWs.contains(ew), "RIVA_v1 only supports EW = 4/8/16/32")
      ew match {
        case 4  => 0
        case 8  => 1
        case 16 => 2
        case 32 => 3
        case _ => 0
      }
    }

    // get lane ID
    def laneIdOff(ew: Int): Int = log2Ceil(NrLanes) + elemOffBits(ew)

    def getLaneId(ew: Int): UInt = {
      val selMask = Cat(Seq.fill(laneIdBits) { EW(log2Ceil(ew)) })

      selMask & idx(laneIdBits - 1 + elemOffBits(ew), elemOffBits(ew))
    }

    // get Lane Offset
    def getElemIdx(ew: Int): UInt = (idx >> laneIdOff(ew)).asUInt

    def getElemOff(ew: Int): UInt = {
      require(ew != 4, "There are no elemOff in idx when ew = 4")

      idx(elemOffBits(ew) - 1, 0)
    }
    
    def getLaneOff(ew: Int): UInt = {
      val selMask = Cat(Seq.fill(laneOffBits) { EW(log2Ceil(ew)) })
      val laneOff = if (ew == 4) getElemIdx(ew) else Cat(getElemIdx(ew), getElemOff(ew))
      
      selMask & laneOff
    }

    // Final Result connection
    lane       := EWs.map(ew => getLaneId (ew)).reduce(_ | _)
    laneOffset := EWs.map(ew => getLaneOff(ew)).reduce(_ | _)
}

class LoadDataController(implicit p: Parameters) extends VLSUModule with DataCtrlHelper{
//  val info = IO(Flipped(Valid(new Bundle {
//    val meta = new MetaCtrlInfo()
//    val axi  = new AxiCtrlInfo()
//  })))
//
//  val r = IO(Flipped(Decoupled(new RFlit(axi4Params))))

  val io = IO(new Bundle {
    val EW      = Input (UInt(6.W))
    val idx     = Input (UInt(hBIdxBits.W))
    val lane    = Output(UInt(laneIdBits.W))
    val laneOff = Output(UInt(laneOffBits.W))
  })

  shuffle(io.EW, io.idx, io.lane, io.laneOff)
}