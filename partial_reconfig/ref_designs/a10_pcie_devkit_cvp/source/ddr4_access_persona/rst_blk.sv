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

// This module generates the reset that causes the memory interface to be reset
// and recalibrated
//
// it also counts how many time recalibration was done.

module rst_blk # (
      parameter RST_CNTR_WIDTH      = 8,
      parameter RECALIB_MAX_NUM     = 2
   ) (
      input  wire         pr_logic_clk_clk,                 //       pr_logic_clk.clk

      input  wire         sw_reset,
      input  wire         emif_reset,
      input  wire         start_recalibration,

      output reg          ddr4a_global_reset,
      output reg          max_retry_cal_reached,
      input  wire         reset_recal_counter,

      output reg          rst_blk_busy,

      input  wire         pr_logic_reset_reset_n            //     pr_logic_reset.reset_n
   );

   // Local Signals
   localparam RST_CNTR_WIDTH_MSB = RST_CNTR_WIDTH -1;

   reg [RST_CNTR_WIDTH_MSB:0] rst_counter;
   reg [2:0]   recal_counter;
   reg     ddr4a_global_reset_q;
   reg     emif_reset_q;
   reg     emif_sw_reset;

   always_comb begin
      rst_blk_busy = ~rst_counter[RST_CNTR_WIDTH_MSB] || ddr4a_global_reset;
   end

   always_ff @(posedge pr_logic_clk_clk or negedge pr_logic_reset_reset_n) begin

      // Active low HW Async reset
      if ( pr_logic_reset_reset_n == 1'b0 ) begin

         recal_counter <= 3'b0;

      end
      // Active high SW Ssync reset
      else if ( ( sw_reset == 1'b1 ) || ( reset_recal_counter == 1'b1 ) ) begin

         recal_counter <= 3'b0;

      end
      else if ( start_recalibration == 1'b1 ) begin

         recal_counter <= recal_counter + 1'b1;

      end
   end

   always_comb begin
      max_retry_cal_reached = (recal_counter == RECALIB_MAX_NUM) ? 1'b1 : 1'b0 ;
   end

   // Generating ddr4a_global_reset to mem_ctlr system which feeds the EMIF input global_reset_n.
   // This EMIF port is an Asynchronous reset whcih causes the memory interface to be reset and recalibrated
   //
   always_ff @(posedge pr_logic_clk_clk or negedge pr_logic_reset_reset_n) begin

      // Active low HW Async reset
      if ( pr_logic_reset_reset_n == 1'b0 ) begin

         rst_counter <= {RST_CNTR_WIDTH{1'b0}};

      end
      else if (( start_recalibration == 1'b1 ) || ( emif_sw_reset == 1'b1 )) begin

         rst_counter <= {RST_CNTR_WIDTH{1'b0}};

      end
      else if ( rst_counter[RST_CNTR_WIDTH_MSB] == 1'b0 ) begin

         rst_counter <= rst_counter + 1'b1;

      end
   end
   
   
   always_ff @(posedge pr_logic_clk_clk or negedge pr_logic_reset_reset_n) begin

      if ( pr_logic_reset_reset_n == 1'b0 ) begin

         ddr4a_global_reset  <= 1'b0;
         ddr4a_global_reset_q  <= 1'b0;
         emif_reset_q <= 1'b0;
         emif_sw_reset <= 1'b0;

      end
      else begin

         ddr4a_global_reset_q <= ~rst_counter[RST_CNTR_WIDTH_MSB];
         ddr4a_global_reset  <= ddr4a_global_reset_q;
         emif_reset_q <= emif_reset;
         emif_sw_reset <= emif_reset & ~emif_reset_q;

      end
   end

endmodule
