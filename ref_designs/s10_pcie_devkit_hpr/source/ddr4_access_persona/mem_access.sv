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

// This module handles interactions with the traffic
// generator for DDRaccess persona

module mem_access 
(
   input wire pr_region_clk, 

   input wire clr_io_reg,
   input wire start_operation,
   input wire ddr_access_completed,
   output reg busy_reg,
   output reg clear_start_operation,
   output reg start_traffic_generator,
   input wire pr_logic_rst            
);


   ////////////////////////////////////////////////////////////////////////////
   //
   // State Machine Definitions
   typedef enum reg [1:0] 
   {
      IDLE,
      DDR_ACCESS,
      UNDEF      
   } states_definition_t;

   states_definition_t curr_state, next_state;
   //
   ////////////////////////////////////////////////////////////////////////////

   always_ff @(posedge pr_region_clk or posedge pr_logic_rst ) begin

      if ( pr_logic_rst == 1'b1 ) 
      begin
         curr_state <= IDLE;
      end
      else begin
         if( clr_io_reg == 1'b1 ) begin
            curr_state <= IDLE;
         end
         else begin
            curr_state <= next_state;
         end
      end
   end


   // Also check for overlapping case values, item duplicated or not found;
   // hence no default case!
   always_comb 
   begin
      // Default next_state assignment of type undefined 
      next_state = UNDEF;
      unique case ( curr_state )

         IDLE:
            begin

               if ( ( start_operation == 1'b1 ) && ( ddr_access_completed == 1'b0 )) begin

                  next_state = DDR_ACCESS;
               end
               else begin

                  next_state = IDLE;

               end
            end

         DDR_ACCESS:
            begin

               if ( ddr_access_completed == 1'b0 ) begin

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
   always_ff @(posedge pr_region_clk or posedge pr_logic_rst) begin
      if ( pr_logic_rst == 1'b1 ) begin
         clear_start_operation <= 1'b0; 
         start_traffic_generator <= 1'b0;
         busy_reg <= 1'b0;
      end
      else begin
         if ( clr_io_reg == 1'b1 ) begin
            clear_start_operation <= 1'b0; 
            start_traffic_generator <= 1'b0;
            busy_reg <= 1'b0;
         end 
         else begin
            // default values
            clear_start_operation <= 1'b0; 
            start_traffic_generator <= 1'b0;
            busy_reg <= 1'b0;

            unique case ( next_state )
               
               IDLE: begin

                     clear_start_operation <= 1'b1; 
                     busy_reg <= 1'b0;
                     
                  end

               
               DDR_ACCESS: begin
                     start_traffic_generator <= 1'b1;
                     busy_reg <= 1'b1;
                     if ( ( ddr_access_completed == 1'b1 ) ) begin
                        clear_start_operation <= 1'b1; 
                        start_traffic_generator <= 1'b0;
                     end
                  end

               default: begin

                     clear_start_operation <= 1'b0; 
                     start_traffic_generator <= 1'b0;

                  end
            endcase
         end
      end
   end

endmodule
