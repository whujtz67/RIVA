package protocols.AXI.spec

import chisel3._
import chisel3.util.Decoupled

// -------------------------------------
// Extended AXI Bundle
// -------------------------------------
case class headerParams(
	routeIDWidth: Int = 0
)

abstract class exRespFlitBase[T <: RespFlitBase] extends Bundle {
  val header   : HeaderBundle
  val flit     : T
}

abstract class exAddrReqFlitBase[T <: AddrReqFlitBase] extends Bundle {
  val header   : HeaderBundle
  val flit     : T
}

case class exAXI4Params(
	axi4Params  : AXI4Params,
	reqHParams  : headerParams = headerParams(),
	respHParams : headerParams = headerParams(),
	dataHParams : headerParams = headerParams()
)

class HeaderBundle(params: headerParams) extends Bundle {
	val tgtID = UInt(params.routeIDWidth.W)
	val srcID = UInt(params.routeIDWidth.W)
}

class exAWFlit(params: exAXI4Params) extends exAddrReqFlitBase[AWFlit] {
	val header = new HeaderBundle(params.reqHParams)
	val flit   = new AWFlit(params.axi4Params)
}

class exWFlit(params: exAXI4Params) extends Bundle {
	val header = new HeaderBundle(params.dataHParams)
	val flit   = new WFlit(params.axi4Params)
}

class exBFlit(params: exAXI4Params) extends exRespFlitBase[BFlit] {
	val header = new HeaderBundle(params.respHParams)
	val flit   = new BFlit(params.axi4Params)
}

class exARFlit(params: exAXI4Params) extends exAddrReqFlitBase[ARFlit] {
	val header = new HeaderBundle(params.reqHParams)
	val flit   = new ARFlit(params.axi4Params)
}

class exRFlit(params: exAXI4Params) extends exRespFlitBase[RFlit] {
	val header = new HeaderBundle(params.respHParams)
	val flit   = new RFlit(params.axi4Params)
}

class exAxi4Bundle(params: exAXI4Params) extends AbstrAxi4Bundle {
  val aw     =         Decoupled(new exAWFlit(params)) // bits are OutPut
  val ar     =         Decoupled(new exARFlit(params))
  val w      =         Decoupled(new exWFlit (params))
  val b      = Flipped(Decoupled(new exBFlit (params)))
  val r      = Flipped(Decoupled(new exRFlit (params)))
}