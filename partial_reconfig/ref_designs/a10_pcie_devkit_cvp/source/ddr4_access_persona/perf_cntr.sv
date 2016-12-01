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

// This module is used to count number of PASS asserted by ddr_wr_rd module

module perf_cntr (
      input  wire         pr_logic_clk_clk,                 //       pr_logic_clk.clk
      input  wire         sw_reset,
      input  wire         pass,
      output reg [31:0]   performance_cntr,
      input  wire         pr_logic_reset_reset_n            //     pr_logic_reset.reset_n
   );


   always_ff @(posedge pr_logic_clk_clk or negedge pr_logic_reset_reset_n) begin

      // Active low HW reset
      if (  pr_logic_reset_reset_n == 1'b0 ) begin

         performance_cntr <= 'b0;

      end
      // Active high SW reset
      else if (  sw_reset == 1'b1 ) begin

         performance_cntr <= 'b0;

      end
      else begin

         if ( pass == 1'b1 ) begin

            performance_cntr <= performance_cntr + 1;
            
         end

      end
   end

endmodule
