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
// Basic Arithmetic
// 
// This module conducts the arithmetic operation on the pr_operand and
// increment operand it receives and produces the result.

module basic_arithmetic 
   (
      input wire        pr_region_clk, 
      output reg [31:0] result,
      input wire [31:0] pr_operand,
      input wire [31:0] increment,
      input wire        pr_logic_rst   
   );
    always_ff @(posedge pr_region_clk) begin
        if ( pr_logic_rst ) begin
            result <= 'b0;
        end
        else begin
            result <= pr_operand + increment;
        end
    end
endmodule
