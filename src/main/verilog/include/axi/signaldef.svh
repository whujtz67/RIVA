/// Help axi signal define
`ifndef AXI_SIGNALDEF_SVH_
`define AXI_SIGNALDEF_SVH_

// --------------------------------------
// AXI4(no ATOP) 5 Channels signal define(for npu_fullsys_top)
// --------------------------------------
// NOTE: Make sure typedef types correspond with the config of our npu!!!
`define AXI_SIGDEF_AW(prefix)               \
	id_t                prefix``_aw_id    ; \
	addr_t              prefix``_aw_addr  ; \
	axi_pkg::len_t      prefix``_aw_len   ; \
	axi_pkg::size_t     prefix``_aw_size  ; \
	axi_pkg::burst_t    prefix``_aw_burst ; \
	logic               prefix``_aw_lock  ; \
	axi_pkg::cache_t    prefix``_aw_cache ; \
	axi_pkg::prot_t     prefix``_aw_prot  ; \
	axi_pkg::qos_t      prefix``_aw_qos   ; \
	axi_pkg::region_t   prefix``_aw_region; \
	user_t              prefix``_aw_user  ; \
	logic               prefix``_aw_valid ; \
	logic               prefix``_aw_ready ;

`define AXI_SIGDEF_W(prefix)              \
	data_t              prefix``_w_data ; \
	strb_t              prefix``_w_strb ; \
	logic               prefix``_w_last ; \
	user_t              prefix``_w_user ; \
	logic               prefix``_w_valid; \
	logic               prefix``_w_ready;

`define AXI_SIGDEF_B(prefix)              \
	id_t                prefix``_b_id   ; \
	axi_pkg::resp_t     prefix``_b_resp ; \
	user_t              prefix``_b_user ; \
	logic               prefix``_b_valid; \
	logic               prefix``_b_ready;

`define AXI_SIGDEF_AR(prefix)               \
	id_t                prefix``_ar_id    ; \
	addr_t              prefix``_ar_addr  ; \
	axi_pkg::len_t      prefix``_ar_len   ; \
	axi_pkg::size_t     prefix``_ar_size  ; \
	axi_pkg::burst_t    prefix``_ar_burst ; \
	logic               prefix``_ar_lock  ; \
	axi_pkg::cache_t    prefix``_ar_cache ; \
	axi_pkg::prot_t     prefix``_ar_prot  ; \
	axi_pkg::qos_t      prefix``_ar_qos   ; \
	axi_pkg::region_t   prefix``_ar_region; \
	user_t              prefix``_ar_user  ; \
	logic               prefix``_ar_valid ; \
	logic               prefix``_ar_ready ;

`define AXI_SIGDEF_R(prefix)              \
	id_t                prefix``_r_id   ; \
	data_t              prefix``_r_data ; \
	axi_pkg::resp_t     prefix``_r_resp ; \
	logic               prefix``_r_last ; \
	user_t              prefix``_r_user ; \
	logic               prefix``_r_valid; \
	logic               prefix``_r_ready;

`define SIGDEF_REQRESP(__row, __col, __prefix) \
axi_req_t   [Cfg.NoMstPorts-1:0]  ``__prefix``_mst_reqs_``__row``__col ;  \
axi_resp_t  [Cfg.NoMstPorts-1:0]  ``__prefix``_mst_resps_``__row``__col;  \
axi_req_t   [Cfg.NoSlvPorts-1:0]  ``__prefix``_slv_reqs_``__row``__col ;  \
axi_resp_t  [Cfg.NoSlvPorts-1:0]  ``__prefix``_slv_resps_``__row``__col;  

`endif
