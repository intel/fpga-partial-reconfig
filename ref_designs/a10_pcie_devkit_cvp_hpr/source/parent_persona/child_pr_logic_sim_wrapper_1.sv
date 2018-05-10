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

`timescale 1 ps / 1 ps
`default_nettype none

`include "uvm_macros.svh"
`include "altr_cmn_macros.sv"

module child_pr_logic_wrapper_1
(
   input wire         pr_region_clk , 
   input wire         pr_logic_rst , 
   input wire         emif_usr_clk ,
   input wire         emif_usr_rst_n ,

   // Signaltap Interface
   input wire           tck ,
   input wire           tms ,
   input wire           tdi ,
   input wire           vir_tdi ,
   input wire           ena ,
   output wire          tdo ,
   // DDR4 interface
   input wire           emif_avmm_waitrequest , 
   input wire [511:0]   emif_avmm_readdata , 
   input wire           emif_avmm_readdatavalid , 
   output reg [6:0]     emif_avmm_burstcount , 
   output reg [511:0]   emif_avmm_writedata , 
   output reg [24:0]    emif_avmm_address , 
   output reg           emif_avmm_write , 
   output reg           emif_avmm_read , 
   output reg [63:0]    emif_avmm_byteenable , 

   input wire           pr_handshake_start_req ,
   output reg           pr_handshake_start_ack ,
   input wire           pr_handshake_stop_req ,
   output reg           pr_handshake_stop_ack ,
   output wire          freeze_pr_region_avmm ,

   // AVMM interface
   output reg           pr_region_avmm_waitrequest , 
   output reg [31:0]    pr_region_avmm_readdata , 
   output reg           pr_region_avmm_readdatavalid, 
   input wire [0:0]     pr_region_avmm_burstcount , 
   input wire [31:0]    pr_region_avmm_writedata , 
   input wire [13:0]    pr_region_avmm_address , 
   input wire           pr_region_avmm_write , 
   input wire           pr_region_avmm_read , 
   input wire [3:0]     pr_region_avmm_byteenable 
);

localparam ENABLE_PERSONA_0 = 1;
localparam NUM_PERSONA = 1;

logic                pr_activate;
int                  persona_select;

altera_pr_persona_if persona_bfm();
assign pr_activate = persona_bfm.pr_activate;
assign persona_select = persona_bfm.persona_select;

//   Register the PR region IF
initial begin
   `altr_set_if(virtual altera_pr_persona_if, "testbench", "parent_persona_pr_region1", persona_bfm)
end

wire                 pr_region_clk_mux [NUM_PERSONA-1:0];
wire                 pr_logic_rst_mux [NUM_PERSONA-1:0];
wire                 emif_usr_clk_mux [NUM_PERSONA-1:0];
wire                 emif_usr_rst_n_mux [NUM_PERSONA-1:0];

wire                 emif_avmm_waitrequest_mux [NUM_PERSONA-1:0];
wire [511:0]         emif_avmm_readdata_mux [NUM_PERSONA-1:0];
wire                 emif_avmm_readdatavalid_mux [NUM_PERSONA-1:0];
wire [6:0]           emif_avmm_burstcount_mux [NUM_PERSONA-1:0];
wire [511:0]         emif_avmm_writedata_mux [NUM_PERSONA-1:0];
wire [24:0]          emif_avmm_address_mux [NUM_PERSONA-1:0];
wire                 emif_avmm_write_mux [NUM_PERSONA-1:0];
wire                 emif_avmm_read_mux [NUM_PERSONA-1:0];
wire [63:0]          emif_avmm_byteenable_mux [NUM_PERSONA-1:0];

wire                 pr_region_avmm_waitrequest_mux [NUM_PERSONA-1:0];
wire [31:0]          pr_region_avmm_readdata_mux [NUM_PERSONA-1:0];
wire                 pr_region_avmm_readdatavalid_mux [NUM_PERSONA-1:0];
wire [0:0]           pr_region_avmm_burstcount_mux [NUM_PERSONA-1:0];
wire [31:0]          pr_region_avmm_writedata_mux [NUM_PERSONA-1:0];
wire [13:0]          pr_region_avmm_address_mux [NUM_PERSONA-1:0];
wire                 pr_region_avmm_write_mux [NUM_PERSONA-1:0];
wire                 pr_region_avmm_read_mux [NUM_PERSONA-1:0];
wire [3:0]           pr_region_avmm_byteenable_mux [NUM_PERSONA-1:0];

wire                 pr_handshake_start_req_mux [NUM_PERSONA-1:0];
wire                 pr_handshake_start_ack_mux [NUM_PERSONA-1:0];
wire                 pr_handshake_stop_req_mux [NUM_PERSONA-1:0];
wire                 pr_handshake_stop_ack_mux [NUM_PERSONA-1:0];
wire                 freeze_pr_region_avmm_mux [NUM_PERSONA-1:0];


generate if (ENABLE_PERSONA_0) begin
   localparam persona_id = 0;

`ifdef ALTERA_ENABLE_PR_MODEL
   assign u_persona_0.altera_sim_pr_activate = pr_activate;
`endif

   ddr4_access_persona_top u_persona_0
   (
      .pr_region_clk               ( pr_region_clk_mux [persona_id]),
      .pr_logic_rst                ( pr_logic_rst_mux [persona_id]),
      .emif_usr_clk                ( emif_usr_clk_mux [persona_id]),
      .emif_usr_rst_n              ( emif_usr_rst_n_mux [persona_id]),
      .tck                         ( tck ),
      .tms                         ( tms ),
      .tdi                         ( tdi ),
      .vir_tdi                     ( vir_tdi ),
      .ena                         ( ena ),
      .tdo                         ( tdo ),
      .emif_avmm_waitrequest       ( emif_avmm_waitrequest_mux [persona_id]),
      .emif_avmm_readdata          ( emif_avmm_readdata_mux [persona_id]),
      .emif_avmm_readdatavalid     ( emif_avmm_readdatavalid_mux [persona_id]),
      .emif_avmm_burstcount        ( emif_avmm_burstcount_mux [persona_id]),
      .emif_avmm_writedata         ( emif_avmm_writedata_mux [persona_id]),
      .emif_avmm_address           ( emif_avmm_address_mux [persona_id]),
      .emif_avmm_write             ( emif_avmm_write_mux [persona_id]),
      .emif_avmm_read              ( emif_avmm_read_mux [persona_id]),
      .emif_avmm_byteenable        ( emif_avmm_byteenable_mux [persona_id]),
      .pr_handshake_start_req      ( pr_handshake_start_req_mux [persona_id]),
      .pr_handshake_start_ack      ( pr_handshake_start_ack_mux [persona_id]),
      .pr_handshake_stop_req       ( pr_handshake_stop_req_mux [persona_id]),
      .pr_handshake_stop_ack       ( pr_handshake_stop_ack_mux [persona_id]),
      .freeze_pr_region_avmm       ( freeze_pr_region_avmm_mux [persona_id]),
      .pr_region_avmm_waitrequest  ( pr_region_avmm_waitrequest_mux [persona_id]),
      .pr_region_avmm_readdata     ( pr_region_avmm_readdata_mux [persona_id]),
      .pr_region_avmm_readdatavalid( pr_region_avmm_readdatavalid_mux [persona_id]),
      .pr_region_avmm_burstcount   ( pr_region_avmm_burstcount_mux [persona_id]),
      .pr_region_avmm_writedata    ( pr_region_avmm_writedata_mux [persona_id]),
      .pr_region_avmm_address      ( pr_region_avmm_address_mux [persona_id]),
      .pr_region_avmm_write        ( pr_region_avmm_write_mux [persona_id]),
      .pr_region_avmm_read         ( pr_region_avmm_read_mux [persona_id]),
      .pr_region_avmm_byteenable   ( pr_region_avmm_byteenable_mux [persona_id])
   );

end
endgenerate

altera_pr_wrapper_mux_in #(.NUM_PERSONA(NUM_PERSONA), .WIDTH(1), .DISABLED_OUTPUT_VAL(1'b0)) u_pr_region_clk_mux(.sel(persona_select), .mux_in(pr_region_clk), .mux_out(pr_region_clk_mux));
altera_pr_wrapper_mux_in #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(1) ) u_pr_logic_rst_mux ( .sel(persona_select), .mux_in(pr_logic_rst), .mux_out(pr_logic_rst_mux) );
altera_pr_wrapper_mux_in #(.NUM_PERSONA(NUM_PERSONA), .WIDTH(1), .DISABLED_OUTPUT_VAL(1'b0)) u_emif_usr_clk_mux(.sel(persona_select), .mux_in(emif_usr_clk), .mux_out(emif_usr_clk_mux));
altera_pr_wrapper_mux_in #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(1) ) u_emif_usr_rst_n_mux ( .sel(persona_select), .mux_in(emif_usr_rst_n), .mux_out(emif_usr_rst_n_mux) );

altera_pr_wrapper_mux_in #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(1) ) u_pr_handshake_start_req_mux ( .sel(persona_select), .mux_in(pr_handshake_start_req), .mux_out(pr_handshake_start_req_mux) );
altera_pr_wrapper_mux_out #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(1) ) u_pr_handshake_start_ack_mux ( .sel(persona_select), .mux_in(pr_handshake_start_ack_mux), .mux_out(pr_handshake_start_ack), .pr_activate(pr_activate) );
altera_pr_wrapper_mux_in #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(1) ) u_pr_handshake_stop_req_mux ( .sel(persona_select), .mux_in(pr_handshake_stop_req), .mux_out(pr_handshake_stop_req_mux) );
altera_pr_wrapper_mux_out #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(1) ) u_pr_handshake_stop_ack_mux ( .sel(persona_select), .mux_in(pr_handshake_stop_ack_mux), .mux_out(pr_handshake_stop_ack), .pr_activate(pr_activate) );
altera_pr_wrapper_mux_out #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(1) ) u_freeze_pr_region_avmm_mux ( .sel(persona_select), .mux_in(freeze_pr_region_avmm_mux), .mux_out(freeze_pr_region_avmm), .pr_activate(pr_activate) );

altera_pr_wrapper_mux_in #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(1) ) u_emif_avmm_waitrequest_mux ( .sel(persona_select), .mux_in(emif_avmm_waitrequest), .mux_out(emif_avmm_waitrequest_mux) );
altera_pr_wrapper_mux_in #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(512) ) u_emif_avmm_readdata_mux ( .sel(persona_select), .mux_in(emif_avmm_readdata), .mux_out(emif_avmm_readdata_mux) );
altera_pr_wrapper_mux_in #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(1) ) u_emif_avmm_readdatavalid_mux ( .sel(persona_select), .mux_in(emif_avmm_readdatavalid), .mux_out(emif_avmm_readdatavalid_mux) );
altera_pr_wrapper_mux_out #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(7) ) u_emif_avmm_burstcount_mux ( .sel(persona_select), .mux_in(emif_avmm_burstcount_mux), .mux_out(emif_avmm_burstcount), .pr_activate(pr_activate) );
altera_pr_wrapper_mux_out #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(512) ) u_emif_avmm_writedata_mux ( .sel(persona_select), .mux_in(emif_avmm_writedata_mux), .mux_out(emif_avmm_writedata), .pr_activate(pr_activate) );
altera_pr_wrapper_mux_out #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(25) ) u_emif_avmm_address_mux ( .sel(persona_select), .mux_in(emif_avmm_address_mux), .mux_out(emif_avmm_address), .pr_activate(pr_activate) );
altera_pr_wrapper_mux_out #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(1) ) u_emif_avmm_write_mux ( .sel(persona_select), .mux_in(emif_avmm_write_mux), .mux_out(emif_avmm_write), .pr_activate(pr_activate) );
altera_pr_wrapper_mux_out #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(1) ) u_emif_avmm_read_mux ( .sel(persona_select), .mux_in(emif_avmm_read_mux), .mux_out(emif_avmm_read), .pr_activate(pr_activate) );
altera_pr_wrapper_mux_out #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(64) ) u_emif_avmm_byteenable_mux ( .sel(persona_select), .mux_in(emif_avmm_byteenable_mux), .mux_out(emif_avmm_byteenable), .pr_activate(pr_activate) );

altera_pr_wrapper_mux_out #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(1) ) u_pr_region_avmm_waitrequest_mux ( .sel(persona_select), .mux_in(pr_region_avmm_waitrequest_mux), .mux_out(pr_region_avmm_waitrequest), .pr_activate(pr_activate) );
altera_pr_wrapper_mux_out #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(32) ) u_pr_region_avmm_readdata_mux ( .sel(persona_select), .mux_in(pr_region_avmm_readdata_mux), .mux_out(pr_region_avmm_readdata), .pr_activate(pr_activate) );
altera_pr_wrapper_mux_out #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(1) ) u_pr_region_avmm_readdatavalid_mux ( .sel(persona_select), .mux_in(pr_region_avmm_readdatavalid_mux), .mux_out(pr_region_avmm_readdatavalid), .pr_activate(pr_activate) );
altera_pr_wrapper_mux_in #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(1) ) u_pr_region_avmm_burstcount_mux ( .sel(persona_select), .mux_in(pr_region_avmm_burstcount), .mux_out(pr_region_avmm_burstcount_mux) );
altera_pr_wrapper_mux_in #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(32) ) u_pr_region_avmm_writedata_mux ( .sel(persona_select), .mux_in(pr_region_avmm_writedata), .mux_out(pr_region_avmm_writedata_mux) );
altera_pr_wrapper_mux_in #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(14) ) u_pr_region_avmm_address_mux ( .sel(persona_select), .mux_in(pr_region_avmm_address), .mux_out(pr_region_avmm_address_mux) );
altera_pr_wrapper_mux_in #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(1) ) u_pr_region_avmm_write_mux ( .sel(persona_select), .mux_in(pr_region_avmm_write), .mux_out(pr_region_avmm_write_mux) );
altera_pr_wrapper_mux_in #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(1) ) u_pr_region_avmm_read_mux ( .sel(persona_select), .mux_in(pr_region_avmm_read), .mux_out(pr_region_avmm_read_mux) );
altera_pr_wrapper_mux_in #( .NUM_PERSONA(NUM_PERSONA), .WIDTH(4) ) u_pr_region_avmm_byteenable_mux ( .sel(persona_select), .mux_in(pr_region_avmm_byteenable), .mux_out(pr_region_avmm_byteenable_mux) );

endmodule
