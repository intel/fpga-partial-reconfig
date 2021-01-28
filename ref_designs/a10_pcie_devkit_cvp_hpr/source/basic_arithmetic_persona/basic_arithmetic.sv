`timescale 1 ps / 1 ps
`default_nettype none
// Basic Arithmetic
// 
// This module conducts the arithmetic operation on the pr_operand and
// increment operand it receives and produces the result.

module basic_arithmetic 
   (
      input wire        pr_region_clk, 
      output reg [31:0] result,
      input wire [31:0] pr_operand,
      input wire [31:0] increment,
      input wire        pr_logic_rst   
   );
    always_ff @(posedge pr_region_clk) begin
        if ( pr_logic_rst ) begin
            result <= 'b0;
        end
        else begin
            result <= pr_operand + increment;
        end
    end
endmodule
