package protocols.AXI.components

import chisel3._
import chisel3.util._
import protocols.AXI.spec.{exAXI4Params, exAxi4Bundle, AbstrAxi4Bundle}

// This module is primarily designed to reduce the number of modules displayed at the top level in waveform software, 
// while also facilitating instantiation and wiring.
class AXI4Buffer(
  val exAXI4Params:   exAXI4Params,
  val entries:        Int,
  val pipe:           Boolean = false,
  val flow:           Boolean = false,
  val useSyncReadMem: Boolean = false,
  val hasFlush:       Boolean = false
) extends Module {

// ------------------------------------------ IO Declaration ---------------------------------------------- //
	val io = IO(new Bundle {
		val in   = Flipped(new exAxi4Bundle(exAXI4Params))
		val out  =         new exAxi4Bundle(exAXI4Params)
	})

// ------------------------------------------ Declarations ---------------------------------------------- //
	// --------------------- Module declaration ------------------------ //
	val awQueue = Module(new Queue(chiselTypeOf(io.in.aw.bits), entries, pipe, flow, useSyncReadMem, hasFlush))
	val wQueue  = Module(new Queue(chiselTypeOf(io.in.w .bits), entries, pipe, flow, useSyncReadMem, hasFlush))
	val bQueue  = Module(new Queue(chiselTypeOf(io.in.b .bits), entries, pipe, flow, useSyncReadMem, hasFlush))
	val arQueue = Module(new Queue(chiselTypeOf(io.in.ar.bits), entries, pipe, flow, useSyncReadMem, hasFlush))
	val rQueue  = Module(new Queue(chiselTypeOf(io.in.r .bits), entries, pipe, flow, useSyncReadMem, hasFlush))

// ------------------------------------------ Connections ---------------------------------------------- //
	awQueue.io.enq <> io.in .aw
	wQueue .io.enq <> io.in .w
	bQueue .io.enq <> io.out.b
	arQueue.io.enq <> io.in .ar
	rQueue .io.enq <> io.out.r

	io.out.aw      <> awQueue.io.deq
	io.out.w       <> wQueue .io.deq
	io.in .b       <> bQueue .io.deq
	io.out.ar      <> arQueue.io.deq
	io.in .r       <> rQueue .io.deq
}

object AXI4Buffer {
	def conn(
		spBundle: AbstrAxi4Bundle, 
		mpBundle: AbstrAxi4Bundle,
		axi4Buf : AXI4Buffer
	) = {
		axi4Buf.io.in <> spBundle
		mpBundle      <> axi4Buf.io.out
	}

	def gen_and_conn(
		spBundle      : AbstrAxi4Bundle, 
		mpBundle      : AbstrAxi4Bundle,
		exAXI4Params  : exAXI4Params,
  		entries       : Int,
  		pipe          : Boolean = false,
  		flow          : Boolean = false,
  		useSyncReadMem: Boolean = false,
  		hasFlush      : Boolean = false
	) = {
		val axi4Buf = new AXI4Buffer(
			exAXI4Params  ,
			entries       ,
			pipe          ,
			flow          ,
			useSyncReadMem,
			hasFlush      
		)

		AXI4Buffer.conn(spBundle, mpBundle, axi4Buf)
	}
}