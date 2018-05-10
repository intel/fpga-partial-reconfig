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

`timescale 1 ps / 1 ps
`default_nettype none

// This module is DDRaccess persona. 
// It is the default persona of the design.

module ddr4_access_top #(parameter REG_FILE_IO_SIZE = 8) 
   (
      //clock
      input wire          clk ,
      input wire          pr_logic_rst ,
      output reg          clr_io_reg ,
      //Persona identification register, used by host in host program
      output reg [31:0]   persona_id ,
      //Host control register, used for control signals.
      input wire [31:0]   host_cntrl_register ,
      // 8 registers for host -> PR logic communication
      input wire [31:0]   host_pr [0:REG_FILE_IO_SIZE-1],
      // 8 Registers for PR logic -> host communication
      output wire [31:0]  pr_host [0:REG_FILE_IO_SIZE-1],
      // DDR4 interface
      input wire          emif_avmm_waitrequest , 
      input wire [511:0]  emif_avmm_readdata , 
      input wire          emif_avmm_readdatavalid ,
      output reg [6:0]    emif_avmm_burstcount , 
      output reg [511:0]  emif_avmm_writedata , 
      output reg [24:0]   emif_avmm_address , 
      output reg          emif_avmm_write , 
      output reg          emif_avmm_read , 
      output reg [63:0]   emif_avmm_byteenable
   );

   wire                 start_operation;
   wire [31:0]          mem_addr;
   wire                 post_wr_pulse;
   wire [31:0]          seed;
   wire                 clear_start_operation;
   wire                 start_traffic_generator;
   wire                 rst_blk_busy;
   wire                 ddr_access_completed;
   wire                 pass;
   wire                 fail;
   wire                 busy_reg;
   wire                 load_seed;
   wire                 start_ddr_wr_rd;
   wire [31:0]          final_address;
   wire [31:0]          performance_cntr;
   reg [24:0]           target_address;
   reg [511:0]          target_data;

   ddr4_access_persona_controller #(
      .REG_FILE_IO_SIZE(REG_FILE_IO_SIZE)
   ) u_ddr4_access_persona_controller (
      .clk                                     ( clk ),
      .pr_logic_rst                            ( pr_logic_rst ),
      .clr_io_reg                              ( clr_io_reg ),
      .persona_id                              ( persona_id ),
      .host_cntrl_register                     ( host_cntrl_register ),
      .host_pr                                 ( host_pr ),
      .pr_host                                 ( pr_host ),
      // Register Field inputs
      .performance_cntr                        ( performance_cntr ),
      .clear_start_operation                   ( clear_start_operation ),
      .ddr_access_completed                    ( ddr_access_completed ),
      // Register Field outputs
      .start_operation                         ( start_operation ),
      .load_seed                               ( load_seed ),
      .mem_addr                                ( mem_addr ),
      .post_wr_pulse                           ( post_wr_pulse ),
      .seed                                    ( seed ),
      .busy_reg                                ( busy_reg ),
      .final_address                           ( final_address ) 
   );
   
   mem_access u_mem_access 
   (
      .pr_region_clk                           ( clk ),
      .clr_io_reg                              ( clr_io_reg ),
      .start_operation                         ( start_operation ),
      .ddr_access_completed                    ( ddr_access_completed ),
      .busy_reg                                ( busy_reg ),
      .clear_start_operation                   ( clear_start_operation ),
      .start_traffic_generator                 ( start_traffic_generator ),        
      .pr_logic_rst                            ( pr_logic_rst )
   );

   traffic_generator u_traffic_generator 
   (
      .pr_region_clk                          ( clk ),
      .clr_io_reg                             ( clr_io_reg ),
      .start_traffic_generator                ( start_traffic_generator ),        
      .ddr_access_completed                   ( ddr_access_completed ),
      .mem_addr                               ( mem_addr ),
      .post_wr_pulse                          ( post_wr_pulse ),
      .seed                                   ( seed ),
      .load_seed                              ( load_seed ),
      .start_ddr_wr_rd                        ( start_ddr_wr_rd ),
      .target_address                         ( target_address ),
      .target_data                            ( target_data ),
      .pass                                   ( pass ),
      .fail                                   ( fail ),
      .pr_logic_rst                           ( pr_logic_rst ),
      .final_addr                             ( final_address ) 
   );

   ddr_wr_rd u_ddr_wr_rd 
   (
      .pr_region_clk                          ( clk ),
      .clr_io_reg                             ( clr_io_reg ),
      .start_ddr_wr_rd                        ( start_ddr_wr_rd ),        
      .target_address                         ( target_address ),
      .target_data                            ( target_data ),
      .emif_avmm_waitrequest                  ( emif_avmm_waitrequest ),
      .emif_avmm_readdata                     ( emif_avmm_readdata ),
      .emif_avmm_readdatavalid                ( emif_avmm_readdatavalid ),
      .emif_avmm_burstcount                   ( emif_avmm_burstcount ),
      .emif_avmm_writedata                    ( emif_avmm_writedata ),
      .emif_avmm_address                      ( emif_avmm_address ),
      .emif_avmm_write                        ( emif_avmm_write ),
      .emif_avmm_read                         ( emif_avmm_read ),
      .emif_avmm_byteenable                   ( emif_avmm_byteenable ),
      .pass                                   ( pass ),
      .fail                                   ( fail ),
      .pr_logic_rst                           ( pr_logic_rst )
   );

   perf_cntr u_perf_cntr 
   (
      .pr_region_clk                         ( clk ),
      .clr_io_reg                            ( clr_io_reg ),
      .pass                                  ( pass ),
      .performance_cntr                      ( performance_cntr ),
      .pr_logic_rst                          ( pr_logic_rst )
   );


endmodule
