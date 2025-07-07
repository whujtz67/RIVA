`ifndef RIVA_SVH_
`define RIVA_SVH_


  // MUST SPECIFIC THE "+define+DUMP_FSDB" WHEN SIMULATE WITH VCS in Makefile
	// MAKEFILE EXAMPLE:
	//     MODULE_NAME = your_module_name
	//     VCD_NAME    = $(MODULE_NAME)_wave.vcd
    //     FSDB_NAME   = $(MODULE_NAME)_wave.fsdb
    //
    //     VCS_OPTS = +define+DUMP_FSDB \
           			//  +define+DUT_MODULE=$(MODULE_NAME) \
           			//  +define+VCD_NAME="\"$(VCD_NAME)\"" \
           			//  +define+FSDB_NAME="\"$(FSDB_NAME)\""
	// HOW TO USE: INCLUDE THIS FILE IN YOUR MODULE TESTBENCH FILE
	// DETAILES: 
		//`include "riva.svh"

		//module testbench_top;
		//  // use macro `DUMP_WAVE here
		//  `DUMP_WAVE
		
		//  // other test case...
		//endmodule
	`ifdef DUMP_FSDB
	  `define DUMP_WAVE \
	    initial begin \
	      `ifdef DUT_MODULE \
	        $dumpfile(`VCD_NAME); \
	        $dumpvars(0); \
	        $fsdbDumpfile(`FSDB_NAME); \
	        $fsdbDumpvars(0, `DUT_MODULE, "+all"); \
	      `else \
	        $dumpfile("default.vcd"); \
	        $dumpvars(0); \
	        $fsdbDumpfile("default.fsdb"); \
	        $fsdbDumpvars(0, top, "+all"); \
	      `endif \
	      $fsdbDumpMDA(); \
	    end
	`else
	  `define DUMP_WAVE
	`endif


  // Structs in ports of hierarchical modules are not supported in Verilator
  // --> Flatten them for Verilator
  `define STRUCT_PORT(struct_t)  \
  `ifndef VERILATOR              \
    struct_t                     \
  `else                          \
    logic[$bits(struct_t)-1:0]   \
  `endif

  // Structs in ports of hierarchical modules are not supported in Verilator
  // --> Flatten them for Verilator
  `define STRUCT_PORT_BITS(bits) \
    logic[bits-1:0]              \

  // Create a flattened vector of a struct. Make sure the first dimension is
  // the dimension into the vector of struct types and not the struct itself.
  `define STRUCT_VECT(struct_t, dim)  \
  `ifndef VERILATOR                   \
    struct_t dim                      \
  `else                               \
    logic dim [$bits(struct_t)-1:0]   \
  `endif

`endif