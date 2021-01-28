`timescale 1 ps / 1 ps
`default_nettype none
//This module acts as a countdown timer until user mode is ready on powerup.
//Using the internal oscillator of 50 MHz, with a countdown for 830 us as defined
//in the data sheet, upon power up, pll reset is driven high until we reach the
//designated time. 
module tcD2UM 
   (
      input wire  ref_clk,
      output wire pll_reset
   );

   // Local Signals
   localparam RST_CNTR_WIDTH_MSB = 17;
   localparam REF_CLOCK_SPEED_MHZ = 50;
   localparam TCD2UM_US = 830;
   localparam CYCLES = REF_CLOCK_SPEED_MHZ * TCD2UM_US;

   reg [RST_CNTR_WIDTH_MSB-1:0] rst_counter;

   assign pll_reset = (rst_counter != CYCLES) ? 1'b1 : 1'b0;

   always_ff @(posedge ref_clk) begin

      if(rst_counter != CYCLES) begin
         rst_counter <= rst_counter + 1'b1;
      end 
      else begin
         rst_counter <= CYCLES;
      end
      
   end

endmodule
