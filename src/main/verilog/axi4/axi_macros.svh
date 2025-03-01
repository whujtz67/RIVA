`ifndef AXI4_MACROS_SVH_
`define AXI4_MACROS_SVH_

// -------------------------------------
// AXI4 Wire Defines
// -------------------------------------
`define AXI_AW_WIRES(prefix, idBits, addrBits, userBits) \
  wire [idBits  -1:0] prefix``_aw_id    ; \
  wire [addrBits-1:0] prefix``_aw_addr  ; \
  wire [7         :0] prefix``_aw_len   ; \
  wire [2         :0] prefix``_aw_size  ; \
  wire [1         :0] prefix``_aw_burst ; \
  wire [1         :0] prefix``_aw_lock  ; \
  wire [3         :0] prefix``_aw_cache ; \
  wire [2         :0] prefix``_aw_prot  ; \
  wire [3         :0] prefix``_aw_qos   ; \
  wire [3         :0] prefix``_aw_region; \
  wire [userBits-1:0] prefix``_aw_user  ; \
  wire                prefix``_aw_valid ; \
  wire                prefix``_aw_ready ;

`define AXI_AR_WIRES(prefix, idBits, addrBits, userBits) \
  wire [idBits  -1:0] prefix``_ar_id    ; \
  wire [addrBits-1:0] prefix``_ar_addr  ; \
  wire [7         :0] prefix``_ar_len   ; \
  wire [2         :0] prefix``_ar_size  ; \
  wire [1         :0] prefix``_ar_burst ; \
  wire [1         :0] prefix``_ar_lock  ; \
  wire [3         :0] prefix``_ar_cache ; \
  wire [2         :0] prefix``_ar_prot  ; \
  wire [3         :0] prefix``_ar_qos   ; \
  wire [3         :0] prefix``_ar_region; \
  wire [userBits-1:0] prefix``_ar_user  ; \
  wire                prefix``_ar_valid ; \
  wire                prefix``_ar_ready ;

`define AXI_W_WIRES(prefix, dataBits, userBits) \
  wire [dataBits  -1:0] prefix``_w_data ; \
  wire [dataBits/8-1:0] prefix``_w_strb ; \
  wire                  prefix``_w_last ; \
  wire [userBits  -1:0] prefix``_w_user ; \
  wire                  prefix``_w_valid; \
  wire                  prefix``_w_ready;

`define AXI_R_WIRES(prefix, idBits, dataBits, userBits) \
  wire [idBits  -1:0] prefix``_r_id   ; \
  wire [dataBits-1:0] prefix``_r_data ; \
  wire [1         :0] prefix``_r_resp ; \
  wire                prefix``_r_last ; \
  wire [userBits-1:0] prefix``_r_user ; \
  wire                prefix``_r_valid; \
  wire                prefix``_r_ready;

`define AXI_B_WIRES(prefix, idBits, userBits) \
  wire [idBits  -1:0] prefix``_b_id   ; \
  wire [1         :0] prefix``_b_resp ; \
  wire [userBits-1:0] prefix``_b_user ; \
  wire                prefix``_b_valid; \
  wire                prefix``_b_ready;

`define AXI_WR_WIRES(prefix, idBits, addrBits, dataBits, userBits) \
  `AXI_AW_WIRES(prefix, idBits, addrBits, userBits) \
  `AXI_W_WIRES (prefix, dataBits, userBits)         \
  `AXI_B_WIRES (prefix, idBits, userBits)

`define AXI_RD_WIRES(prefix, idBits, addrBits, dataBits, userBits) \
  `AXI_AR_WIRES(prefix, idBits, addrBits, userBits) \
  `AXI_R_WIRES (prefix, idBits, dataBits, userBits)

`define AXI_WIRES(prefix, idBits, addrBits, dataBits, userBits) \
  `AXI_WR_WIRES(prefix, idBits, addrBits, dataBits, userBits) \
  `AXI_RD_WIRES(prefix, idBits, addrBits, dataBits, userBits)

// -------------------------------------
// AXI4 INST
// -------------------------------------
`define AXI_AW_INST(portPref, sigPref) \
  .``portPref``_aw_id     (``sigPref``_aw_id    ), \
  .``portPref``_aw_addr   (``sigPref``_aw_addr  ), \
  .``portPref``_aw_len    (``sigPref``_aw_len   ), \
  .``portPref``_aw_size   (``sigPref``_aw_size  ), \
  .``portPref``_aw_burst  (``sigPref``_aw_burst ), \
  .``portPref``_aw_lock   (``sigPref``_aw_lock  ), \
  .``portPref``_aw_cache  (``sigPref``_aw_cache ), \
  .``portPref``_aw_prot   (``sigPref``_aw_prot  ), \
  .``portPref``_aw_qos    (``sigPref``_aw_qos   ), \
  .``portPref``_aw_region (``sigPref``_aw_region), \
  .``portPref``_aw_user   (``sigPref``_aw_user  ), \
  .``portPref``_aw_valid  (``sigPref``_aw_valid ), \
  .``portPref``_aw_ready  (``sigPref``_aw_ready ),

`define AXI_AR_INST(portPref, sigPref) \
  .``portPref``_ar_id     (``sigPref``_ar_id    ), \
  .``portPref``_ar_addr   (``sigPref``_ar_addr  ), \
  .``portPref``_ar_len    (``sigPref``_ar_len   ), \
  .``portPref``_ar_size   (``sigPref``_ar_size  ), \
  .``portPref``_ar_burst  (``sigPref``_ar_burst ), \
  .``portPref``_ar_lock   (``sigPref``_ar_lock  ), \
  .``portPref``_ar_cache  (``sigPref``_ar_cache ), \
  .``portPref``_ar_prot   (``sigPref``_ar_prot  ), \
  .``portPref``_ar_qos    (``sigPref``_ar_qos   ), \
  .``portPref``_ar_region (``sigPref``_ar_region), \
  .``portPref``_ar_user   (``sigPref``_ar_user  ), \
  .``portPref``_ar_valid  (``sigPref``_ar_valid ), \
  .``portPref``_ar_ready  (``sigPref``_ar_ready ),

`define AXI_W_INST(portPref, sigPref) \
  .``portPref``_w_data    (``sigPref``_w_data   ), \
  .``portPref``_w_strb    (``sigPref``_w_strb   ), \
  .``portPref``_w_last    (``sigPref``_w_last   ), \
  .``portPref``_w_user    (``sigPref``_w_user   ), \
  .``portPref``_w_valid   (``sigPref``_w_valid  ), \
  .``portPref``_w_ready   (``sigPref``_w_ready  ),

`define AXI_R_INST(portPref, sigPref) \
  .``portPref``_r_id      (``sigPref``_r_id     ), \
  .``portPref``_r_data    (``sigPref``_r_data   ), \
  .``portPref``_r_resp    (``sigPref``_r_resp   ), \
  .``portPref``_r_last    (``sigPref``_r_last   ), \
  .``portPref``_r_user    (``sigPref``_r_user   ), \
  .``portPref``_r_valid   (``sigPref``_r_valid  ), \
  .``portPref``_r_ready   (``sigPref``_r_ready  ),

`define AXI_B_INST(portPref, sigPref) \
  .``portPref``_b_id      (``sigPref``_b_id     ), \
  .``portPref``_b_resp    (``sigPref``_b_resp   ), \
  .``portPref``_b_user    (``sigPref``_b_user   ), \
  .``portPref``_b_valid   (``sigPref``_b_valid  ), \
  .``portPref``_b_ready   (``sigPref``_b_ready  ),

`define AXI_WR_INST(portPref, sigPref) \
  `AXI_AW_INST(portPref, sigPref) \
  `AXI_W_INST (portPref, sigPref) \
  `AXI_B_INST (portPref, sigPref)

`define AXI_RD_INST(portPref, sigPref) \
  `AXI_AR_INST(portPref, sigPref) \
  `AXI_R_INST (portPref, sigPref)

`define AXI_INST(portPref, sigPref) \
  `AXI_WR_INST(portPref, sigPref) \
  `AXI_RD_INST(portPref, sigPref)

// -------------------------------------
// AXI4 Assign
// -------------------------------------
`define AXI_AW_ASG(slvPref, mstPref) \
  assign slvPref``_aw_id     = mstPref``_aw_id    ; \
  assign slvPref``_aw_addr   = mstPref``_aw_addr  ; \
  assign slvPref``_aw_len    = mstPref``_aw_len   ; \
  assign slvPref``_aw_size   = mstPref``_aw_size  ; \
  assign slvPref``_aw_burst  = mstPref``_aw_burst ; \
  assign slvPref``_aw_lock   = mstPref``_aw_lock  ; \
  assign slvPref``_aw_cache  = mstPref``_aw_cache ; \
  assign slvPref``_aw_prot   = mstPref``_aw_prot  ; \
  assign slvPref``_aw_qos    = mstPref``_aw_qos   ; \
  assign slvPref``_aw_region = mstPref``_aw_region; \
  assign slvPref``_aw_user   = mstPref``_aw_user  ; \
  assign slvPref``_aw_valid  = mstPref``_aw_valid ; \
  assign mstPref``_aw_ready  = slvPref``_aw_ready ;

`define AXI_AR_ASG(slvPref, mstPref) \
  assign slvPref``_ar_id     = mstPref``_ar_id    ; \
  assign slvPref``_ar_addr   = mstPref``_ar_addr  ; \
  assign slvPref``_ar_len    = mstPref``_ar_len   ; \
  assign slvPref``_ar_size   = mstPref``_ar_size  ; \
  assign slvPref``_ar_burst  = mstPref``_ar_burst ; \
  assign slvPref``_ar_lock   = mstPref``_ar_lock  ; \
  assign slvPref``_ar_cache  = mstPref``_ar_cache ; \
  assign slvPref``_ar_prot   = mstPref``_ar_prot  ; \
  assign slvPref``_ar_qos    = mstPref``_ar_qos   ; \
  assign slvPref``_ar_region = mstPref``_ar_region; \
  assign slvPref``_ar_user   = mstPref``_ar_user  ; \
  assign slvPref``_ar_valid  = mstPref``_ar_valid ; \
  assign mstPref``_ar_ready  = slvPref``_ar_ready ;

`define AXI_W_ASG(slvPref, mstPref) \
  assign slvPref``_w_data    = mstPref``_w_data   ; \
  assign slvPref``_w_strb    = mstPref``_w_strb   ; \
  assign slvPref``_w_last    = mstPref``_w_last   ; \
  assign slvPref``_w_user    = mstPref``_w_user   ; \
  assign slvPref``_w_valid   = mstPref``_w_valid  ; \
  assign mstPref``_w_ready   = slvPref``_w_ready  ;

`define AXI_R_ASG(slvPref, mstPref) \
  assign slvPref``_r_id      = mstPref``_r_id     ; \
  assign slvPref``_r_data    = mstPref``_r_data   ; \
  assign slvPref``_r_resp    = mstPref``_r_resp   ; \
  assign slvPref``_r_last    = mstPref``_r_last   ; \
  assign slvPref``_r_user    = mstPref``_r_user   ; \
  assign slvPref``_r_valid   = mstPref``_r_valid  ; \
  assign mstPref``_r_ready   = slvPref``_r_ready  ;

`define AXI_B_ASG(slvPref, mstPref) \
  assign slvPref``_b_id      = mstPref``_b_id     ; \
  assign slvPref``_b_resp    = mstPref``_b_resp   ; \
  assign slvPref``_b_user    = mstPref``_b_user   ; \
  assign slvPref``_b_valid   = mstPref``_b_valid  ; \
  assign mstPref``_b_ready   = slvPref``_b_ready  ;

`define AXI_WR_ASG(slvPref, mstPref) \
  `AXI_AW_ASG(slvPref, mstPref) \
  `AXI_W_ASG (slvPref, mstPref) \
  `AXI_B_ASG (mstPref, slvPref)

`define AXI_RD_ASG(slvPref, mstPref) \
  `AXI_AR_ASG(slvPref, mstPref) \
  `AXI_R_ASG (mstPref, slvPref)

`define AXI_ASG(slvPref, mstPref) \
  `AXI_WR_ASG(slvPref, mstPref) \
  `AXI_RD_ASG(slvPref, mstPref)
`endif