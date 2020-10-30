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

   localparam SECTOR_COL = 40;//50;
   localparam SECTOR_ROW = 41;
   localparam RULE_OF_ELEVEN = 11;
   localparam PRR_SECTOR_HEIGHT = 3;
   localparam PRR_SECTOR_WIDTH = 4;
   localparam PIPES_PER_SECTOR_HEIGHT = 5; // 41/V8 = ~5
   localparam PIPES_PER_SECTOR_WIDTH = 4;  // 50/H12 = ~4

   // North/South ALM FFs per lane
   // Demand: 40*11*2    = 880 * PIPEs
   // Supply: 41*40*3*2  = 9840 ALM FFs
   
   // East/West ALM FFs per lane   
   // Demand: 21*11*2 = 462 * PIPEs
   // Supply: 40*40*4 = 6400 ALM FFs
   
   // 6,6 --> 599 MHz @ 7.375 W AC 

   // HACK on /2 --> make sure this is an even number
   
   parameter  NORTH_SOUTH_PIPES = 6; // 880 * 8 = 7040/9840
   parameter  EAST_WEST_PIPES   = 6; // 452 * 8 = 3616/6400
       
   input      wire clock;
   input      wire fast_clock;
   input      wire bus_clock;

   output     reg led_zero_on;
   output     reg led_one_on;
   output     reg led_two_on;
   output     reg led_three_on;
   
   input      wire dummy_in;
   output     wire dummy_out;

   input      logic north_in[PRR_SECTOR_WIDTH-1:0][SECTOR_COL-1:0][RULE_OF_ELEVEN-1:0];
   input      logic south_in[PRR_SECTOR_WIDTH-1:0][SECTOR_COL-1:0][RULE_OF_ELEVEN-1:0];
   input      logic east_in[PRR_SECTOR_HEIGHT-1:0][SECTOR_ROW-1:0][RULE_OF_ELEVEN-1:0];   
   input      logic west_in[PRR_SECTOR_HEIGHT-1:0][SECTOR_ROW-1:0][RULE_OF_ELEVEN-1:0];    
   
   output     logic north_out[PRR_SECTOR_WIDTH-1:0][SECTOR_COL-1:0][RULE_OF_ELEVEN-1:0];
   output     logic south_out[PRR_SECTOR_WIDTH-1:0][SECTOR_COL-1:0][RULE_OF_ELEVEN-1:0];
   output     logic east_out[PRR_SECTOR_HEIGHT-1:0][SECTOR_ROW-1:0][RULE_OF_ELEVEN-1:0];
   output     logic west_out[PRR_SECTOR_HEIGHT-1:0][SECTOR_ROW-1:0][RULE_OF_ELEVEN-1:0];

   // The synthesis preserve here avoids these registers being retimed into hyperflex   
   logic      north_in_reg[PRR_SECTOR_WIDTH-1:0][SECTOR_COL-1:0][RULE_OF_ELEVEN-1:0] /* synthesis preserve */;
   logic      south_in_reg[PRR_SECTOR_WIDTH-1:0][SECTOR_COL-1:0][RULE_OF_ELEVEN-1:0] /* synthesis preserve */;
   logic      east_in_reg[PRR_SECTOR_HEIGHT-1:0][SECTOR_ROW-1:0][RULE_OF_ELEVEN-1:0] /* synthesis preserve */;   
   logic      west_in_reg[PRR_SECTOR_HEIGHT-1:0][SECTOR_ROW-1:0][RULE_OF_ELEVEN-1:0] /* synthesis preserve */;    

   // The synthesis preserve here avoids these registers being retimed into hyperflex
   logic      north_out_reg[PRR_SECTOR_WIDTH-1:0][SECTOR_COL-1:0][RULE_OF_ELEVEN-1:0] /* synthesis preserve */;
   logic      south_out_reg[PRR_SECTOR_WIDTH-1:0][SECTOR_COL-1:0][RULE_OF_ELEVEN-1:0] /* synthesis preserve */;
   logic      east_out_reg[PRR_SECTOR_HEIGHT-1:0][SECTOR_ROW-1:0][RULE_OF_ELEVEN-1:0] /* synthesis preserve */;
   logic      west_out_reg[PRR_SECTOR_HEIGHT-1:0][SECTOR_ROW-1:0][RULE_OF_ELEVEN-1:0] /* synthesis preserve */;   

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
   
   // North to South
   generate
      for (i=0; i<PRR_SECTOR_WIDTH; i=i+1)  begin : north_to_south_sector_size
	 for (j=0; j<SECTOR_COL; j=j+1)  begin : north_to_south_ip_size

	    logic first_to_second [RULE_OF_ELEVEN-1:0];

	    bus_pipe #(.RULE_OF_ELEVEN(RULE_OF_ELEVEN),
		       .PIPES(NORTH_SOUTH_PIPES/2)) bus_first(.clock(bus_clock),
	    						      .in(north_in_reg[i][j]),
							      .out(first_to_second));
	    bus_pipe #(.RULE_OF_ELEVEN(RULE_OF_ELEVEN),
		       .PIPES(NORTH_SOUTH_PIPES/2)) bus_second(.clock(bus_clock),
	    						       .in(first_to_second),
							       .out(south_out_reg[i][j]));	    
	 end	 
      end // block: north_to_south_sector_size      
   endgenerate
  
   // South to North
   generate
      for (i=0; i<PRR_SECTOR_WIDTH; i=i+1)  begin : south_to_north_sector_size
	 for (j=0; j<SECTOR_COL; j=j+1)  begin : south_to_north_ip_size

	    logic first_to_second [RULE_OF_ELEVEN-1:0];
	    
	    bus_pipe #(.RULE_OF_ELEVEN(RULE_OF_ELEVEN),
		       .PIPES(NORTH_SOUTH_PIPES/2)) bus_first(.clock(bus_clock),
	    						      .in(south_in_reg[i][j]),
							      .out(first_to_second));
	    bus_pipe #(.RULE_OF_ELEVEN(RULE_OF_ELEVEN),
		       .PIPES(NORTH_SOUTH_PIPES/2)) bus_second(.clock(bus_clock),
	    						       .in(first_to_second),
							       .out(north_out_reg[i][j]));	    
	 end	 
      end // block: south_to_north_sector_size      
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
   
   // East to West
   generate
      for (i=0; i<PRR_SECTOR_HEIGHT; i=i+1)  begin : east_to_west_sector_size
	 for (j=0; j<SECTOR_ROW; j=j+1)  begin : east_to_west_ip_size

	    logic first_to_second[RULE_OF_ELEVEN-1:0];

	    if (j < SECTOR_ROW/2)
	      begin		 
		 bus_pipe #(.RULE_OF_ELEVEN(RULE_OF_ELEVEN),
			    .PIPES(EAST_WEST_PIPES/2)) bot_bus_first(.clock(bus_clock),
	    							     .in(east_in_reg[i][j]),
								     .out(first_to_second));
		 bus_pipe #(.RULE_OF_ELEVEN(RULE_OF_ELEVEN),
			    .PIPES(EAST_WEST_PIPES/2)) bot_bus_second(.clock(bus_clock),
	    							      .in(first_to_second),
								      .out(west_out_reg[i][j]));
	      end // if (j < SECTOR_ROW/2)
	    else
	      begin
	    	 bus_pipe #(.RULE_OF_ELEVEN(RULE_OF_ELEVEN),
			    .PIPES(EAST_WEST_PIPES/2)) top_bus_first(.clock(bus_clock),
	    							     .in(east_in_reg[i][j]),
								     .out(first_to_second));
		 bus_pipe #(.RULE_OF_ELEVEN(RULE_OF_ELEVEN),
			    .PIPES(EAST_WEST_PIPES/2)) top_bus_second(.clock(bus_clock),
	    							      .in(first_to_second),
								      .out(west_out_reg[i][j]));
	      end
	 end	 
      end // block: east_to_west_sector_size      
   endgenerate

   generate
      for (i=0; i<PRR_SECTOR_HEIGHT; i=i+1)  begin : west_to_east_sector_size
	 for (j=0; j<SECTOR_ROW; j=j+1)  begin : west_to_east_ip_size

	    logic first_to_second [RULE_OF_ELEVEN-1:0];

	    if (j < SECTOR_ROW/2)
	      begin		 
		 bus_pipe #(.RULE_OF_ELEVEN(RULE_OF_ELEVEN),
			    .PIPES(EAST_WEST_PIPES/2)) bot_bus_first(.clock(bus_clock),
	    							     .in(west_in_reg[i][j]),
								     .out(first_to_second));
		 bus_pipe #(.RULE_OF_ELEVEN(RULE_OF_ELEVEN),
			    .PIPES(EAST_WEST_PIPES/2)) bot_bus_second(.clock(bus_clock),
	    							      .in(first_to_second),
								      .out(east_out_reg[i][j]));
	      end // if (j < SECTOR_ROW/2)
	    else
	      begin		 
		 bus_pipe #(.RULE_OF_ELEVEN(RULE_OF_ELEVEN),
			    .PIPES(EAST_WEST_PIPES/2)) top_bus_first(.clock(bus_clock),
	    							     .in(west_in_reg[i][j]),
								     .out(first_to_second));
		 bus_pipe #(.RULE_OF_ELEVEN(RULE_OF_ELEVEN),
			    .PIPES(EAST_WEST_PIPES/2)) top_bus_second(.clock(bus_clock),
	    							      .in(first_to_second),
								      .out(east_out_reg[i][j]));
	      end
	 end	 
      end // block: west_to_east_sector_size       
   endgenerate   
  




   
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

endmodule // top

module bus_pipe(clock,
		in,
		out);

   parameter RULE_OF_ELEVEN = 11;
   parameter PIPES = 1;

   input     logic clock;
   input     logic in[RULE_OF_ELEVEN-1:0];
   output    logic out[RULE_OF_ELEVEN-1:0];

   logic [PIPES-1:0] pipes[RULE_OF_ELEVEN-1:0] /* synthesis ramstyle = "logic" */;
   
   genvar    i;
   generate
      for (i=0; i<RULE_OF_ELEVEN; i=i+1)  begin : rule_of_eleven_size
	 if (PIPES == 1)
	   always_ff @(posedge clock)   
	     out[i] <=  in[i];
	 else
	   always_ff @(posedge clock)   
	     pipes[i][PIPES-1:0] <= {pipes[i][PIPES-2:0], in[i]};
           always_comb 
	     out[i]              =  pipes[i][PIPES-1];
      end
   endgenerate

endmodule // bus_pipe

