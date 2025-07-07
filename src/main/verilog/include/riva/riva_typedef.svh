// Author: Chuan_nWang
// Description: RIVA specfic instruction interface definations.	
// RIVA: RISC-V artificial Intelligent Vector Accelerator

typedef struct packed {
  vid_t id; // ID of the vector instruction

  riva_op_e op; // Operation

  // Mask vector register operand
  logic vm;
  rvmv_pkg::vew_e eew_vmask;

  mvfu_e vfu; // VFU responsible for handling this instruction

  // Rescale vl taking into account the new and old EEW
  logic scale_vl;
  logic two_dim_vl;
  logic scale_al;
  logic scale_tile;

  // The lane that provides the first element of the computation
  logic [$clog2(MaxNrLanes)-1:0] start_lane;
  // The lane that provides the last element of the computation
  logic [$clog2(MaxNrLanes)-1:0] end_lane;


  // 1st vector & matrix register operand
  logic [4:0] vs1;
  //logic [1:0] ms1;
  logic use_mm_src1;
  logic use_src1;
  opqueue_type_e conversion_src1;
  rvmv_pkg::vew_e eew_src1;
  rvmv_pkg::vew_e old_eew_src1;

  // 2nd vector & matrix register operand
  logic [4:0] vs2;
  //logic [1:0] ms2;
  logic use_mm_src2;
  logic use_src2;
  opqueue_type_e conversion_src2;
  rvmv_pkg::vew_e eew_src2;

  // Use vd as an operand as well (e.g., vmacc)
  logic use_dest_op;
  logic use_mm_dest;

  // Scalar operand
  elen_t scalar_op1;
  logic use_scalar_op1;
  elen_t scalar_op2;
  logic use_scalar_op2;

  // If asserted: vs2 is kept in MulFPU opqueue C, and vd_op in MulFPU A
  logic swap_src2_dest_op;

  // 2nd scalar operand: stride for constant-strided vector load/stores
  elen_t stride;
  logic is_stride_np2;

  // Destination vector & matrix register
  logic [4:0] vd;
  //logic [1:0] md;
  logic use_dest;
  opqueue_type_e conversion_dest;

  // Effective length multiplier
  rvmv_pkg::vlmul_e evmul;
  rvmv_pkg::vlmul_e eamul;
  rvmv_pkg::vlmul_e emmul;

  // Rounding-Mode for FP operations
  fpnew_pkg::roundmode_e fp_rm;
  // Widen FP immediate (re-encoding)
  logic wide_fp_imm;
  // Resizing of FP conversions
  resize_e cvt_resize;

  // Matrix config info
  logic overflow; // do not care invalid address or beyond (Base addr + mlen)
  //
  logic jump; // skip some matrix source operand
  logic sd;   // slide direction, 1: up, 0: down
  logic [1:0] sd_len; // pad value or stride length, 0~3.
  logic fpad;  //  front pad indicator
  logic bpad;  //  back pad indicator
  
  // Vector machine metadata
  logic   two_dim_ts;
  vlen_t   vl;
  mlen_t tile;
  alen_t   al; // accu length and application length

  vlen_t vstart;
  rvmv_pkg::vtype_t vtype;

  // Hazards
  logic [NrVInsn-1:0] hazard_src1;
  logic [NrVInsn-1:0] hazard_src2;
  logic [NrVInsn-1:0] hazard_vm;
  logic [NrVInsn-1:0] hazard_dest;
} pe_req_t;

typedef struct packed {
  // Each set bit indicates that the corresponding vector loop has finished execution
  logic [NrVInsn-1:0] vinsn_done;
} pe_resp_t;
