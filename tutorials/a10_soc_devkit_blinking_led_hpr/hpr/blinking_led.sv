// Copyright (c) 2001-2017 Intel Corporation
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
// a simple design to get LEDs blink using a 32-bit counter
///////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps
`default_nettype none

module blinking_led (

    // Control signals for the LEDs
    led_three_on,

    // clock 
    clock
);

    // assuming single bit control signal to turn LED 'on'
    output  wire    led_three_on;

    // clock 
    input   wire    clock;

    // the 32-bit counter
    reg      [31:0] count;

    localparam COUNTER_TAP = 23;

    // The counter:
    always_ff @(posedge clock)
    begin
        count <= count + 1;
    end

   assign  led_three_on  = count[COUNTER_TAP];

endmodule
