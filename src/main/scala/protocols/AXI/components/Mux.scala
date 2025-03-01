package protocols.AXI.components

import chisel3._
import chisel3.util._
import Utils.{FastArb, LogicMux, LogicDemux}
import chisel3.experimental.requireIsChiselType
import protocols.AXI.spec._

// -----------------------------------------------------------------------------------------------------------------
// Channel Mux in Router
// -----------------------------------------------------------------------------------------------------------------
/*
 * @param: idPpdWidth indicates the prepended ID Width. If it is not defined, selWidth = log2Up(spNum)
 */
class ChannelMux(spNum: Int, awQueueDepth: Int, axi4Params: AXI4Params, idPpdWidth: Option[Int] = None) extends Module {
// ------------------------------------------ Parameters ---------------------------------------------- //
  // -------------------- Get Params from MeshModule ------------------ //
  private val idWidth_i      = axi4Params.idBits
  // --------------------- Constant Calculation ------------------------ //
  private val selWidth       = if (idPpdWidth.isDefined) idPpdWidth.get else log2Up(spNum)
  private val idWidth_o      = idWidth_i + selWidth

// ------------------------------------------ IO Declaration ---------------------------------------------- //
  val io = IO(new Bundle {
    val in = new Bundle {
      val slvPorts = Vec(spNum, Flipped(new Axi4Bundle(axi4Params.copy(idBits = idWidth_o))))
    }
    val out = new Bundle{
      val mstPort = new Axi4Bundle(axi4Params.copy(idBits = idWidth_o))
    }
  })

// ------------------------------------------ Declarations ---------------------------------------------- //
  // --------------------- Module declaration ------------------------ //
  // The requests on the W channel should be consistent with the results of the AW arbiter.
  // Therefore, a FIFO is required to store the arbitration results of the AW channel.
  val awQueue = Module(new ReorderQueue(chiselTypeOf(io.in.slvPorts(0).aw.bits), awQueueDepth, spNum))

  // AW AR Channel Skid Buffer
  val arSkid  = Module(new Queue(chiselTypeOf(io.in.slvPorts(0).ar.bits), 1, flow = true))

  // AW 

  // --------------------- Reg/Wire declaration ------------------------ //
  val w_mux_out     = Wire(io.out.mstPort.w.cloneType)
  val lockAwQueue   = RegInit(false.B) // should be a Reg to avoid Combinational loop

  val w_sel_nxt     = awQueue.io.deq.bits.id(idWidth_o - 1, idWidth_i)
  val w_sel         = RegEnable(w_sel_nxt, 0.U(selWidth.W), !lockAwQueue)
  // val awQ_deq_ready_nxt = io.out.mstPort.aw.ready && w_mux_out.valid && !lockAwQueue
  // val awQ_deq_ready_nxt

// ------------------------------------------ Main Logics ---------------------------------------------- //

// ------------------------------------------ Connections ---------------------------------------------- //
  // ------ Channel Demux and RR ----- //
  // AW
  FastArb.fastArbDec2Dec(io.in.slvPorts.map(_.aw), awQueue.io.enq, Some("mux_aw"))

  io.out.mstPort.aw.bits := awQueue.io.deq.bits

  awQueue.io.deq.ready    := io.out.mstPort.aw.ready && io.in.slvPorts(w_sel_nxt).w.valid && !lockAwQueue
  io.out.mstPort.aw.valid := awQueue.io.deq.fire

  when (awQueue.io.deq.fire) { lockAwQueue := true.B } 
  when (io.out.mstPort.w.fire && io.out.mstPort.w.bits.last) { lockAwQueue := false.B }

  awQueue.ctrl_io.lock_reorder := lockAwQueue

  // W
  LogicMux.conn_selUInt(ins = io.in.slvPorts.map(_.w), out = w_mux_out , sel = w_sel, Some("W"))

  io.out.mstPort.w <> w_mux_out

  io.out.mstPort.w.valid := w_mux_out.fire // valid should be connected to fired, otherwise will be a repeat w beat
  w_mux_out.ready := io.out.mstPort.w.ready && lockAwQueue// Block W if we do not have an AW destination by taking awQueue.io.deq.valid into consideration

  awQueue.ctrl_io.valids.zip(io.in.slvPorts.map(_.w.valid)).foreach {
    case (awQ_v, spW_v) =>
      awQ_v := spW_v
  }

  // B
  LogicDemux.conn_selUInt(io.out.mstPort.b, io.in.slvPorts.map(_.b), io.out.mstPort.b.bits.id(idWidth_o - 1, idWidth_i), Some("B"))

  // AR
  FastArb.fastArbDec2Dec(io.in.slvPorts.map(_.ar), arSkid.io.enq, Some("mux_ar"))

  io.out.mstPort.ar <> arSkid.io.deq


  // R
  LogicDemux.conn_selUInt(io.out.mstPort.r, io.in.slvPorts.map(_.r), io.out.mstPort.r.bits.id(idWidth_o - 1, idWidth_i), Some("R"))

  // ------------------------------------------  Don't Touch ---------------------------------------------- //
  dontTouch(w_sel)
  dontTouch(w_sel_nxt)

}

// -----------------------------------------------------------------------------------------------------------------
// RamPtrBundle
// -----------------------------------------------------------------------------------------------------------------
// To achieve reordering of AW requests, we need a RAM pointer lookup table to record the output order of all RAMs. 
// The entry at each position in the table represents the RAM pointer for that particular output, 
// along with an en signal indicating whether the request stored in that RAM is valid. 
// The RamPtrBundle is the type of each entry in the table.
class RamPtrBundle(entries: Int) extends Bundle {
  val en  = Bool()
  val ptr = UInt(log2Up(entries).W) // ram pointer
}

// -----------------------------------------------------------------------------------------------------------------
// ReorderQueue
// -----------------------------------------------------------------------------------------------------------------
// ReorderQueue is designed for AW Channel to avoid DEADLOCK and to improve performance.
class ReorderQueue(val gen: AWFlit, val entries: Int, spNum: Int) extends Module {
  require(entries > -1, "Queue must have non-negative number of entries")
  require(entries != 0, "Use companion object Queue.apply for zero entries")
  requireIsChiselType(gen)

  private val spSelWidth    = log2Up(spNum)
  private val QueueSelWidth = log2Up(entries)

  val io = IO(new QueueIO(gen, entries))
  val ctrl_io = IO(new Bundle {
    val valids = Input(Vec(spNum, Bool()))   // W valids of W mux slv ports
    val lock_reorder = Input(Bool())         // connects to lockAWQueue => don't do reorder when the last aw req is in process.
  })

  val ram = Mem(entries, gen)
  val enq_ptr = WireInit(0.U(QueueSelWidth.W))
  val deq_ptr = WireInit(0.U(QueueSelWidth.W)) // always use the ptr of ramPtrMap_r(0) as deq_ptr
  val empty   = WireInit(true .B)
  val full    = WireInit(false.B)
  val do_enq  = WireDefault(io.enq.fire) 
  val do_deq  = WireDefault(io.deq.fire) // io.deq.ready := io.out.mstPort.aw.ready && io.in.slvPorts(w_sel_nxt).w.valid && !lockAwQueue
                                        // so that 'io.deq.ready' already contains all the info we need.

  val deq_spIdx = Wire(UInt(spSelWidth.W)) // get the slave port idx of AW Txn ready to deq in awQueue

  

  // ---------------------------
  // FSM
  //
  // The FSM have 3 States: IDLE POP and DoReorder
  //                      do_deq
  //  IDLE  ------------------------------->  POP
  //   |    <-------------------------------   ^
  //   |                 next cycle            |
  //   |                                       |
  //   |  do_reorder              next cycle   |
  //   -------------> DoReorder ----------------
  //
  val IDLE      = 0
  val POP       = 1
  val DoReorder = 2
  
  val state_nxt = WireInit(0.U(2.W))
  val state_r   = RegNext(state_nxt) // (1) state transfer, Sequential Logic

  val idle      = state_r === IDLE.U
  val pop       = state_r === POP.U
  val reorder   = state_r === DoReorder.U
  
  val ramPtrMap_nxt = Wire(Vec(entries, new RamPtrBundle(entries)))
  val ramPtrMap_r   = RegNext(ramPtrMap_nxt)

  val awSrcPorts = Wire(Vec(entries, UInt(spSelWidth.W))) // indicates the sel slv port idx of each aw Txn stored in Rams
  val aw_can_be_reorder = Wire(Vec(entries, Bool())) // 


  // do reorder when:
  // 1. There is an AW txn in the awQueue waiting to be sent;
  // 2. However its W txn valid has not come;
  // 3. The W request of last AW req popped from awQueue has been finished (Not lock awQueue)
  // 4. At least one other W request has arrived. Note that w valid is also asserted when the last W txn is in process,
  //    while its aw req has been pop. So we judge whether do reorder when there isn't aw req in process (Not lock awQueue) 
  val do_reorder  = ramPtrMap_r(0).en && !ctrl_io.valids(deq_spIdx) && !ctrl_io.lock_reorder && ramPtrMap_r.map(_.en).zip(awSrcPorts).zipWithIndex.map {
    case ((en, sp), i) =>
      val ret = WireInit(false.B) // TO make vscode happy
      if (i != 0) {
        when (en) {
          ret := ctrl_io.valids(sp)
        }.otherwise {
          ret := false.B
        }
      }            

      ret
  }.reduce(_ || _)

  val reorder_sel_nxt = WireInit(0.U(QueueSelWidth.W))
  val reorder_sel_r   = RegNext(reorder_sel_nxt)

  // (2) state switch, using block assignment for combination-logic
  /*
   * outputs:
   *          state_nxt
   */
  when (idle) {
    when (do_deq) {
      state_nxt := POP.U
    } .elsewhen (do_reorder) {
      state_nxt := DoReorder.U
    } .otherwise {
      state_nxt := state_r
    }
  }
  // always returns to IDLE the next cycle no matter the state is pop or reorder
  .elsewhen (pop) {
    state_nxt := IDLE.U
  }
  .elsewhen (reorder) {
    // Take io.deq.ready into consideration.
    // Because if Downstream cannot receive the txn, but we still Pop it, we will lose the req.
    when (aw_can_be_reorder.asUInt.orR && io.deq.ready) {
      state_nxt := POP.U
    } .otherwise {
      state_nxt := IDLE.U // This is a corner case where W has come but the corresponding aw hasn't been enq to awQueue. However, it may never happends? 
    }
  }
  // default
  . otherwise {
    state_nxt := state_r
  }

  // (3) FSM output logic, using Sequential non-block assignment
  /*
   * outputs:
   *          ramPtrMap_nxt (en + ptr)
   */
  when (idle) {
    // default assignments
    ramPtrMap_nxt := ramPtrMap_r
  }
  // State == POP
  .elsewhen (pop){
    // pop one item from the map. 'Take Effect Next Cycle'. 
    ramPtrMap_nxt.zipWithIndex.foreach {
      case (ptr, i) =>
        ptr := ramPtrMap_r(((i + 1) % entries))
    }

    // When we pop an element, we move its corresponding RAM pointer to the end of the map
    // and set its en signal to 0. 'Take Effect Next Cycle'.
    ramPtrMap_nxt.last.en := false.B
  } 
  // State == REORDER
  .elsewhen (reorder) {
    // find all aw that can be reorder (Their w valid has come, but sel isn't given to them)
    // There might be more then one W valid has come, 'aw_can_be_reorder' represents all the AW requests stored in 
    // the awQueue whose W valid has come.
    // 'reorder_sel_nxt' uses PriorityEncoder to sel the lowest bit that is set to 1 of 'aw_can_be_reorder'.
    reorder_sel_nxt := PriorityEncoder(aw_can_be_reorder) // get the only one that can be reorder (The lowest one)

    // update ramPtrMap_nxt, make the reorder_sel aw txn to the first one. 'Take Effect Next Cycle'. 
    ramPtrMap_nxt.zipWithIndex.foreach {
      case (nxt, i) => 
        // To avoid index out of bound
        if (i == 0) {
          nxt := ramPtrMap_r(reorder_sel_nxt)
        } 
        else {
          when (i.U <= reorder_sel_nxt) {
            nxt := ramPtrMap_r(i - 1)
          } .otherwise {
            nxt := ramPtrMap_r(i)
          }
        }
        
    }
  } 
  // default
  .otherwise {
    ramPtrMap_nxt := ramPtrMap_r
  }

  // ** Generate awSrcPorts **
  // The src slv port(High-order bits of the ID) of aw requests in the ram of awQueue.
  // We don't consider whether the request is valid or not here.
  awSrcPorts.zip(ramPtrMap_r).foreach {
    case (sel, ptr) =>
      sel := ram(ptr.ptr).id >> (gen.id.getWidth - spSelWidth)
  }

  // Can be reorder means that the corresponding W valid has come, and the aw req stored in awQueue is valid.
  // aw_can_be_reorder is used to sel the aw req to be reordered.
  awSrcPorts.zipWithIndex.foreach { 
    case (sel, i) =>
      aw_can_be_reorder(i) := ctrl_io.valids(sel) && ramPtrMap_r(i).en
  }

  // 
  // end FSM
  // ---------------------------
  
  // empty and full
  empty   := !ramPtrMap_r.map(_.en).reduce(_ || _)
  full    := ramPtrMap_r.map(_.en).reduce(_ && _) 

  // 
  // enq logic, it should not be put in the FSM, because we can do enq at each state
  //
  val ramPtrMap_enq_sel = PriorityEncoder(ramPtrMap_r.map(!_.en))

  io.enq.ready := !full
  enq_ptr := ramPtrMap_r(ramPtrMap_enq_sel).ptr
  when (do_enq) {
    ram(enq_ptr) := io.enq.bits
    when (pop) {
      ramPtrMap_nxt(ramPtrMap_enq_sel - 1.U).en := true.B
    } .otherwise {
      ramPtrMap_nxt(ramPtrMap_enq_sel).en := true.B
    }
    
  }

  //
  // deq logic, deq ptr is always the ptr of ramPtrMap_r(0)
  //
  deq_spIdx    := awSrcPorts(0)
  deq_ptr      := ramPtrMap_r(0).ptr
  io.deq.bits  := ram(deq_ptr)
  io.deq.valid := !empty

  io.count := ramPtrMap_r.map(_.en.asUInt).reduce(_ + _)

  /** Give this Queue a default, stable desired name using the supplied `Data`
    * generator's `typeName`
    */
  override def desiredName = s"ReorderQueue${entries}_${gen.typeName}"

  // ------------------------------------------  Reset ---------------------------------------------- //
  when (reset.asBool) {
    ramPtrMap_nxt.zipWithIndex.foreach { 
      case (ptr, i) => 
        ptr.en  := false.B
        ptr.ptr := i.U
    }

    state_nxt := 0.U // The start state should be IDLE
  }

  // ------------------------------------------  Don't Touch ---------------------------------------------- //
  dontTouch(ramPtrMap_nxt)
  dontTouch(empty)
  dontTouch(full)
  dontTouch(do_deq)
  dontTouch(state_nxt)
  dontTouch(do_reorder)
  dontTouch(awSrcPorts)

  // ------------------------------------------  Debug ---------------------------------------------- //
  // The awSrcAddrs is not used in main logic. However, it is useful to have it when debug.
  val awSrcAddrs = Wire(Vec(entries, UInt(32.W)))
  awSrcAddrs.zip(ramPtrMap_r).foreach {
    case (sel, ptr) =>
      sel := ram(ptr.ptr).addr 
  }

  dontTouch(awSrcAddrs)
}



