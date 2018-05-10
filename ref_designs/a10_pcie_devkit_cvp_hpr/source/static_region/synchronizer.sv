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

// Synchronize one signal originated from a different
// clock domain to the current clock domain.

module synchronizer #( parameter WIDTH = 1, parameter STAGES = 5 )
   (
      input wire             clk_in,arstn_in,
      input wire             clk_out,arstn_out,

      input wire [WIDTH-1:0] dat_in,
      output reg [WIDTH-1:0] dat_out  
   );

   // launch register
   reg [WIDTH-1:0]         d /* synthesis preserve */;
   always @(posedge clk_in or negedge arstn_in) begin
      if (!arstn_in) d <= 0;
      else d <= dat_in;
   end

   // capture registers
   reg [STAGES*WIDTH-1:0] c /* synthesis preserve */;
   always @(posedge clk_out or negedge arstn_out) begin
      if (!arstn_out) c <= 0;
      else c <= {c[(STAGES-1)*WIDTH-1:0],d};
   end

   assign dat_out = c[STAGES*WIDTH-1:(STAGES-1)*WIDTH];

endmodule
