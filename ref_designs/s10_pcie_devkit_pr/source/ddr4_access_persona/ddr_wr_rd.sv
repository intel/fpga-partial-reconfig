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

// DDR4 write and read
//
// This module takes a target address and target data data as inputs, writes
// the target data at the target address. This is done through the series of signals with the suffix
// "emif_avmm", which uses avalon memory mapped interface to the EMIF. After the write is complete,
// the module then reads back data stored in DDR4, using the same avalon interface, from the target address 
// and compares the read data against the target data that was written. If the read data matches the written data,
// the module reports a PASS, otherwise it reports a FAIL. 

module ddr_wr_rd 
   (
      input wire         pr_region_clk, 
      input wire         pr_logic_rst, 
      input wire         clr_io_reg,
      input wire         start_ddr_wr_rd,

      input wire [24:0]   target_address,
      input wire [127:0]  target_data,
      input wire         emif_avmm_waitrequest,
      input wire [127:0] emif_avmm_readdata,
      input wire         emif_avmm_readdatavalid,
      output reg [6:0]   emif_avmm_burstcount,
      output reg [127:0] emif_avmm_writedata,
      output reg [24:0]  emif_avmm_address,
      output reg         emif_avmm_write,
      output reg         emif_avmm_read,
      output reg [15:0]  emif_avmm_byteenable,
      // Output Results
      output reg         pass,
      output reg         fail     
   );

   ////////////////////////////////////////////////////////////////////////////
   //
   // State Machine Definitions
   typedef enum reg [2:0] 
   {
      IDLE,
      WRITE,
      WAIT_WRITE_DONE,
      READ,
      WAIT_READ_ACCEPTED,
      WAIT_READ_DONE,
      DATA_VERIFICATION,
      UNDEF
   } states_definition_t;

   states_definition_t curr_state, next_state;
   //
   ////////////////////////////////////////////////////////////////////////////
   
   reg [127:0]         reference_data;
   reg [24:0]          reference_addr;

   // The data bus does not need to be reset. Instead, constantly capture reference data for
   // comparison
   always_ff @(posedge pr_region_clk) begin

      emif_avmm_writedata    <= target_data;
      
      if ( next_state == WRITE ) begin
         
         reference_data <= target_data;
         reference_addr <= target_address;
         
      end
   end
   assign emif_avmm_address      = reference_addr;   // Use the same address when we read and write
   assign emif_avmm_byteenable   = {16{1'b1}};       // set all bits to 1
   assign emif_avmm_burstcount   = 7'b0000001;


   always_ff @(posedge pr_region_clk or posedge pr_logic_rst ) begin

      if ( pr_logic_rst == 1'b1 ) begin

         curr_state <= IDLE;
      end
      else begin
         if(clr_io_reg == 1'b1) begin
            curr_state <= IDLE;
         end
         else begin
            curr_state <= next_state;
         end
      end
   end

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
            if ( emif_avmm_waitrequest == 1'b1 ) begin
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
            if ( emif_avmm_waitrequest == 1'b1 ) begin
               next_state = WAIT_READ_ACCEPTED;
            end
            else begin
               next_state = WAIT_READ_DONE;
            end
         end

         WAIT_READ_DONE: begin
            if ( emif_avmm_readdatavalid == 1'b1 ) begin
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


   always_ff @(posedge pr_region_clk or posedge pr_logic_rst ) begin

      if ( pr_logic_rst == 1'b1) begin
         emif_avmm_write <= 1'b0;
         emif_avmm_read <= 1'b0; 
         pass <= 1'b0;
         fail <= 1'b0;
      end
      else begin
         if ( clr_io_reg == 1'b1 ) begin 
            // Default values
            emif_avmm_write <= 1'b0;
            emif_avmm_read <= 1'b0; 
            pass <= 1'b0;
            fail <= 1'b0;
         end 
         else begin
            emif_avmm_write <= 1'b0;
            emif_avmm_read <= 1'b0; 
            pass <= 1'b0;
            fail <= 1'b0;
            unique case ( next_state )
               IDLE: begin
               end

               WRITE: begin
                  emif_avmm_write  <= 1'b1;
               end

               WAIT_WRITE_DONE: begin                    
                  if ( emif_avmm_waitrequest == 1'b1 ) begin
                     emif_avmm_write <= 1'b1;
                  end
               end

               READ: begin
                  emif_avmm_read   <= 1'b1;
               end

               WAIT_READ_ACCEPTED: begin
                  if ( emif_avmm_waitrequest == 1'b1 ) begin
                     emif_avmm_read <= 1'b1;
                  end
               end

               WAIT_READ_DONE: begin
               end

               DATA_VERIFICATION: begin
                  if ( emif_avmm_readdatavalid == 1'b1 ) begin
                     if (emif_avmm_readdata == reference_data) begin
                        pass <= 1'b1;
                     end
                     else begin
                        fail <= 1'b1;
                     end
                  end
               end

               default: begin
                  emif_avmm_write <= 1'b0;
                  emif_avmm_read <= 1'b0; 
                  pass <= 1'b0;
                  fail <= 1'b0;

               end
            endcase
         end
      end 
   end
endmodule
