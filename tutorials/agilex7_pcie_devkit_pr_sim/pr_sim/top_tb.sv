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
`define ALTERA_ENABLE_PR_MODEL


module top_tb;
///////////////////////////////////////////////////////////////////////////
// Simulation Clock Timing Parameters
///////////////////////////////////////////////////////////////////////////
parameter PERIOD 				= 10; // in ns (f = 100 MHz)
parameter HALF_PERIOD 		= PERIOD/2;
parameter CLOCK_CYCLE 		= PERIOD;
parameter HALF_CLOCK_CYCLE	= CLOCK_CYCLE/2;

///////////////////////////////////////////////////////////////////////////
// Persona Parameters
///////////////////////////////////////////////////////////////////////////
localparam PERSONA_AND_GATE		= 0;
localparam PERSONA_COUNTER 		= 1;
localparam PERSONA_FSM	 			= 2;
localparam NUM_PERSONAS				= 3;

parameter OUTPUT_WIDTH = 2;

///////////////////////////////////////////////////////////////////////////
// Variable Declaration
///////////////////////////////////////////////////////////////////////////

// Input
reg clk;
reg rst_n;
reg freeze;
reg a;
reg b;

// Output
wire [OUTPUT_WIDTH-1:0] result;
wire [OUTPUT_WIDTH-1:0] result_and_gate;
wire [OUTPUT_WIDTH-1:0] result_counter;
wire [OUTPUT_WIDTH-1:0] result_fsm;
wire [OUTPUT_WIDTH-1:0] result_and_gate_pr;
wire [OUTPUT_WIDTH-1:0] result_counter_pr;
wire [OUTPUT_WIDTH-1:0] result_fsm_pr;

// PR
logic		pr_activate;
integer 	persona_select;

// Waveform Text
reg [32*8-1:0] pr_sim_text;
reg [32*8-1:0] persona_select_text;

///////////////////////////////////////////////////////////////////////////
// DUT's
///////////////////////////////////////////////////////////////////////////

// Top Sim
top_sim #(
	.OUTPUT_WIDTH(OUTPUT_WIDTH)) 

	u_top_sim (
		.clk(clk),
		.rst_n(rst_n),
		.a(a),
		.b(b),
		.result(result)
);

// PR AND Persona
and_gate
	u_and_gate_pr(
		.clk(clk),
		.rst_n(rst_n),
		.a(a),
		.b(b),
		.result(result_and_gate_pr)
);

// PR Counter Persona
counter
	u_counter_pr (
		.clk(clk),
		.rst_n(rst_n),
		.a(a),
		.b(b),
		.result(result_counter_pr)
);

// PR FSM Persona
fsm
	u_fsm_pr (
		.clk(clk),
		.rst_n(rst_n),
		.a(a),
		.b(b),
		.result(result_fsm_pr)
);

// RTL AND Persona
and_gate
	u_and_gate(
		.clk(clk),
		.rst_n(rst_n),
		.a(a),
		.b(b),
		.result(result_and_gate)
);

// RTL Counter Persona
counter
	u_counter(
		.clk(clk),
		.rst_n(rst_n),
		.a(a),
		.b(b),
		.result(result_counter)
);

// RTL FSM Persona
fsm
	u_fsm(
		.clk(clk),
		.rst_n(rst_n),
		.a(a),
		.b(b),
		.result(result_fsm)
);

///////////////////////////////////////////////////////////////////////////
// PR and Freeze Assignments
///////////////////////////////////////////////////////////////////////////
assign u_top_sim.u_pr_sim_wrapper.pr_activate = pr_activate;
assign u_top_sim.u_pr_sim_wrapper.persona_select = persona_select;
assign u_top_sim.u_pr_sim_wrapper.freeze = freeze;

`ifdef ALTERA_ENABLE_PR_MODEL
	assign u_and_gate_pr.altera_sim_pr_activate = pr_activate;
	assign u_counter_pr.altera_sim_pr_activate = pr_activate;
	assign u_fsm_pr.altera_sim_pr_activate = pr_activate;
`endif

// Simulated Clock
always begin
	#(HALF_PERIOD) clk = ~clk;
end

///////////////////////////////////////////////////////////////////////////
// Simulation
///////////////////////////////////////////////////////////////////////////

initial begin
   ///////////////////////////////////////////////////////////////////////////
	// Initialization
	///////////////////////////////////////////////////////////////////////////
	pr_sim_text = "Initialize...";
	persona_select_text = "AND GATE";
	clk = 1; 													// Start clock with rising edge
	pr_activate = 0; 							// Initialize PR to not activate
	persona_select = PERSONA_AND_GATE;	// Setting DEFAULT persona as the default persona
	freeze = 0;													// Disable freeze output
	rst_n = 1;													// Disable reset
	a = 0;
	b = 0;
	
	// Initial reset to put personas into known state
	#(CLOCK_CYCLE);
		pr_sim_text = "Initial RST";
		rst_n = 1'b0; // Assert reset
	#(CLOCK_CYCLE);
		rst_n = 1'b1; // De-assert reset
	
	///////////////////////////////////////////////////////////////////////////
	//  PR Section #1: PR w/ Freeze then Reset
	///////////////////////////////////////////////////////////////////////////	
		pr_sim_text = "SECTION #1: PR W/ FRZ -> RST";
		
		// AND Persona
		a = 1'b0;
		b = 1'b0;
	#(CLOCK_CYCLE * 2);

		a = 1'b1;
		b = 1'b0;
   #(CLOCK_CYCLE * 2);

		a = 1'b0;
		b = 1'b1;
   #(CLOCK_CYCLE * 2);


		a = 1'b1;
		b = 1'b1;
	#(CLOCK_CYCLE * 2);
	
		// Counter Persona
		a =  1'b0;
		b =  1'b0;
		pr_activate = 1;
		freeze = 1;
		persona_select = PERSONA_COUNTER;
		persona_select_text = "COUNTER";
	#(CLOCK_CYCLE * 1);
	
		pr_activate = 0;
		freeze = 0;
		rst_n = 1'b0;		
	#(CLOCK_CYCLE * 1);

		rst_n = 1'b1;		
	#(CLOCK_CYCLE * 16); // Run Counter persona
	
		// FSM Persona
		pr_activate = 1;
		freeze = 1;
		persona_select = PERSONA_FSM;
		persona_select_text = "FSM";
	#(CLOCK_CYCLE * 1);
	
		pr_activate = 0;
		freeze = 0;
		rst_n = 1'b0;		
	#(CLOCK_CYCLE * 1);
	
		rst_n = 1'b1;
		a = 1'b0;
		b = 1'b0;		
	#(CLOCK_CYCLE * 4);

		a = 1'b1;
		b = 1'b0;
	#(CLOCK_CYCLE * 4);

		a = 1'b0;
		b = 1'b1;
	#(CLOCK_CYCLE * 4);

		a = 1'b1;
		b = 1'b1;
	#(CLOCK_CYCLE * 4);

	///////////////////////////////////////////////////////////////////////////
	//  RST between Section #1 & #2
	///////////////////////////////////////////////////////////////////////////
//	#(CLOCK_CYCLE);
		pr_sim_text = "SECTION RST";
		persona_select_text = "AND GATE";
		freeze = 1;
		pr_activate = 1;
		persona_select = PERSONA_AND_GATE;
	
	#(CLOCK_CYCLE);
		rst_n = 1'b0;
		freeze = 0;
		pr_activate = 0;
		
	#(CLOCK_CYCLE);
		rst_n = 1'b1;
		
	///////////////////////////////////////////////////////////////////////////
	//  PR Section #2: PR then Reset (No Freeze)
	///////////////////////////////////////////////////////////////////////////	
		pr_sim_text = "SECTION #2: PR -> RST";
		
		a = 1'b0;
		b = 1'b0;
	#(CLOCK_CYCLE * 2);

		a = 1'b1;
		b = 1'b0;
   #(CLOCK_CYCLE * 2);

		a = 1'b0;
		b = 1'b1;
   #(CLOCK_CYCLE * 2);

		a = 1'b1;
		b = 1'b1;			
	#(CLOCK_CYCLE * 2);
		
		// Counter Persona
		a =  1'b0;
		b =  1'b0;
		pr_activate = 1;
		persona_select = PERSONA_COUNTER;
		persona_select_text = "COUNTER";
	#(CLOCK_CYCLE * 1);
	
		pr_activate = 0;
		rst_n = 1'b0;	
	#(CLOCK_CYCLE * 1);
	
		rst_n = 1'b1;		
	#(CLOCK_CYCLE * 16); // Run counter persona

		// FSM Persona
		pr_activate = 1;
		persona_select = PERSONA_FSM;
		persona_select_text = "FSM";
	#(CLOCK_CYCLE * 1);

		pr_activate = 0;
		rst_n = 1'b0;			
	#(CLOCK_CYCLE * 1);
	
		rst_n = 1'b1;	
		a = 1'b0;
		b = 1'b0;
	#(CLOCK_CYCLE * 4);
	
		a = 1'b1;
		b = 1'b0;
	#(CLOCK_CYCLE * 4);

		a = 1'b0;
		b = 1'b1;
	#(CLOCK_CYCLE * 4);

		a = 1'b1;
		b = 1'b1;
	#(CLOCK_CYCLE * 4);
	

	///////////////////////////////////////////////////////////////////////////
	//  RST between Section #2 & #3
	///////////////////////////////////////////////////////////////////////////
//	#(CLOCK_CYCLE);
		pr_sim_text = "SECTION RST";
		persona_select_text = "AND GATE";
		freeze = 1;
		pr_activate = 1;
		persona_select = PERSONA_AND_GATE;
	#(CLOCK_CYCLE);
	
		rst_n = 1'b0; // Assert reset
		freeze = 0;
		pr_activate = 0;	
	#(CLOCK_CYCLE);
	
		rst_n = 1'b1; // De-assert reset
		
	///////////////////////////////////////////////////////////////////////////
	//  PR Section #3: PR only
	///////////////////////////////////////////////////////////////////////////	
		pr_sim_text = "SECTION #3: PR ONLY";
		
		// AND Persona
		a = 1'b0;
		b = 1'b0;
	#(CLOCK_CYCLE * 2);

		a = 1'b1;
		b = 1'b0;
   #(CLOCK_CYCLE * 2);

		a = 1'b0;
		b = 1'b1;
   #(CLOCK_CYCLE * 2);
	
		a = 1'b1;
		b = 1'b1;			
	#(CLOCK_CYCLE * 2);
		
		// Counter Persona
		a =  1'b0;
		b =  1'b0;
		pr_activate = 1;
		persona_select = PERSONA_COUNTER;
		persona_select_text = "COUNTER";
	#(CLOCK_CYCLE * 1);
	
		pr_activate = 0;		
	#(CLOCK_CYCLE * 16); // Let COUNTER Persona run	
	
		// FSM Persona
		pr_activate = 1;
		persona_select = PERSONA_FSM;	
		persona_select_text = "FSM";
	#(CLOCK_CYCLE * 1);

		pr_activate = 0;		
	#(CLOCK_CYCLE * 1);

		a = 1'b0;
		b = 1'b0;		
	#(CLOCK_CYCLE * 4);
	
		a = 1'b1;
		b = 1'b0;
	#(CLOCK_CYCLE * 4);

		a = 1'b0;
		b = 1'b1;
	#(CLOCK_CYCLE * 4);

		a = 1'b1;
		b = 1'b1;
	#(CLOCK_CYCLE * 4);
	
	// End of Simulation
	$stop;
end

endmodule
