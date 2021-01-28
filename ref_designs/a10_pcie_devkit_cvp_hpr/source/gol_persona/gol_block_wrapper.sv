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
