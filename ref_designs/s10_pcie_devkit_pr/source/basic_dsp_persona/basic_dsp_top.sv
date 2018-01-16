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

module basic_dsp_top #(parameter REG_FILE_IO_SIZE = 8) 
   (
      //clock
      input wire          clk ,
      input wire          pr_logic_rst ,
      output reg          clr_io_reg ,

      //Persona identification register, used by host in host program
      output wire [31:0]  persona_id ,

      //Host control register, used for control signals.
      input wire [31:0]   host_cntrl_register ,

      // 8 registers for host -> PR logic communication
      input wire [31:0]   host_pr [0:REG_FILE_IO_SIZE-1] ,

      // 8 Registers for PR logic -> host communication
      output wire [31:0]  pr_host [0:REG_FILE_IO_SIZE-1] ,

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


   //Software defined reset, uses logic as these are logic
   reg                  clr_io_reg_q;

   //Registers used as they are just buffers
   reg [26:0]           dsp_inputs[0:1];
   (* multstyle = "dsp" *)  wire [53:0]           dsp_output;
   // wire [53:0] result /* synthesis multstyle = "dsp" */;
   assign dsp_output[53:0] =  host_pr[0][26:0]*host_pr[1][26:0]; //Multiplication must be directly assigned to result
   always_comb
   begin
      emif_avmm_burstcount  = 5'b0;
      emif_avmm_writedata   = 128'b0;
      emif_avmm_address     = 31'b0;
      emif_avmm_write       = 1'b0;
      emif_avmm_read        = 1'b0;
      emif_avmm_byteenable  = 16'b0;
   end

   // assign PR Id register to be the value we chose to uniquely identify our program when the host requests
   // Read-Only
   assign persona_id = 32'h0000_aeed;
   
   //54 bit output, uses two output registers
   assign pr_host[0] = dsp_output[31:0];
   assign pr_host[1] = {10'b0, dsp_output[53:32]};
   
   generate
      genvar i;
      //Tieing unusued ouput ports to zero.
      for (i = 2; i < REG_FILE_IO_SIZE; i = i + 1) begin
         assign pr_host [i] = 32'b0;
      end
   endgenerate
   
   //Register map
   //In order to reset these registers without through the host side program
   //setting host_cntrl_register[0] to 1 will cause all communication registers
   //(pr->host and host->pr) to reset. Note that host_cntrl_register[0] only resets
   //on the transition from 0->1, not just on the register value. 

   always_ff @( posedge clk or posedge pr_logic_rst )  begin
      if( pr_logic_rst) begin
         clr_io_reg <= 1'b0;
         clr_io_reg_q <= 1'b0;
      end
      else begin
         clr_io_reg_q <= host_cntrl_register[0];//Use bit zero in the host control register as a reset.
         clr_io_reg <= (~clr_io_reg_q & host_cntrl_register[0]);//Generate a active high pulse for a local reset
      end
   end
endmodule

