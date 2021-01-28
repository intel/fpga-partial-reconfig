`timescale 1 ps / 1 ps
`default_nettype none

// Synchronize one signal originated from a different
// clock domain to the current clock domain.

module synchronizer #( parameter WIDTH = 1, parameter STAGES = 5 )
   (
      input wire             clk_in,arstn_in,
      input wire             clk_out,arstn_out,

      input wire [WIDTH-1:0] dat_in,
      output reg [WIDTH-1:0] dat_out  
   );

   // launch register
   reg [WIDTH-1:0]         d /* synthesis preserve */;
   always @(posedge clk_in or negedge arstn_in) begin
      if (!arstn_in) d <= 0;
      else d <= dat_in;
   end

   // capture registers
   reg [STAGES*WIDTH-1:0] c /* synthesis preserve */;
   always @(posedge clk_out or negedge arstn_out) begin
      if (!arstn_out) c <= 0;
      else c <= {c[(STAGES-1)*WIDTH-1:0],d};
   end

   assign dat_out = c[STAGES*WIDTH-1:(STAGES-1)*WIDTH];

endmodule
