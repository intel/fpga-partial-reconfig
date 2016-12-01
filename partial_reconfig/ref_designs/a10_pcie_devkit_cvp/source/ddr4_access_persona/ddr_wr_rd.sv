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

// DDR4 write and read
//
// This module takes a target address and target data data as inputs, writes
// the target data at the target address. This is done through the series of signals with the suffix
// "pr_logic_mm", which uses avalon memory mapped interface to the EMIF. After the write is complete,
// the module then reads back data stored in DDR4, using the same avalon interface, from the target address 
// and compares the read data against the target data that was written. If the read data matches the written data,
// the module reports a PASS, otherwise it reports a FAIL. 

module ddr_wr_rd (
      input   wire          pr_logic_clk_clk,            //  pr_logic_clk.clk
      input   wire          pr_logic_reset_reset_n,      //  pr_logic_reset.reset_n
      input   wire          sw_reset,
      input   wire          local_cal_success,
      input   wire          start_ddr_wr_rd,

      input   reg  [30:0]   target_address,
      input   reg  [511:0]  target_data,
      ////////////////////////////////////////////////////////////////////////////
      //
      // Avalon Memory Mapped Interface
      input   wire          pr_logic_mm_waitrequest,    //  pr_logic_mm_.waitrequest
      input   wire [511:0]  pr_logic_mm_readdata,       //              .readdata
      input   wire          pr_logic_mm_readdatavalid,  //              .readdatavalid
      output  reg  [4:0]    pr_logic_mm_burstcount,     //              .burstcount
      output  reg  [511:0]  pr_logic_mm_writedata,      //              .writedata
      output  reg  [30:0]   pr_logic_mm_address,        //              .address
      output  reg           pr_logic_mm_write,          //              .write
      output  reg           pr_logic_mm_read,           //              .read
      output  reg  [63:0]   pr_logic_mm_byteenable,     //              .byteenable
      output  reg           pr_logic_mm_debugaccess,    //              .debugaccess
      //
      ///////////////////////////////////////////////////////////////////////////

      // Output Results
      output reg  pass,
      output reg  fail,
      output reg  ddr_access_completed
   );

   ////////////////////////////////////////////////////////////////////////////
   //
   // State Machien Definitions
   // using enum to create indices for one-hot encoding
   typedef enum {
      idle_index,
      write_index,
      wait_write_done_index,
      read_index,
      wait_read_accepted_index,
      wait_read_done_index,
      data_verification
   } states_indx;
   // encoding one-hot states
   typedef enum logic [6:0] {
      IDLE                = 7'b1 << idle_index,
      WRITE               = 7'b1 << write_index,
      WAIT_WRITE_DONE     = 7'b1 << wait_write_done_index,
      READ                = 7'b1 << read_index,
      WAIT_READ_ACCEPTED  = 7'b1 << wait_read_accepted_index,
      WAIT_READ_DONE      = 7'b1 << wait_read_done_index,
      DATA_VERIFICATION   = 7'b1 << data_verification,
      UNDEF               = 'x
   } states_definition;

   states_definition curr_state, next_state;
   //
   ////////////////////////////////////////////////////////////////////////////
   
   reg [511:0] reference_data;
   reg [30:0]  reference_addr;

   always_comb begin

      ddr_access_completed = pass | fail;
      pr_logic_mm_debugaccess = 1'b0;

   end

   // The data bus does not need to be reset. Instead, constantly capture reference data for
   // comparison
   always_ff @(posedge pr_logic_clk_clk) begin

      pr_logic_mm_writedata    <= target_data;
      
      if ( next_state == WRITE ) begin
      
         reference_data <= target_data;
         reference_addr <= target_address;
      
      end
   end

   ////////////////////////////////////////////////////////////////////////////
   // Assigning the following signals as constants
   ////////////////////////////////////////////////////////////////////////////
   assign pr_logic_mm_address      = reference_addr;   // Use the same address when we read and write
   assign pr_logic_mm_byteenable   = '1;               // set all bits to 1
   assign pr_logic_mm_burstcount   = 5'b1;

   ////////////////////////////////////////////////////////////////////////////


   always_ff @(posedge pr_logic_clk_clk or negedge pr_logic_reset_reset_n) begin

      // Active low HW reset
      if (  pr_logic_reset_reset_n == 1'b0 ) begin

         curr_state <= IDLE;

      end
      // Active high SW reset
      else if ( sw_reset == 1'b1 ) begin

         curr_state <= IDLE;

      end
      else begin

         curr_state <= next_state;

      end
   end

   // Check for overlapping case values, item duplicated or not found;
   // hence no default case!
   always_comb
   begin

      // Default next_state assignment of type undefined 
      next_state = UNDEF;

      unique case ( curr_state )

         IDLE: begin

            if ( start_ddr_wr_rd == 1'b1 ) begin

               next_state = WRITE;

            end
            else begin

               next_state = IDLE;

            end
         end

         WRITE: begin

            next_state = WAIT_WRITE_DONE;

         end

         WAIT_WRITE_DONE: begin

            if ( pr_logic_mm_waitrequest == 1'b1 ) begin

               next_state = WAIT_WRITE_DONE;

            end
            else begin

               next_state = READ;

            end
         end

         READ: begin

            next_state = WAIT_READ_ACCEPTED;

         end

         WAIT_READ_ACCEPTED: begin

            if ( pr_logic_mm_waitrequest == 1'b1 ) begin

               next_state = WAIT_READ_ACCEPTED;
            end
            else begin

               next_state = WAIT_READ_DONE;

            end
         end

         WAIT_READ_DONE: begin

            if ( pr_logic_mm_readdatavalid == 1'b1 ) begin

               next_state = DATA_VERIFICATION;

            end
            else begin

               next_state = WAIT_READ_DONE;

            end
         end

         DATA_VERIFICATION: begin

            if ( pass | fail ) begin

               next_state = IDLE;

            end
            else begin

               next_state = DATA_VERIFICATION;

            end
         end

         default: begin

            next_state = UNDEF;

         end
      endcase
   end


   always_ff @(posedge pr_logic_clk_clk or negedge pr_logic_reset_reset_n) begin

      // Active low HW reset
      if ( pr_logic_reset_reset_n == 1'b0 ) begin

         pr_logic_mm_write <= 1'b0;
         pr_logic_mm_read <= 1'b0; 
         pass <= 1'b0;
         fail <= 1'b0;

      end
      // Active high SW reset
      else if ( sw_reset == 1'b1 ) begin

         pr_logic_mm_write <= 1'b0;
         pr_logic_mm_read <= 1'b0; 
         pass <= 1'b0;
         fail <= 1'b0;

      end 
      else begin

         // Default values
         pr_logic_mm_write <= 1'b0;
         pr_logic_mm_read <= 1'b0; 
         pass <= 1'b0;
         fail <= 1'b0;

         unique case ( next_state )

            IDLE: begin

            end

            WRITE: begin

               pr_logic_mm_write  <= 1'b1;

            end

            WAIT_WRITE_DONE: begin
            
               if ( pr_logic_mm_waitrequest == 1'b1 ) begin

                  pr_logic_mm_write <= 1'b1;

               end
            end

            READ: begin

               pr_logic_mm_read   <= 1'b1;

            end

            WAIT_READ_ACCEPTED: begin

               if ( pr_logic_mm_waitrequest == 1'b1 ) begin

                  pr_logic_mm_read <= 1'b1;

               end
            end

            WAIT_READ_DONE: begin

            end
            
            DATA_VERIFICATION: begin

               if ( pr_logic_mm_readdatavalid == 1'b1 ) begin
                  if (pr_logic_mm_readdata == reference_data) begin

                     pass <= 1'b1;

                  end
                  else begin

                     fail <= 1'b1;

                  end
               end
            end

            default: begin

               pr_logic_mm_write <= 1'b0;
               pr_logic_mm_read <= 1'b0; 
               pass <= 1'b0;
               fail <= 1'b0;

            end
         endcase
      end
   end
endmodule
