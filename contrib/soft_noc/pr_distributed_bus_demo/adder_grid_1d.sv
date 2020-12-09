// Copyright (c) Intel Corporation
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

///////////////////////////////////////////////////////////
// blinking_led.v
// a persona to drive LEDs ON
///////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps
`default_nettype none

module adder_grid_1d (

   // clock
   input wire clock,
   input wire fast_clock,
   input wire [31:0] counter,

   input wire dummy_in,
   output wire dummy_out,

   // Control signals for the LEDs
   output wire led_two_on,
   output wire led_three_on

);
   localparam COUNTER_TAP = 23;

   localparam ADDER_COUNT = 100;
   localparam ADDER_WIDTH = 20;   
   localparam ADDER_DEPTH = 80;
   
   reg led_two_on_r;
   reg led_three_on_r;
   
   assign led_two_on   = led_two_on_r;
   assign led_three_on = led_three_on_r;
   
   always_ff @(posedge clock) begin
      led_three_on_r <= counter[COUNTER_TAP];
      led_two_on_r   <= counter[COUNTER_TAP];
   end

   
   reg [ADDER_WIDTH-1:0] adder_in1[ADDER_COUNT-1:0] /* synthesis preserve noprune */;
   reg [ADDER_WIDTH-1:0] adder_in2[ADDER_COUNT-1:0] /* synthesis preserve noprune */;   

   reg [ADDER_WIDTH:0]   adder_pipe[ADDER_DEPTH-1:0][ADDER_COUNT-1:0]     /* synthesis preserve noprune */;
   reg [ADDER_WIDTH-1:0] adder_in2_pipe[ADDER_DEPTH-1:0][ADDER_COUNT-1:0] /* synthesis preserve noprune */;
   
   genvar i,j;
   generate
      for (i=0; i<ADDER_DEPTH; i=i+1)  begin : adder_chain
	 for (j=0; j<ADDER_COUNT; j=j+1)  begin : adder_tile
	    if (i == 0)
	      begin
		 if (j == 0)
		   always_ff @(posedge fast_clock) // add previous and pipelined adder_in2
		     adder_pipe[i][j]     <= adder_in1[i] + adder_in2[j];
		 else
		   always_ff @(posedge fast_clock) // carry-in from [i][j-1]
		     adder_pipe[i][j]     <= adder_in1[i] + adder_in2[j] + adder_pipe[i][j-1][ADDER_WIDTH];
                 always_ff @(posedge fast_clock)   // pipeline of adder_in2
                   adder_in2_pipe[i][j]   <= adder_in2[j];
              end
	    else
	      begin
		 if (j == 0)
		   always_ff @(posedge fast_clock) // add previous and pipelined adder_in2
		     adder_pipe[i][j]     <= adder_pipe[i-1][j] + adder_in2_pipe[i-1][j];
		 else
		   always_ff @(posedge fast_clock) // carry-in from [i][j-1]
		     adder_pipe[i][j]     <= adder_pipe[i-1][j] + adder_in2_pipe[i-1][j] + adder_pipe[i][j-1][ADDER_WIDTH];
                 always_ff @(posedge fast_clock)   // pipeline of adder_in2
		    adder_in2_pipe[i][j] <= adder_in2_pipe[i-1][j];
              end
         end
      end
   endgenerate   
   
endmodule // adder_grid_1d
