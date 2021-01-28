`timescale 1 ps / 1 ps
`default_nettype none

module block 
(
   input wire           clk,
   input wire           clk_en,
   input wire           init, 
   input wire           rst,
   input wire  [63:0]   board_initial,
   output wire [63:0]   board
);

   localparam  NUM_ROWS=8;
   localparam  NUM_COLS=8;
   localparam  NUM_BITS=64;

   wire [(NUM_COLS * NUM_ROWS)-1:0] gol_board;
   wire [7:0] neighbor_wire[0 : (NUM_ROWS*NUM_COLS) - 1];

   assign board = gol_board;
   generate 
      genvar i;
      genvar j;
      for (i = 0; i < NUM_ROWS ;i = i + 1) begin: COL
         for (j = 0; j < NUM_COLS; j = j + 1)begin: ROW
      
                  assign neighbor_wire[(i + (j * NUM_ROWS))][0] =  gol_board[((((i+1) + NUM_ROWS) % NUM_ROWS) + (j * NUM_ROWS))];
                  assign neighbor_wire[(i + (j * NUM_ROWS))][1] =  gol_board[((((i-1) + NUM_ROWS) % NUM_ROWS) + (j * NUM_ROWS))];
                  assign neighbor_wire[(i + (j * NUM_ROWS))][2] =  gol_board[(i + ((((j+1) + NUM_COLS) % NUM_COLS) * NUM_ROWS))];
                  assign neighbor_wire[(i + (j * NUM_ROWS))][3] =  gol_board[(i + ((((j-1) + NUM_COLS) % NUM_COLS) * NUM_ROWS))];
                  assign neighbor_wire[(i + (j * NUM_ROWS))][4] =  gol_board[(((i+1) + NUM_ROWS) % NUM_ROWS) + ((((j+1) + NUM_COLS) % NUM_COLS) * NUM_ROWS)];
                  assign neighbor_wire[(i + (j * NUM_ROWS))][5] =  gol_board[(((i+1) + NUM_ROWS) % NUM_ROWS) + ((((j-1) + NUM_COLS) % NUM_COLS) * NUM_ROWS)];
                  assign neighbor_wire[(i + (j * NUM_ROWS))][6] =  gol_board[(((i-1) + NUM_ROWS) % NUM_ROWS) + ((((j+1) + NUM_COLS) % NUM_COLS) * NUM_ROWS)];
                  assign neighbor_wire[(i + (j * NUM_ROWS))][7] =  gol_board[(((i-1) + NUM_ROWS) % NUM_ROWS) + ((((j-1) + NUM_COLS) % NUM_COLS) * NUM_ROWS)];        
            gol_cell u_gol_cell(  
                  .clk           ( clk ),
                  .clk_en        ( clk_en ),
                  .init          ( init ),
                  .rst           ( rst ),
                  .neighbors     ( neighbor_wire[(i + (j*NUM_ROWS))][7:0] ),
                  .starting_val  ( board_initial[(i + (j*NUM_ROWS))] ),
                  .status        ( gol_board[(i + (j*NUM_ROWS))] )
               );
         end 
      end 
   endgenerate
endmodule