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

// This is a Linear Feedback Shift Register that generates 32-bit pseudo-random data

module lfsr (
      input  wire         pr_logic_clk_clk,                 //       pr_logic_clk.clk
      input  wire         sw_reset,
      input  wire         load_seed,
      input  wire [31:0]  seed,
      output reg  [31:0]  rndm_data,
      input  wire         pr_logic_reset_reset_n            //     pr_logic_reset.reset_n
   );

   reg [31:0] data;

   // Ref equation from
   // http://courses.cse.tamu.edu/csce680/walker/lfsr_table.pdf
   always_comb
   begin
      data[31]    = rndm_data[0];
      data[30]    = rndm_data[31];
      data[29]    = ~(rndm_data[30] ^ rndm_data[0]);
      data[28:26] = rndm_data[29:27];
      data[25]    = ~(rndm_data[26] ^ rndm_data[0]);
      data[24]    = ~(rndm_data[25] ^ rndm_data[0]);
      data[23:0]  = rndm_data[24:1];
   end

   always_ff @(posedge pr_logic_clk_clk or negedge pr_logic_reset_reset_n) begin

      // Active low HW reset
      if (  pr_logic_reset_reset_n == 1'b0 ) begin

         rndm_data <= 'b0;

      end
      // Active high SW reset
      else if ( sw_reset == 1'b1 ) begin

         rndm_data <= 'b0;

      end
      else begin

         if ( load_seed == 1'b1 )
            rndm_data <= seed;
         else begin
            rndm_data <= data;
         end

      end
   end

endmodule
