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

///////////////////////////////////////////////////////////
// blinking_led_empty.v
// a persona to drive LEDs ON
///////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps
`default_nettype none

module blinking_led_empty
    (

     // Control signals for the LEDs
     led_two_on,
     led_three_on,

     // clock
     clock
     );

    // Control signal to turn LED 'on'
    output  wire    led_two_on;
    output  wire    led_three_on;

    // clock
    input   wire    clock;

    // LED is active low
    assign  led_two_on    = 1'b0;
    assign  led_three_on  = 1'b0;

endmodule
