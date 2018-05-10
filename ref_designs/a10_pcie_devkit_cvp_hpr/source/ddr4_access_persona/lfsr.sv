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

// This is a Linear Feedback Shift Register that generates 32-bit pseudo-random data

module lfsr 
   (
      input wire         clk,
      input wire         rst,
      input wire         load_seed,
      input wire  [31:0] seed,
      output wire [31:0] out
   );

   reg [31:0] myreg;

   // nice looking max period polys selected from
   // the internet
   reg [31:0] poly;
   wire [31:0] feedback;
   assign feedback = {32{myreg[31]}} & poly;

   // the inverter on the LSB causes 000... to be a 
   // sequence member rather than the frozen state
   always_ff @(posedge clk or posedge rst) begin
      if ( rst==1'b1 ) begin
         poly <= 32'h800007c3; 
         myreg <= 0;
      end
      else begin
         if(load_seed == 1'b1) begin
            poly <= seed;
         end
         myreg <= ((myreg ^ feedback) << 1) | !myreg[31];
      end
   end

   assign out = myreg;

endmodule

