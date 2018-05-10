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

interface bar4_avalon_mm_monitor_bfm
(
 clk,
 reset,

 avs_waitrequest,
 avs_write,
 avs_read,
 avs_address,
 avs_byteenable,
 avs_burstcount,
 avs_writedata,
 avs_readdata,
 avs_readdatavalid,

 avm_waitrequest,
 avm_write,
 avm_read,
 avm_address,
 avm_byteenable,
 avm_burstcount,
 avm_writedata,
 avm_readdata,
 avm_readdatavalid
);

   input clk;
   input reset;

   // Avalon Master Interface
   output [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_ADDRESS_W-1:0] avm_address;
   input [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_DATA_W-1:0] avm_readdata;
   input avm_waitrequest;
   output [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_DATA_W-1:0] avm_writedata;
   output avm_write;
   output avm_read;
   output [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_BURSTCOUNT_W-1:0] avm_burstcount;
   input avm_readdatavalid;
   output [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_NUMSYMBOLS-1:0] avm_byteenable;

   input [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_ADDRESS_W-1:0] avs_address;
   output [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_DATA_W-1:0] avs_readdata;
   input [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_DATA_W-1:0] avs_writedata;
   input avs_write;
   input avs_read;
   input [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_BURSTCOUNT_W-1:0] avs_burstcount;
   output avs_waitrequest;
   input [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_NUMSYMBOLS-1:0] avs_byteenable;
   output avs_readdatavalid;

   altera_avalon_mm_monitor_iface
   #(
     .AV_ADDRESS_W(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_ADDRESS_W),
     .AV_SYMBOL_W(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_SYMBOL_W),
     .AV_NUMSYMBOLS(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_NUMSYMBOLS),
     .AV_BURSTCOUNT_W(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_BURSTCOUNT_W),
     .AV_READRESPONSE_W(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_READRESPONSE_W),
     .AV_WRITERESPONSE_W(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_WRITERESPONSE_W),
     .USE_READ(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_USE_READ),
     .USE_WRITE(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_USE_WRITE),
     .USE_ADDRESS(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_USE_ADDRESS),
     .USE_BYTE_ENABLE(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_USE_BYTE_ENABLE),
     .USE_BURSTCOUNT(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_USE_BURSTCOUNT),
     .USE_READ_DATA(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_USE_READ_DATA),
     .USE_READ_DATA_VALID(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_USE_READ_DATA_VALID),
     .USE_WRITE_DATA(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_USE_WRITE_DATA),
     .USE_BEGIN_TRANSFER(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_USE_BEGIN_TRANSFER),
     .USE_BEGIN_BURST_TRANSFER(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_USE_BEGIN_BURST_TRANSFER),
     .USE_WAIT_REQUEST(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_USE_WAIT_REQUEST),
     .USE_TRANSACTIONID(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_USE_TRANSACTIONID),
     .USE_WRITERESPONSE(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_USE_WRITERESPONSE),
     .USE_READRESPONSE(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_USE_READRESPONSE),
     .USE_CLKEN(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_USE_CLKEN),
     .AV_CONSTANT_BURST_BEHAVIOR(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_CONSTANT_BURST_BEHAVIOR),
     .AV_BURST_LINEWRAP(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_BURST_LINEWRAP),
     .AV_BURST_BNDR_ONLY(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_BURST_BNDR_ONLY),
     .AV_MAX_PENDING_READS(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_MAX_PENDING_READS),
     .AV_MAX_PENDING_WRITES(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_MAX_PENDING_WRITES),
     .AV_FIX_READ_LATENCY(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_FIX_READ_LATENCY),
     .AV_READ_WAIT_TIME(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_READ_WAIT_TIME),
     .AV_WRITE_WAIT_TIME(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_WRITE_WAIT_TIME),
     .REGISTER_WAITREQUEST(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_REGISTER_WAITREQUEST),
     .AV_REGISTERINCOMINGSIGNALS(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_REGISTERINCOMINGSIGNALS),
     .VHDL_ID(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_VHDL_ID),
     .SLAVE_ADDRESS_TYPE(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_SLAVE_ADDRESS_TYPE),
     .MASTER_ADDRESS_TYPE(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_MASTER_ADDRESS_TYPE)
   ) bfm(
         .clk(clk),
         .reset(reset),
         .avs_address(avs_address),
         .avs_readdata(avs_readdata),
         .avs_writedata(avs_writedata),
         .avs_write(avs_write),
         .avs_read(avs_read),
         .avs_burstcount(avs_burstcount),
         .avs_begintransfer(),
         .avs_beginbursttransfer(),
         .avs_waitrequest(avs_waitrequest),
         .avs_byteenable(avs_byteenable),
         .avs_readdatavalid(avs_readdatavalid),
         .avs_arbiterlock(),
         .avs_lock(),
         .avs_debugaccess(),
         .avs_transactionid(),
         .avs_readid(),
         .avs_writeid(),
         .avs_clken(),
         .avs_response(),
         .avs_writeresponserequest(),
         .avs_writeresponsevalid(),
         .avs_readresponse(),
         .avs_writeresponse(),

         .avm_address(avm_address),
         .avm_readdata(avm_readdata),
         .avm_writedata(avm_writedata),
         .avm_write(avm_write),
         .avm_read(avm_read),
         .avm_burstcount(avm_burstcount),
         .avm_begintransfer(),
         .avm_beginbursttransfer(),
         .avm_waitrequest(avm_waitrequest),
         .avm_byteenable(avm_byteenable),
         .avm_readdatavalid(avm_readdatavalid),
         .avm_arbiterlock(),
         .avm_lock(),
         .avm_debugaccess(),
         .avm_transactionid(),
         .avm_readid(),
         .avm_writeid(),
         .avm_clken(),
         .avm_response(),
         .avm_writeresponserequest(),
         .avm_writeresponsevalid(),
         .avm_readresponse(),
         .avm_writeresponse()
   );


endinterface
