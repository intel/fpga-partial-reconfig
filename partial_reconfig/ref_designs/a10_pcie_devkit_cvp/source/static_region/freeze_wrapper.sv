// Copyright (c) 2001-2016 Intel Corporation
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

`timescale 1 ps / 1 ps
`default_nettype none

// This module stablizes the PR output during Partial Reconfiguration using
// alt_pr_freeze_freeze,

module freeze_wrapper (
      input   wire            alt_pr_freeze_freeze,       //  alt_pr_freeze.freeze
      input   wire            pr_logic_clk_clk,           //  pr_logic_clk.clk
      input   wire            iopll_locked,

      // DDR4 interface
      input   wire            pr_logic_mm_waitrequest,    //  pr_logic_mm_.waitrequest
      input   wire [511:0]    pr_logic_mm_readdata,       //              .readdata
      input   wire            pr_logic_mm_readdatavalid,  //              .readdatavalid
      output  wire [4:0]      pr_logic_mm_burstcount,     //              .burstcount
      output  wire [511:0]    pr_logic_mm_writedata,      //              .writedata
      output  wire [30:0]     pr_logic_mm_address,        //              .address
      output  reg             pr_logic_mm_write,          //              .write
      output  reg             pr_logic_mm_read,           //              .read
      output  wire [63:0]     pr_logic_mm_byteenable,     //              .byteenable
      output  reg             pr_logic_mm_debugaccess,    //              .debugaccess
      input   wire            local_cal_success,
      input   wire            local_cal_fail,   
      input   wire            emif_out_clk,   
      input   wire            emif_out_reset,   
      output  reg             ddr4a_global_reset,
      output  reg             pr_logic_reset,

      // PCIe interface
      output  reg          pr_logic_cra_waitrequest,      //  pr_logic_cra.waitrequest
      output  wire [31:0]  pr_logic_cra_readdata,         //              .readdata
      output  reg          pr_logic_cra_readdatavalid,    //              .readdatavalid
      input   wire [0:0]   pr_logic_cra_burstcount,       //              .burstcount
      input   wire [31:0]  pr_logic_cra_writedata,        //              .writedata
      input   wire [13:0]  pr_logic_cra_address,          //              .address
      input   wire         pr_logic_cra_write,            //              .write
      input   wire         pr_logic_cra_read,             //              .read
      input   wire [3:0]   pr_logic_cra_byteenable,       //              .byteenable
      input   wire         pr_logic_cra_debugaccess,      //              .debugaccess
      input   wire         pr_logic_reset_reset_n         //  pr_logic_reset.reset_n
);

// The output ports driven by PR logic need to stablized during PR reprograming. 
wire pr_region_cra_waitrequest;
wire pr_region_cra_readdatavalid;
wire pr_region_mm_write;
wire pr_region_mm_read;
wire pr_region_mm_debugaccess;
wire pr_region_ddr4a_global_reset;
wire pr_region_reset;

always_comb
begin
   // The freeze control signal, alt_pr_freeze_freeze from alt_pr, is used
   // to hold all output pins of the PR region in an inactive state.
   pr_logic_cra_waitrequest    = alt_pr_freeze_freeze ?   1'b1 : pr_region_cra_waitrequest;
   // By holding readdatavalid signal low during PR, potential toggling of
   // pr_logic_cra_readdata would be ignored. 
   pr_logic_cra_readdatavalid  = alt_pr_freeze_freeze ?   1'b0 : pr_region_cra_readdatavalid;

   // Only Control output pins need to get intercepted during PR reconfiguration
   pr_logic_mm_write           = alt_pr_freeze_freeze ?   1'b0 : pr_region_mm_write;
   pr_logic_mm_read            = alt_pr_freeze_freeze ?   1'b0 : pr_region_mm_read;
   pr_logic_mm_debugaccess     = alt_pr_freeze_freeze ?   1'b0 : pr_region_mm_debugaccess;

   ddr4a_global_reset          = alt_pr_freeze_freeze ?   1'b0 : pr_region_ddr4a_global_reset;
   pr_logic_reset              = alt_pr_freeze_freeze ?   1'b0 : pr_region_reset;
end


// PR Logic instantiation
//
ddr4_access_top u_pr_logic (
      .pr_logic_clk_clk               ( pr_logic_clk_clk ),           // pr_logic_clk.clk
      .iopll_locked                   ( iopll_locked ),

      // DDR4 interface
      .pr_logic_mm_waitrequest        ( pr_logic_mm_waitrequest ),    // pr_logic_mm.waitrequest
      .pr_logic_mm_readdata           ( pr_logic_mm_readdata ),       //            .readdata
      .pr_logic_mm_readdatavalid      ( pr_logic_mm_readdatavalid ),  //            .readdatavalid
      .pr_logic_mm_burstcount         ( pr_logic_mm_burstcount ),     //            .burstcount
      .pr_logic_mm_writedata          ( pr_logic_mm_writedata ),      //            .writedata
      .pr_logic_mm_address            ( pr_logic_mm_address ),        //            .address
      .pr_logic_mm_write              ( pr_region_mm_write ),         //            .write
      .pr_logic_mm_read               ( pr_region_mm_read ),          //            .read
      .pr_logic_mm_byteenable         ( pr_logic_mm_byteenable ),     //            .byteenable
      .pr_logic_mm_debugaccess        ( pr_region_mm_debugaccess ),   //            .debugaccess
      .local_cal_success              ( local_cal_success ),
      .local_cal_fail                 ( local_cal_fail ),
      .emif_out_clk                   ( emif_out_clk ),
      .emif_out_reset                 ( emif_out_reset ),
      .ddr4a_global_reset             ( pr_region_ddr4a_global_reset ),
      .pr_logic_reset                 ( pr_region_reset ),


       // PCIe interface
      .pr_logic_cra_waitrequest       ( pr_region_cra_waitrequest ),  // pr_logic_cra.waitrequest (hold to 1 during freeze)
      .pr_logic_cra_readdata          ( pr_logic_cra_readdata ),      //             .readdata
      .pr_logic_cra_readdatavalid     ( pr_region_cra_readdatavalid ),//             .readdatavalid (hold to 0 during freeze)
      .pr_logic_cra_burstcount        ( pr_logic_cra_burstcount ),    //             .burstcount
      .pr_logic_cra_writedata         ( pr_logic_cra_writedata),      //             .writedata
      .pr_logic_cra_address           ( pr_logic_cra_address ),       //             .address
      .pr_logic_cra_write             ( pr_logic_cra_write ),         //             .write
      .pr_logic_cra_read              ( pr_logic_cra_read ),          //             .read
      .pr_logic_cra_byteenable        ( pr_logic_cra_byteenable ),    //             .byteenable
      .pr_logic_cra_debugaccess       ( pr_logic_cra_debugaccess ),   //             .debugaccess
      .pr_logic_reset_reset_n         ( pr_logic_reset_reset_n )      // pr_logic_reset.reset_n
);


endmodule
