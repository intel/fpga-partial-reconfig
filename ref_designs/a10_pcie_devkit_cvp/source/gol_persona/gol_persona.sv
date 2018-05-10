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

// This is the gol persona, takes an input for the initial board, and then returns the final board after a set number of iterations

module gol_persona 
(
      input  wire         pr_region_clk ,
      input  wire         pr_logic_rst , 
      // DDR4 interface
      input  wire         emif_usr_clk ,
      input  wire         emif_usr_rst_n ,
      input  wire         emif_avmm_waitrequest , 
      input  wire [511:0] emif_avmm_readdata , 
      input  wire         emif_avmm_readdatavalid , 
      output wire [6:0]   emif_avmm_burstcount , 
      output wire [511:0] emif_avmm_writedata , 
      output wire [24:0]  emif_avmm_address , 
      output wire         emif_avmm_write , 
      output wire         emif_avmm_read , 
      output wire [63:0]  emif_avmm_byteenable ,
      // AVMM interface
      output wire         pr_region_avmm_waitrequest ,
      output wire [31:0]  pr_region_avmm_readdata ,
      output wire         pr_region_avmm_readdatavalid,
      input  wire [0:0]   pr_region_avmm_burstcount ,
      input  wire [31:0]  pr_region_avmm_writedata ,
      input  wire [13:0]  pr_region_avmm_address ,
      input  wire         pr_region_avmm_write ,
      input  wire         pr_region_avmm_read ,
      input  wire [3:0]   pr_region_avmm_byteenable
);

   //Define Number of IO registers, base case is 8 input and 8 output
   //Additional regisetrs requires modification of the reg_file.qsys
   localparam REG_FILE_IO_SIZE = 8;
   //Template does not use DDR4 access, tie these signals low.


   wire                clr_io_reg;
   //PCIe reset, or the pll is not locked.

   wire [31:0]         host_pr[0:REG_FILE_IO_SIZE-1];

   wire [31:0]         pr_host [0:REG_FILE_IO_SIZE-1];

   wire [31:0]         persona_id;
   wire [31:0]         host_cntrl_register;

   gol_top #( .REG_FILE_IO_SIZE(REG_FILE_IO_SIZE) ) 
   u_pr_logic 
   (
      //clock
      .clk                       ( pr_region_clk ),                      
      .pr_logic_rst              ( pr_logic_rst ),   
      .clr_io_reg                ( clr_io_reg ),                      
      //Persona identification register, used by host in host program
      .persona_id                ( persona_id ),                     
      //Host control register, used for control signals.
      .host_cntrl_register       ( host_cntrl_register ),   
      // 8 registers for host -> PR logic communication
      .host_pr                   ( host_pr ),                      
      // 8 Registers for PR logic -> host communication
      .pr_host                   ( pr_host ),
      //DDR4 Reset
      .emif_avmm_waitrequest     ( emif_avmm_waitrequest ),
      .emif_avmm_readdata        ( emif_avmm_readdata ),
      .emif_avmm_readdatavalid   ( emif_avmm_readdatavalid ),
      .emif_avmm_burstcount      ( emif_avmm_burstcount ),
      .emif_avmm_writedata       ( emif_avmm_writedata ),
      .emif_avmm_address         ( emif_avmm_address ),
      .emif_avmm_write           ( emif_avmm_write ),
      .emif_avmm_read            ( emif_avmm_read ),
      .emif_avmm_byteenable      ( emif_avmm_byteenable )              
   );
   //////Register Address Map//////////////////
   //    reg_file_persona_id         = 0x0000
   //    reg_file_control_register   = 0x0010
   //    reg_file_pr_host_0          = 0x0020
   //    reg_file_pr_host_1          = 0x0030
   //    reg_file_pr_host_2          = 0x0040
   //    reg_file_pr_host_3          = 0x0050
   //    reg_file_pr_host_4          = 0x0060
   //    reg_file_pr_host_5          = 0x0070
   //    reg_file_pr_host_6          = 0x0080
   //    reg_file_pr_host_7          = 0x0090
   //    reg_file_host_pr_0          = 0x00a0
   //    reg_file_host_pr_1          = 0x00b0
   //    reg_file_host_pr_2          = 0x00c0
   //    reg_file_host_pr_3          = 0x00d0
   //    reg_file_host_pr_4          = 0x00e0
   //    reg_file_host_pr_5          = 0x00f0
   //    reg_file_host_pr_6          = 0x0100
   //    reg_file_host_pr_7          = 0x0110
   ////////////////////////////////////////////   

   reg_file u_reg_file 
      (
         .reg_file_clock_clk_clk                   ( pr_region_clk ),
         .reg_file_hw_rst_reset                    ( pr_logic_rst ),
         .reg_file_io_clr_reset                    ( clr_io_reg ),
         //PR Identification register
         .reg_file_persona_id_export               ( persona_id ),
         //Host Controlled Reset
         .reg_file_control_register_export         ( host_cntrl_register ),
         //Avalon MM Interface
         .reg_file_mm_bridge_s0_waitrequest        ( pr_region_avmm_waitrequest ),
         .reg_file_mm_bridge_s0_readdata           ( pr_region_avmm_readdata ),
         .reg_file_mm_bridge_s0_readdatavalid      ( pr_region_avmm_readdatavalid ),
         .reg_file_mm_bridge_s0_burstcount         ( pr_region_avmm_burstcount ),
         .reg_file_mm_bridge_s0_writedata          ( pr_region_avmm_writedata ),
         .reg_file_mm_bridge_s0_address            ( pr_region_avmm_address[8:0] ),
         .reg_file_mm_bridge_s0_write              ( pr_region_avmm_write ),
         .reg_file_mm_bridge_s0_read               ( pr_region_avmm_read ),
         .reg_file_mm_bridge_s0_byteenable         ( pr_region_avmm_byteenable ),
         .reg_file_mm_bridge_s0_debugaccess        ( 1'b0 ),
         //Host -> PR System registers
         .reg_file_host_pr_0_export                ( host_pr[0] ),
         .reg_file_host_pr_1_export                ( host_pr[1] ),
         .reg_file_host_pr_2_export                ( host_pr[2] ),
         .reg_file_host_pr_3_export                ( host_pr[3] ),
         .reg_file_host_pr_4_export                ( host_pr[4] ),
         .reg_file_host_pr_5_export                ( host_pr[5] ),
         .reg_file_host_pr_6_export                ( host_pr[6] ),
         .reg_file_host_pr_7_export                ( host_pr[7] ),
         // PR System -> Host registers
         .reg_file_pr_host_0_export                ( pr_host[0] ),
         .reg_file_pr_host_1_export                ( pr_host[1] ),
         .reg_file_pr_host_2_export                ( pr_host[2] ),
         .reg_file_pr_host_3_export                ( pr_host[3] ),
         .reg_file_pr_host_4_export                ( pr_host[4] ),
         .reg_file_pr_host_5_export                ( pr_host[5] ),
         .reg_file_pr_host_6_export                ( pr_host[6] ),
         .reg_file_pr_host_7_export                ( pr_host[7] )
      );
endmodule
