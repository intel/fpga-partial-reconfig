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

module blinking_led (

   // clock
   input wire clock,
   input wire [31:0] counter,

	//===================
	// Uncomment this block to enable Signal Tap
	// input wire tck,
	// input wire tms,
	// input wire tdi,
	// input wire vir_tdi,
	// input wire ena,
	// output wire tdo,
	//===================
	
   // Control signals for the LEDs
   output wire led_two_on,
   output wire led_three_on

);
   localparam COUNTER_TAP = 23;
   reg led_two_on_r;
   reg led_three_on_r;
	
	//==================
	//Uncomment this block to enable Signal Tap
 //    sld_host u_sld_hostled_two_on (
	// 	.tck	(tck),	//   input,  width = 1, connect_to_bridge_host.tck
	// 	.tms	(tms),	//   input,  width = 1,                       .tms
	// 	.tdi	(tdi),	//   input,  width = 1,                       .tdi
	// 	.vir_tdi(vir_tdi),//   input,  width = 1,                    .vir_tdi
	// 	.ena	(ena),	//   input,  width = 1,                       .ena
	// 	.tdo	(tdo)	//  output,  width = 1,                       .tdo
	// );
	//==================

   assign led_two_on   = led_two_on_r;
   assign led_three_on = led_three_on_r;
   
   always_ff @(posedge clock) begin
      led_three_on_r <= counter[COUNTER_TAP];
      led_two_on_r   <= counter[COUNTER_TAP];
   end

endmodule
