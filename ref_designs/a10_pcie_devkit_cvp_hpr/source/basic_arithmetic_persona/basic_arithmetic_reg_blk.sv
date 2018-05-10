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

// This is the register block for BasicArithmetic persona where operands are
// provided through AVMM interface and result is created by basic_arithmetic
// moduel.  The result resgister is then can be accessed through PCIe
// interface.

module basic_arithmetic_reg_blk 
   #( parameter REG_FILE_IO_SIZE = 8 ) 
   (
      // Register Field input
      input wire [31:0]  result,
      // Register Field outputs
      output reg [31:0]  pr_operand,
      output reg [31:0]  increment,
      //clock
      input wire         clk, 
      output reg         clr_io_reg, 
      input wire         pr_logic_rst, 
      //Persona identification register, used by host in host program
      output wire [31:0] persona_id, 
      //Host control register, used for control signals.
      input wire [31:0]  host_cntrl_register, 
      // 8 registers for host -> PR logic communication
      input wire [31:0]  host_pr [0:REG_FILE_IO_SIZE-1],
      // 8 Registers for PR logic -> host communication
      output wire [31:0] pr_host [0:REG_FILE_IO_SIZE-1]
   );
   reg [31:0]          pr_region_avmm_readdata_reg;
   reg                 pr_region_avmm_readdatavalid_reg;
   reg                 clr_io_reg_q;
   reg                 clr_io_reg;
   reg [31:0]          unsafe_counter;
   reg [31:0]          safe_counter;

    assign persona_id =32'h000000d2;
    assign pr_host[0] = result;
    assign pr_host[1] = unsafe_counter;
    assign pr_host[2] = safe_counter;
    assign pr_host[3] = '0;
    assign pr_host[4] = '0;
    assign pr_host[5] = '0;
    assign pr_host[6] = '0;
    assign pr_host[7] = '0;

    // Create a safe counter
    always_ff @( posedge clk ) begin
        if ( pr_logic_rst == 1'b1 ) begin
            safe_counter <= '0;
        end
        else begin
            safe_counter <= safe_counter + 1;
        end
    end

    // Create an unsafe counter for PR, one that is not reset
    // Use an always block as opposed to always_ff to work
    // with an initial block
    always @( posedge clk ) begin
        unsafe_counter <= unsafe_counter + 1;
    end
    // synthesis translate_off 
    initial begin
        unsafe_counter <= '0;
    end
    // synthesis translate_on


    // Register write control logic
      always_ff @( posedge clk ) begin
         if (  pr_logic_rst == 1'b1 ) begin
            pr_operand <= '0;
            increment  <= '0;
         end
         else begin            
            pr_operand <= host_pr[0][31:0];
            increment  <= host_pr[1][31:0];
         end
      end

      // Register clear control logic
      always_ff @( posedge clk ) begin
         if (  pr_logic_rst == 1'b1  ) begin
            clr_io_reg   <= 1'b0;
            clr_io_reg_q <= 1'b0;
         end
         else begin
            clr_io_reg_q <= host_cntrl_register[0];
            clr_io_reg   <= (~host_cntrl_register[0] & clr_io_reg_q);
         end
      end 
endmodule
