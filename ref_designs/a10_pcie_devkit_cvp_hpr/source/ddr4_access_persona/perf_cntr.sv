`timescale 1 ps / 1 ps
`default_nettype none

// This module is used to count number of PASS asserted by ddr_wr_rd module

module perf_cntr 
(
   input wire        pr_region_clk, 
   input wire        clr_io_reg,
   input wire        pass,
   output reg [31:0] performance_cntr,
   input wire        pr_logic_rst            
);


   always_ff @(posedge pr_region_clk or posedge pr_logic_rst) begin

      if ( pr_logic_rst == 1'b1  ) 
      begin
         performance_cntr <= 'b0;
      end
      else begin
         if ( clr_io_reg == 1'b1 ) begin
            performance_cntr <= 'b0;
         end
         else begin
            if ( pass == 1'b1 ) begin
               performance_cntr <= performance_cntr + 1;
            end
         end
      end
   end

endmodule
