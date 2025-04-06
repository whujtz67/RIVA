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



  /** SHUFFLE is an important concept in the process of memory access in vector processors.
   *  After the data is shuffled, it will be evenly distributed among the lanes to
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
        case 4 => 0
        case 8 => 1
        case 16 => 2
        case 32 => 3
        case _ => 0
      }
    }

    // get lane ID
    def laneIdOff(ew: Int): Int = log2Ceil(NrLanes) + elemOffBits(ew)

    def getLaneId(ew: Int): UInt = {
      val selMask = Cat(Seq.fill(laneIdBits) {
        EW(log2Ceil(ew))
      })

      selMask & idx(laneIdBits - 1 + elemOffBits(ew), elemOffBits(ew))
    }

    // get Lane Offset
    def getElemIdx(ew: Int): UInt = (idx >> laneIdOff(ew)).asUInt

    def getElemOff(ew: Int): UInt = {
      require(ew != 4, "There are no elemOff in idx when ew = 4")

      idx(elemOffBits(ew) - 1, 0)
    }

    def getLaneOff(ew: Int): UInt = {
      val selMask = Cat(Seq.fill(laneOffBits) {
        EW(log2Ceil(ew))
      })
      val laneOff = if (ew == 4) getElemIdx(ew) else Cat(getElemIdx(ew), getElemOff(ew))

      selMask & laneOff
    }

    // TODO: give an option of using Mux
    // Final Result connection
    lane       := EWs.map(ew => getLaneId (ew)).reduce(_ | _)
    laneOffset := EWs.map(ew => getLaneOff(ew)).reduce(_ | _)
  }
}

class LoadDataController(implicit p: Parameters) extends VLSUModule with DataCtrlHelper{
  val io = IO(new Bundle {
    val ctrl   = Flipped(Decoupled(new DataCtrlBundle())) // ready serves as 'update'
    val r      = Flipped(Decoupled(new RFlit(axi4Params)))
    val txLane = Vec(NrLanes, Decoupled(new LoadLaneSide()))
  })

  private val commitQues_nxt = Vec(2, Vec(NrLanes, Wire(new LoadLaneSide())))
  private val commitQues_r   = Vec(2, Vec(NrLanes, Reg (new LoadLaneSide())))

  private val IDLE       = 0
  private val WaitR      = 1
  private val Committing = 2
  private val state_nxt  = Wire(UInt(2.W))
  private val state_r    = RegNext(state_nxt)
  private val idle       = state_r === IDLE.U
  private val waitR      = state_r === WaitR.U
  private val committing = state_r === Committing.U



  private val cmtDone = WireInit(false.B)

  private val vstart     = WireDefault(io.ctrl.bits.meta.glb.vstart)
  private val busOff     = WireDefault(io.ctrl.bits.axi.addr >> busSize)
  private val lbB        = WireDefault(io.ctrl.bits.axi.lbB)
  private val illuHead   = WireDefault(io.ctrl.bits.meta.rowlv.illuHead && io.ctrl.bits.meta.rowlv.isHead)
  private val illuTail   = WireDefault(io.ctrl.bits.meta.rowlv.illuTail && io.ctrl.bits.meta.rowlv.isLast) // TODO: maybe make it a signal
  private val isHead     = WireDefault(io.ctrl.bits.axi.isHead)
  private val isLastBeat = WireDefault(io.ctrl.bits.axi.isLast) // TODO: maybe make it a signal
  private val isLastTxn  = WireDefault(io.ctrl.bits.meta.txn.isLast)


  commitQues_nxt.zip(commitQues_nxt).foreach {
    case (nxts, rs) =>
      nxts.zip(rs).foreach {
        case (nxt, r) =>
          nxt := r
      }
  }

  when (idle) {
    state_nxt := Mux(io.ctrl.valid, WaitR.U, IDLE.U)
  }.elsewhen(waitR) {
    state_nxt := Mux(io.r.valid, Committing.U, WaitR.U)
  }.elsewhen(committing) {
    state_nxt := Mux(
      cmtDone && isLastBeat,
      Mux(isLastTxn,
        IDLE.U,  // We will return to IDLE once the segment is Done. Because each segment should consider vstart.
        WaitR.U  // Otherwise, we just wait for the R Response of the next AR Request.
      ),
      Committing.U)
  }



  // commit
  //  commitQues_r := RegNext(commitQues_nxt) // TODO: try this
  commitQues_nxt.zip(commitQues_nxt).foreach {
    case (nxts, rs) =>
      nxts.zip(rs).foreach {
        case (nxt, r) =>
          r := RegNext(nxt)
      }
  }

  shuffle(io.EW, io.idx, io.lane, io.laneOff)
}