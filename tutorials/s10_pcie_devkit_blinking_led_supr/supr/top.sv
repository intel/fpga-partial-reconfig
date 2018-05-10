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

////////////////////////////////////////////////////////////////////////////
// top.v
// a simple design to get LEDs blink using a 32-bit counter
//
//
// As the accompanied application note document explains, the commented lines
// would be needed as the design implementation migrates from flat to
// Partial-Reconfiguration (PR) mode
////////////////////////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps
`default_nettype none

module top (

   ////////////////////////////////////////////////////////////////////////
   // clock
   ////////////////////////////////////////////////////////////////////////
   input wire clock,
   ////////////////////////////////////////////////////////////////////////
   // Control signals for the LEDs
   ////////////////////////////////////////////////////////////////////////
   output reg led_zero_on,
   output reg led_one_on,
   output reg led_two_on,
   output reg led_three_on

);
   localparam COUNTER_TAP = 23;
   ////////////////////////////////////////////////////////////////////////
   // When moving from flat design to PR the following lines need to be 
   // uncommented and commented respectively, the parameter ENABLE_PR
   // controls the generation of necessary logic/modules to support PR
   //
   ////////////////////////////////////////////////////////////////////////

   ////////////////////////////////////////////////////////////////////////
   // the 32-bit counters
   ////////////////////////////////////////////////////////////////////////
   reg [31:0] count_d;
   ////////////////////////////////////////////////////////////////////////
   // wire declarations
   ////////////////////////////////////////////////////////////////////////

   wire [31:0] count_u;
   
   wire pr_led_two_on;
   wire pr_led_three_on;

   wire led_zero_on_w;
   wire led_one_on_w;
   wire led_two_on_w;
   wire led_three_on_w;

  
   ////////////////////////////////////////////////////////////////////////
   // Register the LED outputs and SUPR PR communication signals
   ////////////////////////////////////////////////////////////////////////
   always_ff @(posedge clock) begin
      led_zero_on <= led_zero_on_w;
      led_one_on <= led_one_on_w;
      led_two_on <= led_two_on_w;
      led_three_on <= led_three_on_w;
      count_d <= count_u;
   end

   //Static Region Driven LED
   assign  led_zero_on_w   = count_d[COUNTER_TAP];

   assign led_two_on_w    = pr_led_two_on;
   assign led_three_on_w  = pr_led_three_on;

   ////////////////////////////////////////////////////////////////////////
   // instance of the default counter
   ////////////////////////////////////////////////////////////////////////

   top_counter u_top_counter
   (
      .clock         (clock),
      .count         (count_u),
      .led_one_on    (led_one_on_w)
   );
   ////////////////////////////////////////////////////////////////////////
   // instance of the default persona
   ////////////////////////////////////////////////////////////////////////
   blinking_led u_blinking_led
   (
      .clock         (clock),
      .counter       (count_d),
      .led_two_on    (pr_led_two_on),
      .led_three_on  (pr_led_three_on)

   );

endmodule
