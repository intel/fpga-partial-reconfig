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

// This module provides ddr_wr_rd block one pair of
// target_address,target_data and receives pass and fail signals back from
// ddr_wr_rd block. It repeats the same until all addresses are exercised.
//
// It keeps track of addresses in each of mode0 and mode1 and generates
// final_address accordingly.
//
// This module creates a 512-bit data from the 32-bit data that lfsr moduel
// generates.

module traffic_generator 
(
   input wire         pr_region_clk,
   input wire         clr_io_reg,

   // interface to mem_access
   input wire         start_traffic_generator,
   output reg         ddr_access_completed,

   // interface to register block
   input wire [31:0]  mem_addr,
   input wire         post_wr_pulse,
   input wire [31:0]  seed,
   input wire         load_seed,

   // interface to ddr_wr_rd module
   output reg         start_ddr_wr_rd,
   output reg [24:0]  target_address,
   output reg [511:0] target_data,
   input wire         pass,
   input wire         fail,

   input wire         pr_logic_rst, 
   input wire [31:0]  final_addr
);

   wire [31:0]         rndm_data;
   reg                 start_traffic_generator_q;

   typedef enum reg [2:0] 
   {
      IDLE,
      ACTIVE,
      WAIT,
      UNDEF
   } states_definition_t;

   states_definition_t curr_state, next_state;

   always_ff @(posedge pr_region_clk or posedge pr_logic_rst ) 
   begin
      if ( pr_logic_rst == 1'b1  ) 
      begin
         curr_state <= IDLE;
      end
      else begin
         if ( clr_io_reg == 1'b1 ) begin
            curr_state <= IDLE;
         end
         else begin
            curr_state <= next_state;
         end
      end
   end

   // Also check for overlapping case values, item duplicated or not found;
   // hence no default case!
   always_comb begin

      // Default next_state assignment of type undefined 
      next_state = UNDEF;
      unique case ( curr_state )

         IDLE: begin
            if (( target_address == final_addr[24:0] ) && ( |target_address ))   next_state = IDLE;
            else if ( start_traffic_generator == 1'b1 )                          next_state = ACTIVE;
            else                                                                 next_state = IDLE;
         end

         ACTIVE: begin
            if ( target_address == final_addr[24:0] )                            next_state = IDLE;
            else                                                                 next_state = WAIT;
         end

         WAIT: begin
            if ( pass | fail )                                                   next_state = ACTIVE;
            else                                                                 next_state = WAIT;
         end

         default :                                                               next_state = UNDEF;
         
      endcase
   end

   always_ff @(posedge pr_region_clk or posedge pr_logic_rst ) begin

      if ( pr_logic_rst == 1'b1 ) begin
         ddr_access_completed <= '0;
         start_ddr_wr_rd <= 0;
      end
      else begin
         if ( clr_io_reg == 1'b1 ) begin
            ddr_access_completed <= '0;
            start_ddr_wr_rd <= 0;
         end
         else begin
            // default values
            ddr_access_completed <= '0;
            start_ddr_wr_rd <= 0;
            unique case ( next_state )
               IDLE: begin
                  start_ddr_wr_rd <= 0;
                  if (( target_address == final_addr[24:0] ) && ( |target_address )) ddr_access_completed <= 1'b1;
               end
               ACTIVE: begin
                  start_ddr_wr_rd <= 1;
               end
               
               WAIT: begin
                  start_ddr_wr_rd <= 1;
               end

               default : begin
                  ddr_access_completed <= '0;
                  start_ddr_wr_rd <= 0;
               end
            endcase
         end
      end
   end

   always_ff @(posedge pr_region_clk  or posedge pr_logic_rst) begin

      if ( pr_logic_rst == 1'b1 ) begin
         start_traffic_generator_q <= 1'b0;
         target_address <= 'b0;
      end
      else begin
         if ( clr_io_reg == 1'b1 ) begin
            start_traffic_generator_q <= 1'b0;
            target_address <= 'b0;
         end
         else begin
            // load the initial_addr during Idle state
            if ( start_ddr_wr_rd == 0 ) begin
               target_address <= mem_addr[24:0];
            end
            else if ( ( pass == 1'b1 ) || ( fail == 1'b1 ) ) 
            begin
               // increment to the next address when ddr_wr_rd module
               // opertion completed (i.e. either pass or fail got asserted)
               target_address <= target_address + 1'b1;
            end
            else  
            begin
               // hold the value of target_address if there is no "pass" generated
               target_address <= target_address;
            end
            start_traffic_generator_q <= start_traffic_generator;
         end
      end
   end
   
   always_ff @(posedge pr_region_clk) begin

      if (( pass  == 1'b1 ) || ( ( start_traffic_generator == 1'b1 ) && ( start_traffic_generator_q == 1'b0 )))
         target_data = {
         ~{rndm_data[31:10]},~{rndm_data[9:0],rndm_data[31:22]},~{rndm_data[21:0]},
            ~{rndm_data[31:10]},~{rndm_data[9:0],rndm_data[31:22]}, {rndm_data[21:0]},
            ~{rndm_data[31:10]}, {rndm_data[9:0],rndm_data[31:22]},~{rndm_data[21:0]},
            ~{rndm_data[31:10]}, {rndm_data[9:0],rndm_data[31:22]}, {rndm_data[21:0]},
            {rndm_data[31:10]},~{rndm_data[9:0],rndm_data[31:22]},~{rndm_data[21:0]},
            {rndm_data[31:10]},~{rndm_data[9:0],rndm_data[31:22]}, {rndm_data[21:0]},
            {rndm_data[31:10]}, {rndm_data[9:0],rndm_data[31:22]},~{rndm_data[21:0]},
            {rndm_data[31:10]}, {rndm_data[9:0],rndm_data[31:22]}, {rndm_data[21:0]} };
   end

   lfsr u_lfsr (
             .clk            ( pr_region_clk ),
             .rst            ( clr_io_reg | pr_logic_rst ),
             .load_seed      ( load_seed ),
             .seed           ( seed ),
             .out            ( rndm_data )
             );

endmodule
