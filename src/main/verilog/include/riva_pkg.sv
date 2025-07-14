// Author: Chuan_nWang
// Description: RIVA definations.	
// RIVA: RISC-V artificial Intelligent Vector Accelerator
package riva_pkg;

  //////////////////
  //  Parameters  //
  //////////////////

  // Maximum size of a single vector element, in bits.
  // riva only supports vector elements up to 32 bits.
  localparam int unsigned ELEN = 32;
  localparam int unsigned DLEN = 128;
  // Maximum size of a single vector element, in bytes.
  localparam int unsigned ELENB = ELEN / 8;
  localparam int unsigned DLENB = DLEN / 8;

  // Number of vector instructions that can run in parallel.
  localparam int unsigned NrVInsn = 8;

  // Maximum number of lanes that riva can support./
  // Assume a single vector register file contains 8192bits.
  localparam int unsigned MaxNrLanes = 16;

  // FPU latencies.
  localparam int unsigned LatFDivSqrt    = 4'd10;
  localparam int unsigned LatFMulAdd     = 4'd3;
  localparam int unsigned LatFComp       = 4'd1;
  // Define the maximum FPU latency
  localparam int unsigned LatFMax = LatFDivSqrt;

  // FUs instruction queue depth.
  // VLSU
  localparam int unsigned VlduInsnQueueDepth = 4;
  localparam int unsigned VstuInsnQueueDepth = 4;
  localparam int unsigned VaddrgenInsnQueueDepth = 4;
  // MMU
  localparam int unsigned VmmInsnQueueDepth = 4;
  // VPU
  localparam int unsigned ValuInsnQueueDepth  = 4;
  localparam int unsigned VfmauInsnQueueDepth  = 4;
  localparam int unsigned VdivuInsnQueueDepth  = 4;
  localparam int unsigned VcompuInsnQueueDepth = 4;

  localparam int unsigned VmfuInsnQueueDepth   = 2;
  localparam int unsigned VsfuInsnQueueDepth   = 4;
  // XMU
  localparam int unsigned VslduInsnQueueDepth = 4; // (Allowing Reduction operations)
  localparam int unsigned VtopkuInsnQueueDepth = 4;
  // 
  localparam int unsigned NoneInsnQueueDepth = 1;
  
  //////////////////////////////////
  //  SYSTEM FUCTION REDEFINITION //
  //////////////////////////////////
  // Customize the clog2 function and select the implementation method based on whether it is comprehensive
  function automatic int unsigned custom_clog2(input int unsigned value);
    `ifdef SYNTHESIS
      // Using custom implementation during synthesis
      int unsigned result;
      result = 0;

      // Handle special cases: if the value is 0 or 1, return 0
      if (value <= 1) begin
        return 0;
      end

      // Calculate log2 and round it up
      value = value - 1;
      while (value > 0) begin
        value = value >> 1;
        result = result + 1;
      end

      return result;
    `else
      // Use system functions when not synthesized
      return $clog2(value);
    `endif
  endfunction


  ///////////////////
  //  Definitions  //
  ///////////////////

  typedef logic [custom_clog2(NrVInsn)-1:0] vid_t;
  typedef logic [ELEN-1:0] elen_t;

  //////////////////
  //  Operations  //
  //////////////////
  // 94 operations
  typedef enum logic [6:0] {
    //////////////////
    //  Matrix ops  //  
    //////////////////
    // 9
    MZERO, // 1
    // Matrix Multi-ACC unit (Interger)
    VMM, VMMU, MCONV, MCONVU,  // 4
    // Matrix Multi-ACC unit (Floating-point)
    VFMM, VFMMB, MFCONV, MFCONVB, // 4
    //////////////////
    //  Vector ops  //
    //////////////////
    // 63
    // COPY
    VCOPY, VZERO, // 2
    // ALU, Arithmetic and logic instructions (integer & float)
    //VADD, VSUB, VMUL, VDIV, VREM, VMACC, VNMSAC, VMADD, VNMSUB,  // 9
    VADD, VSUB, VMUL, VMACC, VNMSAC, VMADD, VNMSUB,  // 9
    // compare instructions (integer & float)
    //VMSEQ, VMSNE, VMSLT, VMSLE, VMSGT, VMSGE,  // 6
    // Quantization instructions (from FP32 to FP16, BF16, INT4, INT8, INT16), q = f/s + z
    //QUANTS, QUANTU, QUANTBF16, QUANTFP16, // 4 
    // Dequantization instructions (from INT4, INT8, INT16, FP16, BF16 to FP32), f = q*s - z
    DEQUANTS, DEQUANTU, DEQUANTBF16, DEQUANTFP16, // 4
    // Mixed precision instructions (s-v, FP32-INT4, FP32-INT8, FP32-INT16)
    FIADD, FISUB, FIMUL, FIMACC, FIMADD, FINMSUB,   // 8
    // sign inversion
    VREVERSE, VABS, // 2   
    // datatype conversion
    VFP2I, VFP2UI, VI2FP, VUI2FP, VBF2FP, VFP2BF, // 6
    // DIV&REM insn
    VDIV, VREM, FIDIV, FIREM, 
    // Quantization instructions (from FP32 to FP16, BF16, INT4, INT8, INT16), q = f/s + z
    QUANTS, QUANTU, QUANTBF16, QUANTFP16, // 4 
    // compare instructions (integer & float)
    VMSEQ, VMSNE, VMSLT, VMSLE, VMSGT, VMSGE,  // 6
    // Compress    
    VMERGE, VCOMPRESS, // 2 
    // Fast special funtion instructions (integer)
    FASTTANH, FASTSIGMOID, FASTSWISH, FASTMISH, FASTGELU, // 5
    // Multi-operation function instructions (single operation)
    RECIP, LOG2, EXP2, RSQRT,  // 4
    // Multi-operation function instructions with ALU (multi-operations)
    TANH, SIGMOID, SWISH, MISH, GELU, // 5
    // reduction instructions (integer)
    VREDSUM, VREDMIN, VREDMAX, // 3
    // Slide instructions
    VSLIDEUP, VSLIDEDOWN, // 2
    // top-selection instructions
    TOPK, // 1
    ///////////////////////////
    // Memory instructions  //
    ///////////////////////////
    // 22
    // Load instructions(vector{unit, stride, 2-D}, accumulative{unit, stride, 2-D}, matrix{2-D, Reshape,Transpose} load)
    VLE, VLSE, VLRSE, VLTDE, ALE, ALSE, ALRSE, ALTDE, MLE, MLRSE, MLTSE, // 11
    // Store instructionsvector{unit, stride, 2-D}, accumulative{unit, stride, 2-D}, matrix{2-D, Reshape, Transpose} store)
    VSE, VSSE, VSRSE, VSTDE, ASE, ASSE, ASRSE, ASTDE, MSE, MSRSE, MSTSE // 11
  } riva_op_e;  //

  // Return true if op is a load operation
  function automatic logic is_load(riva_op_e op);
    is_load = op inside {[VLE:MLTSE]};
  endfunction : is_load

  // Return true if op is a store operation
  function automatic logic is_store(riva_op_e op);
    is_store = op inside {[VSE:MSTSE]};
  endfunction : is_store

  // Return true of op is either VCPOP or VFIRST
  function automatic logic vd_scalar(riva_op_e op);
    vd_scalar = op inside {[VREDSUM:VREDMAX]};
  endfunction : vd_scalar


  //localparam int unsigned NumConversions = 10;

  typedef enum logic [3:0] {
    OpQueueUINT4  = 4'b0000, // 4-bit unsigned integer
    OpQueueUINT8  = 4'b0001, // 8-bit unsigned integerVMMU, 
    OpQueueUINT16 = 4'b0010, // 16-bit unsigned integer
    OpQueueUINT32 = 4'b0011, // 32-bit unsigned integer
    OpQueueINT4   = 4'b1000, // 4-bit signed integer
    OpQueueINT8   = 4'b1001, // 8-bit signed integer
    OpQueueINT16  = 4'b1010, // 16-bit signed integer
    OpQueueINT32  = 4'b1011, // 32-bit signed integer
    OpQueueNone   = 4'b0101, // NO type
    OpQueueBF16   = 4'b1100,  // 16-bit brain floating-point
    OpQueueFP16   = 4'b1110, // 16-bit floating-point
    OpQueueFP32   = 4'b1111  // 32-bit floating-point
  } opqueue_type_e;

  typedef enum logic [1:0] {
    CVT_WIDE   = 2'b00,
    CVT_SAME   = 2'b01,
    CVT_NARROW = 2'b10
  } resize_e;

  typedef enum logic [1:0] {
    NO_RED, 
    FMAU_RED,
    COMPU_RED
  } sldu_mux_e;

  ////////////////////
  //  PE interface  //
  ////////////////////

  // // Those are Function Units (FUs) of RIVA;
  // localparam int unsigned NrMVFUs = 11;
  // typedef enum logic [custom_clog2(NrVFUs)-1:0] { 
  //   FU_MMu, FU_FMAu, FU_DIVu, FU_COMPu, FU_SFu, FU_MFu, FU_SLDu, FU_TopKu, FU_LOADu, FU_STOREu, FU_None
  // } mvfu_e;

  // typedef enum logic [1:0] {
  //   OffsetLoad, OffsetStore, OffsetTopk, OffsetSlide
  // } mvfu_offset_e;

  // ////////////////////////
  // //  MMU definitions   //
  // ////////////////////////
  // typedef struct packed {
  //   logic overflow; // do not care invalid address or beyond (Base addr + mlen)
  //   //
	//   logic jump; // skip some matrix source operand
  //   logic sd;   // slide direction, 1: up, 0: down
  //   logic [1:0] sd_len; // stride length, 0~3.
  //   logic fpad;
  //   logic bpad;
  // } mu_cgfs_t;

  // ////////////////////////
  // //  Lane definitions  //
  // ////////////////////////

  // // There are seven operand queues, serving operands to the different functional units of each lane
  // localparam int unsigned NrOperandQueues = 10;
  // typedef enum logic [custom_clog2(NrOperandQueues)-1:0] {
  //   MMuM, MMuV, MMuA, AluA, AluB, AluC, SFuA, TopKuA, StA, SlideAddrGenA
  // } opqueue_e;

  // Each lane has eight VRF banks
  // NOTE: values != 8 are not supported
  localparam int unsigned NrVRFBanksPerLane = 8;

  /////////////////////////////////////////
  //  Vector Load/Store Unit definition  //
  /////////////////////////////////////////

  // The address generation unit makes requests on the AR/AW buses, while the load and
  // store unit handle the R, W, and B buses. The latter need some information about the
  // // original request, namely the fields below.
  // typedef struct packed {
  //   axi_pkg::largest_addr_t addr;
  //   axi_pkg::size_t size;
  //   axi_pkg::len_t len;
  //   logic is_load;
  //   logic is_exception;
  // } addrgen_axi_req_t;

  ////////////////
  // Exceptions //
  ////////////////

  // End-to-end store exception latency, i.e.,
  // the latency from the addrgen store exception to the opqueues.
  // We keep it as a define to implement conditional declaration.
  `define StuExLat 1
  localparam int unsigned StuExLat = `StuExLat;

  function automatic integer unsigned idx_width (input integer unsigned num_idx);
    return (num_idx > 32'd1) ? unsigned'(custom_clog2(num_idx)) : 32'd1;
  endfunction


  // function automatic int unsigned div_power2_by_int(
  //   input int unsigned A,  // inval A (power of 2, 1~2^19)
  //   input int unsigned B   // inval B (0~ 2^13)
  // );
  //   // return value
  //   int unsigned C;  
  //   // special case
  //   if (B == 0) begin
  //     // NaN
  //     return 0;
  //   end
  //   else if (B == 1) begin
  //     // A
  //     return A;
  //   end    

  //   int unsigned log_B = 0;
  //   int unsigned B_temp = B;

  //   //logic [3:0] log_b_left, log_b_right;
  //   // find the log of B
  //   casex (B_temp[15:0])
  //     16'b1xxx_xxxx_xxxx_xxxx: log_B = 16'd15;
  //     16'b01xx_xxxx_xxxx_xxxx: log_B = 16'd14;
  //     16'b001x_xxxx_xxxx_xxxx: log_B = 16'd13;
  //     16'b0001_xxxx_xxxx_xxxx: log_B = 16'd12;
  //     16'b0000_1xxx_xxxx_xxxx: log_B = 16'd11;
  //     16'b0000_01xx_xxxx_xxxx: log_B = 16'd10;
  //     16'b0000_001x_xxxx_xxxx: log_B = 16'd9;
  //     16'b0000_0001_xxxx_xxxx: log_B = 16'd8;
  //     16'b0000_0000_1xxx_xxxx: log_B = 16'd7;
  //     16'b0000_0000_01xx_xxxx: log_B = 16'd6;
  //     16'b0000_0000_001x_xxxx: log_B = 16'd5;
  //     16'b0000_0000_0001_xxxx: log_B = 16'd4;
  //     16'b0000_0000_0000_1xxx: log_B = 16'd3;
  //     16'b0000_0000_0000_01xx: log_B = 16'd2;
  //     16'b0000_0000_0000_001x: log_B = 16'd1;
  //     default:                 log_B = 16'd0;
  //   endcase

  //   // Binary search
  //   if (B & (B - 1)) begin
  //     // B is not 2^N
  //     // initial guess
  //     int unsigned initial_guess = A >> log_B;
  //     // Make sure initial guess are reasonable
  //     int unsigned left = (initial_guess > 0) ? (initial_guess >> 1) : 0;
  //     int unsigned right = ((initial_guess << 1) < A) ? (initial_guess << 1) : A;    

  //     // Binary search
  //     if ((right * B) < A) right = A;

  //     for (int i = 0; i < 22; i++) begin // 20 > log2(2^19)
  //       if (left < right) begin
  //         int unsigned mid = (left + right + 1) >> 1;
  //         if ((mid * B) <= A) begin
  //           left = mid;
  //         end else begin
  //           right = mid - 1;
  //         end
  //       end 
  //       else begin
  //         break; // Exit loop when left >= right
  //       end
  //     end

  //     C = left;
  //   end  else begin
  //     // B is 2^N
  //     C = A >> log_B;
  //   end
  //   return C;
  // endfunction

endpackage