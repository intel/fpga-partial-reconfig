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

// This is the RegisterFile persona. It provies 256x32-bit set of
// Readable-Writable registers

module pr_logic_template (
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
   output reg          ddr4a_global_reset,
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

//Define Number of IO registers, base case is 8 input and 8 output
//Additional regisetrs requires modification of the reg_file.qsys
localparam REG_FILE_IO_SIZE = 8;
   //Template does not use DDR4 access, tie these signals low.
always_comb
begin
   ddr4a_global_reset      = 1'b0;
   pr_logic_reset          = 1'b0;
   pr_logic_mm_burstcount  = 5'b0;
   pr_logic_mm_writedata   = 512'b0;
   pr_logic_mm_address     = 31'b0;
   pr_logic_mm_write       = 1'b0;
   pr_logic_mm_read        = 1'b0;
   pr_logic_mm_byteenable  = 64'b0;
   pr_logic_mm_debugaccess = 1'b0;
end

wire pr_rst_sw_n;
//PCIe reset, or the pll is not locked.

wire [31:0] host_pr[0:REG_FILE_IO_SIZE-1];

wire [31:0] pr_host [0:REG_FILE_IO_SIZE-1];

wire [31:0] persona_id;
wire [31:0] host_cntrl_register;

`PR_CUSTOM_PERSONA #(

   .REG_FILE_IO_SIZE(REG_FILE_IO_SIZE)
      
   ) u_pr_logic (
   //clock
   .clk(pr_logic_clk_clk),                      
   
   //active low reset, defined by hardware
   .rst_n(pr_logic_reset_reset_n),   
   .sw_rst_n(pr_rst_sw_n),                      

   //Persona identification register, used by host in host program
   .persona_id(persona_id),                     
   
   //Host control register, used for control signals.
   .host_cntrl_register(host_cntrl_register),   
   
   // 8 registers for host -> PR logic communication
   .host_pr(host_pr),                      
   // 8 Registers for PR logic -> host communication
   .pr_host(pr_host)
   
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



reg_file u_reg_file (
         //Clocking and Hardware Reset
         .reg_file_clock_clk_clk                   (pr_logic_clk_clk),           // reg_file_clock_bridge_0_in_clk.clk
         .reg_file_hw_rst_n_reset_n                (pr_logic_reset_reset_n),     // reg_file_reset_bridge_0_in_reset.reset
         .reg_file_sw_rst_n_reset_n                (pr_rst_sw_n),
         
         //PR Identification register
         .reg_file_persona_id_export               (persona_id),                 // reg_file_persona_id_register_external_connection.export
         
         //Host Controlled Reset
         .reg_file_control_register_export         (host_cntrl_register),        // reg_file_software_reset_external_connection.export
         
         //Avalon MM Interface
         .reg_file_mm_bridge_0_s0_waitrequest      (pr_logic_cra_waitrequest),   // reg_file_mm_bridge_0_s0.waitrequest
         .reg_file_mm_bridge_0_s0_readdata         (pr_logic_cra_readdata),      //                        .readdata
         .reg_file_mm_bridge_0_s0_readdatavalid    (pr_logic_cra_readdatavalid), //                        .readdatavalid
         .reg_file_mm_bridge_0_s0_burstcount       (pr_logic_cra_burstcount),    //                        .burstcount
         .reg_file_mm_bridge_0_s0_writedata        (pr_logic_cra_writedata),     //                        .writedata
         .reg_file_mm_bridge_0_s0_address          (pr_logic_cra_address),       //                        .address
         .reg_file_mm_bridge_0_s0_write            (pr_logic_cra_write),         //                        .write
         .reg_file_mm_bridge_0_s0_read             (pr_logic_cra_read),          //                        .read
         .reg_file_mm_bridge_0_s0_byteenable       (pr_logic_cra_byteenable),    //                        .byteenable
         .reg_file_mm_bridge_0_s0_debugaccess      (pr_logic_cra_debugaccess),   //                        .debugaccess
         
         //Host -> PR System registers
         .reg_file_host_pr_0_export                (host_pr[0]),                  // reg_file_in_0.export
         .reg_file_host_pr_1_export                (host_pr[1]),                  // reg_file_in_1.export
         .reg_file_host_pr_2_export                (host_pr[2]),                  // reg_file_in_2.export
         .reg_file_host_pr_3_export                (host_pr[3]),                  // reg_file_in_3.export
         .reg_file_host_pr_4_export                (host_pr[4]),                  // reg_file_in_4.export
         .reg_file_host_pr_5_export                (host_pr[5]),                  // reg_file_in_5.export
         .reg_file_host_pr_6_export                (host_pr[6]),                  // reg_file_in_6.export
         .reg_file_host_pr_7_export                (host_pr[7]),                  // reg_file_in_7.export
         
         // PR System -> Host registers
         .reg_file_pr_host_0_export                (pr_host[0]),                  // reg_file_out_0.export
         .reg_file_pr_host_1_export                (pr_host[1]),                  // reg_file_out_1.export
         .reg_file_pr_host_2_export                (pr_host[2]),                  // reg_file_out_2.export
         .reg_file_pr_host_3_export                (pr_host[3]),                  // reg_file_out_3.export
         .reg_file_pr_host_4_export                (pr_host[4]),                  // reg_file_out_4.export
         .reg_file_pr_host_5_export                (pr_host[5]),                  // reg_file_out_5.export
         .reg_file_pr_host_6_export                (pr_host[6]),                  // reg_file_out_6.export
         .reg_file_pr_host_7_export                (pr_host[7])                   // reg_file_out_7.export
   
);
endmodule
