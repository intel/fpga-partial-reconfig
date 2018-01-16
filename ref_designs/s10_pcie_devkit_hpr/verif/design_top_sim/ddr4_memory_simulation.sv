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

module ddr4_memory_simulation
(
 input wire clk,
 input wire rst_n,
 output reg   avmm_waitrequest,
 output reg  [127:0] avmm_readdata,
 output reg         avmm_readdatavalid,
 input  wire [6:0]   avmm_burstcount,
 input  wire [127:0] avmm_writedata,
 input  wire [24:0]  avmm_address,
 input  wire         avmm_write,
 input  wire         avmm_read,
 input  wire [15:0]  avmm_byteenable
 );

typedef enum {
   idle_indx,
   read_indx,
   write_indx

} states_indx;

// encoding one-hot states
typedef enum logic [2:0] {
   IDLE       = 3'b1 << idle_indx,
   READ       = 3'b1 << read_indx,
   WRITE      = 3'b1 << write_indx,
   UNDEF      = 'x
} states_definition;

states_definition curr_state,
   next_state;
reg [511:0] memory ;
assign avmm_waitrequest = 1'b0; 
always_ff @(posedge clk or negedge rst_n) begin
   if (rst_n == 1'b0) begin
      avmm_readdata <= 512'b0;
      curr_state <= IDLE;
   end else begin
      curr_state <= next_state;
      avmm_readdatavalid <= 1'b0;
      avmm_readdata <= avmm_readdata;
      if (curr_state == READ) begin
         avmm_readdata <= memory;
         avmm_readdatavalid <= 1'b1;
      end
      if (curr_state == WRITE) begin
         memory<= avmm_writedata;
      end
   end
end
always_comb begin
   next_state = UNDEF;
   unique case (curr_state)
      IDLE: begin
            if (avmm_read == 1'b1 && avmm_write == 1'b0) begin
               next_state = READ;
            end else if (avmm_read == 1'b0 && avmm_write == 1'b1) begin
               next_state = WRITE;
            end else if (avmm_read == 1'b1 && avmm_write == 1'b1) begin
               next_state = UNDEF;
            end else if (avmm_read == 1'b0 && avmm_write == 1'b0) begin
               next_state = IDLE;
            end else begin
               next_state = UNDEF;
            end
         end

      READ: begin
             if (avmm_read == 1'b1 && avmm_write == 1'b0) begin
               next_state = READ;
            end else if (avmm_read == 1'b0 && avmm_write == 1'b1) begin
               next_state = WRITE;
            end else if (avmm_read == 1'b1 && avmm_write == 1'b1) begin
               next_state = UNDEF;
            end else if (avmm_read == 1'b0 && avmm_write == 1'b0) begin
               next_state = IDLE;
            end else begin
               next_state = UNDEF;
            end
         end

      WRITE: begin
             if (avmm_read == 1'b1 && avmm_write == 1'b0) begin
               next_state = READ;
            end else if (avmm_read == 1'b0 && avmm_write == 1'b1) begin
               next_state = WRITE;
            end else if (avmm_read == 1'b1 && avmm_write == 1'b1) begin
               next_state = UNDEF;
            end else if (avmm_read == 1'b0 && avmm_write == 1'b0) begin
               next_state = IDLE;
            end else begin
               next_state = UNDEF;
            end
         end
      default: next_state = UNDEF;
   endcase
end

endmodule
