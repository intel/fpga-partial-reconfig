`timescale 1 ps / 1 ps
`default_nettype none

// This is a Linear Feedback Shift Register that generates 32-bit pseudo-random data

module lfsr 
   (
      input wire         clk,
      input wire         rst,
      input wire         load_seed,
      input wire  [31:0] seed,
      output wire [31:0] out
   );

   reg [31:0] myreg;

   // nice looking max period polys selected from
   // the internet
   reg [31:0] poly;
   wire [31:0] feedback;
   assign feedback = {32{myreg[31]}} & poly;

   // the inverter on the LSB causes 000... to be a 
   // sequence member rather than the frozen state
   always_ff @(posedge clk or posedge rst) begin
      if ( rst==1'b1 ) begin
         poly <= 32'h800007c3; 
         myreg <= 0;
      end
      else begin
         if(load_seed == 1'b1) begin
            poly <= seed;
         end
         myreg <= ((myreg ^ feedback) << 1) | !myreg[31];
      end
   end

   assign out = myreg;

endmodule

