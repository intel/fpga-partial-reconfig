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

module pr_logic_wrapper 
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
      input wire [127:0]   emif_avmm_readdata , 
      input wire           emif_avmm_readdatavalid , 
      output reg [6:0]     emif_avmm_burstcount , 
      output reg [127:0]   emif_avmm_writedata , 
      output reg [24:0]    emif_avmm_address , 
      output reg           emif_avmm_write , 
      output reg           emif_avmm_read , 
      output reg [15:0]    emif_avmm_byteenable , 
      output reg           emif_avmm_debugaccess ,

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
      input wire [15:0]    pr_region_avmm_address , 
      input wire           pr_region_avmm_write , 
      input wire           pr_region_avmm_read , 
      input wire [3:0]     pr_region_avmm_byteenable , 
      input wire           pr_region_avmm_debugaccess    
   );


   ddr4_access_persona_top u_pr_logic
   (
      .pr_region_clk               ( pr_region_clk ),
      .pr_logic_rst                ( pr_logic_rst ),
      .emif_usr_clk                ( emif_usr_clk ),
      .emif_usr_rst_n              ( emif_usr_rst_n ),
      .tck                         ( tck ),
      .tms                         ( tms ),
      .tdi                         ( tdi ),
      .vir_tdi                     ( vir_tdi ),
      .ena                         ( ena ),
      .tdo                         ( tdo ),
      .emif_avmm_waitrequest       ( emif_avmm_waitrequest ),
      .emif_avmm_readdata          ( emif_avmm_readdata ),
      .emif_avmm_readdatavalid     ( emif_avmm_readdatavalid ),
      .emif_avmm_burstcount        ( emif_avmm_burstcount ),
      .emif_avmm_writedata         ( emif_avmm_writedata ),
      .emif_avmm_address           ( emif_avmm_address ),
      .emif_avmm_write             ( emif_avmm_write ),
      .emif_avmm_read              ( emif_avmm_read ),
      .emif_avmm_byteenable        ( emif_avmm_byteenable ),
      .pr_handshake_start_req      ( pr_handshake_start_req ),
      .pr_handshake_start_ack      ( pr_handshake_start_ack ),
      .pr_handshake_stop_req       ( pr_handshake_stop_req ),
      .pr_handshake_stop_ack       ( pr_handshake_stop_ack ),
      .freeze_pr_region_avmm       ( freeze_pr_region_avmm ),
      .pr_region_avmm_waitrequest  ( pr_region_avmm_waitrequest ),
      .pr_region_avmm_readdata     ( pr_region_avmm_readdata ),
      .pr_region_avmm_readdatavalid( pr_region_avmm_readdatavalid ),
      .pr_region_avmm_burstcount   ( pr_region_avmm_burstcount ),
      .pr_region_avmm_writedata    ( pr_region_avmm_writedata ),
      .pr_region_avmm_address      ( pr_region_avmm_address ),
      .pr_region_avmm_write        ( pr_region_avmm_write ),
      .pr_region_avmm_read         ( pr_region_avmm_read ),
      .pr_region_avmm_byteenable   ( pr_region_avmm_byteenable )
   );
endmodule
