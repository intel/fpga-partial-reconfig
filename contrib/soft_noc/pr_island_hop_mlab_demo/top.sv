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

module top(
	   ////////////////////////////////////////////////////////////////////////
	   // clock
	   ////////////////////////////////////////////////////////////////////////
	   clock,
	   fast_clock,
	   bus_clock,
	   ////////////////////////////////////////////////////////////////////////
	   // Control signals for the LEDs
	   ////////////////////////////////////////////////////////////////////////
	   led_zero_on,
	   led_one_on,
	   led_two_on,
	   led_three_on,

           dummy_in,
           dummy_out,

	   north_in,
	   south_in,
	   east_in,	   
	   west_in,
	   
	   north_out,
	   south_out,
	   east_out,	   
	   west_out);

   localparam SECTOR_COL = 40;
   localparam SECTOR_ROW = 41;
   localparam RULE_OF_ELEVEN = 11;
   localparam PRR_SECTOR_HEIGHT = 3;
   localparam PRR_SECTOR_WIDTH = 4;
   
   parameter  NORTH_SOUTH_PIPES = 6; 
   parameter  EAST_WEST_PIPES   = 6; 
       
   input      wire clock;
   input      wire fast_clock;
   input      wire bus_clock;

   output     reg led_zero_on;
   output     reg led_one_on;
   output     reg led_two_on;
   output     reg led_three_on;
   
   input      wire dummy_in;
   output     wire dummy_out;

   input      logic [RULE_OF_ELEVEN-1:0] north_in[PRR_SECTOR_WIDTH-1:0][SECTOR_COL-1:0];
   input      logic [RULE_OF_ELEVEN-1:0] south_in[PRR_SECTOR_WIDTH-1:0][SECTOR_COL-1:0];
   input      logic [RULE_OF_ELEVEN-1:0] east_in[PRR_SECTOR_HEIGHT-1:0][SECTOR_ROW-1:0];
   input      logic [RULE_OF_ELEVEN-1:0] west_in[PRR_SECTOR_HEIGHT-1:0][SECTOR_ROW-1:0];
   
   output     logic [RULE_OF_ELEVEN-1:0] north_out[PRR_SECTOR_WIDTH-1:0][SECTOR_COL-1:0];
   output     logic [RULE_OF_ELEVEN-1:0] south_out[PRR_SECTOR_WIDTH-1:0][SECTOR_COL-1:0];
   output     logic [RULE_OF_ELEVEN-1:0] east_out[PRR_SECTOR_HEIGHT-1:0][SECTOR_ROW-1:0];
   output     logic [RULE_OF_ELEVEN-1:0] west_out[PRR_SECTOR_HEIGHT-1:0][SECTOR_ROW-1:0];

   localparam 	  COUNTER_TAP = 23;
   ////////////////////////////////////////////////////////////////////////
   // When moving from flat design to PR the following lines need to be 
   // uncommented and commented respectively, the parameter ENABLE_PR
   // controls the generation of necessary logic/modules to support PR
   //
   ////////////////////////////////////////////////////////////////////////

   ////////////////////////////////////////////////////////////////////////
   // the 32-bit counters
   ////////////////////////////////////////////////////////////////////////
   reg      [31:0] count_d;
   ////////////////////////////////////////////////////////////////////////
   // wire declarations
   ////////////////////////////////////////////////////////////////////////

   wire     [31:0] count_u;
   
   wire            pr_led_two_on;
   wire            pr_led_three_on;

   wire            led_zero_on_w;
   wire            led_one_on_w;
   wire            led_two_on_w;
   wire            led_three_on_w;

  
   ////////////////////////////////////////////////////////////////////////
   // Register the LED outputs and SUPR PR communication signals
   ////////////////////////////////////////////////////////////////////////
   always_ff @(posedge clock)
   begin
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
      .fast_clock    (fast_clock),
      .counter       (count_d),
      .led_two_on    (pr_led_two_on),
      .led_three_on  (pr_led_three_on),
      .dummy_in      (dummy_in),
      .dummy_out     (dummy_out)
   );

   // Pipelined bus starts here...

   // The synthesis preserve here avoids these registers being retimed into hyperflex   
   logic [RULE_OF_ELEVEN-1:0]      north_in_reg[PRR_SECTOR_WIDTH-1:0][SECTOR_COL-1:0] /* synthesis preserve */; 
   logic [RULE_OF_ELEVEN-1:0]      south_in_reg[PRR_SECTOR_WIDTH-1:0][SECTOR_COL-1:0] /* synthesis preserve */; 
   logic [RULE_OF_ELEVEN-1:0]      east_in_reg[PRR_SECTOR_HEIGHT-1:0][SECTOR_ROW-1:0] /* synthesis preserve */; 
   logic [RULE_OF_ELEVEN-1:0]      west_in_reg[PRR_SECTOR_HEIGHT-1:0][SECTOR_ROW-1:0] /* synthesis preserve */; 

   // The synthesis preserve here avoids these registers being retimed into hyperflex
   logic [RULE_OF_ELEVEN-1:0]      north_out_reg[PRR_SECTOR_WIDTH-1:0][SECTOR_COL-1:0] /* synthesis preserve */;
   logic [RULE_OF_ELEVEN-1:0]      south_out_reg[PRR_SECTOR_WIDTH-1:0][SECTOR_COL-1:0] /* synthesis preserve */;
   logic [RULE_OF_ELEVEN-1:0]      east_out_reg[PRR_SECTOR_HEIGHT-1:0][SECTOR_ROW-1:0] /* synthesis preserve */;
   logic [RULE_OF_ELEVEN-1:0]      west_out_reg[PRR_SECTOR_HEIGHT-1:0][SECTOR_ROW-1:0] /* synthesis preserve */;

   // Separate the start/end out for logic locking
   genvar     i,j,k;
   generate
      for (i=0; i<PRR_SECTOR_WIDTH; i=i+1)  begin : north_south_io
	 for (j=0; j<SECTOR_COL; j=j+1)  begin : north_south_io_size
	    for (k=0; k<RULE_OF_ELEVEN; k=k+1)  begin : north_south_io_rule_of_eleven_size
	       always_ff @(posedge bus_clock)
		 begin
		    north_in_reg[i][j][k] <= north_in[i][j][k];
		    north_out[i][j][k]    <= north_out_reg[i][j][k];
		    south_in_reg[i][j][k] <= south_in[i][j][k];    
		    south_out[i][j][k]    <= south_out_reg[i][j][k];
		 end
            end
         end
      end
   endgenerate
   
   // Separate the start/end out for logic locking
   generate
      for (i=0; i<PRR_SECTOR_HEIGHT; i=i+1)  begin : east_west_io
	 for (j=0; j<SECTOR_ROW; j=j+1)  begin : east_west_io_size
	    if (j < SECTOR_ROW/2)
	      for (k=0; k<RULE_OF_ELEVEN; k=k+1)  begin : bot_east_west_io_rule_of_eleven_size
		 always_ff @(posedge bus_clock)
		   begin
		      east_in_reg[i][j][k] <= east_in[i][j][k];
		      east_out[i][j][k]    <= east_out_reg[i][j][k];
		      west_in_reg[i][j][k] <= west_in[i][j][k];
		      west_out[i][j][k]    <= west_out_reg[i][j][k];
		   end
              end
	    else
	      for (k=0; k<RULE_OF_ELEVEN; k=k+1)  begin : top_east_west_io_rule_of_eleven_size
		 always_ff @(posedge bus_clock)
		   begin
		      east_in_reg[i][j][k] <= east_in[i][j][k];
		      east_out[i][j][k]    <= east_out_reg[i][j][k];
		      west_in_reg[i][j][k] <= west_in[i][j][k];
		      west_out[i][j][k]    <= west_out_reg[i][j][k];
		   end
              end
         end
      end
   endgenerate
   


	parameter DATA_WIDTH=20;
	parameter ADDR_WIDTH=5;

	/* generated from I@X104_Y165@{E[2][40],E[2][39]}@4 */

	logic [DATA_WIDTH-1:0] X104_Y165_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_39_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][40][10:0], east_in_reg[2][39][10:2]}),
		.out(X104_Y165_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X104_Y165(.data(X104_Y165_bus_wdata),
		.q(/* to design */),
		.wraddress(X104_Y165_waddr),
		.rdaddress(/* from design */),
		.wren(X104_Y165_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X105_Y165@{E[2][40],E[2][39]}@4 */

	logic X105_Y165_incr_waddr; // ingress control
	logic X105_Y165_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_39_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][39][0]),
		.out(X105_Y165_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_39_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][39][1]),
		.out(X105_Y165_incr_raddr));

	logic [ADDR_WIDTH-1:0] X105_Y165_waddr;
	logic [ADDR_WIDTH-1:0] X105_Y165_raddr;

	/* positional aliases */

	wire X104_Y165_incr_waddr;
	assign X104_Y165_incr_waddr = X105_Y165_incr_waddr;
	wire [ADDR_WIDTH-1:0] X104_Y165_waddr;
	assign X104_Y165_waddr = X105_Y165_waddr;
	wire X104_Y164_incr_raddr;
	assign X104_Y164_incr_raddr = X105_Y165_incr_raddr;
	wire [ADDR_WIDTH-1:0] X104_Y164_raddr;
	assign X104_Y164_raddr = X105_Y165_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X105_Y165(.clk(bus_clock),
		.incr_waddr(X105_Y165_incr_waddr),
		.waddr(X105_Y165_waddr),
		.incr_raddr(X105_Y165_incr_raddr),
		.raddr(X105_Y165_raddr));


	/* generated from C@X205_Y165@{W[2][40],W[2][39]}@3 */

	logic X205_Y165_incr_waddr; // ingress control
	logic X205_Y165_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_2_west_to_east_ip_size_39_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][40][0]),
		.out(X205_Y165_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_2_west_to_east_ip_size_39_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][40][1]),
		.out(X205_Y165_incr_raddr));

	logic [ADDR_WIDTH-1:0] X205_Y165_waddr;
	logic [ADDR_WIDTH-1:0] X205_Y165_raddr;

	/* positional aliases */

	wire X206_Y165_incr_waddr;
	assign X206_Y165_incr_waddr = X205_Y165_incr_waddr;
	wire [ADDR_WIDTH-1:0] X206_Y165_waddr;
	assign X206_Y165_waddr = X205_Y165_waddr;
	wire X206_Y164_incr_raddr;
	assign X206_Y164_incr_raddr = X205_Y165_incr_raddr;
	wire [ADDR_WIDTH-1:0] X206_Y164_raddr;
	assign X206_Y164_raddr = X205_Y165_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X205_Y165(.clk(bus_clock),
		.incr_waddr(X205_Y165_incr_waddr),
		.waddr(X205_Y165_waddr),
		.incr_raddr(X205_Y165_incr_raddr),
		.raddr(X205_Y165_raddr));


	/* generated from I@X206_Y165@{W[2][40],W[2][39]}@4 */

	logic [DATA_WIDTH-1:0] X206_Y165_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_2_west_to_east_ip_size_39_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][40][10:0], west_in_reg[2][39][10:2]}),
		.out(X206_Y165_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X206_Y165(.data(X206_Y165_bus_wdata),
		.q(/* to design */),
		.wraddress(X206_Y165_waddr),
		.rdaddress(/* from design */),
		.wren(X206_Y165_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X104_Y164@{E[2][40],E[2][39]}@5 */

	logic [DATA_WIDTH-1:0] X104_Y164_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X104_Y164_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_39_bus_first_egress_fifo(.clock(bus_clock),
		.in(X104_Y164_bus_rdata_in),
		.out(X104_Y164_bus_rdata_out));

	assign west_out_reg[2][40][10:0] = X104_Y164_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][39][10:2] = X104_Y164_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X104_Y164(.data(/* from design */),
		.q(X104_Y164_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X104_Y164_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X206_Y164@{W[2][40],W[2][39]}@5 */

	logic [DATA_WIDTH-1:0] X206_Y164_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X206_Y164_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_39_bus_first_egress_fifo(.clock(bus_clock),
		.in(X206_Y164_bus_rdata_in),
		.out(X206_Y164_bus_rdata_out));

	assign east_out_reg[2][40][10:0] = X206_Y164_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][39][10:2] = X206_Y164_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X206_Y164(.data(/* from design */),
		.q(X206_Y164_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X206_Y164_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X103_Y163@{W[2][38],W[2][37]}@1 */

	logic X103_Y163_incr_waddr; // ingress control
	logic X103_Y163_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_37_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][37][0]),
		.out(X103_Y163_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_37_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][37][1]),
		.out(X103_Y163_incr_raddr));

	logic [ADDR_WIDTH-1:0] X103_Y163_waddr;
	logic [ADDR_WIDTH-1:0] X103_Y163_raddr;

	/* positional aliases */

	wire X104_Y163_incr_waddr;
	assign X104_Y163_incr_waddr = X103_Y163_incr_waddr;
	wire [ADDR_WIDTH-1:0] X104_Y163_waddr;
	assign X104_Y163_waddr = X103_Y163_waddr;
	wire X104_Y162_incr_raddr;
	assign X104_Y162_incr_raddr = X103_Y163_incr_raddr;
	wire [ADDR_WIDTH-1:0] X104_Y162_raddr;
	assign X104_Y162_raddr = X103_Y163_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X103_Y163(.clk(bus_clock),
		.incr_waddr(X103_Y163_incr_waddr),
		.waddr(X103_Y163_waddr),
		.incr_raddr(X103_Y163_incr_raddr),
		.raddr(X103_Y163_raddr));


	/* generated from I@X104_Y163@{W[2][38],W[2][37]}@1 */

	logic [DATA_WIDTH-1:0] X104_Y163_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_37_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][38][10:0], west_in_reg[2][37][10:2]}),
		.out(X104_Y163_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X104_Y163(.data(X104_Y163_bus_wdata),
		.q(/* to design */),
		.wraddress(X104_Y163_waddr),
		.rdaddress(/* from design */),
		.wren(X104_Y163_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from I@X206_Y163@{E[2][38],E[2][37]}@1 */

	logic [DATA_WIDTH-1:0] X206_Y163_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_37_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][38][10:0], east_in_reg[2][37][10:2]}),
		.out(X206_Y163_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X206_Y163(.data(X206_Y163_bus_wdata),
		.q(/* to design */),
		.wraddress(X206_Y163_waddr),
		.rdaddress(/* from design */),
		.wren(X206_Y163_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X207_Y163@{E[2][38],E[2][37]}@1 */

	logic X207_Y163_incr_waddr; // ingress control
	logic X207_Y163_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_37_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][38][0]),
		.out(X207_Y163_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_37_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][38][1]),
		.out(X207_Y163_incr_raddr));

	logic [ADDR_WIDTH-1:0] X207_Y163_waddr;
	logic [ADDR_WIDTH-1:0] X207_Y163_raddr;

	/* positional aliases */

	wire X206_Y163_incr_waddr;
	assign X206_Y163_incr_waddr = X207_Y163_incr_waddr;
	wire [ADDR_WIDTH-1:0] X206_Y163_waddr;
	assign X206_Y163_waddr = X207_Y163_waddr;
	wire X206_Y162_incr_raddr;
	assign X206_Y162_incr_raddr = X207_Y163_incr_raddr;
	wire [ADDR_WIDTH-1:0] X206_Y162_raddr;
	assign X206_Y162_raddr = X207_Y163_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X207_Y163(.clk(bus_clock),
		.incr_waddr(X207_Y163_incr_waddr),
		.waddr(X207_Y163_waddr),
		.incr_raddr(X207_Y163_incr_raddr),
		.raddr(X207_Y163_raddr));


	/* generated from E@X104_Y162@{W[2][38],W[2][37]}@2 */

	logic [DATA_WIDTH-1:0] X104_Y162_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X104_Y162_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_2_west_to_east_ip_size_37_bus_first_egress_fifo(.clock(bus_clock),
		.in(X104_Y162_bus_rdata_in),
		.out(X104_Y162_bus_rdata_out));

	assign east_out_reg[2][38][10:0] = X104_Y162_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][37][10:2] = X104_Y162_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X104_Y162(.data(/* from design */),
		.q(X104_Y162_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X104_Y162_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X206_Y162@{E[2][38],E[2][37]}@2 */

	logic [DATA_WIDTH-1:0] X206_Y162_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X206_Y162_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_37_bus_first_egress_fifo(.clock(bus_clock),
		.in(X206_Y162_bus_rdata_in),
		.out(X206_Y162_bus_rdata_out));

	assign west_out_reg[2][38][10:0] = X206_Y162_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][37][10:2] = X206_Y162_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X206_Y162(.data(/* from design */),
		.q(X206_Y162_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X206_Y162_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X153_Y161@{E[2][36],E[2][35]}@3 */

	logic [DATA_WIDTH-1:0] X153_Y161_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) east_to_west_sector_size_2_east_to_west_ip_size_35_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][36][10:0], east_in_reg[2][35][10:2]}),
		.out(X153_Y161_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X153_Y161(.data(X153_Y161_bus_wdata),
		.q(/* to design */),
		.wraddress(X153_Y161_waddr),
		.rdaddress(/* from design */),
		.wren(X153_Y161_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X154_Y161@{E[2][36],E[2][35]}@3 */

	logic X154_Y161_incr_waddr; // ingress control
	logic X154_Y161_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) east_to_west_sector_size_2_east_to_west_ip_size_35_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][35][0]),
		.out(X154_Y161_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) east_to_west_sector_size_2_east_to_west_ip_size_35_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][35][1]),
		.out(X154_Y161_incr_raddr));

	logic [ADDR_WIDTH-1:0] X154_Y161_waddr;
	logic [ADDR_WIDTH-1:0] X154_Y161_raddr;

	/* positional aliases */

	wire X153_Y161_incr_waddr;
	assign X153_Y161_incr_waddr = X154_Y161_incr_waddr;
	wire [ADDR_WIDTH-1:0] X153_Y161_waddr;
	assign X153_Y161_waddr = X154_Y161_waddr;
	wire X153_Y160_incr_raddr;
	assign X153_Y160_incr_raddr = X154_Y161_incr_raddr;
	wire [ADDR_WIDTH-1:0] X153_Y160_raddr;
	assign X153_Y160_raddr = X154_Y161_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X154_Y161(.clk(bus_clock),
		.incr_waddr(X154_Y161_incr_waddr),
		.waddr(X154_Y161_waddr),
		.incr_raddr(X154_Y161_incr_raddr),
		.raddr(X154_Y161_raddr));


	/* generated from C@X238_Y161@{W[2][36],W[2][35]}@4 */

	logic X238_Y161_incr_waddr; // ingress control
	logic X238_Y161_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) west_to_east_sector_size_2_west_to_east_ip_size_35_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][36][0]),
		.out(X238_Y161_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) west_to_east_sector_size_2_west_to_east_ip_size_35_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][36][1]),
		.out(X238_Y161_incr_raddr));

	logic [ADDR_WIDTH-1:0] X238_Y161_waddr;
	logic [ADDR_WIDTH-1:0] X238_Y161_raddr;

	/* positional aliases */

	wire X239_Y161_incr_waddr;
	assign X239_Y161_incr_waddr = X238_Y161_incr_waddr;
	wire [ADDR_WIDTH-1:0] X239_Y161_waddr;
	assign X239_Y161_waddr = X238_Y161_waddr;
	wire X239_Y160_incr_raddr;
	assign X239_Y160_incr_raddr = X238_Y161_incr_raddr;
	wire [ADDR_WIDTH-1:0] X239_Y160_raddr;
	assign X239_Y160_raddr = X238_Y161_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X238_Y161(.clk(bus_clock),
		.incr_waddr(X238_Y161_incr_waddr),
		.waddr(X238_Y161_waddr),
		.incr_raddr(X238_Y161_incr_raddr),
		.raddr(X238_Y161_raddr));


	/* generated from I@X239_Y161@{W[2][36],W[2][35]}@4 */

	logic [DATA_WIDTH-1:0] X239_Y161_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_2_west_to_east_ip_size_35_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][36][10:0], west_in_reg[2][35][10:2]}),
		.out(X239_Y161_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X239_Y161(.data(X239_Y161_bus_wdata),
		.q(/* to design */),
		.wraddress(X239_Y161_waddr),
		.rdaddress(/* from design */),
		.wren(X239_Y161_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X153_Y160@{E[2][36],E[2][35]}@4 */

	logic [DATA_WIDTH-1:0] X153_Y160_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X153_Y160_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) east_to_west_sector_size_2_east_to_west_ip_size_35_bus_first_egress_fifo(.clock(bus_clock),
		.in(X153_Y160_bus_rdata_in),
		.out(X153_Y160_bus_rdata_out));

	assign west_out_reg[2][36][10:0] = X153_Y160_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][35][10:2] = X153_Y160_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X153_Y160(.data(/* from design */),
		.q(X153_Y160_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X153_Y160_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X239_Y160@{W[2][36],W[2][35]}@5 */

	logic [DATA_WIDTH-1:0] X239_Y160_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X239_Y160_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_35_bus_first_egress_fifo(.clock(bus_clock),
		.in(X239_Y160_bus_rdata_in),
		.out(X239_Y160_bus_rdata_out));

	assign east_out_reg[2][36][10:0] = X239_Y160_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][35][10:2] = X239_Y160_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X239_Y160(.data(/* from design */),
		.q(X239_Y160_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X239_Y160_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X152_Y159@{W[2][34],W[2][33]}@2 */

	logic X152_Y159_incr_waddr; // ingress control
	logic X152_Y159_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) west_to_east_sector_size_2_west_to_east_ip_size_33_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][33][0]),
		.out(X152_Y159_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) west_to_east_sector_size_2_west_to_east_ip_size_33_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][33][1]),
		.out(X152_Y159_incr_raddr));

	logic [ADDR_WIDTH-1:0] X152_Y159_waddr;
	logic [ADDR_WIDTH-1:0] X152_Y159_raddr;

	/* positional aliases */

	wire X153_Y159_incr_waddr;
	assign X153_Y159_incr_waddr = X152_Y159_incr_waddr;
	wire [ADDR_WIDTH-1:0] X153_Y159_waddr;
	assign X153_Y159_waddr = X152_Y159_waddr;
	wire X153_Y158_incr_raddr;
	assign X153_Y158_incr_raddr = X152_Y159_incr_raddr;
	wire [ADDR_WIDTH-1:0] X153_Y158_raddr;
	assign X153_Y158_raddr = X152_Y159_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X152_Y159(.clk(bus_clock),
		.incr_waddr(X152_Y159_incr_waddr),
		.waddr(X152_Y159_waddr),
		.incr_raddr(X152_Y159_incr_raddr),
		.raddr(X152_Y159_raddr));


	/* generated from I@X153_Y159@{W[2][34],W[2][33]}@2 */

	logic [DATA_WIDTH-1:0] X153_Y159_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) west_to_east_sector_size_2_west_to_east_ip_size_33_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][34][10:0], west_in_reg[2][33][10:2]}),
		.out(X153_Y159_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X153_Y159(.data(X153_Y159_bus_wdata),
		.q(/* to design */),
		.wraddress(X153_Y159_waddr),
		.rdaddress(/* from design */),
		.wren(X153_Y159_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from I@X239_Y159@{E[2][34],E[2][33]}@1 */

	logic [DATA_WIDTH-1:0] X239_Y159_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_33_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][34][10:0], east_in_reg[2][33][10:2]}),
		.out(X239_Y159_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X239_Y159(.data(X239_Y159_bus_wdata),
		.q(/* to design */),
		.wraddress(X239_Y159_waddr),
		.rdaddress(/* from design */),
		.wren(X239_Y159_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X240_Y159@{E[2][34],E[2][33]}@1 */

	logic X240_Y159_incr_waddr; // ingress control
	logic X240_Y159_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_33_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][34][0]),
		.out(X240_Y159_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_33_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][34][1]),
		.out(X240_Y159_incr_raddr));

	logic [ADDR_WIDTH-1:0] X240_Y159_waddr;
	logic [ADDR_WIDTH-1:0] X240_Y159_raddr;

	/* positional aliases */

	wire X239_Y159_incr_waddr;
	assign X239_Y159_incr_waddr = X240_Y159_incr_waddr;
	wire [ADDR_WIDTH-1:0] X239_Y159_waddr;
	assign X239_Y159_waddr = X240_Y159_waddr;
	wire X239_Y158_incr_raddr;
	assign X239_Y158_incr_raddr = X240_Y159_incr_raddr;
	wire [ADDR_WIDTH-1:0] X239_Y158_raddr;
	assign X239_Y158_raddr = X240_Y159_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X240_Y159(.clk(bus_clock),
		.incr_waddr(X240_Y159_incr_waddr),
		.waddr(X240_Y159_waddr),
		.incr_raddr(X240_Y159_incr_raddr),
		.raddr(X240_Y159_raddr));


	/* generated from E@X153_Y158@{W[2][34],W[2][33]}@3 */

	logic [DATA_WIDTH-1:0] X153_Y158_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X153_Y158_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) west_to_east_sector_size_2_west_to_east_ip_size_33_bus_first_egress_fifo(.clock(bus_clock),
		.in(X153_Y158_bus_rdata_in),
		.out(X153_Y158_bus_rdata_out));

	assign east_out_reg[2][34][10:0] = X153_Y158_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][33][10:2] = X153_Y158_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X153_Y158(.data(/* from design */),
		.q(X153_Y158_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X153_Y158_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X239_Y158@{E[2][34],E[2][33]}@2 */

	logic [DATA_WIDTH-1:0] X239_Y158_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X239_Y158_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_33_bus_first_egress_fifo(.clock(bus_clock),
		.in(X239_Y158_bus_rdata_in),
		.out(X239_Y158_bus_rdata_out));

	assign west_out_reg[2][34][10:0] = X239_Y158_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][33][10:2] = X239_Y158_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X239_Y158(.data(/* from design */),
		.q(X239_Y158_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X239_Y158_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X83_Y157@{E[2][32],E[2][31]}@5 */

	logic [DATA_WIDTH-1:0] X83_Y157_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) east_to_west_sector_size_2_east_to_west_ip_size_31_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][32][10:0], east_in_reg[2][31][10:2]}),
		.out(X83_Y157_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X83_Y157(.data(X83_Y157_bus_wdata),
		.q(/* to design */),
		.wraddress(X83_Y157_waddr),
		.rdaddress(/* from design */),
		.wren(X83_Y157_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X84_Y157@{E[2][32],E[2][31]}@5 */

	logic X84_Y157_incr_waddr; // ingress control
	logic X84_Y157_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) east_to_west_sector_size_2_east_to_west_ip_size_31_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][31][0]),
		.out(X84_Y157_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) east_to_west_sector_size_2_east_to_west_ip_size_31_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][31][1]),
		.out(X84_Y157_incr_raddr));

	logic [ADDR_WIDTH-1:0] X84_Y157_waddr;
	logic [ADDR_WIDTH-1:0] X84_Y157_raddr;

	/* positional aliases */

	wire X83_Y157_incr_waddr;
	assign X83_Y157_incr_waddr = X84_Y157_incr_waddr;
	wire [ADDR_WIDTH-1:0] X83_Y157_waddr;
	assign X83_Y157_waddr = X84_Y157_waddr;
	wire X83_Y156_incr_raddr;
	assign X83_Y156_incr_raddr = X84_Y157_incr_raddr;
	wire [ADDR_WIDTH-1:0] X83_Y156_raddr;
	assign X83_Y156_raddr = X84_Y157_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X84_Y157(.clk(bus_clock),
		.incr_waddr(X84_Y157_incr_waddr),
		.waddr(X84_Y157_waddr),
		.incr_raddr(X84_Y157_incr_raddr),
		.raddr(X84_Y157_raddr));


	/* generated from C@X184_Y157@{W[2][32],W[2][31]}@3 */

	logic X184_Y157_incr_waddr; // ingress control
	logic X184_Y157_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_2_west_to_east_ip_size_31_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][32][0]),
		.out(X184_Y157_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_2_west_to_east_ip_size_31_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][32][1]),
		.out(X184_Y157_incr_raddr));

	logic [ADDR_WIDTH-1:0] X184_Y157_waddr;
	logic [ADDR_WIDTH-1:0] X184_Y157_raddr;

	/* positional aliases */

	wire X185_Y157_incr_waddr;
	assign X185_Y157_incr_waddr = X184_Y157_incr_waddr;
	wire [ADDR_WIDTH-1:0] X185_Y157_waddr;
	assign X185_Y157_waddr = X184_Y157_waddr;
	wire X185_Y156_incr_raddr;
	assign X185_Y156_incr_raddr = X184_Y157_incr_raddr;
	wire [ADDR_WIDTH-1:0] X185_Y156_raddr;
	assign X185_Y156_raddr = X184_Y157_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X184_Y157(.clk(bus_clock),
		.incr_waddr(X184_Y157_incr_waddr),
		.waddr(X184_Y157_waddr),
		.incr_raddr(X184_Y157_incr_raddr),
		.raddr(X184_Y157_raddr));


	/* generated from I@X185_Y157@{W[2][32],W[2][31]}@3 */

	logic [DATA_WIDTH-1:0] X185_Y157_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) west_to_east_sector_size_2_west_to_east_ip_size_31_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][32][10:0], west_in_reg[2][31][10:2]}),
		.out(X185_Y157_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X185_Y157(.data(X185_Y157_bus_wdata),
		.q(/* to design */),
		.wraddress(X185_Y157_waddr),
		.rdaddress(/* from design */),
		.wren(X185_Y157_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X83_Y156@{E[2][32],E[2][31]}@6 */

	logic [DATA_WIDTH-1:0] X83_Y156_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X83_Y156_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) east_to_west_sector_size_2_east_to_west_ip_size_31_bus_first_egress_fifo(.clock(bus_clock),
		.in(X83_Y156_bus_rdata_in),
		.out(X83_Y156_bus_rdata_out));

	assign west_out_reg[2][32][10:0] = X83_Y156_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][31][10:2] = X83_Y156_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X83_Y156(.data(/* from design */),
		.q(X83_Y156_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X83_Y156_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X185_Y156@{W[2][32],W[2][31]}@4 */

	logic [DATA_WIDTH-1:0] X185_Y156_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X185_Y156_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) west_to_east_sector_size_2_west_to_east_ip_size_31_bus_first_egress_fifo(.clock(bus_clock),
		.in(X185_Y156_bus_rdata_in),
		.out(X185_Y156_bus_rdata_out));

	assign east_out_reg[2][32][10:0] = X185_Y156_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][31][10:2] = X185_Y156_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X185_Y156(.data(/* from design */),
		.q(X185_Y156_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X185_Y156_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X82_Y155@{W[2][30],W[2][29]}@0 */

	logic X82_Y155_incr_waddr; // ingress control
	logic X82_Y155_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) west_to_east_sector_size_2_west_to_east_ip_size_29_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][29][0]),
		.out(X82_Y155_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) west_to_east_sector_size_2_west_to_east_ip_size_29_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][29][1]),
		.out(X82_Y155_incr_raddr));

	logic [ADDR_WIDTH-1:0] X82_Y155_waddr;
	logic [ADDR_WIDTH-1:0] X82_Y155_raddr;

	/* positional aliases */

	wire X83_Y155_incr_waddr;
	assign X83_Y155_incr_waddr = X82_Y155_incr_waddr;
	wire [ADDR_WIDTH-1:0] X83_Y155_waddr;
	assign X83_Y155_waddr = X82_Y155_waddr;
	wire X83_Y154_incr_raddr;
	assign X83_Y154_incr_raddr = X82_Y155_incr_raddr;
	wire [ADDR_WIDTH-1:0] X83_Y154_raddr;
	assign X83_Y154_raddr = X82_Y155_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X82_Y155(.clk(bus_clock),
		.incr_waddr(X82_Y155_incr_waddr),
		.waddr(X82_Y155_waddr),
		.incr_raddr(X82_Y155_incr_raddr),
		.raddr(X82_Y155_raddr));


	/* generated from I@X83_Y155@{W[2][30],W[2][29]}@0 */

	logic [DATA_WIDTH-1:0] X83_Y155_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) west_to_east_sector_size_2_west_to_east_ip_size_29_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][30][10:0], west_in_reg[2][29][10:2]}),
		.out(X83_Y155_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X83_Y155(.data(X83_Y155_bus_wdata),
		.q(/* to design */),
		.wraddress(X83_Y155_waddr),
		.rdaddress(/* from design */),
		.wren(X83_Y155_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from I@X185_Y155@{E[2][30],E[2][29]}@2 */

	logic [DATA_WIDTH-1:0] X185_Y155_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) east_to_west_sector_size_2_east_to_west_ip_size_29_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][30][10:0], east_in_reg[2][29][10:2]}),
		.out(X185_Y155_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X185_Y155(.data(X185_Y155_bus_wdata),
		.q(/* to design */),
		.wraddress(X185_Y155_waddr),
		.rdaddress(/* from design */),
		.wren(X185_Y155_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X186_Y155@{E[2][30],E[2][29]}@2 */

	logic X186_Y155_incr_waddr; // ingress control
	logic X186_Y155_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) east_to_west_sector_size_2_east_to_west_ip_size_29_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][30][0]),
		.out(X186_Y155_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) east_to_west_sector_size_2_east_to_west_ip_size_29_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][30][1]),
		.out(X186_Y155_incr_raddr));

	logic [ADDR_WIDTH-1:0] X186_Y155_waddr;
	logic [ADDR_WIDTH-1:0] X186_Y155_raddr;

	/* positional aliases */

	wire X185_Y155_incr_waddr;
	assign X185_Y155_incr_waddr = X186_Y155_incr_waddr;
	wire [ADDR_WIDTH-1:0] X185_Y155_waddr;
	assign X185_Y155_waddr = X186_Y155_waddr;
	wire X185_Y154_incr_raddr;
	assign X185_Y154_incr_raddr = X186_Y155_incr_raddr;
	wire [ADDR_WIDTH-1:0] X185_Y154_raddr;
	assign X185_Y154_raddr = X186_Y155_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X186_Y155(.clk(bus_clock),
		.incr_waddr(X186_Y155_incr_waddr),
		.waddr(X186_Y155_waddr),
		.incr_raddr(X186_Y155_incr_raddr),
		.raddr(X186_Y155_raddr));


	/* generated from E@X83_Y154@{W[2][30],W[2][29]}@1 */

	logic [DATA_WIDTH-1:0] X83_Y154_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X83_Y154_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) west_to_east_sector_size_2_west_to_east_ip_size_29_bus_first_egress_fifo(.clock(bus_clock),
		.in(X83_Y154_bus_rdata_in),
		.out(X83_Y154_bus_rdata_out));

	assign east_out_reg[2][30][10:0] = X83_Y154_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][29][10:2] = X83_Y154_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X83_Y154(.data(/* from design */),
		.q(X83_Y154_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X83_Y154_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X185_Y154@{E[2][30],E[2][29]}@3 */

	logic [DATA_WIDTH-1:0] X185_Y154_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X185_Y154_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) east_to_west_sector_size_2_east_to_west_ip_size_29_bus_first_egress_fifo(.clock(bus_clock),
		.in(X185_Y154_bus_rdata_in),
		.out(X185_Y154_bus_rdata_out));

	assign west_out_reg[2][30][10:0] = X185_Y154_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][29][10:2] = X185_Y154_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X185_Y154(.data(/* from design */),
		.q(X185_Y154_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X185_Y154_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X132_Y153@{E[2][28],E[2][27]}@4 */

	logic [DATA_WIDTH-1:0] X132_Y153_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_27_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][28][10:0], east_in_reg[2][27][10:2]}),
		.out(X132_Y153_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X132_Y153(.data(X132_Y153_bus_wdata),
		.q(/* to design */),
		.wraddress(X132_Y153_waddr),
		.rdaddress(/* from design */),
		.wren(X132_Y153_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X133_Y153@{E[2][28],E[2][27]}@4 */

	logic X133_Y153_incr_waddr; // ingress control
	logic X133_Y153_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_27_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][27][0]),
		.out(X133_Y153_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_27_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][27][1]),
		.out(X133_Y153_incr_raddr));

	logic [ADDR_WIDTH-1:0] X133_Y153_waddr;
	logic [ADDR_WIDTH-1:0] X133_Y153_raddr;

	/* positional aliases */

	wire X132_Y153_incr_waddr;
	assign X132_Y153_incr_waddr = X133_Y153_incr_waddr;
	wire [ADDR_WIDTH-1:0] X132_Y153_waddr;
	assign X132_Y153_waddr = X133_Y153_waddr;
	wire X132_Y152_incr_raddr;
	assign X132_Y152_incr_raddr = X133_Y153_incr_raddr;
	wire [ADDR_WIDTH-1:0] X132_Y152_raddr;
	assign X132_Y152_raddr = X133_Y153_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X133_Y153(.clk(bus_clock),
		.incr_waddr(X133_Y153_incr_waddr),
		.waddr(X133_Y153_waddr),
		.incr_raddr(X133_Y153_incr_raddr),
		.raddr(X133_Y153_raddr));


	/* generated from C@X259_Y153@{W[2][28],W[2][27]}@5 */

	logic X259_Y153_incr_waddr; // ingress control
	logic X259_Y153_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) west_to_east_sector_size_2_west_to_east_ip_size_27_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][28][0]),
		.out(X259_Y153_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) west_to_east_sector_size_2_west_to_east_ip_size_27_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][28][1]),
		.out(X259_Y153_incr_raddr));

	logic [ADDR_WIDTH-1:0] X259_Y153_waddr;
	logic [ADDR_WIDTH-1:0] X259_Y153_raddr;

	/* positional aliases */

	wire X260_Y153_incr_waddr;
	assign X260_Y153_incr_waddr = X259_Y153_incr_waddr;
	wire [ADDR_WIDTH-1:0] X260_Y153_waddr;
	assign X260_Y153_waddr = X259_Y153_waddr;
	wire X260_Y152_incr_raddr;
	assign X260_Y152_incr_raddr = X259_Y153_incr_raddr;
	wire [ADDR_WIDTH-1:0] X260_Y152_raddr;
	assign X260_Y152_raddr = X259_Y153_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X259_Y153(.clk(bus_clock),
		.incr_waddr(X259_Y153_incr_waddr),
		.waddr(X259_Y153_waddr),
		.incr_raddr(X259_Y153_incr_raddr),
		.raddr(X259_Y153_raddr));


	/* generated from I@X260_Y153@{W[2][28],W[2][27]}@5 */

	logic [DATA_WIDTH-1:0] X260_Y153_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) west_to_east_sector_size_2_west_to_east_ip_size_27_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][28][10:0], west_in_reg[2][27][10:2]}),
		.out(X260_Y153_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X260_Y153(.data(X260_Y153_bus_wdata),
		.q(/* to design */),
		.wraddress(X260_Y153_waddr),
		.rdaddress(/* from design */),
		.wren(X260_Y153_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X132_Y152@{E[2][28],E[2][27]}@5 */

	logic [DATA_WIDTH-1:0] X132_Y152_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X132_Y152_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_27_bus_first_egress_fifo(.clock(bus_clock),
		.in(X132_Y152_bus_rdata_in),
		.out(X132_Y152_bus_rdata_out));

	assign west_out_reg[2][28][10:0] = X132_Y152_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][27][10:2] = X132_Y152_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X132_Y152(.data(/* from design */),
		.q(X132_Y152_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X132_Y152_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X260_Y152@{W[2][28],W[2][27]}@6 */

	logic [DATA_WIDTH-1:0] X260_Y152_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X260_Y152_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) west_to_east_sector_size_2_west_to_east_ip_size_27_bus_first_egress_fifo(.clock(bus_clock),
		.in(X260_Y152_bus_rdata_in),
		.out(X260_Y152_bus_rdata_out));

	assign east_out_reg[2][28][10:0] = X260_Y152_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][27][10:2] = X260_Y152_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X260_Y152(.data(/* from design */),
		.q(X260_Y152_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X260_Y152_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X131_Y151@{W[2][26],W[2][25]}@1 */

	logic X131_Y151_incr_waddr; // ingress control
	logic X131_Y151_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_25_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][25][0]),
		.out(X131_Y151_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_25_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][25][1]),
		.out(X131_Y151_incr_raddr));

	logic [ADDR_WIDTH-1:0] X131_Y151_waddr;
	logic [ADDR_WIDTH-1:0] X131_Y151_raddr;

	/* positional aliases */

	wire X132_Y151_incr_waddr;
	assign X132_Y151_incr_waddr = X131_Y151_incr_waddr;
	wire [ADDR_WIDTH-1:0] X132_Y151_waddr;
	assign X132_Y151_waddr = X131_Y151_waddr;
	wire X132_Y150_incr_raddr;
	assign X132_Y150_incr_raddr = X131_Y151_incr_raddr;
	wire [ADDR_WIDTH-1:0] X132_Y150_raddr;
	assign X132_Y150_raddr = X131_Y151_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X131_Y151(.clk(bus_clock),
		.incr_waddr(X131_Y151_incr_waddr),
		.waddr(X131_Y151_waddr),
		.incr_raddr(X131_Y151_incr_raddr),
		.raddr(X131_Y151_raddr));


	/* generated from I@X132_Y151@{W[2][26],W[2][25]}@1 */

	logic [DATA_WIDTH-1:0] X132_Y151_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_25_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][26][10:0], west_in_reg[2][25][10:2]}),
		.out(X132_Y151_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X132_Y151(.data(X132_Y151_bus_wdata),
		.q(/* to design */),
		.wraddress(X132_Y151_waddr),
		.rdaddress(/* from design */),
		.wren(X132_Y151_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X152_Y151@{N[1][23],N[1][24]}@0 */

	logic X152_Y151_incr_waddr; // ingress control
	logic X152_Y151_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) north_to_south_sector_size_1_north_to_south_ip_size_24_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][24][0]),
		.out(X152_Y151_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) north_to_south_sector_size_1_north_to_south_ip_size_24_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][24][1]),
		.out(X152_Y151_incr_raddr));

	logic [ADDR_WIDTH-1:0] X152_Y151_waddr;
	logic [ADDR_WIDTH-1:0] X152_Y151_raddr;

	/* positional aliases */

	wire X153_Y151_incr_waddr;
	assign X153_Y151_incr_waddr = X152_Y151_incr_waddr;
	wire [ADDR_WIDTH-1:0] X153_Y151_waddr;
	assign X153_Y151_waddr = X152_Y151_waddr;
	wire X153_Y150_incr_raddr;
	assign X153_Y150_incr_raddr = X152_Y151_incr_raddr;
	wire [ADDR_WIDTH-1:0] X153_Y150_raddr;
	assign X153_Y150_raddr = X152_Y151_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X152_Y151(.clk(bus_clock),
		.incr_waddr(X152_Y151_incr_waddr),
		.waddr(X152_Y151_waddr),
		.incr_raddr(X152_Y151_incr_raddr),
		.raddr(X152_Y151_raddr));


	/* generated from I@X153_Y151@{N[1][24],N[1][25]}@0 */

	logic [DATA_WIDTH-1:0] X153_Y151_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) north_to_south_sector_size_1_north_to_south_ip_size_25_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][24][10:0], north_in_reg[1][25][10:2]}),
		.out(X153_Y151_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X153_Y151(.data(X153_Y151_bus_wdata),
		.q(/* to design */),
		.wraddress(X153_Y151_waddr),
		.rdaddress(/* from design */),
		.wren(X153_Y151_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X155_Y151@{S[1][26],S[1][27]}@6 */

	logic [DATA_WIDTH-1:0] X155_Y151_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X155_Y151_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) south_to_north_sector_size_1_south_to_north_ip_size_27_bus_first_egress_fifo(.clock(bus_clock),
		.in(X155_Y151_bus_rdata_in),
		.out(X155_Y151_bus_rdata_out));

	assign north_out_reg[1][26][10:0] = X155_Y151_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][27][10:2] = X155_Y151_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X155_Y151(.data(/* from design */),
		.q(X155_Y151_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X155_Y151_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X237_Y151@{N[3][9],N[3][8]}@0 */

	logic [DATA_WIDTH-1:0] X237_Y151_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) north_to_south_sector_size_3_north_to_south_ip_size_8_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][9][10:0], north_in_reg[3][8][10:2]}),
		.out(X237_Y151_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X237_Y151(.data(X237_Y151_bus_wdata),
		.q(/* to design */),
		.wraddress(X237_Y151_waddr),
		.rdaddress(/* from design */),
		.wren(X237_Y151_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X238_Y151@{N[3][10],N[3][9]}@0 */

	logic X238_Y151_incr_waddr; // ingress control
	logic X238_Y151_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) north_to_south_sector_size_3_north_to_south_ip_size_9_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][10][0]),
		.out(X238_Y151_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) north_to_south_sector_size_3_north_to_south_ip_size_9_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][10][1]),
		.out(X238_Y151_incr_raddr));

	logic [ADDR_WIDTH-1:0] X238_Y151_waddr;
	logic [ADDR_WIDTH-1:0] X238_Y151_raddr;

	/* positional aliases */

	wire X237_Y151_incr_waddr;
	assign X237_Y151_incr_waddr = X238_Y151_incr_waddr;
	wire [ADDR_WIDTH-1:0] X237_Y151_waddr;
	assign X237_Y151_waddr = X238_Y151_waddr;
	wire X237_Y150_incr_raddr;
	assign X237_Y150_incr_raddr = X238_Y151_incr_raddr;
	wire [ADDR_WIDTH-1:0] X237_Y150_raddr;
	assign X237_Y150_raddr = X238_Y151_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X238_Y151(.clk(bus_clock),
		.incr_waddr(X238_Y151_incr_waddr),
		.waddr(X238_Y151_waddr),
		.incr_raddr(X238_Y151_incr_raddr),
		.raddr(X238_Y151_raddr));


	/* generated from E@X239_Y151@{S[3][11],S[3][10]}@6 */

	logic [DATA_WIDTH-1:0] X239_Y151_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X239_Y151_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) south_to_north_sector_size_3_south_to_north_ip_size_10_bus_first_egress_fifo(.clock(bus_clock),
		.in(X239_Y151_bus_rdata_in),
		.out(X239_Y151_bus_rdata_out));

	assign north_out_reg[3][11][10:0] = X239_Y151_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][10][10:2] = X239_Y151_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X239_Y151(.data(/* from design */),
		.q(X239_Y151_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X239_Y151_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X260_Y151@{E[2][26],E[2][25]}@0 */

	logic [DATA_WIDTH-1:0] X260_Y151_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) east_to_west_sector_size_2_east_to_west_ip_size_25_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][26][10:0], east_in_reg[2][25][10:2]}),
		.out(X260_Y151_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X260_Y151(.data(X260_Y151_bus_wdata),
		.q(/* to design */),
		.wraddress(X260_Y151_waddr),
		.rdaddress(/* from design */),
		.wren(X260_Y151_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X261_Y151@{E[2][26],E[2][25]}@0 */

	logic X261_Y151_incr_waddr; // ingress control
	logic X261_Y151_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) east_to_west_sector_size_2_east_to_west_ip_size_25_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][26][0]),
		.out(X261_Y151_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) east_to_west_sector_size_2_east_to_west_ip_size_25_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][26][1]),
		.out(X261_Y151_incr_raddr));

	logic [ADDR_WIDTH-1:0] X261_Y151_waddr;
	logic [ADDR_WIDTH-1:0] X261_Y151_raddr;

	/* positional aliases */

	wire X260_Y151_incr_waddr;
	assign X260_Y151_incr_waddr = X261_Y151_incr_waddr;
	wire [ADDR_WIDTH-1:0] X260_Y151_waddr;
	assign X260_Y151_waddr = X261_Y151_waddr;
	wire X260_Y150_incr_raddr;
	assign X260_Y150_incr_raddr = X261_Y151_incr_raddr;
	wire [ADDR_WIDTH-1:0] X260_Y150_raddr;
	assign X260_Y150_raddr = X261_Y151_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X261_Y151(.clk(bus_clock),
		.incr_waddr(X261_Y151_incr_waddr),
		.waddr(X261_Y151_waddr),
		.incr_raddr(X261_Y151_incr_raddr),
		.raddr(X261_Y151_raddr));


	/* generated from E@X132_Y150@{W[2][26],W[2][25]}@2 */

	logic [DATA_WIDTH-1:0] X132_Y150_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X132_Y150_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_2_west_to_east_ip_size_25_bus_first_egress_fifo(.clock(bus_clock),
		.in(X132_Y150_bus_rdata_in),
		.out(X132_Y150_bus_rdata_out));

	assign east_out_reg[2][26][10:0] = X132_Y150_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][25][10:2] = X132_Y150_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X132_Y150(.data(/* from design */),
		.q(X132_Y150_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X132_Y150_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X153_Y150@{N[1][24],N[1][25]}@1 */

	logic [DATA_WIDTH-1:0] X153_Y150_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X153_Y150_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) north_to_south_sector_size_1_north_to_south_ip_size_25_bus_first_egress_fifo(.clock(bus_clock),
		.in(X153_Y150_bus_rdata_in),
		.out(X153_Y150_bus_rdata_out));

	assign south_out_reg[1][24][10:0] = X153_Y150_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][25][10:2] = X153_Y150_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X153_Y150(.data(/* from design */),
		.q(X153_Y150_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X153_Y150_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X154_Y150@{S[1][25],S[1][26]}@5 */

	logic X154_Y150_incr_waddr; // ingress control
	logic X154_Y150_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) south_to_north_sector_size_1_south_to_north_ip_size_26_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][26][0]),
		.out(X154_Y150_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) south_to_north_sector_size_1_south_to_north_ip_size_26_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][26][1]),
		.out(X154_Y150_incr_raddr));

	logic [ADDR_WIDTH-1:0] X154_Y150_waddr;
	logic [ADDR_WIDTH-1:0] X154_Y150_raddr;

	/* positional aliases */

	wire X155_Y150_incr_waddr;
	assign X155_Y150_incr_waddr = X154_Y150_incr_waddr;
	wire [ADDR_WIDTH-1:0] X155_Y150_waddr;
	assign X155_Y150_waddr = X154_Y150_waddr;
	wire X155_Y151_incr_raddr;
	assign X155_Y151_incr_raddr = X154_Y150_incr_raddr;
	wire [ADDR_WIDTH-1:0] X155_Y151_raddr;
	assign X155_Y151_raddr = X154_Y150_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X154_Y150(.clk(bus_clock),
		.incr_waddr(X154_Y150_incr_waddr),
		.waddr(X154_Y150_waddr),
		.incr_raddr(X154_Y150_incr_raddr),
		.raddr(X154_Y150_raddr));


	/* generated from I@X155_Y150@{S[1][26],S[1][27]}@5 */

	logic [DATA_WIDTH-1:0] X155_Y150_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) south_to_north_sector_size_1_south_to_north_ip_size_27_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][26][10:0], south_in_reg[1][27][10:2]}),
		.out(X155_Y150_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X155_Y150(.data(X155_Y150_bus_wdata),
		.q(/* to design */),
		.wraddress(X155_Y150_waddr),
		.rdaddress(/* from design */),
		.wren(X155_Y150_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X237_Y150@{N[3][9],N[3][8]}@1 */

	logic [DATA_WIDTH-1:0] X237_Y150_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X237_Y150_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) north_to_south_sector_size_3_north_to_south_ip_size_8_bus_first_egress_fifo(.clock(bus_clock),
		.in(X237_Y150_bus_rdata_in),
		.out(X237_Y150_bus_rdata_out));

	assign south_out_reg[3][9][10:0] = X237_Y150_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][8][10:2] = X237_Y150_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X237_Y150(.data(/* from design */),
		.q(X237_Y150_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X237_Y150_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X239_Y150@{S[3][11],S[3][10]}@5 */

	logic [DATA_WIDTH-1:0] X239_Y150_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) south_to_north_sector_size_3_south_to_north_ip_size_10_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][11][10:0], south_in_reg[3][10][10:2]}),
		.out(X239_Y150_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X239_Y150(.data(X239_Y150_bus_wdata),
		.q(/* to design */),
		.wraddress(X239_Y150_waddr),
		.rdaddress(/* from design */),
		.wren(X239_Y150_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X240_Y150@{S[3][12],S[3][11]}@5 */

	logic X240_Y150_incr_waddr; // ingress control
	logic X240_Y150_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) south_to_north_sector_size_3_south_to_north_ip_size_11_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][12][0]),
		.out(X240_Y150_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) south_to_north_sector_size_3_south_to_north_ip_size_11_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][12][1]),
		.out(X240_Y150_incr_raddr));

	logic [ADDR_WIDTH-1:0] X240_Y150_waddr;
	logic [ADDR_WIDTH-1:0] X240_Y150_raddr;

	/* positional aliases */

	wire X239_Y150_incr_waddr;
	assign X239_Y150_incr_waddr = X240_Y150_incr_waddr;
	wire [ADDR_WIDTH-1:0] X239_Y150_waddr;
	assign X239_Y150_waddr = X240_Y150_waddr;
	wire X239_Y151_incr_raddr;
	assign X239_Y151_incr_raddr = X240_Y150_incr_raddr;
	wire [ADDR_WIDTH-1:0] X239_Y151_raddr;
	assign X239_Y151_raddr = X240_Y150_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X240_Y150(.clk(bus_clock),
		.incr_waddr(X240_Y150_incr_waddr),
		.waddr(X240_Y150_waddr),
		.incr_raddr(X240_Y150_incr_raddr),
		.raddr(X240_Y150_raddr));


	/* generated from E@X260_Y150@{E[2][26],E[2][25]}@1 */

	logic [DATA_WIDTH-1:0] X260_Y150_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X260_Y150_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) east_to_west_sector_size_2_east_to_west_ip_size_25_bus_first_egress_fifo(.clock(bus_clock),
		.in(X260_Y150_bus_rdata_in),
		.out(X260_Y150_bus_rdata_out));

	assign west_out_reg[2][26][10:0] = X260_Y150_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][25][10:2] = X260_Y150_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X260_Y150(.data(/* from design */),
		.q(X260_Y150_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X260_Y150_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X104_Y149@{E[2][24],E[2][23]}@4 */

	logic [DATA_WIDTH-1:0] X104_Y149_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_23_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][24][10:0], east_in_reg[2][23][10:2]}),
		.out(X104_Y149_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X104_Y149(.data(X104_Y149_bus_wdata),
		.q(/* to design */),
		.wraddress(X104_Y149_waddr),
		.rdaddress(/* from design */),
		.wren(X104_Y149_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X105_Y149@{E[2][24],E[2][23]}@4 */

	logic X105_Y149_incr_waddr; // ingress control
	logic X105_Y149_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_23_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][23][0]),
		.out(X105_Y149_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_23_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][23][1]),
		.out(X105_Y149_incr_raddr));

	logic [ADDR_WIDTH-1:0] X105_Y149_waddr;
	logic [ADDR_WIDTH-1:0] X105_Y149_raddr;

	/* positional aliases */

	wire X104_Y149_incr_waddr;
	assign X104_Y149_incr_waddr = X105_Y149_incr_waddr;
	wire [ADDR_WIDTH-1:0] X104_Y149_waddr;
	assign X104_Y149_waddr = X105_Y149_waddr;
	wire X104_Y148_incr_raddr;
	assign X104_Y148_incr_raddr = X105_Y149_incr_raddr;
	wire [ADDR_WIDTH-1:0] X104_Y148_raddr;
	assign X104_Y148_raddr = X105_Y149_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X105_Y149(.clk(bus_clock),
		.incr_waddr(X105_Y149_incr_waddr),
		.waddr(X105_Y149_waddr),
		.incr_raddr(X105_Y149_incr_raddr),
		.raddr(X105_Y149_raddr));


	/* generated from C@X205_Y149@{W[2][24],W[2][23]}@3 */

	logic X205_Y149_incr_waddr; // ingress control
	logic X205_Y149_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_2_west_to_east_ip_size_23_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][24][0]),
		.out(X205_Y149_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_2_west_to_east_ip_size_23_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][24][1]),
		.out(X205_Y149_incr_raddr));

	logic [ADDR_WIDTH-1:0] X205_Y149_waddr;
	logic [ADDR_WIDTH-1:0] X205_Y149_raddr;

	/* positional aliases */

	wire X206_Y149_incr_waddr;
	assign X206_Y149_incr_waddr = X205_Y149_incr_waddr;
	wire [ADDR_WIDTH-1:0] X206_Y149_waddr;
	assign X206_Y149_waddr = X205_Y149_waddr;
	wire X206_Y148_incr_raddr;
	assign X206_Y148_incr_raddr = X205_Y149_incr_raddr;
	wire [ADDR_WIDTH-1:0] X206_Y148_raddr;
	assign X206_Y148_raddr = X205_Y149_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X205_Y149(.clk(bus_clock),
		.incr_waddr(X205_Y149_incr_waddr),
		.waddr(X205_Y149_waddr),
		.incr_raddr(X205_Y149_incr_raddr),
		.raddr(X205_Y149_raddr));


	/* generated from I@X206_Y149@{W[2][24],W[2][23]}@4 */

	logic [DATA_WIDTH-1:0] X206_Y149_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_2_west_to_east_ip_size_23_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][24][10:0], west_in_reg[2][23][10:2]}),
		.out(X206_Y149_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X206_Y149(.data(X206_Y149_bus_wdata),
		.q(/* to design */),
		.wraddress(X206_Y149_waddr),
		.rdaddress(/* from design */),
		.wren(X206_Y149_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X104_Y148@{E[2][24],E[2][23]}@5 */

	logic [DATA_WIDTH-1:0] X104_Y148_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X104_Y148_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_23_bus_first_egress_fifo(.clock(bus_clock),
		.in(X104_Y148_bus_rdata_in),
		.out(X104_Y148_bus_rdata_out));

	assign west_out_reg[2][24][10:0] = X104_Y148_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][23][10:2] = X104_Y148_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X104_Y148(.data(/* from design */),
		.q(X104_Y148_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X104_Y148_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X206_Y148@{W[2][24],W[2][23]}@5 */

	logic [DATA_WIDTH-1:0] X206_Y148_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X206_Y148_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_23_bus_first_egress_fifo(.clock(bus_clock),
		.in(X206_Y148_bus_rdata_in),
		.out(X206_Y148_bus_rdata_out));

	assign east_out_reg[2][24][10:0] = X206_Y148_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][23][10:2] = X206_Y148_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X206_Y148(.data(/* from design */),
		.q(X206_Y148_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X206_Y148_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X66_Y147@{,N[0][0]}@0 */

	logic X66_Y147_incr_waddr; // ingress control
	logic X66_Y147_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) north_to_south_sector_size_0_north_to_south_ip_size_0_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][0][0]),
		.out(X66_Y147_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) north_to_south_sector_size_0_north_to_south_ip_size_0_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][0][1]),
		.out(X66_Y147_incr_raddr));

	logic [ADDR_WIDTH-1:0] X66_Y147_waddr;
	logic [ADDR_WIDTH-1:0] X66_Y147_raddr;

	/* positional aliases */

	wire X67_Y147_incr_waddr;
	assign X67_Y147_incr_waddr = X66_Y147_incr_waddr;
	wire [ADDR_WIDTH-1:0] X67_Y147_waddr;
	assign X67_Y147_waddr = X66_Y147_waddr;
	wire X67_Y146_incr_raddr;
	assign X67_Y146_incr_raddr = X66_Y147_incr_raddr;
	wire [ADDR_WIDTH-1:0] X67_Y146_raddr;
	assign X67_Y146_raddr = X66_Y147_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X66_Y147(.clk(bus_clock),
		.incr_waddr(X66_Y147_incr_waddr),
		.waddr(X66_Y147_waddr),
		.incr_raddr(X66_Y147_incr_raddr),
		.raddr(X66_Y147_raddr));


	/* generated from I@X67_Y147@{N[0][0],N[0][1]}@0 */

	logic [DATA_WIDTH-1:0] X67_Y147_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) north_to_south_sector_size_0_north_to_south_ip_size_1_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][0][10:0], north_in_reg[0][1][10:2]}),
		.out(X67_Y147_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X67_Y147(.data(X67_Y147_bus_wdata),
		.q(/* to design */),
		.wraddress(X67_Y147_waddr),
		.rdaddress(/* from design */),
		.wren(X67_Y147_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X69_Y147@{S[0][2],S[0][3]}@6 */

	logic [DATA_WIDTH-1:0] X69_Y147_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X69_Y147_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) south_to_north_sector_size_0_south_to_north_ip_size_3_bus_first_egress_fifo(.clock(bus_clock),
		.in(X69_Y147_bus_rdata_in),
		.out(X69_Y147_bus_rdata_out));

	assign north_out_reg[0][2][10:0] = X69_Y147_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][3][10:2] = X69_Y147_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X69_Y147(.data(/* from design */),
		.q(X69_Y147_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X69_Y147_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X77_Y147@{N[0][7],N[0][8]}@0 */

	logic X77_Y147_incr_waddr; // ingress control
	logic X77_Y147_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) north_to_south_sector_size_0_north_to_south_ip_size_8_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][8][0]),
		.out(X77_Y147_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) north_to_south_sector_size_0_north_to_south_ip_size_8_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][8][1]),
		.out(X77_Y147_incr_raddr));

	logic [ADDR_WIDTH-1:0] X77_Y147_waddr;
	logic [ADDR_WIDTH-1:0] X77_Y147_raddr;

	/* positional aliases */

	wire X78_Y147_incr_waddr;
	assign X78_Y147_incr_waddr = X77_Y147_incr_waddr;
	wire [ADDR_WIDTH-1:0] X78_Y147_waddr;
	assign X78_Y147_waddr = X77_Y147_waddr;
	wire X78_Y146_incr_raddr;
	assign X78_Y146_incr_raddr = X77_Y147_incr_raddr;
	wire [ADDR_WIDTH-1:0] X78_Y146_raddr;
	assign X78_Y146_raddr = X77_Y147_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X77_Y147(.clk(bus_clock),
		.incr_waddr(X77_Y147_incr_waddr),
		.waddr(X77_Y147_waddr),
		.incr_raddr(X77_Y147_incr_raddr),
		.raddr(X77_Y147_raddr));


	/* generated from I@X78_Y147@{N[0][8],N[0][9]}@0 */

	logic [DATA_WIDTH-1:0] X78_Y147_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) north_to_south_sector_size_0_north_to_south_ip_size_9_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][8][10:0], north_in_reg[0][9][10:2]}),
		.out(X78_Y147_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X78_Y147(.data(X78_Y147_bus_wdata),
		.q(/* to design */),
		.wraddress(X78_Y147_waddr),
		.rdaddress(/* from design */),
		.wren(X78_Y147_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X80_Y147@{S[0][10],S[0][11]}@6 */

	logic [DATA_WIDTH-1:0] X80_Y147_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X80_Y147_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) south_to_north_sector_size_0_south_to_north_ip_size_11_bus_first_egress_fifo(.clock(bus_clock),
		.in(X80_Y147_bus_rdata_in),
		.out(X80_Y147_bus_rdata_out));

	assign north_out_reg[0][10][10:0] = X80_Y147_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][11][10:2] = X80_Y147_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X80_Y147(.data(/* from design */),
		.q(X80_Y147_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X80_Y147_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X87_Y147@{N[0][15],N[0][16]}@0 */

	logic X87_Y147_incr_waddr; // ingress control
	logic X87_Y147_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) north_to_south_sector_size_0_north_to_south_ip_size_16_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][16][0]),
		.out(X87_Y147_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) north_to_south_sector_size_0_north_to_south_ip_size_16_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][16][1]),
		.out(X87_Y147_incr_raddr));

	logic [ADDR_WIDTH-1:0] X87_Y147_waddr;
	logic [ADDR_WIDTH-1:0] X87_Y147_raddr;

	/* positional aliases */

	wire X88_Y147_incr_waddr;
	assign X88_Y147_incr_waddr = X87_Y147_incr_waddr;
	wire [ADDR_WIDTH-1:0] X88_Y147_waddr;
	assign X88_Y147_waddr = X87_Y147_waddr;
	wire X88_Y146_incr_raddr;
	assign X88_Y146_incr_raddr = X87_Y147_incr_raddr;
	wire [ADDR_WIDTH-1:0] X88_Y146_raddr;
	assign X88_Y146_raddr = X87_Y147_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X87_Y147(.clk(bus_clock),
		.incr_waddr(X87_Y147_incr_waddr),
		.waddr(X87_Y147_waddr),
		.incr_raddr(X87_Y147_incr_raddr),
		.raddr(X87_Y147_raddr));


	/* generated from I@X88_Y147@{N[0][16],N[0][17]}@0 */

	logic [DATA_WIDTH-1:0] X88_Y147_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) north_to_south_sector_size_0_north_to_south_ip_size_17_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][16][10:0], north_in_reg[0][17][10:2]}),
		.out(X88_Y147_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X88_Y147(.data(X88_Y147_bus_wdata),
		.q(/* to design */),
		.wraddress(X88_Y147_waddr),
		.rdaddress(/* from design */),
		.wren(X88_Y147_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X90_Y147@{S[0][18],S[0][19]}@6 */

	logic [DATA_WIDTH-1:0] X90_Y147_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X90_Y147_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) south_to_north_sector_size_0_south_to_north_ip_size_19_bus_first_egress_fifo(.clock(bus_clock),
		.in(X90_Y147_bus_rdata_in),
		.out(X90_Y147_bus_rdata_out));

	assign north_out_reg[0][18][10:0] = X90_Y147_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][19][10:2] = X90_Y147_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X90_Y147(.data(/* from design */),
		.q(X90_Y147_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X90_Y147_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X103_Y147@{W[2][22],W[2][21]}@1 */

	logic X103_Y147_incr_waddr; // ingress control
	logic X103_Y147_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_21_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][21][0]),
		.out(X103_Y147_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_21_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][21][1]),
		.out(X103_Y147_incr_raddr));

	logic [ADDR_WIDTH-1:0] X103_Y147_waddr;
	logic [ADDR_WIDTH-1:0] X103_Y147_raddr;

	/* positional aliases */

	wire X104_Y147_incr_waddr;
	assign X104_Y147_incr_waddr = X103_Y147_incr_waddr;
	wire [ADDR_WIDTH-1:0] X104_Y147_waddr;
	assign X104_Y147_waddr = X103_Y147_waddr;
	wire X104_Y146_incr_raddr;
	assign X104_Y146_incr_raddr = X103_Y147_incr_raddr;
	wire [ADDR_WIDTH-1:0] X104_Y146_raddr;
	assign X104_Y146_raddr = X103_Y147_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X103_Y147(.clk(bus_clock),
		.incr_waddr(X103_Y147_incr_waddr),
		.waddr(X103_Y147_waddr),
		.incr_raddr(X103_Y147_incr_raddr),
		.raddr(X103_Y147_raddr));


	/* generated from I@X104_Y147@{W[2][22],W[2][21]}@1 */

	logic [DATA_WIDTH-1:0] X104_Y147_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_21_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][22][10:0], west_in_reg[2][21][10:2]}),
		.out(X104_Y147_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X104_Y147(.data(X104_Y147_bus_wdata),
		.q(/* to design */),
		.wraddress(X104_Y147_waddr),
		.rdaddress(/* from design */),
		.wren(X104_Y147_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from I@X172_Y147@{N[2][1],N[2][0]}@0 */

	logic [DATA_WIDTH-1:0] X172_Y147_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) north_to_south_sector_size_2_north_to_south_ip_size_0_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][1][10:0], north_in_reg[2][0][10:2]}),
		.out(X172_Y147_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X172_Y147(.data(X172_Y147_bus_wdata),
		.q(/* to design */),
		.wraddress(X172_Y147_waddr),
		.rdaddress(/* from design */),
		.wren(X172_Y147_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X173_Y147@{N[2][2],N[2][1]}@0 */

	logic X173_Y147_incr_waddr; // ingress control
	logic X173_Y147_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) north_to_south_sector_size_2_north_to_south_ip_size_1_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[2][2][0]),
		.out(X173_Y147_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) north_to_south_sector_size_2_north_to_south_ip_size_1_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[2][2][1]),
		.out(X173_Y147_incr_raddr));

	logic [ADDR_WIDTH-1:0] X173_Y147_waddr;
	logic [ADDR_WIDTH-1:0] X173_Y147_raddr;

	/* positional aliases */

	wire X172_Y147_incr_waddr;
	assign X172_Y147_incr_waddr = X173_Y147_incr_waddr;
	wire [ADDR_WIDTH-1:0] X172_Y147_waddr;
	assign X172_Y147_waddr = X173_Y147_waddr;
	wire X172_Y146_incr_raddr;
	assign X172_Y146_incr_raddr = X173_Y147_incr_raddr;
	wire [ADDR_WIDTH-1:0] X172_Y146_raddr;
	assign X172_Y146_raddr = X173_Y147_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X173_Y147(.clk(bus_clock),
		.incr_waddr(X173_Y147_incr_waddr),
		.waddr(X173_Y147_waddr),
		.incr_raddr(X173_Y147_incr_raddr),
		.raddr(X173_Y147_raddr));


	/* generated from E@X174_Y147@{S[2][3],S[2][2]}@6 */

	logic [DATA_WIDTH-1:0] X174_Y147_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X174_Y147_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) south_to_north_sector_size_2_south_to_north_ip_size_2_bus_first_egress_fifo(.clock(bus_clock),
		.in(X174_Y147_bus_rdata_in),
		.out(X174_Y147_bus_rdata_out));

	assign north_out_reg[2][3][10:0] = X174_Y147_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][2][10:2] = X174_Y147_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X174_Y147(.data(/* from design */),
		.q(X174_Y147_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X174_Y147_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X183_Y147@{N[2][9],N[2][8]}@0 */

	logic [DATA_WIDTH-1:0] X183_Y147_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) north_to_south_sector_size_2_north_to_south_ip_size_8_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][9][10:0], north_in_reg[2][8][10:2]}),
		.out(X183_Y147_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X183_Y147(.data(X183_Y147_bus_wdata),
		.q(/* to design */),
		.wraddress(X183_Y147_waddr),
		.rdaddress(/* from design */),
		.wren(X183_Y147_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X184_Y147@{N[2][10],N[2][9]}@0 */

	logic X184_Y147_incr_waddr; // ingress control
	logic X184_Y147_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) north_to_south_sector_size_2_north_to_south_ip_size_9_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[2][10][0]),
		.out(X184_Y147_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) north_to_south_sector_size_2_north_to_south_ip_size_9_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[2][10][1]),
		.out(X184_Y147_incr_raddr));

	logic [ADDR_WIDTH-1:0] X184_Y147_waddr;
	logic [ADDR_WIDTH-1:0] X184_Y147_raddr;

	/* positional aliases */

	wire X183_Y147_incr_waddr;
	assign X183_Y147_incr_waddr = X184_Y147_incr_waddr;
	wire [ADDR_WIDTH-1:0] X183_Y147_waddr;
	assign X183_Y147_waddr = X184_Y147_waddr;
	wire X183_Y146_incr_raddr;
	assign X183_Y146_incr_raddr = X184_Y147_incr_raddr;
	wire [ADDR_WIDTH-1:0] X183_Y146_raddr;
	assign X183_Y146_raddr = X184_Y147_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X184_Y147(.clk(bus_clock),
		.incr_waddr(X184_Y147_incr_waddr),
		.waddr(X184_Y147_waddr),
		.incr_raddr(X184_Y147_incr_raddr),
		.raddr(X184_Y147_raddr));


	/* generated from E@X185_Y147@{S[2][11],S[2][10]}@6 */

	logic [DATA_WIDTH-1:0] X185_Y147_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X185_Y147_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) south_to_north_sector_size_2_south_to_north_ip_size_10_bus_first_egress_fifo(.clock(bus_clock),
		.in(X185_Y147_bus_rdata_in),
		.out(X185_Y147_bus_rdata_out));

	assign north_out_reg[2][11][10:0] = X185_Y147_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][10][10:2] = X185_Y147_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X185_Y147(.data(/* from design */),
		.q(X185_Y147_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X185_Y147_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X194_Y147@{N[2][17],N[2][16]}@0 */

	logic [DATA_WIDTH-1:0] X194_Y147_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) north_to_south_sector_size_2_north_to_south_ip_size_16_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][17][10:0], north_in_reg[2][16][10:2]}),
		.out(X194_Y147_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X194_Y147(.data(X194_Y147_bus_wdata),
		.q(/* to design */),
		.wraddress(X194_Y147_waddr),
		.rdaddress(/* from design */),
		.wren(X194_Y147_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X195_Y147@{N[2][18],N[2][17]}@0 */

	logic X195_Y147_incr_waddr; // ingress control
	logic X195_Y147_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) north_to_south_sector_size_2_north_to_south_ip_size_17_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[2][18][0]),
		.out(X195_Y147_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) north_to_south_sector_size_2_north_to_south_ip_size_17_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[2][18][1]),
		.out(X195_Y147_incr_raddr));

	logic [ADDR_WIDTH-1:0] X195_Y147_waddr;
	logic [ADDR_WIDTH-1:0] X195_Y147_raddr;

	/* positional aliases */

	wire X194_Y147_incr_waddr;
	assign X194_Y147_incr_waddr = X195_Y147_incr_waddr;
	wire [ADDR_WIDTH-1:0] X194_Y147_waddr;
	assign X194_Y147_waddr = X195_Y147_waddr;
	wire X194_Y146_incr_raddr;
	assign X194_Y146_incr_raddr = X195_Y147_incr_raddr;
	wire [ADDR_WIDTH-1:0] X194_Y146_raddr;
	assign X194_Y146_raddr = X195_Y147_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X195_Y147(.clk(bus_clock),
		.incr_waddr(X195_Y147_incr_waddr),
		.waddr(X195_Y147_waddr),
		.incr_raddr(X195_Y147_incr_raddr),
		.raddr(X195_Y147_raddr));


	/* generated from E@X196_Y147@{S[2][19],S[2][18]}@6 */

	logic [DATA_WIDTH-1:0] X196_Y147_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X196_Y147_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) south_to_north_sector_size_2_south_to_north_ip_size_18_bus_first_egress_fifo(.clock(bus_clock),
		.in(X196_Y147_bus_rdata_in),
		.out(X196_Y147_bus_rdata_out));

	assign north_out_reg[2][19][10:0] = X196_Y147_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][18][10:2] = X196_Y147_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X196_Y147(.data(/* from design */),
		.q(X196_Y147_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X196_Y147_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X206_Y147@{E[2][22],E[2][21]}@1 */

	logic [DATA_WIDTH-1:0] X206_Y147_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_21_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][22][10:0], east_in_reg[2][21][10:2]}),
		.out(X206_Y147_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X206_Y147(.data(X206_Y147_bus_wdata),
		.q(/* to design */),
		.wraddress(X206_Y147_waddr),
		.rdaddress(/* from design */),
		.wren(X206_Y147_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X207_Y147@{E[2][22],E[2][21]}@1 */

	logic X207_Y147_incr_waddr; // ingress control
	logic X207_Y147_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_21_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][22][0]),
		.out(X207_Y147_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_21_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][22][1]),
		.out(X207_Y147_incr_raddr));

	logic [ADDR_WIDTH-1:0] X207_Y147_waddr;
	logic [ADDR_WIDTH-1:0] X207_Y147_raddr;

	/* positional aliases */

	wire X206_Y147_incr_waddr;
	assign X206_Y147_incr_waddr = X207_Y147_incr_waddr;
	wire [ADDR_WIDTH-1:0] X206_Y147_waddr;
	assign X206_Y147_waddr = X207_Y147_waddr;
	wire X206_Y146_incr_raddr;
	assign X206_Y146_incr_raddr = X207_Y147_incr_raddr;
	wire [ADDR_WIDTH-1:0] X206_Y146_raddr;
	assign X206_Y146_raddr = X207_Y147_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X207_Y147(.clk(bus_clock),
		.incr_waddr(X207_Y147_incr_waddr),
		.waddr(X207_Y147_waddr),
		.incr_raddr(X207_Y147_incr_raddr),
		.raddr(X207_Y147_raddr));


	/* generated from I@X215_Y147@{N[2][33],N[2][32]}@0 */

	logic [DATA_WIDTH-1:0] X215_Y147_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) north_to_south_sector_size_2_north_to_south_ip_size_32_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][33][10:0], north_in_reg[2][32][10:2]}),
		.out(X215_Y147_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X215_Y147(.data(X215_Y147_bus_wdata),
		.q(/* to design */),
		.wraddress(X215_Y147_waddr),
		.rdaddress(/* from design */),
		.wren(X215_Y147_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X216_Y147@{N[2][34],N[2][33]}@0 */

	logic X216_Y147_incr_waddr; // ingress control
	logic X216_Y147_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) north_to_south_sector_size_2_north_to_south_ip_size_33_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[2][34][0]),
		.out(X216_Y147_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) north_to_south_sector_size_2_north_to_south_ip_size_33_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[2][34][1]),
		.out(X216_Y147_incr_raddr));

	logic [ADDR_WIDTH-1:0] X216_Y147_waddr;
	logic [ADDR_WIDTH-1:0] X216_Y147_raddr;

	/* positional aliases */

	wire X215_Y147_incr_waddr;
	assign X215_Y147_incr_waddr = X216_Y147_incr_waddr;
	wire [ADDR_WIDTH-1:0] X215_Y147_waddr;
	assign X215_Y147_waddr = X216_Y147_waddr;
	wire X215_Y146_incr_raddr;
	assign X215_Y146_incr_raddr = X216_Y147_incr_raddr;
	wire [ADDR_WIDTH-1:0] X215_Y146_raddr;
	assign X215_Y146_raddr = X216_Y147_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X216_Y147(.clk(bus_clock),
		.incr_waddr(X216_Y147_incr_waddr),
		.waddr(X216_Y147_waddr),
		.incr_raddr(X216_Y147_incr_raddr),
		.raddr(X216_Y147_raddr));


	/* generated from E@X217_Y147@{S[2][35],S[2][34]}@6 */

	logic [DATA_WIDTH-1:0] X217_Y147_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X217_Y147_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) south_to_north_sector_size_2_south_to_north_ip_size_34_bus_first_egress_fifo(.clock(bus_clock),
		.in(X217_Y147_bus_rdata_in),
		.out(X217_Y147_bus_rdata_out));

	assign north_out_reg[2][35][10:0] = X217_Y147_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][34][10:2] = X217_Y147_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X217_Y147(.data(/* from design */),
		.q(X217_Y147_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X217_Y147_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X67_Y146@{N[0][0],N[0][1]}@1 */

	logic [DATA_WIDTH-1:0] X67_Y146_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X67_Y146_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) north_to_south_sector_size_0_north_to_south_ip_size_1_bus_first_egress_fifo(.clock(bus_clock),
		.in(X67_Y146_bus_rdata_in),
		.out(X67_Y146_bus_rdata_out));

	assign south_out_reg[0][0][10:0] = X67_Y146_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][1][10:2] = X67_Y146_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X67_Y146(.data(/* from design */),
		.q(X67_Y146_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X67_Y146_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X68_Y146@{S[0][1],S[0][2]}@5 */

	logic X68_Y146_incr_waddr; // ingress control
	logic X68_Y146_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) south_to_north_sector_size_0_south_to_north_ip_size_2_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][2][0]),
		.out(X68_Y146_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) south_to_north_sector_size_0_south_to_north_ip_size_2_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][2][1]),
		.out(X68_Y146_incr_raddr));

	logic [ADDR_WIDTH-1:0] X68_Y146_waddr;
	logic [ADDR_WIDTH-1:0] X68_Y146_raddr;

	/* positional aliases */

	wire X69_Y146_incr_waddr;
	assign X69_Y146_incr_waddr = X68_Y146_incr_waddr;
	wire [ADDR_WIDTH-1:0] X69_Y146_waddr;
	assign X69_Y146_waddr = X68_Y146_waddr;
	wire X69_Y147_incr_raddr;
	assign X69_Y147_incr_raddr = X68_Y146_incr_raddr;
	wire [ADDR_WIDTH-1:0] X69_Y147_raddr;
	assign X69_Y147_raddr = X68_Y146_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X68_Y146(.clk(bus_clock),
		.incr_waddr(X68_Y146_incr_waddr),
		.waddr(X68_Y146_waddr),
		.incr_raddr(X68_Y146_incr_raddr),
		.raddr(X68_Y146_raddr));


	/* generated from I@X69_Y146@{S[0][2],S[0][3]}@5 */

	logic [DATA_WIDTH-1:0] X69_Y146_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) south_to_north_sector_size_0_south_to_north_ip_size_3_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][2][10:0], south_in_reg[0][3][10:2]}),
		.out(X69_Y146_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X69_Y146(.data(X69_Y146_bus_wdata),
		.q(/* to design */),
		.wraddress(X69_Y146_waddr),
		.rdaddress(/* from design */),
		.wren(X69_Y146_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X78_Y146@{N[0][8],N[0][9]}@1 */

	logic [DATA_WIDTH-1:0] X78_Y146_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X78_Y146_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) north_to_south_sector_size_0_north_to_south_ip_size_9_bus_first_egress_fifo(.clock(bus_clock),
		.in(X78_Y146_bus_rdata_in),
		.out(X78_Y146_bus_rdata_out));

	assign south_out_reg[0][8][10:0] = X78_Y146_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][9][10:2] = X78_Y146_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X78_Y146(.data(/* from design */),
		.q(X78_Y146_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X78_Y146_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X79_Y146@{S[0][9],S[0][10]}@5 */

	logic X79_Y146_incr_waddr; // ingress control
	logic X79_Y146_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) south_to_north_sector_size_0_south_to_north_ip_size_10_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][10][0]),
		.out(X79_Y146_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) south_to_north_sector_size_0_south_to_north_ip_size_10_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][10][1]),
		.out(X79_Y146_incr_raddr));

	logic [ADDR_WIDTH-1:0] X79_Y146_waddr;
	logic [ADDR_WIDTH-1:0] X79_Y146_raddr;

	/* positional aliases */

	wire X80_Y146_incr_waddr;
	assign X80_Y146_incr_waddr = X79_Y146_incr_waddr;
	wire [ADDR_WIDTH-1:0] X80_Y146_waddr;
	assign X80_Y146_waddr = X79_Y146_waddr;
	wire X80_Y147_incr_raddr;
	assign X80_Y147_incr_raddr = X79_Y146_incr_raddr;
	wire [ADDR_WIDTH-1:0] X80_Y147_raddr;
	assign X80_Y147_raddr = X79_Y146_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X79_Y146(.clk(bus_clock),
		.incr_waddr(X79_Y146_incr_waddr),
		.waddr(X79_Y146_waddr),
		.incr_raddr(X79_Y146_incr_raddr),
		.raddr(X79_Y146_raddr));


	/* generated from I@X80_Y146@{S[0][10],S[0][11]}@5 */

	logic [DATA_WIDTH-1:0] X80_Y146_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) south_to_north_sector_size_0_south_to_north_ip_size_11_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][10][10:0], south_in_reg[0][11][10:2]}),
		.out(X80_Y146_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X80_Y146(.data(X80_Y146_bus_wdata),
		.q(/* to design */),
		.wraddress(X80_Y146_waddr),
		.rdaddress(/* from design */),
		.wren(X80_Y146_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X88_Y146@{N[0][16],N[0][17]}@1 */

	logic [DATA_WIDTH-1:0] X88_Y146_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X88_Y146_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) north_to_south_sector_size_0_north_to_south_ip_size_17_bus_first_egress_fifo(.clock(bus_clock),
		.in(X88_Y146_bus_rdata_in),
		.out(X88_Y146_bus_rdata_out));

	assign south_out_reg[0][16][10:0] = X88_Y146_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][17][10:2] = X88_Y146_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X88_Y146(.data(/* from design */),
		.q(X88_Y146_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X88_Y146_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X89_Y146@{S[0][17],S[0][18]}@5 */

	logic X89_Y146_incr_waddr; // ingress control
	logic X89_Y146_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) south_to_north_sector_size_0_south_to_north_ip_size_18_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][18][0]),
		.out(X89_Y146_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) south_to_north_sector_size_0_south_to_north_ip_size_18_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][18][1]),
		.out(X89_Y146_incr_raddr));

	logic [ADDR_WIDTH-1:0] X89_Y146_waddr;
	logic [ADDR_WIDTH-1:0] X89_Y146_raddr;

	/* positional aliases */

	wire X90_Y146_incr_waddr;
	assign X90_Y146_incr_waddr = X89_Y146_incr_waddr;
	wire [ADDR_WIDTH-1:0] X90_Y146_waddr;
	assign X90_Y146_waddr = X89_Y146_waddr;
	wire X90_Y147_incr_raddr;
	assign X90_Y147_incr_raddr = X89_Y146_incr_raddr;
	wire [ADDR_WIDTH-1:0] X90_Y147_raddr;
	assign X90_Y147_raddr = X89_Y146_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X89_Y146(.clk(bus_clock),
		.incr_waddr(X89_Y146_incr_waddr),
		.waddr(X89_Y146_waddr),
		.incr_raddr(X89_Y146_incr_raddr),
		.raddr(X89_Y146_raddr));


	/* generated from I@X90_Y146@{S[0][18],S[0][19]}@5 */

	logic [DATA_WIDTH-1:0] X90_Y146_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) south_to_north_sector_size_0_south_to_north_ip_size_19_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][18][10:0], south_in_reg[0][19][10:2]}),
		.out(X90_Y146_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X90_Y146(.data(X90_Y146_bus_wdata),
		.q(/* to design */),
		.wraddress(X90_Y146_waddr),
		.rdaddress(/* from design */),
		.wren(X90_Y146_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X104_Y146@{W[2][22],W[2][21]}@2 */

	logic [DATA_WIDTH-1:0] X104_Y146_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X104_Y146_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_2_west_to_east_ip_size_21_bus_first_egress_fifo(.clock(bus_clock),
		.in(X104_Y146_bus_rdata_in),
		.out(X104_Y146_bus_rdata_out));

	assign east_out_reg[2][22][10:0] = X104_Y146_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][21][10:2] = X104_Y146_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X104_Y146(.data(/* from design */),
		.q(X104_Y146_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X104_Y146_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X172_Y146@{N[2][1],N[2][0]}@1 */

	logic [DATA_WIDTH-1:0] X172_Y146_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X172_Y146_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) north_to_south_sector_size_2_north_to_south_ip_size_0_bus_first_egress_fifo(.clock(bus_clock),
		.in(X172_Y146_bus_rdata_in),
		.out(X172_Y146_bus_rdata_out));

	assign south_out_reg[2][1][10:0] = X172_Y146_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][0][10:2] = X172_Y146_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X172_Y146(.data(/* from design */),
		.q(X172_Y146_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X172_Y146_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X174_Y146@{S[2][3],S[2][2]}@5 */

	logic [DATA_WIDTH-1:0] X174_Y146_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) south_to_north_sector_size_2_south_to_north_ip_size_2_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][3][10:0], south_in_reg[2][2][10:2]}),
		.out(X174_Y146_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X174_Y146(.data(X174_Y146_bus_wdata),
		.q(/* to design */),
		.wraddress(X174_Y146_waddr),
		.rdaddress(/* from design */),
		.wren(X174_Y146_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X175_Y146@{S[2][4],S[2][3]}@5 */

	logic X175_Y146_incr_waddr; // ingress control
	logic X175_Y146_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) south_to_north_sector_size_2_south_to_north_ip_size_3_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[2][4][0]),
		.out(X175_Y146_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) south_to_north_sector_size_2_south_to_north_ip_size_3_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[2][4][1]),
		.out(X175_Y146_incr_raddr));

	logic [ADDR_WIDTH-1:0] X175_Y146_waddr;
	logic [ADDR_WIDTH-1:0] X175_Y146_raddr;

	/* positional aliases */

	wire X174_Y146_incr_waddr;
	assign X174_Y146_incr_waddr = X175_Y146_incr_waddr;
	wire [ADDR_WIDTH-1:0] X174_Y146_waddr;
	assign X174_Y146_waddr = X175_Y146_waddr;
	wire X174_Y147_incr_raddr;
	assign X174_Y147_incr_raddr = X175_Y146_incr_raddr;
	wire [ADDR_WIDTH-1:0] X174_Y147_raddr;
	assign X174_Y147_raddr = X175_Y146_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X175_Y146(.clk(bus_clock),
		.incr_waddr(X175_Y146_incr_waddr),
		.waddr(X175_Y146_waddr),
		.incr_raddr(X175_Y146_incr_raddr),
		.raddr(X175_Y146_raddr));


	/* generated from E@X183_Y146@{N[2][9],N[2][8]}@1 */

	logic [DATA_WIDTH-1:0] X183_Y146_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X183_Y146_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) north_to_south_sector_size_2_north_to_south_ip_size_8_bus_first_egress_fifo(.clock(bus_clock),
		.in(X183_Y146_bus_rdata_in),
		.out(X183_Y146_bus_rdata_out));

	assign south_out_reg[2][9][10:0] = X183_Y146_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][8][10:2] = X183_Y146_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X183_Y146(.data(/* from design */),
		.q(X183_Y146_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X183_Y146_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X185_Y146@{S[2][11],S[2][10]}@5 */

	logic [DATA_WIDTH-1:0] X185_Y146_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) south_to_north_sector_size_2_south_to_north_ip_size_10_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][11][10:0], south_in_reg[2][10][10:2]}),
		.out(X185_Y146_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X185_Y146(.data(X185_Y146_bus_wdata),
		.q(/* to design */),
		.wraddress(X185_Y146_waddr),
		.rdaddress(/* from design */),
		.wren(X185_Y146_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X186_Y146@{S[2][12],S[2][11]}@5 */

	logic X186_Y146_incr_waddr; // ingress control
	logic X186_Y146_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) south_to_north_sector_size_2_south_to_north_ip_size_11_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[2][12][0]),
		.out(X186_Y146_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) south_to_north_sector_size_2_south_to_north_ip_size_11_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[2][12][1]),
		.out(X186_Y146_incr_raddr));

	logic [ADDR_WIDTH-1:0] X186_Y146_waddr;
	logic [ADDR_WIDTH-1:0] X186_Y146_raddr;

	/* positional aliases */

	wire X185_Y146_incr_waddr;
	assign X185_Y146_incr_waddr = X186_Y146_incr_waddr;
	wire [ADDR_WIDTH-1:0] X185_Y146_waddr;
	assign X185_Y146_waddr = X186_Y146_waddr;
	wire X185_Y147_incr_raddr;
	assign X185_Y147_incr_raddr = X186_Y146_incr_raddr;
	wire [ADDR_WIDTH-1:0] X185_Y147_raddr;
	assign X185_Y147_raddr = X186_Y146_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X186_Y146(.clk(bus_clock),
		.incr_waddr(X186_Y146_incr_waddr),
		.waddr(X186_Y146_waddr),
		.incr_raddr(X186_Y146_incr_raddr),
		.raddr(X186_Y146_raddr));


	/* generated from E@X194_Y146@{N[2][17],N[2][16]}@1 */

	logic [DATA_WIDTH-1:0] X194_Y146_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X194_Y146_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) north_to_south_sector_size_2_north_to_south_ip_size_16_bus_first_egress_fifo(.clock(bus_clock),
		.in(X194_Y146_bus_rdata_in),
		.out(X194_Y146_bus_rdata_out));

	assign south_out_reg[2][17][10:0] = X194_Y146_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][16][10:2] = X194_Y146_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X194_Y146(.data(/* from design */),
		.q(X194_Y146_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X194_Y146_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X196_Y146@{S[2][19],S[2][18]}@5 */

	logic [DATA_WIDTH-1:0] X196_Y146_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) south_to_north_sector_size_2_south_to_north_ip_size_18_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][19][10:0], south_in_reg[2][18][10:2]}),
		.out(X196_Y146_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X196_Y146(.data(X196_Y146_bus_wdata),
		.q(/* to design */),
		.wraddress(X196_Y146_waddr),
		.rdaddress(/* from design */),
		.wren(X196_Y146_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X197_Y146@{S[2][20],S[2][19]}@5 */

	logic X197_Y146_incr_waddr; // ingress control
	logic X197_Y146_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) south_to_north_sector_size_2_south_to_north_ip_size_19_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[2][20][0]),
		.out(X197_Y146_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) south_to_north_sector_size_2_south_to_north_ip_size_19_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[2][20][1]),
		.out(X197_Y146_incr_raddr));

	logic [ADDR_WIDTH-1:0] X197_Y146_waddr;
	logic [ADDR_WIDTH-1:0] X197_Y146_raddr;

	/* positional aliases */

	wire X196_Y146_incr_waddr;
	assign X196_Y146_incr_waddr = X197_Y146_incr_waddr;
	wire [ADDR_WIDTH-1:0] X196_Y146_waddr;
	assign X196_Y146_waddr = X197_Y146_waddr;
	wire X196_Y147_incr_raddr;
	assign X196_Y147_incr_raddr = X197_Y146_incr_raddr;
	wire [ADDR_WIDTH-1:0] X196_Y147_raddr;
	assign X196_Y147_raddr = X197_Y146_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X197_Y146(.clk(bus_clock),
		.incr_waddr(X197_Y146_incr_waddr),
		.waddr(X197_Y146_waddr),
		.incr_raddr(X197_Y146_incr_raddr),
		.raddr(X197_Y146_raddr));


	/* generated from E@X206_Y146@{E[2][22],E[2][21]}@2 */

	logic [DATA_WIDTH-1:0] X206_Y146_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X206_Y146_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_21_bus_first_egress_fifo(.clock(bus_clock),
		.in(X206_Y146_bus_rdata_in),
		.out(X206_Y146_bus_rdata_out));

	assign west_out_reg[2][22][10:0] = X206_Y146_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][21][10:2] = X206_Y146_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X206_Y146(.data(/* from design */),
		.q(X206_Y146_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X206_Y146_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X215_Y146@{N[2][33],N[2][32]}@1 */

	logic [DATA_WIDTH-1:0] X215_Y146_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X215_Y146_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) north_to_south_sector_size_2_north_to_south_ip_size_32_bus_first_egress_fifo(.clock(bus_clock),
		.in(X215_Y146_bus_rdata_in),
		.out(X215_Y146_bus_rdata_out));

	assign south_out_reg[2][33][10:0] = X215_Y146_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][32][10:2] = X215_Y146_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X215_Y146(.data(/* from design */),
		.q(X215_Y146_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X215_Y146_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X217_Y146@{S[2][35],S[2][34]}@5 */

	logic [DATA_WIDTH-1:0] X217_Y146_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) south_to_north_sector_size_2_south_to_north_ip_size_34_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][35][10:0], south_in_reg[2][34][10:2]}),
		.out(X217_Y146_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X217_Y146(.data(X217_Y146_bus_wdata),
		.q(/* to design */),
		.wraddress(X217_Y146_waddr),
		.rdaddress(/* from design */),
		.wren(X217_Y146_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X218_Y146@{S[2][36],S[2][35]}@5 */

	logic X218_Y146_incr_waddr; // ingress control
	logic X218_Y146_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) south_to_north_sector_size_2_south_to_north_ip_size_35_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[2][36][0]),
		.out(X218_Y146_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) south_to_north_sector_size_2_south_to_north_ip_size_35_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[2][36][1]),
		.out(X218_Y146_incr_raddr));

	logic [ADDR_WIDTH-1:0] X218_Y146_waddr;
	logic [ADDR_WIDTH-1:0] X218_Y146_raddr;

	/* positional aliases */

	wire X217_Y146_incr_waddr;
	assign X217_Y146_incr_waddr = X218_Y146_incr_waddr;
	wire [ADDR_WIDTH-1:0] X217_Y146_waddr;
	assign X217_Y146_waddr = X218_Y146_waddr;
	wire X217_Y147_incr_raddr;
	assign X217_Y147_incr_raddr = X218_Y146_incr_raddr;
	wire [ADDR_WIDTH-1:0] X217_Y147_raddr;
	assign X217_Y147_raddr = X218_Y146_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X218_Y146(.clk(bus_clock),
		.incr_waddr(X218_Y146_incr_waddr),
		.waddr(X218_Y146_waddr),
		.incr_raddr(X218_Y146_incr_raddr),
		.raddr(X218_Y146_raddr));


	/* generated from I@X153_Y145@{E[2][20],E[2][19]}@3 */

	logic [DATA_WIDTH-1:0] X153_Y145_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) east_to_west_sector_size_2_east_to_west_ip_size_19_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][20][10:0], east_in_reg[2][19][10:2]}),
		.out(X153_Y145_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X153_Y145(.data(X153_Y145_bus_wdata),
		.q(/* to design */),
		.wraddress(X153_Y145_waddr),
		.rdaddress(/* from design */),
		.wren(X153_Y145_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X154_Y145@{E[2][20],E[2][19]}@3 */

	logic X154_Y145_incr_waddr; // ingress control
	logic X154_Y145_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) east_to_west_sector_size_2_east_to_west_ip_size_19_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][19][0]),
		.out(X154_Y145_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) east_to_west_sector_size_2_east_to_west_ip_size_19_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][19][1]),
		.out(X154_Y145_incr_raddr));

	logic [ADDR_WIDTH-1:0] X154_Y145_waddr;
	logic [ADDR_WIDTH-1:0] X154_Y145_raddr;

	/* positional aliases */

	wire X153_Y145_incr_waddr;
	assign X153_Y145_incr_waddr = X154_Y145_incr_waddr;
	wire [ADDR_WIDTH-1:0] X153_Y145_waddr;
	assign X153_Y145_waddr = X154_Y145_waddr;
	wire X153_Y144_incr_raddr;
	assign X153_Y144_incr_raddr = X154_Y145_incr_raddr;
	wire [ADDR_WIDTH-1:0] X153_Y144_raddr;
	assign X153_Y144_raddr = X154_Y145_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X154_Y145(.clk(bus_clock),
		.incr_waddr(X154_Y145_incr_waddr),
		.waddr(X154_Y145_waddr),
		.incr_raddr(X154_Y145_incr_raddr),
		.raddr(X154_Y145_raddr));


	/* generated from C@X238_Y145@{W[2][20],W[2][19]}@4 */

	logic X238_Y145_incr_waddr; // ingress control
	logic X238_Y145_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) west_to_east_sector_size_2_west_to_east_ip_size_19_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][20][0]),
		.out(X238_Y145_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) west_to_east_sector_size_2_west_to_east_ip_size_19_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][20][1]),
		.out(X238_Y145_incr_raddr));

	logic [ADDR_WIDTH-1:0] X238_Y145_waddr;
	logic [ADDR_WIDTH-1:0] X238_Y145_raddr;

	/* positional aliases */

	wire X239_Y145_incr_waddr;
	assign X239_Y145_incr_waddr = X238_Y145_incr_waddr;
	wire [ADDR_WIDTH-1:0] X239_Y145_waddr;
	assign X239_Y145_waddr = X238_Y145_waddr;
	wire X239_Y144_incr_raddr;
	assign X239_Y144_incr_raddr = X238_Y145_incr_raddr;
	wire [ADDR_WIDTH-1:0] X239_Y144_raddr;
	assign X239_Y144_raddr = X238_Y145_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X238_Y145(.clk(bus_clock),
		.incr_waddr(X238_Y145_incr_waddr),
		.waddr(X238_Y145_waddr),
		.incr_raddr(X238_Y145_incr_raddr),
		.raddr(X238_Y145_raddr));


	/* generated from I@X239_Y145@{W[2][20],W[2][19]}@4 */

	logic [DATA_WIDTH-1:0] X239_Y145_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_2_west_to_east_ip_size_19_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][20][10:0], west_in_reg[2][19][10:2]}),
		.out(X239_Y145_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X239_Y145(.data(X239_Y145_bus_wdata),
		.q(/* to design */),
		.wraddress(X239_Y145_waddr),
		.rdaddress(/* from design */),
		.wren(X239_Y145_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X153_Y144@{E[2][20],E[2][19]}@4 */

	logic [DATA_WIDTH-1:0] X153_Y144_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X153_Y144_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) east_to_west_sector_size_2_east_to_west_ip_size_19_bus_first_egress_fifo(.clock(bus_clock),
		.in(X153_Y144_bus_rdata_in),
		.out(X153_Y144_bus_rdata_out));

	assign west_out_reg[2][20][10:0] = X153_Y144_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][19][10:2] = X153_Y144_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X153_Y144(.data(/* from design */),
		.q(X153_Y144_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X153_Y144_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X239_Y144@{W[2][20],W[2][19]}@5 */

	logic [DATA_WIDTH-1:0] X239_Y144_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X239_Y144_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_19_bus_first_egress_fifo(.clock(bus_clock),
		.in(X239_Y144_bus_rdata_in),
		.out(X239_Y144_bus_rdata_out));

	assign east_out_reg[2][20][10:0] = X239_Y144_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][19][10:2] = X239_Y144_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X239_Y144(.data(/* from design */),
		.q(X239_Y144_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X239_Y144_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X120_Y143@{N[0][39],N[1][0]}@1 */

	logic X120_Y143_incr_waddr; // ingress control
	logic X120_Y143_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_1_north_to_south_ip_size_0_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][0][0]),
		.out(X120_Y143_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_1_north_to_south_ip_size_0_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][0][1]),
		.out(X120_Y143_incr_raddr));

	logic [ADDR_WIDTH-1:0] X120_Y143_waddr;
	logic [ADDR_WIDTH-1:0] X120_Y143_raddr;

	/* positional aliases */

	wire X121_Y143_incr_waddr;
	assign X121_Y143_incr_waddr = X120_Y143_incr_waddr;
	wire [ADDR_WIDTH-1:0] X121_Y143_waddr;
	assign X121_Y143_waddr = X120_Y143_waddr;
	wire X121_Y142_incr_raddr;
	assign X121_Y142_incr_raddr = X120_Y143_incr_raddr;
	wire [ADDR_WIDTH-1:0] X121_Y142_raddr;
	assign X121_Y142_raddr = X120_Y143_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X120_Y143(.clk(bus_clock),
		.incr_waddr(X120_Y143_incr_waddr),
		.waddr(X120_Y143_waddr),
		.incr_raddr(X120_Y143_incr_raddr),
		.raddr(X120_Y143_raddr));


	/* generated from I@X121_Y143@{N[1][0],N[1][1]}@1 */

	logic [DATA_WIDTH-1:0] X121_Y143_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_1_north_to_south_ip_size_1_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][0][10:0], north_in_reg[1][1][10:2]}),
		.out(X121_Y143_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X121_Y143(.data(X121_Y143_bus_wdata),
		.q(/* to design */),
		.wraddress(X121_Y143_waddr),
		.rdaddress(/* from design */),
		.wren(X121_Y143_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X123_Y143@{S[1][2],S[1][3]}@5 */

	logic [DATA_WIDTH-1:0] X123_Y143_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X123_Y143_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_1_south_to_north_ip_size_3_bus_first_egress_fifo(.clock(bus_clock),
		.in(X123_Y143_bus_rdata_in),
		.out(X123_Y143_bus_rdata_out));

	assign north_out_reg[1][2][10:0] = X123_Y143_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][3][10:2] = X123_Y143_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X123_Y143(.data(/* from design */),
		.q(X123_Y143_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X123_Y143_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X131_Y143@{N[1][7],N[1][8]}@1 */

	logic X131_Y143_incr_waddr; // ingress control
	logic X131_Y143_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_1_north_to_south_ip_size_8_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][8][0]),
		.out(X131_Y143_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_1_north_to_south_ip_size_8_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][8][1]),
		.out(X131_Y143_incr_raddr));

	logic [ADDR_WIDTH-1:0] X131_Y143_waddr;
	logic [ADDR_WIDTH-1:0] X131_Y143_raddr;

	/* positional aliases */

	wire X132_Y143_incr_waddr;
	assign X132_Y143_incr_waddr = X131_Y143_incr_waddr;
	wire [ADDR_WIDTH-1:0] X132_Y143_waddr;
	assign X132_Y143_waddr = X131_Y143_waddr;
	wire X132_Y142_incr_raddr;
	assign X132_Y142_incr_raddr = X131_Y143_incr_raddr;
	wire [ADDR_WIDTH-1:0] X132_Y142_raddr;
	assign X132_Y142_raddr = X131_Y143_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X131_Y143(.clk(bus_clock),
		.incr_waddr(X131_Y143_incr_waddr),
		.waddr(X131_Y143_waddr),
		.incr_raddr(X131_Y143_incr_raddr),
		.raddr(X131_Y143_raddr));


	/* generated from I@X132_Y143@{N[1][8],N[1][9]}@1 */

	logic [DATA_WIDTH-1:0] X132_Y143_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_1_north_to_south_ip_size_9_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][8][10:0], north_in_reg[1][9][10:2]}),
		.out(X132_Y143_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X132_Y143(.data(X132_Y143_bus_wdata),
		.q(/* to design */),
		.wraddress(X132_Y143_waddr),
		.rdaddress(/* from design */),
		.wren(X132_Y143_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X134_Y143@{S[1][10],S[1][11]}@5 */

	logic [DATA_WIDTH-1:0] X134_Y143_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X134_Y143_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_1_south_to_north_ip_size_11_bus_first_egress_fifo(.clock(bus_clock),
		.in(X134_Y143_bus_rdata_in),
		.out(X134_Y143_bus_rdata_out));

	assign north_out_reg[1][10][10:0] = X134_Y143_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][11][10:2] = X134_Y143_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X134_Y143(.data(/* from design */),
		.q(X134_Y143_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X134_Y143_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X141_Y143@{N[1][15],N[1][16]}@1 */

	logic X141_Y143_incr_waddr; // ingress control
	logic X141_Y143_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_1_north_to_south_ip_size_16_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][16][0]),
		.out(X141_Y143_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_1_north_to_south_ip_size_16_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][16][1]),
		.out(X141_Y143_incr_raddr));

	logic [ADDR_WIDTH-1:0] X141_Y143_waddr;
	logic [ADDR_WIDTH-1:0] X141_Y143_raddr;

	/* positional aliases */

	wire X142_Y143_incr_waddr;
	assign X142_Y143_incr_waddr = X141_Y143_incr_waddr;
	wire [ADDR_WIDTH-1:0] X142_Y143_waddr;
	assign X142_Y143_waddr = X141_Y143_waddr;
	wire X142_Y142_incr_raddr;
	assign X142_Y142_incr_raddr = X141_Y143_incr_raddr;
	wire [ADDR_WIDTH-1:0] X142_Y142_raddr;
	assign X142_Y142_raddr = X141_Y143_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X141_Y143(.clk(bus_clock),
		.incr_waddr(X141_Y143_incr_waddr),
		.waddr(X141_Y143_waddr),
		.incr_raddr(X141_Y143_incr_raddr),
		.raddr(X141_Y143_raddr));


	/* generated from I@X142_Y143@{N[1][16],N[1][17]}@1 */

	logic [DATA_WIDTH-1:0] X142_Y143_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_1_north_to_south_ip_size_17_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][16][10:0], north_in_reg[1][17][10:2]}),
		.out(X142_Y143_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X142_Y143(.data(X142_Y143_bus_wdata),
		.q(/* to design */),
		.wraddress(X142_Y143_waddr),
		.rdaddress(/* from design */),
		.wren(X142_Y143_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X144_Y143@{S[1][18],S[1][19]}@5 */

	logic [DATA_WIDTH-1:0] X144_Y143_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X144_Y143_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_1_south_to_north_ip_size_19_bus_first_egress_fifo(.clock(bus_clock),
		.in(X144_Y143_bus_rdata_in),
		.out(X144_Y143_bus_rdata_out));

	assign north_out_reg[1][18][10:0] = X144_Y143_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][19][10:2] = X144_Y143_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X144_Y143(.data(/* from design */),
		.q(X144_Y143_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X144_Y143_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X152_Y143@{W[2][18],W[2][17]}@2 */

	logic X152_Y143_incr_waddr; // ingress control
	logic X152_Y143_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) west_to_east_sector_size_2_west_to_east_ip_size_17_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][17][0]),
		.out(X152_Y143_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) west_to_east_sector_size_2_west_to_east_ip_size_17_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][17][1]),
		.out(X152_Y143_incr_raddr));

	logic [ADDR_WIDTH-1:0] X152_Y143_waddr;
	logic [ADDR_WIDTH-1:0] X152_Y143_raddr;

	/* positional aliases */

	wire X153_Y143_incr_waddr;
	assign X153_Y143_incr_waddr = X152_Y143_incr_waddr;
	wire [ADDR_WIDTH-1:0] X153_Y143_waddr;
	assign X153_Y143_waddr = X152_Y143_waddr;
	wire X153_Y142_incr_raddr;
	assign X153_Y142_incr_raddr = X152_Y143_incr_raddr;
	wire [ADDR_WIDTH-1:0] X153_Y142_raddr;
	assign X153_Y142_raddr = X152_Y143_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X152_Y143(.clk(bus_clock),
		.incr_waddr(X152_Y143_incr_waddr),
		.waddr(X152_Y143_waddr),
		.incr_raddr(X152_Y143_incr_raddr),
		.raddr(X152_Y143_raddr));


	/* generated from I@X153_Y143@{W[2][18],W[2][17]}@2 */

	logic [DATA_WIDTH-1:0] X153_Y143_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) west_to_east_sector_size_2_west_to_east_ip_size_17_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][18][10:0], west_in_reg[2][17][10:2]}),
		.out(X153_Y143_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X153_Y143(.data(X153_Y143_bus_wdata),
		.q(/* to design */),
		.wraddress(X153_Y143_waddr),
		.rdaddress(/* from design */),
		.wren(X153_Y143_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X163_Y143@{N[1][31],N[1][32]}@1 */

	logic X163_Y143_incr_waddr; // ingress control
	logic X163_Y143_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_1_north_to_south_ip_size_32_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][32][0]),
		.out(X163_Y143_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_1_north_to_south_ip_size_32_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][32][1]),
		.out(X163_Y143_incr_raddr));

	logic [ADDR_WIDTH-1:0] X163_Y143_waddr;
	logic [ADDR_WIDTH-1:0] X163_Y143_raddr;

	/* positional aliases */

	wire X164_Y143_incr_waddr;
	assign X164_Y143_incr_waddr = X163_Y143_incr_waddr;
	wire [ADDR_WIDTH-1:0] X164_Y143_waddr;
	assign X164_Y143_waddr = X163_Y143_waddr;
	wire X164_Y142_incr_raddr;
	assign X164_Y142_incr_raddr = X163_Y143_incr_raddr;
	wire [ADDR_WIDTH-1:0] X164_Y142_raddr;
	assign X164_Y142_raddr = X163_Y143_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X163_Y143(.clk(bus_clock),
		.incr_waddr(X163_Y143_incr_waddr),
		.waddr(X163_Y143_waddr),
		.incr_raddr(X163_Y143_incr_raddr),
		.raddr(X163_Y143_raddr));


	/* generated from I@X164_Y143@{N[1][32],N[1][33]}@1 */

	logic [DATA_WIDTH-1:0] X164_Y143_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_1_north_to_south_ip_size_33_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][32][10:0], north_in_reg[1][33][10:2]}),
		.out(X164_Y143_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X164_Y143(.data(X164_Y143_bus_wdata),
		.q(/* to design */),
		.wraddress(X164_Y143_waddr),
		.rdaddress(/* from design */),
		.wren(X164_Y143_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X166_Y143@{S[1][34],S[1][35]}@5 */

	logic [DATA_WIDTH-1:0] X166_Y143_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X166_Y143_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_1_south_to_north_ip_size_35_bus_first_egress_fifo(.clock(bus_clock),
		.in(X166_Y143_bus_rdata_in),
		.out(X166_Y143_bus_rdata_out));

	assign north_out_reg[1][34][10:0] = X166_Y143_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][35][10:2] = X166_Y143_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X166_Y143(.data(/* from design */),
		.q(X166_Y143_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X166_Y143_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X226_Y143@{N[3][1],N[3][0]}@1 */

	logic [DATA_WIDTH-1:0] X226_Y143_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_3_north_to_south_ip_size_0_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][1][10:0], north_in_reg[3][0][10:2]}),
		.out(X226_Y143_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X226_Y143(.data(X226_Y143_bus_wdata),
		.q(/* to design */),
		.wraddress(X226_Y143_waddr),
		.rdaddress(/* from design */),
		.wren(X226_Y143_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X227_Y143@{N[3][2],N[3][1]}@1 */

	logic X227_Y143_incr_waddr; // ingress control
	logic X227_Y143_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_3_north_to_south_ip_size_1_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][2][0]),
		.out(X227_Y143_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_3_north_to_south_ip_size_1_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][2][1]),
		.out(X227_Y143_incr_raddr));

	logic [ADDR_WIDTH-1:0] X227_Y143_waddr;
	logic [ADDR_WIDTH-1:0] X227_Y143_raddr;

	/* positional aliases */

	wire X226_Y143_incr_waddr;
	assign X226_Y143_incr_waddr = X227_Y143_incr_waddr;
	wire [ADDR_WIDTH-1:0] X226_Y143_waddr;
	assign X226_Y143_waddr = X227_Y143_waddr;
	wire X226_Y142_incr_raddr;
	assign X226_Y142_incr_raddr = X227_Y143_incr_raddr;
	wire [ADDR_WIDTH-1:0] X226_Y142_raddr;
	assign X226_Y142_raddr = X227_Y143_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X227_Y143(.clk(bus_clock),
		.incr_waddr(X227_Y143_incr_waddr),
		.waddr(X227_Y143_waddr),
		.incr_raddr(X227_Y143_incr_raddr),
		.raddr(X227_Y143_raddr));


	/* generated from E@X228_Y143@{S[3][3],S[3][2]}@5 */

	logic [DATA_WIDTH-1:0] X228_Y143_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X228_Y143_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_3_south_to_north_ip_size_2_bus_first_egress_fifo(.clock(bus_clock),
		.in(X228_Y143_bus_rdata_in),
		.out(X228_Y143_bus_rdata_out));

	assign north_out_reg[3][3][10:0] = X228_Y143_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][2][10:2] = X228_Y143_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X228_Y143(.data(/* from design */),
		.q(X228_Y143_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X228_Y143_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X239_Y143@{E[2][18],E[2][17]}@1 */

	logic [DATA_WIDTH-1:0] X239_Y143_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_17_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][18][10:0], east_in_reg[2][17][10:2]}),
		.out(X239_Y143_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X239_Y143(.data(X239_Y143_bus_wdata),
		.q(/* to design */),
		.wraddress(X239_Y143_waddr),
		.rdaddress(/* from design */),
		.wren(X239_Y143_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X240_Y143@{E[2][18],E[2][17]}@1 */

	logic X240_Y143_incr_waddr; // ingress control
	logic X240_Y143_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_17_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][18][0]),
		.out(X240_Y143_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_17_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][18][1]),
		.out(X240_Y143_incr_raddr));

	logic [ADDR_WIDTH-1:0] X240_Y143_waddr;
	logic [ADDR_WIDTH-1:0] X240_Y143_raddr;

	/* positional aliases */

	wire X239_Y143_incr_waddr;
	assign X239_Y143_incr_waddr = X240_Y143_incr_waddr;
	wire [ADDR_WIDTH-1:0] X239_Y143_waddr;
	assign X239_Y143_waddr = X240_Y143_waddr;
	wire X239_Y142_incr_raddr;
	assign X239_Y142_incr_raddr = X240_Y143_incr_raddr;
	wire [ADDR_WIDTH-1:0] X239_Y142_raddr;
	assign X239_Y142_raddr = X240_Y143_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X240_Y143(.clk(bus_clock),
		.incr_waddr(X240_Y143_incr_waddr),
		.waddr(X240_Y143_waddr),
		.incr_raddr(X240_Y143_incr_raddr),
		.raddr(X240_Y143_raddr));


	/* generated from I@X248_Y143@{N[3][17],N[3][16]}@1 */

	logic [DATA_WIDTH-1:0] X248_Y143_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_3_north_to_south_ip_size_16_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][17][10:0], north_in_reg[3][16][10:2]}),
		.out(X248_Y143_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X248_Y143(.data(X248_Y143_bus_wdata),
		.q(/* to design */),
		.wraddress(X248_Y143_waddr),
		.rdaddress(/* from design */),
		.wren(X248_Y143_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X249_Y143@{N[3][18],N[3][17]}@1 */

	logic X249_Y143_incr_waddr; // ingress control
	logic X249_Y143_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_3_north_to_south_ip_size_17_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][18][0]),
		.out(X249_Y143_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_3_north_to_south_ip_size_17_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][18][1]),
		.out(X249_Y143_incr_raddr));

	logic [ADDR_WIDTH-1:0] X249_Y143_waddr;
	logic [ADDR_WIDTH-1:0] X249_Y143_raddr;

	/* positional aliases */

	wire X248_Y143_incr_waddr;
	assign X248_Y143_incr_waddr = X249_Y143_incr_waddr;
	wire [ADDR_WIDTH-1:0] X248_Y143_waddr;
	assign X248_Y143_waddr = X249_Y143_waddr;
	wire X248_Y142_incr_raddr;
	assign X248_Y142_incr_raddr = X249_Y143_incr_raddr;
	wire [ADDR_WIDTH-1:0] X248_Y142_raddr;
	assign X248_Y142_raddr = X249_Y143_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X249_Y143(.clk(bus_clock),
		.incr_waddr(X249_Y143_incr_waddr),
		.waddr(X249_Y143_waddr),
		.incr_raddr(X249_Y143_incr_raddr),
		.raddr(X249_Y143_raddr));


	/* generated from E@X250_Y143@{S[3][19],S[3][18]}@5 */

	logic [DATA_WIDTH-1:0] X250_Y143_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X250_Y143_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_3_south_to_north_ip_size_18_bus_first_egress_fifo(.clock(bus_clock),
		.in(X250_Y143_bus_rdata_in),
		.out(X250_Y143_bus_rdata_out));

	assign north_out_reg[3][19][10:0] = X250_Y143_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][18][10:2] = X250_Y143_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X250_Y143(.data(/* from design */),
		.q(X250_Y143_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X250_Y143_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X258_Y143@{N[3][25],N[3][24]}@1 */

	logic [DATA_WIDTH-1:0] X258_Y143_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_3_north_to_south_ip_size_24_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][25][10:0], north_in_reg[3][24][10:2]}),
		.out(X258_Y143_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X258_Y143(.data(X258_Y143_bus_wdata),
		.q(/* to design */),
		.wraddress(X258_Y143_waddr),
		.rdaddress(/* from design */),
		.wren(X258_Y143_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X259_Y143@{N[3][26],N[3][25]}@1 */

	logic X259_Y143_incr_waddr; // ingress control
	logic X259_Y143_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_3_north_to_south_ip_size_25_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][26][0]),
		.out(X259_Y143_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_3_north_to_south_ip_size_25_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][26][1]),
		.out(X259_Y143_incr_raddr));

	logic [ADDR_WIDTH-1:0] X259_Y143_waddr;
	logic [ADDR_WIDTH-1:0] X259_Y143_raddr;

	/* positional aliases */

	wire X258_Y143_incr_waddr;
	assign X258_Y143_incr_waddr = X259_Y143_incr_waddr;
	wire [ADDR_WIDTH-1:0] X258_Y143_waddr;
	assign X258_Y143_waddr = X259_Y143_waddr;
	wire X258_Y142_incr_raddr;
	assign X258_Y142_incr_raddr = X259_Y143_incr_raddr;
	wire [ADDR_WIDTH-1:0] X258_Y142_raddr;
	assign X258_Y142_raddr = X259_Y143_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X259_Y143(.clk(bus_clock),
		.incr_waddr(X259_Y143_incr_waddr),
		.waddr(X259_Y143_waddr),
		.incr_raddr(X259_Y143_incr_raddr),
		.raddr(X259_Y143_raddr));


	/* generated from E@X260_Y143@{S[3][27],S[3][26]}@5 */

	logic [DATA_WIDTH-1:0] X260_Y143_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X260_Y143_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_3_south_to_north_ip_size_26_bus_first_egress_fifo(.clock(bus_clock),
		.in(X260_Y143_bus_rdata_in),
		.out(X260_Y143_bus_rdata_out));

	assign north_out_reg[3][27][10:0] = X260_Y143_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][26][10:2] = X260_Y143_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X260_Y143(.data(/* from design */),
		.q(X260_Y143_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X260_Y143_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X269_Y143@{N[3][33],N[3][32]}@1 */

	logic [DATA_WIDTH-1:0] X269_Y143_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_3_north_to_south_ip_size_32_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][33][10:0], north_in_reg[3][32][10:2]}),
		.out(X269_Y143_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X269_Y143(.data(X269_Y143_bus_wdata),
		.q(/* to design */),
		.wraddress(X269_Y143_waddr),
		.rdaddress(/* from design */),
		.wren(X269_Y143_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X270_Y143@{N[3][34],N[3][33]}@1 */

	logic X270_Y143_incr_waddr; // ingress control
	logic X270_Y143_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_3_north_to_south_ip_size_33_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][34][0]),
		.out(X270_Y143_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_3_north_to_south_ip_size_33_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][34][1]),
		.out(X270_Y143_incr_raddr));

	logic [ADDR_WIDTH-1:0] X270_Y143_waddr;
	logic [ADDR_WIDTH-1:0] X270_Y143_raddr;

	/* positional aliases */

	wire X269_Y143_incr_waddr;
	assign X269_Y143_incr_waddr = X270_Y143_incr_waddr;
	wire [ADDR_WIDTH-1:0] X269_Y143_waddr;
	assign X269_Y143_waddr = X270_Y143_waddr;
	wire X269_Y142_incr_raddr;
	assign X269_Y142_incr_raddr = X270_Y143_incr_raddr;
	wire [ADDR_WIDTH-1:0] X269_Y142_raddr;
	assign X269_Y142_raddr = X270_Y143_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X270_Y143(.clk(bus_clock),
		.incr_waddr(X270_Y143_incr_waddr),
		.waddr(X270_Y143_waddr),
		.incr_raddr(X270_Y143_incr_raddr),
		.raddr(X270_Y143_raddr));


	/* generated from E@X271_Y143@{S[3][35],S[3][34]}@5 */

	logic [DATA_WIDTH-1:0] X271_Y143_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X271_Y143_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_3_south_to_north_ip_size_34_bus_first_egress_fifo(.clock(bus_clock),
		.in(X271_Y143_bus_rdata_in),
		.out(X271_Y143_bus_rdata_out));

	assign north_out_reg[3][35][10:0] = X271_Y143_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][34][10:2] = X271_Y143_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X271_Y143(.data(/* from design */),
		.q(X271_Y143_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X271_Y143_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X121_Y142@{N[1][0],N[1][1]}@2 */

	logic [DATA_WIDTH-1:0] X121_Y142_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X121_Y142_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_1_north_to_south_ip_size_1_bus_first_egress_fifo(.clock(bus_clock),
		.in(X121_Y142_bus_rdata_in),
		.out(X121_Y142_bus_rdata_out));

	assign south_out_reg[1][0][10:0] = X121_Y142_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][1][10:2] = X121_Y142_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X121_Y142(.data(/* from design */),
		.q(X121_Y142_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X121_Y142_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X122_Y142@{S[1][1],S[1][2]}@4 */

	logic X122_Y142_incr_waddr; // ingress control
	logic X122_Y142_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_1_south_to_north_ip_size_2_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][2][0]),
		.out(X122_Y142_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_1_south_to_north_ip_size_2_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][2][1]),
		.out(X122_Y142_incr_raddr));

	logic [ADDR_WIDTH-1:0] X122_Y142_waddr;
	logic [ADDR_WIDTH-1:0] X122_Y142_raddr;

	/* positional aliases */

	wire X123_Y142_incr_waddr;
	assign X123_Y142_incr_waddr = X122_Y142_incr_waddr;
	wire [ADDR_WIDTH-1:0] X123_Y142_waddr;
	assign X123_Y142_waddr = X122_Y142_waddr;
	wire X123_Y143_incr_raddr;
	assign X123_Y143_incr_raddr = X122_Y142_incr_raddr;
	wire [ADDR_WIDTH-1:0] X123_Y143_raddr;
	assign X123_Y143_raddr = X122_Y142_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X122_Y142(.clk(bus_clock),
		.incr_waddr(X122_Y142_incr_waddr),
		.waddr(X122_Y142_waddr),
		.incr_raddr(X122_Y142_incr_raddr),
		.raddr(X122_Y142_raddr));


	/* generated from I@X123_Y142@{S[1][2],S[1][3]}@4 */

	logic [DATA_WIDTH-1:0] X123_Y142_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_1_south_to_north_ip_size_3_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][2][10:0], south_in_reg[1][3][10:2]}),
		.out(X123_Y142_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X123_Y142(.data(X123_Y142_bus_wdata),
		.q(/* to design */),
		.wraddress(X123_Y142_waddr),
		.rdaddress(/* from design */),
		.wren(X123_Y142_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X132_Y142@{N[1][8],N[1][9]}@2 */

	logic [DATA_WIDTH-1:0] X132_Y142_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X132_Y142_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_1_north_to_south_ip_size_9_bus_first_egress_fifo(.clock(bus_clock),
		.in(X132_Y142_bus_rdata_in),
		.out(X132_Y142_bus_rdata_out));

	assign south_out_reg[1][8][10:0] = X132_Y142_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][9][10:2] = X132_Y142_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X132_Y142(.data(/* from design */),
		.q(X132_Y142_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X132_Y142_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X133_Y142@{S[1][9],S[1][10]}@4 */

	logic X133_Y142_incr_waddr; // ingress control
	logic X133_Y142_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_1_south_to_north_ip_size_10_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][10][0]),
		.out(X133_Y142_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_1_south_to_north_ip_size_10_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][10][1]),
		.out(X133_Y142_incr_raddr));

	logic [ADDR_WIDTH-1:0] X133_Y142_waddr;
	logic [ADDR_WIDTH-1:0] X133_Y142_raddr;

	/* positional aliases */

	wire X134_Y142_incr_waddr;
	assign X134_Y142_incr_waddr = X133_Y142_incr_waddr;
	wire [ADDR_WIDTH-1:0] X134_Y142_waddr;
	assign X134_Y142_waddr = X133_Y142_waddr;
	wire X134_Y143_incr_raddr;
	assign X134_Y143_incr_raddr = X133_Y142_incr_raddr;
	wire [ADDR_WIDTH-1:0] X134_Y143_raddr;
	assign X134_Y143_raddr = X133_Y142_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X133_Y142(.clk(bus_clock),
		.incr_waddr(X133_Y142_incr_waddr),
		.waddr(X133_Y142_waddr),
		.incr_raddr(X133_Y142_incr_raddr),
		.raddr(X133_Y142_raddr));


	/* generated from I@X134_Y142@{S[1][10],S[1][11]}@4 */

	logic [DATA_WIDTH-1:0] X134_Y142_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_1_south_to_north_ip_size_11_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][10][10:0], south_in_reg[1][11][10:2]}),
		.out(X134_Y142_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X134_Y142(.data(X134_Y142_bus_wdata),
		.q(/* to design */),
		.wraddress(X134_Y142_waddr),
		.rdaddress(/* from design */),
		.wren(X134_Y142_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X142_Y142@{N[1][16],N[1][17]}@2 */

	logic [DATA_WIDTH-1:0] X142_Y142_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X142_Y142_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_1_north_to_south_ip_size_17_bus_first_egress_fifo(.clock(bus_clock),
		.in(X142_Y142_bus_rdata_in),
		.out(X142_Y142_bus_rdata_out));

	assign south_out_reg[1][16][10:0] = X142_Y142_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][17][10:2] = X142_Y142_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X142_Y142(.data(/* from design */),
		.q(X142_Y142_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X142_Y142_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X143_Y142@{S[1][17],S[1][18]}@4 */

	logic X143_Y142_incr_waddr; // ingress control
	logic X143_Y142_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_1_south_to_north_ip_size_18_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][18][0]),
		.out(X143_Y142_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_1_south_to_north_ip_size_18_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][18][1]),
		.out(X143_Y142_incr_raddr));

	logic [ADDR_WIDTH-1:0] X143_Y142_waddr;
	logic [ADDR_WIDTH-1:0] X143_Y142_raddr;

	/* positional aliases */

	wire X144_Y142_incr_waddr;
	assign X144_Y142_incr_waddr = X143_Y142_incr_waddr;
	wire [ADDR_WIDTH-1:0] X144_Y142_waddr;
	assign X144_Y142_waddr = X143_Y142_waddr;
	wire X144_Y143_incr_raddr;
	assign X144_Y143_incr_raddr = X143_Y142_incr_raddr;
	wire [ADDR_WIDTH-1:0] X144_Y143_raddr;
	assign X144_Y143_raddr = X143_Y142_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X143_Y142(.clk(bus_clock),
		.incr_waddr(X143_Y142_incr_waddr),
		.waddr(X143_Y142_waddr),
		.incr_raddr(X143_Y142_incr_raddr),
		.raddr(X143_Y142_raddr));


	/* generated from I@X144_Y142@{S[1][18],S[1][19]}@4 */

	logic [DATA_WIDTH-1:0] X144_Y142_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_1_south_to_north_ip_size_19_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][18][10:0], south_in_reg[1][19][10:2]}),
		.out(X144_Y142_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X144_Y142(.data(X144_Y142_bus_wdata),
		.q(/* to design */),
		.wraddress(X144_Y142_waddr),
		.rdaddress(/* from design */),
		.wren(X144_Y142_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X153_Y142@{W[2][18],W[2][17]}@3 */

	logic [DATA_WIDTH-1:0] X153_Y142_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X153_Y142_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) west_to_east_sector_size_2_west_to_east_ip_size_17_bus_first_egress_fifo(.clock(bus_clock),
		.in(X153_Y142_bus_rdata_in),
		.out(X153_Y142_bus_rdata_out));

	assign east_out_reg[2][18][10:0] = X153_Y142_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][17][10:2] = X153_Y142_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X153_Y142(.data(/* from design */),
		.q(X153_Y142_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X153_Y142_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X164_Y142@{N[1][32],N[1][33]}@2 */

	logic [DATA_WIDTH-1:0] X164_Y142_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X164_Y142_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_1_north_to_south_ip_size_33_bus_first_egress_fifo(.clock(bus_clock),
		.in(X164_Y142_bus_rdata_in),
		.out(X164_Y142_bus_rdata_out));

	assign south_out_reg[1][32][10:0] = X164_Y142_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][33][10:2] = X164_Y142_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X164_Y142(.data(/* from design */),
		.q(X164_Y142_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X164_Y142_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X165_Y142@{S[1][33],S[1][34]}@4 */

	logic X165_Y142_incr_waddr; // ingress control
	logic X165_Y142_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_1_south_to_north_ip_size_34_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][34][0]),
		.out(X165_Y142_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_1_south_to_north_ip_size_34_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][34][1]),
		.out(X165_Y142_incr_raddr));

	logic [ADDR_WIDTH-1:0] X165_Y142_waddr;
	logic [ADDR_WIDTH-1:0] X165_Y142_raddr;

	/* positional aliases */

	wire X166_Y142_incr_waddr;
	assign X166_Y142_incr_waddr = X165_Y142_incr_waddr;
	wire [ADDR_WIDTH-1:0] X166_Y142_waddr;
	assign X166_Y142_waddr = X165_Y142_waddr;
	wire X166_Y143_incr_raddr;
	assign X166_Y143_incr_raddr = X165_Y142_incr_raddr;
	wire [ADDR_WIDTH-1:0] X166_Y143_raddr;
	assign X166_Y143_raddr = X165_Y142_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X165_Y142(.clk(bus_clock),
		.incr_waddr(X165_Y142_incr_waddr),
		.waddr(X165_Y142_waddr),
		.incr_raddr(X165_Y142_incr_raddr),
		.raddr(X165_Y142_raddr));


	/* generated from I@X166_Y142@{S[1][34],S[1][35]}@4 */

	logic [DATA_WIDTH-1:0] X166_Y142_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_1_south_to_north_ip_size_35_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][34][10:0], south_in_reg[1][35][10:2]}),
		.out(X166_Y142_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X166_Y142(.data(X166_Y142_bus_wdata),
		.q(/* to design */),
		.wraddress(X166_Y142_waddr),
		.rdaddress(/* from design */),
		.wren(X166_Y142_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X226_Y142@{N[3][1],N[3][0]}@2 */

	logic [DATA_WIDTH-1:0] X226_Y142_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X226_Y142_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_3_north_to_south_ip_size_0_bus_first_egress_fifo(.clock(bus_clock),
		.in(X226_Y142_bus_rdata_in),
		.out(X226_Y142_bus_rdata_out));

	assign south_out_reg[3][1][10:0] = X226_Y142_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][0][10:2] = X226_Y142_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X226_Y142(.data(/* from design */),
		.q(X226_Y142_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X226_Y142_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X228_Y142@{S[3][3],S[3][2]}@4 */

	logic [DATA_WIDTH-1:0] X228_Y142_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_3_south_to_north_ip_size_2_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][3][10:0], south_in_reg[3][2][10:2]}),
		.out(X228_Y142_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X228_Y142(.data(X228_Y142_bus_wdata),
		.q(/* to design */),
		.wraddress(X228_Y142_waddr),
		.rdaddress(/* from design */),
		.wren(X228_Y142_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X229_Y142@{S[3][4],S[3][3]}@4 */

	logic X229_Y142_incr_waddr; // ingress control
	logic X229_Y142_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_3_south_to_north_ip_size_3_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][4][0]),
		.out(X229_Y142_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_3_south_to_north_ip_size_3_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][4][1]),
		.out(X229_Y142_incr_raddr));

	logic [ADDR_WIDTH-1:0] X229_Y142_waddr;
	logic [ADDR_WIDTH-1:0] X229_Y142_raddr;

	/* positional aliases */

	wire X228_Y142_incr_waddr;
	assign X228_Y142_incr_waddr = X229_Y142_incr_waddr;
	wire [ADDR_WIDTH-1:0] X228_Y142_waddr;
	assign X228_Y142_waddr = X229_Y142_waddr;
	wire X228_Y143_incr_raddr;
	assign X228_Y143_incr_raddr = X229_Y142_incr_raddr;
	wire [ADDR_WIDTH-1:0] X228_Y143_raddr;
	assign X228_Y143_raddr = X229_Y142_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X229_Y142(.clk(bus_clock),
		.incr_waddr(X229_Y142_incr_waddr),
		.waddr(X229_Y142_waddr),
		.incr_raddr(X229_Y142_incr_raddr),
		.raddr(X229_Y142_raddr));


	/* generated from E@X239_Y142@{E[2][18],E[2][17]}@2 */

	logic [DATA_WIDTH-1:0] X239_Y142_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X239_Y142_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_17_bus_first_egress_fifo(.clock(bus_clock),
		.in(X239_Y142_bus_rdata_in),
		.out(X239_Y142_bus_rdata_out));

	assign west_out_reg[2][18][10:0] = X239_Y142_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][17][10:2] = X239_Y142_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X239_Y142(.data(/* from design */),
		.q(X239_Y142_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X239_Y142_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X248_Y142@{N[3][17],N[3][16]}@2 */

	logic [DATA_WIDTH-1:0] X248_Y142_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X248_Y142_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_3_north_to_south_ip_size_16_bus_first_egress_fifo(.clock(bus_clock),
		.in(X248_Y142_bus_rdata_in),
		.out(X248_Y142_bus_rdata_out));

	assign south_out_reg[3][17][10:0] = X248_Y142_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][16][10:2] = X248_Y142_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X248_Y142(.data(/* from design */),
		.q(X248_Y142_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X248_Y142_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X250_Y142@{S[3][19],S[3][18]}@4 */

	logic [DATA_WIDTH-1:0] X250_Y142_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_3_south_to_north_ip_size_18_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][19][10:0], south_in_reg[3][18][10:2]}),
		.out(X250_Y142_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X250_Y142(.data(X250_Y142_bus_wdata),
		.q(/* to design */),
		.wraddress(X250_Y142_waddr),
		.rdaddress(/* from design */),
		.wren(X250_Y142_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X251_Y142@{S[3][20],S[3][19]}@4 */

	logic X251_Y142_incr_waddr; // ingress control
	logic X251_Y142_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_3_south_to_north_ip_size_19_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][20][0]),
		.out(X251_Y142_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_3_south_to_north_ip_size_19_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][20][1]),
		.out(X251_Y142_incr_raddr));

	logic [ADDR_WIDTH-1:0] X251_Y142_waddr;
	logic [ADDR_WIDTH-1:0] X251_Y142_raddr;

	/* positional aliases */

	wire X250_Y142_incr_waddr;
	assign X250_Y142_incr_waddr = X251_Y142_incr_waddr;
	wire [ADDR_WIDTH-1:0] X250_Y142_waddr;
	assign X250_Y142_waddr = X251_Y142_waddr;
	wire X250_Y143_incr_raddr;
	assign X250_Y143_incr_raddr = X251_Y142_incr_raddr;
	wire [ADDR_WIDTH-1:0] X250_Y143_raddr;
	assign X250_Y143_raddr = X251_Y142_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X251_Y142(.clk(bus_clock),
		.incr_waddr(X251_Y142_incr_waddr),
		.waddr(X251_Y142_waddr),
		.incr_raddr(X251_Y142_incr_raddr),
		.raddr(X251_Y142_raddr));


	/* generated from E@X258_Y142@{N[3][25],N[3][24]}@2 */

	logic [DATA_WIDTH-1:0] X258_Y142_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X258_Y142_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_3_north_to_south_ip_size_24_bus_first_egress_fifo(.clock(bus_clock),
		.in(X258_Y142_bus_rdata_in),
		.out(X258_Y142_bus_rdata_out));

	assign south_out_reg[3][25][10:0] = X258_Y142_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][24][10:2] = X258_Y142_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X258_Y142(.data(/* from design */),
		.q(X258_Y142_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X258_Y142_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X260_Y142@{S[3][27],S[3][26]}@4 */

	logic [DATA_WIDTH-1:0] X260_Y142_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_3_south_to_north_ip_size_26_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][27][10:0], south_in_reg[3][26][10:2]}),
		.out(X260_Y142_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X260_Y142(.data(X260_Y142_bus_wdata),
		.q(/* to design */),
		.wraddress(X260_Y142_waddr),
		.rdaddress(/* from design */),
		.wren(X260_Y142_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X261_Y142@{S[3][28],S[3][27]}@4 */

	logic X261_Y142_incr_waddr; // ingress control
	logic X261_Y142_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_3_south_to_north_ip_size_27_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][28][0]),
		.out(X261_Y142_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_3_south_to_north_ip_size_27_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][28][1]),
		.out(X261_Y142_incr_raddr));

	logic [ADDR_WIDTH-1:0] X261_Y142_waddr;
	logic [ADDR_WIDTH-1:0] X261_Y142_raddr;

	/* positional aliases */

	wire X260_Y142_incr_waddr;
	assign X260_Y142_incr_waddr = X261_Y142_incr_waddr;
	wire [ADDR_WIDTH-1:0] X260_Y142_waddr;
	assign X260_Y142_waddr = X261_Y142_waddr;
	wire X260_Y143_incr_raddr;
	assign X260_Y143_incr_raddr = X261_Y142_incr_raddr;
	wire [ADDR_WIDTH-1:0] X260_Y143_raddr;
	assign X260_Y143_raddr = X261_Y142_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X261_Y142(.clk(bus_clock),
		.incr_waddr(X261_Y142_incr_waddr),
		.waddr(X261_Y142_waddr),
		.incr_raddr(X261_Y142_incr_raddr),
		.raddr(X261_Y142_raddr));


	/* generated from E@X269_Y142@{N[3][33],N[3][32]}@2 */

	logic [DATA_WIDTH-1:0] X269_Y142_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X269_Y142_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_3_north_to_south_ip_size_32_bus_first_egress_fifo(.clock(bus_clock),
		.in(X269_Y142_bus_rdata_in),
		.out(X269_Y142_bus_rdata_out));

	assign south_out_reg[3][33][10:0] = X269_Y142_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][32][10:2] = X269_Y142_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X269_Y142(.data(/* from design */),
		.q(X269_Y142_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X269_Y142_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X271_Y142@{S[3][35],S[3][34]}@4 */

	logic [DATA_WIDTH-1:0] X271_Y142_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_3_south_to_north_ip_size_34_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][35][10:0], south_in_reg[3][34][10:2]}),
		.out(X271_Y142_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X271_Y142(.data(X271_Y142_bus_wdata),
		.q(/* to design */),
		.wraddress(X271_Y142_waddr),
		.rdaddress(/* from design */),
		.wren(X271_Y142_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X272_Y142@{S[3][36],S[3][35]}@4 */

	logic X272_Y142_incr_waddr; // ingress control
	logic X272_Y142_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_3_south_to_north_ip_size_35_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][36][0]),
		.out(X272_Y142_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_3_south_to_north_ip_size_35_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][36][1]),
		.out(X272_Y142_incr_raddr));

	logic [ADDR_WIDTH-1:0] X272_Y142_waddr;
	logic [ADDR_WIDTH-1:0] X272_Y142_raddr;

	/* positional aliases */

	wire X271_Y142_incr_waddr;
	assign X271_Y142_incr_waddr = X272_Y142_incr_waddr;
	wire [ADDR_WIDTH-1:0] X271_Y142_waddr;
	assign X271_Y142_waddr = X272_Y142_waddr;
	wire X271_Y143_incr_raddr;
	assign X271_Y143_incr_raddr = X272_Y142_incr_raddr;
	wire [ADDR_WIDTH-1:0] X271_Y143_raddr;
	assign X271_Y143_raddr = X272_Y142_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X272_Y142(.clk(bus_clock),
		.incr_waddr(X272_Y142_incr_waddr),
		.waddr(X272_Y142_waddr),
		.incr_raddr(X272_Y142_incr_raddr),
		.raddr(X272_Y142_raddr));


	/* generated from I@X83_Y141@{E[2][16],E[2][15]}@5 */

	logic [DATA_WIDTH-1:0] X83_Y141_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) east_to_west_sector_size_2_east_to_west_ip_size_15_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][16][10:0], east_in_reg[2][15][10:2]}),
		.out(X83_Y141_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X83_Y141(.data(X83_Y141_bus_wdata),
		.q(/* to design */),
		.wraddress(X83_Y141_waddr),
		.rdaddress(/* from design */),
		.wren(X83_Y141_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X84_Y141@{E[2][16],E[2][15]}@5 */

	logic X84_Y141_incr_waddr; // ingress control
	logic X84_Y141_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) east_to_west_sector_size_2_east_to_west_ip_size_15_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][15][0]),
		.out(X84_Y141_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) east_to_west_sector_size_2_east_to_west_ip_size_15_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][15][1]),
		.out(X84_Y141_incr_raddr));

	logic [ADDR_WIDTH-1:0] X84_Y141_waddr;
	logic [ADDR_WIDTH-1:0] X84_Y141_raddr;

	/* positional aliases */

	wire X83_Y141_incr_waddr;
	assign X83_Y141_incr_waddr = X84_Y141_incr_waddr;
	wire [ADDR_WIDTH-1:0] X83_Y141_waddr;
	assign X83_Y141_waddr = X84_Y141_waddr;
	wire X83_Y140_incr_raddr;
	assign X83_Y140_incr_raddr = X84_Y141_incr_raddr;
	wire [ADDR_WIDTH-1:0] X83_Y140_raddr;
	assign X83_Y140_raddr = X84_Y141_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X84_Y141(.clk(bus_clock),
		.incr_waddr(X84_Y141_incr_waddr),
		.waddr(X84_Y141_waddr),
		.incr_raddr(X84_Y141_incr_raddr),
		.raddr(X84_Y141_raddr));


	/* generated from C@X184_Y141@{W[2][16],W[2][15]}@3 */

	logic X184_Y141_incr_waddr; // ingress control
	logic X184_Y141_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_2_west_to_east_ip_size_15_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][16][0]),
		.out(X184_Y141_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_2_west_to_east_ip_size_15_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][16][1]),
		.out(X184_Y141_incr_raddr));

	logic [ADDR_WIDTH-1:0] X184_Y141_waddr;
	logic [ADDR_WIDTH-1:0] X184_Y141_raddr;

	/* positional aliases */

	wire X185_Y141_incr_waddr;
	assign X185_Y141_incr_waddr = X184_Y141_incr_waddr;
	wire [ADDR_WIDTH-1:0] X185_Y141_waddr;
	assign X185_Y141_waddr = X184_Y141_waddr;
	wire X185_Y140_incr_raddr;
	assign X185_Y140_incr_raddr = X184_Y141_incr_raddr;
	wire [ADDR_WIDTH-1:0] X185_Y140_raddr;
	assign X185_Y140_raddr = X184_Y141_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X184_Y141(.clk(bus_clock),
		.incr_waddr(X184_Y141_incr_waddr),
		.waddr(X184_Y141_waddr),
		.incr_raddr(X184_Y141_incr_raddr),
		.raddr(X184_Y141_raddr));


	/* generated from I@X185_Y141@{W[2][16],W[2][15]}@3 */

	logic [DATA_WIDTH-1:0] X185_Y141_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) west_to_east_sector_size_2_west_to_east_ip_size_15_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][16][10:0], west_in_reg[2][15][10:2]}),
		.out(X185_Y141_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X185_Y141(.data(X185_Y141_bus_wdata),
		.q(/* to design */),
		.wraddress(X185_Y141_waddr),
		.rdaddress(/* from design */),
		.wren(X185_Y141_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X83_Y140@{E[2][16],E[2][15]}@6 */

	logic [DATA_WIDTH-1:0] X83_Y140_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X83_Y140_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) east_to_west_sector_size_2_east_to_west_ip_size_15_bus_first_egress_fifo(.clock(bus_clock),
		.in(X83_Y140_bus_rdata_in),
		.out(X83_Y140_bus_rdata_out));

	assign west_out_reg[2][16][10:0] = X83_Y140_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][15][10:2] = X83_Y140_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X83_Y140(.data(/* from design */),
		.q(X83_Y140_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X83_Y140_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X185_Y140@{W[2][16],W[2][15]}@4 */

	logic [DATA_WIDTH-1:0] X185_Y140_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X185_Y140_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) west_to_east_sector_size_2_west_to_east_ip_size_15_bus_first_egress_fifo(.clock(bus_clock),
		.in(X185_Y140_bus_rdata_in),
		.out(X185_Y140_bus_rdata_out));

	assign east_out_reg[2][16][10:0] = X185_Y140_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][15][10:2] = X185_Y140_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X185_Y140(.data(/* from design */),
		.q(X185_Y140_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X185_Y140_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X82_Y139@{W[2][14],W[2][13]}@0 */

	logic X82_Y139_incr_waddr; // ingress control
	logic X82_Y139_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) west_to_east_sector_size_2_west_to_east_ip_size_13_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][13][0]),
		.out(X82_Y139_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) west_to_east_sector_size_2_west_to_east_ip_size_13_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][13][1]),
		.out(X82_Y139_incr_raddr));

	logic [ADDR_WIDTH-1:0] X82_Y139_waddr;
	logic [ADDR_WIDTH-1:0] X82_Y139_raddr;

	/* positional aliases */

	wire X83_Y139_incr_waddr;
	assign X83_Y139_incr_waddr = X82_Y139_incr_waddr;
	wire [ADDR_WIDTH-1:0] X83_Y139_waddr;
	assign X83_Y139_waddr = X82_Y139_waddr;
	wire X83_Y138_incr_raddr;
	assign X83_Y138_incr_raddr = X82_Y139_incr_raddr;
	wire [ADDR_WIDTH-1:0] X83_Y138_raddr;
	assign X83_Y138_raddr = X82_Y139_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X82_Y139(.clk(bus_clock),
		.incr_waddr(X82_Y139_incr_waddr),
		.waddr(X82_Y139_waddr),
		.incr_raddr(X82_Y139_incr_raddr),
		.raddr(X82_Y139_raddr));


	/* generated from I@X83_Y139@{W[2][14],W[2][13]}@0 */

	logic [DATA_WIDTH-1:0] X83_Y139_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) west_to_east_sector_size_2_west_to_east_ip_size_13_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][14][10:0], west_in_reg[2][13][10:2]}),
		.out(X83_Y139_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X83_Y139(.data(X83_Y139_bus_wdata),
		.q(/* to design */),
		.wraddress(X83_Y139_waddr),
		.rdaddress(/* from design */),
		.wren(X83_Y139_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X98_Y139@{N[0][23],N[0][24]}@1 */

	logic X98_Y139_incr_waddr; // ingress control
	logic X98_Y139_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_0_north_to_south_ip_size_24_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][24][0]),
		.out(X98_Y139_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_0_north_to_south_ip_size_24_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][24][1]),
		.out(X98_Y139_incr_raddr));

	logic [ADDR_WIDTH-1:0] X98_Y139_waddr;
	logic [ADDR_WIDTH-1:0] X98_Y139_raddr;

	/* positional aliases */

	wire X99_Y139_incr_waddr;
	assign X99_Y139_incr_waddr = X98_Y139_incr_waddr;
	wire [ADDR_WIDTH-1:0] X99_Y139_waddr;
	assign X99_Y139_waddr = X98_Y139_waddr;
	wire X99_Y138_incr_raddr;
	assign X99_Y138_incr_raddr = X98_Y139_incr_raddr;
	wire [ADDR_WIDTH-1:0] X99_Y138_raddr;
	assign X99_Y138_raddr = X98_Y139_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X98_Y139(.clk(bus_clock),
		.incr_waddr(X98_Y139_incr_waddr),
		.waddr(X98_Y139_waddr),
		.incr_raddr(X98_Y139_incr_raddr),
		.raddr(X98_Y139_raddr));


	/* generated from I@X99_Y139@{N[0][24],N[0][25]}@1 */

	logic [DATA_WIDTH-1:0] X99_Y139_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_0_north_to_south_ip_size_25_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][24][10:0], north_in_reg[0][25][10:2]}),
		.out(X99_Y139_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X99_Y139(.data(X99_Y139_bus_wdata),
		.q(/* to design */),
		.wraddress(X99_Y139_waddr),
		.rdaddress(/* from design */),
		.wren(X99_Y139_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X101_Y139@{S[0][26],S[0][27]}@5 */

	logic [DATA_WIDTH-1:0] X101_Y139_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X101_Y139_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_0_south_to_north_ip_size_27_bus_first_egress_fifo(.clock(bus_clock),
		.in(X101_Y139_bus_rdata_in),
		.out(X101_Y139_bus_rdata_out));

	assign north_out_reg[0][26][10:0] = X101_Y139_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][27][10:2] = X101_Y139_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X101_Y139(.data(/* from design */),
		.q(X101_Y139_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X101_Y139_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X109_Y139@{N[0][31],N[0][32]}@1 */

	logic X109_Y139_incr_waddr; // ingress control
	logic X109_Y139_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_0_north_to_south_ip_size_32_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][32][0]),
		.out(X109_Y139_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_0_north_to_south_ip_size_32_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][32][1]),
		.out(X109_Y139_incr_raddr));

	logic [ADDR_WIDTH-1:0] X109_Y139_waddr;
	logic [ADDR_WIDTH-1:0] X109_Y139_raddr;

	/* positional aliases */

	wire X110_Y139_incr_waddr;
	assign X110_Y139_incr_waddr = X109_Y139_incr_waddr;
	wire [ADDR_WIDTH-1:0] X110_Y139_waddr;
	assign X110_Y139_waddr = X109_Y139_waddr;
	wire X110_Y138_incr_raddr;
	assign X110_Y138_incr_raddr = X109_Y139_incr_raddr;
	wire [ADDR_WIDTH-1:0] X110_Y138_raddr;
	assign X110_Y138_raddr = X109_Y139_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X109_Y139(.clk(bus_clock),
		.incr_waddr(X109_Y139_incr_waddr),
		.waddr(X109_Y139_waddr),
		.incr_raddr(X109_Y139_incr_raddr),
		.raddr(X109_Y139_raddr));


	/* generated from I@X110_Y139@{N[0][32],N[0][33]}@1 */

	logic [DATA_WIDTH-1:0] X110_Y139_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_0_north_to_south_ip_size_33_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][32][10:0], north_in_reg[0][33][10:2]}),
		.out(X110_Y139_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X110_Y139(.data(X110_Y139_bus_wdata),
		.q(/* to design */),
		.wraddress(X110_Y139_waddr),
		.rdaddress(/* from design */),
		.wren(X110_Y139_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X112_Y139@{S[0][34],S[0][35]}@5 */

	logic [DATA_WIDTH-1:0] X112_Y139_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X112_Y139_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_0_south_to_north_ip_size_35_bus_first_egress_fifo(.clock(bus_clock),
		.in(X112_Y139_bus_rdata_in),
		.out(X112_Y139_bus_rdata_out));

	assign north_out_reg[0][34][10:0] = X112_Y139_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][35][10:2] = X112_Y139_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X112_Y139(.data(/* from design */),
		.q(X112_Y139_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X112_Y139_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X185_Y139@{E[2][14],E[2][13]}@2 */

	logic [DATA_WIDTH-1:0] X185_Y139_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) east_to_west_sector_size_2_east_to_west_ip_size_13_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][14][10:0], east_in_reg[2][13][10:2]}),
		.out(X185_Y139_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X185_Y139(.data(X185_Y139_bus_wdata),
		.q(/* to design */),
		.wraddress(X185_Y139_waddr),
		.rdaddress(/* from design */),
		.wren(X185_Y139_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X186_Y139@{E[2][14],E[2][13]}@2 */

	logic X186_Y139_incr_waddr; // ingress control
	logic X186_Y139_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) east_to_west_sector_size_2_east_to_west_ip_size_13_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][14][0]),
		.out(X186_Y139_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) east_to_west_sector_size_2_east_to_west_ip_size_13_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][14][1]),
		.out(X186_Y139_incr_raddr));

	logic [ADDR_WIDTH-1:0] X186_Y139_waddr;
	logic [ADDR_WIDTH-1:0] X186_Y139_raddr;

	/* positional aliases */

	wire X185_Y139_incr_waddr;
	assign X185_Y139_incr_waddr = X186_Y139_incr_waddr;
	wire [ADDR_WIDTH-1:0] X185_Y139_waddr;
	assign X185_Y139_waddr = X186_Y139_waddr;
	wire X185_Y138_incr_raddr;
	assign X185_Y138_incr_raddr = X186_Y139_incr_raddr;
	wire [ADDR_WIDTH-1:0] X185_Y138_raddr;
	assign X185_Y138_raddr = X186_Y139_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X186_Y139(.clk(bus_clock),
		.incr_waddr(X186_Y139_incr_waddr),
		.waddr(X186_Y139_waddr),
		.incr_raddr(X186_Y139_incr_raddr),
		.raddr(X186_Y139_raddr));


	/* generated from I@X204_Y139@{N[2][25],N[2][24]}@1 */

	logic [DATA_WIDTH-1:0] X204_Y139_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_2_north_to_south_ip_size_24_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][25][10:0], north_in_reg[2][24][10:2]}),
		.out(X204_Y139_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X204_Y139(.data(X204_Y139_bus_wdata),
		.q(/* to design */),
		.wraddress(X204_Y139_waddr),
		.rdaddress(/* from design */),
		.wren(X204_Y139_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X205_Y139@{N[2][26],N[2][25]}@1 */

	logic X205_Y139_incr_waddr; // ingress control
	logic X205_Y139_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_2_north_to_south_ip_size_25_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[2][26][0]),
		.out(X205_Y139_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) north_to_south_sector_size_2_north_to_south_ip_size_25_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[2][26][1]),
		.out(X205_Y139_incr_raddr));

	logic [ADDR_WIDTH-1:0] X205_Y139_waddr;
	logic [ADDR_WIDTH-1:0] X205_Y139_raddr;

	/* positional aliases */

	wire X204_Y139_incr_waddr;
	assign X204_Y139_incr_waddr = X205_Y139_incr_waddr;
	wire [ADDR_WIDTH-1:0] X204_Y139_waddr;
	assign X204_Y139_waddr = X205_Y139_waddr;
	wire X204_Y138_incr_raddr;
	assign X204_Y138_incr_raddr = X205_Y139_incr_raddr;
	wire [ADDR_WIDTH-1:0] X204_Y138_raddr;
	assign X204_Y138_raddr = X205_Y139_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X205_Y139(.clk(bus_clock),
		.incr_waddr(X205_Y139_incr_waddr),
		.waddr(X205_Y139_waddr),
		.incr_raddr(X205_Y139_incr_raddr),
		.raddr(X205_Y139_raddr));


	/* generated from E@X206_Y139@{S[2][27],S[2][26]}@5 */

	logic [DATA_WIDTH-1:0] X206_Y139_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X206_Y139_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_2_south_to_north_ip_size_26_bus_first_egress_fifo(.clock(bus_clock),
		.in(X206_Y139_bus_rdata_in),
		.out(X206_Y139_bus_rdata_out));

	assign north_out_reg[2][27][10:0] = X206_Y139_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][26][10:2] = X206_Y139_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X206_Y139(.data(/* from design */),
		.q(X206_Y139_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X206_Y139_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X83_Y138@{W[2][14],W[2][13]}@1 */

	logic [DATA_WIDTH-1:0] X83_Y138_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X83_Y138_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) west_to_east_sector_size_2_west_to_east_ip_size_13_bus_first_egress_fifo(.clock(bus_clock),
		.in(X83_Y138_bus_rdata_in),
		.out(X83_Y138_bus_rdata_out));

	assign east_out_reg[2][14][10:0] = X83_Y138_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][13][10:2] = X83_Y138_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X83_Y138(.data(/* from design */),
		.q(X83_Y138_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X83_Y138_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X99_Y138@{N[0][24],N[0][25]}@2 */

	logic [DATA_WIDTH-1:0] X99_Y138_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X99_Y138_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_0_north_to_south_ip_size_25_bus_first_egress_fifo(.clock(bus_clock),
		.in(X99_Y138_bus_rdata_in),
		.out(X99_Y138_bus_rdata_out));

	assign south_out_reg[0][24][10:0] = X99_Y138_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][25][10:2] = X99_Y138_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X99_Y138(.data(/* from design */),
		.q(X99_Y138_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X99_Y138_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X100_Y138@{S[0][25],S[0][26]}@4 */

	logic X100_Y138_incr_waddr; // ingress control
	logic X100_Y138_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_0_south_to_north_ip_size_26_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][26][0]),
		.out(X100_Y138_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_0_south_to_north_ip_size_26_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][26][1]),
		.out(X100_Y138_incr_raddr));

	logic [ADDR_WIDTH-1:0] X100_Y138_waddr;
	logic [ADDR_WIDTH-1:0] X100_Y138_raddr;

	/* positional aliases */

	wire X101_Y138_incr_waddr;
	assign X101_Y138_incr_waddr = X100_Y138_incr_waddr;
	wire [ADDR_WIDTH-1:0] X101_Y138_waddr;
	assign X101_Y138_waddr = X100_Y138_waddr;
	wire X101_Y139_incr_raddr;
	assign X101_Y139_incr_raddr = X100_Y138_incr_raddr;
	wire [ADDR_WIDTH-1:0] X101_Y139_raddr;
	assign X101_Y139_raddr = X100_Y138_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X100_Y138(.clk(bus_clock),
		.incr_waddr(X100_Y138_incr_waddr),
		.waddr(X100_Y138_waddr),
		.incr_raddr(X100_Y138_incr_raddr),
		.raddr(X100_Y138_raddr));


	/* generated from I@X101_Y138@{S[0][26],S[0][27]}@4 */

	logic [DATA_WIDTH-1:0] X101_Y138_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_0_south_to_north_ip_size_27_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][26][10:0], south_in_reg[0][27][10:2]}),
		.out(X101_Y138_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X101_Y138(.data(X101_Y138_bus_wdata),
		.q(/* to design */),
		.wraddress(X101_Y138_waddr),
		.rdaddress(/* from design */),
		.wren(X101_Y138_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X110_Y138@{N[0][32],N[0][33]}@2 */

	logic [DATA_WIDTH-1:0] X110_Y138_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X110_Y138_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_0_north_to_south_ip_size_33_bus_first_egress_fifo(.clock(bus_clock),
		.in(X110_Y138_bus_rdata_in),
		.out(X110_Y138_bus_rdata_out));

	assign south_out_reg[0][32][10:0] = X110_Y138_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][33][10:2] = X110_Y138_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X110_Y138(.data(/* from design */),
		.q(X110_Y138_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X110_Y138_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X111_Y138@{S[0][33],S[0][34]}@4 */

	logic X111_Y138_incr_waddr; // ingress control
	logic X111_Y138_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_0_south_to_north_ip_size_34_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][34][0]),
		.out(X111_Y138_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_0_south_to_north_ip_size_34_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][34][1]),
		.out(X111_Y138_incr_raddr));

	logic [ADDR_WIDTH-1:0] X111_Y138_waddr;
	logic [ADDR_WIDTH-1:0] X111_Y138_raddr;

	/* positional aliases */

	wire X112_Y138_incr_waddr;
	assign X112_Y138_incr_waddr = X111_Y138_incr_waddr;
	wire [ADDR_WIDTH-1:0] X112_Y138_waddr;
	assign X112_Y138_waddr = X111_Y138_waddr;
	wire X112_Y139_incr_raddr;
	assign X112_Y139_incr_raddr = X111_Y138_incr_raddr;
	wire [ADDR_WIDTH-1:0] X112_Y139_raddr;
	assign X112_Y139_raddr = X111_Y138_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X111_Y138(.clk(bus_clock),
		.incr_waddr(X111_Y138_incr_waddr),
		.waddr(X111_Y138_waddr),
		.incr_raddr(X111_Y138_incr_raddr),
		.raddr(X111_Y138_raddr));


	/* generated from I@X112_Y138@{S[0][34],S[0][35]}@4 */

	logic [DATA_WIDTH-1:0] X112_Y138_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_0_south_to_north_ip_size_35_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][34][10:0], south_in_reg[0][35][10:2]}),
		.out(X112_Y138_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X112_Y138(.data(X112_Y138_bus_wdata),
		.q(/* to design */),
		.wraddress(X112_Y138_waddr),
		.rdaddress(/* from design */),
		.wren(X112_Y138_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X185_Y138@{E[2][14],E[2][13]}@3 */

	logic [DATA_WIDTH-1:0] X185_Y138_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X185_Y138_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) east_to_west_sector_size_2_east_to_west_ip_size_13_bus_first_egress_fifo(.clock(bus_clock),
		.in(X185_Y138_bus_rdata_in),
		.out(X185_Y138_bus_rdata_out));

	assign west_out_reg[2][14][10:0] = X185_Y138_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][13][10:2] = X185_Y138_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X185_Y138(.data(/* from design */),
		.q(X185_Y138_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X185_Y138_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X204_Y138@{N[2][25],N[2][24]}@2 */

	logic [DATA_WIDTH-1:0] X204_Y138_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X204_Y138_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_2_north_to_south_ip_size_24_bus_first_egress_fifo(.clock(bus_clock),
		.in(X204_Y138_bus_rdata_in),
		.out(X204_Y138_bus_rdata_out));

	assign south_out_reg[2][25][10:0] = X204_Y138_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][24][10:2] = X204_Y138_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X204_Y138(.data(/* from design */),
		.q(X204_Y138_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X204_Y138_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X206_Y138@{S[2][27],S[2][26]}@4 */

	logic [DATA_WIDTH-1:0] X206_Y138_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_2_south_to_north_ip_size_26_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][27][10:0], south_in_reg[2][26][10:2]}),
		.out(X206_Y138_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X206_Y138(.data(X206_Y138_bus_wdata),
		.q(/* to design */),
		.wraddress(X206_Y138_waddr),
		.rdaddress(/* from design */),
		.wren(X206_Y138_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X207_Y138@{S[2][28],S[2][27]}@4 */

	logic X207_Y138_incr_waddr; // ingress control
	logic X207_Y138_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_2_south_to_north_ip_size_27_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[2][28][0]),
		.out(X207_Y138_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) south_to_north_sector_size_2_south_to_north_ip_size_27_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[2][28][1]),
		.out(X207_Y138_incr_raddr));

	logic [ADDR_WIDTH-1:0] X207_Y138_waddr;
	logic [ADDR_WIDTH-1:0] X207_Y138_raddr;

	/* positional aliases */

	wire X206_Y138_incr_waddr;
	assign X206_Y138_incr_waddr = X207_Y138_incr_waddr;
	wire [ADDR_WIDTH-1:0] X206_Y138_waddr;
	assign X206_Y138_waddr = X207_Y138_waddr;
	wire X206_Y139_incr_raddr;
	assign X206_Y139_incr_raddr = X207_Y138_incr_raddr;
	wire [ADDR_WIDTH-1:0] X206_Y139_raddr;
	assign X206_Y139_raddr = X207_Y138_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X207_Y138(.clk(bus_clock),
		.incr_waddr(X207_Y138_incr_waddr),
		.waddr(X207_Y138_waddr),
		.incr_raddr(X207_Y138_incr_raddr),
		.raddr(X207_Y138_raddr));


	/* generated from I@X132_Y137@{E[2][12],E[2][11]}@4 */

	logic [DATA_WIDTH-1:0] X132_Y137_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_11_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][12][10:0], east_in_reg[2][11][10:2]}),
		.out(X132_Y137_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X132_Y137(.data(X132_Y137_bus_wdata),
		.q(/* to design */),
		.wraddress(X132_Y137_waddr),
		.rdaddress(/* from design */),
		.wren(X132_Y137_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X133_Y137@{E[2][12],E[2][11]}@4 */

	logic X133_Y137_incr_waddr; // ingress control
	logic X133_Y137_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_11_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][11][0]),
		.out(X133_Y137_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_11_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][11][1]),
		.out(X133_Y137_incr_raddr));

	logic [ADDR_WIDTH-1:0] X133_Y137_waddr;
	logic [ADDR_WIDTH-1:0] X133_Y137_raddr;

	/* positional aliases */

	wire X132_Y137_incr_waddr;
	assign X132_Y137_incr_waddr = X133_Y137_incr_waddr;
	wire [ADDR_WIDTH-1:0] X132_Y137_waddr;
	assign X132_Y137_waddr = X133_Y137_waddr;
	wire X132_Y136_incr_raddr;
	assign X132_Y136_incr_raddr = X133_Y137_incr_raddr;
	wire [ADDR_WIDTH-1:0] X132_Y136_raddr;
	assign X132_Y136_raddr = X133_Y137_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X133_Y137(.clk(bus_clock),
		.incr_waddr(X133_Y137_incr_waddr),
		.waddr(X133_Y137_waddr),
		.incr_raddr(X133_Y137_incr_raddr),
		.raddr(X133_Y137_raddr));


	/* generated from C@X259_Y137@{W[2][12],W[2][11]}@5 */

	logic X259_Y137_incr_waddr; // ingress control
	logic X259_Y137_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) west_to_east_sector_size_2_west_to_east_ip_size_11_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][12][0]),
		.out(X259_Y137_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) west_to_east_sector_size_2_west_to_east_ip_size_11_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][12][1]),
		.out(X259_Y137_incr_raddr));

	logic [ADDR_WIDTH-1:0] X259_Y137_waddr;
	logic [ADDR_WIDTH-1:0] X259_Y137_raddr;

	/* positional aliases */

	wire X260_Y137_incr_waddr;
	assign X260_Y137_incr_waddr = X259_Y137_incr_waddr;
	wire [ADDR_WIDTH-1:0] X260_Y137_waddr;
	assign X260_Y137_waddr = X259_Y137_waddr;
	wire X260_Y136_incr_raddr;
	assign X260_Y136_incr_raddr = X259_Y137_incr_raddr;
	wire [ADDR_WIDTH-1:0] X260_Y136_raddr;
	assign X260_Y136_raddr = X259_Y137_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X259_Y137(.clk(bus_clock),
		.incr_waddr(X259_Y137_incr_waddr),
		.waddr(X259_Y137_waddr),
		.incr_raddr(X259_Y137_incr_raddr),
		.raddr(X259_Y137_raddr));


	/* generated from I@X260_Y137@{W[2][12],W[2][11]}@5 */

	logic [DATA_WIDTH-1:0] X260_Y137_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) west_to_east_sector_size_2_west_to_east_ip_size_11_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][12][10:0], west_in_reg[2][11][10:2]}),
		.out(X260_Y137_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X260_Y137(.data(X260_Y137_bus_wdata),
		.q(/* to design */),
		.wraddress(X260_Y137_waddr),
		.rdaddress(/* from design */),
		.wren(X260_Y137_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X132_Y136@{E[2][12],E[2][11]}@5 */

	logic [DATA_WIDTH-1:0] X132_Y136_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X132_Y136_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_11_bus_first_egress_fifo(.clock(bus_clock),
		.in(X132_Y136_bus_rdata_in),
		.out(X132_Y136_bus_rdata_out));

	assign west_out_reg[2][12][10:0] = X132_Y136_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][11][10:2] = X132_Y136_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X132_Y136(.data(/* from design */),
		.q(X132_Y136_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X132_Y136_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X260_Y136@{W[2][12],W[2][11]}@6 */

	logic [DATA_WIDTH-1:0] X260_Y136_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X260_Y136_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) west_to_east_sector_size_2_west_to_east_ip_size_11_bus_first_egress_fifo(.clock(bus_clock),
		.in(X260_Y136_bus_rdata_in),
		.out(X260_Y136_bus_rdata_out));

	assign east_out_reg[2][12][10:0] = X260_Y136_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][11][10:2] = X260_Y136_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X260_Y136(.data(/* from design */),
		.q(X260_Y136_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X260_Y136_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X131_Y135@{W[2][10],W[2][9]}@1 */

	logic X131_Y135_incr_waddr; // ingress control
	logic X131_Y135_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_9_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][9][0]),
		.out(X131_Y135_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_9_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][9][1]),
		.out(X131_Y135_incr_raddr));

	logic [ADDR_WIDTH-1:0] X131_Y135_waddr;
	logic [ADDR_WIDTH-1:0] X131_Y135_raddr;

	/* positional aliases */

	wire X132_Y135_incr_waddr;
	assign X132_Y135_incr_waddr = X131_Y135_incr_waddr;
	wire [ADDR_WIDTH-1:0] X132_Y135_waddr;
	assign X132_Y135_waddr = X131_Y135_waddr;
	wire X132_Y134_incr_raddr;
	assign X132_Y134_incr_raddr = X131_Y135_incr_raddr;
	wire [ADDR_WIDTH-1:0] X132_Y134_raddr;
	assign X132_Y134_raddr = X131_Y135_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X131_Y135(.clk(bus_clock),
		.incr_waddr(X131_Y135_incr_waddr),
		.waddr(X131_Y135_waddr),
		.incr_raddr(X131_Y135_incr_raddr),
		.raddr(X131_Y135_raddr));


	/* generated from I@X132_Y135@{W[2][10],W[2][9]}@1 */

	logic [DATA_WIDTH-1:0] X132_Y135_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_9_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][10][10:0], west_in_reg[2][9][10:2]}),
		.out(X132_Y135_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X132_Y135(.data(X132_Y135_bus_wdata),
		.q(/* to design */),
		.wraddress(X132_Y135_waddr),
		.rdaddress(/* from design */),
		.wren(X132_Y135_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from I@X260_Y135@{E[2][10],E[2][9]}@0 */

	logic [DATA_WIDTH-1:0] X260_Y135_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) east_to_west_sector_size_2_east_to_west_ip_size_9_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][10][10:0], east_in_reg[2][9][10:2]}),
		.out(X260_Y135_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X260_Y135(.data(X260_Y135_bus_wdata),
		.q(/* to design */),
		.wraddress(X260_Y135_waddr),
		.rdaddress(/* from design */),
		.wren(X260_Y135_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X261_Y135@{E[2][10],E[2][9]}@0 */

	logic X261_Y135_incr_waddr; // ingress control
	logic X261_Y135_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) east_to_west_sector_size_2_east_to_west_ip_size_9_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][10][0]),
		.out(X261_Y135_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) east_to_west_sector_size_2_east_to_west_ip_size_9_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][10][1]),
		.out(X261_Y135_incr_raddr));

	logic [ADDR_WIDTH-1:0] X261_Y135_waddr;
	logic [ADDR_WIDTH-1:0] X261_Y135_raddr;

	/* positional aliases */

	wire X260_Y135_incr_waddr;
	assign X260_Y135_incr_waddr = X261_Y135_incr_waddr;
	wire [ADDR_WIDTH-1:0] X260_Y135_waddr;
	assign X260_Y135_waddr = X261_Y135_waddr;
	wire X260_Y134_incr_raddr;
	assign X260_Y134_incr_raddr = X261_Y135_incr_raddr;
	wire [ADDR_WIDTH-1:0] X260_Y134_raddr;
	assign X260_Y134_raddr = X261_Y135_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X261_Y135(.clk(bus_clock),
		.incr_waddr(X261_Y135_incr_waddr),
		.waddr(X261_Y135_waddr),
		.incr_raddr(X261_Y135_incr_raddr),
		.raddr(X261_Y135_raddr));


	/* generated from E@X132_Y134@{W[2][10],W[2][9]}@2 */

	logic [DATA_WIDTH-1:0] X132_Y134_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X132_Y134_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_2_west_to_east_ip_size_9_bus_first_egress_fifo(.clock(bus_clock),
		.in(X132_Y134_bus_rdata_in),
		.out(X132_Y134_bus_rdata_out));

	assign east_out_reg[2][10][10:0] = X132_Y134_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][9][10:2] = X132_Y134_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X132_Y134(.data(/* from design */),
		.q(X132_Y134_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X132_Y134_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X260_Y134@{E[2][10],E[2][9]}@1 */

	logic [DATA_WIDTH-1:0] X260_Y134_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X260_Y134_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) east_to_west_sector_size_2_east_to_west_ip_size_9_bus_first_egress_fifo(.clock(bus_clock),
		.in(X260_Y134_bus_rdata_in),
		.out(X260_Y134_bus_rdata_out));

	assign west_out_reg[2][10][10:0] = X260_Y134_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][9][10:2] = X260_Y134_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X260_Y134(.data(/* from design */),
		.q(X260_Y134_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X260_Y134_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X104_Y133@{E[2][8],E[2][7]}@4 */

	logic [DATA_WIDTH-1:0] X104_Y133_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_7_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][8][10:0], east_in_reg[2][7][10:2]}),
		.out(X104_Y133_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X104_Y133(.data(X104_Y133_bus_wdata),
		.q(/* to design */),
		.wraddress(X104_Y133_waddr),
		.rdaddress(/* from design */),
		.wren(X104_Y133_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X105_Y133@{E[2][8],E[2][7]}@4 */

	logic X105_Y133_incr_waddr; // ingress control
	logic X105_Y133_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_7_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][7][0]),
		.out(X105_Y133_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_7_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][7][1]),
		.out(X105_Y133_incr_raddr));

	logic [ADDR_WIDTH-1:0] X105_Y133_waddr;
	logic [ADDR_WIDTH-1:0] X105_Y133_raddr;

	/* positional aliases */

	wire X104_Y133_incr_waddr;
	assign X104_Y133_incr_waddr = X105_Y133_incr_waddr;
	wire [ADDR_WIDTH-1:0] X104_Y133_waddr;
	assign X104_Y133_waddr = X105_Y133_waddr;
	wire X104_Y132_incr_raddr;
	assign X104_Y132_incr_raddr = X105_Y133_incr_raddr;
	wire [ADDR_WIDTH-1:0] X104_Y132_raddr;
	assign X104_Y132_raddr = X105_Y133_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X105_Y133(.clk(bus_clock),
		.incr_waddr(X105_Y133_incr_waddr),
		.waddr(X105_Y133_waddr),
		.incr_raddr(X105_Y133_incr_raddr),
		.raddr(X105_Y133_raddr));


	/* generated from C@X205_Y133@{W[2][8],W[2][7]}@3 */

	logic X205_Y133_incr_waddr; // ingress control
	logic X205_Y133_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_2_west_to_east_ip_size_7_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][8][0]),
		.out(X205_Y133_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_2_west_to_east_ip_size_7_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][8][1]),
		.out(X205_Y133_incr_raddr));

	logic [ADDR_WIDTH-1:0] X205_Y133_waddr;
	logic [ADDR_WIDTH-1:0] X205_Y133_raddr;

	/* positional aliases */

	wire X206_Y133_incr_waddr;
	assign X206_Y133_incr_waddr = X205_Y133_incr_waddr;
	wire [ADDR_WIDTH-1:0] X206_Y133_waddr;
	assign X206_Y133_waddr = X205_Y133_waddr;
	wire X206_Y132_incr_raddr;
	assign X206_Y132_incr_raddr = X205_Y133_incr_raddr;
	wire [ADDR_WIDTH-1:0] X206_Y132_raddr;
	assign X206_Y132_raddr = X205_Y133_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X205_Y133(.clk(bus_clock),
		.incr_waddr(X205_Y133_incr_waddr),
		.waddr(X205_Y133_waddr),
		.incr_raddr(X205_Y133_incr_raddr),
		.raddr(X205_Y133_raddr));


	/* generated from I@X206_Y133@{W[2][8],W[2][7]}@4 */

	logic [DATA_WIDTH-1:0] X206_Y133_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_2_west_to_east_ip_size_7_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][8][10:0], west_in_reg[2][7][10:2]}),
		.out(X206_Y133_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X206_Y133(.data(X206_Y133_bus_wdata),
		.q(/* to design */),
		.wraddress(X206_Y133_waddr),
		.rdaddress(/* from design */),
		.wren(X206_Y133_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X104_Y132@{E[2][8],E[2][7]}@5 */

	logic [DATA_WIDTH-1:0] X104_Y132_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X104_Y132_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_7_bus_first_egress_fifo(.clock(bus_clock),
		.in(X104_Y132_bus_rdata_in),
		.out(X104_Y132_bus_rdata_out));

	assign west_out_reg[2][8][10:0] = X104_Y132_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][7][10:2] = X104_Y132_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X104_Y132(.data(/* from design */),
		.q(X104_Y132_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X104_Y132_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X206_Y132@{W[2][8],W[2][7]}@5 */

	logic [DATA_WIDTH-1:0] X206_Y132_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X206_Y132_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_7_bus_first_egress_fifo(.clock(bus_clock),
		.in(X206_Y132_bus_rdata_in),
		.out(X206_Y132_bus_rdata_out));

	assign east_out_reg[2][8][10:0] = X206_Y132_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][7][10:2] = X206_Y132_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X206_Y132(.data(/* from design */),
		.q(X206_Y132_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X206_Y132_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X103_Y131@{W[2][6],W[2][5]}@1 */

	logic X103_Y131_incr_waddr; // ingress control
	logic X103_Y131_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_5_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][5][0]),
		.out(X103_Y131_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_5_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][5][1]),
		.out(X103_Y131_incr_raddr));

	logic [ADDR_WIDTH-1:0] X103_Y131_waddr;
	logic [ADDR_WIDTH-1:0] X103_Y131_raddr;

	/* positional aliases */

	wire X104_Y131_incr_waddr;
	assign X104_Y131_incr_waddr = X103_Y131_incr_waddr;
	wire [ADDR_WIDTH-1:0] X104_Y131_waddr;
	assign X104_Y131_waddr = X103_Y131_waddr;
	wire X104_Y130_incr_raddr;
	assign X104_Y130_incr_raddr = X103_Y131_incr_raddr;
	wire [ADDR_WIDTH-1:0] X104_Y130_raddr;
	assign X104_Y130_raddr = X103_Y131_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X103_Y131(.clk(bus_clock),
		.incr_waddr(X103_Y131_incr_waddr),
		.waddr(X103_Y131_waddr),
		.incr_raddr(X103_Y131_incr_raddr),
		.raddr(X103_Y131_raddr));


	/* generated from I@X104_Y131@{W[2][6],W[2][5]}@1 */

	logic [DATA_WIDTH-1:0] X104_Y131_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_5_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][6][10:0], west_in_reg[2][5][10:2]}),
		.out(X104_Y131_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X104_Y131(.data(X104_Y131_bus_wdata),
		.q(/* to design */),
		.wraddress(X104_Y131_waddr),
		.rdaddress(/* from design */),
		.wren(X104_Y131_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from I@X206_Y131@{E[2][6],E[2][5]}@1 */

	logic [DATA_WIDTH-1:0] X206_Y131_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_5_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][6][10:0], east_in_reg[2][5][10:2]}),
		.out(X206_Y131_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X206_Y131(.data(X206_Y131_bus_wdata),
		.q(/* to design */),
		.wraddress(X206_Y131_waddr),
		.rdaddress(/* from design */),
		.wren(X206_Y131_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X207_Y131@{E[2][6],E[2][5]}@1 */

	logic X207_Y131_incr_waddr; // ingress control
	logic X207_Y131_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_5_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][6][0]),
		.out(X207_Y131_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_5_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][6][1]),
		.out(X207_Y131_incr_raddr));

	logic [ADDR_WIDTH-1:0] X207_Y131_waddr;
	logic [ADDR_WIDTH-1:0] X207_Y131_raddr;

	/* positional aliases */

	wire X206_Y131_incr_waddr;
	assign X206_Y131_incr_waddr = X207_Y131_incr_waddr;
	wire [ADDR_WIDTH-1:0] X206_Y131_waddr;
	assign X206_Y131_waddr = X207_Y131_waddr;
	wire X206_Y130_incr_raddr;
	assign X206_Y130_incr_raddr = X207_Y131_incr_raddr;
	wire [ADDR_WIDTH-1:0] X206_Y130_raddr;
	assign X206_Y130_raddr = X207_Y131_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X207_Y131(.clk(bus_clock),
		.incr_waddr(X207_Y131_incr_waddr),
		.waddr(X207_Y131_waddr),
		.incr_raddr(X207_Y131_incr_raddr),
		.raddr(X207_Y131_raddr));


	/* generated from E@X104_Y130@{W[2][6],W[2][5]}@2 */

	logic [DATA_WIDTH-1:0] X104_Y130_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X104_Y130_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_2_west_to_east_ip_size_5_bus_first_egress_fifo(.clock(bus_clock),
		.in(X104_Y130_bus_rdata_in),
		.out(X104_Y130_bus_rdata_out));

	assign east_out_reg[2][6][10:0] = X104_Y130_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][5][10:2] = X104_Y130_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X104_Y130(.data(/* from design */),
		.q(X104_Y130_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X104_Y130_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X206_Y130@{E[2][6],E[2][5]}@2 */

	logic [DATA_WIDTH-1:0] X206_Y130_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X206_Y130_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_5_bus_first_egress_fifo(.clock(bus_clock),
		.in(X206_Y130_bus_rdata_in),
		.out(X206_Y130_bus_rdata_out));

	assign west_out_reg[2][6][10:0] = X206_Y130_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][5][10:2] = X206_Y130_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X206_Y130(.data(/* from design */),
		.q(X206_Y130_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X206_Y130_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X153_Y129@{E[2][4],E[2][3]}@3 */

	logic [DATA_WIDTH-1:0] X153_Y129_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) east_to_west_sector_size_2_east_to_west_ip_size_3_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][4][10:0], east_in_reg[2][3][10:2]}),
		.out(X153_Y129_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X153_Y129(.data(X153_Y129_bus_wdata),
		.q(/* to design */),
		.wraddress(X153_Y129_waddr),
		.rdaddress(/* from design */),
		.wren(X153_Y129_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X154_Y129@{E[2][4],E[2][3]}@3 */

	logic X154_Y129_incr_waddr; // ingress control
	logic X154_Y129_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) east_to_west_sector_size_2_east_to_west_ip_size_3_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][3][0]),
		.out(X154_Y129_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) east_to_west_sector_size_2_east_to_west_ip_size_3_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][3][1]),
		.out(X154_Y129_incr_raddr));

	logic [ADDR_WIDTH-1:0] X154_Y129_waddr;
	logic [ADDR_WIDTH-1:0] X154_Y129_raddr;

	/* positional aliases */

	wire X153_Y129_incr_waddr;
	assign X153_Y129_incr_waddr = X154_Y129_incr_waddr;
	wire [ADDR_WIDTH-1:0] X153_Y129_waddr;
	assign X153_Y129_waddr = X154_Y129_waddr;
	wire X153_Y128_incr_raddr;
	assign X153_Y128_incr_raddr = X154_Y129_incr_raddr;
	wire [ADDR_WIDTH-1:0] X153_Y128_raddr;
	assign X153_Y128_raddr = X154_Y129_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X154_Y129(.clk(bus_clock),
		.incr_waddr(X154_Y129_incr_waddr),
		.waddr(X154_Y129_waddr),
		.incr_raddr(X154_Y129_incr_raddr),
		.raddr(X154_Y129_raddr));


	/* generated from C@X238_Y129@{W[2][4],W[2][3]}@4 */

	logic X238_Y129_incr_waddr; // ingress control
	logic X238_Y129_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) west_to_east_sector_size_2_west_to_east_ip_size_3_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][4][0]),
		.out(X238_Y129_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) west_to_east_sector_size_2_west_to_east_ip_size_3_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][4][1]),
		.out(X238_Y129_incr_raddr));

	logic [ADDR_WIDTH-1:0] X238_Y129_waddr;
	logic [ADDR_WIDTH-1:0] X238_Y129_raddr;

	/* positional aliases */

	wire X239_Y129_incr_waddr;
	assign X239_Y129_incr_waddr = X238_Y129_incr_waddr;
	wire [ADDR_WIDTH-1:0] X239_Y129_waddr;
	assign X239_Y129_waddr = X238_Y129_waddr;
	wire X239_Y128_incr_raddr;
	assign X239_Y128_incr_raddr = X238_Y129_incr_raddr;
	wire [ADDR_WIDTH-1:0] X239_Y128_raddr;
	assign X239_Y128_raddr = X238_Y129_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X238_Y129(.clk(bus_clock),
		.incr_waddr(X238_Y129_incr_waddr),
		.waddr(X238_Y129_waddr),
		.incr_raddr(X238_Y129_incr_raddr),
		.raddr(X238_Y129_raddr));


	/* generated from I@X239_Y129@{W[2][4],W[2][3]}@4 */

	logic [DATA_WIDTH-1:0] X239_Y129_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_2_west_to_east_ip_size_3_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][4][10:0], west_in_reg[2][3][10:2]}),
		.out(X239_Y129_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X239_Y129(.data(X239_Y129_bus_wdata),
		.q(/* to design */),
		.wraddress(X239_Y129_waddr),
		.rdaddress(/* from design */),
		.wren(X239_Y129_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X153_Y128@{E[2][4],E[2][3]}@4 */

	logic [DATA_WIDTH-1:0] X153_Y128_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X153_Y128_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) east_to_west_sector_size_2_east_to_west_ip_size_3_bus_first_egress_fifo(.clock(bus_clock),
		.in(X153_Y128_bus_rdata_in),
		.out(X153_Y128_bus_rdata_out));

	assign west_out_reg[2][4][10:0] = X153_Y128_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][3][10:2] = X153_Y128_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X153_Y128(.data(/* from design */),
		.q(X153_Y128_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X153_Y128_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X239_Y128@{W[2][4],W[2][3]}@5 */

	logic [DATA_WIDTH-1:0] X239_Y128_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X239_Y128_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_2_west_to_east_ip_size_3_bus_first_egress_fifo(.clock(bus_clock),
		.in(X239_Y128_bus_rdata_in),
		.out(X239_Y128_bus_rdata_out));

	assign east_out_reg[2][4][10:0] = X239_Y128_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][3][10:2] = X239_Y128_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X239_Y128(.data(/* from design */),
		.q(X239_Y128_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X239_Y128_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X152_Y127@{W[2][2],W[2][1]}@2 */

	logic X152_Y127_incr_waddr; // ingress control
	logic X152_Y127_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) west_to_east_sector_size_2_west_to_east_ip_size_1_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[2][1][0]),
		.out(X152_Y127_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) west_to_east_sector_size_2_west_to_east_ip_size_1_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[2][1][1]),
		.out(X152_Y127_incr_raddr));

	logic [ADDR_WIDTH-1:0] X152_Y127_waddr;
	logic [ADDR_WIDTH-1:0] X152_Y127_raddr;

	/* positional aliases */

	wire X153_Y127_incr_waddr;
	assign X153_Y127_incr_waddr = X152_Y127_incr_waddr;
	wire [ADDR_WIDTH-1:0] X153_Y127_waddr;
	assign X153_Y127_waddr = X152_Y127_waddr;
	wire X153_Y126_incr_raddr;
	assign X153_Y126_incr_raddr = X152_Y127_incr_raddr;
	wire [ADDR_WIDTH-1:0] X153_Y126_raddr;
	assign X153_Y126_raddr = X152_Y127_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X152_Y127(.clk(bus_clock),
		.incr_waddr(X152_Y127_incr_waddr),
		.waddr(X152_Y127_waddr),
		.incr_raddr(X152_Y127_incr_raddr),
		.raddr(X152_Y127_raddr));


	/* generated from I@X153_Y127@{W[2][2],W[2][1]}@2 */

	logic [DATA_WIDTH-1:0] X153_Y127_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) west_to_east_sector_size_2_west_to_east_ip_size_1_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[2][2][10:0], west_in_reg[2][1][10:2]}),
		.out(X153_Y127_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X153_Y127(.data(X153_Y127_bus_wdata),
		.q(/* to design */),
		.wraddress(X153_Y127_waddr),
		.rdaddress(/* from design */),
		.wren(X153_Y127_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from I@X239_Y127@{E[2][2],E[2][1]}@1 */

	logic [DATA_WIDTH-1:0] X239_Y127_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_1_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[2][2][10:0], east_in_reg[2][1][10:2]}),
		.out(X239_Y127_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X239_Y127(.data(X239_Y127_bus_wdata),
		.q(/* to design */),
		.wraddress(X239_Y127_waddr),
		.rdaddress(/* from design */),
		.wren(X239_Y127_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X240_Y127@{E[2][2],E[2][1]}@1 */

	logic X240_Y127_incr_waddr; // ingress control
	logic X240_Y127_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_1_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[2][2][0]),
		.out(X240_Y127_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_2_east_to_west_ip_size_1_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[2][2][1]),
		.out(X240_Y127_incr_raddr));

	logic [ADDR_WIDTH-1:0] X240_Y127_waddr;
	logic [ADDR_WIDTH-1:0] X240_Y127_raddr;

	/* positional aliases */

	wire X239_Y127_incr_waddr;
	assign X239_Y127_incr_waddr = X240_Y127_incr_waddr;
	wire [ADDR_WIDTH-1:0] X239_Y127_waddr;
	assign X239_Y127_waddr = X240_Y127_waddr;
	wire X239_Y126_incr_raddr;
	assign X239_Y126_incr_raddr = X240_Y127_incr_raddr;
	wire [ADDR_WIDTH-1:0] X239_Y126_raddr;
	assign X239_Y126_raddr = X240_Y127_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X240_Y127(.clk(bus_clock),
		.incr_waddr(X240_Y127_incr_waddr),
		.waddr(X240_Y127_waddr),
		.incr_raddr(X240_Y127_incr_raddr),
		.raddr(X240_Y127_raddr));


	/* generated from E@X153_Y126@{W[2][2],W[2][1]}@3 */

	logic [DATA_WIDTH-1:0] X153_Y126_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X153_Y126_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) west_to_east_sector_size_2_west_to_east_ip_size_1_bus_first_egress_fifo(.clock(bus_clock),
		.in(X153_Y126_bus_rdata_in),
		.out(X153_Y126_bus_rdata_out));

	assign east_out_reg[2][2][10:0] = X153_Y126_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[2][1][10:2] = X153_Y126_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X153_Y126(.data(/* from design */),
		.q(X153_Y126_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X153_Y126_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X239_Y126@{E[2][2],E[2][1]}@2 */

	logic [DATA_WIDTH-1:0] X239_Y126_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X239_Y126_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_2_east_to_west_ip_size_1_bus_first_egress_fifo(.clock(bus_clock),
		.in(X239_Y126_bus_rdata_in),
		.out(X239_Y126_bus_rdata_out));

	assign west_out_reg[2][2][10:0] = X239_Y126_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[2][1][10:2] = X239_Y126_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X239_Y126(.data(/* from design */),
		.q(X239_Y126_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X239_Y126_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X83_Y124@{E[1][40],E[1][39]}@5 */

	logic [DATA_WIDTH-1:0] X83_Y124_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) east_to_west_sector_size_1_east_to_west_ip_size_39_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][40][10:0], east_in_reg[1][39][10:2]}),
		.out(X83_Y124_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X83_Y124(.data(X83_Y124_bus_wdata),
		.q(/* to design */),
		.wraddress(X83_Y124_waddr),
		.rdaddress(/* from design */),
		.wren(X83_Y124_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X84_Y124@{E[1][40],E[1][39]}@5 */

	logic X84_Y124_incr_waddr; // ingress control
	logic X84_Y124_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) east_to_west_sector_size_1_east_to_west_ip_size_39_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][39][0]),
		.out(X84_Y124_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) east_to_west_sector_size_1_east_to_west_ip_size_39_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][39][1]),
		.out(X84_Y124_incr_raddr));

	logic [ADDR_WIDTH-1:0] X84_Y124_waddr;
	logic [ADDR_WIDTH-1:0] X84_Y124_raddr;

	/* positional aliases */

	wire X83_Y124_incr_waddr;
	assign X83_Y124_incr_waddr = X84_Y124_incr_waddr;
	wire [ADDR_WIDTH-1:0] X83_Y124_waddr;
	assign X83_Y124_waddr = X84_Y124_waddr;
	wire X83_Y123_incr_raddr;
	assign X83_Y123_incr_raddr = X84_Y124_incr_raddr;
	wire [ADDR_WIDTH-1:0] X83_Y123_raddr;
	assign X83_Y123_raddr = X84_Y124_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X84_Y124(.clk(bus_clock),
		.incr_waddr(X84_Y124_incr_waddr),
		.waddr(X84_Y124_waddr),
		.incr_raddr(X84_Y124_incr_raddr),
		.raddr(X84_Y124_raddr));


	/* generated from C@X184_Y124@{W[1][40],W[1][39]}@3 */

	logic X184_Y124_incr_waddr; // ingress control
	logic X184_Y124_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_1_west_to_east_ip_size_39_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][40][0]),
		.out(X184_Y124_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_1_west_to_east_ip_size_39_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][40][1]),
		.out(X184_Y124_incr_raddr));

	logic [ADDR_WIDTH-1:0] X184_Y124_waddr;
	logic [ADDR_WIDTH-1:0] X184_Y124_raddr;

	/* positional aliases */

	wire X185_Y124_incr_waddr;
	assign X185_Y124_incr_waddr = X184_Y124_incr_waddr;
	wire [ADDR_WIDTH-1:0] X185_Y124_waddr;
	assign X185_Y124_waddr = X184_Y124_waddr;
	wire X185_Y123_incr_raddr;
	assign X185_Y123_incr_raddr = X184_Y124_incr_raddr;
	wire [ADDR_WIDTH-1:0] X185_Y123_raddr;
	assign X185_Y123_raddr = X184_Y124_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X184_Y124(.clk(bus_clock),
		.incr_waddr(X184_Y124_incr_waddr),
		.waddr(X184_Y124_waddr),
		.incr_raddr(X184_Y124_incr_raddr),
		.raddr(X184_Y124_raddr));


	/* generated from I@X185_Y124@{W[1][40],W[1][39]}@3 */

	logic [DATA_WIDTH-1:0] X185_Y124_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) west_to_east_sector_size_1_west_to_east_ip_size_39_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][40][10:0], west_in_reg[1][39][10:2]}),
		.out(X185_Y124_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X185_Y124(.data(X185_Y124_bus_wdata),
		.q(/* to design */),
		.wraddress(X185_Y124_waddr),
		.rdaddress(/* from design */),
		.wren(X185_Y124_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X83_Y123@{E[1][40],E[1][39]}@6 */

	logic [DATA_WIDTH-1:0] X83_Y123_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X83_Y123_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) east_to_west_sector_size_1_east_to_west_ip_size_39_bus_first_egress_fifo(.clock(bus_clock),
		.in(X83_Y123_bus_rdata_in),
		.out(X83_Y123_bus_rdata_out));

	assign west_out_reg[1][40][10:0] = X83_Y123_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][39][10:2] = X83_Y123_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X83_Y123(.data(/* from design */),
		.q(X83_Y123_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X83_Y123_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X185_Y123@{W[1][40],W[1][39]}@4 */

	logic [DATA_WIDTH-1:0] X185_Y123_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X185_Y123_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) west_to_east_sector_size_1_west_to_east_ip_size_39_bus_first_egress_fifo(.clock(bus_clock),
		.in(X185_Y123_bus_rdata_in),
		.out(X185_Y123_bus_rdata_out));

	assign east_out_reg[1][40][10:0] = X185_Y123_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][39][10:2] = X185_Y123_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X185_Y123(.data(/* from design */),
		.q(X185_Y123_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X185_Y123_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X82_Y122@{W[1][38],W[1][37]}@0 */

	logic X82_Y122_incr_waddr; // ingress control
	logic X82_Y122_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) west_to_east_sector_size_1_west_to_east_ip_size_37_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][37][0]),
		.out(X82_Y122_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) west_to_east_sector_size_1_west_to_east_ip_size_37_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][37][1]),
		.out(X82_Y122_incr_raddr));

	logic [ADDR_WIDTH-1:0] X82_Y122_waddr;
	logic [ADDR_WIDTH-1:0] X82_Y122_raddr;

	/* positional aliases */

	wire X83_Y122_incr_waddr;
	assign X83_Y122_incr_waddr = X82_Y122_incr_waddr;
	wire [ADDR_WIDTH-1:0] X83_Y122_waddr;
	assign X83_Y122_waddr = X82_Y122_waddr;
	wire X83_Y121_incr_raddr;
	assign X83_Y121_incr_raddr = X82_Y122_incr_raddr;
	wire [ADDR_WIDTH-1:0] X83_Y121_raddr;
	assign X83_Y121_raddr = X82_Y122_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X82_Y122(.clk(bus_clock),
		.incr_waddr(X82_Y122_incr_waddr),
		.waddr(X82_Y122_waddr),
		.incr_raddr(X82_Y122_incr_raddr),
		.raddr(X82_Y122_raddr));


	/* generated from I@X83_Y122@{W[1][38],W[1][37]}@0 */

	logic [DATA_WIDTH-1:0] X83_Y122_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) west_to_east_sector_size_1_west_to_east_ip_size_37_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][38][10:0], west_in_reg[1][37][10:2]}),
		.out(X83_Y122_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X83_Y122(.data(X83_Y122_bus_wdata),
		.q(/* to design */),
		.wraddress(X83_Y122_waddr),
		.rdaddress(/* from design */),
		.wren(X83_Y122_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from I@X185_Y122@{E[1][38],E[1][37]}@2 */

	logic [DATA_WIDTH-1:0] X185_Y122_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) east_to_west_sector_size_1_east_to_west_ip_size_37_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][38][10:0], east_in_reg[1][37][10:2]}),
		.out(X185_Y122_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X185_Y122(.data(X185_Y122_bus_wdata),
		.q(/* to design */),
		.wraddress(X185_Y122_waddr),
		.rdaddress(/* from design */),
		.wren(X185_Y122_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X186_Y122@{E[1][38],E[1][37]}@2 */

	logic X186_Y122_incr_waddr; // ingress control
	logic X186_Y122_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) east_to_west_sector_size_1_east_to_west_ip_size_37_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][38][0]),
		.out(X186_Y122_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) east_to_west_sector_size_1_east_to_west_ip_size_37_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][38][1]),
		.out(X186_Y122_incr_raddr));

	logic [ADDR_WIDTH-1:0] X186_Y122_waddr;
	logic [ADDR_WIDTH-1:0] X186_Y122_raddr;

	/* positional aliases */

	wire X185_Y122_incr_waddr;
	assign X185_Y122_incr_waddr = X186_Y122_incr_waddr;
	wire [ADDR_WIDTH-1:0] X185_Y122_waddr;
	assign X185_Y122_waddr = X186_Y122_waddr;
	wire X185_Y121_incr_raddr;
	assign X185_Y121_incr_raddr = X186_Y122_incr_raddr;
	wire [ADDR_WIDTH-1:0] X185_Y121_raddr;
	assign X185_Y121_raddr = X186_Y122_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X186_Y122(.clk(bus_clock),
		.incr_waddr(X186_Y122_incr_waddr),
		.waddr(X186_Y122_waddr),
		.incr_raddr(X186_Y122_incr_raddr),
		.raddr(X186_Y122_raddr));


	/* generated from E@X83_Y121@{W[1][38],W[1][37]}@1 */

	logic [DATA_WIDTH-1:0] X83_Y121_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X83_Y121_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) west_to_east_sector_size_1_west_to_east_ip_size_37_bus_first_egress_fifo(.clock(bus_clock),
		.in(X83_Y121_bus_rdata_in),
		.out(X83_Y121_bus_rdata_out));

	assign east_out_reg[1][38][10:0] = X83_Y121_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][37][10:2] = X83_Y121_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X83_Y121(.data(/* from design */),
		.q(X83_Y121_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X83_Y121_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X185_Y121@{E[1][38],E[1][37]}@3 */

	logic [DATA_WIDTH-1:0] X185_Y121_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X185_Y121_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) east_to_west_sector_size_1_east_to_west_ip_size_37_bus_first_egress_fifo(.clock(bus_clock),
		.in(X185_Y121_bus_rdata_in),
		.out(X185_Y121_bus_rdata_out));

	assign west_out_reg[1][38][10:0] = X185_Y121_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][37][10:2] = X185_Y121_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X185_Y121(.data(/* from design */),
		.q(X185_Y121_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X185_Y121_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X132_Y120@{E[1][36],E[1][35]}@4 */

	logic [DATA_WIDTH-1:0] X132_Y120_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_1_east_to_west_ip_size_35_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][36][10:0], east_in_reg[1][35][10:2]}),
		.out(X132_Y120_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X132_Y120(.data(X132_Y120_bus_wdata),
		.q(/* to design */),
		.wraddress(X132_Y120_waddr),
		.rdaddress(/* from design */),
		.wren(X132_Y120_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X133_Y120@{E[1][36],E[1][35]}@4 */

	logic X133_Y120_incr_waddr; // ingress control
	logic X133_Y120_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_1_east_to_west_ip_size_35_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][35][0]),
		.out(X133_Y120_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_1_east_to_west_ip_size_35_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][35][1]),
		.out(X133_Y120_incr_raddr));

	logic [ADDR_WIDTH-1:0] X133_Y120_waddr;
	logic [ADDR_WIDTH-1:0] X133_Y120_raddr;

	/* positional aliases */

	wire X132_Y120_incr_waddr;
	assign X132_Y120_incr_waddr = X133_Y120_incr_waddr;
	wire [ADDR_WIDTH-1:0] X132_Y120_waddr;
	assign X132_Y120_waddr = X133_Y120_waddr;
	wire X132_Y119_incr_raddr;
	assign X132_Y119_incr_raddr = X133_Y120_incr_raddr;
	wire [ADDR_WIDTH-1:0] X132_Y119_raddr;
	assign X132_Y119_raddr = X133_Y120_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X133_Y120(.clk(bus_clock),
		.incr_waddr(X133_Y120_incr_waddr),
		.waddr(X133_Y120_waddr),
		.incr_raddr(X133_Y120_incr_raddr),
		.raddr(X133_Y120_raddr));


	/* generated from C@X259_Y120@{W[1][36],W[1][35]}@5 */

	logic X259_Y120_incr_waddr; // ingress control
	logic X259_Y120_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) west_to_east_sector_size_1_west_to_east_ip_size_35_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][36][0]),
		.out(X259_Y120_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) west_to_east_sector_size_1_west_to_east_ip_size_35_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][36][1]),
		.out(X259_Y120_incr_raddr));

	logic [ADDR_WIDTH-1:0] X259_Y120_waddr;
	logic [ADDR_WIDTH-1:0] X259_Y120_raddr;

	/* positional aliases */

	wire X260_Y120_incr_waddr;
	assign X260_Y120_incr_waddr = X259_Y120_incr_waddr;
	wire [ADDR_WIDTH-1:0] X260_Y120_waddr;
	assign X260_Y120_waddr = X259_Y120_waddr;
	wire X260_Y119_incr_raddr;
	assign X260_Y119_incr_raddr = X259_Y120_incr_raddr;
	wire [ADDR_WIDTH-1:0] X260_Y119_raddr;
	assign X260_Y119_raddr = X259_Y120_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X259_Y120(.clk(bus_clock),
		.incr_waddr(X259_Y120_incr_waddr),
		.waddr(X259_Y120_waddr),
		.incr_raddr(X259_Y120_incr_raddr),
		.raddr(X259_Y120_raddr));


	/* generated from I@X260_Y120@{W[1][36],W[1][35]}@5 */

	logic [DATA_WIDTH-1:0] X260_Y120_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) west_to_east_sector_size_1_west_to_east_ip_size_35_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][36][10:0], west_in_reg[1][35][10:2]}),
		.out(X260_Y120_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X260_Y120(.data(X260_Y120_bus_wdata),
		.q(/* to design */),
		.wraddress(X260_Y120_waddr),
		.rdaddress(/* from design */),
		.wren(X260_Y120_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X132_Y119@{E[1][36],E[1][35]}@5 */

	logic [DATA_WIDTH-1:0] X132_Y119_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X132_Y119_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_1_east_to_west_ip_size_35_bus_first_egress_fifo(.clock(bus_clock),
		.in(X132_Y119_bus_rdata_in),
		.out(X132_Y119_bus_rdata_out));

	assign west_out_reg[1][36][10:0] = X132_Y119_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][35][10:2] = X132_Y119_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X132_Y119(.data(/* from design */),
		.q(X132_Y119_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X132_Y119_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X260_Y119@{W[1][36],W[1][35]}@6 */

	logic [DATA_WIDTH-1:0] X260_Y119_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X260_Y119_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) west_to_east_sector_size_1_west_to_east_ip_size_35_bus_first_egress_fifo(.clock(bus_clock),
		.in(X260_Y119_bus_rdata_in),
		.out(X260_Y119_bus_rdata_out));

	assign east_out_reg[1][36][10:0] = X260_Y119_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][35][10:2] = X260_Y119_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X260_Y119(.data(/* from design */),
		.q(X260_Y119_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X260_Y119_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X131_Y118@{W[1][34],W[1][33]}@1 */

	logic X131_Y118_incr_waddr; // ingress control
	logic X131_Y118_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_1_west_to_east_ip_size_33_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][33][0]),
		.out(X131_Y118_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_1_west_to_east_ip_size_33_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][33][1]),
		.out(X131_Y118_incr_raddr));

	logic [ADDR_WIDTH-1:0] X131_Y118_waddr;
	logic [ADDR_WIDTH-1:0] X131_Y118_raddr;

	/* positional aliases */

	wire X132_Y118_incr_waddr;
	assign X132_Y118_incr_waddr = X131_Y118_incr_waddr;
	wire [ADDR_WIDTH-1:0] X132_Y118_waddr;
	assign X132_Y118_waddr = X131_Y118_waddr;
	wire X132_Y117_incr_raddr;
	assign X132_Y117_incr_raddr = X131_Y118_incr_raddr;
	wire [ADDR_WIDTH-1:0] X132_Y117_raddr;
	assign X132_Y117_raddr = X131_Y118_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X131_Y118(.clk(bus_clock),
		.incr_waddr(X131_Y118_incr_waddr),
		.waddr(X131_Y118_waddr),
		.incr_raddr(X131_Y118_incr_raddr),
		.raddr(X131_Y118_raddr));


	/* generated from I@X132_Y118@{W[1][34],W[1][33]}@1 */

	logic [DATA_WIDTH-1:0] X132_Y118_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_1_west_to_east_ip_size_33_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][34][10:0], west_in_reg[1][33][10:2]}),
		.out(X132_Y118_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X132_Y118(.data(X132_Y118_bus_wdata),
		.q(/* to design */),
		.wraddress(X132_Y118_waddr),
		.rdaddress(/* from design */),
		.wren(X132_Y118_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X146_Y118@{N[1][19],N[1][20]}@2 */

	logic X146_Y118_incr_waddr; // ingress control
	logic X146_Y118_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_20_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][20][0]),
		.out(X146_Y118_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_20_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][20][1]),
		.out(X146_Y118_incr_raddr));

	logic [ADDR_WIDTH-1:0] X146_Y118_waddr;
	logic [ADDR_WIDTH-1:0] X146_Y118_raddr;

	/* positional aliases */

	wire X147_Y118_incr_waddr;
	assign X147_Y118_incr_waddr = X146_Y118_incr_waddr;
	wire [ADDR_WIDTH-1:0] X147_Y118_waddr;
	assign X147_Y118_waddr = X146_Y118_waddr;
	wire X147_Y117_incr_raddr;
	assign X147_Y117_incr_raddr = X146_Y118_incr_raddr;
	wire [ADDR_WIDTH-1:0] X147_Y117_raddr;
	assign X147_Y117_raddr = X146_Y118_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X146_Y118(.clk(bus_clock),
		.incr_waddr(X146_Y118_incr_waddr),
		.waddr(X146_Y118_waddr),
		.incr_raddr(X146_Y118_incr_raddr),
		.raddr(X146_Y118_raddr));


	/* generated from I@X147_Y118@{N[1][20],N[1][21]}@2 */

	logic [DATA_WIDTH-1:0] X147_Y118_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_21_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][20][10:0], north_in_reg[1][21][10:2]}),
		.out(X147_Y118_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X147_Y118(.data(X147_Y118_bus_wdata),
		.q(/* to design */),
		.wraddress(X147_Y118_waddr),
		.rdaddress(/* from design */),
		.wren(X147_Y118_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X149_Y118@{S[1][22],S[1][23]}@4 */

	logic [DATA_WIDTH-1:0] X149_Y118_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X149_Y118_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_23_bus_first_egress_fifo(.clock(bus_clock),
		.in(X149_Y118_bus_rdata_in),
		.out(X149_Y118_bus_rdata_out));

	assign north_out_reg[1][22][10:0] = X149_Y118_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][23][10:2] = X149_Y118_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X149_Y118(.data(/* from design */),
		.q(X149_Y118_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X149_Y118_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X157_Y118@{N[1][27],N[1][28]}@2 */

	logic X157_Y118_incr_waddr; // ingress control
	logic X157_Y118_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_28_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][28][0]),
		.out(X157_Y118_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_28_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][28][1]),
		.out(X157_Y118_incr_raddr));

	logic [ADDR_WIDTH-1:0] X157_Y118_waddr;
	logic [ADDR_WIDTH-1:0] X157_Y118_raddr;

	/* positional aliases */

	wire X158_Y118_incr_waddr;
	assign X158_Y118_incr_waddr = X157_Y118_incr_waddr;
	wire [ADDR_WIDTH-1:0] X158_Y118_waddr;
	assign X158_Y118_waddr = X157_Y118_waddr;
	wire X158_Y117_incr_raddr;
	assign X158_Y117_incr_raddr = X157_Y118_incr_raddr;
	wire [ADDR_WIDTH-1:0] X158_Y117_raddr;
	assign X158_Y117_raddr = X157_Y118_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X157_Y118(.clk(bus_clock),
		.incr_waddr(X157_Y118_incr_waddr),
		.waddr(X157_Y118_waddr),
		.incr_raddr(X157_Y118_incr_raddr),
		.raddr(X157_Y118_raddr));


	/* generated from I@X158_Y118@{N[1][28],N[1][29]}@2 */

	logic [DATA_WIDTH-1:0] X158_Y118_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_29_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][28][10:0], north_in_reg[1][29][10:2]}),
		.out(X158_Y118_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X158_Y118(.data(X158_Y118_bus_wdata),
		.q(/* to design */),
		.wraddress(X158_Y118_waddr),
		.rdaddress(/* from design */),
		.wren(X158_Y118_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X160_Y118@{S[1][30],S[1][31]}@4 */

	logic [DATA_WIDTH-1:0] X160_Y118_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X160_Y118_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_31_bus_first_egress_fifo(.clock(bus_clock),
		.in(X160_Y118_bus_rdata_in),
		.out(X160_Y118_bus_rdata_out));

	assign north_out_reg[1][30][10:0] = X160_Y118_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][31][10:2] = X160_Y118_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X160_Y118(.data(/* from design */),
		.q(X160_Y118_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X160_Y118_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X231_Y118@{N[3][5],N[3][4]}@2 */

	logic [DATA_WIDTH-1:0] X231_Y118_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_4_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][5][10:0], north_in_reg[3][4][10:2]}),
		.out(X231_Y118_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X231_Y118(.data(X231_Y118_bus_wdata),
		.q(/* to design */),
		.wraddress(X231_Y118_waddr),
		.rdaddress(/* from design */),
		.wren(X231_Y118_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X232_Y118@{N[3][6],N[3][5]}@2 */

	logic X232_Y118_incr_waddr; // ingress control
	logic X232_Y118_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_5_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][6][0]),
		.out(X232_Y118_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_5_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][6][1]),
		.out(X232_Y118_incr_raddr));

	logic [ADDR_WIDTH-1:0] X232_Y118_waddr;
	logic [ADDR_WIDTH-1:0] X232_Y118_raddr;

	/* positional aliases */

	wire X231_Y118_incr_waddr;
	assign X231_Y118_incr_waddr = X232_Y118_incr_waddr;
	wire [ADDR_WIDTH-1:0] X231_Y118_waddr;
	assign X231_Y118_waddr = X232_Y118_waddr;
	wire X231_Y117_incr_raddr;
	assign X231_Y117_incr_raddr = X232_Y118_incr_raddr;
	wire [ADDR_WIDTH-1:0] X231_Y117_raddr;
	assign X231_Y117_raddr = X232_Y118_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X232_Y118(.clk(bus_clock),
		.incr_waddr(X232_Y118_incr_waddr),
		.waddr(X232_Y118_waddr),
		.incr_raddr(X232_Y118_incr_raddr),
		.raddr(X232_Y118_raddr));


	/* generated from E@X233_Y118@{S[3][7],S[3][6]}@4 */

	logic [DATA_WIDTH-1:0] X233_Y118_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X233_Y118_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_6_bus_first_egress_fifo(.clock(bus_clock),
		.in(X233_Y118_bus_rdata_in),
		.out(X233_Y118_bus_rdata_out));

	assign north_out_reg[3][7][10:0] = X233_Y118_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][6][10:2] = X233_Y118_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X233_Y118(.data(/* from design */),
		.q(X233_Y118_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X233_Y118_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X242_Y118@{N[3][13],N[3][12]}@2 */

	logic [DATA_WIDTH-1:0] X242_Y118_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_12_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][13][10:0], north_in_reg[3][12][10:2]}),
		.out(X242_Y118_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X242_Y118(.data(X242_Y118_bus_wdata),
		.q(/* to design */),
		.wraddress(X242_Y118_waddr),
		.rdaddress(/* from design */),
		.wren(X242_Y118_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X243_Y118@{N[3][14],N[3][13]}@2 */

	logic X243_Y118_incr_waddr; // ingress control
	logic X243_Y118_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_13_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][14][0]),
		.out(X243_Y118_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_13_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][14][1]),
		.out(X243_Y118_incr_raddr));

	logic [ADDR_WIDTH-1:0] X243_Y118_waddr;
	logic [ADDR_WIDTH-1:0] X243_Y118_raddr;

	/* positional aliases */

	wire X242_Y118_incr_waddr;
	assign X242_Y118_incr_waddr = X243_Y118_incr_waddr;
	wire [ADDR_WIDTH-1:0] X242_Y118_waddr;
	assign X242_Y118_waddr = X243_Y118_waddr;
	wire X242_Y117_incr_raddr;
	assign X242_Y117_incr_raddr = X243_Y118_incr_raddr;
	wire [ADDR_WIDTH-1:0] X242_Y117_raddr;
	assign X242_Y117_raddr = X243_Y118_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X243_Y118(.clk(bus_clock),
		.incr_waddr(X243_Y118_incr_waddr),
		.waddr(X243_Y118_waddr),
		.incr_raddr(X243_Y118_incr_raddr),
		.raddr(X243_Y118_raddr));


	/* generated from E@X244_Y118@{S[3][15],S[3][14]}@4 */

	logic [DATA_WIDTH-1:0] X244_Y118_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X244_Y118_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_14_bus_first_egress_fifo(.clock(bus_clock),
		.in(X244_Y118_bus_rdata_in),
		.out(X244_Y118_bus_rdata_out));

	assign north_out_reg[3][15][10:0] = X244_Y118_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][14][10:2] = X244_Y118_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X244_Y118(.data(/* from design */),
		.q(X244_Y118_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X244_Y118_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X260_Y118@{E[1][34],E[1][33]}@0 */

	logic [DATA_WIDTH-1:0] X260_Y118_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) east_to_west_sector_size_1_east_to_west_ip_size_33_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][34][10:0], east_in_reg[1][33][10:2]}),
		.out(X260_Y118_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X260_Y118(.data(X260_Y118_bus_wdata),
		.q(/* to design */),
		.wraddress(X260_Y118_waddr),
		.rdaddress(/* from design */),
		.wren(X260_Y118_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X261_Y118@{E[1][34],E[1][33]}@0 */

	logic X261_Y118_incr_waddr; // ingress control
	logic X261_Y118_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) east_to_west_sector_size_1_east_to_west_ip_size_33_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][34][0]),
		.out(X261_Y118_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) east_to_west_sector_size_1_east_to_west_ip_size_33_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][34][1]),
		.out(X261_Y118_incr_raddr));

	logic [ADDR_WIDTH-1:0] X261_Y118_waddr;
	logic [ADDR_WIDTH-1:0] X261_Y118_raddr;

	/* positional aliases */

	wire X260_Y118_incr_waddr;
	assign X260_Y118_incr_waddr = X261_Y118_incr_waddr;
	wire [ADDR_WIDTH-1:0] X260_Y118_waddr;
	assign X260_Y118_waddr = X261_Y118_waddr;
	wire X260_Y117_incr_raddr;
	assign X260_Y117_incr_raddr = X261_Y118_incr_raddr;
	wire [ADDR_WIDTH-1:0] X260_Y117_raddr;
	assign X260_Y117_raddr = X261_Y118_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X261_Y118(.clk(bus_clock),
		.incr_waddr(X261_Y118_incr_waddr),
		.waddr(X261_Y118_waddr),
		.incr_raddr(X261_Y118_incr_raddr),
		.raddr(X261_Y118_raddr));


	/* generated from I@X274_Y118@{N[3][37],N[3][36]}@2 */

	logic [DATA_WIDTH-1:0] X274_Y118_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_36_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][37][10:0], north_in_reg[3][36][10:2]}),
		.out(X274_Y118_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X274_Y118(.data(X274_Y118_bus_wdata),
		.q(/* to design */),
		.wraddress(X274_Y118_waddr),
		.rdaddress(/* from design */),
		.wren(X274_Y118_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X275_Y118@{N[3][38],N[3][37]}@2 */

	logic X275_Y118_incr_waddr; // ingress control
	logic X275_Y118_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_37_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][38][0]),
		.out(X275_Y118_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_37_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][38][1]),
		.out(X275_Y118_incr_raddr));

	logic [ADDR_WIDTH-1:0] X275_Y118_waddr;
	logic [ADDR_WIDTH-1:0] X275_Y118_raddr;

	/* positional aliases */

	wire X274_Y118_incr_waddr;
	assign X274_Y118_incr_waddr = X275_Y118_incr_waddr;
	wire [ADDR_WIDTH-1:0] X274_Y118_waddr;
	assign X274_Y118_waddr = X275_Y118_waddr;
	wire X274_Y117_incr_raddr;
	assign X274_Y117_incr_raddr = X275_Y118_incr_raddr;
	wire [ADDR_WIDTH-1:0] X274_Y117_raddr;
	assign X274_Y117_raddr = X275_Y118_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X275_Y118(.clk(bus_clock),
		.incr_waddr(X275_Y118_incr_waddr),
		.waddr(X275_Y118_waddr),
		.incr_raddr(X275_Y118_incr_raddr),
		.raddr(X275_Y118_raddr));


	/* generated from E@X276_Y118@{S[3][39],S[3][38]}@4 */

	logic [DATA_WIDTH-1:0] X276_Y118_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X276_Y118_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_38_bus_first_egress_fifo(.clock(bus_clock),
		.in(X276_Y118_bus_rdata_in),
		.out(X276_Y118_bus_rdata_out));

	assign north_out_reg[3][39][10:0] = X276_Y118_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][38][10:2] = X276_Y118_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X276_Y118(.data(/* from design */),
		.q(X276_Y118_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X276_Y118_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X132_Y117@{W[1][34],W[1][33]}@2 */

	logic [DATA_WIDTH-1:0] X132_Y117_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X132_Y117_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_1_west_to_east_ip_size_33_bus_first_egress_fifo(.clock(bus_clock),
		.in(X132_Y117_bus_rdata_in),
		.out(X132_Y117_bus_rdata_out));

	assign east_out_reg[1][34][10:0] = X132_Y117_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][33][10:2] = X132_Y117_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X132_Y117(.data(/* from design */),
		.q(X132_Y117_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X132_Y117_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X147_Y117@{N[1][20],N[1][21]}@3 */

	logic [DATA_WIDTH-1:0] X147_Y117_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X147_Y117_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_21_bus_first_egress_fifo(.clock(bus_clock),
		.in(X147_Y117_bus_rdata_in),
		.out(X147_Y117_bus_rdata_out));

	assign south_out_reg[1][20][10:0] = X147_Y117_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][21][10:2] = X147_Y117_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X147_Y117(.data(/* from design */),
		.q(X147_Y117_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X147_Y117_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X148_Y117@{S[1][21],S[1][22]}@3 */

	logic X148_Y117_incr_waddr; // ingress control
	logic X148_Y117_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_22_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][22][0]),
		.out(X148_Y117_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_22_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][22][1]),
		.out(X148_Y117_incr_raddr));

	logic [ADDR_WIDTH-1:0] X148_Y117_waddr;
	logic [ADDR_WIDTH-1:0] X148_Y117_raddr;

	/* positional aliases */

	wire X149_Y117_incr_waddr;
	assign X149_Y117_incr_waddr = X148_Y117_incr_waddr;
	wire [ADDR_WIDTH-1:0] X149_Y117_waddr;
	assign X149_Y117_waddr = X148_Y117_waddr;
	wire X149_Y118_incr_raddr;
	assign X149_Y118_incr_raddr = X148_Y117_incr_raddr;
	wire [ADDR_WIDTH-1:0] X149_Y118_raddr;
	assign X149_Y118_raddr = X148_Y117_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X148_Y117(.clk(bus_clock),
		.incr_waddr(X148_Y117_incr_waddr),
		.waddr(X148_Y117_waddr),
		.incr_raddr(X148_Y117_incr_raddr),
		.raddr(X148_Y117_raddr));


	/* generated from I@X149_Y117@{S[1][22],S[1][23]}@3 */

	logic [DATA_WIDTH-1:0] X149_Y117_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_23_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][22][10:0], south_in_reg[1][23][10:2]}),
		.out(X149_Y117_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X149_Y117(.data(X149_Y117_bus_wdata),
		.q(/* to design */),
		.wraddress(X149_Y117_waddr),
		.rdaddress(/* from design */),
		.wren(X149_Y117_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X158_Y117@{N[1][28],N[1][29]}@3 */

	logic [DATA_WIDTH-1:0] X158_Y117_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X158_Y117_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_29_bus_first_egress_fifo(.clock(bus_clock),
		.in(X158_Y117_bus_rdata_in),
		.out(X158_Y117_bus_rdata_out));

	assign south_out_reg[1][28][10:0] = X158_Y117_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][29][10:2] = X158_Y117_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X158_Y117(.data(/* from design */),
		.q(X158_Y117_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X158_Y117_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X159_Y117@{S[1][29],S[1][30]}@3 */

	logic X159_Y117_incr_waddr; // ingress control
	logic X159_Y117_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_30_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][30][0]),
		.out(X159_Y117_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_30_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][30][1]),
		.out(X159_Y117_incr_raddr));

	logic [ADDR_WIDTH-1:0] X159_Y117_waddr;
	logic [ADDR_WIDTH-1:0] X159_Y117_raddr;

	/* positional aliases */

	wire X160_Y117_incr_waddr;
	assign X160_Y117_incr_waddr = X159_Y117_incr_waddr;
	wire [ADDR_WIDTH-1:0] X160_Y117_waddr;
	assign X160_Y117_waddr = X159_Y117_waddr;
	wire X160_Y118_incr_raddr;
	assign X160_Y118_incr_raddr = X159_Y117_incr_raddr;
	wire [ADDR_WIDTH-1:0] X160_Y118_raddr;
	assign X160_Y118_raddr = X159_Y117_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X159_Y117(.clk(bus_clock),
		.incr_waddr(X159_Y117_incr_waddr),
		.waddr(X159_Y117_waddr),
		.incr_raddr(X159_Y117_incr_raddr),
		.raddr(X159_Y117_raddr));


	/* generated from I@X160_Y117@{S[1][30],S[1][31]}@3 */

	logic [DATA_WIDTH-1:0] X160_Y117_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_31_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][30][10:0], south_in_reg[1][31][10:2]}),
		.out(X160_Y117_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X160_Y117(.data(X160_Y117_bus_wdata),
		.q(/* to design */),
		.wraddress(X160_Y117_waddr),
		.rdaddress(/* from design */),
		.wren(X160_Y117_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X231_Y117@{N[3][5],N[3][4]}@3 */

	logic [DATA_WIDTH-1:0] X231_Y117_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X231_Y117_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_4_bus_first_egress_fifo(.clock(bus_clock),
		.in(X231_Y117_bus_rdata_in),
		.out(X231_Y117_bus_rdata_out));

	assign south_out_reg[3][5][10:0] = X231_Y117_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][4][10:2] = X231_Y117_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X231_Y117(.data(/* from design */),
		.q(X231_Y117_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X231_Y117_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X233_Y117@{S[3][7],S[3][6]}@3 */

	logic [DATA_WIDTH-1:0] X233_Y117_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_6_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][7][10:0], south_in_reg[3][6][10:2]}),
		.out(X233_Y117_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X233_Y117(.data(X233_Y117_bus_wdata),
		.q(/* to design */),
		.wraddress(X233_Y117_waddr),
		.rdaddress(/* from design */),
		.wren(X233_Y117_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X234_Y117@{S[3][8],S[3][7]}@3 */

	logic X234_Y117_incr_waddr; // ingress control
	logic X234_Y117_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_7_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][8][0]),
		.out(X234_Y117_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_7_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][8][1]),
		.out(X234_Y117_incr_raddr));

	logic [ADDR_WIDTH-1:0] X234_Y117_waddr;
	logic [ADDR_WIDTH-1:0] X234_Y117_raddr;

	/* positional aliases */

	wire X233_Y117_incr_waddr;
	assign X233_Y117_incr_waddr = X234_Y117_incr_waddr;
	wire [ADDR_WIDTH-1:0] X233_Y117_waddr;
	assign X233_Y117_waddr = X234_Y117_waddr;
	wire X233_Y118_incr_raddr;
	assign X233_Y118_incr_raddr = X234_Y117_incr_raddr;
	wire [ADDR_WIDTH-1:0] X233_Y118_raddr;
	assign X233_Y118_raddr = X234_Y117_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X234_Y117(.clk(bus_clock),
		.incr_waddr(X234_Y117_incr_waddr),
		.waddr(X234_Y117_waddr),
		.incr_raddr(X234_Y117_incr_raddr),
		.raddr(X234_Y117_raddr));


	/* generated from E@X242_Y117@{N[3][13],N[3][12]}@3 */

	logic [DATA_WIDTH-1:0] X242_Y117_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X242_Y117_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_12_bus_first_egress_fifo(.clock(bus_clock),
		.in(X242_Y117_bus_rdata_in),
		.out(X242_Y117_bus_rdata_out));

	assign south_out_reg[3][13][10:0] = X242_Y117_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][12][10:2] = X242_Y117_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X242_Y117(.data(/* from design */),
		.q(X242_Y117_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X242_Y117_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X244_Y117@{S[3][15],S[3][14]}@3 */

	logic [DATA_WIDTH-1:0] X244_Y117_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_14_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][15][10:0], south_in_reg[3][14][10:2]}),
		.out(X244_Y117_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X244_Y117(.data(X244_Y117_bus_wdata),
		.q(/* to design */),
		.wraddress(X244_Y117_waddr),
		.rdaddress(/* from design */),
		.wren(X244_Y117_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X245_Y117@{S[3][16],S[3][15]}@3 */

	logic X245_Y117_incr_waddr; // ingress control
	logic X245_Y117_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_15_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][16][0]),
		.out(X245_Y117_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_15_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][16][1]),
		.out(X245_Y117_incr_raddr));

	logic [ADDR_WIDTH-1:0] X245_Y117_waddr;
	logic [ADDR_WIDTH-1:0] X245_Y117_raddr;

	/* positional aliases */

	wire X244_Y117_incr_waddr;
	assign X244_Y117_incr_waddr = X245_Y117_incr_waddr;
	wire [ADDR_WIDTH-1:0] X244_Y117_waddr;
	assign X244_Y117_waddr = X245_Y117_waddr;
	wire X244_Y118_incr_raddr;
	assign X244_Y118_incr_raddr = X245_Y117_incr_raddr;
	wire [ADDR_WIDTH-1:0] X244_Y118_raddr;
	assign X244_Y118_raddr = X245_Y117_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X245_Y117(.clk(bus_clock),
		.incr_waddr(X245_Y117_incr_waddr),
		.waddr(X245_Y117_waddr),
		.incr_raddr(X245_Y117_incr_raddr),
		.raddr(X245_Y117_raddr));


	/* generated from E@X260_Y117@{E[1][34],E[1][33]}@1 */

	logic [DATA_WIDTH-1:0] X260_Y117_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X260_Y117_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) east_to_west_sector_size_1_east_to_west_ip_size_33_bus_first_egress_fifo(.clock(bus_clock),
		.in(X260_Y117_bus_rdata_in),
		.out(X260_Y117_bus_rdata_out));

	assign west_out_reg[1][34][10:0] = X260_Y117_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][33][10:2] = X260_Y117_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X260_Y117(.data(/* from design */),
		.q(X260_Y117_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X260_Y117_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X274_Y117@{N[3][37],N[3][36]}@3 */

	logic [DATA_WIDTH-1:0] X274_Y117_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X274_Y117_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_36_bus_first_egress_fifo(.clock(bus_clock),
		.in(X274_Y117_bus_rdata_in),
		.out(X274_Y117_bus_rdata_out));

	assign south_out_reg[3][37][10:0] = X274_Y117_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][36][10:2] = X274_Y117_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X274_Y117(.data(/* from design */),
		.q(X274_Y117_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X274_Y117_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X276_Y117@{S[3][39],S[3][38]}@3 */

	logic [DATA_WIDTH-1:0] X276_Y117_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_38_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][39][10:0], south_in_reg[3][38][10:2]}),
		.out(X276_Y117_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X276_Y117(.data(X276_Y117_bus_wdata),
		.q(/* to design */),
		.wraddress(X276_Y117_waddr),
		.rdaddress(/* from design */),
		.wren(X276_Y117_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X277_Y117@{,S[3][39]}@3 */

	logic X277_Y117_incr_waddr; // ingress control
	logic X277_Y117_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_39_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][39][0]),
		.out(X277_Y117_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_39_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][39][1]),
		.out(X277_Y117_incr_raddr));

	logic [ADDR_WIDTH-1:0] X277_Y117_waddr;
	logic [ADDR_WIDTH-1:0] X277_Y117_raddr;

	/* positional aliases */

	wire X276_Y117_incr_waddr;
	assign X276_Y117_incr_waddr = X277_Y117_incr_waddr;
	wire [ADDR_WIDTH-1:0] X276_Y117_waddr;
	assign X276_Y117_waddr = X277_Y117_waddr;
	wire X276_Y118_incr_raddr;
	assign X276_Y118_incr_raddr = X277_Y117_incr_raddr;
	wire [ADDR_WIDTH-1:0] X276_Y118_raddr;
	assign X276_Y118_raddr = X277_Y117_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X277_Y117(.clk(bus_clock),
		.incr_waddr(X277_Y117_incr_waddr),
		.waddr(X277_Y117_waddr),
		.incr_raddr(X277_Y117_incr_raddr),
		.raddr(X277_Y117_raddr));


	/* generated from I@X104_Y116@{E[1][32],E[1][31]}@4 */

	logic [DATA_WIDTH-1:0] X104_Y116_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_1_east_to_west_ip_size_31_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][32][10:0], east_in_reg[1][31][10:2]}),
		.out(X104_Y116_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X104_Y116(.data(X104_Y116_bus_wdata),
		.q(/* to design */),
		.wraddress(X104_Y116_waddr),
		.rdaddress(/* from design */),
		.wren(X104_Y116_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X105_Y116@{E[1][32],E[1][31]}@4 */

	logic X105_Y116_incr_waddr; // ingress control
	logic X105_Y116_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_1_east_to_west_ip_size_31_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][31][0]),
		.out(X105_Y116_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_1_east_to_west_ip_size_31_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][31][1]),
		.out(X105_Y116_incr_raddr));

	logic [ADDR_WIDTH-1:0] X105_Y116_waddr;
	logic [ADDR_WIDTH-1:0] X105_Y116_raddr;

	/* positional aliases */

	wire X104_Y116_incr_waddr;
	assign X104_Y116_incr_waddr = X105_Y116_incr_waddr;
	wire [ADDR_WIDTH-1:0] X104_Y116_waddr;
	assign X104_Y116_waddr = X105_Y116_waddr;
	wire X104_Y115_incr_raddr;
	assign X104_Y115_incr_raddr = X105_Y116_incr_raddr;
	wire [ADDR_WIDTH-1:0] X104_Y115_raddr;
	assign X104_Y115_raddr = X105_Y116_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X105_Y116(.clk(bus_clock),
		.incr_waddr(X105_Y116_incr_waddr),
		.waddr(X105_Y116_waddr),
		.incr_raddr(X105_Y116_incr_raddr),
		.raddr(X105_Y116_raddr));


	/* generated from C@X205_Y116@{W[1][32],W[1][31]}@3 */

	logic X205_Y116_incr_waddr; // ingress control
	logic X205_Y116_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_1_west_to_east_ip_size_31_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][32][0]),
		.out(X205_Y116_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_1_west_to_east_ip_size_31_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][32][1]),
		.out(X205_Y116_incr_raddr));

	logic [ADDR_WIDTH-1:0] X205_Y116_waddr;
	logic [ADDR_WIDTH-1:0] X205_Y116_raddr;

	/* positional aliases */

	wire X206_Y116_incr_waddr;
	assign X206_Y116_incr_waddr = X205_Y116_incr_waddr;
	wire [ADDR_WIDTH-1:0] X206_Y116_waddr;
	assign X206_Y116_waddr = X205_Y116_waddr;
	wire X206_Y115_incr_raddr;
	assign X206_Y115_incr_raddr = X205_Y116_incr_raddr;
	wire [ADDR_WIDTH-1:0] X206_Y115_raddr;
	assign X206_Y115_raddr = X205_Y116_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X205_Y116(.clk(bus_clock),
		.incr_waddr(X205_Y116_incr_waddr),
		.waddr(X205_Y116_waddr),
		.incr_raddr(X205_Y116_incr_raddr),
		.raddr(X205_Y116_raddr));


	/* generated from I@X206_Y116@{W[1][32],W[1][31]}@4 */

	logic [DATA_WIDTH-1:0] X206_Y116_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_1_west_to_east_ip_size_31_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][32][10:0], west_in_reg[1][31][10:2]}),
		.out(X206_Y116_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X206_Y116(.data(X206_Y116_bus_wdata),
		.q(/* to design */),
		.wraddress(X206_Y116_waddr),
		.rdaddress(/* from design */),
		.wren(X206_Y116_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X104_Y115@{E[1][32],E[1][31]}@5 */

	logic [DATA_WIDTH-1:0] X104_Y115_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X104_Y115_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_1_east_to_west_ip_size_31_bus_first_egress_fifo(.clock(bus_clock),
		.in(X104_Y115_bus_rdata_in),
		.out(X104_Y115_bus_rdata_out));

	assign west_out_reg[1][32][10:0] = X104_Y115_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][31][10:2] = X104_Y115_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X104_Y115(.data(/* from design */),
		.q(X104_Y115_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X104_Y115_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X206_Y115@{W[1][32],W[1][31]}@5 */

	logic [DATA_WIDTH-1:0] X206_Y115_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X206_Y115_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_1_west_to_east_ip_size_31_bus_first_egress_fifo(.clock(bus_clock),
		.in(X206_Y115_bus_rdata_in),
		.out(X206_Y115_bus_rdata_out));

	assign east_out_reg[1][32][10:0] = X206_Y115_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][31][10:2] = X206_Y115_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X206_Y115(.data(/* from design */),
		.q(X206_Y115_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X206_Y115_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X71_Y114@{N[0][3],N[0][4]}@2 */

	logic X71_Y114_incr_waddr; // ingress control
	logic X71_Y114_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_4_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][4][0]),
		.out(X71_Y114_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_4_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][4][1]),
		.out(X71_Y114_incr_raddr));

	logic [ADDR_WIDTH-1:0] X71_Y114_waddr;
	logic [ADDR_WIDTH-1:0] X71_Y114_raddr;

	/* positional aliases */

	wire X72_Y114_incr_waddr;
	assign X72_Y114_incr_waddr = X71_Y114_incr_waddr;
	wire [ADDR_WIDTH-1:0] X72_Y114_waddr;
	assign X72_Y114_waddr = X71_Y114_waddr;
	wire X72_Y113_incr_raddr;
	assign X72_Y113_incr_raddr = X71_Y114_incr_raddr;
	wire [ADDR_WIDTH-1:0] X72_Y113_raddr;
	assign X72_Y113_raddr = X71_Y114_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X71_Y114(.clk(bus_clock),
		.incr_waddr(X71_Y114_incr_waddr),
		.waddr(X71_Y114_waddr),
		.incr_raddr(X71_Y114_incr_raddr),
		.raddr(X71_Y114_raddr));


	/* generated from I@X72_Y114@{N[0][4],N[0][5]}@2 */

	logic [DATA_WIDTH-1:0] X72_Y114_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_5_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][4][10:0], north_in_reg[0][5][10:2]}),
		.out(X72_Y114_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X72_Y114(.data(X72_Y114_bus_wdata),
		.q(/* to design */),
		.wraddress(X72_Y114_waddr),
		.rdaddress(/* from design */),
		.wren(X72_Y114_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X74_Y114@{S[0][6],S[0][7]}@4 */

	logic [DATA_WIDTH-1:0] X74_Y114_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X74_Y114_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_7_bus_first_egress_fifo(.clock(bus_clock),
		.in(X74_Y114_bus_rdata_in),
		.out(X74_Y114_bus_rdata_out));

	assign north_out_reg[0][6][10:0] = X74_Y114_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][7][10:2] = X74_Y114_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X74_Y114(.data(/* from design */),
		.q(X74_Y114_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X74_Y114_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X82_Y114@{N[0][11],N[0][12]}@2 */

	logic X82_Y114_incr_waddr; // ingress control
	logic X82_Y114_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_12_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][12][0]),
		.out(X82_Y114_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_12_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][12][1]),
		.out(X82_Y114_incr_raddr));

	logic [ADDR_WIDTH-1:0] X82_Y114_waddr;
	logic [ADDR_WIDTH-1:0] X82_Y114_raddr;

	/* positional aliases */

	wire X83_Y114_incr_waddr;
	assign X83_Y114_incr_waddr = X82_Y114_incr_waddr;
	wire [ADDR_WIDTH-1:0] X83_Y114_waddr;
	assign X83_Y114_waddr = X82_Y114_waddr;
	wire X83_Y113_incr_raddr;
	assign X83_Y113_incr_raddr = X82_Y114_incr_raddr;
	wire [ADDR_WIDTH-1:0] X83_Y113_raddr;
	assign X83_Y113_raddr = X82_Y114_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X82_Y114(.clk(bus_clock),
		.incr_waddr(X82_Y114_incr_waddr),
		.waddr(X82_Y114_waddr),
		.incr_raddr(X82_Y114_incr_raddr),
		.raddr(X82_Y114_raddr));


	/* generated from I@X83_Y114@{N[0][12],N[0][13]}@2 */

	logic [DATA_WIDTH-1:0] X83_Y114_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_13_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][12][10:0], north_in_reg[0][13][10:2]}),
		.out(X83_Y114_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X83_Y114(.data(X83_Y114_bus_wdata),
		.q(/* to design */),
		.wraddress(X83_Y114_waddr),
		.rdaddress(/* from design */),
		.wren(X83_Y114_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X85_Y114@{S[0][14],S[0][15]}@4 */

	logic [DATA_WIDTH-1:0] X85_Y114_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X85_Y114_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_15_bus_first_egress_fifo(.clock(bus_clock),
		.in(X85_Y114_bus_rdata_in),
		.out(X85_Y114_bus_rdata_out));

	assign north_out_reg[0][14][10:0] = X85_Y114_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][15][10:2] = X85_Y114_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X85_Y114(.data(/* from design */),
		.q(X85_Y114_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X85_Y114_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X92_Y114@{N[0][19],N[0][20]}@2 */

	logic X92_Y114_incr_waddr; // ingress control
	logic X92_Y114_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_20_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][20][0]),
		.out(X92_Y114_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_20_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][20][1]),
		.out(X92_Y114_incr_raddr));

	logic [ADDR_WIDTH-1:0] X92_Y114_waddr;
	logic [ADDR_WIDTH-1:0] X92_Y114_raddr;

	/* positional aliases */

	wire X93_Y114_incr_waddr;
	assign X93_Y114_incr_waddr = X92_Y114_incr_waddr;
	wire [ADDR_WIDTH-1:0] X93_Y114_waddr;
	assign X93_Y114_waddr = X92_Y114_waddr;
	wire X93_Y113_incr_raddr;
	assign X93_Y113_incr_raddr = X92_Y114_incr_raddr;
	wire [ADDR_WIDTH-1:0] X93_Y113_raddr;
	assign X93_Y113_raddr = X92_Y114_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X92_Y114(.clk(bus_clock),
		.incr_waddr(X92_Y114_incr_waddr),
		.waddr(X92_Y114_waddr),
		.incr_raddr(X92_Y114_incr_raddr),
		.raddr(X92_Y114_raddr));


	/* generated from I@X93_Y114@{N[0][20],N[0][21]}@2 */

	logic [DATA_WIDTH-1:0] X93_Y114_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_21_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][20][10:0], north_in_reg[0][21][10:2]}),
		.out(X93_Y114_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X93_Y114(.data(X93_Y114_bus_wdata),
		.q(/* to design */),
		.wraddress(X93_Y114_waddr),
		.rdaddress(/* from design */),
		.wren(X93_Y114_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X95_Y114@{S[0][22],S[0][23]}@4 */

	logic [DATA_WIDTH-1:0] X95_Y114_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X95_Y114_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_23_bus_first_egress_fifo(.clock(bus_clock),
		.in(X95_Y114_bus_rdata_in),
		.out(X95_Y114_bus_rdata_out));

	assign north_out_reg[0][22][10:0] = X95_Y114_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][23][10:2] = X95_Y114_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X95_Y114(.data(/* from design */),
		.q(X95_Y114_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X95_Y114_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X103_Y114@{W[1][30],W[1][29]}@1 */

	logic X103_Y114_incr_waddr; // ingress control
	logic X103_Y114_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_1_west_to_east_ip_size_29_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][29][0]),
		.out(X103_Y114_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_1_west_to_east_ip_size_29_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][29][1]),
		.out(X103_Y114_incr_raddr));

	logic [ADDR_WIDTH-1:0] X103_Y114_waddr;
	logic [ADDR_WIDTH-1:0] X103_Y114_raddr;

	/* positional aliases */

	wire X104_Y114_incr_waddr;
	assign X104_Y114_incr_waddr = X103_Y114_incr_waddr;
	wire [ADDR_WIDTH-1:0] X104_Y114_waddr;
	assign X104_Y114_waddr = X103_Y114_waddr;
	wire X104_Y113_incr_raddr;
	assign X104_Y113_incr_raddr = X103_Y114_incr_raddr;
	wire [ADDR_WIDTH-1:0] X104_Y113_raddr;
	assign X104_Y113_raddr = X103_Y114_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X103_Y114(.clk(bus_clock),
		.incr_waddr(X103_Y114_incr_waddr),
		.waddr(X103_Y114_waddr),
		.incr_raddr(X103_Y114_incr_raddr),
		.raddr(X103_Y114_raddr));


	/* generated from I@X104_Y114@{W[1][30],W[1][29]}@1 */

	logic [DATA_WIDTH-1:0] X104_Y114_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_1_west_to_east_ip_size_29_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][30][10:0], west_in_reg[1][29][10:2]}),
		.out(X104_Y114_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X104_Y114(.data(X104_Y114_bus_wdata),
		.q(/* to design */),
		.wraddress(X104_Y114_waddr),
		.rdaddress(/* from design */),
		.wren(X104_Y114_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X114_Y114@{N[0][35],N[0][36]}@2 */

	logic X114_Y114_incr_waddr; // ingress control
	logic X114_Y114_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_36_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][36][0]),
		.out(X114_Y114_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_36_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][36][1]),
		.out(X114_Y114_incr_raddr));

	logic [ADDR_WIDTH-1:0] X114_Y114_waddr;
	logic [ADDR_WIDTH-1:0] X114_Y114_raddr;

	/* positional aliases */

	wire X115_Y114_incr_waddr;
	assign X115_Y114_incr_waddr = X114_Y114_incr_waddr;
	wire [ADDR_WIDTH-1:0] X115_Y114_waddr;
	assign X115_Y114_waddr = X114_Y114_waddr;
	wire X115_Y113_incr_raddr;
	assign X115_Y113_incr_raddr = X114_Y114_incr_raddr;
	wire [ADDR_WIDTH-1:0] X115_Y113_raddr;
	assign X115_Y113_raddr = X114_Y114_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X114_Y114(.clk(bus_clock),
		.incr_waddr(X114_Y114_incr_waddr),
		.waddr(X114_Y114_waddr),
		.incr_raddr(X114_Y114_incr_raddr),
		.raddr(X114_Y114_raddr));


	/* generated from I@X115_Y114@{N[0][36],N[0][37]}@2 */

	logic [DATA_WIDTH-1:0] X115_Y114_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_37_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][36][10:0], north_in_reg[0][37][10:2]}),
		.out(X115_Y114_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X115_Y114(.data(X115_Y114_bus_wdata),
		.q(/* to design */),
		.wraddress(X115_Y114_waddr),
		.rdaddress(/* from design */),
		.wren(X115_Y114_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X117_Y114@{S[0][38],S[0][39]}@4 */

	logic [DATA_WIDTH-1:0] X117_Y114_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X117_Y114_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_39_bus_first_egress_fifo(.clock(bus_clock),
		.in(X117_Y114_bus_rdata_in),
		.out(X117_Y114_bus_rdata_out));

	assign north_out_reg[0][38][10:0] = X117_Y114_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][39][10:2] = X117_Y114_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X117_Y114(.data(/* from design */),
		.q(X117_Y114_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X117_Y114_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X177_Y114@{N[2][5],N[2][4]}@2 */

	logic [DATA_WIDTH-1:0] X177_Y114_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_4_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][5][10:0], north_in_reg[2][4][10:2]}),
		.out(X177_Y114_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X177_Y114(.data(X177_Y114_bus_wdata),
		.q(/* to design */),
		.wraddress(X177_Y114_waddr),
		.rdaddress(/* from design */),
		.wren(X177_Y114_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X178_Y114@{N[2][6],N[2][5]}@2 */

	logic X178_Y114_incr_waddr; // ingress control
	logic X178_Y114_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_5_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[2][6][0]),
		.out(X178_Y114_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_5_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[2][6][1]),
		.out(X178_Y114_incr_raddr));

	logic [ADDR_WIDTH-1:0] X178_Y114_waddr;
	logic [ADDR_WIDTH-1:0] X178_Y114_raddr;

	/* positional aliases */

	wire X177_Y114_incr_waddr;
	assign X177_Y114_incr_waddr = X178_Y114_incr_waddr;
	wire [ADDR_WIDTH-1:0] X177_Y114_waddr;
	assign X177_Y114_waddr = X178_Y114_waddr;
	wire X177_Y113_incr_raddr;
	assign X177_Y113_incr_raddr = X178_Y114_incr_raddr;
	wire [ADDR_WIDTH-1:0] X177_Y113_raddr;
	assign X177_Y113_raddr = X178_Y114_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X178_Y114(.clk(bus_clock),
		.incr_waddr(X178_Y114_incr_waddr),
		.waddr(X178_Y114_waddr),
		.incr_raddr(X178_Y114_incr_raddr),
		.raddr(X178_Y114_raddr));


	/* generated from E@X179_Y114@{S[2][7],S[2][6]}@4 */

	logic [DATA_WIDTH-1:0] X179_Y114_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X179_Y114_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_6_bus_first_egress_fifo(.clock(bus_clock),
		.in(X179_Y114_bus_rdata_in),
		.out(X179_Y114_bus_rdata_out));

	assign north_out_reg[2][7][10:0] = X179_Y114_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][6][10:2] = X179_Y114_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X179_Y114(.data(/* from design */),
		.q(X179_Y114_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X179_Y114_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X188_Y114@{N[2][13],N[2][12]}@2 */

	logic [DATA_WIDTH-1:0] X188_Y114_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_12_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][13][10:0], north_in_reg[2][12][10:2]}),
		.out(X188_Y114_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X188_Y114(.data(X188_Y114_bus_wdata),
		.q(/* to design */),
		.wraddress(X188_Y114_waddr),
		.rdaddress(/* from design */),
		.wren(X188_Y114_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X189_Y114@{N[2][14],N[2][13]}@2 */

	logic X189_Y114_incr_waddr; // ingress control
	logic X189_Y114_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_13_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[2][14][0]),
		.out(X189_Y114_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_13_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[2][14][1]),
		.out(X189_Y114_incr_raddr));

	logic [ADDR_WIDTH-1:0] X189_Y114_waddr;
	logic [ADDR_WIDTH-1:0] X189_Y114_raddr;

	/* positional aliases */

	wire X188_Y114_incr_waddr;
	assign X188_Y114_incr_waddr = X189_Y114_incr_waddr;
	wire [ADDR_WIDTH-1:0] X188_Y114_waddr;
	assign X188_Y114_waddr = X189_Y114_waddr;
	wire X188_Y113_incr_raddr;
	assign X188_Y113_incr_raddr = X189_Y114_incr_raddr;
	wire [ADDR_WIDTH-1:0] X188_Y113_raddr;
	assign X188_Y113_raddr = X189_Y114_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X189_Y114(.clk(bus_clock),
		.incr_waddr(X189_Y114_incr_waddr),
		.waddr(X189_Y114_waddr),
		.incr_raddr(X189_Y114_incr_raddr),
		.raddr(X189_Y114_raddr));


	/* generated from E@X190_Y114@{S[2][15],S[2][14]}@4 */

	logic [DATA_WIDTH-1:0] X190_Y114_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X190_Y114_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_14_bus_first_egress_fifo(.clock(bus_clock),
		.in(X190_Y114_bus_rdata_in),
		.out(X190_Y114_bus_rdata_out));

	assign north_out_reg[2][15][10:0] = X190_Y114_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][14][10:2] = X190_Y114_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X190_Y114(.data(/* from design */),
		.q(X190_Y114_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X190_Y114_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X206_Y114@{E[1][30],E[1][29]}@1 */

	logic [DATA_WIDTH-1:0] X206_Y114_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_1_east_to_west_ip_size_29_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][30][10:0], east_in_reg[1][29][10:2]}),
		.out(X206_Y114_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X206_Y114(.data(X206_Y114_bus_wdata),
		.q(/* to design */),
		.wraddress(X206_Y114_waddr),
		.rdaddress(/* from design */),
		.wren(X206_Y114_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X207_Y114@{E[1][30],E[1][29]}@1 */

	logic X207_Y114_incr_waddr; // ingress control
	logic X207_Y114_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_1_east_to_west_ip_size_29_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][30][0]),
		.out(X207_Y114_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_1_east_to_west_ip_size_29_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][30][1]),
		.out(X207_Y114_incr_raddr));

	logic [ADDR_WIDTH-1:0] X207_Y114_waddr;
	logic [ADDR_WIDTH-1:0] X207_Y114_raddr;

	/* positional aliases */

	wire X206_Y114_incr_waddr;
	assign X206_Y114_incr_waddr = X207_Y114_incr_waddr;
	wire [ADDR_WIDTH-1:0] X206_Y114_waddr;
	assign X206_Y114_waddr = X207_Y114_waddr;
	wire X206_Y113_incr_raddr;
	assign X206_Y113_incr_raddr = X207_Y114_incr_raddr;
	wire [ADDR_WIDTH-1:0] X206_Y113_raddr;
	assign X206_Y113_raddr = X207_Y114_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X207_Y114(.clk(bus_clock),
		.incr_waddr(X207_Y114_incr_waddr),
		.waddr(X207_Y114_waddr),
		.incr_raddr(X207_Y114_incr_raddr),
		.raddr(X207_Y114_raddr));


	/* generated from I@X220_Y114@{N[2][37],N[2][36]}@2 */

	logic [DATA_WIDTH-1:0] X220_Y114_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_36_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][37][10:0], north_in_reg[2][36][10:2]}),
		.out(X220_Y114_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X220_Y114(.data(X220_Y114_bus_wdata),
		.q(/* to design */),
		.wraddress(X220_Y114_waddr),
		.rdaddress(/* from design */),
		.wren(X220_Y114_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X221_Y114@{N[2][38],N[2][37]}@2 */

	logic X221_Y114_incr_waddr; // ingress control
	logic X221_Y114_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_37_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[2][38][0]),
		.out(X221_Y114_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_37_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[2][38][1]),
		.out(X221_Y114_incr_raddr));

	logic [ADDR_WIDTH-1:0] X221_Y114_waddr;
	logic [ADDR_WIDTH-1:0] X221_Y114_raddr;

	/* positional aliases */

	wire X220_Y114_incr_waddr;
	assign X220_Y114_incr_waddr = X221_Y114_incr_waddr;
	wire [ADDR_WIDTH-1:0] X220_Y114_waddr;
	assign X220_Y114_waddr = X221_Y114_waddr;
	wire X220_Y113_incr_raddr;
	assign X220_Y113_incr_raddr = X221_Y114_incr_raddr;
	wire [ADDR_WIDTH-1:0] X220_Y113_raddr;
	assign X220_Y113_raddr = X221_Y114_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X221_Y114(.clk(bus_clock),
		.incr_waddr(X221_Y114_incr_waddr),
		.waddr(X221_Y114_waddr),
		.incr_raddr(X221_Y114_incr_raddr),
		.raddr(X221_Y114_raddr));


	/* generated from E@X222_Y114@{S[2][39],S[2][38]}@4 */

	logic [DATA_WIDTH-1:0] X222_Y114_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X222_Y114_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_38_bus_first_egress_fifo(.clock(bus_clock),
		.in(X222_Y114_bus_rdata_in),
		.out(X222_Y114_bus_rdata_out));

	assign north_out_reg[2][39][10:0] = X222_Y114_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][38][10:2] = X222_Y114_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X222_Y114(.data(/* from design */),
		.q(X222_Y114_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X222_Y114_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X72_Y113@{N[0][4],N[0][5]}@3 */

	logic [DATA_WIDTH-1:0] X72_Y113_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X72_Y113_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_5_bus_first_egress_fifo(.clock(bus_clock),
		.in(X72_Y113_bus_rdata_in),
		.out(X72_Y113_bus_rdata_out));

	assign south_out_reg[0][4][10:0] = X72_Y113_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][5][10:2] = X72_Y113_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X72_Y113(.data(/* from design */),
		.q(X72_Y113_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X72_Y113_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X73_Y113@{S[0][5],S[0][6]}@3 */

	logic X73_Y113_incr_waddr; // ingress control
	logic X73_Y113_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_6_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][6][0]),
		.out(X73_Y113_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_6_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][6][1]),
		.out(X73_Y113_incr_raddr));

	logic [ADDR_WIDTH-1:0] X73_Y113_waddr;
	logic [ADDR_WIDTH-1:0] X73_Y113_raddr;

	/* positional aliases */

	wire X74_Y113_incr_waddr;
	assign X74_Y113_incr_waddr = X73_Y113_incr_waddr;
	wire [ADDR_WIDTH-1:0] X74_Y113_waddr;
	assign X74_Y113_waddr = X73_Y113_waddr;
	wire X74_Y114_incr_raddr;
	assign X74_Y114_incr_raddr = X73_Y113_incr_raddr;
	wire [ADDR_WIDTH-1:0] X74_Y114_raddr;
	assign X74_Y114_raddr = X73_Y113_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X73_Y113(.clk(bus_clock),
		.incr_waddr(X73_Y113_incr_waddr),
		.waddr(X73_Y113_waddr),
		.incr_raddr(X73_Y113_incr_raddr),
		.raddr(X73_Y113_raddr));


	/* generated from I@X74_Y113@{S[0][6],S[0][7]}@3 */

	logic [DATA_WIDTH-1:0] X74_Y113_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_7_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][6][10:0], south_in_reg[0][7][10:2]}),
		.out(X74_Y113_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X74_Y113(.data(X74_Y113_bus_wdata),
		.q(/* to design */),
		.wraddress(X74_Y113_waddr),
		.rdaddress(/* from design */),
		.wren(X74_Y113_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X83_Y113@{N[0][12],N[0][13]}@3 */

	logic [DATA_WIDTH-1:0] X83_Y113_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X83_Y113_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_13_bus_first_egress_fifo(.clock(bus_clock),
		.in(X83_Y113_bus_rdata_in),
		.out(X83_Y113_bus_rdata_out));

	assign south_out_reg[0][12][10:0] = X83_Y113_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][13][10:2] = X83_Y113_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X83_Y113(.data(/* from design */),
		.q(X83_Y113_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X83_Y113_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X84_Y113@{S[0][13],S[0][14]}@3 */

	logic X84_Y113_incr_waddr; // ingress control
	logic X84_Y113_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_14_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][14][0]),
		.out(X84_Y113_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_14_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][14][1]),
		.out(X84_Y113_incr_raddr));

	logic [ADDR_WIDTH-1:0] X84_Y113_waddr;
	logic [ADDR_WIDTH-1:0] X84_Y113_raddr;

	/* positional aliases */

	wire X85_Y113_incr_waddr;
	assign X85_Y113_incr_waddr = X84_Y113_incr_waddr;
	wire [ADDR_WIDTH-1:0] X85_Y113_waddr;
	assign X85_Y113_waddr = X84_Y113_waddr;
	wire X85_Y114_incr_raddr;
	assign X85_Y114_incr_raddr = X84_Y113_incr_raddr;
	wire [ADDR_WIDTH-1:0] X85_Y114_raddr;
	assign X85_Y114_raddr = X84_Y113_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X84_Y113(.clk(bus_clock),
		.incr_waddr(X84_Y113_incr_waddr),
		.waddr(X84_Y113_waddr),
		.incr_raddr(X84_Y113_incr_raddr),
		.raddr(X84_Y113_raddr));


	/* generated from I@X85_Y113@{S[0][14],S[0][15]}@3 */

	logic [DATA_WIDTH-1:0] X85_Y113_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_15_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][14][10:0], south_in_reg[0][15][10:2]}),
		.out(X85_Y113_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X85_Y113(.data(X85_Y113_bus_wdata),
		.q(/* to design */),
		.wraddress(X85_Y113_waddr),
		.rdaddress(/* from design */),
		.wren(X85_Y113_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X93_Y113@{N[0][20],N[0][21]}@3 */

	logic [DATA_WIDTH-1:0] X93_Y113_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X93_Y113_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_21_bus_first_egress_fifo(.clock(bus_clock),
		.in(X93_Y113_bus_rdata_in),
		.out(X93_Y113_bus_rdata_out));

	assign south_out_reg[0][20][10:0] = X93_Y113_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][21][10:2] = X93_Y113_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X93_Y113(.data(/* from design */),
		.q(X93_Y113_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X93_Y113_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X94_Y113@{S[0][21],S[0][22]}@3 */

	logic X94_Y113_incr_waddr; // ingress control
	logic X94_Y113_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_22_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][22][0]),
		.out(X94_Y113_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_22_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][22][1]),
		.out(X94_Y113_incr_raddr));

	logic [ADDR_WIDTH-1:0] X94_Y113_waddr;
	logic [ADDR_WIDTH-1:0] X94_Y113_raddr;

	/* positional aliases */

	wire X95_Y113_incr_waddr;
	assign X95_Y113_incr_waddr = X94_Y113_incr_waddr;
	wire [ADDR_WIDTH-1:0] X95_Y113_waddr;
	assign X95_Y113_waddr = X94_Y113_waddr;
	wire X95_Y114_incr_raddr;
	assign X95_Y114_incr_raddr = X94_Y113_incr_raddr;
	wire [ADDR_WIDTH-1:0] X95_Y114_raddr;
	assign X95_Y114_raddr = X94_Y113_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X94_Y113(.clk(bus_clock),
		.incr_waddr(X94_Y113_incr_waddr),
		.waddr(X94_Y113_waddr),
		.incr_raddr(X94_Y113_incr_raddr),
		.raddr(X94_Y113_raddr));


	/* generated from I@X95_Y113@{S[0][22],S[0][23]}@3 */

	logic [DATA_WIDTH-1:0] X95_Y113_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_23_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][22][10:0], south_in_reg[0][23][10:2]}),
		.out(X95_Y113_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X95_Y113(.data(X95_Y113_bus_wdata),
		.q(/* to design */),
		.wraddress(X95_Y113_waddr),
		.rdaddress(/* from design */),
		.wren(X95_Y113_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X104_Y113@{W[1][30],W[1][29]}@2 */

	logic [DATA_WIDTH-1:0] X104_Y113_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X104_Y113_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_1_west_to_east_ip_size_29_bus_first_egress_fifo(.clock(bus_clock),
		.in(X104_Y113_bus_rdata_in),
		.out(X104_Y113_bus_rdata_out));

	assign east_out_reg[1][30][10:0] = X104_Y113_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][29][10:2] = X104_Y113_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X104_Y113(.data(/* from design */),
		.q(X104_Y113_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X104_Y113_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X115_Y113@{N[0][36],N[0][37]}@3 */

	logic [DATA_WIDTH-1:0] X115_Y113_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X115_Y113_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_37_bus_first_egress_fifo(.clock(bus_clock),
		.in(X115_Y113_bus_rdata_in),
		.out(X115_Y113_bus_rdata_out));

	assign south_out_reg[0][36][10:0] = X115_Y113_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][37][10:2] = X115_Y113_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X115_Y113(.data(/* from design */),
		.q(X115_Y113_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X115_Y113_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X116_Y113@{S[0][37],S[0][38]}@3 */

	logic X116_Y113_incr_waddr; // ingress control
	logic X116_Y113_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_38_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][38][0]),
		.out(X116_Y113_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_38_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][38][1]),
		.out(X116_Y113_incr_raddr));

	logic [ADDR_WIDTH-1:0] X116_Y113_waddr;
	logic [ADDR_WIDTH-1:0] X116_Y113_raddr;

	/* positional aliases */

	wire X117_Y113_incr_waddr;
	assign X117_Y113_incr_waddr = X116_Y113_incr_waddr;
	wire [ADDR_WIDTH-1:0] X117_Y113_waddr;
	assign X117_Y113_waddr = X116_Y113_waddr;
	wire X117_Y114_incr_raddr;
	assign X117_Y114_incr_raddr = X116_Y113_incr_raddr;
	wire [ADDR_WIDTH-1:0] X117_Y114_raddr;
	assign X117_Y114_raddr = X116_Y113_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X116_Y113(.clk(bus_clock),
		.incr_waddr(X116_Y113_incr_waddr),
		.waddr(X116_Y113_waddr),
		.incr_raddr(X116_Y113_incr_raddr),
		.raddr(X116_Y113_raddr));


	/* generated from I@X117_Y113@{S[0][38],S[0][39]}@3 */

	logic [DATA_WIDTH-1:0] X117_Y113_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_39_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][38][10:0], south_in_reg[0][39][10:2]}),
		.out(X117_Y113_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X117_Y113(.data(X117_Y113_bus_wdata),
		.q(/* to design */),
		.wraddress(X117_Y113_waddr),
		.rdaddress(/* from design */),
		.wren(X117_Y113_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X177_Y113@{N[2][5],N[2][4]}@3 */

	logic [DATA_WIDTH-1:0] X177_Y113_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X177_Y113_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_4_bus_first_egress_fifo(.clock(bus_clock),
		.in(X177_Y113_bus_rdata_in),
		.out(X177_Y113_bus_rdata_out));

	assign south_out_reg[2][5][10:0] = X177_Y113_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][4][10:2] = X177_Y113_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X177_Y113(.data(/* from design */),
		.q(X177_Y113_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X177_Y113_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X179_Y113@{S[2][7],S[2][6]}@3 */

	logic [DATA_WIDTH-1:0] X179_Y113_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_6_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][7][10:0], south_in_reg[2][6][10:2]}),
		.out(X179_Y113_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X179_Y113(.data(X179_Y113_bus_wdata),
		.q(/* to design */),
		.wraddress(X179_Y113_waddr),
		.rdaddress(/* from design */),
		.wren(X179_Y113_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X180_Y113@{S[2][8],S[2][7]}@3 */

	logic X180_Y113_incr_waddr; // ingress control
	logic X180_Y113_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_7_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[2][8][0]),
		.out(X180_Y113_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_7_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[2][8][1]),
		.out(X180_Y113_incr_raddr));

	logic [ADDR_WIDTH-1:0] X180_Y113_waddr;
	logic [ADDR_WIDTH-1:0] X180_Y113_raddr;

	/* positional aliases */

	wire X179_Y113_incr_waddr;
	assign X179_Y113_incr_waddr = X180_Y113_incr_waddr;
	wire [ADDR_WIDTH-1:0] X179_Y113_waddr;
	assign X179_Y113_waddr = X180_Y113_waddr;
	wire X179_Y114_incr_raddr;
	assign X179_Y114_incr_raddr = X180_Y113_incr_raddr;
	wire [ADDR_WIDTH-1:0] X179_Y114_raddr;
	assign X179_Y114_raddr = X180_Y113_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X180_Y113(.clk(bus_clock),
		.incr_waddr(X180_Y113_incr_waddr),
		.waddr(X180_Y113_waddr),
		.incr_raddr(X180_Y113_incr_raddr),
		.raddr(X180_Y113_raddr));


	/* generated from E@X188_Y113@{N[2][13],N[2][12]}@3 */

	logic [DATA_WIDTH-1:0] X188_Y113_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X188_Y113_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_12_bus_first_egress_fifo(.clock(bus_clock),
		.in(X188_Y113_bus_rdata_in),
		.out(X188_Y113_bus_rdata_out));

	assign south_out_reg[2][13][10:0] = X188_Y113_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][12][10:2] = X188_Y113_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X188_Y113(.data(/* from design */),
		.q(X188_Y113_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X188_Y113_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X190_Y113@{S[2][15],S[2][14]}@3 */

	logic [DATA_WIDTH-1:0] X190_Y113_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_14_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][15][10:0], south_in_reg[2][14][10:2]}),
		.out(X190_Y113_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X190_Y113(.data(X190_Y113_bus_wdata),
		.q(/* to design */),
		.wraddress(X190_Y113_waddr),
		.rdaddress(/* from design */),
		.wren(X190_Y113_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X191_Y113@{S[2][16],S[2][15]}@3 */

	logic X191_Y113_incr_waddr; // ingress control
	logic X191_Y113_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_15_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[2][16][0]),
		.out(X191_Y113_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_15_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[2][16][1]),
		.out(X191_Y113_incr_raddr));

	logic [ADDR_WIDTH-1:0] X191_Y113_waddr;
	logic [ADDR_WIDTH-1:0] X191_Y113_raddr;

	/* positional aliases */

	wire X190_Y113_incr_waddr;
	assign X190_Y113_incr_waddr = X191_Y113_incr_waddr;
	wire [ADDR_WIDTH-1:0] X190_Y113_waddr;
	assign X190_Y113_waddr = X191_Y113_waddr;
	wire X190_Y114_incr_raddr;
	assign X190_Y114_incr_raddr = X191_Y113_incr_raddr;
	wire [ADDR_WIDTH-1:0] X190_Y114_raddr;
	assign X190_Y114_raddr = X191_Y113_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X191_Y113(.clk(bus_clock),
		.incr_waddr(X191_Y113_incr_waddr),
		.waddr(X191_Y113_waddr),
		.incr_raddr(X191_Y113_incr_raddr),
		.raddr(X191_Y113_raddr));


	/* generated from E@X206_Y113@{E[1][30],E[1][29]}@2 */

	logic [DATA_WIDTH-1:0] X206_Y113_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X206_Y113_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_1_east_to_west_ip_size_29_bus_first_egress_fifo(.clock(bus_clock),
		.in(X206_Y113_bus_rdata_in),
		.out(X206_Y113_bus_rdata_out));

	assign west_out_reg[1][30][10:0] = X206_Y113_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][29][10:2] = X206_Y113_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X206_Y113(.data(/* from design */),
		.q(X206_Y113_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X206_Y113_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X220_Y113@{N[2][37],N[2][36]}@3 */

	logic [DATA_WIDTH-1:0] X220_Y113_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X220_Y113_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_36_bus_first_egress_fifo(.clock(bus_clock),
		.in(X220_Y113_bus_rdata_in),
		.out(X220_Y113_bus_rdata_out));

	assign south_out_reg[2][37][10:0] = X220_Y113_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][36][10:2] = X220_Y113_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X220_Y113(.data(/* from design */),
		.q(X220_Y113_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X220_Y113_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X222_Y113@{S[2][39],S[2][38]}@3 */

	logic [DATA_WIDTH-1:0] X222_Y113_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_38_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][39][10:0], south_in_reg[2][38][10:2]}),
		.out(X222_Y113_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X222_Y113(.data(X222_Y113_bus_wdata),
		.q(/* to design */),
		.wraddress(X222_Y113_waddr),
		.rdaddress(/* from design */),
		.wren(X222_Y113_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X223_Y113@{S[3][0],S[2][39]}@3 */

	logic X223_Y113_incr_waddr; // ingress control
	logic X223_Y113_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_39_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][0][0]),
		.out(X223_Y113_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_39_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][0][1]),
		.out(X223_Y113_incr_raddr));

	logic [ADDR_WIDTH-1:0] X223_Y113_waddr;
	logic [ADDR_WIDTH-1:0] X223_Y113_raddr;

	/* positional aliases */

	wire X222_Y113_incr_waddr;
	assign X222_Y113_incr_waddr = X223_Y113_incr_waddr;
	wire [ADDR_WIDTH-1:0] X222_Y113_waddr;
	assign X222_Y113_waddr = X223_Y113_waddr;
	wire X222_Y114_incr_raddr;
	assign X222_Y114_incr_raddr = X223_Y113_incr_raddr;
	wire [ADDR_WIDTH-1:0] X222_Y114_raddr;
	assign X222_Y114_raddr = X223_Y113_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X223_Y113(.clk(bus_clock),
		.incr_waddr(X223_Y113_incr_waddr),
		.waddr(X223_Y113_waddr),
		.incr_raddr(X223_Y113_incr_raddr),
		.raddr(X223_Y113_raddr));


	/* generated from I@X153_Y112@{E[1][28],E[1][27]}@3 */

	logic [DATA_WIDTH-1:0] X153_Y112_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) east_to_west_sector_size_1_east_to_west_ip_size_27_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][28][10:0], east_in_reg[1][27][10:2]}),
		.out(X153_Y112_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X153_Y112(.data(X153_Y112_bus_wdata),
		.q(/* to design */),
		.wraddress(X153_Y112_waddr),
		.rdaddress(/* from design */),
		.wren(X153_Y112_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X154_Y112@{E[1][28],E[1][27]}@3 */

	logic X154_Y112_incr_waddr; // ingress control
	logic X154_Y112_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) east_to_west_sector_size_1_east_to_west_ip_size_27_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][27][0]),
		.out(X154_Y112_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) east_to_west_sector_size_1_east_to_west_ip_size_27_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][27][1]),
		.out(X154_Y112_incr_raddr));

	logic [ADDR_WIDTH-1:0] X154_Y112_waddr;
	logic [ADDR_WIDTH-1:0] X154_Y112_raddr;

	/* positional aliases */

	wire X153_Y112_incr_waddr;
	assign X153_Y112_incr_waddr = X154_Y112_incr_waddr;
	wire [ADDR_WIDTH-1:0] X153_Y112_waddr;
	assign X153_Y112_waddr = X154_Y112_waddr;
	wire X153_Y111_incr_raddr;
	assign X153_Y111_incr_raddr = X154_Y112_incr_raddr;
	wire [ADDR_WIDTH-1:0] X153_Y111_raddr;
	assign X153_Y111_raddr = X154_Y112_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X154_Y112(.clk(bus_clock),
		.incr_waddr(X154_Y112_incr_waddr),
		.waddr(X154_Y112_waddr),
		.incr_raddr(X154_Y112_incr_raddr),
		.raddr(X154_Y112_raddr));


	/* generated from C@X238_Y112@{W[1][28],W[1][27]}@4 */

	logic X238_Y112_incr_waddr; // ingress control
	logic X238_Y112_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) west_to_east_sector_size_1_west_to_east_ip_size_27_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][28][0]),
		.out(X238_Y112_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) west_to_east_sector_size_1_west_to_east_ip_size_27_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][28][1]),
		.out(X238_Y112_incr_raddr));

	logic [ADDR_WIDTH-1:0] X238_Y112_waddr;
	logic [ADDR_WIDTH-1:0] X238_Y112_raddr;

	/* positional aliases */

	wire X239_Y112_incr_waddr;
	assign X239_Y112_incr_waddr = X238_Y112_incr_waddr;
	wire [ADDR_WIDTH-1:0] X239_Y112_waddr;
	assign X239_Y112_waddr = X238_Y112_waddr;
	wire X239_Y111_incr_raddr;
	assign X239_Y111_incr_raddr = X238_Y112_incr_raddr;
	wire [ADDR_WIDTH-1:0] X239_Y111_raddr;
	assign X239_Y111_raddr = X238_Y112_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X238_Y112(.clk(bus_clock),
		.incr_waddr(X238_Y112_incr_waddr),
		.waddr(X238_Y112_waddr),
		.incr_raddr(X238_Y112_incr_raddr),
		.raddr(X238_Y112_raddr));


	/* generated from I@X239_Y112@{W[1][28],W[1][27]}@4 */

	logic [DATA_WIDTH-1:0] X239_Y112_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_1_west_to_east_ip_size_27_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][28][10:0], west_in_reg[1][27][10:2]}),
		.out(X239_Y112_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X239_Y112(.data(X239_Y112_bus_wdata),
		.q(/* to design */),
		.wraddress(X239_Y112_waddr),
		.rdaddress(/* from design */),
		.wren(X239_Y112_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X153_Y111@{E[1][28],E[1][27]}@4 */

	logic [DATA_WIDTH-1:0] X153_Y111_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X153_Y111_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) east_to_west_sector_size_1_east_to_west_ip_size_27_bus_first_egress_fifo(.clock(bus_clock),
		.in(X153_Y111_bus_rdata_in),
		.out(X153_Y111_bus_rdata_out));

	assign west_out_reg[1][28][10:0] = X153_Y111_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][27][10:2] = X153_Y111_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X153_Y111(.data(/* from design */),
		.q(X153_Y111_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X153_Y111_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X239_Y111@{W[1][28],W[1][27]}@5 */

	logic [DATA_WIDTH-1:0] X239_Y111_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X239_Y111_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_1_west_to_east_ip_size_27_bus_first_egress_fifo(.clock(bus_clock),
		.in(X239_Y111_bus_rdata_in),
		.out(X239_Y111_bus_rdata_out));

	assign east_out_reg[1][28][10:0] = X239_Y111_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][27][10:2] = X239_Y111_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X239_Y111(.data(/* from design */),
		.q(X239_Y111_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X239_Y111_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X125_Y110@{N[1][3],N[1][4]}@2 */

	logic X125_Y110_incr_waddr; // ingress control
	logic X125_Y110_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_4_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][4][0]),
		.out(X125_Y110_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_4_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][4][1]),
		.out(X125_Y110_incr_raddr));

	logic [ADDR_WIDTH-1:0] X125_Y110_waddr;
	logic [ADDR_WIDTH-1:0] X125_Y110_raddr;

	/* positional aliases */

	wire X126_Y110_incr_waddr;
	assign X126_Y110_incr_waddr = X125_Y110_incr_waddr;
	wire [ADDR_WIDTH-1:0] X126_Y110_waddr;
	assign X126_Y110_waddr = X125_Y110_waddr;
	wire X126_Y109_incr_raddr;
	assign X126_Y109_incr_raddr = X125_Y110_incr_raddr;
	wire [ADDR_WIDTH-1:0] X126_Y109_raddr;
	assign X126_Y109_raddr = X125_Y110_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X125_Y110(.clk(bus_clock),
		.incr_waddr(X125_Y110_incr_waddr),
		.waddr(X125_Y110_waddr),
		.incr_raddr(X125_Y110_incr_raddr),
		.raddr(X125_Y110_raddr));


	/* generated from I@X126_Y110@{N[1][4],N[1][5]}@2 */

	logic [DATA_WIDTH-1:0] X126_Y110_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_5_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][4][10:0], north_in_reg[1][5][10:2]}),
		.out(X126_Y110_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X126_Y110(.data(X126_Y110_bus_wdata),
		.q(/* to design */),
		.wraddress(X126_Y110_waddr),
		.rdaddress(/* from design */),
		.wren(X126_Y110_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X128_Y110@{S[1][6],S[1][7]}@4 */

	logic [DATA_WIDTH-1:0] X128_Y110_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X128_Y110_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_7_bus_first_egress_fifo(.clock(bus_clock),
		.in(X128_Y110_bus_rdata_in),
		.out(X128_Y110_bus_rdata_out));

	assign north_out_reg[1][6][10:0] = X128_Y110_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][7][10:2] = X128_Y110_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X128_Y110(.data(/* from design */),
		.q(X128_Y110_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X128_Y110_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X136_Y110@{N[1][11],N[1][12]}@2 */

	logic X136_Y110_incr_waddr; // ingress control
	logic X136_Y110_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_12_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][12][0]),
		.out(X136_Y110_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_12_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][12][1]),
		.out(X136_Y110_incr_raddr));

	logic [ADDR_WIDTH-1:0] X136_Y110_waddr;
	logic [ADDR_WIDTH-1:0] X136_Y110_raddr;

	/* positional aliases */

	wire X137_Y110_incr_waddr;
	assign X137_Y110_incr_waddr = X136_Y110_incr_waddr;
	wire [ADDR_WIDTH-1:0] X137_Y110_waddr;
	assign X137_Y110_waddr = X136_Y110_waddr;
	wire X137_Y109_incr_raddr;
	assign X137_Y109_incr_raddr = X136_Y110_incr_raddr;
	wire [ADDR_WIDTH-1:0] X137_Y109_raddr;
	assign X137_Y109_raddr = X136_Y110_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X136_Y110(.clk(bus_clock),
		.incr_waddr(X136_Y110_incr_waddr),
		.waddr(X136_Y110_waddr),
		.incr_raddr(X136_Y110_incr_raddr),
		.raddr(X136_Y110_raddr));


	/* generated from I@X137_Y110@{N[1][12],N[1][13]}@2 */

	logic [DATA_WIDTH-1:0] X137_Y110_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_13_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][12][10:0], north_in_reg[1][13][10:2]}),
		.out(X137_Y110_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X137_Y110(.data(X137_Y110_bus_wdata),
		.q(/* to design */),
		.wraddress(X137_Y110_waddr),
		.rdaddress(/* from design */),
		.wren(X137_Y110_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X139_Y110@{S[1][14],S[1][15]}@4 */

	logic [DATA_WIDTH-1:0] X139_Y110_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X139_Y110_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_15_bus_first_egress_fifo(.clock(bus_clock),
		.in(X139_Y110_bus_rdata_in),
		.out(X139_Y110_bus_rdata_out));

	assign north_out_reg[1][14][10:0] = X139_Y110_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][15][10:2] = X139_Y110_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X139_Y110(.data(/* from design */),
		.q(X139_Y110_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X139_Y110_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X152_Y110@{W[1][26],W[1][25]}@2 */

	logic X152_Y110_incr_waddr; // ingress control
	logic X152_Y110_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) west_to_east_sector_size_1_west_to_east_ip_size_25_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][25][0]),
		.out(X152_Y110_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) west_to_east_sector_size_1_west_to_east_ip_size_25_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][25][1]),
		.out(X152_Y110_incr_raddr));

	logic [ADDR_WIDTH-1:0] X152_Y110_waddr;
	logic [ADDR_WIDTH-1:0] X152_Y110_raddr;

	/* positional aliases */

	wire X153_Y110_incr_waddr;
	assign X153_Y110_incr_waddr = X152_Y110_incr_waddr;
	wire [ADDR_WIDTH-1:0] X153_Y110_waddr;
	assign X153_Y110_waddr = X152_Y110_waddr;
	wire X153_Y109_incr_raddr;
	assign X153_Y109_incr_raddr = X152_Y110_incr_raddr;
	wire [ADDR_WIDTH-1:0] X153_Y109_raddr;
	assign X153_Y109_raddr = X152_Y110_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X152_Y110(.clk(bus_clock),
		.incr_waddr(X152_Y110_incr_waddr),
		.waddr(X152_Y110_waddr),
		.incr_raddr(X152_Y110_incr_raddr),
		.raddr(X152_Y110_raddr));


	/* generated from I@X153_Y110@{W[1][26],W[1][25]}@2 */

	logic [DATA_WIDTH-1:0] X153_Y110_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) west_to_east_sector_size_1_west_to_east_ip_size_25_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][26][10:0], west_in_reg[1][25][10:2]}),
		.out(X153_Y110_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X153_Y110(.data(X153_Y110_bus_wdata),
		.q(/* to design */),
		.wraddress(X153_Y110_waddr),
		.rdaddress(/* from design */),
		.wren(X153_Y110_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X168_Y110@{N[1][35],N[1][36]}@2 */

	logic X168_Y110_incr_waddr; // ingress control
	logic X168_Y110_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_36_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][36][0]),
		.out(X168_Y110_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_36_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][36][1]),
		.out(X168_Y110_incr_raddr));

	logic [ADDR_WIDTH-1:0] X168_Y110_waddr;
	logic [ADDR_WIDTH-1:0] X168_Y110_raddr;

	/* positional aliases */

	wire X169_Y110_incr_waddr;
	assign X169_Y110_incr_waddr = X168_Y110_incr_waddr;
	wire [ADDR_WIDTH-1:0] X169_Y110_waddr;
	assign X169_Y110_waddr = X168_Y110_waddr;
	wire X169_Y109_incr_raddr;
	assign X169_Y109_incr_raddr = X168_Y110_incr_raddr;
	wire [ADDR_WIDTH-1:0] X169_Y109_raddr;
	assign X169_Y109_raddr = X168_Y110_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X168_Y110(.clk(bus_clock),
		.incr_waddr(X168_Y110_incr_waddr),
		.waddr(X168_Y110_waddr),
		.incr_raddr(X168_Y110_incr_raddr),
		.raddr(X168_Y110_raddr));


	/* generated from I@X169_Y110@{N[1][36],N[1][37]}@2 */

	logic [DATA_WIDTH-1:0] X169_Y110_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_37_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][36][10:0], north_in_reg[1][37][10:2]}),
		.out(X169_Y110_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X169_Y110(.data(X169_Y110_bus_wdata),
		.q(/* to design */),
		.wraddress(X169_Y110_waddr),
		.rdaddress(/* from design */),
		.wren(X169_Y110_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X171_Y110@{S[1][38],S[1][39]}@4 */

	logic [DATA_WIDTH-1:0] X171_Y110_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X171_Y110_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_39_bus_first_egress_fifo(.clock(bus_clock),
		.in(X171_Y110_bus_rdata_in),
		.out(X171_Y110_bus_rdata_out));

	assign north_out_reg[1][38][10:0] = X171_Y110_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][39][10:2] = X171_Y110_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X171_Y110(.data(/* from design */),
		.q(X171_Y110_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X171_Y110_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X239_Y110@{E[1][26],E[1][25]}@1 */

	logic [DATA_WIDTH-1:0] X239_Y110_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_1_east_to_west_ip_size_25_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][26][10:0], east_in_reg[1][25][10:2]}),
		.out(X239_Y110_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X239_Y110(.data(X239_Y110_bus_wdata),
		.q(/* to design */),
		.wraddress(X239_Y110_waddr),
		.rdaddress(/* from design */),
		.wren(X239_Y110_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X240_Y110@{E[1][26],E[1][25]}@1 */

	logic X240_Y110_incr_waddr; // ingress control
	logic X240_Y110_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_1_east_to_west_ip_size_25_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][26][0]),
		.out(X240_Y110_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_1_east_to_west_ip_size_25_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][26][1]),
		.out(X240_Y110_incr_raddr));

	logic [ADDR_WIDTH-1:0] X240_Y110_waddr;
	logic [ADDR_WIDTH-1:0] X240_Y110_raddr;

	/* positional aliases */

	wire X239_Y110_incr_waddr;
	assign X239_Y110_incr_waddr = X240_Y110_incr_waddr;
	wire [ADDR_WIDTH-1:0] X239_Y110_waddr;
	assign X239_Y110_waddr = X240_Y110_waddr;
	wire X239_Y109_incr_raddr;
	assign X239_Y109_incr_raddr = X240_Y110_incr_raddr;
	wire [ADDR_WIDTH-1:0] X239_Y109_raddr;
	assign X239_Y109_raddr = X240_Y110_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X240_Y110(.clk(bus_clock),
		.incr_waddr(X240_Y110_incr_waddr),
		.waddr(X240_Y110_waddr),
		.incr_raddr(X240_Y110_incr_raddr),
		.raddr(X240_Y110_raddr));


	/* generated from I@X253_Y110@{N[3][21],N[3][20]}@2 */

	logic [DATA_WIDTH-1:0] X253_Y110_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_20_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][21][10:0], north_in_reg[3][20][10:2]}),
		.out(X253_Y110_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X253_Y110(.data(X253_Y110_bus_wdata),
		.q(/* to design */),
		.wraddress(X253_Y110_waddr),
		.rdaddress(/* from design */),
		.wren(X253_Y110_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X254_Y110@{N[3][22],N[3][21]}@2 */

	logic X254_Y110_incr_waddr; // ingress control
	logic X254_Y110_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_21_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][22][0]),
		.out(X254_Y110_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_21_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][22][1]),
		.out(X254_Y110_incr_raddr));

	logic [ADDR_WIDTH-1:0] X254_Y110_waddr;
	logic [ADDR_WIDTH-1:0] X254_Y110_raddr;

	/* positional aliases */

	wire X253_Y110_incr_waddr;
	assign X253_Y110_incr_waddr = X254_Y110_incr_waddr;
	wire [ADDR_WIDTH-1:0] X253_Y110_waddr;
	assign X253_Y110_waddr = X254_Y110_waddr;
	wire X253_Y109_incr_raddr;
	assign X253_Y109_incr_raddr = X254_Y110_incr_raddr;
	wire [ADDR_WIDTH-1:0] X253_Y109_raddr;
	assign X253_Y109_raddr = X254_Y110_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X254_Y110(.clk(bus_clock),
		.incr_waddr(X254_Y110_incr_waddr),
		.waddr(X254_Y110_waddr),
		.incr_raddr(X254_Y110_incr_raddr),
		.raddr(X254_Y110_raddr));


	/* generated from E@X255_Y110@{S[3][23],S[3][22]}@4 */

	logic [DATA_WIDTH-1:0] X255_Y110_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X255_Y110_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_22_bus_first_egress_fifo(.clock(bus_clock),
		.in(X255_Y110_bus_rdata_in),
		.out(X255_Y110_bus_rdata_out));

	assign north_out_reg[3][23][10:0] = X255_Y110_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][22][10:2] = X255_Y110_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X255_Y110(.data(/* from design */),
		.q(X255_Y110_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X255_Y110_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X263_Y110@{N[3][29],N[3][28]}@2 */

	logic [DATA_WIDTH-1:0] X263_Y110_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_28_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][29][10:0], north_in_reg[3][28][10:2]}),
		.out(X263_Y110_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X263_Y110(.data(X263_Y110_bus_wdata),
		.q(/* to design */),
		.wraddress(X263_Y110_waddr),
		.rdaddress(/* from design */),
		.wren(X263_Y110_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X264_Y110@{N[3][30],N[3][29]}@2 */

	logic X264_Y110_incr_waddr; // ingress control
	logic X264_Y110_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_29_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][30][0]),
		.out(X264_Y110_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_29_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][30][1]),
		.out(X264_Y110_incr_raddr));

	logic [ADDR_WIDTH-1:0] X264_Y110_waddr;
	logic [ADDR_WIDTH-1:0] X264_Y110_raddr;

	/* positional aliases */

	wire X263_Y110_incr_waddr;
	assign X263_Y110_incr_waddr = X264_Y110_incr_waddr;
	wire [ADDR_WIDTH-1:0] X263_Y110_waddr;
	assign X263_Y110_waddr = X264_Y110_waddr;
	wire X263_Y109_incr_raddr;
	assign X263_Y109_incr_raddr = X264_Y110_incr_raddr;
	wire [ADDR_WIDTH-1:0] X263_Y109_raddr;
	assign X263_Y109_raddr = X264_Y110_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X264_Y110(.clk(bus_clock),
		.incr_waddr(X264_Y110_incr_waddr),
		.waddr(X264_Y110_waddr),
		.incr_raddr(X264_Y110_incr_raddr),
		.raddr(X264_Y110_raddr));


	/* generated from E@X265_Y110@{S[3][31],S[3][30]}@4 */

	logic [DATA_WIDTH-1:0] X265_Y110_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X265_Y110_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_30_bus_first_egress_fifo(.clock(bus_clock),
		.in(X265_Y110_bus_rdata_in),
		.out(X265_Y110_bus_rdata_out));

	assign north_out_reg[3][31][10:0] = X265_Y110_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][30][10:2] = X265_Y110_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X265_Y110(.data(/* from design */),
		.q(X265_Y110_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X265_Y110_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X126_Y109@{N[1][4],N[1][5]}@3 */

	logic [DATA_WIDTH-1:0] X126_Y109_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X126_Y109_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_5_bus_first_egress_fifo(.clock(bus_clock),
		.in(X126_Y109_bus_rdata_in),
		.out(X126_Y109_bus_rdata_out));

	assign south_out_reg[1][4][10:0] = X126_Y109_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][5][10:2] = X126_Y109_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X126_Y109(.data(/* from design */),
		.q(X126_Y109_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X126_Y109_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X127_Y109@{S[1][5],S[1][6]}@3 */

	logic X127_Y109_incr_waddr; // ingress control
	logic X127_Y109_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_6_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][6][0]),
		.out(X127_Y109_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_6_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][6][1]),
		.out(X127_Y109_incr_raddr));

	logic [ADDR_WIDTH-1:0] X127_Y109_waddr;
	logic [ADDR_WIDTH-1:0] X127_Y109_raddr;

	/* positional aliases */

	wire X128_Y109_incr_waddr;
	assign X128_Y109_incr_waddr = X127_Y109_incr_waddr;
	wire [ADDR_WIDTH-1:0] X128_Y109_waddr;
	assign X128_Y109_waddr = X127_Y109_waddr;
	wire X128_Y110_incr_raddr;
	assign X128_Y110_incr_raddr = X127_Y109_incr_raddr;
	wire [ADDR_WIDTH-1:0] X128_Y110_raddr;
	assign X128_Y110_raddr = X127_Y109_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X127_Y109(.clk(bus_clock),
		.incr_waddr(X127_Y109_incr_waddr),
		.waddr(X127_Y109_waddr),
		.incr_raddr(X127_Y109_incr_raddr),
		.raddr(X127_Y109_raddr));


	/* generated from I@X128_Y109@{S[1][6],S[1][7]}@3 */

	logic [DATA_WIDTH-1:0] X128_Y109_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_7_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][6][10:0], south_in_reg[1][7][10:2]}),
		.out(X128_Y109_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X128_Y109(.data(X128_Y109_bus_wdata),
		.q(/* to design */),
		.wraddress(X128_Y109_waddr),
		.rdaddress(/* from design */),
		.wren(X128_Y109_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X137_Y109@{N[1][12],N[1][13]}@3 */

	logic [DATA_WIDTH-1:0] X137_Y109_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X137_Y109_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_13_bus_first_egress_fifo(.clock(bus_clock),
		.in(X137_Y109_bus_rdata_in),
		.out(X137_Y109_bus_rdata_out));

	assign south_out_reg[1][12][10:0] = X137_Y109_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][13][10:2] = X137_Y109_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X137_Y109(.data(/* from design */),
		.q(X137_Y109_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X137_Y109_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X138_Y109@{S[1][13],S[1][14]}@3 */

	logic X138_Y109_incr_waddr; // ingress control
	logic X138_Y109_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_14_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][14][0]),
		.out(X138_Y109_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_14_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][14][1]),
		.out(X138_Y109_incr_raddr));

	logic [ADDR_WIDTH-1:0] X138_Y109_waddr;
	logic [ADDR_WIDTH-1:0] X138_Y109_raddr;

	/* positional aliases */

	wire X139_Y109_incr_waddr;
	assign X139_Y109_incr_waddr = X138_Y109_incr_waddr;
	wire [ADDR_WIDTH-1:0] X139_Y109_waddr;
	assign X139_Y109_waddr = X138_Y109_waddr;
	wire X139_Y110_incr_raddr;
	assign X139_Y110_incr_raddr = X138_Y109_incr_raddr;
	wire [ADDR_WIDTH-1:0] X139_Y110_raddr;
	assign X139_Y110_raddr = X138_Y109_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X138_Y109(.clk(bus_clock),
		.incr_waddr(X138_Y109_incr_waddr),
		.waddr(X138_Y109_waddr),
		.incr_raddr(X138_Y109_incr_raddr),
		.raddr(X138_Y109_raddr));


	/* generated from I@X139_Y109@{S[1][14],S[1][15]}@3 */

	logic [DATA_WIDTH-1:0] X139_Y109_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_15_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][14][10:0], south_in_reg[1][15][10:2]}),
		.out(X139_Y109_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X139_Y109(.data(X139_Y109_bus_wdata),
		.q(/* to design */),
		.wraddress(X139_Y109_waddr),
		.rdaddress(/* from design */),
		.wren(X139_Y109_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X153_Y109@{W[1][26],W[1][25]}@3 */

	logic [DATA_WIDTH-1:0] X153_Y109_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X153_Y109_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) west_to_east_sector_size_1_west_to_east_ip_size_25_bus_first_egress_fifo(.clock(bus_clock),
		.in(X153_Y109_bus_rdata_in),
		.out(X153_Y109_bus_rdata_out));

	assign east_out_reg[1][26][10:0] = X153_Y109_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][25][10:2] = X153_Y109_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X153_Y109(.data(/* from design */),
		.q(X153_Y109_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X153_Y109_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X169_Y109@{N[1][36],N[1][37]}@3 */

	logic [DATA_WIDTH-1:0] X169_Y109_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X169_Y109_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_37_bus_first_egress_fifo(.clock(bus_clock),
		.in(X169_Y109_bus_rdata_in),
		.out(X169_Y109_bus_rdata_out));

	assign south_out_reg[1][36][10:0] = X169_Y109_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][37][10:2] = X169_Y109_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X169_Y109(.data(/* from design */),
		.q(X169_Y109_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X169_Y109_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X170_Y109@{S[1][37],S[1][38]}@3 */

	logic X170_Y109_incr_waddr; // ingress control
	logic X170_Y109_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_38_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][38][0]),
		.out(X170_Y109_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_38_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][38][1]),
		.out(X170_Y109_incr_raddr));

	logic [ADDR_WIDTH-1:0] X170_Y109_waddr;
	logic [ADDR_WIDTH-1:0] X170_Y109_raddr;

	/* positional aliases */

	wire X171_Y109_incr_waddr;
	assign X171_Y109_incr_waddr = X170_Y109_incr_waddr;
	wire [ADDR_WIDTH-1:0] X171_Y109_waddr;
	assign X171_Y109_waddr = X170_Y109_waddr;
	wire X171_Y110_incr_raddr;
	assign X171_Y110_incr_raddr = X170_Y109_incr_raddr;
	wire [ADDR_WIDTH-1:0] X171_Y110_raddr;
	assign X171_Y110_raddr = X170_Y109_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X170_Y109(.clk(bus_clock),
		.incr_waddr(X170_Y109_incr_waddr),
		.waddr(X170_Y109_waddr),
		.incr_raddr(X170_Y109_incr_raddr),
		.raddr(X170_Y109_raddr));


	/* generated from I@X171_Y109@{S[1][38],S[1][39]}@3 */

	logic [DATA_WIDTH-1:0] X171_Y109_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_39_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][38][10:0], south_in_reg[1][39][10:2]}),
		.out(X171_Y109_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X171_Y109(.data(X171_Y109_bus_wdata),
		.q(/* to design */),
		.wraddress(X171_Y109_waddr),
		.rdaddress(/* from design */),
		.wren(X171_Y109_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X239_Y109@{E[1][26],E[1][25]}@2 */

	logic [DATA_WIDTH-1:0] X239_Y109_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X239_Y109_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_1_east_to_west_ip_size_25_bus_first_egress_fifo(.clock(bus_clock),
		.in(X239_Y109_bus_rdata_in),
		.out(X239_Y109_bus_rdata_out));

	assign west_out_reg[1][26][10:0] = X239_Y109_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][25][10:2] = X239_Y109_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X239_Y109(.data(/* from design */),
		.q(X239_Y109_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X239_Y109_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X253_Y109@{N[3][21],N[3][20]}@3 */

	logic [DATA_WIDTH-1:0] X253_Y109_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X253_Y109_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_20_bus_first_egress_fifo(.clock(bus_clock),
		.in(X253_Y109_bus_rdata_in),
		.out(X253_Y109_bus_rdata_out));

	assign south_out_reg[3][21][10:0] = X253_Y109_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][20][10:2] = X253_Y109_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X253_Y109(.data(/* from design */),
		.q(X253_Y109_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X253_Y109_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X255_Y109@{S[3][23],S[3][22]}@3 */

	logic [DATA_WIDTH-1:0] X255_Y109_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_22_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][23][10:0], south_in_reg[3][22][10:2]}),
		.out(X255_Y109_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X255_Y109(.data(X255_Y109_bus_wdata),
		.q(/* to design */),
		.wraddress(X255_Y109_waddr),
		.rdaddress(/* from design */),
		.wren(X255_Y109_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X256_Y109@{S[3][24],S[3][23]}@3 */

	logic X256_Y109_incr_waddr; // ingress control
	logic X256_Y109_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_23_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][24][0]),
		.out(X256_Y109_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_23_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][24][1]),
		.out(X256_Y109_incr_raddr));

	logic [ADDR_WIDTH-1:0] X256_Y109_waddr;
	logic [ADDR_WIDTH-1:0] X256_Y109_raddr;

	/* positional aliases */

	wire X255_Y109_incr_waddr;
	assign X255_Y109_incr_waddr = X256_Y109_incr_waddr;
	wire [ADDR_WIDTH-1:0] X255_Y109_waddr;
	assign X255_Y109_waddr = X256_Y109_waddr;
	wire X255_Y110_incr_raddr;
	assign X255_Y110_incr_raddr = X256_Y109_incr_raddr;
	wire [ADDR_WIDTH-1:0] X255_Y110_raddr;
	assign X255_Y110_raddr = X256_Y109_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X256_Y109(.clk(bus_clock),
		.incr_waddr(X256_Y109_incr_waddr),
		.waddr(X256_Y109_waddr),
		.incr_raddr(X256_Y109_incr_raddr),
		.raddr(X256_Y109_raddr));


	/* generated from E@X263_Y109@{N[3][29],N[3][28]}@3 */

	logic [DATA_WIDTH-1:0] X263_Y109_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X263_Y109_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_28_bus_first_egress_fifo(.clock(bus_clock),
		.in(X263_Y109_bus_rdata_in),
		.out(X263_Y109_bus_rdata_out));

	assign south_out_reg[3][29][10:0] = X263_Y109_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][28][10:2] = X263_Y109_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X263_Y109(.data(/* from design */),
		.q(X263_Y109_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X263_Y109_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X265_Y109@{S[3][31],S[3][30]}@3 */

	logic [DATA_WIDTH-1:0] X265_Y109_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_30_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][31][10:0], south_in_reg[3][30][10:2]}),
		.out(X265_Y109_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X265_Y109(.data(X265_Y109_bus_wdata),
		.q(/* to design */),
		.wraddress(X265_Y109_waddr),
		.rdaddress(/* from design */),
		.wren(X265_Y109_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X266_Y109@{S[3][32],S[3][31]}@3 */

	logic X266_Y109_incr_waddr; // ingress control
	logic X266_Y109_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_31_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][32][0]),
		.out(X266_Y109_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_31_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][32][1]),
		.out(X266_Y109_incr_raddr));

	logic [ADDR_WIDTH-1:0] X266_Y109_waddr;
	logic [ADDR_WIDTH-1:0] X266_Y109_raddr;

	/* positional aliases */

	wire X265_Y109_incr_waddr;
	assign X265_Y109_incr_waddr = X266_Y109_incr_waddr;
	wire [ADDR_WIDTH-1:0] X265_Y109_waddr;
	assign X265_Y109_waddr = X266_Y109_waddr;
	wire X265_Y110_incr_raddr;
	assign X265_Y110_incr_raddr = X266_Y109_incr_raddr;
	wire [ADDR_WIDTH-1:0] X265_Y110_raddr;
	assign X265_Y110_raddr = X266_Y109_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X266_Y109(.clk(bus_clock),
		.incr_waddr(X266_Y109_incr_waddr),
		.waddr(X266_Y109_waddr),
		.incr_raddr(X266_Y109_incr_raddr),
		.raddr(X266_Y109_raddr));


	/* generated from I@X83_Y108@{E[1][24],E[1][23]}@5 */

	logic [DATA_WIDTH-1:0] X83_Y108_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) east_to_west_sector_size_1_east_to_west_ip_size_23_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][24][10:0], east_in_reg[1][23][10:2]}),
		.out(X83_Y108_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X83_Y108(.data(X83_Y108_bus_wdata),
		.q(/* to design */),
		.wraddress(X83_Y108_waddr),
		.rdaddress(/* from design */),
		.wren(X83_Y108_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X84_Y108@{E[1][24],E[1][23]}@5 */

	logic X84_Y108_incr_waddr; // ingress control
	logic X84_Y108_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) east_to_west_sector_size_1_east_to_west_ip_size_23_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][23][0]),
		.out(X84_Y108_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) east_to_west_sector_size_1_east_to_west_ip_size_23_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][23][1]),
		.out(X84_Y108_incr_raddr));

	logic [ADDR_WIDTH-1:0] X84_Y108_waddr;
	logic [ADDR_WIDTH-1:0] X84_Y108_raddr;

	/* positional aliases */

	wire X83_Y108_incr_waddr;
	assign X83_Y108_incr_waddr = X84_Y108_incr_waddr;
	wire [ADDR_WIDTH-1:0] X83_Y108_waddr;
	assign X83_Y108_waddr = X84_Y108_waddr;
	wire X83_Y107_incr_raddr;
	assign X83_Y107_incr_raddr = X84_Y108_incr_raddr;
	wire [ADDR_WIDTH-1:0] X83_Y107_raddr;
	assign X83_Y107_raddr = X84_Y108_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X84_Y108(.clk(bus_clock),
		.incr_waddr(X84_Y108_incr_waddr),
		.waddr(X84_Y108_waddr),
		.incr_raddr(X84_Y108_incr_raddr),
		.raddr(X84_Y108_raddr));


	/* generated from C@X184_Y108@{W[1][24],W[1][23]}@3 */

	logic X184_Y108_incr_waddr; // ingress control
	logic X184_Y108_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_1_west_to_east_ip_size_23_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][24][0]),
		.out(X184_Y108_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_1_west_to_east_ip_size_23_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][24][1]),
		.out(X184_Y108_incr_raddr));

	logic [ADDR_WIDTH-1:0] X184_Y108_waddr;
	logic [ADDR_WIDTH-1:0] X184_Y108_raddr;

	/* positional aliases */

	wire X185_Y108_incr_waddr;
	assign X185_Y108_incr_waddr = X184_Y108_incr_waddr;
	wire [ADDR_WIDTH-1:0] X185_Y108_waddr;
	assign X185_Y108_waddr = X184_Y108_waddr;
	wire X185_Y107_incr_raddr;
	assign X185_Y107_incr_raddr = X184_Y108_incr_raddr;
	wire [ADDR_WIDTH-1:0] X185_Y107_raddr;
	assign X185_Y107_raddr = X184_Y108_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X184_Y108(.clk(bus_clock),
		.incr_waddr(X184_Y108_incr_waddr),
		.waddr(X184_Y108_waddr),
		.incr_raddr(X184_Y108_incr_raddr),
		.raddr(X184_Y108_raddr));


	/* generated from I@X185_Y108@{W[1][24],W[1][23]}@3 */

	logic [DATA_WIDTH-1:0] X185_Y108_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) west_to_east_sector_size_1_west_to_east_ip_size_23_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][24][10:0], west_in_reg[1][23][10:2]}),
		.out(X185_Y108_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X185_Y108(.data(X185_Y108_bus_wdata),
		.q(/* to design */),
		.wraddress(X185_Y108_waddr),
		.rdaddress(/* from design */),
		.wren(X185_Y108_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X83_Y107@{E[1][24],E[1][23]}@6 */

	logic [DATA_WIDTH-1:0] X83_Y107_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X83_Y107_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) east_to_west_sector_size_1_east_to_west_ip_size_23_bus_first_egress_fifo(.clock(bus_clock),
		.in(X83_Y107_bus_rdata_in),
		.out(X83_Y107_bus_rdata_out));

	assign west_out_reg[1][24][10:0] = X83_Y107_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][23][10:2] = X83_Y107_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X83_Y107(.data(/* from design */),
		.q(X83_Y107_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X83_Y107_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X185_Y107@{W[1][24],W[1][23]}@4 */

	logic [DATA_WIDTH-1:0] X185_Y107_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X185_Y107_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) west_to_east_sector_size_1_west_to_east_ip_size_23_bus_first_egress_fifo(.clock(bus_clock),
		.in(X185_Y107_bus_rdata_in),
		.out(X185_Y107_bus_rdata_out));

	assign east_out_reg[1][24][10:0] = X185_Y107_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][23][10:2] = X185_Y107_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X185_Y107(.data(/* from design */),
		.q(X185_Y107_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X185_Y107_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X82_Y106@{W[1][22],W[1][21]}@0 */

	logic X82_Y106_incr_waddr; // ingress control
	logic X82_Y106_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) west_to_east_sector_size_1_west_to_east_ip_size_21_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][21][0]),
		.out(X82_Y106_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) west_to_east_sector_size_1_west_to_east_ip_size_21_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][21][1]),
		.out(X82_Y106_incr_raddr));

	logic [ADDR_WIDTH-1:0] X82_Y106_waddr;
	logic [ADDR_WIDTH-1:0] X82_Y106_raddr;

	/* positional aliases */

	wire X83_Y106_incr_waddr;
	assign X83_Y106_incr_waddr = X82_Y106_incr_waddr;
	wire [ADDR_WIDTH-1:0] X83_Y106_waddr;
	assign X83_Y106_waddr = X82_Y106_waddr;
	wire X83_Y105_incr_raddr;
	assign X83_Y105_incr_raddr = X82_Y106_incr_raddr;
	wire [ADDR_WIDTH-1:0] X83_Y105_raddr;
	assign X83_Y105_raddr = X82_Y106_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X82_Y106(.clk(bus_clock),
		.incr_waddr(X82_Y106_incr_waddr),
		.waddr(X82_Y106_waddr),
		.incr_raddr(X82_Y106_incr_raddr),
		.raddr(X82_Y106_raddr));


	/* generated from I@X83_Y106@{W[1][22],W[1][21]}@0 */

	logic [DATA_WIDTH-1:0] X83_Y106_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) west_to_east_sector_size_1_west_to_east_ip_size_21_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][22][10:0], west_in_reg[1][21][10:2]}),
		.out(X83_Y106_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X83_Y106(.data(X83_Y106_bus_wdata),
		.q(/* to design */),
		.wraddress(X83_Y106_waddr),
		.rdaddress(/* from design */),
		.wren(X83_Y106_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X103_Y106@{N[0][27],N[0][28]}@2 */

	logic X103_Y106_incr_waddr; // ingress control
	logic X103_Y106_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_28_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][28][0]),
		.out(X103_Y106_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_28_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][28][1]),
		.out(X103_Y106_incr_raddr));

	logic [ADDR_WIDTH-1:0] X103_Y106_waddr;
	logic [ADDR_WIDTH-1:0] X103_Y106_raddr;

	/* positional aliases */

	wire X104_Y106_incr_waddr;
	assign X104_Y106_incr_waddr = X103_Y106_incr_waddr;
	wire [ADDR_WIDTH-1:0] X104_Y106_waddr;
	assign X104_Y106_waddr = X103_Y106_waddr;
	wire X104_Y105_incr_raddr;
	assign X104_Y105_incr_raddr = X103_Y106_incr_raddr;
	wire [ADDR_WIDTH-1:0] X104_Y105_raddr;
	assign X104_Y105_raddr = X103_Y106_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X103_Y106(.clk(bus_clock),
		.incr_waddr(X103_Y106_incr_waddr),
		.waddr(X103_Y106_waddr),
		.incr_raddr(X103_Y106_incr_raddr),
		.raddr(X103_Y106_raddr));


	/* generated from I@X104_Y106@{N[0][28],N[0][29]}@2 */

	logic [DATA_WIDTH-1:0] X104_Y106_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_29_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][28][10:0], north_in_reg[0][29][10:2]}),
		.out(X104_Y106_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X104_Y106(.data(X104_Y106_bus_wdata),
		.q(/* to design */),
		.wraddress(X104_Y106_waddr),
		.rdaddress(/* from design */),
		.wren(X104_Y106_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X106_Y106@{S[0][30],S[0][31]}@4 */

	logic [DATA_WIDTH-1:0] X106_Y106_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X106_Y106_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_31_bus_first_egress_fifo(.clock(bus_clock),
		.in(X106_Y106_bus_rdata_in),
		.out(X106_Y106_bus_rdata_out));

	assign north_out_reg[0][30][10:0] = X106_Y106_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][31][10:2] = X106_Y106_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X106_Y106(.data(/* from design */),
		.q(X106_Y106_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X106_Y106_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X185_Y106@{E[1][22],E[1][21]}@2 */

	logic [DATA_WIDTH-1:0] X185_Y106_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) east_to_west_sector_size_1_east_to_west_ip_size_21_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][22][10:0], east_in_reg[1][21][10:2]}),
		.out(X185_Y106_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X185_Y106(.data(X185_Y106_bus_wdata),
		.q(/* to design */),
		.wraddress(X185_Y106_waddr),
		.rdaddress(/* from design */),
		.wren(X185_Y106_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X186_Y106@{E[1][22],E[1][21]}@2 */

	logic X186_Y106_incr_waddr; // ingress control
	logic X186_Y106_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) east_to_west_sector_size_1_east_to_west_ip_size_21_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][22][0]),
		.out(X186_Y106_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) east_to_west_sector_size_1_east_to_west_ip_size_21_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][22][1]),
		.out(X186_Y106_incr_raddr));

	logic [ADDR_WIDTH-1:0] X186_Y106_waddr;
	logic [ADDR_WIDTH-1:0] X186_Y106_raddr;

	/* positional aliases */

	wire X185_Y106_incr_waddr;
	assign X185_Y106_incr_waddr = X186_Y106_incr_waddr;
	wire [ADDR_WIDTH-1:0] X185_Y106_waddr;
	assign X185_Y106_waddr = X186_Y106_waddr;
	wire X185_Y105_incr_raddr;
	assign X185_Y105_incr_raddr = X186_Y106_incr_raddr;
	wire [ADDR_WIDTH-1:0] X185_Y105_raddr;
	assign X185_Y105_raddr = X186_Y106_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X186_Y106(.clk(bus_clock),
		.incr_waddr(X186_Y106_incr_waddr),
		.waddr(X186_Y106_waddr),
		.incr_raddr(X186_Y106_incr_raddr),
		.raddr(X186_Y106_raddr));


	/* generated from I@X199_Y106@{N[2][21],N[2][20]}@2 */

	logic [DATA_WIDTH-1:0] X199_Y106_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_20_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][21][10:0], north_in_reg[2][20][10:2]}),
		.out(X199_Y106_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X199_Y106(.data(X199_Y106_bus_wdata),
		.q(/* to design */),
		.wraddress(X199_Y106_waddr),
		.rdaddress(/* from design */),
		.wren(X199_Y106_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X200_Y106@{N[2][22],N[2][21]}@2 */

	logic X200_Y106_incr_waddr; // ingress control
	logic X200_Y106_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_21_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[2][22][0]),
		.out(X200_Y106_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_21_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[2][22][1]),
		.out(X200_Y106_incr_raddr));

	logic [ADDR_WIDTH-1:0] X200_Y106_waddr;
	logic [ADDR_WIDTH-1:0] X200_Y106_raddr;

	/* positional aliases */

	wire X199_Y106_incr_waddr;
	assign X199_Y106_incr_waddr = X200_Y106_incr_waddr;
	wire [ADDR_WIDTH-1:0] X199_Y106_waddr;
	assign X199_Y106_waddr = X200_Y106_waddr;
	wire X199_Y105_incr_raddr;
	assign X199_Y105_incr_raddr = X200_Y106_incr_raddr;
	wire [ADDR_WIDTH-1:0] X199_Y105_raddr;
	assign X199_Y105_raddr = X200_Y106_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X200_Y106(.clk(bus_clock),
		.incr_waddr(X200_Y106_incr_waddr),
		.waddr(X200_Y106_waddr),
		.incr_raddr(X200_Y106_incr_raddr),
		.raddr(X200_Y106_raddr));


	/* generated from E@X201_Y106@{S[2][23],S[2][22]}@4 */

	logic [DATA_WIDTH-1:0] X201_Y106_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X201_Y106_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_22_bus_first_egress_fifo(.clock(bus_clock),
		.in(X201_Y106_bus_rdata_in),
		.out(X201_Y106_bus_rdata_out));

	assign north_out_reg[2][23][10:0] = X201_Y106_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][22][10:2] = X201_Y106_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X201_Y106(.data(/* from design */),
		.q(X201_Y106_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X201_Y106_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X209_Y106@{N[2][29],N[2][28]}@2 */

	logic [DATA_WIDTH-1:0] X209_Y106_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_28_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][29][10:0], north_in_reg[2][28][10:2]}),
		.out(X209_Y106_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X209_Y106(.data(X209_Y106_bus_wdata),
		.q(/* to design */),
		.wraddress(X209_Y106_waddr),
		.rdaddress(/* from design */),
		.wren(X209_Y106_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X210_Y106@{N[2][30],N[2][29]}@2 */

	logic X210_Y106_incr_waddr; // ingress control
	logic X210_Y106_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_29_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[2][30][0]),
		.out(X210_Y106_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_29_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[2][30][1]),
		.out(X210_Y106_incr_raddr));

	logic [ADDR_WIDTH-1:0] X210_Y106_waddr;
	logic [ADDR_WIDTH-1:0] X210_Y106_raddr;

	/* positional aliases */

	wire X209_Y106_incr_waddr;
	assign X209_Y106_incr_waddr = X210_Y106_incr_waddr;
	wire [ADDR_WIDTH-1:0] X209_Y106_waddr;
	assign X209_Y106_waddr = X210_Y106_waddr;
	wire X209_Y105_incr_raddr;
	assign X209_Y105_incr_raddr = X210_Y106_incr_raddr;
	wire [ADDR_WIDTH-1:0] X209_Y105_raddr;
	assign X209_Y105_raddr = X210_Y106_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X210_Y106(.clk(bus_clock),
		.incr_waddr(X210_Y106_incr_waddr),
		.waddr(X210_Y106_waddr),
		.incr_raddr(X210_Y106_incr_raddr),
		.raddr(X210_Y106_raddr));


	/* generated from E@X211_Y106@{S[2][31],S[2][30]}@4 */

	logic [DATA_WIDTH-1:0] X211_Y106_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X211_Y106_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_30_bus_first_egress_fifo(.clock(bus_clock),
		.in(X211_Y106_bus_rdata_in),
		.out(X211_Y106_bus_rdata_out));

	assign north_out_reg[2][31][10:0] = X211_Y106_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][30][10:2] = X211_Y106_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X211_Y106(.data(/* from design */),
		.q(X211_Y106_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X211_Y106_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X83_Y105@{W[1][22],W[1][21]}@1 */

	logic [DATA_WIDTH-1:0] X83_Y105_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X83_Y105_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) west_to_east_sector_size_1_west_to_east_ip_size_21_bus_first_egress_fifo(.clock(bus_clock),
		.in(X83_Y105_bus_rdata_in),
		.out(X83_Y105_bus_rdata_out));

	assign east_out_reg[1][22][10:0] = X83_Y105_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][21][10:2] = X83_Y105_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X83_Y105(.data(/* from design */),
		.q(X83_Y105_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X83_Y105_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X104_Y105@{N[0][28],N[0][29]}@3 */

	logic [DATA_WIDTH-1:0] X104_Y105_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X104_Y105_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_29_bus_first_egress_fifo(.clock(bus_clock),
		.in(X104_Y105_bus_rdata_in),
		.out(X104_Y105_bus_rdata_out));

	assign south_out_reg[0][28][10:0] = X104_Y105_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][29][10:2] = X104_Y105_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X104_Y105(.data(/* from design */),
		.q(X104_Y105_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X104_Y105_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X105_Y105@{S[0][29],S[0][30]}@3 */

	logic X105_Y105_incr_waddr; // ingress control
	logic X105_Y105_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_30_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][30][0]),
		.out(X105_Y105_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_30_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][30][1]),
		.out(X105_Y105_incr_raddr));

	logic [ADDR_WIDTH-1:0] X105_Y105_waddr;
	logic [ADDR_WIDTH-1:0] X105_Y105_raddr;

	/* positional aliases */

	wire X106_Y105_incr_waddr;
	assign X106_Y105_incr_waddr = X105_Y105_incr_waddr;
	wire [ADDR_WIDTH-1:0] X106_Y105_waddr;
	assign X106_Y105_waddr = X105_Y105_waddr;
	wire X106_Y106_incr_raddr;
	assign X106_Y106_incr_raddr = X105_Y105_incr_raddr;
	wire [ADDR_WIDTH-1:0] X106_Y106_raddr;
	assign X106_Y106_raddr = X105_Y105_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X105_Y105(.clk(bus_clock),
		.incr_waddr(X105_Y105_incr_waddr),
		.waddr(X105_Y105_waddr),
		.incr_raddr(X105_Y105_incr_raddr),
		.raddr(X105_Y105_raddr));


	/* generated from I@X106_Y105@{S[0][30],S[0][31]}@3 */

	logic [DATA_WIDTH-1:0] X106_Y105_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_31_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][30][10:0], south_in_reg[0][31][10:2]}),
		.out(X106_Y105_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X106_Y105(.data(X106_Y105_bus_wdata),
		.q(/* to design */),
		.wraddress(X106_Y105_waddr),
		.rdaddress(/* from design */),
		.wren(X106_Y105_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X185_Y105@{E[1][22],E[1][21]}@3 */

	logic [DATA_WIDTH-1:0] X185_Y105_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X185_Y105_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) east_to_west_sector_size_1_east_to_west_ip_size_21_bus_first_egress_fifo(.clock(bus_clock),
		.in(X185_Y105_bus_rdata_in),
		.out(X185_Y105_bus_rdata_out));

	assign west_out_reg[1][22][10:0] = X185_Y105_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][21][10:2] = X185_Y105_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X185_Y105(.data(/* from design */),
		.q(X185_Y105_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X185_Y105_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X199_Y105@{N[2][21],N[2][20]}@3 */

	logic [DATA_WIDTH-1:0] X199_Y105_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X199_Y105_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_20_bus_first_egress_fifo(.clock(bus_clock),
		.in(X199_Y105_bus_rdata_in),
		.out(X199_Y105_bus_rdata_out));

	assign south_out_reg[2][21][10:0] = X199_Y105_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][20][10:2] = X199_Y105_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X199_Y105(.data(/* from design */),
		.q(X199_Y105_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X199_Y105_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X201_Y105@{S[2][23],S[2][22]}@3 */

	logic [DATA_WIDTH-1:0] X201_Y105_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_22_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][23][10:0], south_in_reg[2][22][10:2]}),
		.out(X201_Y105_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X201_Y105(.data(X201_Y105_bus_wdata),
		.q(/* to design */),
		.wraddress(X201_Y105_waddr),
		.rdaddress(/* from design */),
		.wren(X201_Y105_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X202_Y105@{S[2][24],S[2][23]}@3 */

	logic X202_Y105_incr_waddr; // ingress control
	logic X202_Y105_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_23_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[2][24][0]),
		.out(X202_Y105_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_23_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[2][24][1]),
		.out(X202_Y105_incr_raddr));

	logic [ADDR_WIDTH-1:0] X202_Y105_waddr;
	logic [ADDR_WIDTH-1:0] X202_Y105_raddr;

	/* positional aliases */

	wire X201_Y105_incr_waddr;
	assign X201_Y105_incr_waddr = X202_Y105_incr_waddr;
	wire [ADDR_WIDTH-1:0] X201_Y105_waddr;
	assign X201_Y105_waddr = X202_Y105_waddr;
	wire X201_Y106_incr_raddr;
	assign X201_Y106_incr_raddr = X202_Y105_incr_raddr;
	wire [ADDR_WIDTH-1:0] X201_Y106_raddr;
	assign X201_Y106_raddr = X202_Y105_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X202_Y105(.clk(bus_clock),
		.incr_waddr(X202_Y105_incr_waddr),
		.waddr(X202_Y105_waddr),
		.incr_raddr(X202_Y105_incr_raddr),
		.raddr(X202_Y105_raddr));


	/* generated from E@X209_Y105@{N[2][29],N[2][28]}@3 */

	logic [DATA_WIDTH-1:0] X209_Y105_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X209_Y105_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_28_bus_first_egress_fifo(.clock(bus_clock),
		.in(X209_Y105_bus_rdata_in),
		.out(X209_Y105_bus_rdata_out));

	assign south_out_reg[2][29][10:0] = X209_Y105_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][28][10:2] = X209_Y105_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X209_Y105(.data(/* from design */),
		.q(X209_Y105_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X209_Y105_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X211_Y105@{S[2][31],S[2][30]}@3 */

	logic [DATA_WIDTH-1:0] X211_Y105_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_30_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][31][10:0], south_in_reg[2][30][10:2]}),
		.out(X211_Y105_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X211_Y105(.data(X211_Y105_bus_wdata),
		.q(/* to design */),
		.wraddress(X211_Y105_waddr),
		.rdaddress(/* from design */),
		.wren(X211_Y105_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X212_Y105@{S[2][32],S[2][31]}@3 */

	logic X212_Y105_incr_waddr; // ingress control
	logic X212_Y105_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_31_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[2][32][0]),
		.out(X212_Y105_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_31_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[2][32][1]),
		.out(X212_Y105_incr_raddr));

	logic [ADDR_WIDTH-1:0] X212_Y105_waddr;
	logic [ADDR_WIDTH-1:0] X212_Y105_raddr;

	/* positional aliases */

	wire X211_Y105_incr_waddr;
	assign X211_Y105_incr_waddr = X212_Y105_incr_waddr;
	wire [ADDR_WIDTH-1:0] X211_Y105_waddr;
	assign X211_Y105_waddr = X212_Y105_waddr;
	wire X211_Y106_incr_raddr;
	assign X211_Y106_incr_raddr = X212_Y105_incr_raddr;
	wire [ADDR_WIDTH-1:0] X211_Y106_raddr;
	assign X211_Y106_raddr = X212_Y105_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X212_Y105(.clk(bus_clock),
		.incr_waddr(X212_Y105_incr_waddr),
		.waddr(X212_Y105_waddr),
		.incr_raddr(X212_Y105_incr_raddr),
		.raddr(X212_Y105_raddr));


	/* generated from I@X132_Y104@{E[1][20],E[1][19]}@4 */

	logic [DATA_WIDTH-1:0] X132_Y104_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_1_east_to_west_ip_size_19_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][20][10:0], east_in_reg[1][19][10:2]}),
		.out(X132_Y104_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X132_Y104(.data(X132_Y104_bus_wdata),
		.q(/* to design */),
		.wraddress(X132_Y104_waddr),
		.rdaddress(/* from design */),
		.wren(X132_Y104_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X133_Y104@{E[1][20],E[1][19]}@4 */

	logic X133_Y104_incr_waddr; // ingress control
	logic X133_Y104_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_1_east_to_west_ip_size_19_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][19][0]),
		.out(X133_Y104_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_1_east_to_west_ip_size_19_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][19][1]),
		.out(X133_Y104_incr_raddr));

	logic [ADDR_WIDTH-1:0] X133_Y104_waddr;
	logic [ADDR_WIDTH-1:0] X133_Y104_raddr;

	/* positional aliases */

	wire X132_Y104_incr_waddr;
	assign X132_Y104_incr_waddr = X133_Y104_incr_waddr;
	wire [ADDR_WIDTH-1:0] X132_Y104_waddr;
	assign X132_Y104_waddr = X133_Y104_waddr;
	wire X132_Y103_incr_raddr;
	assign X132_Y103_incr_raddr = X133_Y104_incr_raddr;
	wire [ADDR_WIDTH-1:0] X132_Y103_raddr;
	assign X132_Y103_raddr = X133_Y104_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X133_Y104(.clk(bus_clock),
		.incr_waddr(X133_Y104_incr_waddr),
		.waddr(X133_Y104_waddr),
		.incr_raddr(X133_Y104_incr_raddr),
		.raddr(X133_Y104_raddr));


	/* generated from C@X259_Y104@{W[1][20],W[1][19]}@5 */

	logic X259_Y104_incr_waddr; // ingress control
	logic X259_Y104_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) west_to_east_sector_size_1_west_to_east_ip_size_19_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][20][0]),
		.out(X259_Y104_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) west_to_east_sector_size_1_west_to_east_ip_size_19_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][20][1]),
		.out(X259_Y104_incr_raddr));

	logic [ADDR_WIDTH-1:0] X259_Y104_waddr;
	logic [ADDR_WIDTH-1:0] X259_Y104_raddr;

	/* positional aliases */

	wire X260_Y104_incr_waddr;
	assign X260_Y104_incr_waddr = X259_Y104_incr_waddr;
	wire [ADDR_WIDTH-1:0] X260_Y104_waddr;
	assign X260_Y104_waddr = X259_Y104_waddr;
	wire X260_Y103_incr_raddr;
	assign X260_Y103_incr_raddr = X259_Y104_incr_raddr;
	wire [ADDR_WIDTH-1:0] X260_Y103_raddr;
	assign X260_Y103_raddr = X259_Y104_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X259_Y104(.clk(bus_clock),
		.incr_waddr(X259_Y104_incr_waddr),
		.waddr(X259_Y104_waddr),
		.incr_raddr(X259_Y104_incr_raddr),
		.raddr(X259_Y104_raddr));


	/* generated from I@X260_Y104@{W[1][20],W[1][19]}@5 */

	logic [DATA_WIDTH-1:0] X260_Y104_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) west_to_east_sector_size_1_west_to_east_ip_size_19_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][20][10:0], west_in_reg[1][19][10:2]}),
		.out(X260_Y104_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X260_Y104(.data(X260_Y104_bus_wdata),
		.q(/* to design */),
		.wraddress(X260_Y104_waddr),
		.rdaddress(/* from design */),
		.wren(X260_Y104_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X132_Y103@{E[1][20],E[1][19]}@5 */

	logic [DATA_WIDTH-1:0] X132_Y103_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X132_Y103_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_1_east_to_west_ip_size_19_bus_first_egress_fifo(.clock(bus_clock),
		.in(X132_Y103_bus_rdata_in),
		.out(X132_Y103_bus_rdata_out));

	assign west_out_reg[1][20][10:0] = X132_Y103_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][19][10:2] = X132_Y103_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X132_Y103(.data(/* from design */),
		.q(X132_Y103_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X132_Y103_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X260_Y103@{W[1][20],W[1][19]}@6 */

	logic [DATA_WIDTH-1:0] X260_Y103_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X260_Y103_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) west_to_east_sector_size_1_west_to_east_ip_size_19_bus_first_egress_fifo(.clock(bus_clock),
		.in(X260_Y103_bus_rdata_in),
		.out(X260_Y103_bus_rdata_out));

	assign east_out_reg[1][20][10:0] = X260_Y103_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][19][10:2] = X260_Y103_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X260_Y103(.data(/* from design */),
		.q(X260_Y103_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X260_Y103_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X131_Y102@{W[1][18],W[1][17]}@1 */

	logic X131_Y102_incr_waddr; // ingress control
	logic X131_Y102_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_1_west_to_east_ip_size_17_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][17][0]),
		.out(X131_Y102_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_1_west_to_east_ip_size_17_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][17][1]),
		.out(X131_Y102_incr_raddr));

	logic [ADDR_WIDTH-1:0] X131_Y102_waddr;
	logic [ADDR_WIDTH-1:0] X131_Y102_raddr;

	/* positional aliases */

	wire X132_Y102_incr_waddr;
	assign X132_Y102_incr_waddr = X131_Y102_incr_waddr;
	wire [ADDR_WIDTH-1:0] X132_Y102_waddr;
	assign X132_Y102_waddr = X131_Y102_waddr;
	wire X132_Y101_incr_raddr;
	assign X132_Y101_incr_raddr = X131_Y102_incr_raddr;
	wire [ADDR_WIDTH-1:0] X132_Y101_raddr;
	assign X132_Y101_raddr = X131_Y102_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X131_Y102(.clk(bus_clock),
		.incr_waddr(X131_Y102_incr_waddr),
		.waddr(X131_Y102_waddr),
		.incr_raddr(X131_Y102_incr_raddr),
		.raddr(X131_Y102_raddr));


	/* generated from I@X132_Y102@{W[1][18],W[1][17]}@1 */

	logic [DATA_WIDTH-1:0] X132_Y102_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_1_west_to_east_ip_size_17_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][18][10:0], west_in_reg[1][17][10:2]}),
		.out(X132_Y102_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X132_Y102(.data(X132_Y102_bus_wdata),
		.q(/* to design */),
		.wraddress(X132_Y102_waddr),
		.rdaddress(/* from design */),
		.wren(X132_Y102_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X153_Y102@{S[1][24],S[1][25]}@3 */

	logic [DATA_WIDTH-1:0] X153_Y102_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X153_Y102_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_25_bus_first_egress_fifo(.clock(bus_clock),
		.in(X153_Y102_bus_rdata_in),
		.out(X153_Y102_bus_rdata_out));

	assign north_out_reg[1][24][10:0] = X153_Y102_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][25][10:2] = X153_Y102_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X153_Y102(.data(/* from design */),
		.q(X153_Y102_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X153_Y102_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X154_Y102@{N[1][25],N[1][26]}@3 */

	logic X154_Y102_incr_waddr; // ingress control
	logic X154_Y102_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_26_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][26][0]),
		.out(X154_Y102_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_26_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][26][1]),
		.out(X154_Y102_incr_raddr));

	logic [ADDR_WIDTH-1:0] X154_Y102_waddr;
	logic [ADDR_WIDTH-1:0] X154_Y102_raddr;

	/* positional aliases */

	wire X155_Y102_incr_waddr;
	assign X155_Y102_incr_waddr = X154_Y102_incr_waddr;
	wire [ADDR_WIDTH-1:0] X155_Y102_waddr;
	assign X155_Y102_waddr = X154_Y102_waddr;
	wire X155_Y101_incr_raddr;
	assign X155_Y101_incr_raddr = X154_Y102_incr_raddr;
	wire [ADDR_WIDTH-1:0] X155_Y101_raddr;
	assign X155_Y101_raddr = X154_Y102_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X154_Y102(.clk(bus_clock),
		.incr_waddr(X154_Y102_incr_waddr),
		.waddr(X154_Y102_waddr),
		.incr_raddr(X154_Y102_incr_raddr),
		.raddr(X154_Y102_raddr));


	/* generated from I@X155_Y102@{N[1][26],N[1][27]}@3 */

	logic [DATA_WIDTH-1:0] X155_Y102_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_27_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][26][10:0], north_in_reg[1][27][10:2]}),
		.out(X155_Y102_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X155_Y102(.data(X155_Y102_bus_wdata),
		.q(/* to design */),
		.wraddress(X155_Y102_waddr),
		.rdaddress(/* from design */),
		.wren(X155_Y102_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X237_Y102@{S[3][9],S[3][8]}@3 */

	logic [DATA_WIDTH-1:0] X237_Y102_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X237_Y102_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_8_bus_first_egress_fifo(.clock(bus_clock),
		.in(X237_Y102_bus_rdata_in),
		.out(X237_Y102_bus_rdata_out));

	assign north_out_reg[3][9][10:0] = X237_Y102_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][8][10:2] = X237_Y102_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X237_Y102(.data(/* from design */),
		.q(X237_Y102_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X237_Y102_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X239_Y102@{N[3][11],N[3][10]}@3 */

	logic [DATA_WIDTH-1:0] X239_Y102_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_10_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][11][10:0], north_in_reg[3][10][10:2]}),
		.out(X239_Y102_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X239_Y102(.data(X239_Y102_bus_wdata),
		.q(/* to design */),
		.wraddress(X239_Y102_waddr),
		.rdaddress(/* from design */),
		.wren(X239_Y102_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X240_Y102@{N[3][12],N[3][11]}@3 */

	logic X240_Y102_incr_waddr; // ingress control
	logic X240_Y102_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_11_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][12][0]),
		.out(X240_Y102_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_11_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][12][1]),
		.out(X240_Y102_incr_raddr));

	logic [ADDR_WIDTH-1:0] X240_Y102_waddr;
	logic [ADDR_WIDTH-1:0] X240_Y102_raddr;

	/* positional aliases */

	wire X239_Y102_incr_waddr;
	assign X239_Y102_incr_waddr = X240_Y102_incr_waddr;
	wire [ADDR_WIDTH-1:0] X239_Y102_waddr;
	assign X239_Y102_waddr = X240_Y102_waddr;
	wire X239_Y101_incr_raddr;
	assign X239_Y101_incr_raddr = X240_Y102_incr_raddr;
	wire [ADDR_WIDTH-1:0] X239_Y101_raddr;
	assign X239_Y101_raddr = X240_Y102_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X240_Y102(.clk(bus_clock),
		.incr_waddr(X240_Y102_incr_waddr),
		.waddr(X240_Y102_waddr),
		.incr_raddr(X240_Y102_incr_raddr),
		.raddr(X240_Y102_raddr));


	/* generated from I@X260_Y102@{E[1][18],E[1][17]}@0 */

	logic [DATA_WIDTH-1:0] X260_Y102_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) east_to_west_sector_size_1_east_to_west_ip_size_17_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][18][10:0], east_in_reg[1][17][10:2]}),
		.out(X260_Y102_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X260_Y102(.data(X260_Y102_bus_wdata),
		.q(/* to design */),
		.wraddress(X260_Y102_waddr),
		.rdaddress(/* from design */),
		.wren(X260_Y102_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X261_Y102@{E[1][18],E[1][17]}@0 */

	logic X261_Y102_incr_waddr; // ingress control
	logic X261_Y102_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) east_to_west_sector_size_1_east_to_west_ip_size_17_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][18][0]),
		.out(X261_Y102_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) east_to_west_sector_size_1_east_to_west_ip_size_17_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][18][1]),
		.out(X261_Y102_incr_raddr));

	logic [ADDR_WIDTH-1:0] X261_Y102_waddr;
	logic [ADDR_WIDTH-1:0] X261_Y102_raddr;

	/* positional aliases */

	wire X260_Y102_incr_waddr;
	assign X260_Y102_incr_waddr = X261_Y102_incr_waddr;
	wire [ADDR_WIDTH-1:0] X260_Y102_waddr;
	assign X260_Y102_waddr = X261_Y102_waddr;
	wire X260_Y101_incr_raddr;
	assign X260_Y101_incr_raddr = X261_Y102_incr_raddr;
	wire [ADDR_WIDTH-1:0] X260_Y101_raddr;
	assign X260_Y101_raddr = X261_Y102_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X261_Y102(.clk(bus_clock),
		.incr_waddr(X261_Y102_incr_waddr),
		.waddr(X261_Y102_waddr),
		.incr_raddr(X261_Y102_incr_raddr),
		.raddr(X261_Y102_raddr));


	/* generated from E@X132_Y101@{W[1][18],W[1][17]}@2 */

	logic [DATA_WIDTH-1:0] X132_Y101_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X132_Y101_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_1_west_to_east_ip_size_17_bus_first_egress_fifo(.clock(bus_clock),
		.in(X132_Y101_bus_rdata_in),
		.out(X132_Y101_bus_rdata_out));

	assign east_out_reg[1][18][10:0] = X132_Y101_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][17][10:2] = X132_Y101_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X132_Y101(.data(/* from design */),
		.q(X132_Y101_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X132_Y101_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X152_Y101@{S[1][23],S[1][24]}@2 */

	logic X152_Y101_incr_waddr; // ingress control
	logic X152_Y101_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_24_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][24][0]),
		.out(X152_Y101_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_24_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][24][1]),
		.out(X152_Y101_incr_raddr));

	logic [ADDR_WIDTH-1:0] X152_Y101_waddr;
	logic [ADDR_WIDTH-1:0] X152_Y101_raddr;

	/* positional aliases */

	wire X153_Y101_incr_waddr;
	assign X153_Y101_incr_waddr = X152_Y101_incr_waddr;
	wire [ADDR_WIDTH-1:0] X153_Y101_waddr;
	assign X153_Y101_waddr = X152_Y101_waddr;
	wire X153_Y102_incr_raddr;
	assign X153_Y102_incr_raddr = X152_Y101_incr_raddr;
	wire [ADDR_WIDTH-1:0] X153_Y102_raddr;
	assign X153_Y102_raddr = X152_Y101_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X152_Y101(.clk(bus_clock),
		.incr_waddr(X152_Y101_incr_waddr),
		.waddr(X152_Y101_waddr),
		.incr_raddr(X152_Y101_incr_raddr),
		.raddr(X152_Y101_raddr));


	/* generated from I@X153_Y101@{S[1][24],S[1][25]}@2 */

	logic [DATA_WIDTH-1:0] X153_Y101_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_25_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][24][10:0], south_in_reg[1][25][10:2]}),
		.out(X153_Y101_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X153_Y101(.data(X153_Y101_bus_wdata),
		.q(/* to design */),
		.wraddress(X153_Y101_waddr),
		.rdaddress(/* from design */),
		.wren(X153_Y101_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X155_Y101@{N[1][26],N[1][27]}@4 */

	logic [DATA_WIDTH-1:0] X155_Y101_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X155_Y101_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_27_bus_first_egress_fifo(.clock(bus_clock),
		.in(X155_Y101_bus_rdata_in),
		.out(X155_Y101_bus_rdata_out));

	assign south_out_reg[1][26][10:0] = X155_Y101_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][27][10:2] = X155_Y101_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X155_Y101(.data(/* from design */),
		.q(X155_Y101_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X155_Y101_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X237_Y101@{S[3][9],S[3][8]}@2 */

	logic [DATA_WIDTH-1:0] X237_Y101_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_8_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][9][10:0], south_in_reg[3][8][10:2]}),
		.out(X237_Y101_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X237_Y101(.data(X237_Y101_bus_wdata),
		.q(/* to design */),
		.wraddress(X237_Y101_waddr),
		.rdaddress(/* from design */),
		.wren(X237_Y101_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X238_Y101@{S[3][10],S[3][9]}@2 */

	logic X238_Y101_incr_waddr; // ingress control
	logic X238_Y101_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_9_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][10][0]),
		.out(X238_Y101_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_9_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][10][1]),
		.out(X238_Y101_incr_raddr));

	logic [ADDR_WIDTH-1:0] X238_Y101_waddr;
	logic [ADDR_WIDTH-1:0] X238_Y101_raddr;

	/* positional aliases */

	wire X237_Y101_incr_waddr;
	assign X237_Y101_incr_waddr = X238_Y101_incr_waddr;
	wire [ADDR_WIDTH-1:0] X237_Y101_waddr;
	assign X237_Y101_waddr = X238_Y101_waddr;
	wire X237_Y102_incr_raddr;
	assign X237_Y102_incr_raddr = X238_Y101_incr_raddr;
	wire [ADDR_WIDTH-1:0] X237_Y102_raddr;
	assign X237_Y102_raddr = X238_Y101_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X238_Y101(.clk(bus_clock),
		.incr_waddr(X238_Y101_incr_waddr),
		.waddr(X238_Y101_waddr),
		.incr_raddr(X238_Y101_incr_raddr),
		.raddr(X238_Y101_raddr));


	/* generated from E@X239_Y101@{N[3][11],N[3][10]}@4 */

	logic [DATA_WIDTH-1:0] X239_Y101_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X239_Y101_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_10_bus_first_egress_fifo(.clock(bus_clock),
		.in(X239_Y101_bus_rdata_in),
		.out(X239_Y101_bus_rdata_out));

	assign south_out_reg[3][11][10:0] = X239_Y101_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][10][10:2] = X239_Y101_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X239_Y101(.data(/* from design */),
		.q(X239_Y101_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X239_Y101_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X260_Y101@{E[1][18],E[1][17]}@1 */

	logic [DATA_WIDTH-1:0] X260_Y101_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X260_Y101_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) east_to_west_sector_size_1_east_to_west_ip_size_17_bus_first_egress_fifo(.clock(bus_clock),
		.in(X260_Y101_bus_rdata_in),
		.out(X260_Y101_bus_rdata_out));

	assign west_out_reg[1][18][10:0] = X260_Y101_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][17][10:2] = X260_Y101_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X260_Y101(.data(/* from design */),
		.q(X260_Y101_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X260_Y101_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X104_Y100@{E[1][16],E[1][15]}@4 */

	logic [DATA_WIDTH-1:0] X104_Y100_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_1_east_to_west_ip_size_15_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][16][10:0], east_in_reg[1][15][10:2]}),
		.out(X104_Y100_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X104_Y100(.data(X104_Y100_bus_wdata),
		.q(/* to design */),
		.wraddress(X104_Y100_waddr),
		.rdaddress(/* from design */),
		.wren(X104_Y100_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X105_Y100@{E[1][16],E[1][15]}@4 */

	logic X105_Y100_incr_waddr; // ingress control
	logic X105_Y100_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_1_east_to_west_ip_size_15_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][15][0]),
		.out(X105_Y100_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_1_east_to_west_ip_size_15_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][15][1]),
		.out(X105_Y100_incr_raddr));

	logic [ADDR_WIDTH-1:0] X105_Y100_waddr;
	logic [ADDR_WIDTH-1:0] X105_Y100_raddr;

	/* positional aliases */

	wire X104_Y100_incr_waddr;
	assign X104_Y100_incr_waddr = X105_Y100_incr_waddr;
	wire [ADDR_WIDTH-1:0] X104_Y100_waddr;
	assign X104_Y100_waddr = X105_Y100_waddr;
	wire X104_Y99_incr_raddr;
	assign X104_Y99_incr_raddr = X105_Y100_incr_raddr;
	wire [ADDR_WIDTH-1:0] X104_Y99_raddr;
	assign X104_Y99_raddr = X105_Y100_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X105_Y100(.clk(bus_clock),
		.incr_waddr(X105_Y100_incr_waddr),
		.waddr(X105_Y100_waddr),
		.incr_raddr(X105_Y100_incr_raddr),
		.raddr(X105_Y100_raddr));


	/* generated from C@X205_Y100@{W[1][16],W[1][15]}@3 */

	logic X205_Y100_incr_waddr; // ingress control
	logic X205_Y100_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_1_west_to_east_ip_size_15_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][16][0]),
		.out(X205_Y100_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_1_west_to_east_ip_size_15_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][16][1]),
		.out(X205_Y100_incr_raddr));

	logic [ADDR_WIDTH-1:0] X205_Y100_waddr;
	logic [ADDR_WIDTH-1:0] X205_Y100_raddr;

	/* positional aliases */

	wire X206_Y100_incr_waddr;
	assign X206_Y100_incr_waddr = X205_Y100_incr_waddr;
	wire [ADDR_WIDTH-1:0] X206_Y100_waddr;
	assign X206_Y100_waddr = X205_Y100_waddr;
	wire X206_Y99_incr_raddr;
	assign X206_Y99_incr_raddr = X205_Y100_incr_raddr;
	wire [ADDR_WIDTH-1:0] X206_Y99_raddr;
	assign X206_Y99_raddr = X205_Y100_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X205_Y100(.clk(bus_clock),
		.incr_waddr(X205_Y100_incr_waddr),
		.waddr(X205_Y100_waddr),
		.incr_raddr(X205_Y100_incr_raddr),
		.raddr(X205_Y100_raddr));


	/* generated from I@X206_Y100@{W[1][16],W[1][15]}@4 */

	logic [DATA_WIDTH-1:0] X206_Y100_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_1_west_to_east_ip_size_15_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][16][10:0], west_in_reg[1][15][10:2]}),
		.out(X206_Y100_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X206_Y100(.data(X206_Y100_bus_wdata),
		.q(/* to design */),
		.wraddress(X206_Y100_waddr),
		.rdaddress(/* from design */),
		.wren(X206_Y100_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X104_Y99@{E[1][16],E[1][15]}@5 */

	logic [DATA_WIDTH-1:0] X104_Y99_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X104_Y99_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_1_east_to_west_ip_size_15_bus_first_egress_fifo(.clock(bus_clock),
		.in(X104_Y99_bus_rdata_in),
		.out(X104_Y99_bus_rdata_out));

	assign west_out_reg[1][16][10:0] = X104_Y99_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][15][10:2] = X104_Y99_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X104_Y99(.data(/* from design */),
		.q(X104_Y99_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X104_Y99_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X206_Y99@{W[1][16],W[1][15]}@5 */

	logic [DATA_WIDTH-1:0] X206_Y99_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X206_Y99_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_1_west_to_east_ip_size_15_bus_first_egress_fifo(.clock(bus_clock),
		.in(X206_Y99_bus_rdata_in),
		.out(X206_Y99_bus_rdata_out));

	assign east_out_reg[1][16][10:0] = X206_Y99_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][15][10:2] = X206_Y99_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X206_Y99(.data(/* from design */),
		.q(X206_Y99_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X206_Y99_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X67_Y98@{S[0][0],S[0][1]}@3 */

	logic [DATA_WIDTH-1:0] X67_Y98_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X67_Y98_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_1_bus_first_egress_fifo(.clock(bus_clock),
		.in(X67_Y98_bus_rdata_in),
		.out(X67_Y98_bus_rdata_out));

	assign north_out_reg[0][0][10:0] = X67_Y98_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][1][10:2] = X67_Y98_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X67_Y98(.data(/* from design */),
		.q(X67_Y98_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X67_Y98_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X68_Y98@{N[0][1],N[0][2]}@3 */

	logic X68_Y98_incr_waddr; // ingress control
	logic X68_Y98_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_2_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][2][0]),
		.out(X68_Y98_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_2_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][2][1]),
		.out(X68_Y98_incr_raddr));

	logic [ADDR_WIDTH-1:0] X68_Y98_waddr;
	logic [ADDR_WIDTH-1:0] X68_Y98_raddr;

	/* positional aliases */

	wire X69_Y98_incr_waddr;
	assign X69_Y98_incr_waddr = X68_Y98_incr_waddr;
	wire [ADDR_WIDTH-1:0] X69_Y98_waddr;
	assign X69_Y98_waddr = X68_Y98_waddr;
	wire X69_Y97_incr_raddr;
	assign X69_Y97_incr_raddr = X68_Y98_incr_raddr;
	wire [ADDR_WIDTH-1:0] X69_Y97_raddr;
	assign X69_Y97_raddr = X68_Y98_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X68_Y98(.clk(bus_clock),
		.incr_waddr(X68_Y98_incr_waddr),
		.waddr(X68_Y98_waddr),
		.incr_raddr(X68_Y98_incr_raddr),
		.raddr(X68_Y98_raddr));


	/* generated from I@X69_Y98@{N[0][2],N[0][3]}@3 */

	logic [DATA_WIDTH-1:0] X69_Y98_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_3_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][2][10:0], north_in_reg[0][3][10:2]}),
		.out(X69_Y98_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X69_Y98(.data(X69_Y98_bus_wdata),
		.q(/* to design */),
		.wraddress(X69_Y98_waddr),
		.rdaddress(/* from design */),
		.wren(X69_Y98_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X78_Y98@{S[0][8],S[0][9]}@3 */

	logic [DATA_WIDTH-1:0] X78_Y98_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X78_Y98_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_9_bus_first_egress_fifo(.clock(bus_clock),
		.in(X78_Y98_bus_rdata_in),
		.out(X78_Y98_bus_rdata_out));

	assign north_out_reg[0][8][10:0] = X78_Y98_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][9][10:2] = X78_Y98_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X78_Y98(.data(/* from design */),
		.q(X78_Y98_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X78_Y98_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X79_Y98@{N[0][9],N[0][10]}@3 */

	logic X79_Y98_incr_waddr; // ingress control
	logic X79_Y98_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_10_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][10][0]),
		.out(X79_Y98_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_10_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][10][1]),
		.out(X79_Y98_incr_raddr));

	logic [ADDR_WIDTH-1:0] X79_Y98_waddr;
	logic [ADDR_WIDTH-1:0] X79_Y98_raddr;

	/* positional aliases */

	wire X80_Y98_incr_waddr;
	assign X80_Y98_incr_waddr = X79_Y98_incr_waddr;
	wire [ADDR_WIDTH-1:0] X80_Y98_waddr;
	assign X80_Y98_waddr = X79_Y98_waddr;
	wire X80_Y97_incr_raddr;
	assign X80_Y97_incr_raddr = X79_Y98_incr_raddr;
	wire [ADDR_WIDTH-1:0] X80_Y97_raddr;
	assign X80_Y97_raddr = X79_Y98_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X79_Y98(.clk(bus_clock),
		.incr_waddr(X79_Y98_incr_waddr),
		.waddr(X79_Y98_waddr),
		.incr_raddr(X79_Y98_incr_raddr),
		.raddr(X79_Y98_raddr));


	/* generated from I@X80_Y98@{N[0][10],N[0][11]}@3 */

	logic [DATA_WIDTH-1:0] X80_Y98_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_11_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][10][10:0], north_in_reg[0][11][10:2]}),
		.out(X80_Y98_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X80_Y98(.data(X80_Y98_bus_wdata),
		.q(/* to design */),
		.wraddress(X80_Y98_waddr),
		.rdaddress(/* from design */),
		.wren(X80_Y98_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X88_Y98@{S[0][16],S[0][17]}@3 */

	logic [DATA_WIDTH-1:0] X88_Y98_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X88_Y98_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_17_bus_first_egress_fifo(.clock(bus_clock),
		.in(X88_Y98_bus_rdata_in),
		.out(X88_Y98_bus_rdata_out));

	assign north_out_reg[0][16][10:0] = X88_Y98_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][17][10:2] = X88_Y98_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X88_Y98(.data(/* from design */),
		.q(X88_Y98_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X88_Y98_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X89_Y98@{N[0][17],N[0][18]}@3 */

	logic X89_Y98_incr_waddr; // ingress control
	logic X89_Y98_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_18_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][18][0]),
		.out(X89_Y98_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_18_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][18][1]),
		.out(X89_Y98_incr_raddr));

	logic [ADDR_WIDTH-1:0] X89_Y98_waddr;
	logic [ADDR_WIDTH-1:0] X89_Y98_raddr;

	/* positional aliases */

	wire X90_Y98_incr_waddr;
	assign X90_Y98_incr_waddr = X89_Y98_incr_waddr;
	wire [ADDR_WIDTH-1:0] X90_Y98_waddr;
	assign X90_Y98_waddr = X89_Y98_waddr;
	wire X90_Y97_incr_raddr;
	assign X90_Y97_incr_raddr = X89_Y98_incr_raddr;
	wire [ADDR_WIDTH-1:0] X90_Y97_raddr;
	assign X90_Y97_raddr = X89_Y98_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X89_Y98(.clk(bus_clock),
		.incr_waddr(X89_Y98_incr_waddr),
		.waddr(X89_Y98_waddr),
		.incr_raddr(X89_Y98_incr_raddr),
		.raddr(X89_Y98_raddr));


	/* generated from I@X90_Y98@{N[0][18],N[0][19]}@3 */

	logic [DATA_WIDTH-1:0] X90_Y98_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_19_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][18][10:0], north_in_reg[0][19][10:2]}),
		.out(X90_Y98_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X90_Y98(.data(X90_Y98_bus_wdata),
		.q(/* to design */),
		.wraddress(X90_Y98_waddr),
		.rdaddress(/* from design */),
		.wren(X90_Y98_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X103_Y98@{W[1][14],W[1][13]}@1 */

	logic X103_Y98_incr_waddr; // ingress control
	logic X103_Y98_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_1_west_to_east_ip_size_13_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][13][0]),
		.out(X103_Y98_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_1_west_to_east_ip_size_13_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][13][1]),
		.out(X103_Y98_incr_raddr));

	logic [ADDR_WIDTH-1:0] X103_Y98_waddr;
	logic [ADDR_WIDTH-1:0] X103_Y98_raddr;

	/* positional aliases */

	wire X104_Y98_incr_waddr;
	assign X104_Y98_incr_waddr = X103_Y98_incr_waddr;
	wire [ADDR_WIDTH-1:0] X104_Y98_waddr;
	assign X104_Y98_waddr = X103_Y98_waddr;
	wire X104_Y97_incr_raddr;
	assign X104_Y97_incr_raddr = X103_Y98_incr_raddr;
	wire [ADDR_WIDTH-1:0] X104_Y97_raddr;
	assign X104_Y97_raddr = X103_Y98_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X103_Y98(.clk(bus_clock),
		.incr_waddr(X103_Y98_incr_waddr),
		.waddr(X103_Y98_waddr),
		.incr_raddr(X103_Y98_incr_raddr),
		.raddr(X103_Y98_raddr));


	/* generated from I@X104_Y98@{W[1][14],W[1][13]}@1 */

	logic [DATA_WIDTH-1:0] X104_Y98_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_1_west_to_east_ip_size_13_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][14][10:0], west_in_reg[1][13][10:2]}),
		.out(X104_Y98_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X104_Y98(.data(X104_Y98_bus_wdata),
		.q(/* to design */),
		.wraddress(X104_Y98_waddr),
		.rdaddress(/* from design */),
		.wren(X104_Y98_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X172_Y98@{S[2][1],S[2][0]}@3 */

	logic [DATA_WIDTH-1:0] X172_Y98_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X172_Y98_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_0_bus_first_egress_fifo(.clock(bus_clock),
		.in(X172_Y98_bus_rdata_in),
		.out(X172_Y98_bus_rdata_out));

	assign north_out_reg[2][1][10:0] = X172_Y98_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][0][10:2] = X172_Y98_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X172_Y98(.data(/* from design */),
		.q(X172_Y98_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X172_Y98_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X174_Y98@{N[2][3],N[2][2]}@3 */

	logic [DATA_WIDTH-1:0] X174_Y98_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_2_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][3][10:0], north_in_reg[2][2][10:2]}),
		.out(X174_Y98_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X174_Y98(.data(X174_Y98_bus_wdata),
		.q(/* to design */),
		.wraddress(X174_Y98_waddr),
		.rdaddress(/* from design */),
		.wren(X174_Y98_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X175_Y98@{N[2][4],N[2][3]}@3 */

	logic X175_Y98_incr_waddr; // ingress control
	logic X175_Y98_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_3_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[2][4][0]),
		.out(X175_Y98_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_3_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[2][4][1]),
		.out(X175_Y98_incr_raddr));

	logic [ADDR_WIDTH-1:0] X175_Y98_waddr;
	logic [ADDR_WIDTH-1:0] X175_Y98_raddr;

	/* positional aliases */

	wire X174_Y98_incr_waddr;
	assign X174_Y98_incr_waddr = X175_Y98_incr_waddr;
	wire [ADDR_WIDTH-1:0] X174_Y98_waddr;
	assign X174_Y98_waddr = X175_Y98_waddr;
	wire X174_Y97_incr_raddr;
	assign X174_Y97_incr_raddr = X175_Y98_incr_raddr;
	wire [ADDR_WIDTH-1:0] X174_Y97_raddr;
	assign X174_Y97_raddr = X175_Y98_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X175_Y98(.clk(bus_clock),
		.incr_waddr(X175_Y98_incr_waddr),
		.waddr(X175_Y98_waddr),
		.incr_raddr(X175_Y98_incr_raddr),
		.raddr(X175_Y98_raddr));


	/* generated from E@X183_Y98@{S[2][9],S[2][8]}@3 */

	logic [DATA_WIDTH-1:0] X183_Y98_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X183_Y98_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_8_bus_first_egress_fifo(.clock(bus_clock),
		.in(X183_Y98_bus_rdata_in),
		.out(X183_Y98_bus_rdata_out));

	assign north_out_reg[2][9][10:0] = X183_Y98_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][8][10:2] = X183_Y98_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X183_Y98(.data(/* from design */),
		.q(X183_Y98_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X183_Y98_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X185_Y98@{N[2][11],N[2][10]}@3 */

	logic [DATA_WIDTH-1:0] X185_Y98_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_10_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][11][10:0], north_in_reg[2][10][10:2]}),
		.out(X185_Y98_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X185_Y98(.data(X185_Y98_bus_wdata),
		.q(/* to design */),
		.wraddress(X185_Y98_waddr),
		.rdaddress(/* from design */),
		.wren(X185_Y98_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X186_Y98@{N[2][12],N[2][11]}@3 */

	logic X186_Y98_incr_waddr; // ingress control
	logic X186_Y98_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_11_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[2][12][0]),
		.out(X186_Y98_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_11_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[2][12][1]),
		.out(X186_Y98_incr_raddr));

	logic [ADDR_WIDTH-1:0] X186_Y98_waddr;
	logic [ADDR_WIDTH-1:0] X186_Y98_raddr;

	/* positional aliases */

	wire X185_Y98_incr_waddr;
	assign X185_Y98_incr_waddr = X186_Y98_incr_waddr;
	wire [ADDR_WIDTH-1:0] X185_Y98_waddr;
	assign X185_Y98_waddr = X186_Y98_waddr;
	wire X185_Y97_incr_raddr;
	assign X185_Y97_incr_raddr = X186_Y98_incr_raddr;
	wire [ADDR_WIDTH-1:0] X185_Y97_raddr;
	assign X185_Y97_raddr = X186_Y98_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X186_Y98(.clk(bus_clock),
		.incr_waddr(X186_Y98_incr_waddr),
		.waddr(X186_Y98_waddr),
		.incr_raddr(X186_Y98_incr_raddr),
		.raddr(X186_Y98_raddr));


	/* generated from E@X194_Y98@{S[2][17],S[2][16]}@3 */

	logic [DATA_WIDTH-1:0] X194_Y98_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X194_Y98_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_16_bus_first_egress_fifo(.clock(bus_clock),
		.in(X194_Y98_bus_rdata_in),
		.out(X194_Y98_bus_rdata_out));

	assign north_out_reg[2][17][10:0] = X194_Y98_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][16][10:2] = X194_Y98_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X194_Y98(.data(/* from design */),
		.q(X194_Y98_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X194_Y98_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X196_Y98@{N[2][19],N[2][18]}@3 */

	logic [DATA_WIDTH-1:0] X196_Y98_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_18_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][19][10:0], north_in_reg[2][18][10:2]}),
		.out(X196_Y98_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X196_Y98(.data(X196_Y98_bus_wdata),
		.q(/* to design */),
		.wraddress(X196_Y98_waddr),
		.rdaddress(/* from design */),
		.wren(X196_Y98_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X197_Y98@{N[2][20],N[2][19]}@3 */

	logic X197_Y98_incr_waddr; // ingress control
	logic X197_Y98_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_19_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[2][20][0]),
		.out(X197_Y98_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_19_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[2][20][1]),
		.out(X197_Y98_incr_raddr));

	logic [ADDR_WIDTH-1:0] X197_Y98_waddr;
	logic [ADDR_WIDTH-1:0] X197_Y98_raddr;

	/* positional aliases */

	wire X196_Y98_incr_waddr;
	assign X196_Y98_incr_waddr = X197_Y98_incr_waddr;
	wire [ADDR_WIDTH-1:0] X196_Y98_waddr;
	assign X196_Y98_waddr = X197_Y98_waddr;
	wire X196_Y97_incr_raddr;
	assign X196_Y97_incr_raddr = X197_Y98_incr_raddr;
	wire [ADDR_WIDTH-1:0] X196_Y97_raddr;
	assign X196_Y97_raddr = X197_Y98_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X197_Y98(.clk(bus_clock),
		.incr_waddr(X197_Y98_incr_waddr),
		.waddr(X197_Y98_waddr),
		.incr_raddr(X197_Y98_incr_raddr),
		.raddr(X197_Y98_raddr));


	/* generated from I@X206_Y98@{E[1][14],E[1][13]}@1 */

	logic [DATA_WIDTH-1:0] X206_Y98_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_1_east_to_west_ip_size_13_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][14][10:0], east_in_reg[1][13][10:2]}),
		.out(X206_Y98_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X206_Y98(.data(X206_Y98_bus_wdata),
		.q(/* to design */),
		.wraddress(X206_Y98_waddr),
		.rdaddress(/* from design */),
		.wren(X206_Y98_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X207_Y98@{E[1][14],E[1][13]}@1 */

	logic X207_Y98_incr_waddr; // ingress control
	logic X207_Y98_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_1_east_to_west_ip_size_13_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][14][0]),
		.out(X207_Y98_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_1_east_to_west_ip_size_13_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][14][1]),
		.out(X207_Y98_incr_raddr));

	logic [ADDR_WIDTH-1:0] X207_Y98_waddr;
	logic [ADDR_WIDTH-1:0] X207_Y98_raddr;

	/* positional aliases */

	wire X206_Y98_incr_waddr;
	assign X206_Y98_incr_waddr = X207_Y98_incr_waddr;
	wire [ADDR_WIDTH-1:0] X206_Y98_waddr;
	assign X206_Y98_waddr = X207_Y98_waddr;
	wire X206_Y97_incr_raddr;
	assign X206_Y97_incr_raddr = X207_Y98_incr_raddr;
	wire [ADDR_WIDTH-1:0] X206_Y97_raddr;
	assign X206_Y97_raddr = X207_Y98_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X207_Y98(.clk(bus_clock),
		.incr_waddr(X207_Y98_incr_waddr),
		.waddr(X207_Y98_waddr),
		.incr_raddr(X207_Y98_incr_raddr),
		.raddr(X207_Y98_raddr));


	/* generated from E@X215_Y98@{S[2][33],S[2][32]}@3 */

	logic [DATA_WIDTH-1:0] X215_Y98_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X215_Y98_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_32_bus_first_egress_fifo(.clock(bus_clock),
		.in(X215_Y98_bus_rdata_in),
		.out(X215_Y98_bus_rdata_out));

	assign north_out_reg[2][33][10:0] = X215_Y98_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][32][10:2] = X215_Y98_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X215_Y98(.data(/* from design */),
		.q(X215_Y98_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X215_Y98_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X217_Y98@{N[2][35],N[2][34]}@3 */

	logic [DATA_WIDTH-1:0] X217_Y98_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_34_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][35][10:0], north_in_reg[2][34][10:2]}),
		.out(X217_Y98_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X217_Y98(.data(X217_Y98_bus_wdata),
		.q(/* to design */),
		.wraddress(X217_Y98_waddr),
		.rdaddress(/* from design */),
		.wren(X217_Y98_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X218_Y98@{N[2][36],N[2][35]}@3 */

	logic X218_Y98_incr_waddr; // ingress control
	logic X218_Y98_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_35_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[2][36][0]),
		.out(X218_Y98_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_35_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[2][36][1]),
		.out(X218_Y98_incr_raddr));

	logic [ADDR_WIDTH-1:0] X218_Y98_waddr;
	logic [ADDR_WIDTH-1:0] X218_Y98_raddr;

	/* positional aliases */

	wire X217_Y98_incr_waddr;
	assign X217_Y98_incr_waddr = X218_Y98_incr_waddr;
	wire [ADDR_WIDTH-1:0] X217_Y98_waddr;
	assign X217_Y98_waddr = X218_Y98_waddr;
	wire X217_Y97_incr_raddr;
	assign X217_Y97_incr_raddr = X218_Y98_incr_raddr;
	wire [ADDR_WIDTH-1:0] X217_Y97_raddr;
	assign X217_Y97_raddr = X218_Y98_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X218_Y98(.clk(bus_clock),
		.incr_waddr(X218_Y98_incr_waddr),
		.waddr(X218_Y98_waddr),
		.incr_raddr(X218_Y98_incr_raddr),
		.raddr(X218_Y98_raddr));


	/* generated from C@X66_Y97@{,S[0][0]}@2 */

	logic X66_Y97_incr_waddr; // ingress control
	logic X66_Y97_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_0_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][0][0]),
		.out(X66_Y97_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_0_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][0][1]),
		.out(X66_Y97_incr_raddr));

	logic [ADDR_WIDTH-1:0] X66_Y97_waddr;
	logic [ADDR_WIDTH-1:0] X66_Y97_raddr;

	/* positional aliases */

	wire X67_Y97_incr_waddr;
	assign X67_Y97_incr_waddr = X66_Y97_incr_waddr;
	wire [ADDR_WIDTH-1:0] X67_Y97_waddr;
	assign X67_Y97_waddr = X66_Y97_waddr;
	wire X67_Y98_incr_raddr;
	assign X67_Y98_incr_raddr = X66_Y97_incr_raddr;
	wire [ADDR_WIDTH-1:0] X67_Y98_raddr;
	assign X67_Y98_raddr = X66_Y97_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X66_Y97(.clk(bus_clock),
		.incr_waddr(X66_Y97_incr_waddr),
		.waddr(X66_Y97_waddr),
		.incr_raddr(X66_Y97_incr_raddr),
		.raddr(X66_Y97_raddr));


	/* generated from I@X67_Y97@{S[0][0],S[0][1]}@2 */

	logic [DATA_WIDTH-1:0] X67_Y97_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_1_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][0][10:0], south_in_reg[0][1][10:2]}),
		.out(X67_Y97_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X67_Y97(.data(X67_Y97_bus_wdata),
		.q(/* to design */),
		.wraddress(X67_Y97_waddr),
		.rdaddress(/* from design */),
		.wren(X67_Y97_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X69_Y97@{N[0][2],N[0][3]}@4 */

	logic [DATA_WIDTH-1:0] X69_Y97_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X69_Y97_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_3_bus_first_egress_fifo(.clock(bus_clock),
		.in(X69_Y97_bus_rdata_in),
		.out(X69_Y97_bus_rdata_out));

	assign south_out_reg[0][2][10:0] = X69_Y97_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][3][10:2] = X69_Y97_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X69_Y97(.data(/* from design */),
		.q(X69_Y97_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X69_Y97_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X77_Y97@{S[0][7],S[0][8]}@2 */

	logic X77_Y97_incr_waddr; // ingress control
	logic X77_Y97_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_8_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][8][0]),
		.out(X77_Y97_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_8_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][8][1]),
		.out(X77_Y97_incr_raddr));

	logic [ADDR_WIDTH-1:0] X77_Y97_waddr;
	logic [ADDR_WIDTH-1:0] X77_Y97_raddr;

	/* positional aliases */

	wire X78_Y97_incr_waddr;
	assign X78_Y97_incr_waddr = X77_Y97_incr_waddr;
	wire [ADDR_WIDTH-1:0] X78_Y97_waddr;
	assign X78_Y97_waddr = X77_Y97_waddr;
	wire X78_Y98_incr_raddr;
	assign X78_Y98_incr_raddr = X77_Y97_incr_raddr;
	wire [ADDR_WIDTH-1:0] X78_Y98_raddr;
	assign X78_Y98_raddr = X77_Y97_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X77_Y97(.clk(bus_clock),
		.incr_waddr(X77_Y97_incr_waddr),
		.waddr(X77_Y97_waddr),
		.incr_raddr(X77_Y97_incr_raddr),
		.raddr(X77_Y97_raddr));


	/* generated from I@X78_Y97@{S[0][8],S[0][9]}@2 */

	logic [DATA_WIDTH-1:0] X78_Y97_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_9_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][8][10:0], south_in_reg[0][9][10:2]}),
		.out(X78_Y97_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X78_Y97(.data(X78_Y97_bus_wdata),
		.q(/* to design */),
		.wraddress(X78_Y97_waddr),
		.rdaddress(/* from design */),
		.wren(X78_Y97_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X80_Y97@{N[0][10],N[0][11]}@4 */

	logic [DATA_WIDTH-1:0] X80_Y97_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X80_Y97_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_11_bus_first_egress_fifo(.clock(bus_clock),
		.in(X80_Y97_bus_rdata_in),
		.out(X80_Y97_bus_rdata_out));

	assign south_out_reg[0][10][10:0] = X80_Y97_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][11][10:2] = X80_Y97_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X80_Y97(.data(/* from design */),
		.q(X80_Y97_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X80_Y97_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X87_Y97@{S[0][15],S[0][16]}@2 */

	logic X87_Y97_incr_waddr; // ingress control
	logic X87_Y97_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_16_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][16][0]),
		.out(X87_Y97_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_16_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][16][1]),
		.out(X87_Y97_incr_raddr));

	logic [ADDR_WIDTH-1:0] X87_Y97_waddr;
	logic [ADDR_WIDTH-1:0] X87_Y97_raddr;

	/* positional aliases */

	wire X88_Y97_incr_waddr;
	assign X88_Y97_incr_waddr = X87_Y97_incr_waddr;
	wire [ADDR_WIDTH-1:0] X88_Y97_waddr;
	assign X88_Y97_waddr = X87_Y97_waddr;
	wire X88_Y98_incr_raddr;
	assign X88_Y98_incr_raddr = X87_Y97_incr_raddr;
	wire [ADDR_WIDTH-1:0] X88_Y98_raddr;
	assign X88_Y98_raddr = X87_Y97_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X87_Y97(.clk(bus_clock),
		.incr_waddr(X87_Y97_incr_waddr),
		.waddr(X87_Y97_waddr),
		.incr_raddr(X87_Y97_incr_raddr),
		.raddr(X87_Y97_raddr));


	/* generated from I@X88_Y97@{S[0][16],S[0][17]}@2 */

	logic [DATA_WIDTH-1:0] X88_Y97_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_17_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][16][10:0], south_in_reg[0][17][10:2]}),
		.out(X88_Y97_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X88_Y97(.data(X88_Y97_bus_wdata),
		.q(/* to design */),
		.wraddress(X88_Y97_waddr),
		.rdaddress(/* from design */),
		.wren(X88_Y97_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X90_Y97@{N[0][18],N[0][19]}@4 */

	logic [DATA_WIDTH-1:0] X90_Y97_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X90_Y97_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_19_bus_first_egress_fifo(.clock(bus_clock),
		.in(X90_Y97_bus_rdata_in),
		.out(X90_Y97_bus_rdata_out));

	assign south_out_reg[0][18][10:0] = X90_Y97_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][19][10:2] = X90_Y97_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X90_Y97(.data(/* from design */),
		.q(X90_Y97_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X90_Y97_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X104_Y97@{W[1][14],W[1][13]}@2 */

	logic [DATA_WIDTH-1:0] X104_Y97_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X104_Y97_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_1_west_to_east_ip_size_13_bus_first_egress_fifo(.clock(bus_clock),
		.in(X104_Y97_bus_rdata_in),
		.out(X104_Y97_bus_rdata_out));

	assign east_out_reg[1][14][10:0] = X104_Y97_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][13][10:2] = X104_Y97_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X104_Y97(.data(/* from design */),
		.q(X104_Y97_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X104_Y97_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X172_Y97@{S[2][1],S[2][0]}@2 */

	logic [DATA_WIDTH-1:0] X172_Y97_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_0_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][1][10:0], south_in_reg[2][0][10:2]}),
		.out(X172_Y97_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X172_Y97(.data(X172_Y97_bus_wdata),
		.q(/* to design */),
		.wraddress(X172_Y97_waddr),
		.rdaddress(/* from design */),
		.wren(X172_Y97_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X173_Y97@{S[2][2],S[2][1]}@2 */

	logic X173_Y97_incr_waddr; // ingress control
	logic X173_Y97_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_1_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[2][2][0]),
		.out(X173_Y97_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_1_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[2][2][1]),
		.out(X173_Y97_incr_raddr));

	logic [ADDR_WIDTH-1:0] X173_Y97_waddr;
	logic [ADDR_WIDTH-1:0] X173_Y97_raddr;

	/* positional aliases */

	wire X172_Y97_incr_waddr;
	assign X172_Y97_incr_waddr = X173_Y97_incr_waddr;
	wire [ADDR_WIDTH-1:0] X172_Y97_waddr;
	assign X172_Y97_waddr = X173_Y97_waddr;
	wire X172_Y98_incr_raddr;
	assign X172_Y98_incr_raddr = X173_Y97_incr_raddr;
	wire [ADDR_WIDTH-1:0] X172_Y98_raddr;
	assign X172_Y98_raddr = X173_Y97_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X173_Y97(.clk(bus_clock),
		.incr_waddr(X173_Y97_incr_waddr),
		.waddr(X173_Y97_waddr),
		.incr_raddr(X173_Y97_incr_raddr),
		.raddr(X173_Y97_raddr));


	/* generated from E@X174_Y97@{N[2][3],N[2][2]}@4 */

	logic [DATA_WIDTH-1:0] X174_Y97_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X174_Y97_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_2_bus_first_egress_fifo(.clock(bus_clock),
		.in(X174_Y97_bus_rdata_in),
		.out(X174_Y97_bus_rdata_out));

	assign south_out_reg[2][3][10:0] = X174_Y97_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][2][10:2] = X174_Y97_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X174_Y97(.data(/* from design */),
		.q(X174_Y97_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X174_Y97_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X183_Y97@{S[2][9],S[2][8]}@2 */

	logic [DATA_WIDTH-1:0] X183_Y97_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_8_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][9][10:0], south_in_reg[2][8][10:2]}),
		.out(X183_Y97_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X183_Y97(.data(X183_Y97_bus_wdata),
		.q(/* to design */),
		.wraddress(X183_Y97_waddr),
		.rdaddress(/* from design */),
		.wren(X183_Y97_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X184_Y97@{S[2][10],S[2][9]}@2 */

	logic X184_Y97_incr_waddr; // ingress control
	logic X184_Y97_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_9_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[2][10][0]),
		.out(X184_Y97_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_9_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[2][10][1]),
		.out(X184_Y97_incr_raddr));

	logic [ADDR_WIDTH-1:0] X184_Y97_waddr;
	logic [ADDR_WIDTH-1:0] X184_Y97_raddr;

	/* positional aliases */

	wire X183_Y97_incr_waddr;
	assign X183_Y97_incr_waddr = X184_Y97_incr_waddr;
	wire [ADDR_WIDTH-1:0] X183_Y97_waddr;
	assign X183_Y97_waddr = X184_Y97_waddr;
	wire X183_Y98_incr_raddr;
	assign X183_Y98_incr_raddr = X184_Y97_incr_raddr;
	wire [ADDR_WIDTH-1:0] X183_Y98_raddr;
	assign X183_Y98_raddr = X184_Y97_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X184_Y97(.clk(bus_clock),
		.incr_waddr(X184_Y97_incr_waddr),
		.waddr(X184_Y97_waddr),
		.incr_raddr(X184_Y97_incr_raddr),
		.raddr(X184_Y97_raddr));


	/* generated from E@X185_Y97@{N[2][11],N[2][10]}@4 */

	logic [DATA_WIDTH-1:0] X185_Y97_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X185_Y97_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_10_bus_first_egress_fifo(.clock(bus_clock),
		.in(X185_Y97_bus_rdata_in),
		.out(X185_Y97_bus_rdata_out));

	assign south_out_reg[2][11][10:0] = X185_Y97_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][10][10:2] = X185_Y97_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X185_Y97(.data(/* from design */),
		.q(X185_Y97_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X185_Y97_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X194_Y97@{S[2][17],S[2][16]}@2 */

	logic [DATA_WIDTH-1:0] X194_Y97_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_16_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][17][10:0], south_in_reg[2][16][10:2]}),
		.out(X194_Y97_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X194_Y97(.data(X194_Y97_bus_wdata),
		.q(/* to design */),
		.wraddress(X194_Y97_waddr),
		.rdaddress(/* from design */),
		.wren(X194_Y97_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X195_Y97@{S[2][18],S[2][17]}@2 */

	logic X195_Y97_incr_waddr; // ingress control
	logic X195_Y97_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_17_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[2][18][0]),
		.out(X195_Y97_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_17_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[2][18][1]),
		.out(X195_Y97_incr_raddr));

	logic [ADDR_WIDTH-1:0] X195_Y97_waddr;
	logic [ADDR_WIDTH-1:0] X195_Y97_raddr;

	/* positional aliases */

	wire X194_Y97_incr_waddr;
	assign X194_Y97_incr_waddr = X195_Y97_incr_waddr;
	wire [ADDR_WIDTH-1:0] X194_Y97_waddr;
	assign X194_Y97_waddr = X195_Y97_waddr;
	wire X194_Y98_incr_raddr;
	assign X194_Y98_incr_raddr = X195_Y97_incr_raddr;
	wire [ADDR_WIDTH-1:0] X194_Y98_raddr;
	assign X194_Y98_raddr = X195_Y97_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X195_Y97(.clk(bus_clock),
		.incr_waddr(X195_Y97_incr_waddr),
		.waddr(X195_Y97_waddr),
		.incr_raddr(X195_Y97_incr_raddr),
		.raddr(X195_Y97_raddr));


	/* generated from E@X196_Y97@{N[2][19],N[2][18]}@4 */

	logic [DATA_WIDTH-1:0] X196_Y97_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X196_Y97_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_18_bus_first_egress_fifo(.clock(bus_clock),
		.in(X196_Y97_bus_rdata_in),
		.out(X196_Y97_bus_rdata_out));

	assign south_out_reg[2][19][10:0] = X196_Y97_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][18][10:2] = X196_Y97_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X196_Y97(.data(/* from design */),
		.q(X196_Y97_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X196_Y97_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X206_Y97@{E[1][14],E[1][13]}@2 */

	logic [DATA_WIDTH-1:0] X206_Y97_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X206_Y97_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_1_east_to_west_ip_size_13_bus_first_egress_fifo(.clock(bus_clock),
		.in(X206_Y97_bus_rdata_in),
		.out(X206_Y97_bus_rdata_out));

	assign west_out_reg[1][14][10:0] = X206_Y97_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][13][10:2] = X206_Y97_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X206_Y97(.data(/* from design */),
		.q(X206_Y97_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X206_Y97_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X215_Y97@{S[2][33],S[2][32]}@2 */

	logic [DATA_WIDTH-1:0] X215_Y97_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_32_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][33][10:0], south_in_reg[2][32][10:2]}),
		.out(X215_Y97_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X215_Y97(.data(X215_Y97_bus_wdata),
		.q(/* to design */),
		.wraddress(X215_Y97_waddr),
		.rdaddress(/* from design */),
		.wren(X215_Y97_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X216_Y97@{S[2][34],S[2][33]}@2 */

	logic X216_Y97_incr_waddr; // ingress control
	logic X216_Y97_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_33_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[2][34][0]),
		.out(X216_Y97_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_33_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[2][34][1]),
		.out(X216_Y97_incr_raddr));

	logic [ADDR_WIDTH-1:0] X216_Y97_waddr;
	logic [ADDR_WIDTH-1:0] X216_Y97_raddr;

	/* positional aliases */

	wire X215_Y97_incr_waddr;
	assign X215_Y97_incr_waddr = X216_Y97_incr_waddr;
	wire [ADDR_WIDTH-1:0] X215_Y97_waddr;
	assign X215_Y97_waddr = X216_Y97_waddr;
	wire X215_Y98_incr_raddr;
	assign X215_Y98_incr_raddr = X216_Y97_incr_raddr;
	wire [ADDR_WIDTH-1:0] X215_Y98_raddr;
	assign X215_Y98_raddr = X216_Y97_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X216_Y97(.clk(bus_clock),
		.incr_waddr(X216_Y97_incr_waddr),
		.waddr(X216_Y97_waddr),
		.incr_raddr(X216_Y97_incr_raddr),
		.raddr(X216_Y97_raddr));


	/* generated from E@X217_Y97@{N[2][35],N[2][34]}@4 */

	logic [DATA_WIDTH-1:0] X217_Y97_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X217_Y97_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_34_bus_first_egress_fifo(.clock(bus_clock),
		.in(X217_Y97_bus_rdata_in),
		.out(X217_Y97_bus_rdata_out));

	assign south_out_reg[2][35][10:0] = X217_Y97_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][34][10:2] = X217_Y97_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X217_Y97(.data(/* from design */),
		.q(X217_Y97_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X217_Y97_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X153_Y96@{E[1][12],E[1][11]}@3 */

	logic [DATA_WIDTH-1:0] X153_Y96_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) east_to_west_sector_size_1_east_to_west_ip_size_11_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][12][10:0], east_in_reg[1][11][10:2]}),
		.out(X153_Y96_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X153_Y96(.data(X153_Y96_bus_wdata),
		.q(/* to design */),
		.wraddress(X153_Y96_waddr),
		.rdaddress(/* from design */),
		.wren(X153_Y96_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X154_Y96@{E[1][12],E[1][11]}@3 */

	logic X154_Y96_incr_waddr; // ingress control
	logic X154_Y96_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) east_to_west_sector_size_1_east_to_west_ip_size_11_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][11][0]),
		.out(X154_Y96_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) east_to_west_sector_size_1_east_to_west_ip_size_11_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][11][1]),
		.out(X154_Y96_incr_raddr));

	logic [ADDR_WIDTH-1:0] X154_Y96_waddr;
	logic [ADDR_WIDTH-1:0] X154_Y96_raddr;

	/* positional aliases */

	wire X153_Y96_incr_waddr;
	assign X153_Y96_incr_waddr = X154_Y96_incr_waddr;
	wire [ADDR_WIDTH-1:0] X153_Y96_waddr;
	assign X153_Y96_waddr = X154_Y96_waddr;
	wire X153_Y95_incr_raddr;
	assign X153_Y95_incr_raddr = X154_Y96_incr_raddr;
	wire [ADDR_WIDTH-1:0] X153_Y95_raddr;
	assign X153_Y95_raddr = X154_Y96_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X154_Y96(.clk(bus_clock),
		.incr_waddr(X154_Y96_incr_waddr),
		.waddr(X154_Y96_waddr),
		.incr_raddr(X154_Y96_incr_raddr),
		.raddr(X154_Y96_raddr));


	/* generated from C@X238_Y96@{W[1][12],W[1][11]}@4 */

	logic X238_Y96_incr_waddr; // ingress control
	logic X238_Y96_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) west_to_east_sector_size_1_west_to_east_ip_size_11_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][12][0]),
		.out(X238_Y96_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) west_to_east_sector_size_1_west_to_east_ip_size_11_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][12][1]),
		.out(X238_Y96_incr_raddr));

	logic [ADDR_WIDTH-1:0] X238_Y96_waddr;
	logic [ADDR_WIDTH-1:0] X238_Y96_raddr;

	/* positional aliases */

	wire X239_Y96_incr_waddr;
	assign X239_Y96_incr_waddr = X238_Y96_incr_waddr;
	wire [ADDR_WIDTH-1:0] X239_Y96_waddr;
	assign X239_Y96_waddr = X238_Y96_waddr;
	wire X239_Y95_incr_raddr;
	assign X239_Y95_incr_raddr = X238_Y96_incr_raddr;
	wire [ADDR_WIDTH-1:0] X239_Y95_raddr;
	assign X239_Y95_raddr = X238_Y96_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X238_Y96(.clk(bus_clock),
		.incr_waddr(X238_Y96_incr_waddr),
		.waddr(X238_Y96_waddr),
		.incr_raddr(X238_Y96_incr_raddr),
		.raddr(X238_Y96_raddr));


	/* generated from I@X239_Y96@{W[1][12],W[1][11]}@4 */

	logic [DATA_WIDTH-1:0] X239_Y96_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_1_west_to_east_ip_size_11_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][12][10:0], west_in_reg[1][11][10:2]}),
		.out(X239_Y96_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X239_Y96(.data(X239_Y96_bus_wdata),
		.q(/* to design */),
		.wraddress(X239_Y96_waddr),
		.rdaddress(/* from design */),
		.wren(X239_Y96_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X153_Y95@{E[1][12],E[1][11]}@4 */

	logic [DATA_WIDTH-1:0] X153_Y95_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X153_Y95_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) east_to_west_sector_size_1_east_to_west_ip_size_11_bus_first_egress_fifo(.clock(bus_clock),
		.in(X153_Y95_bus_rdata_in),
		.out(X153_Y95_bus_rdata_out));

	assign west_out_reg[1][12][10:0] = X153_Y95_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][11][10:2] = X153_Y95_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X153_Y95(.data(/* from design */),
		.q(X153_Y95_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X153_Y95_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X239_Y95@{W[1][12],W[1][11]}@5 */

	logic [DATA_WIDTH-1:0] X239_Y95_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X239_Y95_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_1_west_to_east_ip_size_11_bus_first_egress_fifo(.clock(bus_clock),
		.in(X239_Y95_bus_rdata_in),
		.out(X239_Y95_bus_rdata_out));

	assign east_out_reg[1][12][10:0] = X239_Y95_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][11][10:2] = X239_Y95_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X239_Y95(.data(/* from design */),
		.q(X239_Y95_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X239_Y95_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X121_Y94@{S[1][0],S[1][1]}@3 */

	logic [DATA_WIDTH-1:0] X121_Y94_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X121_Y94_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_1_bus_first_egress_fifo(.clock(bus_clock),
		.in(X121_Y94_bus_rdata_in),
		.out(X121_Y94_bus_rdata_out));

	assign north_out_reg[1][0][10:0] = X121_Y94_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][1][10:2] = X121_Y94_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X121_Y94(.data(/* from design */),
		.q(X121_Y94_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X121_Y94_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X122_Y94@{N[1][1],N[1][2]}@3 */

	logic X122_Y94_incr_waddr; // ingress control
	logic X122_Y94_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_2_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][2][0]),
		.out(X122_Y94_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_2_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][2][1]),
		.out(X122_Y94_incr_raddr));

	logic [ADDR_WIDTH-1:0] X122_Y94_waddr;
	logic [ADDR_WIDTH-1:0] X122_Y94_raddr;

	/* positional aliases */

	wire X123_Y94_incr_waddr;
	assign X123_Y94_incr_waddr = X122_Y94_incr_waddr;
	wire [ADDR_WIDTH-1:0] X123_Y94_waddr;
	assign X123_Y94_waddr = X122_Y94_waddr;
	wire X123_Y93_incr_raddr;
	assign X123_Y93_incr_raddr = X122_Y94_incr_raddr;
	wire [ADDR_WIDTH-1:0] X123_Y93_raddr;
	assign X123_Y93_raddr = X122_Y94_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X122_Y94(.clk(bus_clock),
		.incr_waddr(X122_Y94_incr_waddr),
		.waddr(X122_Y94_waddr),
		.incr_raddr(X122_Y94_incr_raddr),
		.raddr(X122_Y94_raddr));


	/* generated from I@X123_Y94@{N[1][2],N[1][3]}@3 */

	logic [DATA_WIDTH-1:0] X123_Y94_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_3_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][2][10:0], north_in_reg[1][3][10:2]}),
		.out(X123_Y94_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X123_Y94(.data(X123_Y94_bus_wdata),
		.q(/* to design */),
		.wraddress(X123_Y94_waddr),
		.rdaddress(/* from design */),
		.wren(X123_Y94_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X132_Y94@{S[1][8],S[1][9]}@3 */

	logic [DATA_WIDTH-1:0] X132_Y94_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X132_Y94_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_9_bus_first_egress_fifo(.clock(bus_clock),
		.in(X132_Y94_bus_rdata_in),
		.out(X132_Y94_bus_rdata_out));

	assign north_out_reg[1][8][10:0] = X132_Y94_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][9][10:2] = X132_Y94_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X132_Y94(.data(/* from design */),
		.q(X132_Y94_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X132_Y94_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X133_Y94@{N[1][9],N[1][10]}@3 */

	logic X133_Y94_incr_waddr; // ingress control
	logic X133_Y94_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_10_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][10][0]),
		.out(X133_Y94_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_10_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][10][1]),
		.out(X133_Y94_incr_raddr));

	logic [ADDR_WIDTH-1:0] X133_Y94_waddr;
	logic [ADDR_WIDTH-1:0] X133_Y94_raddr;

	/* positional aliases */

	wire X134_Y94_incr_waddr;
	assign X134_Y94_incr_waddr = X133_Y94_incr_waddr;
	wire [ADDR_WIDTH-1:0] X134_Y94_waddr;
	assign X134_Y94_waddr = X133_Y94_waddr;
	wire X134_Y93_incr_raddr;
	assign X134_Y93_incr_raddr = X133_Y94_incr_raddr;
	wire [ADDR_WIDTH-1:0] X134_Y93_raddr;
	assign X134_Y93_raddr = X133_Y94_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X133_Y94(.clk(bus_clock),
		.incr_waddr(X133_Y94_incr_waddr),
		.waddr(X133_Y94_waddr),
		.incr_raddr(X133_Y94_incr_raddr),
		.raddr(X133_Y94_raddr));


	/* generated from I@X134_Y94@{N[1][10],N[1][11]}@3 */

	logic [DATA_WIDTH-1:0] X134_Y94_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_11_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][10][10:0], north_in_reg[1][11][10:2]}),
		.out(X134_Y94_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X134_Y94(.data(X134_Y94_bus_wdata),
		.q(/* to design */),
		.wraddress(X134_Y94_waddr),
		.rdaddress(/* from design */),
		.wren(X134_Y94_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X142_Y94@{S[1][16],S[1][17]}@3 */

	logic [DATA_WIDTH-1:0] X142_Y94_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X142_Y94_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_17_bus_first_egress_fifo(.clock(bus_clock),
		.in(X142_Y94_bus_rdata_in),
		.out(X142_Y94_bus_rdata_out));

	assign north_out_reg[1][16][10:0] = X142_Y94_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][17][10:2] = X142_Y94_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X142_Y94(.data(/* from design */),
		.q(X142_Y94_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X142_Y94_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X143_Y94@{N[1][17],N[1][18]}@3 */

	logic X143_Y94_incr_waddr; // ingress control
	logic X143_Y94_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_18_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][18][0]),
		.out(X143_Y94_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_18_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][18][1]),
		.out(X143_Y94_incr_raddr));

	logic [ADDR_WIDTH-1:0] X143_Y94_waddr;
	logic [ADDR_WIDTH-1:0] X143_Y94_raddr;

	/* positional aliases */

	wire X144_Y94_incr_waddr;
	assign X144_Y94_incr_waddr = X143_Y94_incr_waddr;
	wire [ADDR_WIDTH-1:0] X144_Y94_waddr;
	assign X144_Y94_waddr = X143_Y94_waddr;
	wire X144_Y93_incr_raddr;
	assign X144_Y93_incr_raddr = X143_Y94_incr_raddr;
	wire [ADDR_WIDTH-1:0] X144_Y93_raddr;
	assign X144_Y93_raddr = X143_Y94_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X143_Y94(.clk(bus_clock),
		.incr_waddr(X143_Y94_incr_waddr),
		.waddr(X143_Y94_waddr),
		.incr_raddr(X143_Y94_incr_raddr),
		.raddr(X143_Y94_raddr));


	/* generated from I@X144_Y94@{N[1][18],N[1][19]}@3 */

	logic [DATA_WIDTH-1:0] X144_Y94_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_19_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][18][10:0], north_in_reg[1][19][10:2]}),
		.out(X144_Y94_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X144_Y94(.data(X144_Y94_bus_wdata),
		.q(/* to design */),
		.wraddress(X144_Y94_waddr),
		.rdaddress(/* from design */),
		.wren(X144_Y94_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X152_Y94@{W[1][10],W[1][9]}@2 */

	logic X152_Y94_incr_waddr; // ingress control
	logic X152_Y94_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) west_to_east_sector_size_1_west_to_east_ip_size_9_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][9][0]),
		.out(X152_Y94_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) west_to_east_sector_size_1_west_to_east_ip_size_9_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][9][1]),
		.out(X152_Y94_incr_raddr));

	logic [ADDR_WIDTH-1:0] X152_Y94_waddr;
	logic [ADDR_WIDTH-1:0] X152_Y94_raddr;

	/* positional aliases */

	wire X153_Y94_incr_waddr;
	assign X153_Y94_incr_waddr = X152_Y94_incr_waddr;
	wire [ADDR_WIDTH-1:0] X153_Y94_waddr;
	assign X153_Y94_waddr = X152_Y94_waddr;
	wire X153_Y93_incr_raddr;
	assign X153_Y93_incr_raddr = X152_Y94_incr_raddr;
	wire [ADDR_WIDTH-1:0] X153_Y93_raddr;
	assign X153_Y93_raddr = X152_Y94_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X152_Y94(.clk(bus_clock),
		.incr_waddr(X152_Y94_incr_waddr),
		.waddr(X152_Y94_waddr),
		.incr_raddr(X152_Y94_incr_raddr),
		.raddr(X152_Y94_raddr));


	/* generated from I@X153_Y94@{W[1][10],W[1][9]}@2 */

	logic [DATA_WIDTH-1:0] X153_Y94_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) west_to_east_sector_size_1_west_to_east_ip_size_9_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][10][10:0], west_in_reg[1][9][10:2]}),
		.out(X153_Y94_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X153_Y94(.data(X153_Y94_bus_wdata),
		.q(/* to design */),
		.wraddress(X153_Y94_waddr),
		.rdaddress(/* from design */),
		.wren(X153_Y94_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X164_Y94@{S[1][32],S[1][33]}@3 */

	logic [DATA_WIDTH-1:0] X164_Y94_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X164_Y94_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_1_south_to_north_ip_size_33_bus_first_egress_fifo(.clock(bus_clock),
		.in(X164_Y94_bus_rdata_in),
		.out(X164_Y94_bus_rdata_out));

	assign north_out_reg[1][32][10:0] = X164_Y94_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][33][10:2] = X164_Y94_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X164_Y94(.data(/* from design */),
		.q(X164_Y94_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X164_Y94_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X165_Y94@{N[1][33],N[1][34]}@3 */

	logic X165_Y94_incr_waddr; // ingress control
	logic X165_Y94_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_34_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][34][0]),
		.out(X165_Y94_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_34_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][34][1]),
		.out(X165_Y94_incr_raddr));

	logic [ADDR_WIDTH-1:0] X165_Y94_waddr;
	logic [ADDR_WIDTH-1:0] X165_Y94_raddr;

	/* positional aliases */

	wire X166_Y94_incr_waddr;
	assign X166_Y94_incr_waddr = X165_Y94_incr_waddr;
	wire [ADDR_WIDTH-1:0] X166_Y94_waddr;
	assign X166_Y94_waddr = X165_Y94_waddr;
	wire X166_Y93_incr_raddr;
	assign X166_Y93_incr_raddr = X165_Y94_incr_raddr;
	wire [ADDR_WIDTH-1:0] X166_Y93_raddr;
	assign X166_Y93_raddr = X165_Y94_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X165_Y94(.clk(bus_clock),
		.incr_waddr(X165_Y94_incr_waddr),
		.waddr(X165_Y94_waddr),
		.incr_raddr(X165_Y94_incr_raddr),
		.raddr(X165_Y94_raddr));


	/* generated from I@X166_Y94@{N[1][34],N[1][35]}@3 */

	logic [DATA_WIDTH-1:0] X166_Y94_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_1_north_to_south_ip_size_35_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][34][10:0], north_in_reg[1][35][10:2]}),
		.out(X166_Y94_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X166_Y94(.data(X166_Y94_bus_wdata),
		.q(/* to design */),
		.wraddress(X166_Y94_waddr),
		.rdaddress(/* from design */),
		.wren(X166_Y94_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X226_Y94@{S[3][1],S[3][0]}@3 */

	logic [DATA_WIDTH-1:0] X226_Y94_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X226_Y94_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_0_bus_first_egress_fifo(.clock(bus_clock),
		.in(X226_Y94_bus_rdata_in),
		.out(X226_Y94_bus_rdata_out));

	assign north_out_reg[3][1][10:0] = X226_Y94_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][0][10:2] = X226_Y94_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X226_Y94(.data(/* from design */),
		.q(X226_Y94_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X226_Y94_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X228_Y94@{N[3][3],N[3][2]}@3 */

	logic [DATA_WIDTH-1:0] X228_Y94_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_2_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][3][10:0], north_in_reg[3][2][10:2]}),
		.out(X228_Y94_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X228_Y94(.data(X228_Y94_bus_wdata),
		.q(/* to design */),
		.wraddress(X228_Y94_waddr),
		.rdaddress(/* from design */),
		.wren(X228_Y94_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X229_Y94@{N[3][4],N[3][3]}@3 */

	logic X229_Y94_incr_waddr; // ingress control
	logic X229_Y94_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_3_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][4][0]),
		.out(X229_Y94_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_3_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][4][1]),
		.out(X229_Y94_incr_raddr));

	logic [ADDR_WIDTH-1:0] X229_Y94_waddr;
	logic [ADDR_WIDTH-1:0] X229_Y94_raddr;

	/* positional aliases */

	wire X228_Y94_incr_waddr;
	assign X228_Y94_incr_waddr = X229_Y94_incr_waddr;
	wire [ADDR_WIDTH-1:0] X228_Y94_waddr;
	assign X228_Y94_waddr = X229_Y94_waddr;
	wire X228_Y93_incr_raddr;
	assign X228_Y93_incr_raddr = X229_Y94_incr_raddr;
	wire [ADDR_WIDTH-1:0] X228_Y93_raddr;
	assign X228_Y93_raddr = X229_Y94_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X229_Y94(.clk(bus_clock),
		.incr_waddr(X229_Y94_incr_waddr),
		.waddr(X229_Y94_waddr),
		.incr_raddr(X229_Y94_incr_raddr),
		.raddr(X229_Y94_raddr));


	/* generated from I@X239_Y94@{E[1][10],E[1][9]}@1 */

	logic [DATA_WIDTH-1:0] X239_Y94_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_1_east_to_west_ip_size_9_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][10][10:0], east_in_reg[1][9][10:2]}),
		.out(X239_Y94_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X239_Y94(.data(X239_Y94_bus_wdata),
		.q(/* to design */),
		.wraddress(X239_Y94_waddr),
		.rdaddress(/* from design */),
		.wren(X239_Y94_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X240_Y94@{E[1][10],E[1][9]}@1 */

	logic X240_Y94_incr_waddr; // ingress control
	logic X240_Y94_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_1_east_to_west_ip_size_9_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][10][0]),
		.out(X240_Y94_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_1_east_to_west_ip_size_9_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][10][1]),
		.out(X240_Y94_incr_raddr));

	logic [ADDR_WIDTH-1:0] X240_Y94_waddr;
	logic [ADDR_WIDTH-1:0] X240_Y94_raddr;

	/* positional aliases */

	wire X239_Y94_incr_waddr;
	assign X239_Y94_incr_waddr = X240_Y94_incr_waddr;
	wire [ADDR_WIDTH-1:0] X239_Y94_waddr;
	assign X239_Y94_waddr = X240_Y94_waddr;
	wire X239_Y93_incr_raddr;
	assign X239_Y93_incr_raddr = X240_Y94_incr_raddr;
	wire [ADDR_WIDTH-1:0] X239_Y93_raddr;
	assign X239_Y93_raddr = X240_Y94_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X240_Y94(.clk(bus_clock),
		.incr_waddr(X240_Y94_incr_waddr),
		.waddr(X240_Y94_waddr),
		.incr_raddr(X240_Y94_incr_raddr),
		.raddr(X240_Y94_raddr));


	/* generated from E@X248_Y94@{S[3][17],S[3][16]}@3 */

	logic [DATA_WIDTH-1:0] X248_Y94_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X248_Y94_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_16_bus_first_egress_fifo(.clock(bus_clock),
		.in(X248_Y94_bus_rdata_in),
		.out(X248_Y94_bus_rdata_out));

	assign north_out_reg[3][17][10:0] = X248_Y94_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][16][10:2] = X248_Y94_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X248_Y94(.data(/* from design */),
		.q(X248_Y94_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X248_Y94_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X250_Y94@{N[3][19],N[3][18]}@3 */

	logic [DATA_WIDTH-1:0] X250_Y94_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_18_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][19][10:0], north_in_reg[3][18][10:2]}),
		.out(X250_Y94_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X250_Y94(.data(X250_Y94_bus_wdata),
		.q(/* to design */),
		.wraddress(X250_Y94_waddr),
		.rdaddress(/* from design */),
		.wren(X250_Y94_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X251_Y94@{N[3][20],N[3][19]}@3 */

	logic X251_Y94_incr_waddr; // ingress control
	logic X251_Y94_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_19_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][20][0]),
		.out(X251_Y94_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_19_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][20][1]),
		.out(X251_Y94_incr_raddr));

	logic [ADDR_WIDTH-1:0] X251_Y94_waddr;
	logic [ADDR_WIDTH-1:0] X251_Y94_raddr;

	/* positional aliases */

	wire X250_Y94_incr_waddr;
	assign X250_Y94_incr_waddr = X251_Y94_incr_waddr;
	wire [ADDR_WIDTH-1:0] X250_Y94_waddr;
	assign X250_Y94_waddr = X251_Y94_waddr;
	wire X250_Y93_incr_raddr;
	assign X250_Y93_incr_raddr = X251_Y94_incr_raddr;
	wire [ADDR_WIDTH-1:0] X250_Y93_raddr;
	assign X250_Y93_raddr = X251_Y94_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X251_Y94(.clk(bus_clock),
		.incr_waddr(X251_Y94_incr_waddr),
		.waddr(X251_Y94_waddr),
		.incr_raddr(X251_Y94_incr_raddr),
		.raddr(X251_Y94_raddr));


	/* generated from E@X258_Y94@{S[3][25],S[3][24]}@3 */

	logic [DATA_WIDTH-1:0] X258_Y94_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X258_Y94_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_24_bus_first_egress_fifo(.clock(bus_clock),
		.in(X258_Y94_bus_rdata_in),
		.out(X258_Y94_bus_rdata_out));

	assign north_out_reg[3][25][10:0] = X258_Y94_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][24][10:2] = X258_Y94_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X258_Y94(.data(/* from design */),
		.q(X258_Y94_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X258_Y94_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X260_Y94@{N[3][27],N[3][26]}@3 */

	logic [DATA_WIDTH-1:0] X260_Y94_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_26_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][27][10:0], north_in_reg[3][26][10:2]}),
		.out(X260_Y94_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X260_Y94(.data(X260_Y94_bus_wdata),
		.q(/* to design */),
		.wraddress(X260_Y94_waddr),
		.rdaddress(/* from design */),
		.wren(X260_Y94_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X261_Y94@{N[3][28],N[3][27]}@3 */

	logic X261_Y94_incr_waddr; // ingress control
	logic X261_Y94_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_27_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][28][0]),
		.out(X261_Y94_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_27_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][28][1]),
		.out(X261_Y94_incr_raddr));

	logic [ADDR_WIDTH-1:0] X261_Y94_waddr;
	logic [ADDR_WIDTH-1:0] X261_Y94_raddr;

	/* positional aliases */

	wire X260_Y94_incr_waddr;
	assign X260_Y94_incr_waddr = X261_Y94_incr_waddr;
	wire [ADDR_WIDTH-1:0] X260_Y94_waddr;
	assign X260_Y94_waddr = X261_Y94_waddr;
	wire X260_Y93_incr_raddr;
	assign X260_Y93_incr_raddr = X261_Y94_incr_raddr;
	wire [ADDR_WIDTH-1:0] X260_Y93_raddr;
	assign X260_Y93_raddr = X261_Y94_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X261_Y94(.clk(bus_clock),
		.incr_waddr(X261_Y94_incr_waddr),
		.waddr(X261_Y94_waddr),
		.incr_raddr(X261_Y94_incr_raddr),
		.raddr(X261_Y94_raddr));


	/* generated from E@X269_Y94@{S[3][33],S[3][32]}@3 */

	logic [DATA_WIDTH-1:0] X269_Y94_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X269_Y94_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_3_south_to_north_ip_size_32_bus_first_egress_fifo(.clock(bus_clock),
		.in(X269_Y94_bus_rdata_in),
		.out(X269_Y94_bus_rdata_out));

	assign north_out_reg[3][33][10:0] = X269_Y94_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][32][10:2] = X269_Y94_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X269_Y94(.data(/* from design */),
		.q(X269_Y94_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X269_Y94_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X271_Y94@{N[3][35],N[3][34]}@3 */

	logic [DATA_WIDTH-1:0] X271_Y94_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_34_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][35][10:0], north_in_reg[3][34][10:2]}),
		.out(X271_Y94_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X271_Y94(.data(X271_Y94_bus_wdata),
		.q(/* to design */),
		.wraddress(X271_Y94_waddr),
		.rdaddress(/* from design */),
		.wren(X271_Y94_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X272_Y94@{N[3][36],N[3][35]}@3 */

	logic X272_Y94_incr_waddr; // ingress control
	logic X272_Y94_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_35_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][36][0]),
		.out(X272_Y94_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_3_north_to_south_ip_size_35_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][36][1]),
		.out(X272_Y94_incr_raddr));

	logic [ADDR_WIDTH-1:0] X272_Y94_waddr;
	logic [ADDR_WIDTH-1:0] X272_Y94_raddr;

	/* positional aliases */

	wire X271_Y94_incr_waddr;
	assign X271_Y94_incr_waddr = X272_Y94_incr_waddr;
	wire [ADDR_WIDTH-1:0] X271_Y94_waddr;
	assign X271_Y94_waddr = X272_Y94_waddr;
	wire X271_Y93_incr_raddr;
	assign X271_Y93_incr_raddr = X272_Y94_incr_raddr;
	wire [ADDR_WIDTH-1:0] X271_Y93_raddr;
	assign X271_Y93_raddr = X272_Y94_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X272_Y94(.clk(bus_clock),
		.incr_waddr(X272_Y94_incr_waddr),
		.waddr(X272_Y94_waddr),
		.incr_raddr(X272_Y94_incr_raddr),
		.raddr(X272_Y94_raddr));


	/* generated from C@X120_Y93@{S[0][39],S[1][0]}@2 */

	logic X120_Y93_incr_waddr; // ingress control
	logic X120_Y93_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_0_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][0][0]),
		.out(X120_Y93_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_0_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][0][1]),
		.out(X120_Y93_incr_raddr));

	logic [ADDR_WIDTH-1:0] X120_Y93_waddr;
	logic [ADDR_WIDTH-1:0] X120_Y93_raddr;

	/* positional aliases */

	wire X121_Y93_incr_waddr;
	assign X121_Y93_incr_waddr = X120_Y93_incr_waddr;
	wire [ADDR_WIDTH-1:0] X121_Y93_waddr;
	assign X121_Y93_waddr = X120_Y93_waddr;
	wire X121_Y94_incr_raddr;
	assign X121_Y94_incr_raddr = X120_Y93_incr_raddr;
	wire [ADDR_WIDTH-1:0] X121_Y94_raddr;
	assign X121_Y94_raddr = X120_Y93_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X120_Y93(.clk(bus_clock),
		.incr_waddr(X120_Y93_incr_waddr),
		.waddr(X120_Y93_waddr),
		.incr_raddr(X120_Y93_incr_raddr),
		.raddr(X120_Y93_raddr));


	/* generated from I@X121_Y93@{S[1][0],S[1][1]}@2 */

	logic [DATA_WIDTH-1:0] X121_Y93_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_1_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][0][10:0], south_in_reg[1][1][10:2]}),
		.out(X121_Y93_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X121_Y93(.data(X121_Y93_bus_wdata),
		.q(/* to design */),
		.wraddress(X121_Y93_waddr),
		.rdaddress(/* from design */),
		.wren(X121_Y93_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X123_Y93@{N[1][2],N[1][3]}@4 */

	logic [DATA_WIDTH-1:0] X123_Y93_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X123_Y93_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_3_bus_first_egress_fifo(.clock(bus_clock),
		.in(X123_Y93_bus_rdata_in),
		.out(X123_Y93_bus_rdata_out));

	assign south_out_reg[1][2][10:0] = X123_Y93_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][3][10:2] = X123_Y93_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X123_Y93(.data(/* from design */),
		.q(X123_Y93_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X123_Y93_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X131_Y93@{S[1][7],S[1][8]}@2 */

	logic X131_Y93_incr_waddr; // ingress control
	logic X131_Y93_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_8_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][8][0]),
		.out(X131_Y93_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_8_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][8][1]),
		.out(X131_Y93_incr_raddr));

	logic [ADDR_WIDTH-1:0] X131_Y93_waddr;
	logic [ADDR_WIDTH-1:0] X131_Y93_raddr;

	/* positional aliases */

	wire X132_Y93_incr_waddr;
	assign X132_Y93_incr_waddr = X131_Y93_incr_waddr;
	wire [ADDR_WIDTH-1:0] X132_Y93_waddr;
	assign X132_Y93_waddr = X131_Y93_waddr;
	wire X132_Y94_incr_raddr;
	assign X132_Y94_incr_raddr = X131_Y93_incr_raddr;
	wire [ADDR_WIDTH-1:0] X132_Y94_raddr;
	assign X132_Y94_raddr = X131_Y93_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X131_Y93(.clk(bus_clock),
		.incr_waddr(X131_Y93_incr_waddr),
		.waddr(X131_Y93_waddr),
		.incr_raddr(X131_Y93_incr_raddr),
		.raddr(X131_Y93_raddr));


	/* generated from I@X132_Y93@{S[1][8],S[1][9]}@2 */

	logic [DATA_WIDTH-1:0] X132_Y93_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_9_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][8][10:0], south_in_reg[1][9][10:2]}),
		.out(X132_Y93_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X132_Y93(.data(X132_Y93_bus_wdata),
		.q(/* to design */),
		.wraddress(X132_Y93_waddr),
		.rdaddress(/* from design */),
		.wren(X132_Y93_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X134_Y93@{N[1][10],N[1][11]}@4 */

	logic [DATA_WIDTH-1:0] X134_Y93_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X134_Y93_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_11_bus_first_egress_fifo(.clock(bus_clock),
		.in(X134_Y93_bus_rdata_in),
		.out(X134_Y93_bus_rdata_out));

	assign south_out_reg[1][10][10:0] = X134_Y93_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][11][10:2] = X134_Y93_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X134_Y93(.data(/* from design */),
		.q(X134_Y93_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X134_Y93_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X141_Y93@{S[1][15],S[1][16]}@2 */

	logic X141_Y93_incr_waddr; // ingress control
	logic X141_Y93_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_16_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][16][0]),
		.out(X141_Y93_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_16_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][16][1]),
		.out(X141_Y93_incr_raddr));

	logic [ADDR_WIDTH-1:0] X141_Y93_waddr;
	logic [ADDR_WIDTH-1:0] X141_Y93_raddr;

	/* positional aliases */

	wire X142_Y93_incr_waddr;
	assign X142_Y93_incr_waddr = X141_Y93_incr_waddr;
	wire [ADDR_WIDTH-1:0] X142_Y93_waddr;
	assign X142_Y93_waddr = X141_Y93_waddr;
	wire X142_Y94_incr_raddr;
	assign X142_Y94_incr_raddr = X141_Y93_incr_raddr;
	wire [ADDR_WIDTH-1:0] X142_Y94_raddr;
	assign X142_Y94_raddr = X141_Y93_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X141_Y93(.clk(bus_clock),
		.incr_waddr(X141_Y93_incr_waddr),
		.waddr(X141_Y93_waddr),
		.incr_raddr(X141_Y93_incr_raddr),
		.raddr(X141_Y93_raddr));


	/* generated from I@X142_Y93@{S[1][16],S[1][17]}@2 */

	logic [DATA_WIDTH-1:0] X142_Y93_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_17_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][16][10:0], south_in_reg[1][17][10:2]}),
		.out(X142_Y93_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X142_Y93(.data(X142_Y93_bus_wdata),
		.q(/* to design */),
		.wraddress(X142_Y93_waddr),
		.rdaddress(/* from design */),
		.wren(X142_Y93_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X144_Y93@{N[1][18],N[1][19]}@4 */

	logic [DATA_WIDTH-1:0] X144_Y93_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X144_Y93_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_19_bus_first_egress_fifo(.clock(bus_clock),
		.in(X144_Y93_bus_rdata_in),
		.out(X144_Y93_bus_rdata_out));

	assign south_out_reg[1][18][10:0] = X144_Y93_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][19][10:2] = X144_Y93_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X144_Y93(.data(/* from design */),
		.q(X144_Y93_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X144_Y93_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X153_Y93@{W[1][10],W[1][9]}@3 */

	logic [DATA_WIDTH-1:0] X153_Y93_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X153_Y93_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) west_to_east_sector_size_1_west_to_east_ip_size_9_bus_first_egress_fifo(.clock(bus_clock),
		.in(X153_Y93_bus_rdata_in),
		.out(X153_Y93_bus_rdata_out));

	assign east_out_reg[1][10][10:0] = X153_Y93_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][9][10:2] = X153_Y93_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X153_Y93(.data(/* from design */),
		.q(X153_Y93_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X153_Y93_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X163_Y93@{S[1][31],S[1][32]}@2 */

	logic X163_Y93_incr_waddr; // ingress control
	logic X163_Y93_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_32_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][32][0]),
		.out(X163_Y93_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_32_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][32][1]),
		.out(X163_Y93_incr_raddr));

	logic [ADDR_WIDTH-1:0] X163_Y93_waddr;
	logic [ADDR_WIDTH-1:0] X163_Y93_raddr;

	/* positional aliases */

	wire X164_Y93_incr_waddr;
	assign X164_Y93_incr_waddr = X163_Y93_incr_waddr;
	wire [ADDR_WIDTH-1:0] X164_Y93_waddr;
	assign X164_Y93_waddr = X163_Y93_waddr;
	wire X164_Y94_incr_raddr;
	assign X164_Y94_incr_raddr = X163_Y93_incr_raddr;
	wire [ADDR_WIDTH-1:0] X164_Y94_raddr;
	assign X164_Y94_raddr = X163_Y93_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X163_Y93(.clk(bus_clock),
		.incr_waddr(X163_Y93_incr_waddr),
		.waddr(X163_Y93_waddr),
		.incr_raddr(X163_Y93_incr_raddr),
		.raddr(X163_Y93_raddr));


	/* generated from I@X164_Y93@{S[1][32],S[1][33]}@2 */

	logic [DATA_WIDTH-1:0] X164_Y93_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_1_south_to_north_ip_size_33_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][32][10:0], south_in_reg[1][33][10:2]}),
		.out(X164_Y93_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X164_Y93(.data(X164_Y93_bus_wdata),
		.q(/* to design */),
		.wraddress(X164_Y93_waddr),
		.rdaddress(/* from design */),
		.wren(X164_Y93_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X166_Y93@{N[1][34],N[1][35]}@4 */

	logic [DATA_WIDTH-1:0] X166_Y93_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X166_Y93_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_1_north_to_south_ip_size_35_bus_first_egress_fifo(.clock(bus_clock),
		.in(X166_Y93_bus_rdata_in),
		.out(X166_Y93_bus_rdata_out));

	assign south_out_reg[1][34][10:0] = X166_Y93_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][35][10:2] = X166_Y93_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X166_Y93(.data(/* from design */),
		.q(X166_Y93_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X166_Y93_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X226_Y93@{S[3][1],S[3][0]}@2 */

	logic [DATA_WIDTH-1:0] X226_Y93_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_0_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][1][10:0], south_in_reg[3][0][10:2]}),
		.out(X226_Y93_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X226_Y93(.data(X226_Y93_bus_wdata),
		.q(/* to design */),
		.wraddress(X226_Y93_waddr),
		.rdaddress(/* from design */),
		.wren(X226_Y93_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X227_Y93@{S[3][2],S[3][1]}@2 */

	logic X227_Y93_incr_waddr; // ingress control
	logic X227_Y93_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_1_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][2][0]),
		.out(X227_Y93_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_1_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][2][1]),
		.out(X227_Y93_incr_raddr));

	logic [ADDR_WIDTH-1:0] X227_Y93_waddr;
	logic [ADDR_WIDTH-1:0] X227_Y93_raddr;

	/* positional aliases */

	wire X226_Y93_incr_waddr;
	assign X226_Y93_incr_waddr = X227_Y93_incr_waddr;
	wire [ADDR_WIDTH-1:0] X226_Y93_waddr;
	assign X226_Y93_waddr = X227_Y93_waddr;
	wire X226_Y94_incr_raddr;
	assign X226_Y94_incr_raddr = X227_Y93_incr_raddr;
	wire [ADDR_WIDTH-1:0] X226_Y94_raddr;
	assign X226_Y94_raddr = X227_Y93_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X227_Y93(.clk(bus_clock),
		.incr_waddr(X227_Y93_incr_waddr),
		.waddr(X227_Y93_waddr),
		.incr_raddr(X227_Y93_incr_raddr),
		.raddr(X227_Y93_raddr));


	/* generated from E@X228_Y93@{N[3][3],N[3][2]}@4 */

	logic [DATA_WIDTH-1:0] X228_Y93_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X228_Y93_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_2_bus_first_egress_fifo(.clock(bus_clock),
		.in(X228_Y93_bus_rdata_in),
		.out(X228_Y93_bus_rdata_out));

	assign south_out_reg[3][3][10:0] = X228_Y93_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][2][10:2] = X228_Y93_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X228_Y93(.data(/* from design */),
		.q(X228_Y93_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X228_Y93_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X239_Y93@{E[1][10],E[1][9]}@2 */

	logic [DATA_WIDTH-1:0] X239_Y93_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X239_Y93_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_1_east_to_west_ip_size_9_bus_first_egress_fifo(.clock(bus_clock),
		.in(X239_Y93_bus_rdata_in),
		.out(X239_Y93_bus_rdata_out));

	assign west_out_reg[1][10][10:0] = X239_Y93_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][9][10:2] = X239_Y93_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X239_Y93(.data(/* from design */),
		.q(X239_Y93_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X239_Y93_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X248_Y93@{S[3][17],S[3][16]}@2 */

	logic [DATA_WIDTH-1:0] X248_Y93_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_16_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][17][10:0], south_in_reg[3][16][10:2]}),
		.out(X248_Y93_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X248_Y93(.data(X248_Y93_bus_wdata),
		.q(/* to design */),
		.wraddress(X248_Y93_waddr),
		.rdaddress(/* from design */),
		.wren(X248_Y93_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X249_Y93@{S[3][18],S[3][17]}@2 */

	logic X249_Y93_incr_waddr; // ingress control
	logic X249_Y93_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_17_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][18][0]),
		.out(X249_Y93_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_17_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][18][1]),
		.out(X249_Y93_incr_raddr));

	logic [ADDR_WIDTH-1:0] X249_Y93_waddr;
	logic [ADDR_WIDTH-1:0] X249_Y93_raddr;

	/* positional aliases */

	wire X248_Y93_incr_waddr;
	assign X248_Y93_incr_waddr = X249_Y93_incr_waddr;
	wire [ADDR_WIDTH-1:0] X248_Y93_waddr;
	assign X248_Y93_waddr = X249_Y93_waddr;
	wire X248_Y94_incr_raddr;
	assign X248_Y94_incr_raddr = X249_Y93_incr_raddr;
	wire [ADDR_WIDTH-1:0] X248_Y94_raddr;
	assign X248_Y94_raddr = X249_Y93_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X249_Y93(.clk(bus_clock),
		.incr_waddr(X249_Y93_incr_waddr),
		.waddr(X249_Y93_waddr),
		.incr_raddr(X249_Y93_incr_raddr),
		.raddr(X249_Y93_raddr));


	/* generated from E@X250_Y93@{N[3][19],N[3][18]}@4 */

	logic [DATA_WIDTH-1:0] X250_Y93_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X250_Y93_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_18_bus_first_egress_fifo(.clock(bus_clock),
		.in(X250_Y93_bus_rdata_in),
		.out(X250_Y93_bus_rdata_out));

	assign south_out_reg[3][19][10:0] = X250_Y93_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][18][10:2] = X250_Y93_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X250_Y93(.data(/* from design */),
		.q(X250_Y93_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X250_Y93_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X258_Y93@{S[3][25],S[3][24]}@2 */

	logic [DATA_WIDTH-1:0] X258_Y93_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_24_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][25][10:0], south_in_reg[3][24][10:2]}),
		.out(X258_Y93_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X258_Y93(.data(X258_Y93_bus_wdata),
		.q(/* to design */),
		.wraddress(X258_Y93_waddr),
		.rdaddress(/* from design */),
		.wren(X258_Y93_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X259_Y93@{S[3][26],S[3][25]}@2 */

	logic X259_Y93_incr_waddr; // ingress control
	logic X259_Y93_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_25_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][26][0]),
		.out(X259_Y93_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_25_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][26][1]),
		.out(X259_Y93_incr_raddr));

	logic [ADDR_WIDTH-1:0] X259_Y93_waddr;
	logic [ADDR_WIDTH-1:0] X259_Y93_raddr;

	/* positional aliases */

	wire X258_Y93_incr_waddr;
	assign X258_Y93_incr_waddr = X259_Y93_incr_waddr;
	wire [ADDR_WIDTH-1:0] X258_Y93_waddr;
	assign X258_Y93_waddr = X259_Y93_waddr;
	wire X258_Y94_incr_raddr;
	assign X258_Y94_incr_raddr = X259_Y93_incr_raddr;
	wire [ADDR_WIDTH-1:0] X258_Y94_raddr;
	assign X258_Y94_raddr = X259_Y93_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X259_Y93(.clk(bus_clock),
		.incr_waddr(X259_Y93_incr_waddr),
		.waddr(X259_Y93_waddr),
		.incr_raddr(X259_Y93_incr_raddr),
		.raddr(X259_Y93_raddr));


	/* generated from E@X260_Y93@{N[3][27],N[3][26]}@4 */

	logic [DATA_WIDTH-1:0] X260_Y93_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X260_Y93_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_26_bus_first_egress_fifo(.clock(bus_clock),
		.in(X260_Y93_bus_rdata_in),
		.out(X260_Y93_bus_rdata_out));

	assign south_out_reg[3][27][10:0] = X260_Y93_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][26][10:2] = X260_Y93_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X260_Y93(.data(/* from design */),
		.q(X260_Y93_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X260_Y93_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X269_Y93@{S[3][33],S[3][32]}@2 */

	logic [DATA_WIDTH-1:0] X269_Y93_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_32_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][33][10:0], south_in_reg[3][32][10:2]}),
		.out(X269_Y93_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X269_Y93(.data(X269_Y93_bus_wdata),
		.q(/* to design */),
		.wraddress(X269_Y93_waddr),
		.rdaddress(/* from design */),
		.wren(X269_Y93_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X270_Y93@{S[3][34],S[3][33]}@2 */

	logic X270_Y93_incr_waddr; // ingress control
	logic X270_Y93_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_33_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][34][0]),
		.out(X270_Y93_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_3_south_to_north_ip_size_33_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][34][1]),
		.out(X270_Y93_incr_raddr));

	logic [ADDR_WIDTH-1:0] X270_Y93_waddr;
	logic [ADDR_WIDTH-1:0] X270_Y93_raddr;

	/* positional aliases */

	wire X269_Y93_incr_waddr;
	assign X269_Y93_incr_waddr = X270_Y93_incr_waddr;
	wire [ADDR_WIDTH-1:0] X269_Y93_waddr;
	assign X269_Y93_waddr = X270_Y93_waddr;
	wire X269_Y94_incr_raddr;
	assign X269_Y94_incr_raddr = X270_Y93_incr_raddr;
	wire [ADDR_WIDTH-1:0] X269_Y94_raddr;
	assign X269_Y94_raddr = X270_Y93_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X270_Y93(.clk(bus_clock),
		.incr_waddr(X270_Y93_incr_waddr),
		.waddr(X270_Y93_waddr),
		.incr_raddr(X270_Y93_incr_raddr),
		.raddr(X270_Y93_raddr));


	/* generated from E@X271_Y93@{N[3][35],N[3][34]}@4 */

	logic [DATA_WIDTH-1:0] X271_Y93_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X271_Y93_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_3_north_to_south_ip_size_34_bus_first_egress_fifo(.clock(bus_clock),
		.in(X271_Y93_bus_rdata_in),
		.out(X271_Y93_bus_rdata_out));

	assign south_out_reg[3][35][10:0] = X271_Y93_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][34][10:2] = X271_Y93_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X271_Y93(.data(/* from design */),
		.q(X271_Y93_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X271_Y93_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X83_Y92@{E[1][8],E[1][7]}@5 */

	logic [DATA_WIDTH-1:0] X83_Y92_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) east_to_west_sector_size_1_east_to_west_ip_size_7_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][8][10:0], east_in_reg[1][7][10:2]}),
		.out(X83_Y92_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X83_Y92(.data(X83_Y92_bus_wdata),
		.q(/* to design */),
		.wraddress(X83_Y92_waddr),
		.rdaddress(/* from design */),
		.wren(X83_Y92_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X84_Y92@{E[1][8],E[1][7]}@5 */

	logic X84_Y92_incr_waddr; // ingress control
	logic X84_Y92_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) east_to_west_sector_size_1_east_to_west_ip_size_7_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][7][0]),
		.out(X84_Y92_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) east_to_west_sector_size_1_east_to_west_ip_size_7_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][7][1]),
		.out(X84_Y92_incr_raddr));

	logic [ADDR_WIDTH-1:0] X84_Y92_waddr;
	logic [ADDR_WIDTH-1:0] X84_Y92_raddr;

	/* positional aliases */

	wire X83_Y92_incr_waddr;
	assign X83_Y92_incr_waddr = X84_Y92_incr_waddr;
	wire [ADDR_WIDTH-1:0] X83_Y92_waddr;
	assign X83_Y92_waddr = X84_Y92_waddr;
	wire X83_Y91_incr_raddr;
	assign X83_Y91_incr_raddr = X84_Y92_incr_raddr;
	wire [ADDR_WIDTH-1:0] X83_Y91_raddr;
	assign X83_Y91_raddr = X84_Y92_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X84_Y92(.clk(bus_clock),
		.incr_waddr(X84_Y92_incr_waddr),
		.waddr(X84_Y92_waddr),
		.incr_raddr(X84_Y92_incr_raddr),
		.raddr(X84_Y92_raddr));


	/* generated from C@X184_Y92@{W[1][8],W[1][7]}@3 */

	logic X184_Y92_incr_waddr; // ingress control
	logic X184_Y92_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_1_west_to_east_ip_size_7_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][8][0]),
		.out(X184_Y92_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_1_west_to_east_ip_size_7_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][8][1]),
		.out(X184_Y92_incr_raddr));

	logic [ADDR_WIDTH-1:0] X184_Y92_waddr;
	logic [ADDR_WIDTH-1:0] X184_Y92_raddr;

	/* positional aliases */

	wire X185_Y92_incr_waddr;
	assign X185_Y92_incr_waddr = X184_Y92_incr_waddr;
	wire [ADDR_WIDTH-1:0] X185_Y92_waddr;
	assign X185_Y92_waddr = X184_Y92_waddr;
	wire X185_Y91_incr_raddr;
	assign X185_Y91_incr_raddr = X184_Y92_incr_raddr;
	wire [ADDR_WIDTH-1:0] X185_Y91_raddr;
	assign X185_Y91_raddr = X184_Y92_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X184_Y92(.clk(bus_clock),
		.incr_waddr(X184_Y92_incr_waddr),
		.waddr(X184_Y92_waddr),
		.incr_raddr(X184_Y92_incr_raddr),
		.raddr(X184_Y92_raddr));


	/* generated from I@X185_Y92@{W[1][8],W[1][7]}@3 */

	logic [DATA_WIDTH-1:0] X185_Y92_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) west_to_east_sector_size_1_west_to_east_ip_size_7_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][8][10:0], west_in_reg[1][7][10:2]}),
		.out(X185_Y92_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X185_Y92(.data(X185_Y92_bus_wdata),
		.q(/* to design */),
		.wraddress(X185_Y92_waddr),
		.rdaddress(/* from design */),
		.wren(X185_Y92_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X83_Y91@{E[1][8],E[1][7]}@6 */

	logic [DATA_WIDTH-1:0] X83_Y91_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X83_Y91_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) east_to_west_sector_size_1_east_to_west_ip_size_7_bus_first_egress_fifo(.clock(bus_clock),
		.in(X83_Y91_bus_rdata_in),
		.out(X83_Y91_bus_rdata_out));

	assign west_out_reg[1][8][10:0] = X83_Y91_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][7][10:2] = X83_Y91_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X83_Y91(.data(/* from design */),
		.q(X83_Y91_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X83_Y91_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X185_Y91@{W[1][8],W[1][7]}@4 */

	logic [DATA_WIDTH-1:0] X185_Y91_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X185_Y91_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) west_to_east_sector_size_1_west_to_east_ip_size_7_bus_first_egress_fifo(.clock(bus_clock),
		.in(X185_Y91_bus_rdata_in),
		.out(X185_Y91_bus_rdata_out));

	assign east_out_reg[1][8][10:0] = X185_Y91_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][7][10:2] = X185_Y91_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X185_Y91(.data(/* from design */),
		.q(X185_Y91_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X185_Y91_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X82_Y90@{W[1][6],W[1][5]}@0 */

	logic X82_Y90_incr_waddr; // ingress control
	logic X82_Y90_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) west_to_east_sector_size_1_west_to_east_ip_size_5_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][5][0]),
		.out(X82_Y90_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) west_to_east_sector_size_1_west_to_east_ip_size_5_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][5][1]),
		.out(X82_Y90_incr_raddr));

	logic [ADDR_WIDTH-1:0] X82_Y90_waddr;
	logic [ADDR_WIDTH-1:0] X82_Y90_raddr;

	/* positional aliases */

	wire X83_Y90_incr_waddr;
	assign X83_Y90_incr_waddr = X82_Y90_incr_waddr;
	wire [ADDR_WIDTH-1:0] X83_Y90_waddr;
	assign X83_Y90_waddr = X82_Y90_waddr;
	wire X83_Y89_incr_raddr;
	assign X83_Y89_incr_raddr = X82_Y90_incr_raddr;
	wire [ADDR_WIDTH-1:0] X83_Y89_raddr;
	assign X83_Y89_raddr = X82_Y90_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X82_Y90(.clk(bus_clock),
		.incr_waddr(X82_Y90_incr_waddr),
		.waddr(X82_Y90_waddr),
		.incr_raddr(X82_Y90_incr_raddr),
		.raddr(X82_Y90_raddr));


	/* generated from I@X83_Y90@{W[1][6],W[1][5]}@0 */

	logic [DATA_WIDTH-1:0] X83_Y90_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) west_to_east_sector_size_1_west_to_east_ip_size_5_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][6][10:0], west_in_reg[1][5][10:2]}),
		.out(X83_Y90_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X83_Y90(.data(X83_Y90_bus_wdata),
		.q(/* to design */),
		.wraddress(X83_Y90_waddr),
		.rdaddress(/* from design */),
		.wren(X83_Y90_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X99_Y90@{S[0][24],S[0][25]}@3 */

	logic [DATA_WIDTH-1:0] X99_Y90_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X99_Y90_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_25_bus_first_egress_fifo(.clock(bus_clock),
		.in(X99_Y90_bus_rdata_in),
		.out(X99_Y90_bus_rdata_out));

	assign north_out_reg[0][24][10:0] = X99_Y90_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][25][10:2] = X99_Y90_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X99_Y90(.data(/* from design */),
		.q(X99_Y90_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X99_Y90_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X100_Y90@{N[0][25],N[0][26]}@3 */

	logic X100_Y90_incr_waddr; // ingress control
	logic X100_Y90_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_26_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][26][0]),
		.out(X100_Y90_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_26_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][26][1]),
		.out(X100_Y90_incr_raddr));

	logic [ADDR_WIDTH-1:0] X100_Y90_waddr;
	logic [ADDR_WIDTH-1:0] X100_Y90_raddr;

	/* positional aliases */

	wire X101_Y90_incr_waddr;
	assign X101_Y90_incr_waddr = X100_Y90_incr_waddr;
	wire [ADDR_WIDTH-1:0] X101_Y90_waddr;
	assign X101_Y90_waddr = X100_Y90_waddr;
	wire X101_Y89_incr_raddr;
	assign X101_Y89_incr_raddr = X100_Y90_incr_raddr;
	wire [ADDR_WIDTH-1:0] X101_Y89_raddr;
	assign X101_Y89_raddr = X100_Y90_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X100_Y90(.clk(bus_clock),
		.incr_waddr(X100_Y90_incr_waddr),
		.waddr(X100_Y90_waddr),
		.incr_raddr(X100_Y90_incr_raddr),
		.raddr(X100_Y90_raddr));


	/* generated from I@X101_Y90@{N[0][26],N[0][27]}@3 */

	logic [DATA_WIDTH-1:0] X101_Y90_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_27_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][26][10:0], north_in_reg[0][27][10:2]}),
		.out(X101_Y90_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X101_Y90(.data(X101_Y90_bus_wdata),
		.q(/* to design */),
		.wraddress(X101_Y90_waddr),
		.rdaddress(/* from design */),
		.wren(X101_Y90_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X110_Y90@{S[0][32],S[0][33]}@3 */

	logic [DATA_WIDTH-1:0] X110_Y90_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X110_Y90_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_0_south_to_north_ip_size_33_bus_first_egress_fifo(.clock(bus_clock),
		.in(X110_Y90_bus_rdata_in),
		.out(X110_Y90_bus_rdata_out));

	assign north_out_reg[0][32][10:0] = X110_Y90_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][33][10:2] = X110_Y90_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X110_Y90(.data(/* from design */),
		.q(X110_Y90_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X110_Y90_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X111_Y90@{N[0][33],N[0][34]}@3 */

	logic X111_Y90_incr_waddr; // ingress control
	logic X111_Y90_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_34_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][34][0]),
		.out(X111_Y90_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_34_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][34][1]),
		.out(X111_Y90_incr_raddr));

	logic [ADDR_WIDTH-1:0] X111_Y90_waddr;
	logic [ADDR_WIDTH-1:0] X111_Y90_raddr;

	/* positional aliases */

	wire X112_Y90_incr_waddr;
	assign X112_Y90_incr_waddr = X111_Y90_incr_waddr;
	wire [ADDR_WIDTH-1:0] X112_Y90_waddr;
	assign X112_Y90_waddr = X111_Y90_waddr;
	wire X112_Y89_incr_raddr;
	assign X112_Y89_incr_raddr = X111_Y90_incr_raddr;
	wire [ADDR_WIDTH-1:0] X112_Y89_raddr;
	assign X112_Y89_raddr = X111_Y90_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X111_Y90(.clk(bus_clock),
		.incr_waddr(X111_Y90_incr_waddr),
		.waddr(X111_Y90_waddr),
		.incr_raddr(X111_Y90_incr_raddr),
		.raddr(X111_Y90_raddr));


	/* generated from I@X112_Y90@{N[0][34],N[0][35]}@3 */

	logic [DATA_WIDTH-1:0] X112_Y90_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_0_north_to_south_ip_size_35_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][34][10:0], north_in_reg[0][35][10:2]}),
		.out(X112_Y90_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X112_Y90(.data(X112_Y90_bus_wdata),
		.q(/* to design */),
		.wraddress(X112_Y90_waddr),
		.rdaddress(/* from design */),
		.wren(X112_Y90_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from I@X185_Y90@{E[1][6],E[1][5]}@2 */

	logic [DATA_WIDTH-1:0] X185_Y90_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) east_to_west_sector_size_1_east_to_west_ip_size_5_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][6][10:0], east_in_reg[1][5][10:2]}),
		.out(X185_Y90_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X185_Y90(.data(X185_Y90_bus_wdata),
		.q(/* to design */),
		.wraddress(X185_Y90_waddr),
		.rdaddress(/* from design */),
		.wren(X185_Y90_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X186_Y90@{E[1][6],E[1][5]}@2 */

	logic X186_Y90_incr_waddr; // ingress control
	logic X186_Y90_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) east_to_west_sector_size_1_east_to_west_ip_size_5_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][6][0]),
		.out(X186_Y90_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) east_to_west_sector_size_1_east_to_west_ip_size_5_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][6][1]),
		.out(X186_Y90_incr_raddr));

	logic [ADDR_WIDTH-1:0] X186_Y90_waddr;
	logic [ADDR_WIDTH-1:0] X186_Y90_raddr;

	/* positional aliases */

	wire X185_Y90_incr_waddr;
	assign X185_Y90_incr_waddr = X186_Y90_incr_waddr;
	wire [ADDR_WIDTH-1:0] X185_Y90_waddr;
	assign X185_Y90_waddr = X186_Y90_waddr;
	wire X185_Y89_incr_raddr;
	assign X185_Y89_incr_raddr = X186_Y90_incr_raddr;
	wire [ADDR_WIDTH-1:0] X185_Y89_raddr;
	assign X185_Y89_raddr = X186_Y90_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X186_Y90(.clk(bus_clock),
		.incr_waddr(X186_Y90_incr_waddr),
		.waddr(X186_Y90_waddr),
		.incr_raddr(X186_Y90_incr_raddr),
		.raddr(X186_Y90_raddr));


	/* generated from E@X204_Y90@{S[2][25],S[2][24]}@3 */

	logic [DATA_WIDTH-1:0] X204_Y90_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X204_Y90_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) south_to_north_sector_size_2_south_to_north_ip_size_24_bus_first_egress_fifo(.clock(bus_clock),
		.in(X204_Y90_bus_rdata_in),
		.out(X204_Y90_bus_rdata_out));

	assign north_out_reg[2][25][10:0] = X204_Y90_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][24][10:2] = X204_Y90_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X204_Y90(.data(/* from design */),
		.q(X204_Y90_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X204_Y90_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X206_Y90@{N[2][27],N[2][26]}@3 */

	logic [DATA_WIDTH-1:0] X206_Y90_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_26_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][27][10:0], north_in_reg[2][26][10:2]}),
		.out(X206_Y90_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X206_Y90(.data(X206_Y90_bus_wdata),
		.q(/* to design */),
		.wraddress(X206_Y90_waddr),
		.rdaddress(/* from design */),
		.wren(X206_Y90_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X207_Y90@{N[2][28],N[2][27]}@3 */

	logic X207_Y90_incr_waddr; // ingress control
	logic X207_Y90_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_27_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[2][28][0]),
		.out(X207_Y90_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) north_to_south_sector_size_2_north_to_south_ip_size_27_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[2][28][1]),
		.out(X207_Y90_incr_raddr));

	logic [ADDR_WIDTH-1:0] X207_Y90_waddr;
	logic [ADDR_WIDTH-1:0] X207_Y90_raddr;

	/* positional aliases */

	wire X206_Y90_incr_waddr;
	assign X206_Y90_incr_waddr = X207_Y90_incr_waddr;
	wire [ADDR_WIDTH-1:0] X206_Y90_waddr;
	assign X206_Y90_waddr = X207_Y90_waddr;
	wire X206_Y89_incr_raddr;
	assign X206_Y89_incr_raddr = X207_Y90_incr_raddr;
	wire [ADDR_WIDTH-1:0] X206_Y89_raddr;
	assign X206_Y89_raddr = X207_Y90_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X207_Y90(.clk(bus_clock),
		.incr_waddr(X207_Y90_incr_waddr),
		.waddr(X207_Y90_waddr),
		.incr_raddr(X207_Y90_incr_raddr),
		.raddr(X207_Y90_raddr));


	/* generated from E@X83_Y89@{W[1][6],W[1][5]}@1 */

	logic [DATA_WIDTH-1:0] X83_Y89_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X83_Y89_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) west_to_east_sector_size_1_west_to_east_ip_size_5_bus_first_egress_fifo(.clock(bus_clock),
		.in(X83_Y89_bus_rdata_in),
		.out(X83_Y89_bus_rdata_out));

	assign east_out_reg[1][6][10:0] = X83_Y89_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][5][10:2] = X83_Y89_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X83_Y89(.data(/* from design */),
		.q(X83_Y89_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X83_Y89_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X98_Y89@{S[0][23],S[0][24]}@2 */

	logic X98_Y89_incr_waddr; // ingress control
	logic X98_Y89_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_24_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][24][0]),
		.out(X98_Y89_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_24_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][24][1]),
		.out(X98_Y89_incr_raddr));

	logic [ADDR_WIDTH-1:0] X98_Y89_waddr;
	logic [ADDR_WIDTH-1:0] X98_Y89_raddr;

	/* positional aliases */

	wire X99_Y89_incr_waddr;
	assign X99_Y89_incr_waddr = X98_Y89_incr_waddr;
	wire [ADDR_WIDTH-1:0] X99_Y89_waddr;
	assign X99_Y89_waddr = X98_Y89_waddr;
	wire X99_Y90_incr_raddr;
	assign X99_Y90_incr_raddr = X98_Y89_incr_raddr;
	wire [ADDR_WIDTH-1:0] X99_Y90_raddr;
	assign X99_Y90_raddr = X98_Y89_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X98_Y89(.clk(bus_clock),
		.incr_waddr(X98_Y89_incr_waddr),
		.waddr(X98_Y89_waddr),
		.incr_raddr(X98_Y89_incr_raddr),
		.raddr(X98_Y89_raddr));


	/* generated from I@X99_Y89@{S[0][24],S[0][25]}@2 */

	logic [DATA_WIDTH-1:0] X99_Y89_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_25_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][24][10:0], south_in_reg[0][25][10:2]}),
		.out(X99_Y89_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X99_Y89(.data(X99_Y89_bus_wdata),
		.q(/* to design */),
		.wraddress(X99_Y89_waddr),
		.rdaddress(/* from design */),
		.wren(X99_Y89_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X101_Y89@{N[0][26],N[0][27]}@4 */

	logic [DATA_WIDTH-1:0] X101_Y89_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X101_Y89_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_27_bus_first_egress_fifo(.clock(bus_clock),
		.in(X101_Y89_bus_rdata_in),
		.out(X101_Y89_bus_rdata_out));

	assign south_out_reg[0][26][10:0] = X101_Y89_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][27][10:2] = X101_Y89_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X101_Y89(.data(/* from design */),
		.q(X101_Y89_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X101_Y89_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X109_Y89@{S[0][31],S[0][32]}@2 */

	logic X109_Y89_incr_waddr; // ingress control
	logic X109_Y89_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_32_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][32][0]),
		.out(X109_Y89_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_32_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][32][1]),
		.out(X109_Y89_incr_raddr));

	logic [ADDR_WIDTH-1:0] X109_Y89_waddr;
	logic [ADDR_WIDTH-1:0] X109_Y89_raddr;

	/* positional aliases */

	wire X110_Y89_incr_waddr;
	assign X110_Y89_incr_waddr = X109_Y89_incr_waddr;
	wire [ADDR_WIDTH-1:0] X110_Y89_waddr;
	assign X110_Y89_waddr = X109_Y89_waddr;
	wire X110_Y90_incr_raddr;
	assign X110_Y90_incr_raddr = X109_Y89_incr_raddr;
	wire [ADDR_WIDTH-1:0] X110_Y90_raddr;
	assign X110_Y90_raddr = X109_Y89_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X109_Y89(.clk(bus_clock),
		.incr_waddr(X109_Y89_incr_waddr),
		.waddr(X109_Y89_waddr),
		.incr_raddr(X109_Y89_incr_raddr),
		.raddr(X109_Y89_raddr));


	/* generated from I@X110_Y89@{S[0][32],S[0][33]}@2 */

	logic [DATA_WIDTH-1:0] X110_Y89_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_0_south_to_north_ip_size_33_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][32][10:0], south_in_reg[0][33][10:2]}),
		.out(X110_Y89_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X110_Y89(.data(X110_Y89_bus_wdata),
		.q(/* to design */),
		.wraddress(X110_Y89_waddr),
		.rdaddress(/* from design */),
		.wren(X110_Y89_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X112_Y89@{N[0][34],N[0][35]}@4 */

	logic [DATA_WIDTH-1:0] X112_Y89_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X112_Y89_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_0_north_to_south_ip_size_35_bus_first_egress_fifo(.clock(bus_clock),
		.in(X112_Y89_bus_rdata_in),
		.out(X112_Y89_bus_rdata_out));

	assign south_out_reg[0][34][10:0] = X112_Y89_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][35][10:2] = X112_Y89_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X112_Y89(.data(/* from design */),
		.q(X112_Y89_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X112_Y89_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X185_Y89@{E[1][6],E[1][5]}@3 */

	logic [DATA_WIDTH-1:0] X185_Y89_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X185_Y89_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) east_to_west_sector_size_1_east_to_west_ip_size_5_bus_first_egress_fifo(.clock(bus_clock),
		.in(X185_Y89_bus_rdata_in),
		.out(X185_Y89_bus_rdata_out));

	assign west_out_reg[1][6][10:0] = X185_Y89_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][5][10:2] = X185_Y89_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X185_Y89(.data(/* from design */),
		.q(X185_Y89_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X185_Y89_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X204_Y89@{S[2][25],S[2][24]}@2 */

	logic [DATA_WIDTH-1:0] X204_Y89_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_24_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][25][10:0], south_in_reg[2][24][10:2]}),
		.out(X204_Y89_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X204_Y89(.data(X204_Y89_bus_wdata),
		.q(/* to design */),
		.wraddress(X204_Y89_waddr),
		.rdaddress(/* from design */),
		.wren(X204_Y89_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X205_Y89@{S[2][26],S[2][25]}@2 */

	logic X205_Y89_incr_waddr; // ingress control
	logic X205_Y89_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_25_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[2][26][0]),
		.out(X205_Y89_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) south_to_north_sector_size_2_south_to_north_ip_size_25_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[2][26][1]),
		.out(X205_Y89_incr_raddr));

	logic [ADDR_WIDTH-1:0] X205_Y89_waddr;
	logic [ADDR_WIDTH-1:0] X205_Y89_raddr;

	/* positional aliases */

	wire X204_Y89_incr_waddr;
	assign X204_Y89_incr_waddr = X205_Y89_incr_waddr;
	wire [ADDR_WIDTH-1:0] X204_Y89_waddr;
	assign X204_Y89_waddr = X205_Y89_waddr;
	wire X204_Y90_incr_raddr;
	assign X204_Y90_incr_raddr = X205_Y89_incr_raddr;
	wire [ADDR_WIDTH-1:0] X204_Y90_raddr;
	assign X204_Y90_raddr = X205_Y89_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X205_Y89(.clk(bus_clock),
		.incr_waddr(X205_Y89_incr_waddr),
		.waddr(X205_Y89_waddr),
		.incr_raddr(X205_Y89_incr_raddr),
		.raddr(X205_Y89_raddr));


	/* generated from E@X206_Y89@{N[2][27],N[2][26]}@4 */

	logic [DATA_WIDTH-1:0] X206_Y89_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X206_Y89_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) north_to_south_sector_size_2_north_to_south_ip_size_26_bus_first_egress_fifo(.clock(bus_clock),
		.in(X206_Y89_bus_rdata_in),
		.out(X206_Y89_bus_rdata_out));

	assign south_out_reg[2][27][10:0] = X206_Y89_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][26][10:2] = X206_Y89_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X206_Y89(.data(/* from design */),
		.q(X206_Y89_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X206_Y89_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X132_Y88@{E[1][4],E[1][3]}@4 */

	logic [DATA_WIDTH-1:0] X132_Y88_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_1_east_to_west_ip_size_3_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][4][10:0], east_in_reg[1][3][10:2]}),
		.out(X132_Y88_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X132_Y88(.data(X132_Y88_bus_wdata),
		.q(/* to design */),
		.wraddress(X132_Y88_waddr),
		.rdaddress(/* from design */),
		.wren(X132_Y88_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X133_Y88@{E[1][4],E[1][3]}@4 */

	logic X133_Y88_incr_waddr; // ingress control
	logic X133_Y88_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_1_east_to_west_ip_size_3_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][3][0]),
		.out(X133_Y88_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_1_east_to_west_ip_size_3_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][3][1]),
		.out(X133_Y88_incr_raddr));

	logic [ADDR_WIDTH-1:0] X133_Y88_waddr;
	logic [ADDR_WIDTH-1:0] X133_Y88_raddr;

	/* positional aliases */

	wire X132_Y88_incr_waddr;
	assign X132_Y88_incr_waddr = X133_Y88_incr_waddr;
	wire [ADDR_WIDTH-1:0] X132_Y88_waddr;
	assign X132_Y88_waddr = X133_Y88_waddr;
	wire X132_Y87_incr_raddr;
	assign X132_Y87_incr_raddr = X133_Y88_incr_raddr;
	wire [ADDR_WIDTH-1:0] X132_Y87_raddr;
	assign X132_Y87_raddr = X133_Y88_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X133_Y88(.clk(bus_clock),
		.incr_waddr(X133_Y88_incr_waddr),
		.waddr(X133_Y88_waddr),
		.incr_raddr(X133_Y88_incr_raddr),
		.raddr(X133_Y88_raddr));


	/* generated from C@X259_Y88@{W[1][4],W[1][3]}@5 */

	logic X259_Y88_incr_waddr; // ingress control
	logic X259_Y88_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) west_to_east_sector_size_1_west_to_east_ip_size_3_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][4][0]),
		.out(X259_Y88_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) west_to_east_sector_size_1_west_to_east_ip_size_3_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][4][1]),
		.out(X259_Y88_incr_raddr));

	logic [ADDR_WIDTH-1:0] X259_Y88_waddr;
	logic [ADDR_WIDTH-1:0] X259_Y88_raddr;

	/* positional aliases */

	wire X260_Y88_incr_waddr;
	assign X260_Y88_incr_waddr = X259_Y88_incr_waddr;
	wire [ADDR_WIDTH-1:0] X260_Y88_waddr;
	assign X260_Y88_waddr = X259_Y88_waddr;
	wire X260_Y87_incr_raddr;
	assign X260_Y87_incr_raddr = X259_Y88_incr_raddr;
	wire [ADDR_WIDTH-1:0] X260_Y87_raddr;
	assign X260_Y87_raddr = X259_Y88_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X259_Y88(.clk(bus_clock),
		.incr_waddr(X259_Y88_incr_waddr),
		.waddr(X259_Y88_waddr),
		.incr_raddr(X259_Y88_incr_raddr),
		.raddr(X259_Y88_raddr));


	/* generated from I@X260_Y88@{W[1][4],W[1][3]}@5 */

	logic [DATA_WIDTH-1:0] X260_Y88_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) west_to_east_sector_size_1_west_to_east_ip_size_3_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][4][10:0], west_in_reg[1][3][10:2]}),
		.out(X260_Y88_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X260_Y88(.data(X260_Y88_bus_wdata),
		.q(/* to design */),
		.wraddress(X260_Y88_waddr),
		.rdaddress(/* from design */),
		.wren(X260_Y88_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X132_Y87@{E[1][4],E[1][3]}@5 */

	logic [DATA_WIDTH-1:0] X132_Y87_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X132_Y87_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_1_east_to_west_ip_size_3_bus_first_egress_fifo(.clock(bus_clock),
		.in(X132_Y87_bus_rdata_in),
		.out(X132_Y87_bus_rdata_out));

	assign west_out_reg[1][4][10:0] = X132_Y87_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][3][10:2] = X132_Y87_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X132_Y87(.data(/* from design */),
		.q(X132_Y87_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X132_Y87_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X260_Y87@{W[1][4],W[1][3]}@6 */

	logic [DATA_WIDTH-1:0] X260_Y87_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X260_Y87_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) west_to_east_sector_size_1_west_to_east_ip_size_3_bus_first_egress_fifo(.clock(bus_clock),
		.in(X260_Y87_bus_rdata_in),
		.out(X260_Y87_bus_rdata_out));

	assign east_out_reg[1][4][10:0] = X260_Y87_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][3][10:2] = X260_Y87_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X260_Y87(.data(/* from design */),
		.q(X260_Y87_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X260_Y87_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X131_Y86@{W[1][2],W[1][1]}@1 */

	logic X131_Y86_incr_waddr; // ingress control
	logic X131_Y86_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_1_west_to_east_ip_size_1_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[1][1][0]),
		.out(X131_Y86_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_1_west_to_east_ip_size_1_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[1][1][1]),
		.out(X131_Y86_incr_raddr));

	logic [ADDR_WIDTH-1:0] X131_Y86_waddr;
	logic [ADDR_WIDTH-1:0] X131_Y86_raddr;

	/* positional aliases */

	wire X132_Y86_incr_waddr;
	assign X132_Y86_incr_waddr = X131_Y86_incr_waddr;
	wire [ADDR_WIDTH-1:0] X132_Y86_waddr;
	assign X132_Y86_waddr = X131_Y86_waddr;
	wire X132_Y85_incr_raddr;
	assign X132_Y85_incr_raddr = X131_Y86_incr_raddr;
	wire [ADDR_WIDTH-1:0] X132_Y85_raddr;
	assign X132_Y85_raddr = X131_Y86_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X131_Y86(.clk(bus_clock),
		.incr_waddr(X131_Y86_incr_waddr),
		.waddr(X131_Y86_waddr),
		.incr_raddr(X131_Y86_incr_raddr),
		.raddr(X131_Y86_raddr));


	/* generated from I@X132_Y86@{W[1][2],W[1][1]}@1 */

	logic [DATA_WIDTH-1:0] X132_Y86_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_1_west_to_east_ip_size_1_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[1][2][10:0], west_in_reg[1][1][10:2]}),
		.out(X132_Y86_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X132_Y86(.data(X132_Y86_bus_wdata),
		.q(/* to design */),
		.wraddress(X132_Y86_waddr),
		.rdaddress(/* from design */),
		.wren(X132_Y86_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from I@X260_Y86@{E[1][2],E[1][1]}@0 */

	logic [DATA_WIDTH-1:0] X260_Y86_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) east_to_west_sector_size_1_east_to_west_ip_size_1_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[1][2][10:0], east_in_reg[1][1][10:2]}),
		.out(X260_Y86_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X260_Y86(.data(X260_Y86_bus_wdata),
		.q(/* to design */),
		.wraddress(X260_Y86_waddr),
		.rdaddress(/* from design */),
		.wren(X260_Y86_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X261_Y86@{E[1][2],E[1][1]}@0 */

	logic X261_Y86_incr_waddr; // ingress control
	logic X261_Y86_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) east_to_west_sector_size_1_east_to_west_ip_size_1_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[1][2][0]),
		.out(X261_Y86_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) east_to_west_sector_size_1_east_to_west_ip_size_1_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[1][2][1]),
		.out(X261_Y86_incr_raddr));

	logic [ADDR_WIDTH-1:0] X261_Y86_waddr;
	logic [ADDR_WIDTH-1:0] X261_Y86_raddr;

	/* positional aliases */

	wire X260_Y86_incr_waddr;
	assign X260_Y86_incr_waddr = X261_Y86_incr_waddr;
	wire [ADDR_WIDTH-1:0] X260_Y86_waddr;
	assign X260_Y86_waddr = X261_Y86_waddr;
	wire X260_Y85_incr_raddr;
	assign X260_Y85_incr_raddr = X261_Y86_incr_raddr;
	wire [ADDR_WIDTH-1:0] X260_Y85_raddr;
	assign X260_Y85_raddr = X261_Y86_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X261_Y86(.clk(bus_clock),
		.incr_waddr(X261_Y86_incr_waddr),
		.waddr(X261_Y86_waddr),
		.incr_raddr(X261_Y86_incr_raddr),
		.raddr(X261_Y86_raddr));


	/* generated from E@X132_Y85@{W[1][2],W[1][1]}@2 */

	logic [DATA_WIDTH-1:0] X132_Y85_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X132_Y85_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_1_west_to_east_ip_size_1_bus_first_egress_fifo(.clock(bus_clock),
		.in(X132_Y85_bus_rdata_in),
		.out(X132_Y85_bus_rdata_out));

	assign east_out_reg[1][2][10:0] = X132_Y85_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[1][1][10:2] = X132_Y85_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X132_Y85(.data(/* from design */),
		.q(X132_Y85_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X132_Y85_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X260_Y85@{E[1][2],E[1][1]}@1 */

	logic [DATA_WIDTH-1:0] X260_Y85_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X260_Y85_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) east_to_west_sector_size_1_east_to_west_ip_size_1_bus_first_egress_fifo(.clock(bus_clock),
		.in(X260_Y85_bus_rdata_in),
		.out(X260_Y85_bus_rdata_out));

	assign west_out_reg[1][2][10:0] = X260_Y85_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[1][1][10:2] = X260_Y85_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X260_Y85(.data(/* from design */),
		.q(X260_Y85_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X260_Y85_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X104_Y83@{E[0][40],E[0][39]}@4 */

	logic [DATA_WIDTH-1:0] X104_Y83_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_39_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][40][10:0], east_in_reg[0][39][10:2]}),
		.out(X104_Y83_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X104_Y83(.data(X104_Y83_bus_wdata),
		.q(/* to design */),
		.wraddress(X104_Y83_waddr),
		.rdaddress(/* from design */),
		.wren(X104_Y83_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X105_Y83@{E[0][40],E[0][39]}@4 */

	logic X105_Y83_incr_waddr; // ingress control
	logic X105_Y83_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_39_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][39][0]),
		.out(X105_Y83_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_39_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][39][1]),
		.out(X105_Y83_incr_raddr));

	logic [ADDR_WIDTH-1:0] X105_Y83_waddr;
	logic [ADDR_WIDTH-1:0] X105_Y83_raddr;

	/* positional aliases */

	wire X104_Y83_incr_waddr;
	assign X104_Y83_incr_waddr = X105_Y83_incr_waddr;
	wire [ADDR_WIDTH-1:0] X104_Y83_waddr;
	assign X104_Y83_waddr = X105_Y83_waddr;
	wire X104_Y82_incr_raddr;
	assign X104_Y82_incr_raddr = X105_Y83_incr_raddr;
	wire [ADDR_WIDTH-1:0] X104_Y82_raddr;
	assign X104_Y82_raddr = X105_Y83_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X105_Y83(.clk(bus_clock),
		.incr_waddr(X105_Y83_incr_waddr),
		.waddr(X105_Y83_waddr),
		.incr_raddr(X105_Y83_incr_raddr),
		.raddr(X105_Y83_raddr));


	/* generated from C@X205_Y83@{W[0][40],W[0][39]}@3 */

	logic X205_Y83_incr_waddr; // ingress control
	logic X205_Y83_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_0_west_to_east_ip_size_39_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][40][0]),
		.out(X205_Y83_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_0_west_to_east_ip_size_39_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][40][1]),
		.out(X205_Y83_incr_raddr));

	logic [ADDR_WIDTH-1:0] X205_Y83_waddr;
	logic [ADDR_WIDTH-1:0] X205_Y83_raddr;

	/* positional aliases */

	wire X206_Y83_incr_waddr;
	assign X206_Y83_incr_waddr = X205_Y83_incr_waddr;
	wire [ADDR_WIDTH-1:0] X206_Y83_waddr;
	assign X206_Y83_waddr = X205_Y83_waddr;
	wire X206_Y82_incr_raddr;
	assign X206_Y82_incr_raddr = X205_Y83_incr_raddr;
	wire [ADDR_WIDTH-1:0] X206_Y82_raddr;
	assign X206_Y82_raddr = X205_Y83_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X205_Y83(.clk(bus_clock),
		.incr_waddr(X205_Y83_incr_waddr),
		.waddr(X205_Y83_waddr),
		.incr_raddr(X205_Y83_incr_raddr),
		.raddr(X205_Y83_raddr));


	/* generated from I@X206_Y83@{W[0][40],W[0][39]}@4 */

	logic [DATA_WIDTH-1:0] X206_Y83_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_0_west_to_east_ip_size_39_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][40][10:0], west_in_reg[0][39][10:2]}),
		.out(X206_Y83_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X206_Y83(.data(X206_Y83_bus_wdata),
		.q(/* to design */),
		.wraddress(X206_Y83_waddr),
		.rdaddress(/* from design */),
		.wren(X206_Y83_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X104_Y82@{E[0][40],E[0][39]}@5 */

	logic [DATA_WIDTH-1:0] X104_Y82_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X104_Y82_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_39_bus_first_egress_fifo(.clock(bus_clock),
		.in(X104_Y82_bus_rdata_in),
		.out(X104_Y82_bus_rdata_out));

	assign west_out_reg[0][40][10:0] = X104_Y82_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][39][10:2] = X104_Y82_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X104_Y82(.data(/* from design */),
		.q(X104_Y82_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X104_Y82_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X206_Y82@{W[0][40],W[0][39]}@5 */

	logic [DATA_WIDTH-1:0] X206_Y82_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X206_Y82_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_39_bus_first_egress_fifo(.clock(bus_clock),
		.in(X206_Y82_bus_rdata_in),
		.out(X206_Y82_bus_rdata_out));

	assign east_out_reg[0][40][10:0] = X206_Y82_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][39][10:2] = X206_Y82_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X206_Y82(.data(/* from design */),
		.q(X206_Y82_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X206_Y82_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X103_Y81@{W[0][38],W[0][37]}@1 */

	logic X103_Y81_incr_waddr; // ingress control
	logic X103_Y81_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_37_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][37][0]),
		.out(X103_Y81_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_37_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][37][1]),
		.out(X103_Y81_incr_raddr));

	logic [ADDR_WIDTH-1:0] X103_Y81_waddr;
	logic [ADDR_WIDTH-1:0] X103_Y81_raddr;

	/* positional aliases */

	wire X104_Y81_incr_waddr;
	assign X104_Y81_incr_waddr = X103_Y81_incr_waddr;
	wire [ADDR_WIDTH-1:0] X104_Y81_waddr;
	assign X104_Y81_waddr = X103_Y81_waddr;
	wire X104_Y80_incr_raddr;
	assign X104_Y80_incr_raddr = X103_Y81_incr_raddr;
	wire [ADDR_WIDTH-1:0] X104_Y80_raddr;
	assign X104_Y80_raddr = X103_Y81_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X103_Y81(.clk(bus_clock),
		.incr_waddr(X103_Y81_incr_waddr),
		.waddr(X103_Y81_waddr),
		.incr_raddr(X103_Y81_incr_raddr),
		.raddr(X103_Y81_raddr));


	/* generated from I@X104_Y81@{W[0][38],W[0][37]}@1 */

	logic [DATA_WIDTH-1:0] X104_Y81_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_37_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][38][10:0], west_in_reg[0][37][10:2]}),
		.out(X104_Y81_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X104_Y81(.data(X104_Y81_bus_wdata),
		.q(/* to design */),
		.wraddress(X104_Y81_waddr),
		.rdaddress(/* from design */),
		.wren(X104_Y81_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from I@X206_Y81@{E[0][38],E[0][37]}@1 */

	logic [DATA_WIDTH-1:0] X206_Y81_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_37_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][38][10:0], east_in_reg[0][37][10:2]}),
		.out(X206_Y81_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X206_Y81(.data(X206_Y81_bus_wdata),
		.q(/* to design */),
		.wraddress(X206_Y81_waddr),
		.rdaddress(/* from design */),
		.wren(X206_Y81_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X207_Y81@{E[0][38],E[0][37]}@1 */

	logic X207_Y81_incr_waddr; // ingress control
	logic X207_Y81_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_37_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][38][0]),
		.out(X207_Y81_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_37_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][38][1]),
		.out(X207_Y81_incr_raddr));

	logic [ADDR_WIDTH-1:0] X207_Y81_waddr;
	logic [ADDR_WIDTH-1:0] X207_Y81_raddr;

	/* positional aliases */

	wire X206_Y81_incr_waddr;
	assign X206_Y81_incr_waddr = X207_Y81_incr_waddr;
	wire [ADDR_WIDTH-1:0] X206_Y81_waddr;
	assign X206_Y81_waddr = X207_Y81_waddr;
	wire X206_Y80_incr_raddr;
	assign X206_Y80_incr_raddr = X207_Y81_incr_raddr;
	wire [ADDR_WIDTH-1:0] X206_Y80_raddr;
	assign X206_Y80_raddr = X207_Y81_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X207_Y81(.clk(bus_clock),
		.incr_waddr(X207_Y81_incr_waddr),
		.waddr(X207_Y81_waddr),
		.incr_raddr(X207_Y81_incr_raddr),
		.raddr(X207_Y81_raddr));


	/* generated from E@X104_Y80@{W[0][38],W[0][37]}@2 */

	logic [DATA_WIDTH-1:0] X104_Y80_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X104_Y80_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_0_west_to_east_ip_size_37_bus_first_egress_fifo(.clock(bus_clock),
		.in(X104_Y80_bus_rdata_in),
		.out(X104_Y80_bus_rdata_out));

	assign east_out_reg[0][38][10:0] = X104_Y80_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][37][10:2] = X104_Y80_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X104_Y80(.data(/* from design */),
		.q(X104_Y80_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X104_Y80_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X206_Y80@{E[0][38],E[0][37]}@2 */

	logic [DATA_WIDTH-1:0] X206_Y80_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X206_Y80_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_37_bus_first_egress_fifo(.clock(bus_clock),
		.in(X206_Y80_bus_rdata_in),
		.out(X206_Y80_bus_rdata_out));

	assign west_out_reg[0][38][10:0] = X206_Y80_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][37][10:2] = X206_Y80_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X206_Y80(.data(/* from design */),
		.q(X206_Y80_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X206_Y80_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X153_Y79@{E[0][36],E[0][35]}@3 */

	logic [DATA_WIDTH-1:0] X153_Y79_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) east_to_west_sector_size_0_east_to_west_ip_size_35_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][36][10:0], east_in_reg[0][35][10:2]}),
		.out(X153_Y79_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X153_Y79(.data(X153_Y79_bus_wdata),
		.q(/* to design */),
		.wraddress(X153_Y79_waddr),
		.rdaddress(/* from design */),
		.wren(X153_Y79_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X154_Y79@{E[0][36],E[0][35]}@3 */

	logic X154_Y79_incr_waddr; // ingress control
	logic X154_Y79_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) east_to_west_sector_size_0_east_to_west_ip_size_35_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][35][0]),
		.out(X154_Y79_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) east_to_west_sector_size_0_east_to_west_ip_size_35_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][35][1]),
		.out(X154_Y79_incr_raddr));

	logic [ADDR_WIDTH-1:0] X154_Y79_waddr;
	logic [ADDR_WIDTH-1:0] X154_Y79_raddr;

	/* positional aliases */

	wire X153_Y79_incr_waddr;
	assign X153_Y79_incr_waddr = X154_Y79_incr_waddr;
	wire [ADDR_WIDTH-1:0] X153_Y79_waddr;
	assign X153_Y79_waddr = X154_Y79_waddr;
	wire X153_Y78_incr_raddr;
	assign X153_Y78_incr_raddr = X154_Y79_incr_raddr;
	wire [ADDR_WIDTH-1:0] X153_Y78_raddr;
	assign X153_Y78_raddr = X154_Y79_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X154_Y79(.clk(bus_clock),
		.incr_waddr(X154_Y79_incr_waddr),
		.waddr(X154_Y79_waddr),
		.incr_raddr(X154_Y79_incr_raddr),
		.raddr(X154_Y79_raddr));


	/* generated from C@X238_Y79@{W[0][36],W[0][35]}@4 */

	logic X238_Y79_incr_waddr; // ingress control
	logic X238_Y79_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) west_to_east_sector_size_0_west_to_east_ip_size_35_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][36][0]),
		.out(X238_Y79_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) west_to_east_sector_size_0_west_to_east_ip_size_35_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][36][1]),
		.out(X238_Y79_incr_raddr));

	logic [ADDR_WIDTH-1:0] X238_Y79_waddr;
	logic [ADDR_WIDTH-1:0] X238_Y79_raddr;

	/* positional aliases */

	wire X239_Y79_incr_waddr;
	assign X239_Y79_incr_waddr = X238_Y79_incr_waddr;
	wire [ADDR_WIDTH-1:0] X239_Y79_waddr;
	assign X239_Y79_waddr = X238_Y79_waddr;
	wire X239_Y78_incr_raddr;
	assign X239_Y78_incr_raddr = X238_Y79_incr_raddr;
	wire [ADDR_WIDTH-1:0] X239_Y78_raddr;
	assign X239_Y78_raddr = X238_Y79_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X238_Y79(.clk(bus_clock),
		.incr_waddr(X238_Y79_incr_waddr),
		.waddr(X238_Y79_waddr),
		.incr_raddr(X238_Y79_incr_raddr),
		.raddr(X238_Y79_raddr));


	/* generated from I@X239_Y79@{W[0][36],W[0][35]}@4 */

	logic [DATA_WIDTH-1:0] X239_Y79_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_0_west_to_east_ip_size_35_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][36][10:0], west_in_reg[0][35][10:2]}),
		.out(X239_Y79_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X239_Y79(.data(X239_Y79_bus_wdata),
		.q(/* to design */),
		.wraddress(X239_Y79_waddr),
		.rdaddress(/* from design */),
		.wren(X239_Y79_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X153_Y78@{E[0][36],E[0][35]}@4 */

	logic [DATA_WIDTH-1:0] X153_Y78_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X153_Y78_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) east_to_west_sector_size_0_east_to_west_ip_size_35_bus_first_egress_fifo(.clock(bus_clock),
		.in(X153_Y78_bus_rdata_in),
		.out(X153_Y78_bus_rdata_out));

	assign west_out_reg[0][36][10:0] = X153_Y78_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][35][10:2] = X153_Y78_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X153_Y78(.data(/* from design */),
		.q(X153_Y78_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X153_Y78_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X239_Y78@{W[0][36],W[0][35]}@5 */

	logic [DATA_WIDTH-1:0] X239_Y78_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X239_Y78_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_35_bus_first_egress_fifo(.clock(bus_clock),
		.in(X239_Y78_bus_rdata_in),
		.out(X239_Y78_bus_rdata_out));

	assign east_out_reg[0][36][10:0] = X239_Y78_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][35][10:2] = X239_Y78_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X239_Y78(.data(/* from design */),
		.q(X239_Y78_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X239_Y78_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X152_Y77@{W[0][34],W[0][33]}@2 */

	logic X152_Y77_incr_waddr; // ingress control
	logic X152_Y77_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) west_to_east_sector_size_0_west_to_east_ip_size_33_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][33][0]),
		.out(X152_Y77_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) west_to_east_sector_size_0_west_to_east_ip_size_33_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][33][1]),
		.out(X152_Y77_incr_raddr));

	logic [ADDR_WIDTH-1:0] X152_Y77_waddr;
	logic [ADDR_WIDTH-1:0] X152_Y77_raddr;

	/* positional aliases */

	wire X153_Y77_incr_waddr;
	assign X153_Y77_incr_waddr = X152_Y77_incr_waddr;
	wire [ADDR_WIDTH-1:0] X153_Y77_waddr;
	assign X153_Y77_waddr = X152_Y77_waddr;
	wire X153_Y76_incr_raddr;
	assign X153_Y76_incr_raddr = X152_Y77_incr_raddr;
	wire [ADDR_WIDTH-1:0] X153_Y76_raddr;
	assign X153_Y76_raddr = X152_Y77_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X152_Y77(.clk(bus_clock),
		.incr_waddr(X152_Y77_incr_waddr),
		.waddr(X152_Y77_waddr),
		.incr_raddr(X152_Y77_incr_raddr),
		.raddr(X152_Y77_raddr));


	/* generated from I@X153_Y77@{W[0][34],W[0][33]}@2 */

	logic [DATA_WIDTH-1:0] X153_Y77_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) west_to_east_sector_size_0_west_to_east_ip_size_33_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][34][10:0], west_in_reg[0][33][10:2]}),
		.out(X153_Y77_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X153_Y77(.data(X153_Y77_bus_wdata),
		.q(/* to design */),
		.wraddress(X153_Y77_waddr),
		.rdaddress(/* from design */),
		.wren(X153_Y77_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from I@X239_Y77@{E[0][34],E[0][33]}@1 */

	logic [DATA_WIDTH-1:0] X239_Y77_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_33_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][34][10:0], east_in_reg[0][33][10:2]}),
		.out(X239_Y77_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X239_Y77(.data(X239_Y77_bus_wdata),
		.q(/* to design */),
		.wraddress(X239_Y77_waddr),
		.rdaddress(/* from design */),
		.wren(X239_Y77_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X240_Y77@{E[0][34],E[0][33]}@1 */

	logic X240_Y77_incr_waddr; // ingress control
	logic X240_Y77_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_33_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][34][0]),
		.out(X240_Y77_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_33_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][34][1]),
		.out(X240_Y77_incr_raddr));

	logic [ADDR_WIDTH-1:0] X240_Y77_waddr;
	logic [ADDR_WIDTH-1:0] X240_Y77_raddr;

	/* positional aliases */

	wire X239_Y77_incr_waddr;
	assign X239_Y77_incr_waddr = X240_Y77_incr_waddr;
	wire [ADDR_WIDTH-1:0] X239_Y77_waddr;
	assign X239_Y77_waddr = X240_Y77_waddr;
	wire X239_Y76_incr_raddr;
	assign X239_Y76_incr_raddr = X240_Y77_incr_raddr;
	wire [ADDR_WIDTH-1:0] X239_Y76_raddr;
	assign X239_Y76_raddr = X240_Y77_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X240_Y77(.clk(bus_clock),
		.incr_waddr(X240_Y77_incr_waddr),
		.waddr(X240_Y77_waddr),
		.incr_raddr(X240_Y77_incr_raddr),
		.raddr(X240_Y77_raddr));


	/* generated from E@X153_Y76@{W[0][34],W[0][33]}@3 */

	logic [DATA_WIDTH-1:0] X153_Y76_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X153_Y76_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) west_to_east_sector_size_0_west_to_east_ip_size_33_bus_first_egress_fifo(.clock(bus_clock),
		.in(X153_Y76_bus_rdata_in),
		.out(X153_Y76_bus_rdata_out));

	assign east_out_reg[0][34][10:0] = X153_Y76_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][33][10:2] = X153_Y76_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X153_Y76(.data(/* from design */),
		.q(X153_Y76_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X153_Y76_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X239_Y76@{E[0][34],E[0][33]}@2 */

	logic [DATA_WIDTH-1:0] X239_Y76_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X239_Y76_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_33_bus_first_egress_fifo(.clock(bus_clock),
		.in(X239_Y76_bus_rdata_in),
		.out(X239_Y76_bus_rdata_out));

	assign west_out_reg[0][34][10:0] = X239_Y76_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][33][10:2] = X239_Y76_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X239_Y76(.data(/* from design */),
		.q(X239_Y76_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X239_Y76_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X83_Y75@{E[0][32],E[0][31]}@5 */

	logic [DATA_WIDTH-1:0] X83_Y75_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) east_to_west_sector_size_0_east_to_west_ip_size_31_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][32][10:0], east_in_reg[0][31][10:2]}),
		.out(X83_Y75_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X83_Y75(.data(X83_Y75_bus_wdata),
		.q(/* to design */),
		.wraddress(X83_Y75_waddr),
		.rdaddress(/* from design */),
		.wren(X83_Y75_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X84_Y75@{E[0][32],E[0][31]}@5 */

	logic X84_Y75_incr_waddr; // ingress control
	logic X84_Y75_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) east_to_west_sector_size_0_east_to_west_ip_size_31_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][31][0]),
		.out(X84_Y75_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) east_to_west_sector_size_0_east_to_west_ip_size_31_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][31][1]),
		.out(X84_Y75_incr_raddr));

	logic [ADDR_WIDTH-1:0] X84_Y75_waddr;
	logic [ADDR_WIDTH-1:0] X84_Y75_raddr;

	/* positional aliases */

	wire X83_Y75_incr_waddr;
	assign X83_Y75_incr_waddr = X84_Y75_incr_waddr;
	wire [ADDR_WIDTH-1:0] X83_Y75_waddr;
	assign X83_Y75_waddr = X84_Y75_waddr;
	wire X83_Y74_incr_raddr;
	assign X83_Y74_incr_raddr = X84_Y75_incr_raddr;
	wire [ADDR_WIDTH-1:0] X83_Y74_raddr;
	assign X83_Y74_raddr = X84_Y75_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X84_Y75(.clk(bus_clock),
		.incr_waddr(X84_Y75_incr_waddr),
		.waddr(X84_Y75_waddr),
		.incr_raddr(X84_Y75_incr_raddr),
		.raddr(X84_Y75_raddr));


	/* generated from C@X184_Y75@{W[0][32],W[0][31]}@3 */

	logic X184_Y75_incr_waddr; // ingress control
	logic X184_Y75_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_0_west_to_east_ip_size_31_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][32][0]),
		.out(X184_Y75_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_0_west_to_east_ip_size_31_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][32][1]),
		.out(X184_Y75_incr_raddr));

	logic [ADDR_WIDTH-1:0] X184_Y75_waddr;
	logic [ADDR_WIDTH-1:0] X184_Y75_raddr;

	/* positional aliases */

	wire X185_Y75_incr_waddr;
	assign X185_Y75_incr_waddr = X184_Y75_incr_waddr;
	wire [ADDR_WIDTH-1:0] X185_Y75_waddr;
	assign X185_Y75_waddr = X184_Y75_waddr;
	wire X185_Y74_incr_raddr;
	assign X185_Y74_incr_raddr = X184_Y75_incr_raddr;
	wire [ADDR_WIDTH-1:0] X185_Y74_raddr;
	assign X185_Y74_raddr = X184_Y75_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X184_Y75(.clk(bus_clock),
		.incr_waddr(X184_Y75_incr_waddr),
		.waddr(X184_Y75_waddr),
		.incr_raddr(X184_Y75_incr_raddr),
		.raddr(X184_Y75_raddr));


	/* generated from I@X185_Y75@{W[0][32],W[0][31]}@3 */

	logic [DATA_WIDTH-1:0] X185_Y75_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) west_to_east_sector_size_0_west_to_east_ip_size_31_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][32][10:0], west_in_reg[0][31][10:2]}),
		.out(X185_Y75_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X185_Y75(.data(X185_Y75_bus_wdata),
		.q(/* to design */),
		.wraddress(X185_Y75_waddr),
		.rdaddress(/* from design */),
		.wren(X185_Y75_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X83_Y74@{E[0][32],E[0][31]}@6 */

	logic [DATA_WIDTH-1:0] X83_Y74_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X83_Y74_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) east_to_west_sector_size_0_east_to_west_ip_size_31_bus_first_egress_fifo(.clock(bus_clock),
		.in(X83_Y74_bus_rdata_in),
		.out(X83_Y74_bus_rdata_out));

	assign west_out_reg[0][32][10:0] = X83_Y74_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][31][10:2] = X83_Y74_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X83_Y74(.data(/* from design */),
		.q(X83_Y74_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X83_Y74_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X185_Y74@{W[0][32],W[0][31]}@4 */

	logic [DATA_WIDTH-1:0] X185_Y74_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X185_Y74_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) west_to_east_sector_size_0_west_to_east_ip_size_31_bus_first_egress_fifo(.clock(bus_clock),
		.in(X185_Y74_bus_rdata_in),
		.out(X185_Y74_bus_rdata_out));

	assign east_out_reg[0][32][10:0] = X185_Y74_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][31][10:2] = X185_Y74_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X185_Y74(.data(/* from design */),
		.q(X185_Y74_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X185_Y74_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X82_Y73@{W[0][30],W[0][29]}@0 */

	logic X82_Y73_incr_waddr; // ingress control
	logic X82_Y73_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) west_to_east_sector_size_0_west_to_east_ip_size_29_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][29][0]),
		.out(X82_Y73_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) west_to_east_sector_size_0_west_to_east_ip_size_29_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][29][1]),
		.out(X82_Y73_incr_raddr));

	logic [ADDR_WIDTH-1:0] X82_Y73_waddr;
	logic [ADDR_WIDTH-1:0] X82_Y73_raddr;

	/* positional aliases */

	wire X83_Y73_incr_waddr;
	assign X83_Y73_incr_waddr = X82_Y73_incr_waddr;
	wire [ADDR_WIDTH-1:0] X83_Y73_waddr;
	assign X83_Y73_waddr = X82_Y73_waddr;
	wire X83_Y72_incr_raddr;
	assign X83_Y72_incr_raddr = X82_Y73_incr_raddr;
	wire [ADDR_WIDTH-1:0] X83_Y72_raddr;
	assign X83_Y72_raddr = X82_Y73_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X82_Y73(.clk(bus_clock),
		.incr_waddr(X82_Y73_incr_waddr),
		.waddr(X82_Y73_waddr),
		.incr_raddr(X82_Y73_incr_raddr),
		.raddr(X82_Y73_raddr));


	/* generated from I@X83_Y73@{W[0][30],W[0][29]}@0 */

	logic [DATA_WIDTH-1:0] X83_Y73_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) west_to_east_sector_size_0_west_to_east_ip_size_29_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][30][10:0], west_in_reg[0][29][10:2]}),
		.out(X83_Y73_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X83_Y73(.data(X83_Y73_bus_wdata),
		.q(/* to design */),
		.wraddress(X83_Y73_waddr),
		.rdaddress(/* from design */),
		.wren(X83_Y73_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from I@X185_Y73@{E[0][30],E[0][29]}@2 */

	logic [DATA_WIDTH-1:0] X185_Y73_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) east_to_west_sector_size_0_east_to_west_ip_size_29_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][30][10:0], east_in_reg[0][29][10:2]}),
		.out(X185_Y73_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X185_Y73(.data(X185_Y73_bus_wdata),
		.q(/* to design */),
		.wraddress(X185_Y73_waddr),
		.rdaddress(/* from design */),
		.wren(X185_Y73_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X186_Y73@{E[0][30],E[0][29]}@2 */

	logic X186_Y73_incr_waddr; // ingress control
	logic X186_Y73_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) east_to_west_sector_size_0_east_to_west_ip_size_29_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][30][0]),
		.out(X186_Y73_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) east_to_west_sector_size_0_east_to_west_ip_size_29_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][30][1]),
		.out(X186_Y73_incr_raddr));

	logic [ADDR_WIDTH-1:0] X186_Y73_waddr;
	logic [ADDR_WIDTH-1:0] X186_Y73_raddr;

	/* positional aliases */

	wire X185_Y73_incr_waddr;
	assign X185_Y73_incr_waddr = X186_Y73_incr_waddr;
	wire [ADDR_WIDTH-1:0] X185_Y73_waddr;
	assign X185_Y73_waddr = X186_Y73_waddr;
	wire X185_Y72_incr_raddr;
	assign X185_Y72_incr_raddr = X186_Y73_incr_raddr;
	wire [ADDR_WIDTH-1:0] X185_Y72_raddr;
	assign X185_Y72_raddr = X186_Y73_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X186_Y73(.clk(bus_clock),
		.incr_waddr(X186_Y73_incr_waddr),
		.waddr(X186_Y73_waddr),
		.incr_raddr(X186_Y73_incr_raddr),
		.raddr(X186_Y73_raddr));


	/* generated from E@X83_Y72@{W[0][30],W[0][29]}@1 */

	logic [DATA_WIDTH-1:0] X83_Y72_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X83_Y72_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) west_to_east_sector_size_0_west_to_east_ip_size_29_bus_first_egress_fifo(.clock(bus_clock),
		.in(X83_Y72_bus_rdata_in),
		.out(X83_Y72_bus_rdata_out));

	assign east_out_reg[0][30][10:0] = X83_Y72_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][29][10:2] = X83_Y72_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X83_Y72(.data(/* from design */),
		.q(X83_Y72_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X83_Y72_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X185_Y72@{E[0][30],E[0][29]}@3 */

	logic [DATA_WIDTH-1:0] X185_Y72_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X185_Y72_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) east_to_west_sector_size_0_east_to_west_ip_size_29_bus_first_egress_fifo(.clock(bus_clock),
		.in(X185_Y72_bus_rdata_in),
		.out(X185_Y72_bus_rdata_out));

	assign west_out_reg[0][30][10:0] = X185_Y72_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][29][10:2] = X185_Y72_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X185_Y72(.data(/* from design */),
		.q(X185_Y72_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X185_Y72_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X132_Y71@{E[0][28],E[0][27]}@4 */

	logic [DATA_WIDTH-1:0] X132_Y71_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_27_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][28][10:0], east_in_reg[0][27][10:2]}),
		.out(X132_Y71_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X132_Y71(.data(X132_Y71_bus_wdata),
		.q(/* to design */),
		.wraddress(X132_Y71_waddr),
		.rdaddress(/* from design */),
		.wren(X132_Y71_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X133_Y71@{E[0][28],E[0][27]}@4 */

	logic X133_Y71_incr_waddr; // ingress control
	logic X133_Y71_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_27_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][27][0]),
		.out(X133_Y71_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_27_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][27][1]),
		.out(X133_Y71_incr_raddr));

	logic [ADDR_WIDTH-1:0] X133_Y71_waddr;
	logic [ADDR_WIDTH-1:0] X133_Y71_raddr;

	/* positional aliases */

	wire X132_Y71_incr_waddr;
	assign X132_Y71_incr_waddr = X133_Y71_incr_waddr;
	wire [ADDR_WIDTH-1:0] X132_Y71_waddr;
	assign X132_Y71_waddr = X133_Y71_waddr;
	wire X132_Y70_incr_raddr;
	assign X132_Y70_incr_raddr = X133_Y71_incr_raddr;
	wire [ADDR_WIDTH-1:0] X132_Y70_raddr;
	assign X132_Y70_raddr = X133_Y71_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X133_Y71(.clk(bus_clock),
		.incr_waddr(X133_Y71_incr_waddr),
		.waddr(X133_Y71_waddr),
		.incr_raddr(X133_Y71_incr_raddr),
		.raddr(X133_Y71_raddr));


	/* generated from C@X259_Y71@{W[0][28],W[0][27]}@5 */

	logic X259_Y71_incr_waddr; // ingress control
	logic X259_Y71_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) west_to_east_sector_size_0_west_to_east_ip_size_27_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][28][0]),
		.out(X259_Y71_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) west_to_east_sector_size_0_west_to_east_ip_size_27_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][28][1]),
		.out(X259_Y71_incr_raddr));

	logic [ADDR_WIDTH-1:0] X259_Y71_waddr;
	logic [ADDR_WIDTH-1:0] X259_Y71_raddr;

	/* positional aliases */

	wire X260_Y71_incr_waddr;
	assign X260_Y71_incr_waddr = X259_Y71_incr_waddr;
	wire [ADDR_WIDTH-1:0] X260_Y71_waddr;
	assign X260_Y71_waddr = X259_Y71_waddr;
	wire X260_Y70_incr_raddr;
	assign X260_Y70_incr_raddr = X259_Y71_incr_raddr;
	wire [ADDR_WIDTH-1:0] X260_Y70_raddr;
	assign X260_Y70_raddr = X259_Y71_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X259_Y71(.clk(bus_clock),
		.incr_waddr(X259_Y71_incr_waddr),
		.waddr(X259_Y71_waddr),
		.incr_raddr(X259_Y71_incr_raddr),
		.raddr(X259_Y71_raddr));


	/* generated from I@X260_Y71@{W[0][28],W[0][27]}@5 */

	logic [DATA_WIDTH-1:0] X260_Y71_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) west_to_east_sector_size_0_west_to_east_ip_size_27_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][28][10:0], west_in_reg[0][27][10:2]}),
		.out(X260_Y71_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X260_Y71(.data(X260_Y71_bus_wdata),
		.q(/* to design */),
		.wraddress(X260_Y71_waddr),
		.rdaddress(/* from design */),
		.wren(X260_Y71_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X132_Y70@{E[0][28],E[0][27]}@5 */

	logic [DATA_WIDTH-1:0] X132_Y70_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X132_Y70_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_27_bus_first_egress_fifo(.clock(bus_clock),
		.in(X132_Y70_bus_rdata_in),
		.out(X132_Y70_bus_rdata_out));

	assign west_out_reg[0][28][10:0] = X132_Y70_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][27][10:2] = X132_Y70_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X132_Y70(.data(/* from design */),
		.q(X132_Y70_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X132_Y70_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X260_Y70@{W[0][28],W[0][27]}@6 */

	logic [DATA_WIDTH-1:0] X260_Y70_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X260_Y70_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) west_to_east_sector_size_0_west_to_east_ip_size_27_bus_first_egress_fifo(.clock(bus_clock),
		.in(X260_Y70_bus_rdata_in),
		.out(X260_Y70_bus_rdata_out));

	assign east_out_reg[0][28][10:0] = X260_Y70_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][27][10:2] = X260_Y70_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X260_Y70(.data(/* from design */),
		.q(X260_Y70_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X260_Y70_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X131_Y69@{W[0][26],W[0][25]}@1 */

	logic X131_Y69_incr_waddr; // ingress control
	logic X131_Y69_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_25_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][25][0]),
		.out(X131_Y69_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_25_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][25][1]),
		.out(X131_Y69_incr_raddr));

	logic [ADDR_WIDTH-1:0] X131_Y69_waddr;
	logic [ADDR_WIDTH-1:0] X131_Y69_raddr;

	/* positional aliases */

	wire X132_Y69_incr_waddr;
	assign X132_Y69_incr_waddr = X131_Y69_incr_waddr;
	wire [ADDR_WIDTH-1:0] X132_Y69_waddr;
	assign X132_Y69_waddr = X131_Y69_waddr;
	wire X132_Y68_incr_raddr;
	assign X132_Y68_incr_raddr = X131_Y69_incr_raddr;
	wire [ADDR_WIDTH-1:0] X132_Y68_raddr;
	assign X132_Y68_raddr = X131_Y69_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X131_Y69(.clk(bus_clock),
		.incr_waddr(X131_Y69_incr_waddr),
		.waddr(X131_Y69_waddr),
		.incr_raddr(X131_Y69_incr_raddr),
		.raddr(X131_Y69_raddr));


	/* generated from I@X132_Y69@{W[0][26],W[0][25]}@1 */

	logic [DATA_WIDTH-1:0] X132_Y69_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_25_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][26][10:0], west_in_reg[0][25][10:2]}),
		.out(X132_Y69_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X132_Y69(.data(X132_Y69_bus_wdata),
		.q(/* to design */),
		.wraddress(X132_Y69_waddr),
		.rdaddress(/* from design */),
		.wren(X132_Y69_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X147_Y69@{S[1][20],S[1][21]}@2 */

	logic [DATA_WIDTH-1:0] X147_Y69_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X147_Y69_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_1_south_to_north_ip_size_21_bus_first_egress_fifo(.clock(bus_clock),
		.in(X147_Y69_bus_rdata_in),
		.out(X147_Y69_bus_rdata_out));

	assign north_out_reg[1][20][10:0] = X147_Y69_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][21][10:2] = X147_Y69_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X147_Y69(.data(/* from design */),
		.q(X147_Y69_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X147_Y69_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X148_Y69@{N[1][21],N[1][22]}@4 */

	logic X148_Y69_incr_waddr; // ingress control
	logic X148_Y69_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_1_north_to_south_ip_size_22_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][22][0]),
		.out(X148_Y69_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_1_north_to_south_ip_size_22_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][22][1]),
		.out(X148_Y69_incr_raddr));

	logic [ADDR_WIDTH-1:0] X148_Y69_waddr;
	logic [ADDR_WIDTH-1:0] X148_Y69_raddr;

	/* positional aliases */

	wire X149_Y69_incr_waddr;
	assign X149_Y69_incr_waddr = X148_Y69_incr_waddr;
	wire [ADDR_WIDTH-1:0] X149_Y69_waddr;
	assign X149_Y69_waddr = X148_Y69_waddr;
	wire X149_Y68_incr_raddr;
	assign X149_Y68_incr_raddr = X148_Y69_incr_raddr;
	wire [ADDR_WIDTH-1:0] X149_Y68_raddr;
	assign X149_Y68_raddr = X148_Y69_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X148_Y69(.clk(bus_clock),
		.incr_waddr(X148_Y69_incr_waddr),
		.waddr(X148_Y69_waddr),
		.incr_raddr(X148_Y69_incr_raddr),
		.raddr(X148_Y69_raddr));


	/* generated from I@X149_Y69@{N[1][22],N[1][23]}@4 */

	logic [DATA_WIDTH-1:0] X149_Y69_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_1_north_to_south_ip_size_23_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][22][10:0], north_in_reg[1][23][10:2]}),
		.out(X149_Y69_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X149_Y69(.data(X149_Y69_bus_wdata),
		.q(/* to design */),
		.wraddress(X149_Y69_waddr),
		.rdaddress(/* from design */),
		.wren(X149_Y69_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X158_Y69@{S[1][28],S[1][29]}@2 */

	logic [DATA_WIDTH-1:0] X158_Y69_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X158_Y69_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_1_south_to_north_ip_size_29_bus_first_egress_fifo(.clock(bus_clock),
		.in(X158_Y69_bus_rdata_in),
		.out(X158_Y69_bus_rdata_out));

	assign north_out_reg[1][28][10:0] = X158_Y69_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][29][10:2] = X158_Y69_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X158_Y69(.data(/* from design */),
		.q(X158_Y69_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X158_Y69_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X159_Y69@{N[1][29],N[1][30]}@4 */

	logic X159_Y69_incr_waddr; // ingress control
	logic X159_Y69_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_1_north_to_south_ip_size_30_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][30][0]),
		.out(X159_Y69_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_1_north_to_south_ip_size_30_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][30][1]),
		.out(X159_Y69_incr_raddr));

	logic [ADDR_WIDTH-1:0] X159_Y69_waddr;
	logic [ADDR_WIDTH-1:0] X159_Y69_raddr;

	/* positional aliases */

	wire X160_Y69_incr_waddr;
	assign X160_Y69_incr_waddr = X159_Y69_incr_waddr;
	wire [ADDR_WIDTH-1:0] X160_Y69_waddr;
	assign X160_Y69_waddr = X159_Y69_waddr;
	wire X160_Y68_incr_raddr;
	assign X160_Y68_incr_raddr = X159_Y69_incr_raddr;
	wire [ADDR_WIDTH-1:0] X160_Y68_raddr;
	assign X160_Y68_raddr = X159_Y69_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X159_Y69(.clk(bus_clock),
		.incr_waddr(X159_Y69_incr_waddr),
		.waddr(X159_Y69_waddr),
		.incr_raddr(X159_Y69_incr_raddr),
		.raddr(X159_Y69_raddr));


	/* generated from I@X160_Y69@{N[1][30],N[1][31]}@4 */

	logic [DATA_WIDTH-1:0] X160_Y69_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_1_north_to_south_ip_size_31_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][30][10:0], north_in_reg[1][31][10:2]}),
		.out(X160_Y69_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X160_Y69(.data(X160_Y69_bus_wdata),
		.q(/* to design */),
		.wraddress(X160_Y69_waddr),
		.rdaddress(/* from design */),
		.wren(X160_Y69_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X231_Y69@{S[3][5],S[3][4]}@2 */

	logic [DATA_WIDTH-1:0] X231_Y69_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X231_Y69_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_3_south_to_north_ip_size_4_bus_first_egress_fifo(.clock(bus_clock),
		.in(X231_Y69_bus_rdata_in),
		.out(X231_Y69_bus_rdata_out));

	assign north_out_reg[3][5][10:0] = X231_Y69_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][4][10:2] = X231_Y69_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X231_Y69(.data(/* from design */),
		.q(X231_Y69_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X231_Y69_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X233_Y69@{N[3][7],N[3][6]}@4 */

	logic [DATA_WIDTH-1:0] X233_Y69_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_3_north_to_south_ip_size_6_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][7][10:0], north_in_reg[3][6][10:2]}),
		.out(X233_Y69_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X233_Y69(.data(X233_Y69_bus_wdata),
		.q(/* to design */),
		.wraddress(X233_Y69_waddr),
		.rdaddress(/* from design */),
		.wren(X233_Y69_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X234_Y69@{N[3][8],N[3][7]}@4 */

	logic X234_Y69_incr_waddr; // ingress control
	logic X234_Y69_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_3_north_to_south_ip_size_7_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][8][0]),
		.out(X234_Y69_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_3_north_to_south_ip_size_7_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][8][1]),
		.out(X234_Y69_incr_raddr));

	logic [ADDR_WIDTH-1:0] X234_Y69_waddr;
	logic [ADDR_WIDTH-1:0] X234_Y69_raddr;

	/* positional aliases */

	wire X233_Y69_incr_waddr;
	assign X233_Y69_incr_waddr = X234_Y69_incr_waddr;
	wire [ADDR_WIDTH-1:0] X233_Y69_waddr;
	assign X233_Y69_waddr = X234_Y69_waddr;
	wire X233_Y68_incr_raddr;
	assign X233_Y68_incr_raddr = X234_Y69_incr_raddr;
	wire [ADDR_WIDTH-1:0] X233_Y68_raddr;
	assign X233_Y68_raddr = X234_Y69_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X234_Y69(.clk(bus_clock),
		.incr_waddr(X234_Y69_incr_waddr),
		.waddr(X234_Y69_waddr),
		.incr_raddr(X234_Y69_incr_raddr),
		.raddr(X234_Y69_raddr));


	/* generated from E@X242_Y69@{S[3][13],S[3][12]}@2 */

	logic [DATA_WIDTH-1:0] X242_Y69_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X242_Y69_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_3_south_to_north_ip_size_12_bus_first_egress_fifo(.clock(bus_clock),
		.in(X242_Y69_bus_rdata_in),
		.out(X242_Y69_bus_rdata_out));

	assign north_out_reg[3][13][10:0] = X242_Y69_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][12][10:2] = X242_Y69_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X242_Y69(.data(/* from design */),
		.q(X242_Y69_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X242_Y69_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X244_Y69@{N[3][15],N[3][14]}@4 */

	logic [DATA_WIDTH-1:0] X244_Y69_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_3_north_to_south_ip_size_14_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][15][10:0], north_in_reg[3][14][10:2]}),
		.out(X244_Y69_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X244_Y69(.data(X244_Y69_bus_wdata),
		.q(/* to design */),
		.wraddress(X244_Y69_waddr),
		.rdaddress(/* from design */),
		.wren(X244_Y69_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X245_Y69@{N[3][16],N[3][15]}@4 */

	logic X245_Y69_incr_waddr; // ingress control
	logic X245_Y69_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_3_north_to_south_ip_size_15_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][16][0]),
		.out(X245_Y69_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_3_north_to_south_ip_size_15_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][16][1]),
		.out(X245_Y69_incr_raddr));

	logic [ADDR_WIDTH-1:0] X245_Y69_waddr;
	logic [ADDR_WIDTH-1:0] X245_Y69_raddr;

	/* positional aliases */

	wire X244_Y69_incr_waddr;
	assign X244_Y69_incr_waddr = X245_Y69_incr_waddr;
	wire [ADDR_WIDTH-1:0] X244_Y69_waddr;
	assign X244_Y69_waddr = X245_Y69_waddr;
	wire X244_Y68_incr_raddr;
	assign X244_Y68_incr_raddr = X245_Y69_incr_raddr;
	wire [ADDR_WIDTH-1:0] X244_Y68_raddr;
	assign X244_Y68_raddr = X245_Y69_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X245_Y69(.clk(bus_clock),
		.incr_waddr(X245_Y69_incr_waddr),
		.waddr(X245_Y69_waddr),
		.incr_raddr(X245_Y69_incr_raddr),
		.raddr(X245_Y69_raddr));


	/* generated from I@X260_Y69@{E[0][26],E[0][25]}@0 */

	logic [DATA_WIDTH-1:0] X260_Y69_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) east_to_west_sector_size_0_east_to_west_ip_size_25_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][26][10:0], east_in_reg[0][25][10:2]}),
		.out(X260_Y69_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X260_Y69(.data(X260_Y69_bus_wdata),
		.q(/* to design */),
		.wraddress(X260_Y69_waddr),
		.rdaddress(/* from design */),
		.wren(X260_Y69_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X261_Y69@{E[0][26],E[0][25]}@0 */

	logic X261_Y69_incr_waddr; // ingress control
	logic X261_Y69_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) east_to_west_sector_size_0_east_to_west_ip_size_25_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][26][0]),
		.out(X261_Y69_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) east_to_west_sector_size_0_east_to_west_ip_size_25_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][26][1]),
		.out(X261_Y69_incr_raddr));

	logic [ADDR_WIDTH-1:0] X261_Y69_waddr;
	logic [ADDR_WIDTH-1:0] X261_Y69_raddr;

	/* positional aliases */

	wire X260_Y69_incr_waddr;
	assign X260_Y69_incr_waddr = X261_Y69_incr_waddr;
	wire [ADDR_WIDTH-1:0] X260_Y69_waddr;
	assign X260_Y69_waddr = X261_Y69_waddr;
	wire X260_Y68_incr_raddr;
	assign X260_Y68_incr_raddr = X261_Y69_incr_raddr;
	wire [ADDR_WIDTH-1:0] X260_Y68_raddr;
	assign X260_Y68_raddr = X261_Y69_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X261_Y69(.clk(bus_clock),
		.incr_waddr(X261_Y69_incr_waddr),
		.waddr(X261_Y69_waddr),
		.incr_raddr(X261_Y69_incr_raddr),
		.raddr(X261_Y69_raddr));


	/* generated from E@X274_Y69@{S[3][37],S[3][36]}@2 */

	logic [DATA_WIDTH-1:0] X274_Y69_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X274_Y69_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_3_south_to_north_ip_size_36_bus_first_egress_fifo(.clock(bus_clock),
		.in(X274_Y69_bus_rdata_in),
		.out(X274_Y69_bus_rdata_out));

	assign north_out_reg[3][37][10:0] = X274_Y69_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][36][10:2] = X274_Y69_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X274_Y69(.data(/* from design */),
		.q(X274_Y69_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X274_Y69_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X276_Y69@{N[3][39],N[3][38]}@4 */

	logic [DATA_WIDTH-1:0] X276_Y69_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_3_north_to_south_ip_size_38_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][39][10:0], north_in_reg[3][38][10:2]}),
		.out(X276_Y69_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X276_Y69(.data(X276_Y69_bus_wdata),
		.q(/* to design */),
		.wraddress(X276_Y69_waddr),
		.rdaddress(/* from design */),
		.wren(X276_Y69_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X277_Y69@{,N[3][39]}@4 */

	logic X277_Y69_incr_waddr; // ingress control
	logic X277_Y69_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_3_north_to_south_ip_size_39_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][39][0]),
		.out(X277_Y69_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_3_north_to_south_ip_size_39_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][39][1]),
		.out(X277_Y69_incr_raddr));

	logic [ADDR_WIDTH-1:0] X277_Y69_waddr;
	logic [ADDR_WIDTH-1:0] X277_Y69_raddr;

	/* positional aliases */

	wire X276_Y69_incr_waddr;
	assign X276_Y69_incr_waddr = X277_Y69_incr_waddr;
	wire [ADDR_WIDTH-1:0] X276_Y69_waddr;
	assign X276_Y69_waddr = X277_Y69_waddr;
	wire X276_Y68_incr_raddr;
	assign X276_Y68_incr_raddr = X277_Y69_incr_raddr;
	wire [ADDR_WIDTH-1:0] X276_Y68_raddr;
	assign X276_Y68_raddr = X277_Y69_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X277_Y69(.clk(bus_clock),
		.incr_waddr(X277_Y69_incr_waddr),
		.waddr(X277_Y69_waddr),
		.incr_raddr(X277_Y69_incr_raddr),
		.raddr(X277_Y69_raddr));


	/* generated from E@X132_Y68@{W[0][26],W[0][25]}@2 */

	logic [DATA_WIDTH-1:0] X132_Y68_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X132_Y68_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_0_west_to_east_ip_size_25_bus_first_egress_fifo(.clock(bus_clock),
		.in(X132_Y68_bus_rdata_in),
		.out(X132_Y68_bus_rdata_out));

	assign east_out_reg[0][26][10:0] = X132_Y68_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][25][10:2] = X132_Y68_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X132_Y68(.data(/* from design */),
		.q(X132_Y68_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X132_Y68_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X146_Y68@{S[1][19],S[1][20]}@1 */

	logic X146_Y68_incr_waddr; // ingress control
	logic X146_Y68_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_1_south_to_north_ip_size_20_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][20][0]),
		.out(X146_Y68_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_1_south_to_north_ip_size_20_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][20][1]),
		.out(X146_Y68_incr_raddr));

	logic [ADDR_WIDTH-1:0] X146_Y68_waddr;
	logic [ADDR_WIDTH-1:0] X146_Y68_raddr;

	/* positional aliases */

	wire X147_Y68_incr_waddr;
	assign X147_Y68_incr_waddr = X146_Y68_incr_waddr;
	wire [ADDR_WIDTH-1:0] X147_Y68_waddr;
	assign X147_Y68_waddr = X146_Y68_waddr;
	wire X147_Y69_incr_raddr;
	assign X147_Y69_incr_raddr = X146_Y68_incr_raddr;
	wire [ADDR_WIDTH-1:0] X147_Y69_raddr;
	assign X147_Y69_raddr = X146_Y68_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X146_Y68(.clk(bus_clock),
		.incr_waddr(X146_Y68_incr_waddr),
		.waddr(X146_Y68_waddr),
		.incr_raddr(X146_Y68_incr_raddr),
		.raddr(X146_Y68_raddr));


	/* generated from I@X147_Y68@{S[1][20],S[1][21]}@1 */

	logic [DATA_WIDTH-1:0] X147_Y68_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_1_south_to_north_ip_size_21_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][20][10:0], south_in_reg[1][21][10:2]}),
		.out(X147_Y68_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X147_Y68(.data(X147_Y68_bus_wdata),
		.q(/* to design */),
		.wraddress(X147_Y68_waddr),
		.rdaddress(/* from design */),
		.wren(X147_Y68_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X149_Y68@{N[1][22],N[1][23]}@5 */

	logic [DATA_WIDTH-1:0] X149_Y68_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X149_Y68_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_1_north_to_south_ip_size_23_bus_first_egress_fifo(.clock(bus_clock),
		.in(X149_Y68_bus_rdata_in),
		.out(X149_Y68_bus_rdata_out));

	assign south_out_reg[1][22][10:0] = X149_Y68_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][23][10:2] = X149_Y68_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X149_Y68(.data(/* from design */),
		.q(X149_Y68_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X149_Y68_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X157_Y68@{S[1][27],S[1][28]}@1 */

	logic X157_Y68_incr_waddr; // ingress control
	logic X157_Y68_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_1_south_to_north_ip_size_28_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][28][0]),
		.out(X157_Y68_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_1_south_to_north_ip_size_28_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][28][1]),
		.out(X157_Y68_incr_raddr));

	logic [ADDR_WIDTH-1:0] X157_Y68_waddr;
	logic [ADDR_WIDTH-1:0] X157_Y68_raddr;

	/* positional aliases */

	wire X158_Y68_incr_waddr;
	assign X158_Y68_incr_waddr = X157_Y68_incr_waddr;
	wire [ADDR_WIDTH-1:0] X158_Y68_waddr;
	assign X158_Y68_waddr = X157_Y68_waddr;
	wire X158_Y69_incr_raddr;
	assign X158_Y69_incr_raddr = X157_Y68_incr_raddr;
	wire [ADDR_WIDTH-1:0] X158_Y69_raddr;
	assign X158_Y69_raddr = X157_Y68_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X157_Y68(.clk(bus_clock),
		.incr_waddr(X157_Y68_incr_waddr),
		.waddr(X157_Y68_waddr),
		.incr_raddr(X157_Y68_incr_raddr),
		.raddr(X157_Y68_raddr));


	/* generated from I@X158_Y68@{S[1][28],S[1][29]}@1 */

	logic [DATA_WIDTH-1:0] X158_Y68_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_1_south_to_north_ip_size_29_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][28][10:0], south_in_reg[1][29][10:2]}),
		.out(X158_Y68_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X158_Y68(.data(X158_Y68_bus_wdata),
		.q(/* to design */),
		.wraddress(X158_Y68_waddr),
		.rdaddress(/* from design */),
		.wren(X158_Y68_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X160_Y68@{N[1][30],N[1][31]}@5 */

	logic [DATA_WIDTH-1:0] X160_Y68_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X160_Y68_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_1_north_to_south_ip_size_31_bus_first_egress_fifo(.clock(bus_clock),
		.in(X160_Y68_bus_rdata_in),
		.out(X160_Y68_bus_rdata_out));

	assign south_out_reg[1][30][10:0] = X160_Y68_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][31][10:2] = X160_Y68_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X160_Y68(.data(/* from design */),
		.q(X160_Y68_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X160_Y68_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X231_Y68@{S[3][5],S[3][4]}@1 */

	logic [DATA_WIDTH-1:0] X231_Y68_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_3_south_to_north_ip_size_4_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][5][10:0], south_in_reg[3][4][10:2]}),
		.out(X231_Y68_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X231_Y68(.data(X231_Y68_bus_wdata),
		.q(/* to design */),
		.wraddress(X231_Y68_waddr),
		.rdaddress(/* from design */),
		.wren(X231_Y68_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X232_Y68@{S[3][6],S[3][5]}@1 */

	logic X232_Y68_incr_waddr; // ingress control
	logic X232_Y68_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_3_south_to_north_ip_size_5_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][6][0]),
		.out(X232_Y68_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_3_south_to_north_ip_size_5_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][6][1]),
		.out(X232_Y68_incr_raddr));

	logic [ADDR_WIDTH-1:0] X232_Y68_waddr;
	logic [ADDR_WIDTH-1:0] X232_Y68_raddr;

	/* positional aliases */

	wire X231_Y68_incr_waddr;
	assign X231_Y68_incr_waddr = X232_Y68_incr_waddr;
	wire [ADDR_WIDTH-1:0] X231_Y68_waddr;
	assign X231_Y68_waddr = X232_Y68_waddr;
	wire X231_Y69_incr_raddr;
	assign X231_Y69_incr_raddr = X232_Y68_incr_raddr;
	wire [ADDR_WIDTH-1:0] X231_Y69_raddr;
	assign X231_Y69_raddr = X232_Y68_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X232_Y68(.clk(bus_clock),
		.incr_waddr(X232_Y68_incr_waddr),
		.waddr(X232_Y68_waddr),
		.incr_raddr(X232_Y68_incr_raddr),
		.raddr(X232_Y68_raddr));


	/* generated from E@X233_Y68@{N[3][7],N[3][6]}@5 */

	logic [DATA_WIDTH-1:0] X233_Y68_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X233_Y68_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_3_north_to_south_ip_size_6_bus_first_egress_fifo(.clock(bus_clock),
		.in(X233_Y68_bus_rdata_in),
		.out(X233_Y68_bus_rdata_out));

	assign south_out_reg[3][7][10:0] = X233_Y68_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][6][10:2] = X233_Y68_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X233_Y68(.data(/* from design */),
		.q(X233_Y68_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X233_Y68_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X242_Y68@{S[3][13],S[3][12]}@1 */

	logic [DATA_WIDTH-1:0] X242_Y68_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_3_south_to_north_ip_size_12_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][13][10:0], south_in_reg[3][12][10:2]}),
		.out(X242_Y68_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X242_Y68(.data(X242_Y68_bus_wdata),
		.q(/* to design */),
		.wraddress(X242_Y68_waddr),
		.rdaddress(/* from design */),
		.wren(X242_Y68_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X243_Y68@{S[3][14],S[3][13]}@1 */

	logic X243_Y68_incr_waddr; // ingress control
	logic X243_Y68_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_3_south_to_north_ip_size_13_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][14][0]),
		.out(X243_Y68_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_3_south_to_north_ip_size_13_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][14][1]),
		.out(X243_Y68_incr_raddr));

	logic [ADDR_WIDTH-1:0] X243_Y68_waddr;
	logic [ADDR_WIDTH-1:0] X243_Y68_raddr;

	/* positional aliases */

	wire X242_Y68_incr_waddr;
	assign X242_Y68_incr_waddr = X243_Y68_incr_waddr;
	wire [ADDR_WIDTH-1:0] X242_Y68_waddr;
	assign X242_Y68_waddr = X243_Y68_waddr;
	wire X242_Y69_incr_raddr;
	assign X242_Y69_incr_raddr = X243_Y68_incr_raddr;
	wire [ADDR_WIDTH-1:0] X242_Y69_raddr;
	assign X242_Y69_raddr = X243_Y68_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X243_Y68(.clk(bus_clock),
		.incr_waddr(X243_Y68_incr_waddr),
		.waddr(X243_Y68_waddr),
		.incr_raddr(X243_Y68_incr_raddr),
		.raddr(X243_Y68_raddr));


	/* generated from E@X244_Y68@{N[3][15],N[3][14]}@5 */

	logic [DATA_WIDTH-1:0] X244_Y68_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X244_Y68_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_3_north_to_south_ip_size_14_bus_first_egress_fifo(.clock(bus_clock),
		.in(X244_Y68_bus_rdata_in),
		.out(X244_Y68_bus_rdata_out));

	assign south_out_reg[3][15][10:0] = X244_Y68_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][14][10:2] = X244_Y68_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X244_Y68(.data(/* from design */),
		.q(X244_Y68_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X244_Y68_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X260_Y68@{E[0][26],E[0][25]}@1 */

	logic [DATA_WIDTH-1:0] X260_Y68_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X260_Y68_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) east_to_west_sector_size_0_east_to_west_ip_size_25_bus_first_egress_fifo(.clock(bus_clock),
		.in(X260_Y68_bus_rdata_in),
		.out(X260_Y68_bus_rdata_out));

	assign west_out_reg[0][26][10:0] = X260_Y68_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][25][10:2] = X260_Y68_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X260_Y68(.data(/* from design */),
		.q(X260_Y68_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X260_Y68_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X274_Y68@{S[3][37],S[3][36]}@1 */

	logic [DATA_WIDTH-1:0] X274_Y68_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_3_south_to_north_ip_size_36_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][37][10:0], south_in_reg[3][36][10:2]}),
		.out(X274_Y68_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X274_Y68(.data(X274_Y68_bus_wdata),
		.q(/* to design */),
		.wraddress(X274_Y68_waddr),
		.rdaddress(/* from design */),
		.wren(X274_Y68_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X275_Y68@{S[3][38],S[3][37]}@1 */

	logic X275_Y68_incr_waddr; // ingress control
	logic X275_Y68_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_3_south_to_north_ip_size_37_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][38][0]),
		.out(X275_Y68_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_3_south_to_north_ip_size_37_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][38][1]),
		.out(X275_Y68_incr_raddr));

	logic [ADDR_WIDTH-1:0] X275_Y68_waddr;
	logic [ADDR_WIDTH-1:0] X275_Y68_raddr;

	/* positional aliases */

	wire X274_Y68_incr_waddr;
	assign X274_Y68_incr_waddr = X275_Y68_incr_waddr;
	wire [ADDR_WIDTH-1:0] X274_Y68_waddr;
	assign X274_Y68_waddr = X275_Y68_waddr;
	wire X274_Y69_incr_raddr;
	assign X274_Y69_incr_raddr = X275_Y68_incr_raddr;
	wire [ADDR_WIDTH-1:0] X274_Y69_raddr;
	assign X274_Y69_raddr = X275_Y68_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X275_Y68(.clk(bus_clock),
		.incr_waddr(X275_Y68_incr_waddr),
		.waddr(X275_Y68_waddr),
		.incr_raddr(X275_Y68_incr_raddr),
		.raddr(X275_Y68_raddr));


	/* generated from E@X276_Y68@{N[3][39],N[3][38]}@5 */

	logic [DATA_WIDTH-1:0] X276_Y68_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X276_Y68_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_3_north_to_south_ip_size_38_bus_first_egress_fifo(.clock(bus_clock),
		.in(X276_Y68_bus_rdata_in),
		.out(X276_Y68_bus_rdata_out));

	assign south_out_reg[3][39][10:0] = X276_Y68_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][38][10:2] = X276_Y68_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X276_Y68(.data(/* from design */),
		.q(X276_Y68_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X276_Y68_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X104_Y67@{E[0][24],E[0][23]}@4 */

	logic [DATA_WIDTH-1:0] X104_Y67_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_23_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][24][10:0], east_in_reg[0][23][10:2]}),
		.out(X104_Y67_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X104_Y67(.data(X104_Y67_bus_wdata),
		.q(/* to design */),
		.wraddress(X104_Y67_waddr),
		.rdaddress(/* from design */),
		.wren(X104_Y67_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X105_Y67@{E[0][24],E[0][23]}@4 */

	logic X105_Y67_incr_waddr; // ingress control
	logic X105_Y67_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_23_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][23][0]),
		.out(X105_Y67_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_23_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][23][1]),
		.out(X105_Y67_incr_raddr));

	logic [ADDR_WIDTH-1:0] X105_Y67_waddr;
	logic [ADDR_WIDTH-1:0] X105_Y67_raddr;

	/* positional aliases */

	wire X104_Y67_incr_waddr;
	assign X104_Y67_incr_waddr = X105_Y67_incr_waddr;
	wire [ADDR_WIDTH-1:0] X104_Y67_waddr;
	assign X104_Y67_waddr = X105_Y67_waddr;
	wire X104_Y66_incr_raddr;
	assign X104_Y66_incr_raddr = X105_Y67_incr_raddr;
	wire [ADDR_WIDTH-1:0] X104_Y66_raddr;
	assign X104_Y66_raddr = X105_Y67_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X105_Y67(.clk(bus_clock),
		.incr_waddr(X105_Y67_incr_waddr),
		.waddr(X105_Y67_waddr),
		.incr_raddr(X105_Y67_incr_raddr),
		.raddr(X105_Y67_raddr));


	/* generated from C@X205_Y67@{W[0][24],W[0][23]}@3 */

	logic X205_Y67_incr_waddr; // ingress control
	logic X205_Y67_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_0_west_to_east_ip_size_23_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][24][0]),
		.out(X205_Y67_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_0_west_to_east_ip_size_23_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][24][1]),
		.out(X205_Y67_incr_raddr));

	logic [ADDR_WIDTH-1:0] X205_Y67_waddr;
	logic [ADDR_WIDTH-1:0] X205_Y67_raddr;

	/* positional aliases */

	wire X206_Y67_incr_waddr;
	assign X206_Y67_incr_waddr = X205_Y67_incr_waddr;
	wire [ADDR_WIDTH-1:0] X206_Y67_waddr;
	assign X206_Y67_waddr = X205_Y67_waddr;
	wire X206_Y66_incr_raddr;
	assign X206_Y66_incr_raddr = X205_Y67_incr_raddr;
	wire [ADDR_WIDTH-1:0] X206_Y66_raddr;
	assign X206_Y66_raddr = X205_Y67_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X205_Y67(.clk(bus_clock),
		.incr_waddr(X205_Y67_incr_waddr),
		.waddr(X205_Y67_waddr),
		.incr_raddr(X205_Y67_incr_raddr),
		.raddr(X205_Y67_raddr));


	/* generated from I@X206_Y67@{W[0][24],W[0][23]}@4 */

	logic [DATA_WIDTH-1:0] X206_Y67_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_0_west_to_east_ip_size_23_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][24][10:0], west_in_reg[0][23][10:2]}),
		.out(X206_Y67_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X206_Y67(.data(X206_Y67_bus_wdata),
		.q(/* to design */),
		.wraddress(X206_Y67_waddr),
		.rdaddress(/* from design */),
		.wren(X206_Y67_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X104_Y66@{E[0][24],E[0][23]}@5 */

	logic [DATA_WIDTH-1:0] X104_Y66_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X104_Y66_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_23_bus_first_egress_fifo(.clock(bus_clock),
		.in(X104_Y66_bus_rdata_in),
		.out(X104_Y66_bus_rdata_out));

	assign west_out_reg[0][24][10:0] = X104_Y66_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][23][10:2] = X104_Y66_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X104_Y66(.data(/* from design */),
		.q(X104_Y66_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X104_Y66_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X206_Y66@{W[0][24],W[0][23]}@5 */

	logic [DATA_WIDTH-1:0] X206_Y66_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X206_Y66_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_23_bus_first_egress_fifo(.clock(bus_clock),
		.in(X206_Y66_bus_rdata_in),
		.out(X206_Y66_bus_rdata_out));

	assign east_out_reg[0][24][10:0] = X206_Y66_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][23][10:2] = X206_Y66_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X206_Y66(.data(/* from design */),
		.q(X206_Y66_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X206_Y66_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X72_Y65@{S[0][4],S[0][5]}@2 */

	logic [DATA_WIDTH-1:0] X72_Y65_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X72_Y65_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_0_south_to_north_ip_size_5_bus_first_egress_fifo(.clock(bus_clock),
		.in(X72_Y65_bus_rdata_in),
		.out(X72_Y65_bus_rdata_out));

	assign north_out_reg[0][4][10:0] = X72_Y65_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][5][10:2] = X72_Y65_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X72_Y65(.data(/* from design */),
		.q(X72_Y65_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X72_Y65_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X73_Y65@{N[0][5],N[0][6]}@4 */

	logic X73_Y65_incr_waddr; // ingress control
	logic X73_Y65_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_0_north_to_south_ip_size_6_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][6][0]),
		.out(X73_Y65_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_0_north_to_south_ip_size_6_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][6][1]),
		.out(X73_Y65_incr_raddr));

	logic [ADDR_WIDTH-1:0] X73_Y65_waddr;
	logic [ADDR_WIDTH-1:0] X73_Y65_raddr;

	/* positional aliases */

	wire X74_Y65_incr_waddr;
	assign X74_Y65_incr_waddr = X73_Y65_incr_waddr;
	wire [ADDR_WIDTH-1:0] X74_Y65_waddr;
	assign X74_Y65_waddr = X73_Y65_waddr;
	wire X74_Y64_incr_raddr;
	assign X74_Y64_incr_raddr = X73_Y65_incr_raddr;
	wire [ADDR_WIDTH-1:0] X74_Y64_raddr;
	assign X74_Y64_raddr = X73_Y65_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X73_Y65(.clk(bus_clock),
		.incr_waddr(X73_Y65_incr_waddr),
		.waddr(X73_Y65_waddr),
		.incr_raddr(X73_Y65_incr_raddr),
		.raddr(X73_Y65_raddr));


	/* generated from I@X74_Y65@{N[0][6],N[0][7]}@4 */

	logic [DATA_WIDTH-1:0] X74_Y65_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_0_north_to_south_ip_size_7_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][6][10:0], north_in_reg[0][7][10:2]}),
		.out(X74_Y65_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X74_Y65(.data(X74_Y65_bus_wdata),
		.q(/* to design */),
		.wraddress(X74_Y65_waddr),
		.rdaddress(/* from design */),
		.wren(X74_Y65_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X83_Y65@{S[0][12],S[0][13]}@2 */

	logic [DATA_WIDTH-1:0] X83_Y65_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X83_Y65_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_0_south_to_north_ip_size_13_bus_first_egress_fifo(.clock(bus_clock),
		.in(X83_Y65_bus_rdata_in),
		.out(X83_Y65_bus_rdata_out));

	assign north_out_reg[0][12][10:0] = X83_Y65_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][13][10:2] = X83_Y65_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X83_Y65(.data(/* from design */),
		.q(X83_Y65_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X83_Y65_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X84_Y65@{N[0][13],N[0][14]}@4 */

	logic X84_Y65_incr_waddr; // ingress control
	logic X84_Y65_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_0_north_to_south_ip_size_14_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][14][0]),
		.out(X84_Y65_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_0_north_to_south_ip_size_14_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][14][1]),
		.out(X84_Y65_incr_raddr));

	logic [ADDR_WIDTH-1:0] X84_Y65_waddr;
	logic [ADDR_WIDTH-1:0] X84_Y65_raddr;

	/* positional aliases */

	wire X85_Y65_incr_waddr;
	assign X85_Y65_incr_waddr = X84_Y65_incr_waddr;
	wire [ADDR_WIDTH-1:0] X85_Y65_waddr;
	assign X85_Y65_waddr = X84_Y65_waddr;
	wire X85_Y64_incr_raddr;
	assign X85_Y64_incr_raddr = X84_Y65_incr_raddr;
	wire [ADDR_WIDTH-1:0] X85_Y64_raddr;
	assign X85_Y64_raddr = X84_Y65_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X84_Y65(.clk(bus_clock),
		.incr_waddr(X84_Y65_incr_waddr),
		.waddr(X84_Y65_waddr),
		.incr_raddr(X84_Y65_incr_raddr),
		.raddr(X84_Y65_raddr));


	/* generated from I@X85_Y65@{N[0][14],N[0][15]}@4 */

	logic [DATA_WIDTH-1:0] X85_Y65_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_0_north_to_south_ip_size_15_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][14][10:0], north_in_reg[0][15][10:2]}),
		.out(X85_Y65_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X85_Y65(.data(X85_Y65_bus_wdata),
		.q(/* to design */),
		.wraddress(X85_Y65_waddr),
		.rdaddress(/* from design */),
		.wren(X85_Y65_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X93_Y65@{S[0][20],S[0][21]}@2 */

	logic [DATA_WIDTH-1:0] X93_Y65_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X93_Y65_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_0_south_to_north_ip_size_21_bus_first_egress_fifo(.clock(bus_clock),
		.in(X93_Y65_bus_rdata_in),
		.out(X93_Y65_bus_rdata_out));

	assign north_out_reg[0][20][10:0] = X93_Y65_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][21][10:2] = X93_Y65_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X93_Y65(.data(/* from design */),
		.q(X93_Y65_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X93_Y65_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X94_Y65@{N[0][21],N[0][22]}@4 */

	logic X94_Y65_incr_waddr; // ingress control
	logic X94_Y65_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_0_north_to_south_ip_size_22_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][22][0]),
		.out(X94_Y65_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_0_north_to_south_ip_size_22_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][22][1]),
		.out(X94_Y65_incr_raddr));

	logic [ADDR_WIDTH-1:0] X94_Y65_waddr;
	logic [ADDR_WIDTH-1:0] X94_Y65_raddr;

	/* positional aliases */

	wire X95_Y65_incr_waddr;
	assign X95_Y65_incr_waddr = X94_Y65_incr_waddr;
	wire [ADDR_WIDTH-1:0] X95_Y65_waddr;
	assign X95_Y65_waddr = X94_Y65_waddr;
	wire X95_Y64_incr_raddr;
	assign X95_Y64_incr_raddr = X94_Y65_incr_raddr;
	wire [ADDR_WIDTH-1:0] X95_Y64_raddr;
	assign X95_Y64_raddr = X94_Y65_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X94_Y65(.clk(bus_clock),
		.incr_waddr(X94_Y65_incr_waddr),
		.waddr(X94_Y65_waddr),
		.incr_raddr(X94_Y65_incr_raddr),
		.raddr(X94_Y65_raddr));


	/* generated from I@X95_Y65@{N[0][22],N[0][23]}@4 */

	logic [DATA_WIDTH-1:0] X95_Y65_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_0_north_to_south_ip_size_23_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][22][10:0], north_in_reg[0][23][10:2]}),
		.out(X95_Y65_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X95_Y65(.data(X95_Y65_bus_wdata),
		.q(/* to design */),
		.wraddress(X95_Y65_waddr),
		.rdaddress(/* from design */),
		.wren(X95_Y65_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X103_Y65@{W[0][22],W[0][21]}@1 */

	logic X103_Y65_incr_waddr; // ingress control
	logic X103_Y65_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_21_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][21][0]),
		.out(X103_Y65_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_21_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][21][1]),
		.out(X103_Y65_incr_raddr));

	logic [ADDR_WIDTH-1:0] X103_Y65_waddr;
	logic [ADDR_WIDTH-1:0] X103_Y65_raddr;

	/* positional aliases */

	wire X104_Y65_incr_waddr;
	assign X104_Y65_incr_waddr = X103_Y65_incr_waddr;
	wire [ADDR_WIDTH-1:0] X104_Y65_waddr;
	assign X104_Y65_waddr = X103_Y65_waddr;
	wire X104_Y64_incr_raddr;
	assign X104_Y64_incr_raddr = X103_Y65_incr_raddr;
	wire [ADDR_WIDTH-1:0] X104_Y64_raddr;
	assign X104_Y64_raddr = X103_Y65_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X103_Y65(.clk(bus_clock),
		.incr_waddr(X103_Y65_incr_waddr),
		.waddr(X103_Y65_waddr),
		.incr_raddr(X103_Y65_incr_raddr),
		.raddr(X103_Y65_raddr));


	/* generated from I@X104_Y65@{W[0][22],W[0][21]}@1 */

	logic [DATA_WIDTH-1:0] X104_Y65_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_21_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][22][10:0], west_in_reg[0][21][10:2]}),
		.out(X104_Y65_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X104_Y65(.data(X104_Y65_bus_wdata),
		.q(/* to design */),
		.wraddress(X104_Y65_waddr),
		.rdaddress(/* from design */),
		.wren(X104_Y65_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X115_Y65@{S[0][36],S[0][37]}@2 */

	logic [DATA_WIDTH-1:0] X115_Y65_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X115_Y65_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_0_south_to_north_ip_size_37_bus_first_egress_fifo(.clock(bus_clock),
		.in(X115_Y65_bus_rdata_in),
		.out(X115_Y65_bus_rdata_out));

	assign north_out_reg[0][36][10:0] = X115_Y65_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][37][10:2] = X115_Y65_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X115_Y65(.data(/* from design */),
		.q(X115_Y65_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X115_Y65_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X116_Y65@{N[0][37],N[0][38]}@4 */

	logic X116_Y65_incr_waddr; // ingress control
	logic X116_Y65_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_0_north_to_south_ip_size_38_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][38][0]),
		.out(X116_Y65_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_0_north_to_south_ip_size_38_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][38][1]),
		.out(X116_Y65_incr_raddr));

	logic [ADDR_WIDTH-1:0] X116_Y65_waddr;
	logic [ADDR_WIDTH-1:0] X116_Y65_raddr;

	/* positional aliases */

	wire X117_Y65_incr_waddr;
	assign X117_Y65_incr_waddr = X116_Y65_incr_waddr;
	wire [ADDR_WIDTH-1:0] X117_Y65_waddr;
	assign X117_Y65_waddr = X116_Y65_waddr;
	wire X117_Y64_incr_raddr;
	assign X117_Y64_incr_raddr = X116_Y65_incr_raddr;
	wire [ADDR_WIDTH-1:0] X117_Y64_raddr;
	assign X117_Y64_raddr = X116_Y65_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X116_Y65(.clk(bus_clock),
		.incr_waddr(X116_Y65_incr_waddr),
		.waddr(X116_Y65_waddr),
		.incr_raddr(X116_Y65_incr_raddr),
		.raddr(X116_Y65_raddr));


	/* generated from I@X117_Y65@{N[0][38],N[0][39]}@4 */

	logic [DATA_WIDTH-1:0] X117_Y65_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_0_north_to_south_ip_size_39_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][38][10:0], north_in_reg[0][39][10:2]}),
		.out(X117_Y65_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X117_Y65(.data(X117_Y65_bus_wdata),
		.q(/* to design */),
		.wraddress(X117_Y65_waddr),
		.rdaddress(/* from design */),
		.wren(X117_Y65_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X177_Y65@{S[2][5],S[2][4]}@2 */

	logic [DATA_WIDTH-1:0] X177_Y65_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X177_Y65_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_2_south_to_north_ip_size_4_bus_first_egress_fifo(.clock(bus_clock),
		.in(X177_Y65_bus_rdata_in),
		.out(X177_Y65_bus_rdata_out));

	assign north_out_reg[2][5][10:0] = X177_Y65_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][4][10:2] = X177_Y65_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X177_Y65(.data(/* from design */),
		.q(X177_Y65_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X177_Y65_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X179_Y65@{N[2][7],N[2][6]}@4 */

	logic [DATA_WIDTH-1:0] X179_Y65_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_2_north_to_south_ip_size_6_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][7][10:0], north_in_reg[2][6][10:2]}),
		.out(X179_Y65_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X179_Y65(.data(X179_Y65_bus_wdata),
		.q(/* to design */),
		.wraddress(X179_Y65_waddr),
		.rdaddress(/* from design */),
		.wren(X179_Y65_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X180_Y65@{N[2][8],N[2][7]}@4 */

	logic X180_Y65_incr_waddr; // ingress control
	logic X180_Y65_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_2_north_to_south_ip_size_7_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[2][8][0]),
		.out(X180_Y65_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_2_north_to_south_ip_size_7_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[2][8][1]),
		.out(X180_Y65_incr_raddr));

	logic [ADDR_WIDTH-1:0] X180_Y65_waddr;
	logic [ADDR_WIDTH-1:0] X180_Y65_raddr;

	/* positional aliases */

	wire X179_Y65_incr_waddr;
	assign X179_Y65_incr_waddr = X180_Y65_incr_waddr;
	wire [ADDR_WIDTH-1:0] X179_Y65_waddr;
	assign X179_Y65_waddr = X180_Y65_waddr;
	wire X179_Y64_incr_raddr;
	assign X179_Y64_incr_raddr = X180_Y65_incr_raddr;
	wire [ADDR_WIDTH-1:0] X179_Y64_raddr;
	assign X179_Y64_raddr = X180_Y65_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X180_Y65(.clk(bus_clock),
		.incr_waddr(X180_Y65_incr_waddr),
		.waddr(X180_Y65_waddr),
		.incr_raddr(X180_Y65_incr_raddr),
		.raddr(X180_Y65_raddr));


	/* generated from E@X188_Y65@{S[2][13],S[2][12]}@2 */

	logic [DATA_WIDTH-1:0] X188_Y65_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X188_Y65_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_2_south_to_north_ip_size_12_bus_first_egress_fifo(.clock(bus_clock),
		.in(X188_Y65_bus_rdata_in),
		.out(X188_Y65_bus_rdata_out));

	assign north_out_reg[2][13][10:0] = X188_Y65_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][12][10:2] = X188_Y65_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X188_Y65(.data(/* from design */),
		.q(X188_Y65_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X188_Y65_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X190_Y65@{N[2][15],N[2][14]}@4 */

	logic [DATA_WIDTH-1:0] X190_Y65_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_2_north_to_south_ip_size_14_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][15][10:0], north_in_reg[2][14][10:2]}),
		.out(X190_Y65_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X190_Y65(.data(X190_Y65_bus_wdata),
		.q(/* to design */),
		.wraddress(X190_Y65_waddr),
		.rdaddress(/* from design */),
		.wren(X190_Y65_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X191_Y65@{N[2][16],N[2][15]}@4 */

	logic X191_Y65_incr_waddr; // ingress control
	logic X191_Y65_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_2_north_to_south_ip_size_15_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[2][16][0]),
		.out(X191_Y65_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_2_north_to_south_ip_size_15_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[2][16][1]),
		.out(X191_Y65_incr_raddr));

	logic [ADDR_WIDTH-1:0] X191_Y65_waddr;
	logic [ADDR_WIDTH-1:0] X191_Y65_raddr;

	/* positional aliases */

	wire X190_Y65_incr_waddr;
	assign X190_Y65_incr_waddr = X191_Y65_incr_waddr;
	wire [ADDR_WIDTH-1:0] X190_Y65_waddr;
	assign X190_Y65_waddr = X191_Y65_waddr;
	wire X190_Y64_incr_raddr;
	assign X190_Y64_incr_raddr = X191_Y65_incr_raddr;
	wire [ADDR_WIDTH-1:0] X190_Y64_raddr;
	assign X190_Y64_raddr = X191_Y65_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X191_Y65(.clk(bus_clock),
		.incr_waddr(X191_Y65_incr_waddr),
		.waddr(X191_Y65_waddr),
		.incr_raddr(X191_Y65_incr_raddr),
		.raddr(X191_Y65_raddr));


	/* generated from I@X206_Y65@{E[0][22],E[0][21]}@1 */

	logic [DATA_WIDTH-1:0] X206_Y65_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_21_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][22][10:0], east_in_reg[0][21][10:2]}),
		.out(X206_Y65_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X206_Y65(.data(X206_Y65_bus_wdata),
		.q(/* to design */),
		.wraddress(X206_Y65_waddr),
		.rdaddress(/* from design */),
		.wren(X206_Y65_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X207_Y65@{E[0][22],E[0][21]}@1 */

	logic X207_Y65_incr_waddr; // ingress control
	logic X207_Y65_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_21_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][22][0]),
		.out(X207_Y65_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_21_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][22][1]),
		.out(X207_Y65_incr_raddr));

	logic [ADDR_WIDTH-1:0] X207_Y65_waddr;
	logic [ADDR_WIDTH-1:0] X207_Y65_raddr;

	/* positional aliases */

	wire X206_Y65_incr_waddr;
	assign X206_Y65_incr_waddr = X207_Y65_incr_waddr;
	wire [ADDR_WIDTH-1:0] X206_Y65_waddr;
	assign X206_Y65_waddr = X207_Y65_waddr;
	wire X206_Y64_incr_raddr;
	assign X206_Y64_incr_raddr = X207_Y65_incr_raddr;
	wire [ADDR_WIDTH-1:0] X206_Y64_raddr;
	assign X206_Y64_raddr = X207_Y65_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X207_Y65(.clk(bus_clock),
		.incr_waddr(X207_Y65_incr_waddr),
		.waddr(X207_Y65_waddr),
		.incr_raddr(X207_Y65_incr_raddr),
		.raddr(X207_Y65_raddr));


	/* generated from E@X220_Y65@{S[2][37],S[2][36]}@2 */

	logic [DATA_WIDTH-1:0] X220_Y65_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X220_Y65_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) south_to_north_sector_size_2_south_to_north_ip_size_36_bus_first_egress_fifo(.clock(bus_clock),
		.in(X220_Y65_bus_rdata_in),
		.out(X220_Y65_bus_rdata_out));

	assign north_out_reg[2][37][10:0] = X220_Y65_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][36][10:2] = X220_Y65_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X220_Y65(.data(/* from design */),
		.q(X220_Y65_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X220_Y65_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X222_Y65@{N[2][39],N[2][38]}@4 */

	logic [DATA_WIDTH-1:0] X222_Y65_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) north_to_south_sector_size_2_north_to_south_ip_size_38_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][39][10:0], north_in_reg[2][38][10:2]}),
		.out(X222_Y65_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X222_Y65(.data(X222_Y65_bus_wdata),
		.q(/* to design */),
		.wraddress(X222_Y65_waddr),
		.rdaddress(/* from design */),
		.wren(X222_Y65_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X223_Y65@{N[3][0],N[2][39]}@4 */

	logic X223_Y65_incr_waddr; // ingress control
	logic X223_Y65_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_2_north_to_south_ip_size_39_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][0][0]),
		.out(X223_Y65_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) north_to_south_sector_size_2_north_to_south_ip_size_39_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][0][1]),
		.out(X223_Y65_incr_raddr));

	logic [ADDR_WIDTH-1:0] X223_Y65_waddr;
	logic [ADDR_WIDTH-1:0] X223_Y65_raddr;

	/* positional aliases */

	wire X222_Y65_incr_waddr;
	assign X222_Y65_incr_waddr = X223_Y65_incr_waddr;
	wire [ADDR_WIDTH-1:0] X222_Y65_waddr;
	assign X222_Y65_waddr = X223_Y65_waddr;
	wire X222_Y64_incr_raddr;
	assign X222_Y64_incr_raddr = X223_Y65_incr_raddr;
	wire [ADDR_WIDTH-1:0] X222_Y64_raddr;
	assign X222_Y64_raddr = X223_Y65_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X223_Y65(.clk(bus_clock),
		.incr_waddr(X223_Y65_incr_waddr),
		.waddr(X223_Y65_waddr),
		.incr_raddr(X223_Y65_incr_raddr),
		.raddr(X223_Y65_raddr));


	/* generated from C@X71_Y64@{S[0][3],S[0][4]}@1 */

	logic X71_Y64_incr_waddr; // ingress control
	logic X71_Y64_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_0_south_to_north_ip_size_4_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][4][0]),
		.out(X71_Y64_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_0_south_to_north_ip_size_4_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][4][1]),
		.out(X71_Y64_incr_raddr));

	logic [ADDR_WIDTH-1:0] X71_Y64_waddr;
	logic [ADDR_WIDTH-1:0] X71_Y64_raddr;

	/* positional aliases */

	wire X72_Y64_incr_waddr;
	assign X72_Y64_incr_waddr = X71_Y64_incr_waddr;
	wire [ADDR_WIDTH-1:0] X72_Y64_waddr;
	assign X72_Y64_waddr = X71_Y64_waddr;
	wire X72_Y65_incr_raddr;
	assign X72_Y65_incr_raddr = X71_Y64_incr_raddr;
	wire [ADDR_WIDTH-1:0] X72_Y65_raddr;
	assign X72_Y65_raddr = X71_Y64_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X71_Y64(.clk(bus_clock),
		.incr_waddr(X71_Y64_incr_waddr),
		.waddr(X71_Y64_waddr),
		.incr_raddr(X71_Y64_incr_raddr),
		.raddr(X71_Y64_raddr));


	/* generated from I@X72_Y64@{S[0][4],S[0][5]}@1 */

	logic [DATA_WIDTH-1:0] X72_Y64_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_0_south_to_north_ip_size_5_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][4][10:0], south_in_reg[0][5][10:2]}),
		.out(X72_Y64_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X72_Y64(.data(X72_Y64_bus_wdata),
		.q(/* to design */),
		.wraddress(X72_Y64_waddr),
		.rdaddress(/* from design */),
		.wren(X72_Y64_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X74_Y64@{N[0][6],N[0][7]}@5 */

	logic [DATA_WIDTH-1:0] X74_Y64_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X74_Y64_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_0_north_to_south_ip_size_7_bus_first_egress_fifo(.clock(bus_clock),
		.in(X74_Y64_bus_rdata_in),
		.out(X74_Y64_bus_rdata_out));

	assign south_out_reg[0][6][10:0] = X74_Y64_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][7][10:2] = X74_Y64_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X74_Y64(.data(/* from design */),
		.q(X74_Y64_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X74_Y64_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X82_Y64@{S[0][11],S[0][12]}@1 */

	logic X82_Y64_incr_waddr; // ingress control
	logic X82_Y64_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_0_south_to_north_ip_size_12_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][12][0]),
		.out(X82_Y64_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_0_south_to_north_ip_size_12_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][12][1]),
		.out(X82_Y64_incr_raddr));

	logic [ADDR_WIDTH-1:0] X82_Y64_waddr;
	logic [ADDR_WIDTH-1:0] X82_Y64_raddr;

	/* positional aliases */

	wire X83_Y64_incr_waddr;
	assign X83_Y64_incr_waddr = X82_Y64_incr_waddr;
	wire [ADDR_WIDTH-1:0] X83_Y64_waddr;
	assign X83_Y64_waddr = X82_Y64_waddr;
	wire X83_Y65_incr_raddr;
	assign X83_Y65_incr_raddr = X82_Y64_incr_raddr;
	wire [ADDR_WIDTH-1:0] X83_Y65_raddr;
	assign X83_Y65_raddr = X82_Y64_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X82_Y64(.clk(bus_clock),
		.incr_waddr(X82_Y64_incr_waddr),
		.waddr(X82_Y64_waddr),
		.incr_raddr(X82_Y64_incr_raddr),
		.raddr(X82_Y64_raddr));


	/* generated from I@X83_Y64@{S[0][12],S[0][13]}@1 */

	logic [DATA_WIDTH-1:0] X83_Y64_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_0_south_to_north_ip_size_13_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][12][10:0], south_in_reg[0][13][10:2]}),
		.out(X83_Y64_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X83_Y64(.data(X83_Y64_bus_wdata),
		.q(/* to design */),
		.wraddress(X83_Y64_waddr),
		.rdaddress(/* from design */),
		.wren(X83_Y64_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X85_Y64@{N[0][14],N[0][15]}@5 */

	logic [DATA_WIDTH-1:0] X85_Y64_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X85_Y64_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_0_north_to_south_ip_size_15_bus_first_egress_fifo(.clock(bus_clock),
		.in(X85_Y64_bus_rdata_in),
		.out(X85_Y64_bus_rdata_out));

	assign south_out_reg[0][14][10:0] = X85_Y64_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][15][10:2] = X85_Y64_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X85_Y64(.data(/* from design */),
		.q(X85_Y64_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X85_Y64_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X92_Y64@{S[0][19],S[0][20]}@1 */

	logic X92_Y64_incr_waddr; // ingress control
	logic X92_Y64_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_0_south_to_north_ip_size_20_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][20][0]),
		.out(X92_Y64_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_0_south_to_north_ip_size_20_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][20][1]),
		.out(X92_Y64_incr_raddr));

	logic [ADDR_WIDTH-1:0] X92_Y64_waddr;
	logic [ADDR_WIDTH-1:0] X92_Y64_raddr;

	/* positional aliases */

	wire X93_Y64_incr_waddr;
	assign X93_Y64_incr_waddr = X92_Y64_incr_waddr;
	wire [ADDR_WIDTH-1:0] X93_Y64_waddr;
	assign X93_Y64_waddr = X92_Y64_waddr;
	wire X93_Y65_incr_raddr;
	assign X93_Y65_incr_raddr = X92_Y64_incr_raddr;
	wire [ADDR_WIDTH-1:0] X93_Y65_raddr;
	assign X93_Y65_raddr = X92_Y64_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X92_Y64(.clk(bus_clock),
		.incr_waddr(X92_Y64_incr_waddr),
		.waddr(X92_Y64_waddr),
		.incr_raddr(X92_Y64_incr_raddr),
		.raddr(X92_Y64_raddr));


	/* generated from I@X93_Y64@{S[0][20],S[0][21]}@1 */

	logic [DATA_WIDTH-1:0] X93_Y64_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_0_south_to_north_ip_size_21_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][20][10:0], south_in_reg[0][21][10:2]}),
		.out(X93_Y64_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X93_Y64(.data(X93_Y64_bus_wdata),
		.q(/* to design */),
		.wraddress(X93_Y64_waddr),
		.rdaddress(/* from design */),
		.wren(X93_Y64_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X95_Y64@{N[0][22],N[0][23]}@5 */

	logic [DATA_WIDTH-1:0] X95_Y64_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X95_Y64_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_0_north_to_south_ip_size_23_bus_first_egress_fifo(.clock(bus_clock),
		.in(X95_Y64_bus_rdata_in),
		.out(X95_Y64_bus_rdata_out));

	assign south_out_reg[0][22][10:0] = X95_Y64_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][23][10:2] = X95_Y64_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X95_Y64(.data(/* from design */),
		.q(X95_Y64_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X95_Y64_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X104_Y64@{W[0][22],W[0][21]}@2 */

	logic [DATA_WIDTH-1:0] X104_Y64_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X104_Y64_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_0_west_to_east_ip_size_21_bus_first_egress_fifo(.clock(bus_clock),
		.in(X104_Y64_bus_rdata_in),
		.out(X104_Y64_bus_rdata_out));

	assign east_out_reg[0][22][10:0] = X104_Y64_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][21][10:2] = X104_Y64_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X104_Y64(.data(/* from design */),
		.q(X104_Y64_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X104_Y64_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X114_Y64@{S[0][35],S[0][36]}@1 */

	logic X114_Y64_incr_waddr; // ingress control
	logic X114_Y64_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_0_south_to_north_ip_size_36_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][36][0]),
		.out(X114_Y64_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_0_south_to_north_ip_size_36_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][36][1]),
		.out(X114_Y64_incr_raddr));

	logic [ADDR_WIDTH-1:0] X114_Y64_waddr;
	logic [ADDR_WIDTH-1:0] X114_Y64_raddr;

	/* positional aliases */

	wire X115_Y64_incr_waddr;
	assign X115_Y64_incr_waddr = X114_Y64_incr_waddr;
	wire [ADDR_WIDTH-1:0] X115_Y64_waddr;
	assign X115_Y64_waddr = X114_Y64_waddr;
	wire X115_Y65_incr_raddr;
	assign X115_Y65_incr_raddr = X114_Y64_incr_raddr;
	wire [ADDR_WIDTH-1:0] X115_Y65_raddr;
	assign X115_Y65_raddr = X114_Y64_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X114_Y64(.clk(bus_clock),
		.incr_waddr(X114_Y64_incr_waddr),
		.waddr(X114_Y64_waddr),
		.incr_raddr(X114_Y64_incr_raddr),
		.raddr(X114_Y64_raddr));


	/* generated from I@X115_Y64@{S[0][36],S[0][37]}@1 */

	logic [DATA_WIDTH-1:0] X115_Y64_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_0_south_to_north_ip_size_37_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][36][10:0], south_in_reg[0][37][10:2]}),
		.out(X115_Y64_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X115_Y64(.data(X115_Y64_bus_wdata),
		.q(/* to design */),
		.wraddress(X115_Y64_waddr),
		.rdaddress(/* from design */),
		.wren(X115_Y64_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X117_Y64@{N[0][38],N[0][39]}@5 */

	logic [DATA_WIDTH-1:0] X117_Y64_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X117_Y64_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_0_north_to_south_ip_size_39_bus_first_egress_fifo(.clock(bus_clock),
		.in(X117_Y64_bus_rdata_in),
		.out(X117_Y64_bus_rdata_out));

	assign south_out_reg[0][38][10:0] = X117_Y64_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][39][10:2] = X117_Y64_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X117_Y64(.data(/* from design */),
		.q(X117_Y64_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X117_Y64_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X177_Y64@{S[2][5],S[2][4]}@1 */

	logic [DATA_WIDTH-1:0] X177_Y64_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_2_south_to_north_ip_size_4_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][5][10:0], south_in_reg[2][4][10:2]}),
		.out(X177_Y64_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X177_Y64(.data(X177_Y64_bus_wdata),
		.q(/* to design */),
		.wraddress(X177_Y64_waddr),
		.rdaddress(/* from design */),
		.wren(X177_Y64_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X178_Y64@{S[2][6],S[2][5]}@1 */

	logic X178_Y64_incr_waddr; // ingress control
	logic X178_Y64_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_2_south_to_north_ip_size_5_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[2][6][0]),
		.out(X178_Y64_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_2_south_to_north_ip_size_5_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[2][6][1]),
		.out(X178_Y64_incr_raddr));

	logic [ADDR_WIDTH-1:0] X178_Y64_waddr;
	logic [ADDR_WIDTH-1:0] X178_Y64_raddr;

	/* positional aliases */

	wire X177_Y64_incr_waddr;
	assign X177_Y64_incr_waddr = X178_Y64_incr_waddr;
	wire [ADDR_WIDTH-1:0] X177_Y64_waddr;
	assign X177_Y64_waddr = X178_Y64_waddr;
	wire X177_Y65_incr_raddr;
	assign X177_Y65_incr_raddr = X178_Y64_incr_raddr;
	wire [ADDR_WIDTH-1:0] X177_Y65_raddr;
	assign X177_Y65_raddr = X178_Y64_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X178_Y64(.clk(bus_clock),
		.incr_waddr(X178_Y64_incr_waddr),
		.waddr(X178_Y64_waddr),
		.incr_raddr(X178_Y64_incr_raddr),
		.raddr(X178_Y64_raddr));


	/* generated from E@X179_Y64@{N[2][7],N[2][6]}@5 */

	logic [DATA_WIDTH-1:0] X179_Y64_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X179_Y64_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_2_north_to_south_ip_size_6_bus_first_egress_fifo(.clock(bus_clock),
		.in(X179_Y64_bus_rdata_in),
		.out(X179_Y64_bus_rdata_out));

	assign south_out_reg[2][7][10:0] = X179_Y64_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][6][10:2] = X179_Y64_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X179_Y64(.data(/* from design */),
		.q(X179_Y64_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X179_Y64_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X188_Y64@{S[2][13],S[2][12]}@1 */

	logic [DATA_WIDTH-1:0] X188_Y64_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_2_south_to_north_ip_size_12_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][13][10:0], south_in_reg[2][12][10:2]}),
		.out(X188_Y64_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X188_Y64(.data(X188_Y64_bus_wdata),
		.q(/* to design */),
		.wraddress(X188_Y64_waddr),
		.rdaddress(/* from design */),
		.wren(X188_Y64_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X189_Y64@{S[2][14],S[2][13]}@1 */

	logic X189_Y64_incr_waddr; // ingress control
	logic X189_Y64_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_2_south_to_north_ip_size_13_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[2][14][0]),
		.out(X189_Y64_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_2_south_to_north_ip_size_13_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[2][14][1]),
		.out(X189_Y64_incr_raddr));

	logic [ADDR_WIDTH-1:0] X189_Y64_waddr;
	logic [ADDR_WIDTH-1:0] X189_Y64_raddr;

	/* positional aliases */

	wire X188_Y64_incr_waddr;
	assign X188_Y64_incr_waddr = X189_Y64_incr_waddr;
	wire [ADDR_WIDTH-1:0] X188_Y64_waddr;
	assign X188_Y64_waddr = X189_Y64_waddr;
	wire X188_Y65_incr_raddr;
	assign X188_Y65_incr_raddr = X189_Y64_incr_raddr;
	wire [ADDR_WIDTH-1:0] X188_Y65_raddr;
	assign X188_Y65_raddr = X189_Y64_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X189_Y64(.clk(bus_clock),
		.incr_waddr(X189_Y64_incr_waddr),
		.waddr(X189_Y64_waddr),
		.incr_raddr(X189_Y64_incr_raddr),
		.raddr(X189_Y64_raddr));


	/* generated from E@X190_Y64@{N[2][15],N[2][14]}@5 */

	logic [DATA_WIDTH-1:0] X190_Y64_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X190_Y64_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_2_north_to_south_ip_size_14_bus_first_egress_fifo(.clock(bus_clock),
		.in(X190_Y64_bus_rdata_in),
		.out(X190_Y64_bus_rdata_out));

	assign south_out_reg[2][15][10:0] = X190_Y64_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][14][10:2] = X190_Y64_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X190_Y64(.data(/* from design */),
		.q(X190_Y64_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X190_Y64_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X206_Y64@{E[0][22],E[0][21]}@2 */

	logic [DATA_WIDTH-1:0] X206_Y64_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X206_Y64_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_21_bus_first_egress_fifo(.clock(bus_clock),
		.in(X206_Y64_bus_rdata_in),
		.out(X206_Y64_bus_rdata_out));

	assign west_out_reg[0][22][10:0] = X206_Y64_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][21][10:2] = X206_Y64_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X206_Y64(.data(/* from design */),
		.q(X206_Y64_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X206_Y64_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X220_Y64@{S[2][37],S[2][36]}@1 */

	logic [DATA_WIDTH-1:0] X220_Y64_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) south_to_north_sector_size_2_south_to_north_ip_size_36_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][37][10:0], south_in_reg[2][36][10:2]}),
		.out(X220_Y64_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X220_Y64(.data(X220_Y64_bus_wdata),
		.q(/* to design */),
		.wraddress(X220_Y64_waddr),
		.rdaddress(/* from design */),
		.wren(X220_Y64_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X221_Y64@{S[2][38],S[2][37]}@1 */

	logic X221_Y64_incr_waddr; // ingress control
	logic X221_Y64_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_2_south_to_north_ip_size_37_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[2][38][0]),
		.out(X221_Y64_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) south_to_north_sector_size_2_south_to_north_ip_size_37_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[2][38][1]),
		.out(X221_Y64_incr_raddr));

	logic [ADDR_WIDTH-1:0] X221_Y64_waddr;
	logic [ADDR_WIDTH-1:0] X221_Y64_raddr;

	/* positional aliases */

	wire X220_Y64_incr_waddr;
	assign X220_Y64_incr_waddr = X221_Y64_incr_waddr;
	wire [ADDR_WIDTH-1:0] X220_Y64_waddr;
	assign X220_Y64_waddr = X221_Y64_waddr;
	wire X220_Y65_incr_raddr;
	assign X220_Y65_incr_raddr = X221_Y64_incr_raddr;
	wire [ADDR_WIDTH-1:0] X220_Y65_raddr;
	assign X220_Y65_raddr = X221_Y64_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X221_Y64(.clk(bus_clock),
		.incr_waddr(X221_Y64_incr_waddr),
		.waddr(X221_Y64_waddr),
		.incr_raddr(X221_Y64_incr_raddr),
		.raddr(X221_Y64_raddr));


	/* generated from E@X222_Y64@{N[2][39],N[2][38]}@5 */

	logic [DATA_WIDTH-1:0] X222_Y64_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X222_Y64_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) north_to_south_sector_size_2_north_to_south_ip_size_38_bus_first_egress_fifo(.clock(bus_clock),
		.in(X222_Y64_bus_rdata_in),
		.out(X222_Y64_bus_rdata_out));

	assign south_out_reg[2][39][10:0] = X222_Y64_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][38][10:2] = X222_Y64_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X222_Y64(.data(/* from design */),
		.q(X222_Y64_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X222_Y64_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X153_Y63@{E[0][20],E[0][19]}@3 */

	logic [DATA_WIDTH-1:0] X153_Y63_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) east_to_west_sector_size_0_east_to_west_ip_size_19_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][20][10:0], east_in_reg[0][19][10:2]}),
		.out(X153_Y63_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X153_Y63(.data(X153_Y63_bus_wdata),
		.q(/* to design */),
		.wraddress(X153_Y63_waddr),
		.rdaddress(/* from design */),
		.wren(X153_Y63_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X154_Y63@{E[0][20],E[0][19]}@3 */

	logic X154_Y63_incr_waddr; // ingress control
	logic X154_Y63_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) east_to_west_sector_size_0_east_to_west_ip_size_19_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][19][0]),
		.out(X154_Y63_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) east_to_west_sector_size_0_east_to_west_ip_size_19_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][19][1]),
		.out(X154_Y63_incr_raddr));

	logic [ADDR_WIDTH-1:0] X154_Y63_waddr;
	logic [ADDR_WIDTH-1:0] X154_Y63_raddr;

	/* positional aliases */

	wire X153_Y63_incr_waddr;
	assign X153_Y63_incr_waddr = X154_Y63_incr_waddr;
	wire [ADDR_WIDTH-1:0] X153_Y63_waddr;
	assign X153_Y63_waddr = X154_Y63_waddr;
	wire X153_Y62_incr_raddr;
	assign X153_Y62_incr_raddr = X154_Y63_incr_raddr;
	wire [ADDR_WIDTH-1:0] X153_Y62_raddr;
	assign X153_Y62_raddr = X154_Y63_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X154_Y63(.clk(bus_clock),
		.incr_waddr(X154_Y63_incr_waddr),
		.waddr(X154_Y63_waddr),
		.incr_raddr(X154_Y63_incr_raddr),
		.raddr(X154_Y63_raddr));


	/* generated from C@X238_Y63@{W[0][20],W[0][19]}@4 */

	logic X238_Y63_incr_waddr; // ingress control
	logic X238_Y63_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) west_to_east_sector_size_0_west_to_east_ip_size_19_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][20][0]),
		.out(X238_Y63_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) west_to_east_sector_size_0_west_to_east_ip_size_19_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][20][1]),
		.out(X238_Y63_incr_raddr));

	logic [ADDR_WIDTH-1:0] X238_Y63_waddr;
	logic [ADDR_WIDTH-1:0] X238_Y63_raddr;

	/* positional aliases */

	wire X239_Y63_incr_waddr;
	assign X239_Y63_incr_waddr = X238_Y63_incr_waddr;
	wire [ADDR_WIDTH-1:0] X239_Y63_waddr;
	assign X239_Y63_waddr = X238_Y63_waddr;
	wire X239_Y62_incr_raddr;
	assign X239_Y62_incr_raddr = X238_Y63_incr_raddr;
	wire [ADDR_WIDTH-1:0] X239_Y62_raddr;
	assign X239_Y62_raddr = X238_Y63_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X238_Y63(.clk(bus_clock),
		.incr_waddr(X238_Y63_incr_waddr),
		.waddr(X238_Y63_waddr),
		.incr_raddr(X238_Y63_incr_raddr),
		.raddr(X238_Y63_raddr));


	/* generated from I@X239_Y63@{W[0][20],W[0][19]}@4 */

	logic [DATA_WIDTH-1:0] X239_Y63_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_0_west_to_east_ip_size_19_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][20][10:0], west_in_reg[0][19][10:2]}),
		.out(X239_Y63_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X239_Y63(.data(X239_Y63_bus_wdata),
		.q(/* to design */),
		.wraddress(X239_Y63_waddr),
		.rdaddress(/* from design */),
		.wren(X239_Y63_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X153_Y62@{E[0][20],E[0][19]}@4 */

	logic [DATA_WIDTH-1:0] X153_Y62_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X153_Y62_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) east_to_west_sector_size_0_east_to_west_ip_size_19_bus_first_egress_fifo(.clock(bus_clock),
		.in(X153_Y62_bus_rdata_in),
		.out(X153_Y62_bus_rdata_out));

	assign west_out_reg[0][20][10:0] = X153_Y62_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][19][10:2] = X153_Y62_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X153_Y62(.data(/* from design */),
		.q(X153_Y62_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X153_Y62_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X239_Y62@{W[0][20],W[0][19]}@5 */

	logic [DATA_WIDTH-1:0] X239_Y62_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X239_Y62_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_19_bus_first_egress_fifo(.clock(bus_clock),
		.in(X239_Y62_bus_rdata_in),
		.out(X239_Y62_bus_rdata_out));

	assign east_out_reg[0][20][10:0] = X239_Y62_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][19][10:2] = X239_Y62_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X239_Y62(.data(/* from design */),
		.q(X239_Y62_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X239_Y62_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X126_Y61@{S[1][4],S[1][5]}@1 */

	logic [DATA_WIDTH-1:0] X126_Y61_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X126_Y61_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) south_to_north_sector_size_1_south_to_north_ip_size_5_bus_first_egress_fifo(.clock(bus_clock),
		.in(X126_Y61_bus_rdata_in),
		.out(X126_Y61_bus_rdata_out));

	assign north_out_reg[1][4][10:0] = X126_Y61_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][5][10:2] = X126_Y61_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X126_Y61(.data(/* from design */),
		.q(X126_Y61_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X126_Y61_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X127_Y61@{N[1][5],N[1][6]}@5 */

	logic X127_Y61_incr_waddr; // ingress control
	logic X127_Y61_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) north_to_south_sector_size_1_north_to_south_ip_size_6_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][6][0]),
		.out(X127_Y61_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) north_to_south_sector_size_1_north_to_south_ip_size_6_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][6][1]),
		.out(X127_Y61_incr_raddr));

	logic [ADDR_WIDTH-1:0] X127_Y61_waddr;
	logic [ADDR_WIDTH-1:0] X127_Y61_raddr;

	/* positional aliases */

	wire X128_Y61_incr_waddr;
	assign X128_Y61_incr_waddr = X127_Y61_incr_waddr;
	wire [ADDR_WIDTH-1:0] X128_Y61_waddr;
	assign X128_Y61_waddr = X127_Y61_waddr;
	wire X128_Y60_incr_raddr;
	assign X128_Y60_incr_raddr = X127_Y61_incr_raddr;
	wire [ADDR_WIDTH-1:0] X128_Y60_raddr;
	assign X128_Y60_raddr = X127_Y61_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X127_Y61(.clk(bus_clock),
		.incr_waddr(X127_Y61_incr_waddr),
		.waddr(X127_Y61_waddr),
		.incr_raddr(X127_Y61_incr_raddr),
		.raddr(X127_Y61_raddr));


	/* generated from I@X128_Y61@{N[1][6],N[1][7]}@5 */

	logic [DATA_WIDTH-1:0] X128_Y61_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) north_to_south_sector_size_1_north_to_south_ip_size_7_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][6][10:0], north_in_reg[1][7][10:2]}),
		.out(X128_Y61_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X128_Y61(.data(X128_Y61_bus_wdata),
		.q(/* to design */),
		.wraddress(X128_Y61_waddr),
		.rdaddress(/* from design */),
		.wren(X128_Y61_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X137_Y61@{S[1][12],S[1][13]}@1 */

	logic [DATA_WIDTH-1:0] X137_Y61_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X137_Y61_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) south_to_north_sector_size_1_south_to_north_ip_size_13_bus_first_egress_fifo(.clock(bus_clock),
		.in(X137_Y61_bus_rdata_in),
		.out(X137_Y61_bus_rdata_out));

	assign north_out_reg[1][12][10:0] = X137_Y61_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][13][10:2] = X137_Y61_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X137_Y61(.data(/* from design */),
		.q(X137_Y61_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X137_Y61_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X138_Y61@{N[1][13],N[1][14]}@5 */

	logic X138_Y61_incr_waddr; // ingress control
	logic X138_Y61_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) north_to_south_sector_size_1_north_to_south_ip_size_14_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][14][0]),
		.out(X138_Y61_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) north_to_south_sector_size_1_north_to_south_ip_size_14_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][14][1]),
		.out(X138_Y61_incr_raddr));

	logic [ADDR_WIDTH-1:0] X138_Y61_waddr;
	logic [ADDR_WIDTH-1:0] X138_Y61_raddr;

	/* positional aliases */

	wire X139_Y61_incr_waddr;
	assign X139_Y61_incr_waddr = X138_Y61_incr_waddr;
	wire [ADDR_WIDTH-1:0] X139_Y61_waddr;
	assign X139_Y61_waddr = X138_Y61_waddr;
	wire X139_Y60_incr_raddr;
	assign X139_Y60_incr_raddr = X138_Y61_incr_raddr;
	wire [ADDR_WIDTH-1:0] X139_Y60_raddr;
	assign X139_Y60_raddr = X138_Y61_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X138_Y61(.clk(bus_clock),
		.incr_waddr(X138_Y61_incr_waddr),
		.waddr(X138_Y61_waddr),
		.incr_raddr(X138_Y61_incr_raddr),
		.raddr(X138_Y61_raddr));


	/* generated from I@X139_Y61@{N[1][14],N[1][15]}@5 */

	logic [DATA_WIDTH-1:0] X139_Y61_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) north_to_south_sector_size_1_north_to_south_ip_size_15_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][14][10:0], north_in_reg[1][15][10:2]}),
		.out(X139_Y61_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X139_Y61(.data(X139_Y61_bus_wdata),
		.q(/* to design */),
		.wraddress(X139_Y61_waddr),
		.rdaddress(/* from design */),
		.wren(X139_Y61_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X152_Y61@{W[0][18],W[0][17]}@2 */

	logic X152_Y61_incr_waddr; // ingress control
	logic X152_Y61_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) west_to_east_sector_size_0_west_to_east_ip_size_17_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][17][0]),
		.out(X152_Y61_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) west_to_east_sector_size_0_west_to_east_ip_size_17_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][17][1]),
		.out(X152_Y61_incr_raddr));

	logic [ADDR_WIDTH-1:0] X152_Y61_waddr;
	logic [ADDR_WIDTH-1:0] X152_Y61_raddr;

	/* positional aliases */

	wire X153_Y61_incr_waddr;
	assign X153_Y61_incr_waddr = X152_Y61_incr_waddr;
	wire [ADDR_WIDTH-1:0] X153_Y61_waddr;
	assign X153_Y61_waddr = X152_Y61_waddr;
	wire X153_Y60_incr_raddr;
	assign X153_Y60_incr_raddr = X152_Y61_incr_raddr;
	wire [ADDR_WIDTH-1:0] X153_Y60_raddr;
	assign X153_Y60_raddr = X152_Y61_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X152_Y61(.clk(bus_clock),
		.incr_waddr(X152_Y61_incr_waddr),
		.waddr(X152_Y61_waddr),
		.incr_raddr(X152_Y61_incr_raddr),
		.raddr(X152_Y61_raddr));


	/* generated from I@X153_Y61@{W[0][18],W[0][17]}@2 */

	logic [DATA_WIDTH-1:0] X153_Y61_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) west_to_east_sector_size_0_west_to_east_ip_size_17_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][18][10:0], west_in_reg[0][17][10:2]}),
		.out(X153_Y61_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X153_Y61(.data(X153_Y61_bus_wdata),
		.q(/* to design */),
		.wraddress(X153_Y61_waddr),
		.rdaddress(/* from design */),
		.wren(X153_Y61_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X169_Y61@{S[1][36],S[1][37]}@1 */

	logic [DATA_WIDTH-1:0] X169_Y61_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X169_Y61_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) south_to_north_sector_size_1_south_to_north_ip_size_37_bus_first_egress_fifo(.clock(bus_clock),
		.in(X169_Y61_bus_rdata_in),
		.out(X169_Y61_bus_rdata_out));

	assign north_out_reg[1][36][10:0] = X169_Y61_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[1][37][10:2] = X169_Y61_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X169_Y61(.data(/* from design */),
		.q(X169_Y61_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X169_Y61_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X170_Y61@{N[1][37],N[1][38]}@5 */

	logic X170_Y61_incr_waddr; // ingress control
	logic X170_Y61_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) north_to_south_sector_size_1_north_to_south_ip_size_38_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[1][38][0]),
		.out(X170_Y61_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) north_to_south_sector_size_1_north_to_south_ip_size_38_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[1][38][1]),
		.out(X170_Y61_incr_raddr));

	logic [ADDR_WIDTH-1:0] X170_Y61_waddr;
	logic [ADDR_WIDTH-1:0] X170_Y61_raddr;

	/* positional aliases */

	wire X171_Y61_incr_waddr;
	assign X171_Y61_incr_waddr = X170_Y61_incr_waddr;
	wire [ADDR_WIDTH-1:0] X171_Y61_waddr;
	assign X171_Y61_waddr = X170_Y61_waddr;
	wire X171_Y60_incr_raddr;
	assign X171_Y60_incr_raddr = X170_Y61_incr_raddr;
	wire [ADDR_WIDTH-1:0] X171_Y60_raddr;
	assign X171_Y60_raddr = X170_Y61_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X170_Y61(.clk(bus_clock),
		.incr_waddr(X170_Y61_incr_waddr),
		.waddr(X170_Y61_waddr),
		.incr_raddr(X170_Y61_incr_raddr),
		.raddr(X170_Y61_raddr));


	/* generated from I@X171_Y61@{N[1][38],N[1][39]}@5 */

	logic [DATA_WIDTH-1:0] X171_Y61_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) north_to_south_sector_size_1_north_to_south_ip_size_39_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[1][38][10:0], north_in_reg[1][39][10:2]}),
		.out(X171_Y61_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X171_Y61(.data(X171_Y61_bus_wdata),
		.q(/* to design */),
		.wraddress(X171_Y61_waddr),
		.rdaddress(/* from design */),
		.wren(X171_Y61_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from I@X239_Y61@{E[0][18],E[0][17]}@1 */

	logic [DATA_WIDTH-1:0] X239_Y61_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_17_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][18][10:0], east_in_reg[0][17][10:2]}),
		.out(X239_Y61_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X239_Y61(.data(X239_Y61_bus_wdata),
		.q(/* to design */),
		.wraddress(X239_Y61_waddr),
		.rdaddress(/* from design */),
		.wren(X239_Y61_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X240_Y61@{E[0][18],E[0][17]}@1 */

	logic X240_Y61_incr_waddr; // ingress control
	logic X240_Y61_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_17_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][18][0]),
		.out(X240_Y61_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_17_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][18][1]),
		.out(X240_Y61_incr_raddr));

	logic [ADDR_WIDTH-1:0] X240_Y61_waddr;
	logic [ADDR_WIDTH-1:0] X240_Y61_raddr;

	/* positional aliases */

	wire X239_Y61_incr_waddr;
	assign X239_Y61_incr_waddr = X240_Y61_incr_waddr;
	wire [ADDR_WIDTH-1:0] X239_Y61_waddr;
	assign X239_Y61_waddr = X240_Y61_waddr;
	wire X239_Y60_incr_raddr;
	assign X239_Y60_incr_raddr = X240_Y61_incr_raddr;
	wire [ADDR_WIDTH-1:0] X239_Y60_raddr;
	assign X239_Y60_raddr = X240_Y61_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X240_Y61(.clk(bus_clock),
		.incr_waddr(X240_Y61_incr_waddr),
		.waddr(X240_Y61_waddr),
		.incr_raddr(X240_Y61_incr_raddr),
		.raddr(X240_Y61_raddr));


	/* generated from E@X253_Y61@{S[3][21],S[3][20]}@1 */

	logic [DATA_WIDTH-1:0] X253_Y61_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X253_Y61_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) south_to_north_sector_size_3_south_to_north_ip_size_20_bus_first_egress_fifo(.clock(bus_clock),
		.in(X253_Y61_bus_rdata_in),
		.out(X253_Y61_bus_rdata_out));

	assign north_out_reg[3][21][10:0] = X253_Y61_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][20][10:2] = X253_Y61_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X253_Y61(.data(/* from design */),
		.q(X253_Y61_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X253_Y61_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X255_Y61@{N[3][23],N[3][22]}@5 */

	logic [DATA_WIDTH-1:0] X255_Y61_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) north_to_south_sector_size_3_north_to_south_ip_size_22_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][23][10:0], north_in_reg[3][22][10:2]}),
		.out(X255_Y61_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X255_Y61(.data(X255_Y61_bus_wdata),
		.q(/* to design */),
		.wraddress(X255_Y61_waddr),
		.rdaddress(/* from design */),
		.wren(X255_Y61_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X256_Y61@{N[3][24],N[3][23]}@5 */

	logic X256_Y61_incr_waddr; // ingress control
	logic X256_Y61_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) north_to_south_sector_size_3_north_to_south_ip_size_23_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][24][0]),
		.out(X256_Y61_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) north_to_south_sector_size_3_north_to_south_ip_size_23_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][24][1]),
		.out(X256_Y61_incr_raddr));

	logic [ADDR_WIDTH-1:0] X256_Y61_waddr;
	logic [ADDR_WIDTH-1:0] X256_Y61_raddr;

	/* positional aliases */

	wire X255_Y61_incr_waddr;
	assign X255_Y61_incr_waddr = X256_Y61_incr_waddr;
	wire [ADDR_WIDTH-1:0] X255_Y61_waddr;
	assign X255_Y61_waddr = X256_Y61_waddr;
	wire X255_Y60_incr_raddr;
	assign X255_Y60_incr_raddr = X256_Y61_incr_raddr;
	wire [ADDR_WIDTH-1:0] X255_Y60_raddr;
	assign X255_Y60_raddr = X256_Y61_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X256_Y61(.clk(bus_clock),
		.incr_waddr(X256_Y61_incr_waddr),
		.waddr(X256_Y61_waddr),
		.incr_raddr(X256_Y61_incr_raddr),
		.raddr(X256_Y61_raddr));


	/* generated from E@X263_Y61@{S[3][29],S[3][28]}@1 */

	logic [DATA_WIDTH-1:0] X263_Y61_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X263_Y61_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) south_to_north_sector_size_3_south_to_north_ip_size_28_bus_first_egress_fifo(.clock(bus_clock),
		.in(X263_Y61_bus_rdata_in),
		.out(X263_Y61_bus_rdata_out));

	assign north_out_reg[3][29][10:0] = X263_Y61_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[3][28][10:2] = X263_Y61_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X263_Y61(.data(/* from design */),
		.q(X263_Y61_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X263_Y61_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X265_Y61@{N[3][31],N[3][30]}@5 */

	logic [DATA_WIDTH-1:0] X265_Y61_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) north_to_south_sector_size_3_north_to_south_ip_size_30_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[3][31][10:0], north_in_reg[3][30][10:2]}),
		.out(X265_Y61_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X265_Y61(.data(X265_Y61_bus_wdata),
		.q(/* to design */),
		.wraddress(X265_Y61_waddr),
		.rdaddress(/* from design */),
		.wren(X265_Y61_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X266_Y61@{N[3][32],N[3][31]}@5 */

	logic X266_Y61_incr_waddr; // ingress control
	logic X266_Y61_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) north_to_south_sector_size_3_north_to_south_ip_size_31_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[3][32][0]),
		.out(X266_Y61_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) north_to_south_sector_size_3_north_to_south_ip_size_31_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[3][32][1]),
		.out(X266_Y61_incr_raddr));

	logic [ADDR_WIDTH-1:0] X266_Y61_waddr;
	logic [ADDR_WIDTH-1:0] X266_Y61_raddr;

	/* positional aliases */

	wire X265_Y61_incr_waddr;
	assign X265_Y61_incr_waddr = X266_Y61_incr_waddr;
	wire [ADDR_WIDTH-1:0] X265_Y61_waddr;
	assign X265_Y61_waddr = X266_Y61_waddr;
	wire X265_Y60_incr_raddr;
	assign X265_Y60_incr_raddr = X266_Y61_incr_raddr;
	wire [ADDR_WIDTH-1:0] X265_Y60_raddr;
	assign X265_Y60_raddr = X266_Y61_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X266_Y61(.clk(bus_clock),
		.incr_waddr(X266_Y61_incr_waddr),
		.waddr(X266_Y61_waddr),
		.incr_raddr(X266_Y61_incr_raddr),
		.raddr(X266_Y61_raddr));


	/* generated from C@X125_Y60@{S[1][3],S[1][4]}@0 */

	logic X125_Y60_incr_waddr; // ingress control
	logic X125_Y60_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) south_to_north_sector_size_1_south_to_north_ip_size_4_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][4][0]),
		.out(X125_Y60_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) south_to_north_sector_size_1_south_to_north_ip_size_4_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][4][1]),
		.out(X125_Y60_incr_raddr));

	logic [ADDR_WIDTH-1:0] X125_Y60_waddr;
	logic [ADDR_WIDTH-1:0] X125_Y60_raddr;

	/* positional aliases */

	wire X126_Y60_incr_waddr;
	assign X126_Y60_incr_waddr = X125_Y60_incr_waddr;
	wire [ADDR_WIDTH-1:0] X126_Y60_waddr;
	assign X126_Y60_waddr = X125_Y60_waddr;
	wire X126_Y61_incr_raddr;
	assign X126_Y61_incr_raddr = X125_Y60_incr_raddr;
	wire [ADDR_WIDTH-1:0] X126_Y61_raddr;
	assign X126_Y61_raddr = X125_Y60_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X125_Y60(.clk(bus_clock),
		.incr_waddr(X125_Y60_incr_waddr),
		.waddr(X125_Y60_waddr),
		.incr_raddr(X125_Y60_incr_raddr),
		.raddr(X125_Y60_raddr));


	/* generated from I@X126_Y60@{S[1][4],S[1][5]}@0 */

	logic [DATA_WIDTH-1:0] X126_Y60_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) south_to_north_sector_size_1_south_to_north_ip_size_5_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][4][10:0], south_in_reg[1][5][10:2]}),
		.out(X126_Y60_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X126_Y60(.data(X126_Y60_bus_wdata),
		.q(/* to design */),
		.wraddress(X126_Y60_waddr),
		.rdaddress(/* from design */),
		.wren(X126_Y60_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X128_Y60@{N[1][6],N[1][7]}@6 */

	logic [DATA_WIDTH-1:0] X128_Y60_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X128_Y60_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) north_to_south_sector_size_1_north_to_south_ip_size_7_bus_first_egress_fifo(.clock(bus_clock),
		.in(X128_Y60_bus_rdata_in),
		.out(X128_Y60_bus_rdata_out));

	assign south_out_reg[1][6][10:0] = X128_Y60_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][7][10:2] = X128_Y60_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X128_Y60(.data(/* from design */),
		.q(X128_Y60_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X128_Y60_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X136_Y60@{S[1][11],S[1][12]}@0 */

	logic X136_Y60_incr_waddr; // ingress control
	logic X136_Y60_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) south_to_north_sector_size_1_south_to_north_ip_size_12_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][12][0]),
		.out(X136_Y60_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) south_to_north_sector_size_1_south_to_north_ip_size_12_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][12][1]),
		.out(X136_Y60_incr_raddr));

	logic [ADDR_WIDTH-1:0] X136_Y60_waddr;
	logic [ADDR_WIDTH-1:0] X136_Y60_raddr;

	/* positional aliases */

	wire X137_Y60_incr_waddr;
	assign X137_Y60_incr_waddr = X136_Y60_incr_waddr;
	wire [ADDR_WIDTH-1:0] X137_Y60_waddr;
	assign X137_Y60_waddr = X136_Y60_waddr;
	wire X137_Y61_incr_raddr;
	assign X137_Y61_incr_raddr = X136_Y60_incr_raddr;
	wire [ADDR_WIDTH-1:0] X137_Y61_raddr;
	assign X137_Y61_raddr = X136_Y60_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X136_Y60(.clk(bus_clock),
		.incr_waddr(X136_Y60_incr_waddr),
		.waddr(X136_Y60_waddr),
		.incr_raddr(X136_Y60_incr_raddr),
		.raddr(X136_Y60_raddr));


	/* generated from I@X137_Y60@{S[1][12],S[1][13]}@0 */

	logic [DATA_WIDTH-1:0] X137_Y60_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) south_to_north_sector_size_1_south_to_north_ip_size_13_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][12][10:0], south_in_reg[1][13][10:2]}),
		.out(X137_Y60_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X137_Y60(.data(X137_Y60_bus_wdata),
		.q(/* to design */),
		.wraddress(X137_Y60_waddr),
		.rdaddress(/* from design */),
		.wren(X137_Y60_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X139_Y60@{N[1][14],N[1][15]}@6 */

	logic [DATA_WIDTH-1:0] X139_Y60_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X139_Y60_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) north_to_south_sector_size_1_north_to_south_ip_size_15_bus_first_egress_fifo(.clock(bus_clock),
		.in(X139_Y60_bus_rdata_in),
		.out(X139_Y60_bus_rdata_out));

	assign south_out_reg[1][14][10:0] = X139_Y60_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][15][10:2] = X139_Y60_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X139_Y60(.data(/* from design */),
		.q(X139_Y60_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X139_Y60_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X153_Y60@{W[0][18],W[0][17]}@3 */

	logic [DATA_WIDTH-1:0] X153_Y60_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X153_Y60_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) west_to_east_sector_size_0_west_to_east_ip_size_17_bus_first_egress_fifo(.clock(bus_clock),
		.in(X153_Y60_bus_rdata_in),
		.out(X153_Y60_bus_rdata_out));

	assign east_out_reg[0][18][10:0] = X153_Y60_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][17][10:2] = X153_Y60_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X153_Y60(.data(/* from design */),
		.q(X153_Y60_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X153_Y60_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X168_Y60@{S[1][35],S[1][36]}@0 */

	logic X168_Y60_incr_waddr; // ingress control
	logic X168_Y60_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) south_to_north_sector_size_1_south_to_north_ip_size_36_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[1][36][0]),
		.out(X168_Y60_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) south_to_north_sector_size_1_south_to_north_ip_size_36_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[1][36][1]),
		.out(X168_Y60_incr_raddr));

	logic [ADDR_WIDTH-1:0] X168_Y60_waddr;
	logic [ADDR_WIDTH-1:0] X168_Y60_raddr;

	/* positional aliases */

	wire X169_Y60_incr_waddr;
	assign X169_Y60_incr_waddr = X168_Y60_incr_waddr;
	wire [ADDR_WIDTH-1:0] X169_Y60_waddr;
	assign X169_Y60_waddr = X168_Y60_waddr;
	wire X169_Y61_incr_raddr;
	assign X169_Y61_incr_raddr = X168_Y60_incr_raddr;
	wire [ADDR_WIDTH-1:0] X169_Y61_raddr;
	assign X169_Y61_raddr = X168_Y60_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X168_Y60(.clk(bus_clock),
		.incr_waddr(X168_Y60_incr_waddr),
		.waddr(X168_Y60_waddr),
		.incr_raddr(X168_Y60_incr_raddr),
		.raddr(X168_Y60_raddr));


	/* generated from I@X169_Y60@{S[1][36],S[1][37]}@0 */

	logic [DATA_WIDTH-1:0] X169_Y60_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) south_to_north_sector_size_1_south_to_north_ip_size_37_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[1][36][10:0], south_in_reg[1][37][10:2]}),
		.out(X169_Y60_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X169_Y60(.data(X169_Y60_bus_wdata),
		.q(/* to design */),
		.wraddress(X169_Y60_waddr),
		.rdaddress(/* from design */),
		.wren(X169_Y60_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X171_Y60@{N[1][38],N[1][39]}@6 */

	logic [DATA_WIDTH-1:0] X171_Y60_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X171_Y60_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) north_to_south_sector_size_1_north_to_south_ip_size_39_bus_first_egress_fifo(.clock(bus_clock),
		.in(X171_Y60_bus_rdata_in),
		.out(X171_Y60_bus_rdata_out));

	assign south_out_reg[1][38][10:0] = X171_Y60_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[1][39][10:2] = X171_Y60_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X171_Y60(.data(/* from design */),
		.q(X171_Y60_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X171_Y60_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X239_Y60@{E[0][18],E[0][17]}@2 */

	logic [DATA_WIDTH-1:0] X239_Y60_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X239_Y60_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_17_bus_first_egress_fifo(.clock(bus_clock),
		.in(X239_Y60_bus_rdata_in),
		.out(X239_Y60_bus_rdata_out));

	assign west_out_reg[0][18][10:0] = X239_Y60_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][17][10:2] = X239_Y60_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X239_Y60(.data(/* from design */),
		.q(X239_Y60_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X239_Y60_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X253_Y60@{S[3][21],S[3][20]}@0 */

	logic [DATA_WIDTH-1:0] X253_Y60_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) south_to_north_sector_size_3_south_to_north_ip_size_20_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][21][10:0], south_in_reg[3][20][10:2]}),
		.out(X253_Y60_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X253_Y60(.data(X253_Y60_bus_wdata),
		.q(/* to design */),
		.wraddress(X253_Y60_waddr),
		.rdaddress(/* from design */),
		.wren(X253_Y60_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X254_Y60@{S[3][22],S[3][21]}@0 */

	logic X254_Y60_incr_waddr; // ingress control
	logic X254_Y60_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) south_to_north_sector_size_3_south_to_north_ip_size_21_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][22][0]),
		.out(X254_Y60_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) south_to_north_sector_size_3_south_to_north_ip_size_21_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][22][1]),
		.out(X254_Y60_incr_raddr));

	logic [ADDR_WIDTH-1:0] X254_Y60_waddr;
	logic [ADDR_WIDTH-1:0] X254_Y60_raddr;

	/* positional aliases */

	wire X253_Y60_incr_waddr;
	assign X253_Y60_incr_waddr = X254_Y60_incr_waddr;
	wire [ADDR_WIDTH-1:0] X253_Y60_waddr;
	assign X253_Y60_waddr = X254_Y60_waddr;
	wire X253_Y61_incr_raddr;
	assign X253_Y61_incr_raddr = X254_Y60_incr_raddr;
	wire [ADDR_WIDTH-1:0] X253_Y61_raddr;
	assign X253_Y61_raddr = X254_Y60_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X254_Y60(.clk(bus_clock),
		.incr_waddr(X254_Y60_incr_waddr),
		.waddr(X254_Y60_waddr),
		.incr_raddr(X254_Y60_incr_raddr),
		.raddr(X254_Y60_raddr));


	/* generated from E@X255_Y60@{N[3][23],N[3][22]}@6 */

	logic [DATA_WIDTH-1:0] X255_Y60_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X255_Y60_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) north_to_south_sector_size_3_north_to_south_ip_size_22_bus_first_egress_fifo(.clock(bus_clock),
		.in(X255_Y60_bus_rdata_in),
		.out(X255_Y60_bus_rdata_out));

	assign south_out_reg[3][23][10:0] = X255_Y60_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][22][10:2] = X255_Y60_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X255_Y60(.data(/* from design */),
		.q(X255_Y60_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X255_Y60_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X263_Y60@{S[3][29],S[3][28]}@0 */

	logic [DATA_WIDTH-1:0] X263_Y60_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) south_to_north_sector_size_3_south_to_north_ip_size_28_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[3][29][10:0], south_in_reg[3][28][10:2]}),
		.out(X263_Y60_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X263_Y60(.data(X263_Y60_bus_wdata),
		.q(/* to design */),
		.wraddress(X263_Y60_waddr),
		.rdaddress(/* from design */),
		.wren(X263_Y60_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X264_Y60@{S[3][30],S[3][29]}@0 */

	logic X264_Y60_incr_waddr; // ingress control
	logic X264_Y60_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) south_to_north_sector_size_3_south_to_north_ip_size_29_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[3][30][0]),
		.out(X264_Y60_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) south_to_north_sector_size_3_south_to_north_ip_size_29_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[3][30][1]),
		.out(X264_Y60_incr_raddr));

	logic [ADDR_WIDTH-1:0] X264_Y60_waddr;
	logic [ADDR_WIDTH-1:0] X264_Y60_raddr;

	/* positional aliases */

	wire X263_Y60_incr_waddr;
	assign X263_Y60_incr_waddr = X264_Y60_incr_waddr;
	wire [ADDR_WIDTH-1:0] X263_Y60_waddr;
	assign X263_Y60_waddr = X264_Y60_waddr;
	wire X263_Y61_incr_raddr;
	assign X263_Y61_incr_raddr = X264_Y60_incr_raddr;
	wire [ADDR_WIDTH-1:0] X263_Y61_raddr;
	assign X263_Y61_raddr = X264_Y60_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X264_Y60(.clk(bus_clock),
		.incr_waddr(X264_Y60_incr_waddr),
		.waddr(X264_Y60_waddr),
		.incr_raddr(X264_Y60_incr_raddr),
		.raddr(X264_Y60_raddr));


	/* generated from E@X265_Y60@{N[3][31],N[3][30]}@6 */

	logic [DATA_WIDTH-1:0] X265_Y60_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X265_Y60_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) north_to_south_sector_size_3_north_to_south_ip_size_30_bus_first_egress_fifo(.clock(bus_clock),
		.in(X265_Y60_bus_rdata_in),
		.out(X265_Y60_bus_rdata_out));

	assign south_out_reg[3][31][10:0] = X265_Y60_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[3][30][10:2] = X265_Y60_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X265_Y60(.data(/* from design */),
		.q(X265_Y60_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X265_Y60_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X83_Y59@{E[0][16],E[0][15]}@5 */

	logic [DATA_WIDTH-1:0] X83_Y59_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) east_to_west_sector_size_0_east_to_west_ip_size_15_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][16][10:0], east_in_reg[0][15][10:2]}),
		.out(X83_Y59_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X83_Y59(.data(X83_Y59_bus_wdata),
		.q(/* to design */),
		.wraddress(X83_Y59_waddr),
		.rdaddress(/* from design */),
		.wren(X83_Y59_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X84_Y59@{E[0][16],E[0][15]}@5 */

	logic X84_Y59_incr_waddr; // ingress control
	logic X84_Y59_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) east_to_west_sector_size_0_east_to_west_ip_size_15_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][15][0]),
		.out(X84_Y59_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) east_to_west_sector_size_0_east_to_west_ip_size_15_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][15][1]),
		.out(X84_Y59_incr_raddr));

	logic [ADDR_WIDTH-1:0] X84_Y59_waddr;
	logic [ADDR_WIDTH-1:0] X84_Y59_raddr;

	/* positional aliases */

	wire X83_Y59_incr_waddr;
	assign X83_Y59_incr_waddr = X84_Y59_incr_waddr;
	wire [ADDR_WIDTH-1:0] X83_Y59_waddr;
	assign X83_Y59_waddr = X84_Y59_waddr;
	wire X83_Y58_incr_raddr;
	assign X83_Y58_incr_raddr = X84_Y59_incr_raddr;
	wire [ADDR_WIDTH-1:0] X83_Y58_raddr;
	assign X83_Y58_raddr = X84_Y59_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X84_Y59(.clk(bus_clock),
		.incr_waddr(X84_Y59_incr_waddr),
		.waddr(X84_Y59_waddr),
		.incr_raddr(X84_Y59_incr_raddr),
		.raddr(X84_Y59_raddr));


	/* generated from C@X184_Y59@{W[0][16],W[0][15]}@3 */

	logic X184_Y59_incr_waddr; // ingress control
	logic X184_Y59_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_0_west_to_east_ip_size_15_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][16][0]),
		.out(X184_Y59_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_0_west_to_east_ip_size_15_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][16][1]),
		.out(X184_Y59_incr_raddr));

	logic [ADDR_WIDTH-1:0] X184_Y59_waddr;
	logic [ADDR_WIDTH-1:0] X184_Y59_raddr;

	/* positional aliases */

	wire X185_Y59_incr_waddr;
	assign X185_Y59_incr_waddr = X184_Y59_incr_waddr;
	wire [ADDR_WIDTH-1:0] X185_Y59_waddr;
	assign X185_Y59_waddr = X184_Y59_waddr;
	wire X185_Y58_incr_raddr;
	assign X185_Y58_incr_raddr = X184_Y59_incr_raddr;
	wire [ADDR_WIDTH-1:0] X185_Y58_raddr;
	assign X185_Y58_raddr = X184_Y59_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X184_Y59(.clk(bus_clock),
		.incr_waddr(X184_Y59_incr_waddr),
		.waddr(X184_Y59_waddr),
		.incr_raddr(X184_Y59_incr_raddr),
		.raddr(X184_Y59_raddr));


	/* generated from I@X185_Y59@{W[0][16],W[0][15]}@3 */

	logic [DATA_WIDTH-1:0] X185_Y59_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) west_to_east_sector_size_0_west_to_east_ip_size_15_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][16][10:0], west_in_reg[0][15][10:2]}),
		.out(X185_Y59_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X185_Y59(.data(X185_Y59_bus_wdata),
		.q(/* to design */),
		.wraddress(X185_Y59_waddr),
		.rdaddress(/* from design */),
		.wren(X185_Y59_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X83_Y58@{E[0][16],E[0][15]}@6 */

	logic [DATA_WIDTH-1:0] X83_Y58_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X83_Y58_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) east_to_west_sector_size_0_east_to_west_ip_size_15_bus_first_egress_fifo(.clock(bus_clock),
		.in(X83_Y58_bus_rdata_in),
		.out(X83_Y58_bus_rdata_out));

	assign west_out_reg[0][16][10:0] = X83_Y58_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][15][10:2] = X83_Y58_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X83_Y58(.data(/* from design */),
		.q(X83_Y58_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X83_Y58_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X185_Y58@{W[0][16],W[0][15]}@4 */

	logic [DATA_WIDTH-1:0] X185_Y58_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X185_Y58_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) west_to_east_sector_size_0_west_to_east_ip_size_15_bus_first_egress_fifo(.clock(bus_clock),
		.in(X185_Y58_bus_rdata_in),
		.out(X185_Y58_bus_rdata_out));

	assign east_out_reg[0][16][10:0] = X185_Y58_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][15][10:2] = X185_Y58_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X185_Y58(.data(/* from design */),
		.q(X185_Y58_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X185_Y58_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X82_Y57@{W[0][14],W[0][13]}@0 */

	logic X82_Y57_incr_waddr; // ingress control
	logic X82_Y57_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) west_to_east_sector_size_0_west_to_east_ip_size_13_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][13][0]),
		.out(X82_Y57_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) west_to_east_sector_size_0_west_to_east_ip_size_13_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][13][1]),
		.out(X82_Y57_incr_raddr));

	logic [ADDR_WIDTH-1:0] X82_Y57_waddr;
	logic [ADDR_WIDTH-1:0] X82_Y57_raddr;

	/* positional aliases */

	wire X83_Y57_incr_waddr;
	assign X83_Y57_incr_waddr = X82_Y57_incr_waddr;
	wire [ADDR_WIDTH-1:0] X83_Y57_waddr;
	assign X83_Y57_waddr = X82_Y57_waddr;
	wire X83_Y56_incr_raddr;
	assign X83_Y56_incr_raddr = X82_Y57_incr_raddr;
	wire [ADDR_WIDTH-1:0] X83_Y56_raddr;
	assign X83_Y56_raddr = X82_Y57_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X82_Y57(.clk(bus_clock),
		.incr_waddr(X82_Y57_incr_waddr),
		.waddr(X82_Y57_waddr),
		.incr_raddr(X82_Y57_incr_raddr),
		.raddr(X82_Y57_raddr));


	/* generated from I@X83_Y57@{W[0][14],W[0][13]}@0 */

	logic [DATA_WIDTH-1:0] X83_Y57_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) west_to_east_sector_size_0_west_to_east_ip_size_13_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][14][10:0], west_in_reg[0][13][10:2]}),
		.out(X83_Y57_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X83_Y57(.data(X83_Y57_bus_wdata),
		.q(/* to design */),
		.wraddress(X83_Y57_waddr),
		.rdaddress(/* from design */),
		.wren(X83_Y57_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X104_Y57@{S[0][28],S[0][29]}@1 */

	logic [DATA_WIDTH-1:0] X104_Y57_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X104_Y57_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) south_to_north_sector_size_0_south_to_north_ip_size_29_bus_first_egress_fifo(.clock(bus_clock),
		.in(X104_Y57_bus_rdata_in),
		.out(X104_Y57_bus_rdata_out));

	assign north_out_reg[0][28][10:0] = X104_Y57_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[0][29][10:2] = X104_Y57_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X104_Y57(.data(/* from design */),
		.q(X104_Y57_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X104_Y57_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X105_Y57@{N[0][29],N[0][30]}@5 */

	logic X105_Y57_incr_waddr; // ingress control
	logic X105_Y57_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) north_to_south_sector_size_0_north_to_south_ip_size_30_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[0][30][0]),
		.out(X105_Y57_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) north_to_south_sector_size_0_north_to_south_ip_size_30_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[0][30][1]),
		.out(X105_Y57_incr_raddr));

	logic [ADDR_WIDTH-1:0] X105_Y57_waddr;
	logic [ADDR_WIDTH-1:0] X105_Y57_raddr;

	/* positional aliases */

	wire X106_Y57_incr_waddr;
	assign X106_Y57_incr_waddr = X105_Y57_incr_waddr;
	wire [ADDR_WIDTH-1:0] X106_Y57_waddr;
	assign X106_Y57_waddr = X105_Y57_waddr;
	wire X106_Y56_incr_raddr;
	assign X106_Y56_incr_raddr = X105_Y57_incr_raddr;
	wire [ADDR_WIDTH-1:0] X106_Y56_raddr;
	assign X106_Y56_raddr = X105_Y57_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X105_Y57(.clk(bus_clock),
		.incr_waddr(X105_Y57_incr_waddr),
		.waddr(X105_Y57_waddr),
		.incr_raddr(X105_Y57_incr_raddr),
		.raddr(X105_Y57_raddr));


	/* generated from I@X106_Y57@{N[0][30],N[0][31]}@5 */

	logic [DATA_WIDTH-1:0] X106_Y57_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) north_to_south_sector_size_0_north_to_south_ip_size_31_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[0][30][10:0], north_in_reg[0][31][10:2]}),
		.out(X106_Y57_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X106_Y57(.data(X106_Y57_bus_wdata),
		.q(/* to design */),
		.wraddress(X106_Y57_waddr),
		.rdaddress(/* from design */),
		.wren(X106_Y57_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from I@X185_Y57@{E[0][14],E[0][13]}@2 */

	logic [DATA_WIDTH-1:0] X185_Y57_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) east_to_west_sector_size_0_east_to_west_ip_size_13_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][14][10:0], east_in_reg[0][13][10:2]}),
		.out(X185_Y57_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X185_Y57(.data(X185_Y57_bus_wdata),
		.q(/* to design */),
		.wraddress(X185_Y57_waddr),
		.rdaddress(/* from design */),
		.wren(X185_Y57_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X186_Y57@{E[0][14],E[0][13]}@2 */

	logic X186_Y57_incr_waddr; // ingress control
	logic X186_Y57_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) east_to_west_sector_size_0_east_to_west_ip_size_13_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][14][0]),
		.out(X186_Y57_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) east_to_west_sector_size_0_east_to_west_ip_size_13_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][14][1]),
		.out(X186_Y57_incr_raddr));

	logic [ADDR_WIDTH-1:0] X186_Y57_waddr;
	logic [ADDR_WIDTH-1:0] X186_Y57_raddr;

	/* positional aliases */

	wire X185_Y57_incr_waddr;
	assign X185_Y57_incr_waddr = X186_Y57_incr_waddr;
	wire [ADDR_WIDTH-1:0] X185_Y57_waddr;
	assign X185_Y57_waddr = X186_Y57_waddr;
	wire X185_Y56_incr_raddr;
	assign X185_Y56_incr_raddr = X186_Y57_incr_raddr;
	wire [ADDR_WIDTH-1:0] X185_Y56_raddr;
	assign X185_Y56_raddr = X186_Y57_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X186_Y57(.clk(bus_clock),
		.incr_waddr(X186_Y57_incr_waddr),
		.waddr(X186_Y57_waddr),
		.incr_raddr(X186_Y57_incr_raddr),
		.raddr(X186_Y57_raddr));


	/* generated from E@X199_Y57@{S[2][21],S[2][20]}@1 */

	logic [DATA_WIDTH-1:0] X199_Y57_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X199_Y57_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) south_to_north_sector_size_2_south_to_north_ip_size_20_bus_first_egress_fifo(.clock(bus_clock),
		.in(X199_Y57_bus_rdata_in),
		.out(X199_Y57_bus_rdata_out));

	assign north_out_reg[2][21][10:0] = X199_Y57_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][20][10:2] = X199_Y57_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X199_Y57(.data(/* from design */),
		.q(X199_Y57_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X199_Y57_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X201_Y57@{N[2][23],N[2][22]}@5 */

	logic [DATA_WIDTH-1:0] X201_Y57_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) north_to_south_sector_size_2_north_to_south_ip_size_22_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][23][10:0], north_in_reg[2][22][10:2]}),
		.out(X201_Y57_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X201_Y57(.data(X201_Y57_bus_wdata),
		.q(/* to design */),
		.wraddress(X201_Y57_waddr),
		.rdaddress(/* from design */),
		.wren(X201_Y57_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X202_Y57@{N[2][24],N[2][23]}@5 */

	logic X202_Y57_incr_waddr; // ingress control
	logic X202_Y57_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) north_to_south_sector_size_2_north_to_south_ip_size_23_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[2][24][0]),
		.out(X202_Y57_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) north_to_south_sector_size_2_north_to_south_ip_size_23_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[2][24][1]),
		.out(X202_Y57_incr_raddr));

	logic [ADDR_WIDTH-1:0] X202_Y57_waddr;
	logic [ADDR_WIDTH-1:0] X202_Y57_raddr;

	/* positional aliases */

	wire X201_Y57_incr_waddr;
	assign X201_Y57_incr_waddr = X202_Y57_incr_waddr;
	wire [ADDR_WIDTH-1:0] X201_Y57_waddr;
	assign X201_Y57_waddr = X202_Y57_waddr;
	wire X201_Y56_incr_raddr;
	assign X201_Y56_incr_raddr = X202_Y57_incr_raddr;
	wire [ADDR_WIDTH-1:0] X201_Y56_raddr;
	assign X201_Y56_raddr = X202_Y57_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X202_Y57(.clk(bus_clock),
		.incr_waddr(X202_Y57_incr_waddr),
		.waddr(X202_Y57_waddr),
		.incr_raddr(X202_Y57_incr_raddr),
		.raddr(X202_Y57_raddr));


	/* generated from E@X209_Y57@{S[2][29],S[2][28]}@1 */

	logic [DATA_WIDTH-1:0] X209_Y57_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X209_Y57_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) south_to_north_sector_size_2_south_to_north_ip_size_28_bus_first_egress_fifo(.clock(bus_clock),
		.in(X209_Y57_bus_rdata_in),
		.out(X209_Y57_bus_rdata_out));

	assign north_out_reg[2][29][10:0] = X209_Y57_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign north_out_reg[2][28][10:2] = X209_Y57_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X209_Y57(.data(/* from design */),
		.q(X209_Y57_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X209_Y57_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X211_Y57@{N[2][31],N[2][30]}@5 */

	logic [DATA_WIDTH-1:0] X211_Y57_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) north_to_south_sector_size_2_north_to_south_ip_size_30_bus_first_ingress_fifo(.clock(bus_clock),
		.in({north_in_reg[2][31][10:0], north_in_reg[2][30][10:2]}),
		.out(X211_Y57_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X211_Y57(.data(X211_Y57_bus_wdata),
		.q(/* to design */),
		.wraddress(X211_Y57_waddr),
		.rdaddress(/* from design */),
		.wren(X211_Y57_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X212_Y57@{N[2][32],N[2][31]}@5 */

	logic X212_Y57_incr_waddr; // ingress control
	logic X212_Y57_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) north_to_south_sector_size_2_north_to_south_ip_size_31_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(north_in_reg[2][32][0]),
		.out(X212_Y57_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) north_to_south_sector_size_2_north_to_south_ip_size_31_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(north_in_reg[2][32][1]),
		.out(X212_Y57_incr_raddr));

	logic [ADDR_WIDTH-1:0] X212_Y57_waddr;
	logic [ADDR_WIDTH-1:0] X212_Y57_raddr;

	/* positional aliases */

	wire X211_Y57_incr_waddr;
	assign X211_Y57_incr_waddr = X212_Y57_incr_waddr;
	wire [ADDR_WIDTH-1:0] X211_Y57_waddr;
	assign X211_Y57_waddr = X212_Y57_waddr;
	wire X211_Y56_incr_raddr;
	assign X211_Y56_incr_raddr = X212_Y57_incr_raddr;
	wire [ADDR_WIDTH-1:0] X211_Y56_raddr;
	assign X211_Y56_raddr = X212_Y57_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X212_Y57(.clk(bus_clock),
		.incr_waddr(X212_Y57_incr_waddr),
		.waddr(X212_Y57_waddr),
		.incr_raddr(X212_Y57_incr_raddr),
		.raddr(X212_Y57_raddr));


	/* generated from E@X83_Y56@{W[0][14],W[0][13]}@1 */

	logic [DATA_WIDTH-1:0] X83_Y56_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X83_Y56_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) west_to_east_sector_size_0_west_to_east_ip_size_13_bus_first_egress_fifo(.clock(bus_clock),
		.in(X83_Y56_bus_rdata_in),
		.out(X83_Y56_bus_rdata_out));

	assign east_out_reg[0][14][10:0] = X83_Y56_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][13][10:2] = X83_Y56_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X83_Y56(.data(/* from design */),
		.q(X83_Y56_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X83_Y56_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X103_Y56@{S[0][27],S[0][28]}@0 */

	logic X103_Y56_incr_waddr; // ingress control
	logic X103_Y56_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) south_to_north_sector_size_0_south_to_north_ip_size_28_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[0][28][0]),
		.out(X103_Y56_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) south_to_north_sector_size_0_south_to_north_ip_size_28_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[0][28][1]),
		.out(X103_Y56_incr_raddr));

	logic [ADDR_WIDTH-1:0] X103_Y56_waddr;
	logic [ADDR_WIDTH-1:0] X103_Y56_raddr;

	/* positional aliases */

	wire X104_Y56_incr_waddr;
	assign X104_Y56_incr_waddr = X103_Y56_incr_waddr;
	wire [ADDR_WIDTH-1:0] X104_Y56_waddr;
	assign X104_Y56_waddr = X103_Y56_waddr;
	wire X104_Y57_incr_raddr;
	assign X104_Y57_incr_raddr = X103_Y56_incr_raddr;
	wire [ADDR_WIDTH-1:0] X104_Y57_raddr;
	assign X104_Y57_raddr = X103_Y56_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X103_Y56(.clk(bus_clock),
		.incr_waddr(X103_Y56_incr_waddr),
		.waddr(X103_Y56_waddr),
		.incr_raddr(X103_Y56_incr_raddr),
		.raddr(X103_Y56_raddr));


	/* generated from I@X104_Y56@{S[0][28],S[0][29]}@0 */

	logic [DATA_WIDTH-1:0] X104_Y56_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) south_to_north_sector_size_0_south_to_north_ip_size_29_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[0][28][10:0], south_in_reg[0][29][10:2]}),
		.out(X104_Y56_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X104_Y56(.data(X104_Y56_bus_wdata),
		.q(/* to design */),
		.wraddress(X104_Y56_waddr),
		.rdaddress(/* from design */),
		.wren(X104_Y56_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X106_Y56@{N[0][30],N[0][31]}@6 */

	logic [DATA_WIDTH-1:0] X106_Y56_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X106_Y56_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) north_to_south_sector_size_0_north_to_south_ip_size_31_bus_first_egress_fifo(.clock(bus_clock),
		.in(X106_Y56_bus_rdata_in),
		.out(X106_Y56_bus_rdata_out));

	assign south_out_reg[0][30][10:0] = X106_Y56_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[0][31][10:2] = X106_Y56_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X106_Y56(.data(/* from design */),
		.q(X106_Y56_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X106_Y56_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X185_Y56@{E[0][14],E[0][13]}@3 */

	logic [DATA_WIDTH-1:0] X185_Y56_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X185_Y56_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) east_to_west_sector_size_0_east_to_west_ip_size_13_bus_first_egress_fifo(.clock(bus_clock),
		.in(X185_Y56_bus_rdata_in),
		.out(X185_Y56_bus_rdata_out));

	assign west_out_reg[0][14][10:0] = X185_Y56_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][13][10:2] = X185_Y56_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X185_Y56(.data(/* from design */),
		.q(X185_Y56_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X185_Y56_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X199_Y56@{S[2][21],S[2][20]}@0 */

	logic [DATA_WIDTH-1:0] X199_Y56_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) south_to_north_sector_size_2_south_to_north_ip_size_20_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][21][10:0], south_in_reg[2][20][10:2]}),
		.out(X199_Y56_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X199_Y56(.data(X199_Y56_bus_wdata),
		.q(/* to design */),
		.wraddress(X199_Y56_waddr),
		.rdaddress(/* from design */),
		.wren(X199_Y56_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X200_Y56@{S[2][22],S[2][21]}@0 */

	logic X200_Y56_incr_waddr; // ingress control
	logic X200_Y56_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) south_to_north_sector_size_2_south_to_north_ip_size_21_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[2][22][0]),
		.out(X200_Y56_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) south_to_north_sector_size_2_south_to_north_ip_size_21_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[2][22][1]),
		.out(X200_Y56_incr_raddr));

	logic [ADDR_WIDTH-1:0] X200_Y56_waddr;
	logic [ADDR_WIDTH-1:0] X200_Y56_raddr;

	/* positional aliases */

	wire X199_Y56_incr_waddr;
	assign X199_Y56_incr_waddr = X200_Y56_incr_waddr;
	wire [ADDR_WIDTH-1:0] X199_Y56_waddr;
	assign X199_Y56_waddr = X200_Y56_waddr;
	wire X199_Y57_incr_raddr;
	assign X199_Y57_incr_raddr = X200_Y56_incr_raddr;
	wire [ADDR_WIDTH-1:0] X199_Y57_raddr;
	assign X199_Y57_raddr = X200_Y56_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X200_Y56(.clk(bus_clock),
		.incr_waddr(X200_Y56_incr_waddr),
		.waddr(X200_Y56_waddr),
		.incr_raddr(X200_Y56_incr_raddr),
		.raddr(X200_Y56_raddr));


	/* generated from E@X201_Y56@{N[2][23],N[2][22]}@6 */

	logic [DATA_WIDTH-1:0] X201_Y56_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X201_Y56_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) north_to_south_sector_size_2_north_to_south_ip_size_22_bus_first_egress_fifo(.clock(bus_clock),
		.in(X201_Y56_bus_rdata_in),
		.out(X201_Y56_bus_rdata_out));

	assign south_out_reg[2][23][10:0] = X201_Y56_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][22][10:2] = X201_Y56_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X201_Y56(.data(/* from design */),
		.q(X201_Y56_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X201_Y56_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X209_Y56@{S[2][29],S[2][28]}@0 */

	logic [DATA_WIDTH-1:0] X209_Y56_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) south_to_north_sector_size_2_south_to_north_ip_size_28_bus_first_ingress_fifo(.clock(bus_clock),
		.in({south_in_reg[2][29][10:0], south_in_reg[2][28][10:2]}),
		.out(X209_Y56_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X209_Y56(.data(X209_Y56_bus_wdata),
		.q(/* to design */),
		.wraddress(X209_Y56_waddr),
		.rdaddress(/* from design */),
		.wren(X209_Y56_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X210_Y56@{S[2][30],S[2][29]}@0 */

	logic X210_Y56_incr_waddr; // ingress control
	logic X210_Y56_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) south_to_north_sector_size_2_south_to_north_ip_size_29_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(south_in_reg[2][30][0]),
		.out(X210_Y56_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) south_to_north_sector_size_2_south_to_north_ip_size_29_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(south_in_reg[2][30][1]),
		.out(X210_Y56_incr_raddr));

	logic [ADDR_WIDTH-1:0] X210_Y56_waddr;
	logic [ADDR_WIDTH-1:0] X210_Y56_raddr;

	/* positional aliases */

	wire X209_Y56_incr_waddr;
	assign X209_Y56_incr_waddr = X210_Y56_incr_waddr;
	wire [ADDR_WIDTH-1:0] X209_Y56_waddr;
	assign X209_Y56_waddr = X210_Y56_waddr;
	wire X209_Y57_incr_raddr;
	assign X209_Y57_incr_raddr = X210_Y56_incr_raddr;
	wire [ADDR_WIDTH-1:0] X209_Y57_raddr;
	assign X209_Y57_raddr = X210_Y56_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X210_Y56(.clk(bus_clock),
		.incr_waddr(X210_Y56_incr_waddr),
		.waddr(X210_Y56_waddr),
		.incr_raddr(X210_Y56_incr_raddr),
		.raddr(X210_Y56_raddr));


	/* generated from E@X211_Y56@{N[2][31],N[2][30]}@6 */

	logic [DATA_WIDTH-1:0] X211_Y56_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X211_Y56_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) north_to_south_sector_size_2_north_to_south_ip_size_30_bus_first_egress_fifo(.clock(bus_clock),
		.in(X211_Y56_bus_rdata_in),
		.out(X211_Y56_bus_rdata_out));

	assign south_out_reg[2][31][10:0] = X211_Y56_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign south_out_reg[2][30][10:2] = X211_Y56_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X211_Y56(.data(/* from design */),
		.q(X211_Y56_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X211_Y56_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X132_Y55@{E[0][12],E[0][11]}@4 */

	logic [DATA_WIDTH-1:0] X132_Y55_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_11_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][12][10:0], east_in_reg[0][11][10:2]}),
		.out(X132_Y55_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X132_Y55(.data(X132_Y55_bus_wdata),
		.q(/* to design */),
		.wraddress(X132_Y55_waddr),
		.rdaddress(/* from design */),
		.wren(X132_Y55_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X133_Y55@{E[0][12],E[0][11]}@4 */

	logic X133_Y55_incr_waddr; // ingress control
	logic X133_Y55_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_11_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][11][0]),
		.out(X133_Y55_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_11_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][11][1]),
		.out(X133_Y55_incr_raddr));

	logic [ADDR_WIDTH-1:0] X133_Y55_waddr;
	logic [ADDR_WIDTH-1:0] X133_Y55_raddr;

	/* positional aliases */

	wire X132_Y55_incr_waddr;
	assign X132_Y55_incr_waddr = X133_Y55_incr_waddr;
	wire [ADDR_WIDTH-1:0] X132_Y55_waddr;
	assign X132_Y55_waddr = X133_Y55_waddr;
	wire X132_Y54_incr_raddr;
	assign X132_Y54_incr_raddr = X133_Y55_incr_raddr;
	wire [ADDR_WIDTH-1:0] X132_Y54_raddr;
	assign X132_Y54_raddr = X133_Y55_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X133_Y55(.clk(bus_clock),
		.incr_waddr(X133_Y55_incr_waddr),
		.waddr(X133_Y55_waddr),
		.incr_raddr(X133_Y55_incr_raddr),
		.raddr(X133_Y55_raddr));


	/* generated from C@X259_Y55@{W[0][12],W[0][11]}@5 */

	logic X259_Y55_incr_waddr; // ingress control
	logic X259_Y55_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(6)) west_to_east_sector_size_0_west_to_east_ip_size_11_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][12][0]),
		.out(X259_Y55_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(6)) west_to_east_sector_size_0_west_to_east_ip_size_11_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][12][1]),
		.out(X259_Y55_incr_raddr));

	logic [ADDR_WIDTH-1:0] X259_Y55_waddr;
	logic [ADDR_WIDTH-1:0] X259_Y55_raddr;

	/* positional aliases */

	wire X260_Y55_incr_waddr;
	assign X260_Y55_incr_waddr = X259_Y55_incr_waddr;
	wire [ADDR_WIDTH-1:0] X260_Y55_waddr;
	assign X260_Y55_waddr = X259_Y55_waddr;
	wire X260_Y54_incr_raddr;
	assign X260_Y54_incr_raddr = X259_Y55_incr_raddr;
	wire [ADDR_WIDTH-1:0] X260_Y54_raddr;
	assign X260_Y54_raddr = X259_Y55_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X259_Y55(.clk(bus_clock),
		.incr_waddr(X259_Y55_incr_waddr),
		.waddr(X259_Y55_waddr),
		.incr_raddr(X259_Y55_incr_raddr),
		.raddr(X259_Y55_raddr));


	/* generated from I@X260_Y55@{W[0][12],W[0][11]}@5 */

	logic [DATA_WIDTH-1:0] X260_Y55_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) west_to_east_sector_size_0_west_to_east_ip_size_11_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][12][10:0], west_in_reg[0][11][10:2]}),
		.out(X260_Y55_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X260_Y55(.data(X260_Y55_bus_wdata),
		.q(/* to design */),
		.wraddress(X260_Y55_waddr),
		.rdaddress(/* from design */),
		.wren(X260_Y55_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X132_Y54@{E[0][12],E[0][11]}@5 */

	logic [DATA_WIDTH-1:0] X132_Y54_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X132_Y54_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_11_bus_first_egress_fifo(.clock(bus_clock),
		.in(X132_Y54_bus_rdata_in),
		.out(X132_Y54_bus_rdata_out));

	assign west_out_reg[0][12][10:0] = X132_Y54_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][11][10:2] = X132_Y54_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X132_Y54(.data(/* from design */),
		.q(X132_Y54_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X132_Y54_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X260_Y54@{W[0][12],W[0][11]}@6 */

	logic [DATA_WIDTH-1:0] X260_Y54_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X260_Y54_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) west_to_east_sector_size_0_west_to_east_ip_size_11_bus_first_egress_fifo(.clock(bus_clock),
		.in(X260_Y54_bus_rdata_in),
		.out(X260_Y54_bus_rdata_out));

	assign east_out_reg[0][12][10:0] = X260_Y54_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][11][10:2] = X260_Y54_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X260_Y54(.data(/* from design */),
		.q(X260_Y54_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X260_Y54_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X131_Y53@{W[0][10],W[0][9]}@1 */

	logic X131_Y53_incr_waddr; // ingress control
	logic X131_Y53_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_9_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][9][0]),
		.out(X131_Y53_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_9_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][9][1]),
		.out(X131_Y53_incr_raddr));

	logic [ADDR_WIDTH-1:0] X131_Y53_waddr;
	logic [ADDR_WIDTH-1:0] X131_Y53_raddr;

	/* positional aliases */

	wire X132_Y53_incr_waddr;
	assign X132_Y53_incr_waddr = X131_Y53_incr_waddr;
	wire [ADDR_WIDTH-1:0] X132_Y53_waddr;
	assign X132_Y53_waddr = X131_Y53_waddr;
	wire X132_Y52_incr_raddr;
	assign X132_Y52_incr_raddr = X131_Y53_incr_raddr;
	wire [ADDR_WIDTH-1:0] X132_Y52_raddr;
	assign X132_Y52_raddr = X131_Y53_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X131_Y53(.clk(bus_clock),
		.incr_waddr(X131_Y53_incr_waddr),
		.waddr(X131_Y53_waddr),
		.incr_raddr(X131_Y53_incr_raddr),
		.raddr(X131_Y53_raddr));


	/* generated from I@X132_Y53@{W[0][10],W[0][9]}@1 */

	logic [DATA_WIDTH-1:0] X132_Y53_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_9_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][10][10:0], west_in_reg[0][9][10:2]}),
		.out(X132_Y53_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X132_Y53(.data(X132_Y53_bus_wdata),
		.q(/* to design */),
		.wraddress(X132_Y53_waddr),
		.rdaddress(/* from design */),
		.wren(X132_Y53_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from I@X260_Y53@{E[0][10],E[0][9]}@0 */

	logic [DATA_WIDTH-1:0] X260_Y53_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(1)) east_to_west_sector_size_0_east_to_west_ip_size_9_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][10][10:0], east_in_reg[0][9][10:2]}),
		.out(X260_Y53_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X260_Y53(.data(X260_Y53_bus_wdata),
		.q(/* to design */),
		.wraddress(X260_Y53_waddr),
		.rdaddress(/* from design */),
		.wren(X260_Y53_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X261_Y53@{E[0][10],E[0][9]}@0 */

	logic X261_Y53_incr_waddr; // ingress control
	logic X261_Y53_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(1)) east_to_west_sector_size_0_east_to_west_ip_size_9_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][10][0]),
		.out(X261_Y53_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(1)) east_to_west_sector_size_0_east_to_west_ip_size_9_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][10][1]),
		.out(X261_Y53_incr_raddr));

	logic [ADDR_WIDTH-1:0] X261_Y53_waddr;
	logic [ADDR_WIDTH-1:0] X261_Y53_raddr;

	/* positional aliases */

	wire X260_Y53_incr_waddr;
	assign X260_Y53_incr_waddr = X261_Y53_incr_waddr;
	wire [ADDR_WIDTH-1:0] X260_Y53_waddr;
	assign X260_Y53_waddr = X261_Y53_waddr;
	wire X260_Y52_incr_raddr;
	assign X260_Y52_incr_raddr = X261_Y53_incr_raddr;
	wire [ADDR_WIDTH-1:0] X260_Y52_raddr;
	assign X260_Y52_raddr = X261_Y53_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X261_Y53(.clk(bus_clock),
		.incr_waddr(X261_Y53_incr_waddr),
		.waddr(X261_Y53_waddr),
		.incr_raddr(X261_Y53_incr_raddr),
		.raddr(X261_Y53_raddr));


	/* generated from E@X132_Y52@{W[0][10],W[0][9]}@2 */

	logic [DATA_WIDTH-1:0] X132_Y52_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X132_Y52_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_0_west_to_east_ip_size_9_bus_first_egress_fifo(.clock(bus_clock),
		.in(X132_Y52_bus_rdata_in),
		.out(X132_Y52_bus_rdata_out));

	assign east_out_reg[0][10][10:0] = X132_Y52_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][9][10:2] = X132_Y52_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X132_Y52(.data(/* from design */),
		.q(X132_Y52_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X132_Y52_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X260_Y52@{E[0][10],E[0][9]}@1 */

	logic [DATA_WIDTH-1:0] X260_Y52_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X260_Y52_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(6)) east_to_west_sector_size_0_east_to_west_ip_size_9_bus_first_egress_fifo(.clock(bus_clock),
		.in(X260_Y52_bus_rdata_in),
		.out(X260_Y52_bus_rdata_out));

	assign west_out_reg[0][10][10:0] = X260_Y52_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][9][10:2] = X260_Y52_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X260_Y52(.data(/* from design */),
		.q(X260_Y52_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X260_Y52_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X104_Y51@{E[0][8],E[0][7]}@4 */

	logic [DATA_WIDTH-1:0] X104_Y51_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_7_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][8][10:0], east_in_reg[0][7][10:2]}),
		.out(X104_Y51_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X104_Y51(.data(X104_Y51_bus_wdata),
		.q(/* to design */),
		.wraddress(X104_Y51_waddr),
		.rdaddress(/* from design */),
		.wren(X104_Y51_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X105_Y51@{E[0][8],E[0][7]}@4 */

	logic X105_Y51_incr_waddr; // ingress control
	logic X105_Y51_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_7_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][7][0]),
		.out(X105_Y51_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_7_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][7][1]),
		.out(X105_Y51_incr_raddr));

	logic [ADDR_WIDTH-1:0] X105_Y51_waddr;
	logic [ADDR_WIDTH-1:0] X105_Y51_raddr;

	/* positional aliases */

	wire X104_Y51_incr_waddr;
	assign X104_Y51_incr_waddr = X105_Y51_incr_waddr;
	wire [ADDR_WIDTH-1:0] X104_Y51_waddr;
	assign X104_Y51_waddr = X105_Y51_waddr;
	wire X104_Y50_incr_raddr;
	assign X104_Y50_incr_raddr = X105_Y51_incr_raddr;
	wire [ADDR_WIDTH-1:0] X104_Y50_raddr;
	assign X104_Y50_raddr = X105_Y51_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X105_Y51(.clk(bus_clock),
		.incr_waddr(X105_Y51_incr_waddr),
		.waddr(X105_Y51_waddr),
		.incr_raddr(X105_Y51_incr_raddr),
		.raddr(X105_Y51_raddr));


	/* generated from C@X205_Y51@{W[0][8],W[0][7]}@3 */

	logic X205_Y51_incr_waddr; // ingress control
	logic X205_Y51_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_0_west_to_east_ip_size_7_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][8][0]),
		.out(X205_Y51_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) west_to_east_sector_size_0_west_to_east_ip_size_7_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][8][1]),
		.out(X205_Y51_incr_raddr));

	logic [ADDR_WIDTH-1:0] X205_Y51_waddr;
	logic [ADDR_WIDTH-1:0] X205_Y51_raddr;

	/* positional aliases */

	wire X206_Y51_incr_waddr;
	assign X206_Y51_incr_waddr = X205_Y51_incr_waddr;
	wire [ADDR_WIDTH-1:0] X206_Y51_waddr;
	assign X206_Y51_waddr = X205_Y51_waddr;
	wire X206_Y50_incr_raddr;
	assign X206_Y50_incr_raddr = X205_Y51_incr_raddr;
	wire [ADDR_WIDTH-1:0] X206_Y50_raddr;
	assign X206_Y50_raddr = X205_Y51_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X205_Y51(.clk(bus_clock),
		.incr_waddr(X205_Y51_incr_waddr),
		.waddr(X205_Y51_waddr),
		.incr_raddr(X205_Y51_incr_raddr),
		.raddr(X205_Y51_raddr));


	/* generated from I@X206_Y51@{W[0][8],W[0][7]}@4 */

	logic [DATA_WIDTH-1:0] X206_Y51_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_0_west_to_east_ip_size_7_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][8][10:0], west_in_reg[0][7][10:2]}),
		.out(X206_Y51_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X206_Y51(.data(X206_Y51_bus_wdata),
		.q(/* to design */),
		.wraddress(X206_Y51_waddr),
		.rdaddress(/* from design */),
		.wren(X206_Y51_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X104_Y50@{E[0][8],E[0][7]}@5 */

	logic [DATA_WIDTH-1:0] X104_Y50_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X104_Y50_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_7_bus_first_egress_fifo(.clock(bus_clock),
		.in(X104_Y50_bus_rdata_in),
		.out(X104_Y50_bus_rdata_out));

	assign west_out_reg[0][8][10:0] = X104_Y50_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][7][10:2] = X104_Y50_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X104_Y50(.data(/* from design */),
		.q(X104_Y50_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X104_Y50_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X206_Y50@{W[0][8],W[0][7]}@5 */

	logic [DATA_WIDTH-1:0] X206_Y50_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X206_Y50_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_7_bus_first_egress_fifo(.clock(bus_clock),
		.in(X206_Y50_bus_rdata_in),
		.out(X206_Y50_bus_rdata_out));

	assign east_out_reg[0][8][10:0] = X206_Y50_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][7][10:2] = X206_Y50_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X206_Y50(.data(/* from design */),
		.q(X206_Y50_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X206_Y50_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X103_Y49@{W[0][6],W[0][5]}@1 */

	logic X103_Y49_incr_waddr; // ingress control
	logic X103_Y49_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_5_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][5][0]),
		.out(X103_Y49_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_5_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][5][1]),
		.out(X103_Y49_incr_raddr));

	logic [ADDR_WIDTH-1:0] X103_Y49_waddr;
	logic [ADDR_WIDTH-1:0] X103_Y49_raddr;

	/* positional aliases */

	wire X104_Y49_incr_waddr;
	assign X104_Y49_incr_waddr = X103_Y49_incr_waddr;
	wire [ADDR_WIDTH-1:0] X104_Y49_waddr;
	assign X104_Y49_waddr = X103_Y49_waddr;
	wire X104_Y48_incr_raddr;
	assign X104_Y48_incr_raddr = X103_Y49_incr_raddr;
	wire [ADDR_WIDTH-1:0] X104_Y48_raddr;
	assign X104_Y48_raddr = X103_Y49_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X103_Y49(.clk(bus_clock),
		.incr_waddr(X103_Y49_incr_waddr),
		.waddr(X103_Y49_waddr),
		.incr_raddr(X103_Y49_incr_raddr),
		.raddr(X103_Y49_raddr));


	/* generated from I@X104_Y49@{W[0][6],W[0][5]}@1 */

	logic [DATA_WIDTH-1:0] X104_Y49_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_5_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][6][10:0], west_in_reg[0][5][10:2]}),
		.out(X104_Y49_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X104_Y49(.data(X104_Y49_bus_wdata),
		.q(/* to design */),
		.wraddress(X104_Y49_waddr),
		.rdaddress(/* from design */),
		.wren(X104_Y49_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from I@X206_Y49@{E[0][6],E[0][5]}@1 */

	logic [DATA_WIDTH-1:0] X206_Y49_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_5_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][6][10:0], east_in_reg[0][5][10:2]}),
		.out(X206_Y49_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X206_Y49(.data(X206_Y49_bus_wdata),
		.q(/* to design */),
		.wraddress(X206_Y49_waddr),
		.rdaddress(/* from design */),
		.wren(X206_Y49_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X207_Y49@{E[0][6],E[0][5]}@1 */

	logic X207_Y49_incr_waddr; // ingress control
	logic X207_Y49_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_5_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][6][0]),
		.out(X207_Y49_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_5_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][6][1]),
		.out(X207_Y49_incr_raddr));

	logic [ADDR_WIDTH-1:0] X207_Y49_waddr;
	logic [ADDR_WIDTH-1:0] X207_Y49_raddr;

	/* positional aliases */

	wire X206_Y49_incr_waddr;
	assign X206_Y49_incr_waddr = X207_Y49_incr_waddr;
	wire [ADDR_WIDTH-1:0] X206_Y49_waddr;
	assign X206_Y49_waddr = X207_Y49_waddr;
	wire X206_Y48_incr_raddr;
	assign X206_Y48_incr_raddr = X207_Y49_incr_raddr;
	wire [ADDR_WIDTH-1:0] X206_Y48_raddr;
	assign X206_Y48_raddr = X207_Y49_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X207_Y49(.clk(bus_clock),
		.incr_waddr(X207_Y49_incr_waddr),
		.waddr(X207_Y49_waddr),
		.incr_raddr(X207_Y49_incr_raddr),
		.raddr(X207_Y49_raddr));


	/* generated from E@X104_Y48@{W[0][6],W[0][5]}@2 */

	logic [DATA_WIDTH-1:0] X104_Y48_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X104_Y48_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_0_west_to_east_ip_size_5_bus_first_egress_fifo(.clock(bus_clock),
		.in(X104_Y48_bus_rdata_in),
		.out(X104_Y48_bus_rdata_out));

	assign east_out_reg[0][6][10:0] = X104_Y48_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][5][10:2] = X104_Y48_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X104_Y48(.data(/* from design */),
		.q(X104_Y48_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X104_Y48_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X206_Y48@{E[0][6],E[0][5]}@2 */

	logic [DATA_WIDTH-1:0] X206_Y48_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X206_Y48_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_5_bus_first_egress_fifo(.clock(bus_clock),
		.in(X206_Y48_bus_rdata_in),
		.out(X206_Y48_bus_rdata_out));

	assign west_out_reg[0][6][10:0] = X206_Y48_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][5][10:2] = X206_Y48_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X206_Y48(.data(/* from design */),
		.q(X206_Y48_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X206_Y48_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from I@X153_Y47@{E[0][4],E[0][3]}@3 */

	logic [DATA_WIDTH-1:0] X153_Y47_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) east_to_west_sector_size_0_east_to_west_ip_size_3_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][4][10:0], east_in_reg[0][3][10:2]}),
		.out(X153_Y47_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X153_Y47(.data(X153_Y47_bus_wdata),
		.q(/* to design */),
		.wraddress(X153_Y47_waddr),
		.rdaddress(/* from design */),
		.wren(X153_Y47_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X154_Y47@{E[0][4],E[0][3]}@3 */

	logic X154_Y47_incr_waddr; // ingress control
	logic X154_Y47_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(4)) east_to_west_sector_size_0_east_to_west_ip_size_3_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][3][0]),
		.out(X154_Y47_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(4)) east_to_west_sector_size_0_east_to_west_ip_size_3_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][3][1]),
		.out(X154_Y47_incr_raddr));

	logic [ADDR_WIDTH-1:0] X154_Y47_waddr;
	logic [ADDR_WIDTH-1:0] X154_Y47_raddr;

	/* positional aliases */

	wire X153_Y47_incr_waddr;
	assign X153_Y47_incr_waddr = X154_Y47_incr_waddr;
	wire [ADDR_WIDTH-1:0] X153_Y47_waddr;
	assign X153_Y47_waddr = X154_Y47_waddr;
	wire X153_Y46_incr_raddr;
	assign X153_Y46_incr_raddr = X154_Y47_incr_raddr;
	wire [ADDR_WIDTH-1:0] X153_Y46_raddr;
	assign X153_Y46_raddr = X154_Y47_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X154_Y47(.clk(bus_clock),
		.incr_waddr(X154_Y47_incr_waddr),
		.waddr(X154_Y47_waddr),
		.incr_raddr(X154_Y47_incr_raddr),
		.raddr(X154_Y47_raddr));


	/* generated from C@X238_Y47@{W[0][4],W[0][3]}@4 */

	logic X238_Y47_incr_waddr; // ingress control
	logic X238_Y47_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(5)) west_to_east_sector_size_0_west_to_east_ip_size_3_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][4][0]),
		.out(X238_Y47_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(5)) west_to_east_sector_size_0_west_to_east_ip_size_3_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][4][1]),
		.out(X238_Y47_incr_raddr));

	logic [ADDR_WIDTH-1:0] X238_Y47_waddr;
	logic [ADDR_WIDTH-1:0] X238_Y47_raddr;

	/* positional aliases */

	wire X239_Y47_incr_waddr;
	assign X239_Y47_incr_waddr = X238_Y47_incr_waddr;
	wire [ADDR_WIDTH-1:0] X239_Y47_waddr;
	assign X239_Y47_waddr = X238_Y47_waddr;
	wire X239_Y46_incr_raddr;
	assign X239_Y46_incr_raddr = X238_Y47_incr_raddr;
	wire [ADDR_WIDTH-1:0] X239_Y46_raddr;
	assign X239_Y46_raddr = X238_Y47_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X238_Y47(.clk(bus_clock),
		.incr_waddr(X238_Y47_incr_waddr),
		.waddr(X238_Y47_waddr),
		.incr_raddr(X238_Y47_incr_raddr),
		.raddr(X238_Y47_raddr));


	/* generated from I@X239_Y47@{W[0][4],W[0][3]}@4 */

	logic [DATA_WIDTH-1:0] X239_Y47_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) west_to_east_sector_size_0_west_to_east_ip_size_3_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][4][10:0], west_in_reg[0][3][10:2]}),
		.out(X239_Y47_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X239_Y47(.data(X239_Y47_bus_wdata),
		.q(/* to design */),
		.wraddress(X239_Y47_waddr),
		.rdaddress(/* from design */),
		.wren(X239_Y47_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from E@X153_Y46@{E[0][4],E[0][3]}@4 */

	logic [DATA_WIDTH-1:0] X153_Y46_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X153_Y46_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) east_to_west_sector_size_0_east_to_west_ip_size_3_bus_first_egress_fifo(.clock(bus_clock),
		.in(X153_Y46_bus_rdata_in),
		.out(X153_Y46_bus_rdata_out));

	assign west_out_reg[0][4][10:0] = X153_Y46_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][3][10:2] = X153_Y46_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X153_Y46(.data(/* from design */),
		.q(X153_Y46_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X153_Y46_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X239_Y46@{W[0][4],W[0][3]}@5 */

	logic [DATA_WIDTH-1:0] X239_Y46_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X239_Y46_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) west_to_east_sector_size_0_west_to_east_ip_size_3_bus_first_egress_fifo(.clock(bus_clock),
		.in(X239_Y46_bus_rdata_in),
		.out(X239_Y46_bus_rdata_out));

	assign east_out_reg[0][4][10:0] = X239_Y46_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][3][10:2] = X239_Y46_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X239_Y46(.data(/* from design */),
		.q(X239_Y46_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X239_Y46_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from C@X152_Y45@{W[0][2],W[0][1]}@2 */

	logic X152_Y45_incr_waddr; // ingress control
	logic X152_Y45_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(3)) west_to_east_sector_size_0_west_to_east_ip_size_1_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(west_in_reg[0][1][0]),
		.out(X152_Y45_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(3)) west_to_east_sector_size_0_west_to_east_ip_size_1_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(west_in_reg[0][1][1]),
		.out(X152_Y45_incr_raddr));

	logic [ADDR_WIDTH-1:0] X152_Y45_waddr;
	logic [ADDR_WIDTH-1:0] X152_Y45_raddr;

	/* positional aliases */

	wire X153_Y45_incr_waddr;
	assign X153_Y45_incr_waddr = X152_Y45_incr_waddr;
	wire [ADDR_WIDTH-1:0] X153_Y45_waddr;
	assign X153_Y45_waddr = X152_Y45_waddr;
	wire X153_Y44_incr_raddr;
	assign X153_Y44_incr_raddr = X152_Y45_incr_raddr;
	wire [ADDR_WIDTH-1:0] X153_Y44_raddr;
	assign X153_Y44_raddr = X152_Y45_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X152_Y45(.clk(bus_clock),
		.incr_waddr(X152_Y45_incr_waddr),
		.waddr(X152_Y45_waddr),
		.incr_raddr(X152_Y45_incr_raddr),
		.raddr(X152_Y45_raddr));


	/* generated from I@X153_Y45@{W[0][2],W[0][1]}@2 */

	logic [DATA_WIDTH-1:0] X153_Y45_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(3)) west_to_east_sector_size_0_west_to_east_ip_size_1_bus_first_ingress_fifo(.clock(bus_clock),
		.in({west_in_reg[0][2][10:0], west_in_reg[0][1][10:2]}),
		.out(X153_Y45_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X153_Y45(.data(X153_Y45_bus_wdata),
		.q(/* to design */),
		.wraddress(X153_Y45_waddr),
		.rdaddress(/* from design */),
		.wren(X153_Y45_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from I@X239_Y45@{E[0][2],E[0][1]}@1 */

	logic [DATA_WIDTH-1:0] X239_Y45_bus_wdata; // ingress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_1_bus_first_ingress_fifo(.clock(bus_clock),
		.in({east_in_reg[0][2][10:0], east_in_reg[0][1][10:2]}),
		.out(X239_Y45_bus_wdata));

	(* noprune *)
	mlab_fifo ingress_fifo_X239_Y45(.data(X239_Y45_bus_wdata),
		.q(/* to design */),
		.wraddress(X239_Y45_waddr),
		.rdaddress(/* from design */),
		.wren(X239_Y45_incr_waddr),
		.wrclock(bus_clock),
		.rdclock(/* from design */));


	/* generated from C@X240_Y45@{E[0][2],E[0][1]}@1 */

	logic X240_Y45_incr_waddr; // ingress control
	logic X240_Y45_incr_raddr; // egress control

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_1_bus_first_fifo_control_incr_waddr(.clock(bus_clock),
		.in(east_in_reg[0][2][0]),
		.out(X240_Y45_incr_waddr));

	bus_pipe #(.WIDTH(1), .DEPTH(2)) east_to_west_sector_size_0_east_to_west_ip_size_1_bus_first_fifo_control_incr_raddr(.clock(bus_clock),
		.in(east_in_reg[0][2][1]),
		.out(X240_Y45_incr_raddr));

	logic [ADDR_WIDTH-1:0] X240_Y45_waddr;
	logic [ADDR_WIDTH-1:0] X240_Y45_raddr;

	/* positional aliases */

	wire X239_Y45_incr_waddr;
	assign X239_Y45_incr_waddr = X240_Y45_incr_waddr;
	wire [ADDR_WIDTH-1:0] X239_Y45_waddr;
	assign X239_Y45_waddr = X240_Y45_waddr;
	wire X239_Y44_incr_raddr;
	assign X239_Y44_incr_raddr = X240_Y45_incr_raddr;
	wire [ADDR_WIDTH-1:0] X239_Y44_raddr;
	assign X239_Y44_raddr = X240_Y45_raddr;

	fifo_control #(.ADDR_WIDTH(ADDR_WIDTH)) fifo_control_X240_Y45(.clk(bus_clock),
		.incr_waddr(X240_Y45_incr_waddr),
		.waddr(X240_Y45_waddr),
		.incr_raddr(X240_Y45_incr_raddr),
		.raddr(X240_Y45_raddr));


	/* generated from E@X153_Y44@{W[0][2],W[0][1]}@3 */

	logic [DATA_WIDTH-1:0] X153_Y44_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X153_Y44_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(4)) west_to_east_sector_size_0_west_to_east_ip_size_1_bus_first_egress_fifo(.clock(bus_clock),
		.in(X153_Y44_bus_rdata_in),
		.out(X153_Y44_bus_rdata_out));

	assign east_out_reg[0][2][10:0] = X153_Y44_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign east_out_reg[0][1][10:2] = X153_Y44_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X153_Y44(.data(/* from design */),
		.q(X153_Y44_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X153_Y44_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


	/* generated from E@X239_Y44@{E[0][2],E[0][1]}@2 */

	logic [DATA_WIDTH-1:0] X239_Y44_bus_rdata_in;  // egress
	logic [DATA_WIDTH-1:0] X239_Y44_bus_rdata_out; // egress

	bus_pipe #(.WIDTH(DATA_WIDTH), .DEPTH(5)) east_to_west_sector_size_0_east_to_west_ip_size_1_bus_first_egress_fifo(.clock(bus_clock),
		.in(X239_Y44_bus_rdata_in),
		.out(X239_Y44_bus_rdata_out));

	assign west_out_reg[0][2][10:0] = X239_Y44_bus_rdata_out[DATA_WIDTH-1:DATA_WIDTH-11];
	assign west_out_reg[0][1][10:2] = X239_Y44_bus_rdata_out[DATA_WIDTH-12:0];

	mlab_fifo egress_fifo_X239_Y44(.data(/* from design */),
		.q(X239_Y44_bus_rdata_in),
		.wraddress(/* from design */),
		.rdaddress(X239_Y44_raddr),
		.wren(/* from design */),
		.wrclock(/* from design */),
		.rdclock(bus_clock));


endmodule
