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

`ifndef INC_DESIGN_TOP_SIM_CFG_PKG_SV
`define INC_DESIGN_TOP_SIM_CFG_PKG_SV

package design_top_sim_cfg_pkg;
   
   //==================================================================================================
   // DUT parameters
   //==================================================================================================
   
   //==================================================================================================
   // BFM parameters
   //==================================================================================================
   
   localparam DESIGN_TOP_BAR4_BFM_AV_DATA_W = 32;
   localparam DESIGN_TOP_BAR4_BFM_SLAVE_ADDRESS_TYPE = "WORDS";
   localparam DESIGN_TOP_BAR4_BFM_MASTER_ADDRESS_TYPE = "WORDS";
   localparam DESIGN_TOP_BAR4_BFM_AV_ADDRESS_W = 17;
   localparam DESIGN_TOP_BAR4_BFM_AV_SYMBOL_W = 8;
   localparam DESIGN_TOP_BAR4_BFM_AV_NUMSYMBOLS = 4;
   localparam DESIGN_TOP_BAR4_BFM_AV_BURSTCOUNT_W = 1;
   localparam DESIGN_TOP_BAR4_BFM_AV_READRESPONSE_W = 1;
   localparam DESIGN_TOP_BAR4_BFM_AV_WRITERESPONSE_W = 1;
   localparam DESIGN_TOP_BAR4_BFM_USE_READ = 1;
   localparam DESIGN_TOP_BAR4_BFM_USE_WRITE = 1;
   localparam DESIGN_TOP_BAR4_BFM_USE_ADDRESS = 1;
   localparam DESIGN_TOP_BAR4_BFM_USE_BYTE_ENABLE = 1;
   localparam DESIGN_TOP_BAR4_BFM_USE_BURSTCOUNT = 1;
   localparam DESIGN_TOP_BAR4_BFM_USE_READ_DATA = 1;
   localparam DESIGN_TOP_BAR4_BFM_USE_READ_DATA_VALID = 1;
   localparam DESIGN_TOP_BAR4_BFM_USE_WRITE_DATA = 1;
   localparam DESIGN_TOP_BAR4_BFM_USE_BEGIN_TRANSFER = 0;
   localparam DESIGN_TOP_BAR4_BFM_USE_BEGIN_BURST_TRANSFER = 0;
   localparam DESIGN_TOP_BAR4_BFM_USE_WAIT_REQUEST = 1;
   localparam DESIGN_TOP_BAR4_BFM_USE_TRANSACTIONID = 0;
   localparam DESIGN_TOP_BAR4_BFM_USE_WRITERESPONSE = 0;
   localparam DESIGN_TOP_BAR4_BFM_USE_READRESPONSE = 0;
   localparam DESIGN_TOP_BAR4_BFM_USE_CLKEN = 0;
   localparam DESIGN_TOP_BAR4_BFM_AV_CONSTANT_BURST_BEHAVIOR = 1;
   localparam DESIGN_TOP_BAR4_BFM_AV_BURST_LINEWRAP = 0;
   localparam DESIGN_TOP_BAR4_BFM_AV_BURST_BNDR_ONLY = 0;
   localparam DESIGN_TOP_BAR4_BFM_AV_MAX_PENDING_READS = 4;
   localparam DESIGN_TOP_BAR4_BFM_AV_MAX_PENDING_WRITES = 0;
   localparam DESIGN_TOP_BAR4_BFM_AV_FIX_READ_LATENCY = 0;
   localparam DESIGN_TOP_BAR4_BFM_AV_READ_WAIT_TIME = 0;
   localparam DESIGN_TOP_BAR4_BFM_AV_WRITE_WAIT_TIME = 0;
   localparam DESIGN_TOP_BAR4_BFM_AV_WAITREQUEST_ALLOWANCE = 0;
   localparam DESIGN_TOP_BAR4_BFM_REGISTER_WAITREQUEST = 0;
   localparam DESIGN_TOP_BAR4_BFM_AV_REGISTERINCOMINGSIGNALS = 0;
   localparam DESIGN_TOP_BAR4_BFM_VHDL_ID = 1;

  
   localparam DESIGN_TOP_BAR2_BFM_AV_DATA_W = 32;
   localparam DESIGN_TOP_BAR2_BFM_SLAVE_ADDRESS_TYPE = "WORDS";
   localparam DESIGN_TOP_BAR2_BFM_MASTER_ADDRESS_TYPE = "WORDS";
   localparam DESIGN_TOP_BAR2_BFM_AV_ADDRESS_W = 16;
   localparam DESIGN_TOP_BAR2_BFM_AV_SYMBOL_W = 8;
   localparam DESIGN_TOP_BAR2_BFM_AV_NUMSYMBOLS = 4;
   localparam DESIGN_TOP_BAR2_BFM_AV_BURSTCOUNT_W = 1;
   localparam DESIGN_TOP_BAR2_BFM_AV_READRESPONSE_W = 1;
   localparam DESIGN_TOP_BAR2_BFM_AV_WRITERESPONSE_W = 1;
   localparam DESIGN_TOP_BAR2_BFM_USE_READ = 1;
   localparam DESIGN_TOP_BAR2_BFM_USE_WRITE = 1;
   localparam DESIGN_TOP_BAR2_BFM_USE_ADDRESS = 1;
   localparam DESIGN_TOP_BAR2_BFM_USE_BYTE_ENABLE = 1;
   localparam DESIGN_TOP_BAR2_BFM_USE_BURSTCOUNT = 1;
   localparam DESIGN_TOP_BAR2_BFM_USE_READ_DATA = 1;
   localparam DESIGN_TOP_BAR2_BFM_USE_READ_DATA_VALID = 1;
   localparam DESIGN_TOP_BAR2_BFM_USE_WRITE_DATA = 1;
   localparam DESIGN_TOP_BAR2_BFM_USE_BEGIN_TRANSFER = 0;
   localparam DESIGN_TOP_BAR2_BFM_USE_BEGIN_BURST_TRANSFER = 0;
   localparam DESIGN_TOP_BAR2_BFM_USE_WAIT_REQUEST = 1;
   localparam DESIGN_TOP_BAR2_BFM_USE_TRANSACTIONID = 0;
   localparam DESIGN_TOP_BAR2_BFM_USE_WRITERESPONSE = 0;
   localparam DESIGN_TOP_BAR2_BFM_USE_READRESPONSE = 0;
   localparam DESIGN_TOP_BAR2_BFM_USE_CLKEN = 0;
   localparam DESIGN_TOP_BAR2_BFM_AV_CONSTANT_BURST_BEHAVIOR = 1;
   localparam DESIGN_TOP_BAR2_BFM_AV_BURST_LINEWRAP = 0;
   localparam DESIGN_TOP_BAR2_BFM_AV_BURST_BNDR_ONLY = 0;
   localparam DESIGN_TOP_BAR2_BFM_AV_MAX_PENDING_READS = 4;
   localparam DESIGN_TOP_BAR2_BFM_AV_MAX_PENDING_WRITES = 0;
   localparam DESIGN_TOP_BAR2_BFM_AV_FIX_READ_LATENCY = 0;
   localparam DESIGN_TOP_BAR2_BFM_AV_READ_WAIT_TIME = 0;
   localparam DESIGN_TOP_BAR2_BFM_AV_WRITE_WAIT_TIME = 0;
   localparam DESIGN_TOP_BAR2_BFM_AV_WAITREQUEST_ALLOWANCE = 0;
   localparam DESIGN_TOP_BAR2_BFM_REGISTER_WAITREQUEST = 0;
   localparam DESIGN_TOP_BAR2_BFM_AV_REGISTERINCOMINGSIGNALS = 0;
   localparam DESIGN_TOP_BAR2_BFM_VHDL_ID = 0;
   

endpackage


`endif //INC_DESIGN_TOP_SIM_CFG_PKG_SV
