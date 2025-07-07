// Copyright (c) 2014-2018 ETH Zurich, University of Bologna
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Authors:
// - Andreas Kurth <akurth@iis.ee.ethz.ch>
// - Nils Wistoff <nwistoff@iis.ee.ethz.ch>

// Macros to assign AXI Interfaces and Structs

`ifndef AXI_ASSIGN_SVH_
`define AXI_ASSIGN_SVH_

/// **************** There shouldn't be " " after the "\"!!!!!! ****************  //////

////////////////////////////////////////////////////////////////////////////////////////////////////
// Internal implementation for assigning one AXI struct or interface to another struct or interface.
// The path to the signals on each side is defined by the `__sep*` arguments.  The `__opt_as`
// argument allows to use this standalone (with `__opt_as = assign`) or in assignments inside
// processes (with `__opt_as` void).
// sep可以是'_'也可以是'.'
`define __AXI_TO_AW(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)   \
  __opt_as __lhs``__lhs_sep``id     = __rhs``__rhs_sep``id;         \
  __opt_as __lhs``__lhs_sep``addr   = __rhs``__rhs_sep``addr;       \
  __opt_as __lhs``__lhs_sep``len    = __rhs``__rhs_sep``len;        \
  __opt_as __lhs``__lhs_sep``size   = __rhs``__rhs_sep``size;       \
  __opt_as __lhs``__lhs_sep``burst  = __rhs``__rhs_sep``burst;      \
  __opt_as __lhs``__lhs_sep``lock   = __rhs``__rhs_sep``lock;       \
  __opt_as __lhs``__lhs_sep``cache  = __rhs``__rhs_sep``cache;      \
  __opt_as __lhs``__lhs_sep``prot   = __rhs``__rhs_sep``prot;       \
  __opt_as __lhs``__lhs_sep``qos    = __rhs``__rhs_sep``qos;        \
  __opt_as __lhs``__lhs_sep``region = __rhs``__rhs_sep``region;     \
  __opt_as __lhs``__lhs_sep``user   = __rhs``__rhs_sep``user;
`define __AXI_TO_W(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)    \
  __opt_as __lhs``__lhs_sep``data   = __rhs``__rhs_sep``data;       \
  __opt_as __lhs``__lhs_sep``strb   = __rhs``__rhs_sep``strb;       \
  __opt_as __lhs``__lhs_sep``last   = __rhs``__rhs_sep``last;       \
  __opt_as __lhs``__lhs_sep``user   = __rhs``__rhs_sep``user;
`define __AXI_TO_B(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)    \
  __opt_as __lhs``__lhs_sep``id     = __rhs``__rhs_sep``id;         \
  __opt_as __lhs``__lhs_sep``resp   = __rhs``__rhs_sep``resp;       \
  __opt_as __lhs``__lhs_sep``user   = __rhs``__rhs_sep``user;
`define __AXI_TO_AR(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)   \
  __opt_as __lhs``__lhs_sep``id     = __rhs``__rhs_sep``id;         \
  __opt_as __lhs``__lhs_sep``addr   = __rhs``__rhs_sep``addr;       \
  __opt_as __lhs``__lhs_sep``len    = __rhs``__rhs_sep``len;        \
  __opt_as __lhs``__lhs_sep``size   = __rhs``__rhs_sep``size;       \
  __opt_as __lhs``__lhs_sep``burst  = __rhs``__rhs_sep``burst;      \
  __opt_as __lhs``__lhs_sep``lock   = __rhs``__rhs_sep``lock;       \
  __opt_as __lhs``__lhs_sep``cache  = __rhs``__rhs_sep``cache;      \
  __opt_as __lhs``__lhs_sep``prot   = __rhs``__rhs_sep``prot;       \
  __opt_as __lhs``__lhs_sep``qos    = __rhs``__rhs_sep``qos;        \
  __opt_as __lhs``__lhs_sep``region = __rhs``__rhs_sep``region;     \
  __opt_as __lhs``__lhs_sep``user   = __rhs``__rhs_sep``user;
`define __AXI_TO_R(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)    \
  __opt_as __lhs``__lhs_sep``id     = __rhs``__rhs_sep``id;         \
  __opt_as __lhs``__lhs_sep``data   = __rhs``__rhs_sep``data;       \
  __opt_as __lhs``__lhs_sep``resp   = __rhs``__rhs_sep``resp;       \
  __opt_as __lhs``__lhs_sep``last   = __rhs``__rhs_sep``last;       \
  __opt_as __lhs``__lhs_sep``user   = __rhs``__rhs_sep``user;
`define __AXI_TO_REQ(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)  \
  `__AXI_TO_AW(__opt_as, __lhs.aw, __lhs_sep, __rhs.aw, __rhs_sep)  \
  __opt_as __lhs.aw_valid = __rhs.aw_valid;                         \
  `__AXI_TO_W(__opt_as, __lhs.w, __lhs_sep, __rhs.w, __rhs_sep)     \
  __opt_as __lhs.w_valid = __rhs.w_valid;                           \
  __opt_as __lhs.b_ready = __rhs.b_ready;                           \
  `__AXI_TO_AR(__opt_as, __lhs.ar, __lhs_sep, __rhs.ar, __rhs_sep)  \
  __opt_as __lhs.ar_valid = __rhs.ar_valid;                         \
  __opt_as __lhs.r_ready = __rhs.r_ready;
`define __AXI_TO_RESP(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep) \
  __opt_as __lhs.aw_ready = __rhs.aw_ready;                         \
  __opt_as __lhs.ar_ready = __rhs.ar_ready;                         \
  __opt_as __lhs.w_ready = __rhs.w_ready;                           \
  __opt_as __lhs.b_valid = __rhs.b_valid;                           \
  `__AXI_TO_B(__opt_as, __lhs.b, __lhs_sep, __rhs.b, __rhs_sep)     \
  __opt_as __lhs.r_valid = __rhs.r_valid;                           \
  `__AXI_TO_R(__opt_as, __lhs.r, __lhs_sep, __rhs.r, __rhs_sep)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning one AXI4+ATOP interface to another, as if you would do `assign slv = mst;`
//
// The channel assignments `AXI_ASSIGN_XX(dst, src)` assign all payload and the valid signal of the
// `XX` channel from the `src` to the `dst` interface and they assign the ready signal from the
// `src` to the `dst` interface.
// The interface assignment `AXI_ASSIGN(dst, src)` assigns all channels including handshakes as if
// `src` was the master of `dst`.
//
// Usage Example:
// `AXI_ASSIGN(slv, mst)
// `AXI_ASSIGN_AW(dst, src)
// `AXI_ASSIGN_R(dst, src)
`define AXI_ASSIGN_AW(dst, src)               \
  `__AXI_TO_AW(assign, dst.aw, _, src.aw, _)  \
  assign dst.aw_valid = src.aw_valid;         \
  assign src.aw_ready = dst.aw_ready;
`define AXI_ASSIGN_W(dst, src)                \
  `__AXI_TO_W(assign, dst.w, _, src.w, _)     \
  assign dst.w_valid  = src.w_valid;          \
  assign src.w_ready  = dst.w_ready;
`define AXI_ASSIGN_B(dst, src)                \
  `__AXI_TO_B(assign, dst.b, _, src.b, _)     \
  assign dst.b_valid  = src.b_valid;          \
  assign src.b_ready  = dst.b_ready;
`define AXI_ASSIGN_AR(dst, src)               \
  `__AXI_TO_AR(assign, dst.ar, _, src.ar, _)  \
  assign dst.ar_valid = src.ar_valid;         \
  assign src.ar_ready = dst.ar_ready;
`define AXI_ASSIGN_R(dst, src)                \
  `__AXI_TO_R(assign, dst.r, _, src.r, _)     \
  assign dst.r_valid  = src.r_valid;          \
  assign src.r_ready  = dst.r_ready;
`define AXI_ASSIGN(slv, mst)  \
  `AXI_ASSIGN_AW(slv, mst)    \
  `AXI_ASSIGN_W(slv, mst)     \
  `AXI_ASSIGN_B(mst, slv)     \
  `AXI_ASSIGN_AR(slv, mst)    \
  `AXI_ASSIGN_R(mst, slv)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning a AXI4+ATOP interface to a monitor modport, as if you would do `assign mon = axi_if;`
//
// The channel assignment `AXI_ASSIGN_MONITOR(mon_dv, axi_if)` assigns all signals from `axi_if`
// to the `mon_dv` interface.
//
// Usage Example:
// `AXI_ASSIGN_MONITOR(mon_dv, axi_if)
`define AXI_ASSIGN_MONITOR(mon_dv, axi_if)          \
  `__AXI_TO_AW(assign, mon_dv.aw, _, axi_if.aw, _)  \
  assign mon_dv.aw_valid  = axi_if.aw_valid;        \
  assign mon_dv.aw_ready  = axi_if.aw_ready;        \
  `__AXI_TO_W(assign, mon_dv.w, _, axi_if.w, _)     \
  assign mon_dv.w_valid   = axi_if.w_valid;         \
  assign mon_dv.w_ready   = axi_if.w_ready;         \
  `__AXI_TO_B(assign, mon_dv.b, _, axi_if.b, _)     \
  assign mon_dv.b_valid   = axi_if.b_valid;         \
  assign mon_dv.b_ready   = axi_if.b_ready;         \
  `__AXI_TO_AR(assign, mon_dv.ar, _, axi_if.ar, _)  \
  assign mon_dv.ar_valid  = axi_if.ar_valid;        \
  assign mon_dv.ar_ready  = axi_if.ar_ready;        \
  `__AXI_TO_R(assign, mon_dv.r, _, axi_if.r, _)     \
  assign mon_dv.r_valid   = axi_if.r_valid;         \
  assign mon_dv.r_ready   = axi_if.r_ready;
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Setting an interface from channel or request/response structs inside a process.
//
// The channel macros `AXI_SET_FROM_XX(axi_if, xx_struct)` set the payload signals of the `axi_if`
// interface from the signals in `xx_struct`.  They do not set the handshake signals.
// The request macro `AXI_SET_FROM_REQ(axi_if, req_struct)` sets all request channels (AW, W, AR)
// and the request-side handshake signals (AW, W, and AR valid and B and R ready) of the `axi_if`
// interface from the signals in `req_struct`.
// The response macro `AXI_SET_FROM_RESP(axi_if, resp_struct)` sets both response channels (B and R)
// and the response-side handshake signals (B and R valid and AW, W, and AR ready) of the `axi_if`
// interface from the signals in `resp_struct`.
//
// Usage Example:
// always_comb begin
//   `AXI_SET_FROM_REQ(my_if, my_req_struct)
// end
`define AXI_SET_FROM_AW(axi_if, aw_struct)      `__AXI_TO_AW(, axi_if.aw, _, aw_struct, .)
`define AXI_SET_FROM_W(axi_if, w_struct)        `__AXI_TO_W(, axi_if.w, _, w_struct, .)
`define AXI_SET_FROM_B(axi_if, b_struct)        `__AXI_TO_B(, axi_if.b, _, b_struct, .)
`define AXI_SET_FROM_AR(axi_if, ar_struct)      `__AXI_TO_AR(, axi_if.ar, _, ar_struct, .)
`define AXI_SET_FROM_R(axi_if, r_struct)        `__AXI_TO_R(, axi_if.r, _, r_struct, .)
`define AXI_SET_FROM_REQ(axi_if, req_struct)    `__AXI_TO_REQ(, axi_if, _, req_struct, .)
`define AXI_SET_FROM_RESP(axi_if, resp_struct)  `__AXI_TO_RESP(, axi_if, _, resp_struct, .)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning an interface from channel or request/response structs outside a process.
//
// The channel macros `AXI_ASSIGN_FROM_XX(axi_if, xx_struct)` assign the payload signals of the
// `axi_if` interface from the signals in `xx_struct`.  They do not assign the handshake signals.
// The request macro `AXI_ASSIGN_FROM_REQ(axi_if, req_struct)` assigns all request channels (AW, W,
// AR) and the request-side handshake signals (AW, W, and AR valid and B and R ready) of the
// `axi_if` interface from the signals in `req_struct`.
// The response macro `AXI_ASSIGN_FROM_RESP(axi_if, resp_struct)` assigns both response channels (B
// and R) and the response-side handshake signals (B and R valid and AW, W, and AR ready) of the
// `axi_if` interface from the signals in `resp_struct`.
//
// Usage Example:
// `AXI_ASSIGN_FROM_REQ(my_if, my_req_struct)
`define AXI_ASSIGN_FROM_AW(axi_if, aw_struct)     `__AXI_TO_AW(assign, axi_if.aw, _, aw_struct, .)
`define AXI_ASSIGN_FROM_W(axi_if, w_struct)       `__AXI_TO_W(assign, axi_if.w, _, w_struct, .)
`define AXI_ASSIGN_FROM_B(axi_if, b_struct)       `__AXI_TO_B(assign, axi_if.b, _, b_struct, .)
`define AXI_ASSIGN_FROM_AR(axi_if, ar_struct)     `__AXI_TO_AR(assign, axi_if.ar, _, ar_struct, .)
`define AXI_ASSIGN_FROM_R(axi_if, r_struct)       `__AXI_TO_R(assign, axi_if.r, _, r_struct, .)
`define AXI_ASSIGN_FROM_REQ(axi_if, req_struct)   `__AXI_TO_REQ(assign, axi_if, _, req_struct, .)
`define AXI_ASSIGN_FROM_RESP(axi_if, resp_struct) `__AXI_TO_RESP(assign, axi_if, _, resp_struct, .)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Setting channel or request/response structs from an interface inside a process.
//
// The channel macros `AXI_SET_TO_XX(xx_struct, axi_if)` set the signals of `xx_struct` to the
// payload signals of that channel in the `axi_if` interface.  They do not set the handshake
// signals.
// The request macro `AXI_SET_TO_REQ(axi_if, req_struct)` sets all signals of `req_struct` (i.e.,
// request channel (AW, W, AR) payload and request-side handshake signals (AW, W, and AR valid and
// B and R ready)) to the signals in the `axi_if` interface.
// The response macro `AXI_SET_TO_RESP(axi_if, resp_struct)` sets all signals of `resp_struct`
// (i.e., response channel (B and R) payload and response-side handshake signals (B and R valid and
// AW, W, and AR ready)) to the signals in the `axi_if` interface.
//
// Usage Example:
// always_comb begin
//   `AXI_SET_TO_REQ(my_req_struct, my_if)
// end
`define AXI_SET_TO_AW(aw_struct, axi_if)     `__AXI_TO_AW(, aw_struct, ., axi_if.aw, _)
`define AXI_SET_TO_W(w_struct, axi_if)       `__AXI_TO_W(, w_struct, ., axi_if.w, _)
`define AXI_SET_TO_B(b_struct, axi_if)       `__AXI_TO_B(, b_struct, ., axi_if.b, _)
`define AXI_SET_TO_AR(ar_struct, axi_if)     `__AXI_TO_AR(, ar_struct, ., axi_if.ar, _)
`define AXI_SET_TO_R(r_struct, axi_if)       `__AXI_TO_R(, r_struct, ., axi_if.r, _)
`define AXI_SET_TO_REQ(req_struct, axi_if)   `__AXI_TO_REQ(, req_struct, ., axi_if, _)
`define AXI_SET_TO_RESP(resp_struct, axi_if) `__AXI_TO_RESP(, resp_struct, ., axi_if, _)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning channel or request/response structs from an interface outside a process.
//
// The channel macros `AXI_ASSIGN_TO_XX(xx_struct, axi_if)` assign the signals of `xx_struct` to the
// payload signals of that channel in the `axi_if` interface.  They do not assign the handshake
// signals.
// The request macro `AXI_ASSIGN_TO_REQ(axi_if, req_struct)` assigns all signals of `req_struct`
// (i.e., request channel (AW, W, AR) payload and request-side handshake signals (AW, W, and AR
// valid and B and R ready)) to the signals in the `axi_if` interface.
// The response macro `AXI_ASSIGN_TO_RESP(axi_if, resp_struct)` assigns all signals of `resp_struct`
// (i.e., response channel (B and R) payload and response-side handshake signals (B and R valid and
// AW, W, and AR ready)) to the signals in the `axi_if` interface.
//
// Usage Example:
// `AXI_ASSIGN_TO_REQ(my_req_struct, my_if)
`define AXI_ASSIGN_TO_AW(aw_struct, axi_if)     `__AXI_TO_AW(assign, aw_struct, ., axi_if.aw, _)
`define AXI_ASSIGN_TO_W(w_struct, axi_if)       `__AXI_TO_W(assign, w_struct, ., axi_if.w, _)
`define AXI_ASSIGN_TO_B(b_struct, axi_if)       `__AXI_TO_B(assign, b_struct, ., axi_if.b, _)
`define AXI_ASSIGN_TO_AR(ar_struct, axi_if)     `__AXI_TO_AR(assign, ar_struct, ., axi_if.ar, _)
`define AXI_ASSIGN_TO_R(r_struct, axi_if)       `__AXI_TO_R(assign, r_struct, ., axi_if.r, _)
`define AXI_ASSIGN_TO_REQ(req_struct, axi_if)   `__AXI_TO_REQ(assign, req_struct, ., axi_if, _)
`define AXI_ASSIGN_TO_RESP(resp_struct, axi_if) `__AXI_TO_RESP(assign, resp_struct, ., axi_if, _)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Setting channel or request/response structs from another struct inside a process.
//
// The channel macros `AXI_SET_XX_STRUCT(lhs, rhs)` set the fields of the `lhs` channel struct to
// the fields of the `rhs` channel struct.  They do not set the handshake signals, which are not
// part of channel structs.
// The request macro `AXI_SET_REQ_STRUCT(lhs, rhs)` sets all fields of the `lhs` request struct to
// the fields of the `rhs` request struct.  This includes all request channel (AW, W, AR) payload
// and request-side handshake signals (AW, W, and AR valid and B and R ready).
// The response macro `AXI_SET_RESP_STRUCT(lhs, rhs)` sets all fields of the `lhs` response struct
// to the fields of the `rhs` response struct.  This includes all response channel (B and R) payload
// and response-side handshake signals (B and R valid and AW, W, and R ready).
//
// Usage Example:
// always_comb begin
//   `AXI_SET_REQ_STRUCT(my_req_struct, another_req_struct)
// end
`define AXI_SET_AW_STRUCT(lhs, rhs)     `__AXI_TO_AW(, lhs, ., rhs, .)
`define AXI_SET_W_STRUCT(lhs, rhs)       `__AXI_TO_W(, lhs, ., rhs, .)
`define AXI_SET_B_STRUCT(lhs, rhs)       `__AXI_TO_B(, lhs, ., rhs, .)
`define AXI_SET_AR_STRUCT(lhs, rhs)     `__AXI_TO_AR(, lhs, ., rhs, .)
`define AXI_SET_R_STRUCT(lhs, rhs)       `__AXI_TO_R(, lhs, ., rhs, .)
`define AXI_SET_REQ_STRUCT(lhs, rhs)   `__AXI_TO_REQ(, lhs, ., rhs, .)
`define AXI_SET_RESP_STRUCT(lhs, rhs) `__AXI_TO_RESP(, lhs, ., rhs, .)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning channel or request/response structs from another struct outside a process.
//
// The channel macros `AXI_ASSIGN_XX_STRUCT(lhs, rhs)` assign the fields of the `lhs` channel struct
// to the fields of the `rhs` channel struct.  They do not assign the handshake signals, which are
// not part of the channel structs.
// The request macro `AXI_ASSIGN_REQ_STRUCT(lhs, rhs)` assigns all fields of the `lhs` request
// struct to the fields of the `rhs` request struct.  This includes all request channel (AW, W, AR)
// payload and request-side handshake signals (AW, W, and AR valid and B and R ready).
// The response macro `AXI_ASSIGN_RESP_STRUCT(lhs, rhs)` assigns all fields of the `lhs` response
// struct to the fields of the `rhs` response struct.  This includes all response channel (B and R)
// payload and response-side handshake signals (B and R valid and AW, W, and R ready).
//
// Usage Example:
// `AXI_ASSIGN_REQ_STRUCT(my_req_struct, another_req_struct)
`define AXI_ASSIGN_AW_STRUCT(lhs, rhs)     `__AXI_TO_AW(assign, lhs, ., rhs, .)
`define AXI_ASSIGN_W_STRUCT(lhs, rhs)       `__AXI_TO_W(assign, lhs, ., rhs, .)
`define AXI_ASSIGN_B_STRUCT(lhs, rhs)       `__AXI_TO_B(assign, lhs, ., rhs, .)
`define AXI_ASSIGN_AR_STRUCT(lhs, rhs)     `__AXI_TO_AR(assign, lhs, ., rhs, .)
`define AXI_ASSIGN_R_STRUCT(lhs, rhs)       `__AXI_TO_R(assign, lhs, ., rhs, .)
`define AXI_ASSIGN_REQ_STRUCT(lhs, rhs)   `__AXI_TO_REQ(assign, lhs, ., rhs, .)
`define AXI_ASSIGN_RESP_STRUCT(lhs, rhs) `__AXI_TO_RESP(assign, lhs, ., rhs, .)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Internal implementation for assigning one Lite structs or interface to another struct or
// interface.  The path to the signals on each side is defined by the `__sep*` arguments.  The
// `__opt_as` argument allows to use this standalne (with `__opt_as = assign`) or in assignments
// inside processes (with `__opt_as` void).
`define __AXI_LITE_TO_AX(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)  \
  __opt_as __lhs``__lhs_sep``addr = __rhs``__rhs_sep``addr;             \
  __opt_as __lhs``__lhs_sep``prot = __rhs``__rhs_sep``prot;
`define __AXI_LITE_TO_W(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep) \
  __opt_as __lhs``__lhs_sep``data = __rhs``__rhs_sep``data;           \
  __opt_as __lhs``__lhs_sep``strb = __rhs``__rhs_sep``strb;
`define __AXI_LITE_TO_B(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep) \
  __opt_as __lhs``__lhs_sep``resp = __rhs``__rhs_sep``resp;
`define __AXI_LITE_TO_R(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep) \
  __opt_as __lhs``__lhs_sep``data = __rhs``__rhs_sep``data;           \
  __opt_as __lhs``__lhs_sep``resp = __rhs``__rhs_sep``resp;
`define __AXI_LITE_TO_REQ(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep) \
  `__AXI_LITE_TO_AX(__opt_as, __lhs.aw, __lhs_sep, __rhs.aw, __rhs_sep) \
  __opt_as __lhs.aw_valid = __rhs.aw_valid;                             \
  `__AXI_LITE_TO_W(__opt_as, __lhs.w, __lhs_sep, __rhs.w, __rhs_sep)    \
  __opt_as __lhs.w_valid = __rhs.w_valid;                               \
  __opt_as __lhs.b_ready = __rhs.b_ready;                               \
  `__AXI_LITE_TO_AX(__opt_as, __lhs.ar, __lhs_sep, __rhs.ar, __rhs_sep) \
  __opt_as __lhs.ar_valid = __rhs.ar_valid;                             \
  __opt_as __lhs.r_ready = __rhs.r_ready;
`define __AXI_LITE_TO_RESP(__opt_as, __lhs, __lhs_sep, __rhs, __rhs_sep)  \
  __opt_as __lhs.aw_ready = __rhs.aw_ready;                               \
  __opt_as __lhs.ar_ready = __rhs.ar_ready;                               \
  __opt_as __lhs.w_ready = __rhs.w_ready;                                 \
  __opt_as __lhs.b_valid = __rhs.b_valid;                                 \
  `__AXI_LITE_TO_B(__opt_as, __lhs.b, __lhs_sep, __rhs.b, __rhs_sep)      \
  __opt_as __lhs.r_valid = __rhs.r_valid;                                 \
  `__AXI_LITE_TO_R(__opt_as, __lhs.r, __lhs_sep, __rhs.r, __rhs_sep)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning one AXI-Lite interface to another, as if you would do `assign slv = mst;`
//
// The channel assignments `AXI_LITE_ASSIGN_XX(dst, src)` assign all payload and the valid signal of
// the `XX` channel from the `src` to the `dst` interface and they assign the ready signal from the
// `src` to the `dst` interface.
// The interface assignment `AXI_LITE_ASSIGN(dst, src)` assigns all channels including handshakes as
// if `src` was the master of `dst`.
//
// Usage Example:
// `AXI_LITE_ASSIGN(slv, mst)
// `AXI_LITE_ASSIGN_AW(dst, src)
// `AXI_LITE_ASSIGN_R(dst, src)
`define AXI_LITE_ASSIGN_AW(dst, src)              \
  `__AXI_LITE_TO_AX(assign, dst.aw, _, src.aw, _) \
  assign dst.aw_valid = src.aw_valid;             \
  assign src.aw_ready = dst.aw_ready;
`define AXI_LITE_ASSIGN_W(dst, src)             \
  `__AXI_LITE_TO_W(assign, dst.w, _, src.w, _)  \
  assign dst.w_valid  = src.w_valid;            \
  assign src.w_ready  = dst.w_ready;
`define AXI_LITE_ASSIGN_B(dst, src)             \
  `__AXI_LITE_TO_B(assign, dst.b, _, src.b, _)  \
  assign dst.b_valid  = src.b_valid;            \
  assign src.b_ready  = dst.b_ready;
`define AXI_LITE_ASSIGN_AR(dst, src)              \
  `__AXI_LITE_TO_AX(assign, dst.ar, _, src.ar, _) \
  assign dst.ar_valid = src.ar_valid;             \
  assign src.ar_ready = dst.ar_ready;
`define AXI_LITE_ASSIGN_R(dst, src)             \
  `__AXI_LITE_TO_R(assign, dst.r, _, src.r, _)  \
  assign dst.r_valid  = src.r_valid;            \
  assign src.r_ready  = dst.r_ready;
`define AXI_LITE_ASSIGN(slv, mst) \
  `AXI_LITE_ASSIGN_AW(slv, mst)   \
  `AXI_LITE_ASSIGN_W(slv, mst)    \
  `AXI_LITE_ASSIGN_B(mst, slv)    \
  `AXI_LITE_ASSIGN_AR(slv, mst)   \
  `AXI_LITE_ASSIGN_R(mst, slv)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Setting a Lite interface from channel or request/response structs inside a process.
//
// The channel macros `AXI_LITE_SET_FROM_XX(axi_if, xx_struct)` set the payload signals of the
// `axi_if` interface from the signals in `xx_struct`.  They do not set the handshake signals.
// The request macro `AXI_LITE_SET_FROM_REQ(axi_if, req_struct)` sets all request channels (AW, W,
// AR) and the request-side handshake signals (AW, W, and AR valid and B and R ready) of the
// `axi_if` interface from the signals in `req_struct`.
// The response macro `AXI_LITE_SET_FROM_RESP(axi_if, resp_struct)` sets both response channels (B
// and R) and the response-side handshake signals (B and R valid and AW, W, and AR ready) of the
// `axi_if` interface from the signals in `resp_struct`.
//
// Usage Example:
// always_comb begin
//   `AXI_LITE_SET_FROM_REQ(my_if, my_req_struct)
// end
`define AXI_LITE_SET_FROM_AW(axi_if, aw_struct)      `__AXI_LITE_TO_AX(, axi_if.aw, _, aw_struct, .)
`define AXI_LITE_SET_FROM_W(axi_if, w_struct)        `__AXI_LITE_TO_W(, axi_if.w, _, w_struct, .)
`define AXI_LITE_SET_FROM_B(axi_if, b_struct)        `__AXI_LITE_TO_B(, axi_if.b, _, b_struct, .)
`define AXI_LITE_SET_FROM_AR(axi_if, ar_struct)      `__AXI_LITE_TO_AX(, axi_if.ar, _, ar_struct, .)
`define AXI_LITE_SET_FROM_R(axi_if, r_struct)        `__AXI_LITE_TO_R(, axi_if.r, _, r_struct, .)
`define AXI_LITE_SET_FROM_REQ(axi_if, req_struct)    `__AXI_LITE_TO_REQ(, axi_if, _, req_struct, .)
`define AXI_LITE_SET_FROM_RESP(axi_if, resp_struct)  `__AXI_LITE_TO_RESP(, axi_if, _, resp_struct, .)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning a Lite interface from channel or request/response structs outside a process.
//
// The channel macros `AXI_LITE_ASSIGN_FROM_XX(axi_if, xx_struct)` assign the payload signals of the
// `axi_if` interface from the signals in `xx_struct`.  They do not assign the handshake signals.
// The request macro `AXI_LITE_ASSIGN_FROM_REQ(axi_if, req_struct)` assigns all request channels
// (AW, W, AR) and the request-side handshake signals (AW, W, and AR valid and B and R ready) of the
// `axi_if` interface from the signals in `req_struct`.
// The response macro `AXI_LITE_ASSIGN_FROM_RESP(axi_if, resp_struct)` assigns both response
// channels (B and R) and the response-side handshake signals (B and R valid and AW, W, and AR
// ready) of the `axi_if` interface from the signals in `resp_struct`.
//
// Usage Example:
// `AXI_LITE_ASSIGN_FROM_REQ(my_if, my_req_struct)
`define AXI_LITE_ASSIGN_FROM_AW(axi_if, aw_struct)     `__AXI_LITE_TO_AX(assign, axi_if.aw, _, aw_struct, .)
`define AXI_LITE_ASSIGN_FROM_W(axi_if, w_struct)       `__AXI_LITE_TO_W(assign, axi_if.w, _, w_struct, .)
`define AXI_LITE_ASSIGN_FROM_B(axi_if, b_struct)       `__AXI_LITE_TO_B(assign, axi_if.b, _, b_struct, .)
`define AXI_LITE_ASSIGN_FROM_AR(axi_if, ar_struct)     `__AXI_LITE_TO_AX(assign, axi_if.ar, _, ar_struct, .)
`define AXI_LITE_ASSIGN_FROM_R(axi_if, r_struct)       `__AXI_LITE_TO_R(assign, axi_if.r, _, r_struct, .)
`define AXI_LITE_ASSIGN_FROM_REQ(axi_if, req_struct)   `__AXI_LITE_TO_REQ(assign, axi_if, _, req_struct, .)
`define AXI_LITE_ASSIGN_FROM_RESP(axi_if, resp_struct) `__AXI_LITE_TO_RESP(assign, axi_if, _, resp_struct, .)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Setting channel or request/response structs from an interface inside a process.
//
// The channel macros `AXI_LITE_SET_TO_XX(xx_struct, axi_if)` set the signals of `xx_struct` to the
// payload signals of that channel in the `axi_if` interface.  They do not set the handshake
// signals.
// The request macro `AXI_LITE_SET_TO_REQ(axi_if, req_struct)` sets all signals of `req_struct`
// (i.e., request channel (AW, W, AR) payload and request-side handshake signals (AW, W, and AR
// valid and B and R ready)) to the signals in the `axi_if` interface.
// The response macro `AXI_LITE_SET_TO_RESP(axi_if, resp_struct)` sets all signals of `resp_struct`
// (i.e., response channel (B and R) payload and response-side handshake signals (B and R valid and
// AW, W, and AR ready)) to the signals in the `axi_if` interface.
//
// Usage Example:
// always_comb begin
//   `AXI_LITE_SET_TO_REQ(my_req_struct, my_if)
// end
`define AXI_LITE_SET_TO_AW(aw_struct, axi_if)     `__AXI_LITE_TO_AX(, aw_struct, ., axi_if.aw, _)
`define AXI_LITE_SET_TO_W(w_struct, axi_if)       `__AXI_LITE_TO_W(, w_struct, ., axi_if.w, _)
`define AXI_LITE_SET_TO_B(b_struct, axi_if)       `__AXI_LITE_TO_B(, b_struct, ., axi_if.b, _)
`define AXI_LITE_SET_TO_AR(ar_struct, axi_if)     `__AXI_LITE_TO_AX(, ar_struct, ., axi_if.ar, _)
`define AXI_LITE_SET_TO_R(r_struct, axi_if)       `__AXI_LITE_TO_R(, r_struct, ., axi_if.r, _)
`define AXI_LITE_SET_TO_REQ(req_struct, axi_if)   `__AXI_LITE_TO_REQ(, req_struct, ., axi_if, _)
`define AXI_LITE_SET_TO_RESP(resp_struct, axi_if) `__AXI_LITE_TO_RESP(, resp_struct, ., axi_if, _)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning channel or request/response structs from an interface outside a process.
//
// The channel macros `AXI_LITE_ASSIGN_TO_XX(xx_struct, axi_if)` assign the signals of `xx_struct`
// to the payload signals of that channel in the `axi_if` interface.  They do not assign the
// handshake signals.
// The request macro `AXI_LITE_ASSIGN_TO_REQ(axi_if, req_struct)` assigns all signals of
// `req_struct` (i.e., request channel (AW, W, AR) payload and request-side handshake signals (AW,
// W, and AR valid and B and R ready)) to the signals in the `axi_if` interface.
// The response macro `AXI_LITE_ASSIGN_TO_RESP(axi_if, resp_struct)` assigns all signals of
// `resp_struct` (i.e., response channel (B and R) payload and response-side handshake signals (B
// and R valid and AW, W, and AR ready)) to the signals in the `axi_if` interface.
//
// Usage Example:
// `AXI_LITE_ASSIGN_TO_REQ(my_req_struct, my_if)
`define AXI_LITE_ASSIGN_TO_AW(aw_struct, axi_if)     `__AXI_LITE_TO_AX(assign, aw_struct, ., axi_if.aw, _)
`define AXI_LITE_ASSIGN_TO_W(w_struct, axi_if)       `__AXI_LITE_TO_W(assign, w_struct, ., axi_if.w, _)
`define AXI_LITE_ASSIGN_TO_B(b_struct, axi_if)       `__AXI_LITE_TO_B(assign, b_struct, ., axi_if.b, _)
`define AXI_LITE_ASSIGN_TO_AR(ar_struct, axi_if)     `__AXI_LITE_TO_AX(assign, ar_struct, ., axi_if.ar, _)
`define AXI_LITE_ASSIGN_TO_R(r_struct, axi_if)       `__AXI_LITE_TO_R(assign, r_struct, ., axi_if.r, _)
`define AXI_LITE_ASSIGN_TO_REQ(req_struct, axi_if)   `__AXI_LITE_TO_REQ(assign, req_struct, ., axi_if, _)
`define AXI_LITE_ASSIGN_TO_RESP(resp_struct, axi_if) `__AXI_LITE_TO_RESP(assign, resp_struct, ., axi_if, _)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Setting channel or request/response structs from another struct inside a process.
//
// The channel macros `AXI_LITE_SET_XX_STRUCT(lhs, rhs)` set the fields of the `lhs` channel struct
// to the fields of the `rhs` channel struct.  They do not set the handshake signals, which are not
// part of channel structs.
// The request macro `AXI_LITE_SET_REQ_STRUCT(lhs, rhs)` sets all fields of the `lhs` request struct
// to the fields of the `rhs` request struct.  This includes all request channel (AW, W, AR) payload
// and request-side handshake signals (AW, W, and AR valid and B and R ready).
// The response macro `AXI_LITE_SET_RESP_STRUCT(lhs, rhs)` sets all fields of the `lhs` response
// struct to the fields of the `rhs` response struct.  This includes all response channel (B and R)
// payload and response-side handshake signals (B and R valid and AW, W, and R ready).
//
// Usage Example:
// always_comb begin
//   `AXI_LITE_SET_REQ_STRUCT(my_req_struct, another_req_struct)
// end
`define AXI_LITE_SET_AW_STRUCT(lhs, rhs)     `__AXI_LITE_TO_AX(, lhs, ., rhs, .)
`define AXI_LITE_SET_W_STRUCT(lhs, rhs)       `__AXI_LITE_TO_W(, lhs, ., rhs, .)
`define AXI_LITE_SET_B_STRUCT(lhs, rhs)       `__AXI_LITE_TO_B(, lhs, ., rhs, .)
`define AXI_LITE_SET_AR_STRUCT(lhs, rhs)     `__AXI_LITE_TO_AX(, lhs, ., rhs, .)
`define AXI_LITE_SET_R_STRUCT(lhs, rhs)       `__AXI_LITE_TO_R(, lhs, ., rhs, .)
`define AXI_LITE_SET_REQ_STRUCT(lhs, rhs)   `__AXI_LITE_TO_REQ(, lhs, ., rhs, .)
`define AXI_LITE_SET_RESP_STRUCT(lhs, rhs) `__AXI_LITE_TO_RESP(, lhs, ., rhs, .)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Assigning channel or request/response structs from another struct outside a process.
//
// The channel macros `AXI_LITE_ASSIGN_XX_STRUCT(lhs, rhs)` assign the fields of the `lhs` channel
// struct to the fields of the `rhs` channel struct.  They do not assign the handshake signals,
// which are not part of the channel structs.
// The request macro `AXI_LITE_ASSIGN_REQ_STRUCT(lhs, rhs)` assigns all fields of the `lhs` request
// struct to the fields of the `rhs` request struct.  This includes all request channel (AW, W, AR)
// payload and request-side handshake signals (AW, W, and AR valid and B and R ready).
// The response macro `AXI_LITE_ASSIGN_RESP_STRUCT(lhs, rhs)` assigns all fields of the `lhs`
// response struct to the fields of the `rhs` response struct.  This includes all response channel
// (B and R) payload and response-side handshake signals (B and R valid and AW, W, and R ready).
//
// Usage Example:
// `AXI_LITE_ASSIGN_REQ_STRUCT(my_req_struct, another_req_struct)
`define AXI_LITE_ASSIGN_AW_STRUCT(lhs, rhs)     `__AXI_LITE_TO_AX(assign, lhs, ., rhs, .)
`define AXI_LITE_ASSIGN_W_STRUCT(lhs, rhs)       `__AXI_LITE_TO_W(assign, lhs, ., rhs, .)
`define AXI_LITE_ASSIGN_B_STRUCT(lhs, rhs)       `__AXI_LITE_TO_B(assign, lhs, ., rhs, .)
`define AXI_LITE_ASSIGN_AR_STRUCT(lhs, rhs)     `__AXI_LITE_TO_AX(assign, lhs, ., rhs, .)
`define AXI_LITE_ASSIGN_R_STRUCT(lhs, rhs)       `__AXI_LITE_TO_R(assign, lhs, ., rhs, .)
`define AXI_LITE_ASSIGN_REQ_STRUCT(lhs, rhs)   `__AXI_LITE_TO_REQ(assign, lhs, ., rhs, .)
`define AXI_LITE_ASSIGN_RESP_STRUCT(lhs, rhs) `__AXI_LITE_TO_RESP(assign, lhs, ., rhs, .)
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// Macros for assigning flattened AXI ports to req/resp AXI structs
// Flat AXI ports are required by the Vivado IP Integrator. Vivado naming convention is followed.
//
// Usage Example:
// `AXI_ASSIGN_MASTER_TO_FLAT("my_bus", my_req_struct, my_rsp_struct)
`define AXI_ASSIGN_MASTER_TO_FLAT(pat, req, rsp) \
  assign m_axi_``pat``_awvalid  = req.aw_valid;  \
  assign m_axi_``pat``_awid     = req.aw.id;     \
  assign m_axi_``pat``_awaddr   = req.aw.addr;   \
  assign m_axi_``pat``_awlen    = req.aw.len;    \
  assign m_axi_``pat``_awsize   = req.aw.size;   \
  assign m_axi_``pat``_awburst  = req.aw.burst;  \
  assign m_axi_``pat``_awlock   = req.aw.lock;   \
  assign m_axi_``pat``_awcache  = req.aw.cache;  \
  assign m_axi_``pat``_awprot   = req.aw.prot;   \
  assign m_axi_``pat``_awqos    = req.aw.qos;    \
  assign m_axi_``pat``_awregion = req.aw.region; \
  assign m_axi_``pat``_awuser   = req.aw.user;   \
                                                 \
  assign m_axi_``pat``_wvalid   = req.w_valid;   \
  assign m_axi_``pat``_wdata    = req.w.data;    \
  assign m_axi_``pat``_wstrb    = req.w.strb;    \
  assign m_axi_``pat``_wlast    = req.w.last;    \
  assign m_axi_``pat``_wuser    = req.w.user;    \
                                                 \
  assign m_axi_``pat``_bready   = req.b_ready;   \
                                                 \
  assign m_axi_``pat``_arvalid  = req.ar_valid;  \
  assign m_axi_``pat``_arid     = req.ar.id;     \
  assign m_axi_``pat``_araddr   = req.ar.addr;   \
  assign m_axi_``pat``_arlen    = req.ar.len;    \
  assign m_axi_``pat``_arsize   = req.ar.size;   \
  assign m_axi_``pat``_arburst  = req.ar.burst;  \
  assign m_axi_``pat``_arlock   = req.ar.lock;   \
  assign m_axi_``pat``_arcache  = req.ar.cache;  \
  assign m_axi_``pat``_arprot   = req.ar.prot;   \
  assign m_axi_``pat``_arqos    = req.ar.qos;    \
  assign m_axi_``pat``_arregion = req.ar.region; \
  assign m_axi_``pat``_aruser   = req.ar.user;   \
                                                 \
  assign m_axi_``pat``_rready   = req.r_ready;   \
                                                 \
  assign rsp.aw_ready = m_axi_``pat``_awready;   \
  assign rsp.ar_ready = m_axi_``pat``_arready;   \
  assign rsp.w_ready  = m_axi_``pat``_wready;    \
                                                 \
  assign rsp.b_valid  = m_axi_``pat``_bvalid;    \
  assign rsp.b.id     = m_axi_``pat``_bid;       \
  assign rsp.b.resp   = m_axi_``pat``_bresp;     \
  assign rsp.b.user   = m_axi_``pat``_buser;     \
                                                 \
  assign rsp.r_valid  = m_axi_``pat``_rvalid;    \
  assign rsp.r.id     = m_axi_``pat``_rid;       \
  assign rsp.r.data   = m_axi_``pat``_rdata;     \
  assign rsp.r.resp   = m_axi_``pat``_rresp;     \
  assign rsp.r.last   = m_axi_``pat``_rlast;     \
  assign rsp.r.user   = m_axi_``pat``_ruser;

`define AXI_ASSIGN_SLAVE_TO_FLAT(pat, req, rsp)  \
  assign req.aw_valid  = s_axi_``pat``_awvalid;  \
  assign req.aw.id     = s_axi_``pat``_awid;     \
  assign req.aw.addr   = s_axi_``pat``_awaddr;   \
  assign req.aw.len    = s_axi_``pat``_awlen;    \
  assign req.aw.size   = s_axi_``pat``_awsize;   \
  assign req.aw.burst  = s_axi_``pat``_awburst;  \
  assign req.aw.lock   = s_axi_``pat``_awlock;   \
  assign req.aw.cache  = s_axi_``pat``_awcache;  \
  assign req.aw.prot   = s_axi_``pat``_awprot;   \
  assign req.aw.qos    = s_axi_``pat``_awqos;    \
  assign req.aw.region = s_axi_``pat``_awregion; \
  assign req.aw.user   = s_axi_``pat``_awuser;   \
                                                 \
  assign req.w_valid   = s_axi_``pat``_wvalid;   \
  assign req.w.data    = s_axi_``pat``_wdata;    \
  assign req.w.strb    = s_axi_``pat``_wstrb;    \
  assign req.w.last    = s_axi_``pat``_wlast;    \
  assign req.w.user    = s_axi_``pat``_wuser;    \
                                                 \
  assign req.b_ready   = s_axi_``pat``_bready;   \
                                                 \
  assign req.ar_valid  = s_axi_``pat``_arvalid;  \
  assign req.ar.id     = s_axi_``pat``_arid;     \
  assign req.ar.addr   = s_axi_``pat``_araddr;   \
  assign req.ar.len    = s_axi_``pat``_arlen;    \
  assign req.ar.size   = s_axi_``pat``_arsize;   \
  assign req.ar.burst  = s_axi_``pat``_arburst;  \
  assign req.ar.lock   = s_axi_``pat``_arlock;   \
  assign req.ar.cache  = s_axi_``pat``_arcache;  \
  assign req.ar.prot   = s_axi_``pat``_arprot;   \
  assign req.ar.qos    = s_axi_``pat``_arqos;    \
  assign req.ar.region = s_axi_``pat``_arregion; \
  assign req.ar.user   = s_axi_``pat``_aruser;   \
                                                 \
  assign req.r_ready   = s_axi_``pat``_rready;   \
                                                 \
  assign s_axi_``pat``_awready = rsp.aw_ready;   \
  assign s_axi_``pat``_arready = rsp.ar_ready;   \
  assign s_axi_``pat``_wready  = rsp.w_ready;    \
                                                 \
  assign s_axi_``pat``_bvalid  = rsp.b_valid;    \
  assign s_axi_``pat``_bid     = rsp.b.id;       \
  assign s_axi_``pat``_bresp   = rsp.b.resp;     \
  assign s_axi_``pat``_buser   = rsp.b.user;     \
                                                 \
  assign s_axi_``pat``_rvalid  = rsp.r_valid;    \
  assign s_axi_``pat``_rid     = rsp.r.id;       \
  assign s_axi_``pat``_rdata   = rsp.r.data;     \
  assign s_axi_``pat``_rresp   = rsp.r.resp;     \
  assign s_axi_``pat``_rlast   = rsp.r.last;     \
  assign s_axi_``pat``_ruser   = rsp.r.user;
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assign signals to interface i tb_top.sv
// NOTE: Pay attention to the direction of request and respond channel !!!
// TODO: Some of these left and right are reversed !!!
// -------------------- Masters ------------------- //
`define ASSIGN_SIGNAL_TO_INTF_MST_AW(__lhs, __rhs_sep)         \
  assign __lhs.aw_id     = master_``__rhs_sep``_aw_id    ;     \
  assign __lhs.aw_addr   = master_``__rhs_sep``_aw_addr  ;     \
  assign __lhs.aw_len    = master_``__rhs_sep``_aw_len   ;     \
  assign __lhs.aw_size   = master_``__rhs_sep``_aw_size  ;     \
  assign __lhs.aw_burst  = master_``__rhs_sep``_aw_burst ;     \
  assign __lhs.aw_lock   = master_``__rhs_sep``_aw_lock  ;     \
  assign __lhs.aw_cache  = master_``__rhs_sep``_aw_cache ;     \
  assign __lhs.aw_prot   = master_``__rhs_sep``_aw_prot  ;     \
  assign __lhs.aw_qos    = master_``__rhs_sep``_aw_qos   ;     \
  assign __lhs.aw_region = master_``__rhs_sep``_aw_region;     \
  assign __lhs.aw_user   = master_``__rhs_sep``_aw_user  ;     \
  assign __lhs.aw_valid  = master_``__rhs_sep``_aw_valid ;     \
  assign master_``__rhs_sep``_aw_ready  = __lhs.aw_ready ;

`define ASSIGN_SIGNAL_TO_INTF_MST_W(__lhs, __rhs_sep)    \
  assign __lhs.w_data  = master_``__rhs_sep``_w_data ;   \
  assign __lhs.w_strb  = master_``__rhs_sep``_w_strb ;   \
  assign __lhs.w_last  = master_``__rhs_sep``_w_last ;   \
  assign __lhs.w_user  = master_``__rhs_sep``_w_user ;   \
  assign __lhs.w_valid = master_``__rhs_sep``_w_valid;   \
  assign master_``__rhs_sep``_w_ready = __lhs.w_ready; 

`define ASSIGN_SIGNAL_TO_INTF_MST_B(__lhs, __rhs_sep)       \
  assign master_``__rhs_sep``_b_id    = __lhs.b_id   ;      \
  assign master_``__rhs_sep``_b_resp  = __lhs.b_resp ;      \
  assign master_``__rhs_sep``_b_user  = __lhs.b_user ;      \
  assign master_``__rhs_sep``_b_valid = __lhs.b_valid;      \
  assign master_``__rhs_sep``_b_ready = __lhs.b_ready;    

`define ASSIGN_SIGNAL_TO_INTF_MST_AR(__lhs, __rhs_sep)         \
  assign __lhs.ar_id     = master_``__rhs_sep``_ar_id;         \
  assign __lhs.ar_addr   = master_``__rhs_sep``_ar_addr;       \
  assign __lhs.ar_len    = master_``__rhs_sep``_ar_len;        \
  assign __lhs.ar_size   = master_``__rhs_sep``_ar_size;       \
  assign __lhs.ar_burst  = master_``__rhs_sep``_ar_burst;      \
  assign __lhs.ar_lock   = master_``__rhs_sep``_ar_lock ;      \
  assign __lhs.ar_cache  = master_``__rhs_sep``_ar_cache;      \
  assign __lhs.ar_prot   = master_``__rhs_sep``_ar_prot;       \
  assign __lhs.ar_qos    = master_``__rhs_sep``_ar_qos;        \
  assign __lhs.ar_region = master_``__rhs_sep``_ar_region;     \
  assign __lhs.ar_user   = master_``__rhs_sep``_ar_user;      \
  assign __lhs.ar_valid  = master_``__rhs_sep``_ar_valid;      \
  assign master_``__rhs_sep``_ar_ready  = __lhs.ar_ready;

`define ASSIGN_SIGNAL_TO_INTF_MST_R(__lhs, __rhs_sep)          \
  assign master_``__rhs_sep``_r_id    = __lhs.r_id  ;          \
  assign master_``__rhs_sep``_r_data  = __lhs.r_data;          \
  assign master_``__rhs_sep``_r_resp  = __lhs.r_resp;          \
  assign master_``__rhs_sep``_r_last  = __lhs.r_last;          \
  assign master_``__rhs_sep``_r_user  = __lhs.r_user;          \
  assign master_``__rhs_sep``_r_valid = __lhs.r_valid;         \
  assign master_``__rhs_sep``_r_ready = __lhs.r_ready;

// -------------------- Slaves ------------------- //
`define ASSIGN_SIGNAL_TO_INTF_SLV_AW(__lhs, __rhs_sep)         \
  assign slave_``__rhs_sep``_aw_id     = __lhs.aw_id    ;         \
  assign slave_``__rhs_sep``_aw_addr   = __lhs.aw_addr  ;       \
  assign slave_``__rhs_sep``_aw_len    = __lhs.aw_len   ;        \
  assign slave_``__rhs_sep``_aw_size   = __lhs.aw_size  ;       \
  assign slave_``__rhs_sep``_aw_burst  = __lhs.aw_burst ;      \
  assign slave_``__rhs_sep``_aw_lock   = __lhs.aw_lock  ;       \
  assign slave_``__rhs_sep``_aw_cache  = __lhs.aw_cache ;      \
  assign slave_``__rhs_sep``_aw_prot   = __lhs.aw_prot  ;       \
  assign slave_``__rhs_sep``_aw_qos    = __lhs.aw_qos   ;        \
  assign slave_``__rhs_sep``_aw_region = __lhs.aw_region;     \
  assign slave_``__rhs_sep``_aw_user   = __lhs.aw_user  ;       \
  assign slave_``__rhs_sep``_aw_valid  = __lhs.aw_valid ;       \
  assign __lhs.aw_ready  = slave_``__rhs_sep``_aw_ready ;

`define ASSIGN_SIGNAL_TO_INTF_SLV_W(__lhs, __rhs_sep)          \
  assign slave_``__rhs_sep``_w_data  = __lhs.w_data   ;         \
  assign slave_``__rhs_sep``_w_strb  = __lhs.w_strb   ;         \
  assign slave_``__rhs_sep``_w_last  = __lhs.w_last   ;         \
  assign slave_``__rhs_sep``_w_user  = __lhs.w_user   ;         \
  assign slave_``__rhs_sep``_w_valid = __lhs.w_valid  ;         \
  assign slave_``__rhs_sep``_w_ready = __lhs.w_ready  ;

`define ASSIGN_SIGNAL_TO_INTF_SLV_B(__lhs, __rhs_sep)          \
  assign __lhs.b_id    = slave_``__rhs_sep``_b_id   ;           \
  assign __lhs.b_resp  = slave_``__rhs_sep``_b_resp ;           \
  assign __lhs.b_user  = slave_``__rhs_sep``_b_user ;           \
  assign __lhs.b_valid = slave_``__rhs_sep``_b_valid;           \
  assign slave_``__rhs_sep``_b_ready = __lhs.b_ready;    

`define ASSIGN_SIGNAL_TO_INTF_SLV_AR(__lhs, __rhs_sep)         \
  assign slave_``__rhs_sep``_ar_id     = __lhs.ar_id    ;         \
  assign slave_``__rhs_sep``_ar_addr   = __lhs.ar_addr  ;       \
  assign slave_``__rhs_sep``_ar_len    = __lhs.ar_len   ;        \
  assign slave_``__rhs_sep``_ar_size   = __lhs.ar_size  ;       \
  assign slave_``__rhs_sep``_ar_burst  = __lhs.ar_burst ;      \
  assign slave_``__rhs_sep``_ar_lock   = __lhs.ar_lock  ;       \
  assign slave_``__rhs_sep``_ar_cache  = __lhs.ar_cache ;      \
  assign slave_``__rhs_sep``_ar_prot   = __lhs.ar_prot  ;       \
  assign slave_``__rhs_sep``_ar_qos    = __lhs.ar_qos   ;        \
  assign slave_``__rhs_sep``_ar_region = __lhs.ar_region;     \
  assign slave_``__rhs_sep``_ar_user   = __lhs.ar_user  ;       \
  assign slave_``__rhs_sep``_ar_valid  = __lhs.ar_valid ;       \
  assign slave_``__rhs_sep``_ar_ready  = __lhs.ar_ready ; 

`define ASSIGN_SIGNAL_TO_INTF_SLV_R(__lhs, __rhs_sep)          \
  assign  __lhs.r_id     = slave_``__rhs_sep``_r_id   ;          \
  assign  __lhs.r_data   = slave_``__rhs_sep``_r_data ;          \
  assign  __lhs.r_resp   = slave_``__rhs_sep``_r_resp ;          \
  assign  __lhs.r_last   = slave_``__rhs_sep``_r_last ;          \
  assign  __lhs.r_user   = slave_``__rhs_sep``_r_user ;          \
  assign  __lhs.r_valid  = slave_``__rhs_sep``_r_valid;          \
  assign  slave_``__rhs_sep``_r_ready  = __lhs.r_ready;
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assign signal type to interface type
// NOTE: Pay attention to the direction of request and respond channel !!!
// TODO: Some of these left and right are reversed !!!
  `define ASSIGN_AXI_SIG_TO_AXI_INTF_AW(__lhs, __rhs_sep)         \
  assign __lhs.aw_id     = __rhs_sep``_aw_id    ;     \
  assign __lhs.aw_addr   = __rhs_sep``_aw_addr  ;     \
  assign __lhs.aw_len    = __rhs_sep``_aw_len   ;     \
  assign __lhs.aw_size   = __rhs_sep``_aw_size  ;     \
  assign __lhs.aw_burst  = __rhs_sep``_aw_burst ;     \
  assign __lhs.aw_lock   = __rhs_sep``_aw_lock  ;     \
  assign __lhs.aw_cache  = __rhs_sep``_aw_cache ;     \
  assign __lhs.aw_prot   = __rhs_sep``_aw_prot  ;     \
  assign __lhs.aw_qos    = __rhs_sep``_aw_qos   ;     \
  assign __lhs.aw_region = __rhs_sep``_aw_region;     \
  assign __lhs.aw_user   = __rhs_sep``_aw_user  ;     \
  assign __lhs.aw_valid  = __rhs_sep``_aw_valid ;     \
  assign __rhs_sep``_aw_ready  = __lhs.aw_ready ;
  
  `define ASSIGN_AXI_SIG_TO_AXI_INTF_W(__lhs, __rhs_sep)    \
  assign __lhs.w_data  = __rhs_sep``_w_data ;   \
  assign __lhs.w_strb  = __rhs_sep``_w_strb ;   \
  assign __lhs.w_last  = __rhs_sep``_w_last ;   \
  assign __lhs.w_user  = __rhs_sep``_w_user ;   \
  assign __lhs.w_valid = __rhs_sep``_w_valid;   \
  assign __rhs_sep``_w_ready = __lhs.w_ready; 
  
  `define ASSIGN_AXI_SIG_TO_AXI_INTF_B(__lhs, __rhs_sep)       \
  assign __rhs_sep``_b_id    = __lhs.b_id   ;      \
  assign __rhs_sep``_b_resp  = __lhs.b_resp ;      \
  assign __rhs_sep``_b_user  = __lhs.b_user ;      \
  assign __rhs_sep``_b_valid = __lhs.b_valid;      \
  assign __lhs.b_ready = __rhs_sep``_b_ready;    
  
  `define ASSIGN_AXI_SIG_TO_AXI_INTF_AR(__lhs, __rhs_sep)         \
  assign __lhs.ar_id     = __rhs_sep``_ar_id;         \
  assign __lhs.ar_addr   = __rhs_sep``_ar_addr;       \
  assign __lhs.ar_len    = __rhs_sep``_ar_len;        \
  assign __lhs.ar_size   = __rhs_sep``_ar_size;       \
  assign __lhs.ar_burst  = __rhs_sep``_ar_burst;      \
  assign __lhs.ar_lock   = __rhs_sep``_ar_lock ;      \
  assign __lhs.ar_cache  = __rhs_sep``_ar_cache;      \
  assign __lhs.ar_prot   = __rhs_sep``_ar_prot;       \
  assign __lhs.ar_qos    = __rhs_sep``_ar_qos;        \
  assign __lhs.ar_region = __rhs_sep``_ar_region;     \
  assign __lhs.ar_user   = __rhs_sep``_ar_user;      \
  assign __lhs.ar_valid  = __rhs_sep``_ar_valid;      \
  assign __rhs_sep``_ar_ready  = __lhs.ar_ready;
  
  `define ASSIGN_AXI_SIG_TO_AXI_INTF_R(__lhs, __rhs_sep)          \
  assign __rhs_sep``_r_id    = __lhs.r_id  ;          \
  assign __rhs_sep``_r_data  = __lhs.r_data;          \
  assign __rhs_sep``_r_resp  = __lhs.r_resp;          \
  assign __rhs_sep``_r_last  = __lhs.r_last;          \
  assign __rhs_sep``_r_user  = __lhs.r_user;          \
  assign __rhs_sep``_r_valid = __lhs.r_valid;         \
  assign __lhs.r_ready = __rhs_sep``_r_ready;
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assign signal type to interface type
// NOTE: Pay attention to the direction of request and respond channel !!!
// TODO: Some of these left and right are reversed !!!
`define ASSIGN_AXI_INTF_TO_AXI_SIG_AW(__sig, __intf)         \
assign __sig``_aw_id    = __intf.aw_id     ;     \
assign __sig``_aw_addr  = __intf.aw_addr   ;     \
assign __sig``_aw_len   = __intf.aw_len    ;     \
assign __sig``_aw_size  = __intf.aw_size   ;     \
assign __sig``_aw_burst = __intf.aw_burst  ;     \
assign __sig``_aw_lock  = __intf.aw_lock   ;     \
assign __sig``_aw_cache = __intf.aw_cache  ;     \
assign __sig``_aw_prot  = __intf.aw_prot   ;     \
assign __sig``_aw_qos   = __intf.aw_qos    ;     \
assign __sig``_aw_region= __intf.aw_region ;     \
assign __sig``_aw_user  = __intf.aw_user   ;     \
assign __sig``_aw_valid = __intf.aw_valid  ;     \
assign __intf.aw_ready = __sig``_aw_ready ;

`define ASSIGN_AXI_INTF_TO_AXI_SIG_W(__sig, __intf)    \
assign __sig``_w_data  = __intf.w_data  ;   \
assign __sig``_w_strb  = __intf.w_strb  ;   \
assign __sig``_w_last  = __intf.w_last  ;   \
assign __sig``_w_user  = __intf.w_user  ;   \
assign __sig``_w_valid = __intf.w_valid ;   \
assign __intf.w_ready = __sig``_w_ready;

`define ASSIGN_AXI_INTF_TO_AXI_SIG_B(__sig, __intf)       \
assign __intf.b_id   = __sig``_b_id    ;      \
assign __intf.b_resp = __sig``_b_resp  ;      \
assign __intf.b_user = __sig``_b_user  ;      \
assign __intf.b_valid= __sig``_b_valid ;      \
assign __sig``_b_ready = __intf.b_ready;    

`define ASSIGN_AXI_INTF_TO_AXI_SIG_AR(__sig, __intf)         \
assign __sig``_ar_id     = __intf.ar_id;         \
assign __sig``_ar_addr   = __intf.ar_addr;       \
assign __sig``_ar_len    = __intf.ar_len;        \
assign __sig``_ar_size   = __intf.ar_size;       \
assign __sig``_ar_burst  = __intf.ar_burst;      \
assign __sig``_ar_lock   = __intf.ar_lock ;      \
assign __sig``_ar_cache  = __intf.ar_cache;      \
assign __sig``_ar_prot   = __intf.ar_prot;       \
assign __sig``_ar_qos    = __intf.ar_qos;        \
assign __sig``_ar_region = __intf.ar_region;     \
assign __sig``_ar_user   = __intf.ar_user;      \
assign __sig``_ar_valid  = __intf.ar_valid;      \
assign __intf.ar_ready  = __sig``_ar_ready;

`define ASSIGN_AXI_INTF_TO_AXI_SIG_R(__sig, __intf)          \
assign __intf.r_id     = __sig``_r_id    ;          \
assign __intf.r_data   = __sig``_r_data  ;          \
assign __intf.r_resp   = __sig``_r_resp  ;          \
assign __intf.r_last   = __sig``_r_last  ;          \
assign __intf.r_user   = __sig``_r_user  ;          \
assign __intf.r_valid  = __sig``_r_valid ;         \
assign __sig``_r_ready = __intf.r_ready  ;
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
// Connect interface type with request and response type
// rr: resp and req
// assign intf type to corresponding req or resp
`define ASSIGN_INTF_TO_REQRESP_MST(__row, __col, __idx, __prefix) \
  `AXI_ASSIGN_FROM_REQ (mst_port_``__row``__col``_``__idx, ``__prefix``_mst_reqs_``__row``__col`` [__idx]) \
  `AXI_ASSIGN_TO_RESP  (``__prefix``_mst_resps_``__row``__col``[__idx], mst_port_``__row``__col``_``__idx)

`define ASSIGN_INTF_TO_REQRESP_SLV(__row, __col, __idx, __prefix) \
  `AXI_ASSIGN_TO_REQ   (``__prefix``_slv_reqs_``__row``__col`` [__idx], slv_port_``__row``__col``_``__idx) \
  `AXI_ASSIGN_FROM_RESP(slv_port_``__row``__col``_``__idx, ``__prefix``_slv_resps_``__row``__col``[__idx])

`endif
