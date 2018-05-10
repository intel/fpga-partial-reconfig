// Copyright (c) 2001-2018 Intel Corporation
//  
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//  
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//  
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

`ifndef INC_DESIGN_TOP_SIM_PKG_SV
`define INC_DESIGN_TOP_SIM_PKG_SV

`include "uvm_macros.svh"

package design_top_sim_pkg;
   import uvm_pkg::*;

   `include "sim_reporting.sv"
   `include "reset_watchdog.sv"
   `include "sb_predictor_base.sv"
   `include "sb_predictor_base.sv"
   `include "sb_predict.sv"
   `include "scoreboard.sv"
   `include "environment.sv"
   //`include "base_test.sv"

   //`include "persona_base_sequence_lib.sv"
   //`include "basic_arith_sequence_lib.sv"
   //`include "region0_pr_sequence_lib.sv"
   
endpackage


`endif //INC_DESIGN_TOP_SIM_PKG_SV
