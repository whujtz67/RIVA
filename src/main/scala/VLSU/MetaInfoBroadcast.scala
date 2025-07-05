package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters

/** MetaInfo Broadcast Module
 * 
 * This module broadcasts metaInfo to both sequential and shuffle modules:
 * - Sequential modules: receive seqNbPtr for idleInfoQueue
 * - Shuffle modules: receive full metaInfo for metaBuf
 */
class MetaInfoBroadcast(implicit p: Parameters) extends VLSUModule {
// ------------------------------------------ IO Declaration ------------------------------------------------- //
  // Input from Control Machine
  val metaInfo = IO(Flipped(Decoupled(new MetaCtrlInfo()))).suggestName("io_metaInfo")

  // Output to Sequential modules
  val seq = IO(Decoupled(new MetaCtrlInfo())).suggestName("io_seq")

  // Output to Shuffle modules  
  val shf = IO(Decoupled(new MetaCtrlInfo())).suggestName("io_shf")

// ------------------------------------------ Simple Logic ------------------------------------------------- //
  // Broadcast data to both outputs
  seq.bits := metaInfo.bits
  shf.bits := metaInfo.bits
  
  // Only send valid when both outputs are ready
  seq.valid := metaInfo.valid && seq.ready && shf.ready
  shf.valid := metaInfo.valid && seq.ready && shf.ready
  
  // Input ready when both outputs are ready
  metaInfo.ready := seq.ready && shf.ready
} 