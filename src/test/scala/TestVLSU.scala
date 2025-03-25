package test
import circt.stage.{ChiselStage, FirtoolOption}
import chisel3._
import chisel3.util.{circt, _}
import chisel3.stage.ChiselGeneratorAnnotation
import org.chipsalliance.cde.config._
import protocols.AXI._
import vlsu._



object TestVLSU extends App {

  val config = new Config((site, here, up) => {
    case VLSUParametersKey => VLSUParamters()
  })

  (new ChiselStage).execute(Array("--target", "verilog") ++ args, Seq(
    FirtoolOption("--disable-all-randomization"),
    FirtoolOption("--split-verilog"),
    FirtoolOption("-o=./build/rtl"),
    ChiselGeneratorAnnotation(() => new VLSU()(config))
  ))
}