package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import scala.collection.immutable.ListMap
import xs.utils.{CircularQueuePtr, HasCircularQueuePtrHelper}

/** The Trait to help shuffle and deshuffle.
 *
 *  1. SHUFFLE is an important concept in the process of memory access in vector processors.
 *  After the data is shuffled, it will be evenly distributed among the lanes to
 *  'maximize the utilization' of hardware resources and 'improve parallelism'.
 *
 * The shuffle function has 2 Inputs and 2 Outputs:
 *
 *        EW ----> |-----------------| ----> lane_LUT
 *                 |    shuffle      |
 *  seqNbIdx ----> |-----------------| ----> laneOffset_LUT
 *
 * @param EW: OntHot EW = 4/8/16/32
 * @param idx: The half byte index before shuffling
 * @param lane: In which lane does the half byte locate after shuffling
 * @param laneOffset: Half byte's offset in the lane
 *
 * seqIdx is composed of the following parts (Doesn't have elemOff when ew = 4):
 *         | <-------------------   nbIdxBits    --------------------> |
 *         | <- elemIdxBits -> | <- laneIdBits -> |  <- elemOffBits -> |
 *
 * seqIdx: |      elemIdx      |      laneId      |       elemOff      |
 *
 *                             | <----------- laneIdOff -------------> |
 *
 * The position of laneId and elemIdx is SWITCHED in the 2D Cln mode:
 *         | <-------------------   hBIdxBits    --------------------> |
 *         | <- laneIdBits -> | <- elemIdxBits -> |  <- elemOffBits -> |
 *
 * seqIdx: |      laneId      |      elemIdx      |       elemOff      |
 *
 *                            |  <----------- elemIdxOff -------------> |
 *
 * 2. DESHUFFLE is the inverse process of shuffle (shfNbIdx -> seqNbIdx)
 */
trait ShuffleHelper {
  // Can only be inherited by classes or traits that inherit from VLSUModule
  self: VLSUModule =>

// ------------------------------------------ Parameters ------------------------------------------------- //
  val nbNum      : Int = (SLEN / 4) * NrLanes // halfByte number in SLEN * NrLanes
  val nbIdxBits  : Int = log2Ceil(nbNum)
  val laneIdBits : Int = log2Ceil(NrLanes)
  val laneOffBits: Int = log2Ceil(SLEN/4)

  private val laneElemNum = SLEN / EWs.min // Max element number in a lane, typically 128/4 = 32
  private val seqNbIdxs   = 0 until nbNum
  private val seqElemIdxs = 0 until laneElemNum

  private val seqIdxs: Seq[seqNbIdx] = (0 until nbNum).map(i => new seqNbIdx(i))
  private val shfElemIdxMap = shuffle_elemIdx

  private val seq2shf_map: Seq[Seq[shfNbIdx]]        = sw_shuffle(false)
  private val seq2shf_2d_cln_map: Seq[Seq[shfNbIdx]] = sw_shuffle(true)

  private val shf2seq_map: Seq[ListMap[Int, Int]] = seq2shf_map.map { map =>
    val m = map.zipWithIndex.map {
      case (shf, seq) =>
        shf.idx -> seq
    }.toMap

    val res = ListMap(m.toSeq.sortBy(_._1):_*) // simply convert to ListMap

    res
  }
  private val shf2seq_2d_cln_map: Seq[ListMap[Int, Int]] = seq2shf_2d_cln_map.map { map =>
    val m = map.zipWithIndex.map {
      case (shf, seq) =>
        shf.idx -> seq
    }.toMap

    val res = ListMap(m.toSeq.sortBy(_._1):_*) // simply convert to ListMap

    res
  }

// ------------------------------------------ Index classes ------------------------------------------------- //
  /** half byte idx in the sequential word
   *
   * @param idx
   */
  class seqNbIdx(val idx: Int) {
    require(idx < nbNum)

    private val splitResultNormal = this.split(false)
    private val splitResult2dCln  = this.split(true )
    val idxBin = s"${String.format("%" + nbIdxBits + "s", idx.toBinaryString).replace(' ', '0')}"

    // _1: normal
    // _2: 2D Cln
    val elemOff: (Seq[Int], Seq[Int]) = (splitResultNormal.map(_._1), splitResult2dCln.map(_._1))
    val laneId : (Seq[Int], Seq[Int]) = (splitResultNormal.map(_._2), splitResult2dCln.map(_._3))
    val elemIdx: (Seq[Int], Seq[Int]) = (splitResultNormal.map(_._3), splitResult2dCln.map(_._2))

    private def split(is2DCln: Boolean): IndexedSeq[(Int, Int, Int)] = {
      EWs.indices.map { eew =>
        val elemOffBits = eew
        val elemIdxBits = nbIdxBits - elemOffBits - laneIdBits

        val part1Bits = elemOffBits
        val part2Off = part1Bits
        val part2Bits = if (is2DCln) elemIdxBits else laneIdBits
        val part3Off = part2Off + part2Bits
        val part3Bits = if (is2DCln) laneIdBits else elemIdxBits

        val part1 = if (part1Bits == 0) 0 else idx % (1 << part2Off)
        val part2 = if (part1Bits == 0) idx % (1 << part3Off) else (idx % (1 << part3Off)) >> part2Off
        val part3 = idx >> part3Off

        (part1, part2, part3)
      }
    }

    def getShfIdx(is2DCln: Boolean, eew: Int): shfNbIdx = {
      def get(in: (Seq[Int], Seq[Int])): Int = if (is2DCln) in._2(eew) else in._1(eew)

      val elemOffBits = eew
      val elemIdxBits = nbIdxBits - elemOffBits - laneIdBits

      val eOff = get(this.elemOff)
      val eIdx = get(this.elemIdx)
      val lane = get(this.laneId)

      val laneOff = shfElemIdxMap(eIdx) + eOff // Dont need to "shfElemIdxMap(eIdx) << elemIdxBits" !
//      println(s"laneOff=$laneOff, shfElemIdx=${shfElemIdxMap(eIdx)}, elemOff=${eOff}, elemOffBits=$elemOffBits")

      new shfNbIdx(lane, laneOff)
    }

    override def toString: String = {
      s"""
         |[seq half byte $idx (bin: $idxBin)]
         |Normal:
         |\telemOff = ${elemOff._1}
         |\tlaneId  = ${laneId._1}
         |\telemIdx = ${elemIdx._1}
         |
         |2D Cln:
         |\telemOff = ${elemOff._2}
         |\tlaneId  = ${laneId._2}
         |\telemIdx = ${elemIdx._2}
         |""".stripMargin
    }
  }

  /** half byte index in the shuffled word.
   *
   * @param laneId
   * @param laneOff
   */
  class shfNbIdx(val laneId: Int, val laneOff: Int) {
    val idx = (laneId << laneOffBits) + laneOff
    val idxBin = s"${String.format("%" + nbIdxBits + "s", idx.toBinaryString).replace(' ', '0')}"

    require(idx < nbNum, s"idx = $idx should always < nbNum = $nbNum. Error laneId = $laneId, laneOff = $laneOff")

    override def toString: String = {
      s"[shf_half_byte: idx = $idx (bin: $idxBin)\tlane = $laneId\tlaneOff = $laneOff]"
    }
  }

// ------------------------------------------ sw shuffle ------------------------------------------------- //
  /** Since the mapping relationship follows a sequential integer index starting from 0,
   *  there is no need to implement a Map structure. A linear sequence (e.g., array or list) suffices:
   *
   *  Index: Represents the original position in the sequential order.
   *  Value: Stores the target position in the shuffled order.
   *
   * @return shfElemIdx (0 ~ 31) -> The start nbIdx of this element.
   *         Typically when SLEN = 128:
   *         start nbIdx of this element: 31 30 29 28 27 26 25 24 | 23 22 21 20 19 18 17 16 | 15 14 13 12 11 10  9  8 |  7  6  5  4  3  2  1  0 |
   *         elemIdx                    : 31 15 23  7 27 11 19  3 | 30 14 22  6 26 10 18  2 | 29 13 21  5 25  9 17  1 | 28 12 20  4 24  8 16  0 |
   *
   *         ListMap( 0 ->  0,  1 ->  8,  2 -> 16,  3 -> 24,  4 ->  4,  5 -> 12,  6 -> 20,  7 -> 28,
   *                  8 ->  2,  9 -> 10, 10 -> 18, 11 -> 26, 12 ->  6, 13 -> 14, 14 -> 22, 15 -> 30,
   *                 16 ->  1, 17 ->  9, 18 -> 17, 19 -> 25, 20 ->  5, 21 -> 13, 22 -> 21, 23 -> 29,
   *                 24 ->  3, 25 -> 11, 26 -> 19, 27 -> 27, 28 ->  7, 29 -> 15, 30 -> 23, 31 -> 31)
   */
  private def shuffle_elemIdx: ListMap[Int, Int] = {
    def recursion(seq: Seq[Int]): Seq[Int] = {
      val threshold = SLEN / EWs.max

      if (seq.size == threshold) {
        seq
      } else {
        val (front, back) = seq.splitAt(seq.size / 2)

        val frontResult = recursion(front)
        val backResult = recursion(back)

        frontResult.zip(backResult).flatMap { case (f, b) =>
          Seq(f, b)
        }
      }
    }

    val map = recursion(seqElemIdxs).zipWithIndex.map {
      case (seq, shf) => seq -> shf
    }.toMap

    val res = ListMap(map.toSeq.sortBy(_._1):_*) // simply convert to ListMap

    println(s"shuffle elemIdx map: $res")

    res
  }

  /** software shuffle
   *
   * @param is2DCln
   * @return Map[ EW -> Map[ seqIdx -> shfIdx ] ]
   *         The advantage of returning in this manner is that 'seqIdx' and 'shfIdx' have a one-to-one correspondence.
   *         During the deshuffle process, you can simply flip the key-value pairs, making it extremely convenient.
   *
   */
  def sw_shuffle(is2DCln: Boolean) = {
    println(s"[software shuffle map (is 2D cln: $is2DCln)]\n")
    EWs.indices.map { eew =>
      val res = seqIdxs.map(idx => idx.getShfIdx(is2DCln, eew))

      println(s"EW = ${1 << (eew + 2)}")
      res.zipWithIndex.foreach {
        case (shf, seq) =>
          println(s"\tseqNbIdx: $seq -> $shf")
      }
      println("\n")

      res
    }
  }

// ------------------------------------------ hw shuffle ------------------------------------------------- //
  /** hardware shuffle
   *
   * @param mode
   * @param eew
   * @param seqBuf
   * @param shfBuf_r Should be a reg, because it is a vec and is given a value separately according to the idx. Chisel doesn't allow it to be wire.
   */
  def hw_shuffle[T <: UInt](mode: VecMopOH, eew: UInt, seqBuf: Vec[T], shfBuf_r: Vec[Vec[T]], mask: Option[Vec[UInt]] = None, vm: Option[Bool] = None): Unit = {
    shfBuf_r.zipWithIndex.foreach {
      case (vec, lane) =>
        vec.zipWithIndex.foreach {
          case (sink, off) =>
            val shfNbIdx = new shfNbIdx(lane, off)

            /* Here, Vec is used instead of PriorityMux to ensure that
             * the Verilog generated by Chisel is more structured and organized.
             * Typically, the generated Verilog takes the following form:
             *
             * """
             * automatic logic [3:0][3:0] _GEN_350 = {{io_seqBuf_174}, {io_seqBuf_214}, {io_seqBuf_234}, {io_seqBuf_117}};
             * automatic logic [3:0][3:0] _GEN_351 = {{io_seqBuf_182}, {io_seqBuf_186}, {io_seqBuf_188}, {io_seqBuf_174}};
             *
             * shfBuf_r_5_22 <= io_mode_cln2D ? _GEN_351[io_wid] : _GEN_350[io_wid];
             * """
             */
            // TODO: 合并一些重复的情况
            // In the foreach loop, there is an anonymous scope, so suggestName does not work.
            // INCR, STRD, 2D_ROW Mode
            val vec1 = VecInit(EWs.indices.map { eew =>
              seqBuf(shf2seq_map(eew)(shfNbIdx.idx))
            })
            // 2D_CLN Mode
            val vec2 = VecInit(EWs.indices.map { eew =>
              seqBuf(shf2seq_2d_cln_map(eew)(shfNbIdx.idx))
            })

            if (mask.isDefined) {
              // shuffle nbe
              sink := Mux(
                mode.cln2D,
                vec2(eew).andR && (mask.get(lane)(off) || vm.get),
                vec1(eew).andR && (mask.get(lane)(off) || vm.get)
              )
            } else {
              // shuffle half byte
              sink := Mux(
                mode.cln2D,
                vec2(eew),
                vec1(eew)
              )
            }
        }
    }
  }

  def hw_deshuffle[T <: UInt](mode: VecMopOH, eew: UInt, seqBuf_r: Vec[T], shfBuf: Option[Vec[Vec[T]]], mask: Option[Vec[UInt]] = None, vm: Option[Bool] = None): Unit = {
    seqBuf_r.zipWithIndex.foreach {
      case (sink, seqIdx) =>
        def candidateVec(is2DCln: Boolean): Vec[UInt] = {
          val map = if (is2DCln) seq2shf_2d_cln_map else seq2shf_map
          val res = VecInit(EWs.indices.map { eew =>
            val lane = map(eew)(seqIdx).laneId
            val off  = map(eew)(seqIdx).laneOff

            // Unlike hw_shuffle, mask should be considered at this stage when de-shuffle.
            if (mask.isDefined) {
              // de-shuffle nbe
              mask.get(lane)(off) || vm.get // We don't have shfBuf.nbe in STU, only consider mask from mask Unit
            } else {
              // de-shuffle nb
              shfBuf.get(lane)(off)
            }

          })

          res
        }

        val vec1 = candidateVec(false)
        val vec2 = candidateVec(true)

        sink := Mux(
          mode.cln2D,
          vec2(eew),
          vec1(eew)
        )
    }
  }

  /** The Verilog file generated by the Chisel shuffle function is too long.
   *  To make debugging clearer, it should be encapsulated as a separate module.
   *
   *  @tparam T UInt(4.W)(half byte) or Bundle Type
   */
//  class shuffle[T <: Data](gen: T) extends Module {
//    val io = IO(new Bundle {
//      val mode   = Input(new VecMopOH)
//      val eew    = Input(UInt(2.W))
//      val seqBuf = Input(Vec(nbNum, gen))
//      val shfBuf = Output(Vec(NrLanes, Vec(nbNum/NrLanes, gen)))
//    })
//
//    val shfBuf_r = Reg(Vec(NrLanes, Vec(nbNum/NrLanes, gen)))
//
//    hw_shuffle(io.mode, io.eew, io.seqBuf, shfBuf_r)
//
//    io.shfBuf := shfBuf_r
//  }
}

/** The essential meta info related to DataController saved in MetaBuf.
 *
 * 1. Problem Description
 * Due to the advanced iteration of MetaCtrlInfo by the Control Machine compared to the processing pace of the DataController,
 * the following issues may arise:
 *
 * (1) Request Mismatch: While the DataController is handling request A, the Control Machine might have already progressed to MetaCtrlInfo corresponding to request B.
 * (2) State Inconsistency: This could lead the DataController to use outdated or incorrect meta information, resulting in logical errors or data corruption.
 *
 * 2. Solution: Using MetaBuf
 * To prevent these problems, it is necessary to cache some meta information related to the DataController within the MetaBuf.
 * This ensures a one-to-one correspondence between meta information and requests through physical queue binding.
 *
 * 3. Enq
 * In the 's_row_lv_init' state of the ReqFragmenter, the enq.valid signal is asserted.
 * If the MetaBuf is full at this time, it will cause the ReqFragmenter to enter a stalled state,
 * thereby preventing the loss of requests.
 *
 * 4. Deq
 * Deq when the final transaction of the riva req is committed to the seqBuf.
 *
 * @param p
 */
class MetaBufBundle(implicit p: Parameters) extends VLSUBundle {
  val reqId  = UInt(reqIdBits.W)
  val mode   = new VecMopOH()
  val eew    = UInt(2.W)
  val vd     = UInt(5.W)
  val vstart = UInt(log2Ceil(maxNrElems).W)
  val vm     = Bool()
  val cmtCnt = UInt(log2Ceil(VLEN*EWs.max/SLEN).W)

  def init(meta: MetaCtrlInfo): Unit = {
    this.reqId  := meta.glb.reqId
    this.mode   := meta.glb.mode
    this.eew    := meta.glb.eew
    this.vd     := meta.glb.vd
    this.vstart := meta.glb.vstart
    this.vm     := meta.glb.vm
    this.cmtCnt := meta.glb.cmtCnt
  }
}

trait CommonDataCtrl extends HasCircularQueuePtrHelper with ShuffleHelper {
  self: VLSUModule =>

  class CirQSeqBufPtr extends CircularQueuePtr[CirQSeqBufPtr](2)
  class CirQMetaBufPtr extends CircularQueuePtr[CirQMetaBufPtr](metaBufDep)

  class SeqBufBundle(implicit p: Parameters) extends VLSUBundle {
    val nb = Vec(NrLanes*SLEN/4, UInt(4.W))
    val en = Vec(NrLanes*SLEN/4, Bool()) // Not the nbe committing to the lane, haven't considered mask.
  }

// ------------------------------------------ Common IO Declaration of both DataCtrl ------------------------------------------------- //
  val metaInfo = IO(Flipped(Decoupled(new MetaCtrlInfo()))).suggestName("io_metaInfo") // MetaCtrlInfo from controlMachine
  val txnInfo  = IO(Flipped(Decoupled(new TxnCtrlInfo()))).suggestName("io_txnInfo")   // TxnCtrlInfo from TC. NOTE: txnInfo.ready is the update signal to TC

  // Mask from mask unit
  val mask      = IO(Vec(NrLanes, Flipped(Valid(UInt((SLEN/4).W))))).suggestName("io_mask")
  val maskReady = IO(Output(Bool())).suggestName("io_mask_ready")

// ------------------------------------------ Meta Buffer ------------------------------------------------- //
//  val metaBuf: Queue[MetaBufBundle] = Module(new Queue(new MetaBufBundle(), metaBufDep))
  val metaBuf: Vec[MetaBufBundle] = RegInit(0.U.asTypeOf(Vec(metaBufDep, new MetaBufBundle())))

  val m_enqPtr: CirQMetaBufPtr = RegInit(0.U.asTypeOf(new CirQMetaBufPtr()))
  val m_deqPtr: CirQMetaBufPtr = RegInit(0.U.asTypeOf(new CirQMetaBufPtr()))

  val metaBufEmpty: Bool = isEmpty(m_enqPtr, m_deqPtr)
  val metaBufFull : Bool = isFull (m_enqPtr, m_deqPtr)

// ------------------------------------------ Sequential Buffer ------------------------------------------------- //
  val seqBuf: Vec[SeqBufBundle] = RegInit(0.U.asTypeOf(Vec(2, new SeqBufBundle()))) // Ping-pong buffer

  val enqPtr: CirQSeqBufPtr = RegInit(0.U.asTypeOf(new CirQSeqBufPtr()))
  val deqPtr: CirQSeqBufPtr = RegInit(0.U.asTypeOf(new CirQSeqBufPtr()))

  val seqBufEmpty: Bool = isEmpty(enqPtr, deqPtr)
  val seqBufFull : Bool = isFull (enqPtr, deqPtr)
// ------------------------------------------ Wire/Reg Delaration ------------------------------------------------- //
  // Because the remaining space in seqBuf might be less than the amount of valid data on the bus,
  // it may not be possible to commit all valid data from the bus in a single cycle.
  // Therefore, a counter is required to indicate the amount of valid data from the bus that has already been committed.
  val busNbCnt_nxt: UInt = WireInit(0.U.asTypeOf(UInt((busSize-2).W)))
  val busNbCnt_r  : UInt = RegNext(busNbCnt_nxt)

  // seqBuf half byte pointer
  val seqNbPtr_nxt: UInt = WireInit(0.U.asTypeOf(UInt(log2Ceil(nbNum).W)))
  val seqNbPtr_r  : UInt = RegNext(seqNbPtr_nxt)

// ------------------------------------------ Internal Bundles ------------------------------------------------- //
  val meta: MetaBufBundle = metaBuf(m_deqPtr.value)
  val txn : TxnCtrlInfo   = txnInfo.bits

// ------------------------------------------ FSM Logics ------------------------------------------------- //
  val s_idle :: s_serial_cmt :: s_gather_cmt :: Nil = Enum(3)
  val state_nxt  = WireInit(s_idle)
  val state_r    = RegNext(state_nxt)
  val idle       = state_r === s_idle
  val serial_cmt = state_r === s_serial_cmt
  val gather_cmt = state_r === s_gather_cmt

  // FSM State switch
  when (idle) {
    state_nxt := Mux(
      !metaBufEmpty,
      // accept a new request
      Mux(
        meta.mode.isGather,
        s_gather_cmt,
        s_serial_cmt
      ),
      s_idle
    )
  }.elsewhen(serial_cmt) {
    state_nxt := Mux(txn.isFinalBeat && txnInfo.ready, s_idle, s_serial_cmt) // txnInfo.ready is do Update
  }.elsewhen(gather_cmt) {
    state_nxt := Mux(txn.isFinalBeat && txnInfo.ready, s_idle, s_gather_cmt)
  }.otherwise {
    state_nxt := state_r
  }

// ------------------------------------------ Connections ------------------------------------------------- //
  metaBuf(m_enqPtr.value).init(metaInfo.bits)
  when (metaInfo.fire) {
    m_enqPtr := m_enqPtr + 1.U
  }
  metaInfo.ready := !metaBufFull
}