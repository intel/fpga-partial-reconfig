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

//This is a example of using the provided template of a
//Avalon MM interface controlled over PCIe register file
//To inetrface with a design.
module pr_example_logic_unsigned_mult_dsp #(
      parameter REG_FILE_IO_SIZE = 8
   )(
   //clock
   input wire clk,                      
   
   //active low reset, defined by hardware
   input wire rst_n,         
   output wire sw_rst_n,                

   //Persona identification register, used by host in host program
   output wire [31:0] persona_id,                     

   //Host control register, used for control signals.
   input wire [31:0] host_cntrl_register,   

   // 8 registers for host -> PR logic communication
   input wire [31:0] host_pr [0:REG_FILE_IO_SIZE-1],

   // 8 Registers for PR logic -> host communication
   output wire [31:0] pr_host [0:REG_FILE_IO_SIZE-1]
   );

   //Software defined reset, uses logic as these are logic
   logic local_reset;
   logic local_reset_q;

   //Registers used as they are just buffers
   reg [26:0] dsp_inputs [0:1];
   wire [53:0] dsp_output;



   // assign PR Id register to be the value we chose to uniquely identify our program when the host requests
   // Read-Only
   assign persona_id  = 32'h0000_aeed;
   //54 bit output, uses two output registers
   assign pr_host[0] = dsp_output[31:0];
   assign pr_host[1] = {10'b0, dsp_output[53:32]};
   assign sw_rst_n = ~local_reset_q;
   generate 
      genvar i;
   //Tieing unusued ouput ports to zero.
      for (i = 2; i < REG_FILE_IO_SIZE; i = i + 1) begin

         assign pr_host [i] = 32'b0;

      end
   endgenerate

   //Software defined reset
   always_ff @( posedge clk or negedge rst_n )  begin
      if( rst_n == 1'b0 ) begin
         
         local_reset <= 1'b0;
         local_reset_q <= 1'b0;
      
      end
      else begin

         local_reset <= host_cntrl_register[0];//Use bit zero in the host control register as a reset.
         local_reset_q <= (~local_reset & host_cntrl_register[0]);//Generate a active high pulse for a local reset

      end
   end

   //Register map
    always_ff @( posedge clk or negedge rst_n )  
    begin
      if ( rst_n == 1'b0 ) begin

         dsp_inputs[0] <= 27'b0;
         dsp_inputs[1] <= 27'b0;

      end
      else if ( local_reset_q == 1'b1 ) begin

         dsp_inputs[0] <= 27'b0;
         dsp_inputs[1] <= 27'b0;

      end
      else begin
         //Save the inputs to the registers we want
         dsp_inputs[0] <= host_pr[0];
         dsp_inputs[1] <= host_pr[1];

      end
   end


     logic_example_dsp_unsigned_27x27_atom u_logic_example_dsp_unsigned_27x27_atom(
            .aclr({local_reset_q, local_reset_q}),
            .ax(dsp_inputs[0][26:0]),
            .ay(dsp_inputs[1][26:0]),
            .clk(clk),
            .ena(3'b111),
            .resulta(dsp_output)
            );
endmodule

