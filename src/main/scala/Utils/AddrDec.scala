package Utils

import chisel3._
import chisel3.util.{Cat, Mux1H, OHToUInt}
import freechips.rocketchip.diplomacy.{AddressDecoder, AddressSet}

object AddrDec {
  def genTgtQueryFunc(addrMap: Seq[Seq[AddressSet]]): Seq[UInt => Bool] = {
    val routingMask  = AddressDecoder(addrMap)
    val widenAddrMap = addrMap.map(nodeAddrSet => AddressSet.unify(nodeAddrSet.map(_.widen(~routingMask)).distinct))
//    println(widenAddrMap)
    val tgtDevQueryFunc: Seq[UInt => Bool] = widenAddrMap.map { widenAddrSeq =>
      (addr: UInt) => widenAddrSeq.map(_.contains(addr)).reduce(_ || _)
    }

    tgtDevQueryFunc
  }

  def genTgtID(addr: UInt, func: Seq[UInt => Bool], idSeq: Seq[Int]): UInt = {
    val boolSeq  = func.map(func => func(addr))
    val tgtIDLUT = idSeq.map(_.U)

    Mux1H(boolSeq, tgtIDLUT)
  }

  def genSel(addr: UInt, func: Seq[UInt => Bool], OH: Boolean = true): UInt = {
    val boolSeq = func.map(func => func(addr))
    val selOH = boolSeq.foldLeft(0.U)((acc, elem) => Cat(elem, acc)) >> 1
    val sel = OHToUInt(selOH)

    if (OH) {
      selOH.asUInt
    } else {
      sel.asUInt
    }
  }
}