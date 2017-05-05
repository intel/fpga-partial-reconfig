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

////////////////////////////////////////////////////////////////////////////
// top.v
// a simple design to get LEDs blink using a 32-bit counter
//
// Some of the lines of code are commented out. They are not
// needed since this is the flat implementation of the design
//
// As the accompanied application note document explains, the commented lines
// would be needed as the design implementation migrates from flat to
// Partial-Reconfiguration (PR) mode
////////////////////////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps
`default_nettype none

module top
    (

     ////////////////////////////////////////////////////////////////////////
     // Control signals for the LEDs
     ////////////////////////////////////////////////////////////////////////
     led_zero_on,
     led_one_on,
     led_two_on,
     led_three_on,

     ////////////////////////////////////////////////////////////////////////
     // clock
     ////////////////////////////////////////////////////////////////////////
     clock
     );

    ////////////////////////////////////////////////////////////////////////
    // assuming single bit control signal to turn LED 'on'
    ////////////////////////////////////////////////////////////////////////
    output  reg   led_zero_on;
    output  reg   led_one_on;
    output  reg   led_two_on;
    output  reg   led_three_on;

    ////////////////////////////////////////////////////////////////////////
    // clock
    ////////////////////////////////////////////////////////////////////////
    input   wire  clock;

    localparam COUNTER_TAP = 24;

    ////////////////////////////////////////////////////////////////////////
    // the 32-bit counter
    ////////////////////////////////////////////////////////////////////////
    reg [31:0]    count;

    ////////////////////////////////////////////////////////////////////////
    // wire declarations
    ////////////////////////////////////////////////////////////////////////
    wire          freeze;          // freeze is not used until design is changed to PR
    wire [2:0]    pr_ip_status;
    wire          pr_led_two_on;
    wire          pr_led_three_on;

    wire          led_zero_on_w;
    wire          led_one_on_w;
    wire          led_two_on_w;
    wire          led_three_on_w;

    ////////////////////////////////////////////////////////////////////////
    // The counter:
    ////////////////////////////////////////////////////////////////////////
    always_ff @(posedge clock)
    begin
        count <= count + 1;
    end
    
    ////////////////////////////////////////////////////////////////////////
    // Register the LED outputs
    ////////////////////////////////////////////////////////////////////////
    always_ff @(posedge clock)
    begin
        led_zero_on <= led_zero_on_w;
        led_one_on <= led_one_on_w;
        led_two_on <= led_two_on_w;
        led_three_on <= led_three_on_w;
    end

    ////////////////////////////////////////////////////////////////////////
    // driving LEDs to show PR as the rest of logic is running
    ////////////////////////////////////////////////////////////////////////
    assign  led_zero_on_w   = count[COUNTER_TAP];
    assign  led_one_on_w    = count[COUNTER_TAP];

    ////////////////////////////////////////////////////////////////////////
    // When moving from flat design to PR the following two
    // lines of assign statements need to be used.  
    // User needs to uncomment them.
    //
    // The output ports driven by PR logic need to stablized
    // during PR reprograming.  Using "freeze" control signal,
    // from PR IP, to drive these output to logic 1 during
    // reconfiguration. The logic 1 is chosen because LED is active low.
    ////////////////////////////////////////////////////////////////////////
    // The following line is used in PR implementation
    assign led_two_on_w    = freeze ? 1'b1 : pr_led_two_on;
    
    // The following line is used in PR implementation
    assign led_three_on_w  = freeze ? 1'b1 : pr_led_three_on;

    ////////////////////////////////////////////////////////////////////////
    // instance of the default persona
    ////////////////////////////////////////////////////////////////////////
    blinking_led u_blinking_led
        (
         //      .led_two_on    (led_two_on),       // used in flat implementation
         .led_two_on    (pr_led_two_on),    // used in PR implementation

         //      .led_three_on  (led_three_on),     // used in flat implementation
         .led_three_on  (pr_led_three_on),  // used in PR implementation

         .clock         (clock)
         );

    ////////////////////////////////////////////////////////////////////////
            // when moving from flat design to PR then the following
    // pr_ip needs to be instantiated in order to be able to
    // partially reconfigure the design.
    // 
    // This tutorial implements PR over JTAG
    ////////////////////////////////////////////////////////////////////////
    pr_ip u_pr_ip
        (
         .clk           (clock),
         .nreset        (1'b1),
         .freeze        (freeze),
         .pr_start      (1'b0),            // ignored for JTAG
         .status        (pr_ip_status),
         .data          (16'b0),
         .data_valid    (1'b0),
         .data_ready    ()
         );

endmodule
