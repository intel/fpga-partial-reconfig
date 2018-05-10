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

// This module is used to count number of PASS asserted by ddr_wr_rd module

module perf_cntr 
(
   input wire        pr_region_clk, 
   input wire        clr_io_reg,
   input wire        pass,
   output reg [31:0] performance_cntr,
   input wire        pr_logic_rst            
);


   always_ff @(posedge pr_region_clk or posedge pr_logic_rst) begin

      if ( pr_logic_rst == 1'b1  ) 
      begin
         performance_cntr <= 'b0;
      end
      else begin
         if ( clr_io_reg == 1'b1 ) begin
            performance_cntr <= 'b0;
         end
         else begin
            if ( pass == 1'b1 ) begin
               performance_cntr <= performance_cntr + 1;
            end
         end
      end
   end

endmodule
