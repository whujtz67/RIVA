package Utils

import chisel3._
import chisel3.util.Decoupled

class CutRegister[T <: Data](val gen: T) extends Module {
	val io = IO(new Bundle {
		val in  = Flipped(Decoupled(gen))
		val out =         Decoupled(gen)
	})

	val data_q = RegInit(0.U.asTypeOf(gen))
	val full_q = RegInit(false.B)

	val enq = WireInit(false.B)
	val deq = WireInit(false.B)

	when (enq) {
		data_q := io.in.bits
	} .otherwise{
		data_q := data_q
	}

	when (enq || deq) {
		full_q := enq
	} .otherwise{
		full_q := full_q
	}

	// data_q := Mux(enq, io.in.bits, data_q)
	// full_q := Mux(enq || deq, enq, full_q)

	enq := io.in.fire
	deq := io.out.fire

	io.in.ready := !full_q
	io.out.valid := full_q

	io.out.bits := data_q
}
