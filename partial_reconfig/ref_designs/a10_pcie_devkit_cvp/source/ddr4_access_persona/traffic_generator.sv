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

module traffic_generator (
      input  wire         pr_logic_clk_clk,                 //       pr_logic_clk.clk
      input  wire         sw_reset,

      // interface to mem_access
      input  wire         start_traffic_generator,
      output reg          ddr_access_completed,

      // interface to register block
      input  wire [1:0]   mode,
      inout  wire [7:0]   limit,
      input  wire [31:0]  mem_addr,
      input  wire         post_wr_pulse,
      input  wire [31:0]  seed,
      input  wire         load_seed,

      // interface to ddr_wr_rd module
      output reg          start_ddr_wr_rd,
      output reg  [30:0]  target_address,
      output reg  [511:0] target_data,
      input  wire         pass,
      input  wire         fail,

      input  wire         pr_logic_reset_reset_n            //     pr_logic_reset.reset_n
   );

   wire [31:0]     rndm_data;
   reg             start_traffic_generator_q;
   reg  [31:0]     initial_addr;
   reg  [31:0]     final_addr;

   // using enum to create indices for one-hot encoding
   typedef enum {
      idle_indx,
      active_indx,
      wait_indx
   } states_indx;

   // encoding one-hot states
   typedef enum logic [2:0] {
      IDLE       = 3'b1 << idle_indx,
      ACTIVE     = 3'b1 << active_indx,
      WAIT       = 3'b1 << wait_indx,
      UNDEF      = 'x
   } states_definition;

   states_definition curr_state, next_state;

   always_ff @(posedge pr_logic_clk_clk or negedge pr_logic_reset_reset_n) begin


      // Active low HW reset
      if (  pr_logic_reset_reset_n == 1'b0 ) begin


         curr_state <= IDLE;

      end
      // Active high SW reset
      else if (  sw_reset == 1'b1 ) begin


         curr_state <= IDLE;

      end
      else begin


         curr_state <= next_state;

      end
   end

   // Also check for overlapping case values, item duplicated or not found;
   // hence no default case!
   always_comb begin

      // Default next_state assignment of type undefined 
      next_state = UNDEF;

      unique case ( curr_state )

         IDLE: begin

            if (( target_address == final_addr[30:0] )  && 
               ( |target_address ))                                next_state = IDLE;
            else if ( start_traffic_generator == 1'b1 )             next_state = ACTIVE;
            else                                                    next_state = IDLE;
         end

         ACTIVE: begin

            if ( target_address == final_addr[30:0] )               next_state = IDLE;
            else                                                    next_state = WAIT;
         end

         WAIT: begin

            if ( pass | fail )                                      next_state = ACTIVE;
            else                                                    next_state = WAIT;
         end

         default :                                                   next_state = UNDEF;
   
      endcase
   end

   // Capture the value of the starting address
   always_ff @(posedge pr_logic_clk_clk or negedge pr_logic_reset_reset_n) begin


      // Active low HW reset
      if (  pr_logic_reset_reset_n == 1'b0 ) begin


         initial_addr <= '0;

      end
      // initial_addr value does not get reset by sw_reset assertion since it works as the shadow register 
      // Whenever the PR_MEM_ADDR gets updated, this shadow resgiters gets updated and gets loaded for the logic in Idle state
      else if ( post_wr_pulse == 1'b1 )  begin


         initial_addr <= mem_addr;

      end
   end


   always_ff @(posedge pr_logic_clk_clk or negedge pr_logic_reset_reset_n) begin


      // Active low HW reset
      if (  pr_logic_reset_reset_n == 1'b0 ) begin


         ddr_access_completed <= '0;
         start_ddr_wr_rd <= 0;

      end
      // Active high SW reset
      else if (  sw_reset == 1'b1 )  begin


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

               if (( target_address == final_addr[30:0] ) && ( |target_address ))
                  ddr_access_completed <= 1'b1;
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



   always_ff @(posedge pr_logic_clk_clk or negedge pr_logic_reset_reset_n) begin

      // Active low HW reset
      if (  pr_logic_reset_reset_n == 1'b0 ) begin


         start_traffic_generator_q <= 1'b0;
         target_address     <= 'b0;

      end
      // Active high SW reset
      else if (  sw_reset == 1'b1 ) begin


         start_traffic_generator_q <= 1'b0;
         target_address     <= 'b0;

      end
      else begin


         // load the initial_addr during Idle state
         if ( start_ddr_wr_rd == 0 ) begin

            target_address     <= initial_addr[30:0];
         end
         else if ( ( pass == 1'b1 ) || ( fail == 1'b1 ) ) begin

            // increment to the next address when ddr_wr_rd module
            // opertion completed (i.e. either pass or fail got asserted)
            target_address <= target_address + 1'b1;
         end
         else  begin

            // hold the value of target_address if there is no "pass" generated
            target_address <= target_address;
         end

         start_traffic_generator_q <= start_traffic_generator;
      end
   end






   always_ff @(posedge pr_logic_clk_clk) begin

      if (( pass   == 1'b1 ) || ( ( start_traffic_generator == 1'b1 ) && ( start_traffic_generator_q == 1'b0 )))
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

   always_comb begin

      if ( mode == 2'b0 ) begin

         final_addr = {9'b0,22'h3f_ffff};
      end
      else begin

         final_addr = mem_addr + limit;
      end

   end

   lfsr u_lfsr (
      .pr_logic_clk_clk                       ( pr_logic_clk_clk ),
      .sw_reset                             ( sw_reset ),
      .load_seed                              ( load_seed ),
      .seed                                   ( seed ),
      .rndm_data                              ( rndm_data ),
      .pr_logic_reset_reset_n                 ( pr_logic_reset_reset_n )
   );

endmodule
