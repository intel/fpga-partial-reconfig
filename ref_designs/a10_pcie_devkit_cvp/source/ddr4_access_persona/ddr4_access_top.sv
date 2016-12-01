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

// This module is DDRaccess persona. 
// It is the default persona of the design.

module ddr4_access_top (
      input  wire         pr_logic_clk_clk,                 //       pr_logic_clk.clk
      input  wire         iopll_locked,

      // DDR4 interface
      input  wire         pr_logic_mm_waitrequest,          //       pr_logic_mm.waitrequest
      input  wire [511:0] pr_logic_mm_readdata,             //                  .readdata
      input  wire         pr_logic_mm_readdatavalid,        //                  .readdatavalid
      output reg  [4:0]   pr_logic_mm_burstcount,           //                  .burstcount
      output reg  [511:0] pr_logic_mm_writedata,            //                  .writedata
      output reg  [30:0]  pr_logic_mm_address,              //                  .address
      output reg          pr_logic_mm_write,                //                  .write
      output reg          pr_logic_mm_read,                 //                  .read
      output reg  [63:0]  pr_logic_mm_byteenable,           //                  .byteenable
      output reg          pr_logic_mm_debugaccess,          //                  .debugaccess
      input  wire         local_cal_success,
      input  wire         local_cal_fail,   
      input  wire         emif_out_clk,
      input  wire         emif_out_reset,
      output wire         ddr4a_global_reset,
      output reg          pr_logic_reset,

      // PCIe interface
      output reg          pr_logic_cra_waitrequest,         //       pr_logic_cra.waitrequest
      output wire [31:0]  pr_logic_cra_readdata,            //                   .readdata
      output wire         pr_logic_cra_readdatavalid,       //                   .readdatavalid
      input  wire [0:0]   pr_logic_cra_burstcount,          //                   .burstcount
      input  wire [31:0]  pr_logic_cra_writedata,           //                   .writedata
      input  wire [13:0]  pr_logic_cra_address,             //                   .address
      input  wire         pr_logic_cra_write,               //                   .write
      input  wire         pr_logic_cra_read,                //                   .read
      input  wire [3:0]   pr_logic_cra_byteenable,          //                   .byteenable
      input  wire         pr_logic_cra_debugaccess,         //                   .debugaccess
      input  wire         pr_logic_reset_reset_n            //     pr_logic_reset.reset_n
   );

   // Local Signals
   localparam RST_CNTR_WIDTH  = 8;
   localparam RECALIB_MAX_NUM = 2;  // HW is implemented with a max number of 8, i.e. a 3-bit counter
   
   
   wire [1:0]   mode;
   wire         start_operation;
   wire         sw_reset;
   wire         emif_reset;
   wire [7:0]   limit;
   wire [31:0]  mem_addr;
   wire         post_wr_pulse;
   wire [31:0]  seed;

   wire         cal_success, cal_fail;
   wire         clear_start_operation;
   wire         start_recalibration;
   wire         start_traffic_generator;
   wire         busy;
   wire         reset_recal_counter;
   wire         max_retry_cal_reached;
   wire         rst_blk_busy;
   wire         ddr_access_completed;
   wire         pass;
   wire         fail;
   wire         load_seed;
   wire         start_ddr_wr_rd;

   // The signal pr_logic_reset is used at mem_ctrl logic to reset the
   // section of mm_clock_crossing_bridge that operates on PR clock
   always_comb
   begin
      pr_logic_reset = sw_reset | ~pr_logic_reset_reset_n;
   end
   
   wire [3:0]   pr_op_err;
   wire [31:0]  performance_cntr;

   reg [30:0]  target_address;
   reg [511:0] target_data;


   // synchronize signals from EMIF clock domain to the current clock domain
   synchronizer # ( 
      .WIDTH    (1),
      .STAGES   (2)
   ) u_synchronizer_cal_success (
      .clk_in                                 ( emif_out_clk ),
      .arst_in                                ( emif_out_reset ),
      .clk_out                                ( pr_logic_clk_clk ),
      .arst_out                               ( ~pr_logic_reset_reset_n ),
      .dat_in                                 ( local_cal_success ),
      .dat_out                                ( cal_success )
   );

   synchronizer # ( 
      .WIDTH    (1),
      .STAGES   (2)
   ) u_synchronizer_cal_fail (
      .clk_in                                 ( emif_out_clk ),
      .arst_in                                ( emif_out_reset ),
      .clk_out                                ( pr_logic_clk_clk ),
      .arst_out                               ( ~pr_logic_reset_reset_n ),
      .dat_in                                 ( local_cal_fail ),
      .dat_out                                ( cal_fail )
   );


   reg_blk u_reg_blk (
      .pr_logic_clk_clk                       ( pr_logic_clk_clk ),
      .iopll_locked                           ( iopll_locked ),

      // Register Field inputs
      .pr_op_err                             ( pr_op_err ),
      .local_cal_success                      ( cal_success ),
      .local_cal_fail                           ( cal_fail ),
      .performance_cntr                       ( performance_cntr ),
      .clear_start_operation                  ( clear_start_operation ),
      .ddr_access_completed                   ( ddr_access_completed ),

      // Register Field outputs
      .mode                                ( mode ),
      .start_operation                        ( start_operation ),
      .sw_reset                               ( sw_reset ),
      .emif_reset                             ( emif_reset ),
      .load_seed                              ( load_seed ),
      .limit                               ( limit ),
      .mem_addr                               ( mem_addr ),
      .post_wr_pulse                          ( post_wr_pulse ),
      .seed                                   ( seed ),

      // PCIe interface
      .pr_logic_cra_waitrequest              ( pr_logic_cra_waitrequest ),
      .pr_logic_cra_readdata                 ( pr_logic_cra_readdata ),
      .pr_logic_cra_readdatavalid               ( pr_logic_cra_readdatavalid ),
      .pr_logic_cra_burstcount               ( pr_logic_cra_burstcount ),
      .pr_logic_cra_writedata                ( pr_logic_cra_writedata ),
      .pr_logic_cra_address                  ( pr_logic_cra_address ),
      .pr_logic_cra_write                    ( pr_logic_cra_write ),
      .pr_logic_cra_read                      ( pr_logic_cra_read ),
      .pr_logic_cra_byteenable               ( pr_logic_cra_byteenable ),
      .pr_logic_cra_debugaccess              ( pr_logic_cra_debugaccess ),
      .pr_logic_reset_reset_n                ( pr_logic_reset_reset_n )

   );

   rst_blk # (
      .RST_CNTR_WIDTH                         ( RST_CNTR_WIDTH ),
      .RECALIB_MAX_NUM                        ( RECALIB_MAX_NUM )
   ) u_rst_blk (
      .pr_logic_clk_clk                       ( pr_logic_clk_clk ),
      .start_recalibration                    ( start_recalibration ),
      .sw_reset                             ( sw_reset ),
      .emif_reset                             ( emif_reset ),
      .ddr4a_global_reset                     ( ddr4a_global_reset ),
      .max_retry_cal_reached                  ( max_retry_cal_reached ),
      .reset_recal_counter                    ( reset_recal_counter ),
      .rst_blk_busy                           ( rst_blk_busy ),
      .pr_logic_reset_reset_n                 ( pr_logic_reset_reset_n )
   );

   mem_access u_mem_access (
      .pr_logic_clk_clk                       ( pr_logic_clk_clk ),
      .sw_reset                             ( sw_reset ),
      .start_operation                        ( start_operation ),
      .local_cal_success                       ( cal_success ),
      .local_cal_fail                          ( cal_fail ),
      .max_retry_cal_reached                  ( max_retry_cal_reached ),
      .ddr_access_completed                   ( ddr_access_completed ),
      .clear_start_operation                  ( clear_start_operation ),
      .start_recalibration                    ( start_recalibration ),        
      .rst_blk_busy                           ( rst_blk_busy ),
      .start_traffic_generator                ( start_traffic_generator ),        
      .busy                                   ( busy ),        
      .reset_recal_counter                    ( reset_recal_counter ),
      .pr_logic_reset_reset_n                 ( pr_logic_reset_reset_n )
   );

   traffic_generator u_traffic_generator (
      .pr_logic_clk_clk                       ( pr_logic_clk_clk ),
      .sw_reset                             ( sw_reset ),

      .start_traffic_generator                ( start_traffic_generator ),        
      .ddr_access_completed                   ( ddr_access_completed ),
      
      .mode                                ( mode ),
      .limit                               ( limit ),
      .mem_addr                               ( mem_addr ),
      .post_wr_pulse                          ( post_wr_pulse ),
      .seed                                   ( seed ),
      .load_seed                              ( load_seed ),

      .start_ddr_wr_rd                        ( start_ddr_wr_rd ),
      .target_address                         ( target_address ),
      .target_data                            ( target_data ),
      .pass                                   ( pass ),
      .fail                                   ( fail ),

      .pr_logic_reset_reset_n                 ( pr_logic_reset_reset_n )
   );

   ddr_wr_rd u_ddr_wr_rd (
      .pr_logic_clk_clk                       ( pr_logic_clk_clk ),
      .sw_reset                             ( sw_reset ),
      .local_cal_success                       ( cal_success ),

      .start_ddr_wr_rd                        ( start_ddr_wr_rd ),        
      .target_address                         ( target_address ),
      .target_data                            ( target_data ),

      .pr_logic_mm_waitrequest                ( pr_logic_mm_waitrequest ),
      .pr_logic_mm_readdata                   ( pr_logic_mm_readdata ),
      .pr_logic_mm_readdatavalid              ( pr_logic_mm_readdatavalid ),
      .pr_logic_mm_burstcount                 ( pr_logic_mm_burstcount ),
      .pr_logic_mm_writedata                  ( pr_logic_mm_writedata ),
      .pr_logic_mm_address                    ( pr_logic_mm_address ),
      .pr_logic_mm_write                      ( pr_logic_mm_write ),
      .pr_logic_mm_read                       ( pr_logic_mm_read ),
      .pr_logic_mm_byteenable                 ( pr_logic_mm_byteenable ),
      .pr_logic_mm_debugaccess                ( pr_logic_mm_debugaccess ),

      .pass                                   ( pass ),
      .fail                                   ( fail ),
      .ddr_access_completed                   (  ),

      .pr_logic_reset_reset_n                 ( pr_logic_reset_reset_n )
   );

   perf_cntr u_perf_cntr (
      .pr_logic_clk_clk                       ( pr_logic_clk_clk ),
      .sw_reset                             ( sw_reset ),
      .pass                                   ( pass ),
      .performance_cntr                       ( performance_cntr ),
      .pr_logic_reset_reset_n                 ( pr_logic_reset_reset_n )
   );

   fault_detect u_fault_detect (
      .pr_logic_clk_clk                       ( pr_logic_clk_clk ),
      .sw_reset                             ( sw_reset ),
      .start_operation                      ( start_operation ),
      .max_retry_cal_reached                  ( max_retry_cal_reached ),
      .fail                                   ( fail ),
      .pr_op_err                             ( pr_op_err ),
      .pr_logic_reset_reset_n                 ( pr_logic_reset_reset_n )
   );

endmodule
