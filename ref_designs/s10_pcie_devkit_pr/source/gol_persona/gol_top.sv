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

module gol_top #(parameter REG_FILE_IO_SIZE = 8) 
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
   input wire [127:0]  emif_avmm_readdata , 
   input wire          emif_avmm_readdatavalid ,
   output reg [6:0]    emif_avmm_burstcount , 
   output reg [127:0]  emif_avmm_writedata , 
   output reg [24:0]   emif_avmm_address , 
   output reg          emif_avmm_write , 
   output reg          emif_avmm_read , 
   output reg [15:0]   emif_avmm_byteenable       
);

   always_comb
   begin
      emif_avmm_burstcount  = 5'b0;
      emif_avmm_writedata   = 128'b0;
      emif_avmm_address     = 31'b0;
      emif_avmm_write       = 1'b0;
      emif_avmm_read        = 1'b0;
      emif_avmm_byteenable  = 16'b0;
   end
   moderator wrapper
   (
      .clk                 ( clk ),             
      .pr_logic_rst        ( pr_logic_rst ),
      .clr_io_reg          ( clr_io_reg ),
      .persona_id          ( persona_id ), 
      .host_cntrl_register ( host_cntrl_register ), 
      .host_pr             ( host_pr ),
      .pr_host             ( pr_host )
   );




endmodule
