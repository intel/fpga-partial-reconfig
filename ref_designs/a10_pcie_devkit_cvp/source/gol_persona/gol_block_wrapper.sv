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

module gol_block_wrapper 
(
   input wire           clk,
   input wire           clk_en,
   input wire           init, 
   input wire           rst,
   input wire  [63:0]   board_initial,
   output wire [63:0]   board_final
);
 
   localparam  NUM_BITS=64;
   localparam  NUM_BOARDS = 1;
   wire  [NUM_BITS-1:0]       end_board   [0  : NUM_BOARDS-1];
   reg   [NUM_BITS-1:0]       board_final_reg[0  : NUM_BOARDS-1];

   assign board_final = board_final_reg[NUM_BOARDS-1][63:0];
   generate
      genvar i;
   
      for (i = 0; i < NUM_BOARDS ;i = i + 1) begin: BOARDS
         always_ff @(posedge clk or posedge rst) begin
            if (  rst == 1'b1 ) begin
               board_final_reg[i] <= 0;
            end
            else begin
               if(init == 1'b1 ) begin
                  board_final_reg[i] <= 0;
               end
               else begin
                  if( i == 0) begin
                     board_final_reg[i][63:0] <= end_board[i][63:0];
                  end
                  else begin
                     board_final_reg[i][63:0] <= end_board[i][63:0] & board_final_reg[i-1][63:0];
                  end
               end
            end
         end

         block u_block
         (
            .clk           ( clk ),
            .clk_en        ( clk_en ),
            .init          ( init ),
            .rst           ( rst ),
            .board_initial ( board_initial ),
            .board         ( end_board[i] )
         ); 
      end
   endgenerate
endmodule
