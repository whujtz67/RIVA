// Copyright 2025 Nanjing University
//
// Author: Chuanning Wang <chuan_nwang@smail.nju.edu.cn>

package riscv_mv_pkg;


  ////////////////////////////////////
  //  Common extension definitions  //
  ////////////////////////////////////

    // Element width
  typedef enum logic [1:0] {
    EW4    = 2'b00,
	  EW8    = 2'b01,
	  EW16   = 2'b10,
	  EW32   = 2'b11
  } vew_e;

  // // Length multiplier
  // typedef enum logic [2:0] {
  //   LMUL_1    = 3'b000,
  //   LMUL_2    = 3'b001,
  //   LMUL_4    = 3'b010,
  //   LMUL_RSVD = 3'b100,
  //   LMUL_1_8  = 3'b101,
  //   LMUL_1_4  = 3'b110,
  //   LMUL_1_2  = 3'b111
  // } vlmul_e;

  // // Extension type CSR
  // typedef struct packed {
  //   logic vill; // 1bit: vector instructions are enabled
  //   //
	//   vew_e msew; // 2bit: matrix element width
  //   vlmul_e mlmul; // 3bit: matrix length multiplier
  //   //
  //   vew_e asew; // 2bit: vector element width
  //   vlmul_e almul; // 3bit: vector length multiplier
  //   //
  //   logic vma; // 1bit: matrix instructions are enabled
  //   logic vta; // 1bit: tile instructions are enabled
  //   vew_e vsew; // 2bit:vector element width
  //   vlmul_e vlmul; // 3bit: vector length multiplier
  // } vtype_t;

  // // Func3 values for all instructions under RVMV extension
  // typedef enum logic [2:0] {
  //   // Arithmetic instructions
  //   OPIMV = 3'b000,
  //   OPFMV = 3'b010,
  //   OPIVV = 3'b011,
  //   OPFVV = 3'b100,
  //   OPIVX = 3'b101,
  //   OPFVF = 3'b110,
  //   // Memory instructions
  //   OPMMA = 3'b001,
  //   // Configuration-setting instructions
  //   OPCFG = 3'b111
  // } opcodemv_func3_e;

  // typedef enum logic [1:0] {
  //   NONECFG = 2'b00,
  //   MCFG = 2'b01,
  //   VCFG = 2'b10,
  //   ACFG = 2'b11
  // } cfg_func3_e;


  // ///////////////////
  // //  Vector CSRs  //
  // ///////////////////

  // function automatic logic is_vector_csr (riscv::csr_reg_t csr);
  //   case (csr)
  //     riscv::CSR_VSTART,
  //     riscv::CSR_VXSAT,
  //     riscv::CSR_VXRM,
  //     riscv::CSR_VCSR,
  //     riscv::CSR_VL,
  //     riscv::CSR_VTYPE,
  //     riscv::CSR_VLENB,
  //     riscv::CSR_MVTYPE,  
  //     riscv::CSR_TILEN,   
  //     riscv::CSR_ALEN,    
  //     riscv::CSR_TILENB,  
  //     riscv::CSR_ALENB: begin
  //       return 1'b1;
  //     end
  //     default: return 1'b0;
  //   endcase
  // endfunction : is_vector_csr

  // ///////////////////////////////////////
  // //  Matrix-Vector instruction types  //
  // ///////////////////////////////////////

  // typedef struct packed {
  //   logic         memtype;  // 0: matrix type registers, 1: vector type registers
  //   logic [30:29] mop;  // 00: unit-stride memory access, but specific operation is determined by the imm5 field;
  //   logic [28:26] width;
  //   logic         ls;  // 0: load, 1: store
  //   logic [24:20] rs2;
  //   logic [19:15] rs1;
  //   logic [14:12] func3;
  //   logic [11:7]  rvd;
  //   logic [6:0]   opcode;
  // } vma_type_t;

  // typedef struct packed {
  //   logic         memtype;  // 0: matrix type registers, 1: vector type registers
  //   logic [30:29] mop;  // 00: unit-stride memory access, but specific operation is determined by the imm5 field;
  //   logic [28:27] width;
  //   logic         fpad;
  //   logic         ls;  // 0: load, 1: store
  //   logic [24:20] rs2;
  //   logic [19:15] rs1;
  //   logic [14:12] func3;
  //   logic         bpad;
  //   logic [10: 9] padvalue;
  //   logic [8:7]   rmd;
  //   logic [6:0]   opcode;
  // } mma_type_t;

  // typedef struct packed {
  //   logic [31:28] func4;
  //   logic         overflow;
  //   logic         jump;
  //   logic         vm;
  //   logic         slideup;
  //   logic         slidelen;
  //   logic [21:20] ms2;
  //   logic [19:15] rs1;
  //   logic [14:12] func3;
  //   logic [11:7]  rd;
  //   logic [6:0]   opcode;
  // } marith_type_t;

  // typedef struct packed {
  //   logic [31:26] func6;
  //   logic vm;
  //   logic [24:20] rs2;
  //   logic [19:15] rs1;
  //   logic [14:12] func3;
  //   logic [11:7]  rd;
  //   logic [6:0]   opcode;
  // } varith_type_t;

  // typedef struct packed {
  //   logic [31:30] func2; // rs1 or imm5 input 
  //   logic [29:28] memtype;
  //   logic [27:20] zimm8;
  //   logic [19:15] rs1;
  //   logic [14:12] func3;
  //   logic [11:7]  rd;
  //   logic [6:0]   opcode;
  // } cfglen_type_t;


  // typedef union packed {
  //   logic [31:0] instr ;
  //   riscv::itype_t i_type; // For CSR instructions
  //   vma_type_t vma_type;
  //   mma_type_t mma_type;
  //   marith_type_t marith_type;
  //   varith_type_t varith_type;
  //   cfglen_type_t cfglen_type;
  // } rvmv_instruction_t;

  // ////////////////////////////
  // //  Vector mask register  //
  // ////////////////////////////

  // // The mask register is always vreg[0]
  // localparam VMASK = 5'b00000;

endpackage : riscv_mv_pkg

