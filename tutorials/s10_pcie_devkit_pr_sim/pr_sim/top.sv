// Copyright (c) 2001-2024 Intel Corporation
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

`timescale 1ns/1ps
module top 
	#(	parameter OUTPUT_WIDTH = 2) (
	input logic clk,
	input logic rst_n,
	input logic a,
	input logic b,
	output logic [OUTPUT_WIDTH-1:0] result
);
	
	pr_wrapper #(
		.OUTPUT_WIDTH(OUTPUT_WIDTH)) 
	
		u_pr_wrapper (
			.clk(clk),
			.rst_n(rst_n),
			.a(a),
			.b(b),
			.result(result)
	);
	

endmodule
