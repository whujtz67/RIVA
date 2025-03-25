package Utils

import chisel3._
import chisel3.util._


object Common {
	def boolean2Int(bool: Boolean): Int = {
		if (bool) 1 else 0
	}

	def dontTouchSeq[T <: Data](seq: Seq[T]): Unit = {
		seq.foreach(data => dontTouch(data))
	}

	def log2Ceil0(num: BigInt) = {
		if (num == 0) {
			0
		}
		else {
			log2Ceil(num)
		}
	}
}

object ANSI {
	val reset   = "\u001B[0m"
	val bold    = "\u001B[1m"

	val black   = "\u001B[30m"
	val red     = "\u001B[31m"
	val green   = "\u001B[32m"
	val yellow  = "\u001B[33m"
	val blue    = "\u001B[34m"
	val magenta = "\u001B[35m"
	val cyan    = "\u001B[36m"
	val white   = "\u001B[37m"

	// RGBs
	val lgtBlue   = "\u001B[38;2;152;205;218m"
	val lgtGreen  = "\u001B[38;2;197;213;165m"
	val lgtOrange = "\u001B[38;2;245;199;161m"

	val bg_black   = "\u001B[40m"
	val bg_red     = "\u001B[41m"
	val bg_green   = "\u001B[42m"
	val bg_yellow  = "\u001B[43m"
	val bg_blue    = "\u001B[44m"
	val bg_magenta = "\u001B[45m"
	val bg_cyan    = "\u001B[46m"
	val bg_white   = "\u001B[47m"



	// print bold
	def pbold(s: String) = {
		s"$bold$s$reset"
	}

}

