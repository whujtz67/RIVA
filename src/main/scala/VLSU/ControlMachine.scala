package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import protocols.AXI.spec.{AWFlit, ARFlit}

class ControlMachine(implicit p: Parameters) extends VLSUModule {
  // ------------------------------------------ IO Declaration ---------------------------------------------- //
  val io = IO(new Bundle {
    // TODO: The memory access Req AGU received might has been decoded, not the original Req. The valid should not be the original valid!
    val rivaReq = Flipped(Decoupled(new RivaReq())) // Memory Access Req

    val aw  = Decoupled(new AWFlit(axi4Params))
    val ar  = Decoupled(new ARFlit(axi4Params))

    val csr = Input(new CsrBundle())
  })

  // ------------------------------------------ Module Declaration ---------------------------------------------- //
  //
  private val payload = Reg(UInt(1.W))




  // ------------------------------------------  Don't Touch ---------------------------------------------- //
}