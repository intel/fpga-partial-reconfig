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
module counter
	#(	parameter OUTPUT_WIDTH = 2) (
	input wire clk,
	input wire rst_n,
	input wire a,
	input wire b,
	output wire [OUTPUT_WIDTH-1:0] result
);
// Counter Parameters
parameter COUNTER_WIDTH = 2;

// Variable Declaration
//(* noprune *) reg [COUNTER_WIDTH-1:0] counter = 0;
reg [COUNTER_WIDTH-1:0] counter = 0;

// Output Assignment
assign result = counter[COUNTER_WIDTH-1:COUNTER_WIDTH-2];

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin	
		// Need to have in order reset into known state post PR Reset
		counter <= 0;
	end
	else begin
		counter <= counter + 1'b1;		
	end
end

endmodule