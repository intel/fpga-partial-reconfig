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

module pr_sim_wrapper 
	#(	parameter OUTPUT_WIDTH = 2) (
	input logic clk,
	input logic rst_n,
	input logic a,
	input logic b,
	output logic [OUTPUT_WIDTH-1:0] result
);

// Local parameter's
localparam ENABLE_PERSONA_0 = 1;
localparam ENABLE_PERSONA_1 = 1;
localparam ENABLE_PERSONA_2 = 1;
localparam NUM_PERSONA = 3;

// MUX signals
logic 							clk_mux 		[NUM_PERSONA-1:0];
logic 							rst_n_mux 	[NUM_PERSONA-1:0];
logic 							a_mux 		[NUM_PERSONA-1:0];
logic 							b_mux 		[NUM_PERSONA-1:0];
logic [OUTPUT_WIDTH-1:0]	result_mux	[NUM_PERSONA-1:0];
logic [OUTPUT_WIDTH-1:0]	result_mux_out;							

// Control signals
logic 	pr_activate;	
integer 	persona_select;
wire 		freeze;

////////////////////////////////////////
// Generate AND Gate
////////////////////////////////////////
generate

if (ENABLE_PERSONA_0) begin
		localparam persona_id = 0;

	`ifdef ALTERA_ENABLE_PR_MODEL
		assign u_and_gate.altera_sim_pr_activate = pr_activate;
	`endif
	
	and_gate #(
//		.OUTPUT_WIDTH(OUTPUT_WIDTH) // Note: PR sim model doesn't keep parameterization
		) 
		
		u_and_gate (
			.clk(clk_mux[persona_id]),
			.rst_n(rst_n_mux[persona_id]),
			.a(a_mux[persona_id]),
			.b(b_mux[persona_id]),
			.result(result_mux[persona_id])
		);
	
	end
endgenerate

////////////////////////////////////////
// Generate Counter
////////////////////////////////////////
generate
	if (ENABLE_PERSONA_1) begin
		localparam persona_id = 1;

	`ifdef ALTERA_ENABLE_PR_MODEL
		assign u_counter.altera_sim_pr_activate = pr_activate;
	`endif
	
	counter #(
//		.OUTPUT_WIDTH(OUTPUT_WIDTH) // Note: PR sim model doesn't keep parameterization
		) 
	
	u_counter (
		.clk(clk_mux[persona_id]),
		.rst_n(rst_n_mux[persona_id]),
		.a(a_mux[persona_id]),
		.b(b_mux[persona_id]),
		.result(result_mux[persona_id])
	);
	
	end
endgenerate

////////////////////////////////////////
// Generate FSM
////////////////////////////////////////
generate
	if (ENABLE_PERSONA_2) begin
		localparam persona_id = 2;

	`ifdef ALTERA_ENABLE_PR_MODEL
		assign u_fsm.altera_sim_pr_activate = pr_activate;
	`endif
	
	fsm #(
//		.OUTPUT_WIDTH(OUTPUT_WIDTH) // Note: PR sim model doesn't keep parameterization
		) 
	
	u_fsm (
		.clk(clk_mux[persona_id]),
		.rst_n(rst_n_mux[persona_id]),
		.a(a_mux[persona_id]),
		.b(b_mux[persona_id]),
		.result(result_mux[persona_id])
	);
	
	end
endgenerate

////////////////////////////////////////
// Input Muxes
////////////////////////////////////////

// Control Input Muxes
altera_pr_wrapper_mux_in #(
	.NUM_PERSONA(NUM_PERSONA), 
	.WIDTH(1'b1)
	) 
	
	u_clock_mux( 
		.sel(persona_select), 
		.mux_in(clk), 
		.mux_out(clk_mux)
);

altera_pr_wrapper_mux_in #(
	.NUM_PERSONA(NUM_PERSONA), 
	.WIDTH(1'b1)
	) 
	
	u_reset_mux( 
		.sel(persona_select), 
		.mux_in(rst_n), 
		.mux_out(rst_n_mux)
);

// Data Input Muxes
altera_pr_wrapper_mux_in #(
	.NUM_PERSONA(NUM_PERSONA), 
	.WIDTH(1'b1)
	) 
	
	u_a_mux( 
		.sel(persona_select), 
		.mux_in(a), 
		.mux_out(a_mux)
);

altera_pr_wrapper_mux_in #(
	.NUM_PERSONA(NUM_PERSONA), 
	.WIDTH(1'b1)
	) 
	
	u_b_mux( 
		.sel(persona_select), 
		.mux_in(b), 
		.mux_out(b_mux)
);

////////////////////////////////////////
// Output Muxes
////////////////////////////////////////

// Data Output Muxes
altera_pr_wrapper_mux_out #(
	.NUM_PERSONA(NUM_PERSONA), 
	.WIDTH(OUTPUT_WIDTH)
	) 
	
	u_result_mux( 
		.sel(persona_select), 
		.mux_in(result_mux), 
		.mux_out(result_mux_out),
		.pr_activate(pr_activate)
);


////////////////////////////////////////
// Freeze Logic Controller
////////////////////////////////////////
freeze_logic_controller #(	
	.DATA_WIDTH(OUTPUT_WIDTH),
	.FREEZE_LOGIC_OUTPUT(1'b1)
	)
	
	u_freeze_logic_controller(
		.data_in(result_mux_out),
		.freeze_output(freeze),
		.data_out(result)
);


endmodule
