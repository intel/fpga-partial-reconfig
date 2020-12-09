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

///////////////////////////////////////////////////////////
// blinking_led.v
// a persona to drive LEDs ON
///////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps
`default_nettype none

module adder_grid_2d (

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

   localparam ADDER_HEIGHT = 75;
   localparam ADDER_WIDTH = 20;   
   localparam ADDER_DEPTH = 75; // 100 does not fit, 90 does not fit on concentrated

   localparam LOOP_PIPE = 6;
   
   reg led_two_on_r;
   reg led_three_on_r;
   
   assign led_two_on   = led_two_on_r;
   assign led_three_on = led_three_on_r;
   
   always_ff @(posedge clock) begin
      led_three_on_r <= counter[COUNTER_TAP];
      led_two_on_r   <= counter[COUNTER_TAP];
   end



   
   reg [ADDER_WIDTH-1:0] adder_in1[ADDER_DEPTH-1:0]    /* synthesis preserve noprune */;
   reg [ADDER_WIDTH-1:0] adder_in1_a[ADDER_DEPTH-1:0]  /* synthesis preserve noprune */;
   
   reg [ADDER_WIDTH-1:0] adder_in2[ADDER_HEIGHT-1:0]   /* synthesis preserve noprune */;
   reg [ADDER_WIDTH-1:0] adder_in2_b[ADDER_HEIGHT-1:0] /* synthesis preserve noprune */;
   
   reg [ADDER_WIDTH-1:0] adder_in1_a_pipe[ADDER_DEPTH-1:0][ADDER_HEIGHT-1:0];
   reg [ADDER_WIDTH-1:0] adder_in2_b_pipe[ADDER_DEPTH-1:0][ADDER_HEIGHT-1:0];     
   reg [ADDER_WIDTH:0] 	 adder_pipe[ADDER_DEPTH-1:0][ADDER_HEIGHT-1:0];

   reg [ADDER_WIDTH-1:0] adder_in1_a_out[ADDER_DEPTH-1:0]  /* synthesis preserve noprune */;
   reg [ADDER_WIDTH-1:0] adder_in2_b_out[ADDER_HEIGHT-1:0] /* synthesis preserve noprune */;
   reg [ADDER_WIDTH:0] 	 adder_out[ADDER_HEIGHT-1:0]       /* synthesis preserve noprune */;
   
   genvar 		 i,j,k;
   generate
      for (i=0; i<ADDER_DEPTH; i=i+1)  begin : adder_chain
	 for (j=0; j<ADDER_HEIGHT; j=j+1)  begin : adder_tile
	    if (i == 0)
	      if (j == 0)
		always_ff @(posedge fast_clock)
		  begin
		     adder_pipe[i][j]       <= (adder_in1[i] & adder_in1_a[i]) + (adder_in2[j] & adder_in2_b[j]);
		     adder_in1_a_pipe[i][j] <= adder_in1_a[i]; // [0][0]
		     adder_in2_b_pipe[i][j] <= adder_in2_b[j]; // [0][0]
		  end
	      else // i == 0, j != 0
		always_ff @(posedge fast_clock)
		  begin
		     adder_pipe[i][j]       <= (adder_pipe[i][j-1] & adder_in1_a_pipe[i][j-1]) + (adder_in2[j] & adder_in2_b[j]);
		     adder_in2_b_pipe[i][j] <= adder_in2_b[j]; // [0][j>0]
		  end
	    else // i != 0
	      if (j == 0) // i != 0, j == 0
		always_ff @(posedge fast_clock)
		  begin
		     adder_pipe[i][j]       <= (adder_in1[i] & adder_in1_a[i]) + (adder_pipe[i-1][j] & adder_in2_b_pipe[i-1][j]);
		     adder_in1_a_pipe[i][j] <= adder_in1_a[i]; // [i>0][0]
		  end
	      else // i != 0, j != 0
		always_ff @(posedge fast_clock)
		  begin
		     adder_pipe[i][j] <= (adder_pipe[i][j-1] & adder_in1_a_pipe[i][j-1]) + (adder_pipe[i-1][j] & adder_in2_b_pipe[i-1][j]);
		     adder_in1_a_pipe[i][j] <= adder_in1_a_pipe[i][j-1]; // [i>0][j>0]
		     adder_in2_b_pipe[i][j] <= adder_in2_b_pipe[i-1][j]; // [i>0][j>0]
		  end
         end // block: adder_tile
      end
   endgenerate

   // This is forcing the use of some long wires
   reg [ADDER_WIDTH-1:0] adder_out_SR[ADDER_HEIGHT-1:0][LOOP_PIPE-1:0];
   generate
      for (j=0; j<ADDER_HEIGHT; j=j+1) begin : adder_output_loop
	 for (k=0; k<LOOP_PIPE; k=k+1) begin : loop_pipe
	    if (k == 0)
	      always_ff @(posedge fast_clock)
		adder_out_SR[j][k] <= adder_out[j];
	    else
	      always_ff @(posedge fast_clock)
		adder_out_SR[j][k] <= adder_out_SR[j][k-1];
   	 end
      end
   endgenerate

   generate 
      for (i=0; i<ADDER_DEPTH; i=i+1) begin : adder1_recycle
	 always_ff @(posedge fast_clock)
	   begin
	      adder_in1[i]       <= ~adder_in1_a[i];
	      adder_in1_a[i]     <= ~adder_in1[i];
	      adder_in1_a_out[i] <= adder_in1_a_pipe[i][ADDER_HEIGHT-1];
	   end
      end
   endgenerate
   
   generate
      for (j=0; j<ADDER_HEIGHT; j=j+1)  begin : adder_output
	 always_ff @(posedge fast_clock)
	   begin
	      adder_in2[j]       <= ~adder_in2_b[j];
	      adder_in2_b[j]     <= adder_out_SR[j][LOOP_PIPE-1] ^ adder_in2[j];
	      adder_out[j]       <= adder_pipe[ADDER_DEPTH-1][j];
	      adder_in2_b_out[j] <= adder_in2_b_pipe[ADDER_DEPTH-1][j];	      
	   end
      end
   endgenerate
   
endmodule // adder_grid_2d
