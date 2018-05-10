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

// This is the control module for the GOL persona

module moderator #( parameter REG_FILE_IO_SIZE = 8 ) 
(  
   input wire           clk,            
   input wire           pr_logic_rst,
   output wire          clr_io_reg,
   output wire [31:0]   persona_id, 
   input wire  [31:0]   host_cntrl_register, 
   input wire  [31:0]   host_pr [0:REG_FILE_IO_SIZE-1],
   output wire [31:0]   pr_host [0:REG_FILE_IO_SIZE-1]
);

   reg  local_clr_io_reg_q;
   reg  local_clr_io_reg;
   reg  start_pulse_d;
   reg  count;
   reg  start_game_delay;
   reg  count_delay;
   reg  start_pulse;
   reg  game_done;
   reg  [31:0] counter;
   reg  [31:0] board_start [0:1];
   reg  [31:0] bot_half_start;
   reg  [31:0] counter_limit;
   
   wire [31:0] board_final [0:1];
   wire result;
   wire start_game;

   assign persona_id       = 32'h00676F6C;

   assign pr_host[0][31:0] = ({31'h0,count});
   assign pr_host[1][31:0] = board_final[0];
   assign pr_host[2][31:0] = board_final[1];
   assign start_game       = start_game_delay;
   assign count            = (counter < counter_limit) && start_game;
   assign clr_io_reg       = local_clr_io_reg;
   
   always_ff @(posedge clk or posedge pr_logic_rst) begin
      if (  pr_logic_rst == 1'b1 ) begin
         local_clr_io_reg_q   <= 1'b0;
         local_clr_io_reg     <= 1'b0;
      end
      else begin
         local_clr_io_reg_q   <= host_cntrl_register[0]; 
         local_clr_io_reg     <= ~local_clr_io_reg_q && host_cntrl_register[0]; 
      end
   end
   
   always_ff @(posedge clk or posedge pr_logic_rst) begin
      if (  pr_logic_rst == 1'b1 ) begin
         counter_limit  <= 0;
         board_start[0] <= 0;
         board_start[1] <= 0;
      end
      else begin
         if(local_clr_io_reg == 1'b1) begin
            counter_limit  <= 0;
            board_start[0] <= 0;
            board_start[1] <= 0;
         end
         else begin
            counter_limit  <= host_pr[0][31:0];
            board_start[0] <= host_pr[1][31:0];
            board_start[1] <= host_pr[2][31:0];
         end
      end
   end


   always_ff @(posedge clk or posedge pr_logic_rst) begin
      if (  pr_logic_rst == 1'b1 ) begin
         counter <= 32'b0;
      end
      else begin
         if (  local_clr_io_reg == 1'b1 ) begin
            counter <= 32'b0;
         end
         else begin
            if(start_pulse == 1'b1) begin
            counter <= 0;
            end
            if(count == 1'b1) begin
               counter <= counter + 1;
            end
         end
      end
   end

   always_ff @(posedge clk or posedge pr_logic_rst) begin
      if (  pr_logic_rst == 1'b1 ) begin
         start_pulse_d     <= 'b0;
         start_pulse       <= 'b0;
         start_game_delay  <= 'b0;
         game_done         <= 'b0;
      end
      else begin 
         if (  local_clr_io_reg == 1'b1 ) begin
            start_pulse_d     <= 'b0;
            start_pulse       <= 'b0;
            start_game_delay  <= 'b0;
            game_done         <= 'b0;
         end
         else begin
            if(start_pulse == 1'b1) begin
            start_game_delay  <= 1'b1;
            game_done         <= 1'b0;
            end
            if(count == 1'b0 && start_game == 1'b1) begin
               start_game_delay  <= 1'b0;
               game_done         <= 1'b1;
            end
            start_pulse_d  <= host_cntrl_register[1];
            start_pulse    <= ~start_pulse_d && host_cntrl_register[1];
         end
      end
   end


         
   gol_block_wrapper  u_gol_block_wrapper  
   (
      .clk           ( clk ),
      .clk_en        ( count ),
      .init          ( start_pulse ),
      .rst           ( pr_logic_rst ),
      .board_initial ( {board_start[0], board_start[1]} ),
      .board_final   ( {board_final[0], board_final[1]} )
   );

endmodule
