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
module fsm
	#(	parameter OUTPUT_WIDTH = 2) (
	input wire clk,
	input wire rst_n,
	input wire a,
	input wire b,
	output wire [OUTPUT_WIDTH-1:0] result
);

// FSM State Parameters
localparam STATE_LENGTH = 2;
localparam TOGGLE_STATE = 0;
localparam A_BLINK_STATE = 1;
localparam B_BLINK_STATE = 2;
localparam BLINK_STATE = 3;

// Variable Declaration
logic [STATE_LENGTH-1:0] state = 2'b00;
logic toggle = 1'b0;
reg [OUTPUT_WIDTH-1:0] r_result = {OUTPUT_WIDTH{1'b0}};

// Output Assignment
assign result = r_result;

always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		// Need to have in order reset into known state post PR Reset
		state <= {STATE_LENGTH{1'b0}};
		r_result <= {OUTPUT_WIDTH{1'b0}};
		toggle <= 1'b0;
	end
	else begin
		case(state) 
			TOGGLE_STATE: begin
					r_result <= {toggle, ~toggle}; // Toggle between A & B
				end
			A_BLINK_STATE: begin
					r_result <= {1'b0, toggle}; // Toggle A
				end
			B_BLINK_STATE: begin
					r_result <= {toggle,1'b0}; // Toggle B
				end
			BLINK_STATE: begin
				r_result <= {toggle, toggle}; // Toggle A & B together
			end
		endcase
		
		toggle <= ~toggle;
		state <= {b,a};
	end
end

endmodule