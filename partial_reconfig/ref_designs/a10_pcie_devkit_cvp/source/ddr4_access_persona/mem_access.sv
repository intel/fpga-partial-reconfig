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

// This module handles recalibration logic and interacts with traffic
// generator for DDRaccess persona

module mem_access (
      input  wire         pr_logic_clk_clk,                 //       pr_logic_clk.clk
      
      input  wire         sw_reset,
      input  wire         start_operation,
      input  wire         local_cal_success,
      input  wire         local_cal_fail,
      input  wire         max_retry_cal_reached,
      input  wire         ddr_access_completed,

      output reg          clear_start_operation,
      output reg          start_recalibration,
      output reg          start_traffic_generator,
      output reg          busy,    
      output reg          reset_recal_counter,    
      input  wire         rst_blk_busy,
   
      input  wire         pr_logic_reset_reset_n            //     pr_logic_reset.reset_n
   );


   ////////////////////////////////////////////////////////////////////////////
   //
   // State Machien Definitions
   // using enum to create indices for one-hot encoding
   typedef enum {
      idle_indx,
      calibrate_indx,
      wait_indx,
      retry_cal_indx,
      ddr_access_index
   } states_indx;

   // encoding one-hot states
   typedef enum logic [4:0] {
      IDLE       = 5'b1 << idle_indx,
      CALIBRATE  = 5'b1 << calibrate_indx,
      WAIT       = 5'b1 << wait_indx,
      RETRY_CAL  = 5'b1 <<  retry_cal_indx,
      DDR_ACCESS = 5'b1 << ddr_access_index,
      UNDEF      = 'x
   } states_definition;

   states_definition curr_state, next_state;
   //
   ////////////////////////////////////////////////////////////////////////////

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

            if ( ( start_operation == 1'b1 ) && ( ddr_access_completed == 1'b0 ) && ( max_retry_cal_reached == 1'b0 ) ) begin

               next_state = CALIBRATE;
            end
            else begin

               next_state = IDLE;

            end
         end

         CALIBRATE: begin

            case ( {local_cal_success, local_cal_fail} )

               2'b 00: begin

                  next_state = WAIT;

               end
               2'b 01: begin

                  if ( max_retry_cal_reached == 1'b0 ) begin

                     next_state = RETRY_CAL;

                  end
                  else begin

                     next_state = IDLE;

                  end
               end
               2'b 10: begin

                  next_state = DDR_ACCESS;

               end
               2'b 11: begin

                  next_state = IDLE;

               end
            endcase
         end


         WAIT: begin
            if ( rst_blk_busy == 1'b1 ) begin

               next_state = WAIT;

            end
            else if ( (local_cal_success || local_cal_fail) == 1'b1 ) begin

               next_state = CALIBRATE;

            end
            else begin

               next_state = WAIT;

            end
         end

         RETRY_CAL: begin

            next_state = WAIT;

         end

         DDR_ACCESS: begin

            if ( start_operation == 1'b1 ) begin

               next_state = DDR_ACCESS;

            end
            else begin

               next_state = IDLE;

            end
         end

         default : next_state = UNDEF;

      endcase
   end

   // 
   always_ff @(posedge pr_logic_clk_clk or negedge pr_logic_reset_reset_n) begin

      // Active low HW reset
      if (  pr_logic_reset_reset_n == 1'b0 ) begin

         clear_start_operation <= 1'b0; 
         start_recalibration <= 1'b0;
         start_traffic_generator <= 1'b0;
         busy <= 1'b0;
         reset_recal_counter <= 1'b0;

      end
      // Active high SW reset
      else if (  sw_reset == 1'b1 ) begin

         clear_start_operation <= 1'b0; 
         start_recalibration <= 1'b0;
         start_traffic_generator <= 1'b0;
         busy <= 1'b0;
         reset_recal_counter <= 1'b0;

      end
      else begin

         // default values
         clear_start_operation <= 1'b0; 
         start_recalibration <= 1'b0;
         start_traffic_generator <= 1'b0;
         busy <= 1'b0;
         reset_recal_counter <= 1'b0;

         unique case ( next_state )
         
            IDLE: begin

               if ( ( max_retry_cal_reached == 1'b1 ) &&  ( local_cal_fail == 1'b1 ) ) begin
                  // When start_operation field of pr_ctrl register is
                  // set through the PCIe interface, PR Logic starts
                  // the DDRAccess operation.  When operation is completed the
                  // start_operation field of pr_ctrl register is cleared.  In
                  // other words, after setting start_operation field of
                  // pr_ctrl register, a read back of the same register
                  // bit with a value of 1 indicates PR Logic is busy.
                  clear_start_operation <= 1'b1; 

               end
            end

            CALIBRATE: begin
               busy <= 1'b1;

               if ( ( max_retry_cal_reached == 1'b1 ) && ( local_cal_success == 1'b1 ) )  begin

                  reset_recal_counter <= 1'b1;

               end

            end

            WAIT: begin

               busy <= 1'b1;

            end


            RETRY_CAL: begin

               start_recalibration <= 1'b1;
               busy <= 1'b1;

            end
         
            DDR_ACCESS: begin

               busy <= 1'b1;
               start_traffic_generator <= 1'b1;

               if ( ( ddr_access_completed == 1'b1 ) && ( start_operation == 1'b1 ) ) begin

                  clear_start_operation <= 1'b1; 
                  start_traffic_generator <= 1'b0;

               end
            end

            default: begin

               clear_start_operation <= 1'b0; 
               start_recalibration <= 1'b0;
               start_traffic_generator <= 1'b0;
               busy <= 1'b0;
               reset_recal_counter <= 1'b0;

            end
         endcase
      end
   end

endmodule
