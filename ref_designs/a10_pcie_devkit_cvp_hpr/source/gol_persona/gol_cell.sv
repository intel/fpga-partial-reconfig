`timescale 1 ps / 1 ps
`default_nettype none



module gol_cell
(
   input wire        clk,
   input wire        rst,
   input wire        clk_en,
   input wire        init,
   input wire [7:0]  neighbors,
   input wire        starting_val,
   output wire       status
);
   wire [3:0] num_ones;
   wire my_status_local;
   logic my_status_next;
   logic my_status_reg;
   assign status = my_status_reg;
   assign my_status_local = my_status_reg; 
   assign num_ones = neighbors[7] + neighbors[6] + neighbors[5] + neighbors[4] + neighbors[3] + neighbors[2] + neighbors[1] + neighbors[0];

   always_ff @(posedge clk or posedge rst ) begin
      if(rst == 1'b1) begin
         my_status_reg <= 1'b0;
      end
      else begin
         if(init == 1'b1) begin
            my_status_reg <= starting_val;
         end 
         else if (clk_en == 1'b1)begin
            my_status_reg <= my_status_next;
         end   
         else begin
            my_status_reg <= my_status_reg;
         end
      end
   end

   always_comb begin
      if(my_status_local == 1'b0) begin
         if (num_ones == 4'd3) begin
            my_status_next = 1'b1;
         end
         else begin
            my_status_next = 1'b0;
         end
      end
      else if(my_status_local == 1'b1) begin
         if(num_ones == 4'd2 || num_ones == 4'd3) begin
            my_status_next =1'b1;
         end
         else begin
            my_status_next =1'b0;
         end
      end
   end
endmodule
