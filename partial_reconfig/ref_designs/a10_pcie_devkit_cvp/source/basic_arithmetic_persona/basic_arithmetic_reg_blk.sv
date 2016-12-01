// Copyright (c) 2001-2016 Intel Corporation
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
// provided through PCIe interface and result is created by basic_arithmetic
// moduel.  The result resgister is then can be accessed through PCIe
// interface.

module basic_arithmetic_reg_blk (
      input  wire         pr_logic_clk_clk,                 //       pr_logic_clk.clk
      input  wire         iopll_locked,

      // Register Field input
      input  wire [31:0]  result,

      // Register Field outputs
      output reg  [30:0]  pr_operand,
      output reg  [30:0]  increment,

      // PCIe interface
      output reg          pr_logic_cra_waitrequest,         //       pr_logic_cra.waitrequest
      output wire [31:0]  pr_logic_cra_readdata,            //                   .readdata
      output wire         pr_logic_cra_readdatavalid,       //                   .readdatavalid
      input  wire [0:0]   pr_logic_cra_burstcount,          //                   .burstcount
      input  wire [31:0]  pr_logic_cra_writedata,           //                   .writedata
      input  wire [13:0]  pr_logic_cra_address,             //                   .address
      input  wire         pr_logic_cra_write,               //                   .write
      input  wire         pr_logic_cra_read,                //                   .read
      input  wire [3:0]   pr_logic_cra_byteenable,          //                   .byteenable
      input  wire         pr_logic_cra_debugaccess,         //                   .debugaccess
      input  wire         pr_logic_reset_reset_n            //     pr_logic_reset.reset_n
   );


   reg   [31:0]    regfile [0:3];
   reg   [31:0]    pr_logic_cra_readdata_reg;
   reg             pr_logic_cra_readdatavalid_reg;


   // Register write control logic
   always_ff @(posedge pr_logic_clk_clk or negedge pr_logic_reset_reset_n) 
   begin


      if (  pr_logic_reset_reset_n == 1'b0 )
      begin

         // Register at address 0x0 contains Persona Identity Value
         regfile [0] <= 32'h0000_00d2;

         regfile [1] <= '0;
         regfile [2] <= '0;
         regfile [3] <= '0;

      end

      else
      begin

         regfile [0] <= 32'h0000_00d2;
         regfile [3] <= result;

         // Register Writes
         if (pr_logic_cra_write)
         begin

            // Limit to the 4x32 segment of space
            if (~|pr_logic_cra_address[13:4])
            begin

               if ( |pr_logic_cra_address[3:0] ) // Register at address 0x0 is Read-Only
               begin
                  if (pr_logic_cra_byteenable[0])
                     regfile[pr_logic_cra_address[3:2]][7 : 0] <= pr_logic_cra_writedata[7:0];
                  
                  if (pr_logic_cra_byteenable[1])
                     regfile[pr_logic_cra_address[3:2]][15: 8] <= pr_logic_cra_writedata[15: 8];
                  
                  if (pr_logic_cra_byteenable[2])
                     regfile[pr_logic_cra_address[3:2]][23:16] <= pr_logic_cra_writedata[23:16];
                  
                  if (pr_logic_cra_byteenable[3])
                     regfile[pr_logic_cra_address[3:2]][31:24] <= pr_logic_cra_writedata[31:24];
               end 
            end

         end
      end
   end

   // Register read control logic
   always_ff @(posedge pr_logic_clk_clk or negedge pr_logic_reset_reset_n) 
   begin

      if (  pr_logic_reset_reset_n == 1'b0 )
      begin

         pr_logic_cra_readdata_reg <= 32'b0;
         pr_logic_cra_readdatavalid_reg <= 1'b0;
         pr_logic_cra_waitrequest <= 1'b1;

      end
      else
      begin

         // Register Reads
         if (pr_logic_cra_read)
         begin

            if (~|pr_logic_cra_address[13:4])
            begin
               // select value based on dword address
               pr_logic_cra_readdata_reg <= regfile[pr_logic_cra_address[3:2]];
            end
            else
            begin
               // for the rest of the registers output constant
               pr_logic_cra_readdata_reg <= 32'heeee_ffff;
            end

         end

         // assert readdatavalid immediately when we receive a 
         // read request
         pr_logic_cra_readdatavalid_reg <= pr_logic_cra_read;

         // never need to assert waitrequest (except during reset
         // condition)
         pr_logic_cra_waitrequest <= 1'b0;

      end

   end 
   
   // Configuration Register Read Data output assignments 
   assign pr_logic_cra_readdata        = pr_logic_cra_readdata_reg;
   assign pr_logic_cra_readdatavalid   = pr_logic_cra_readdatavalid_reg;

   always_comb
   begin
      pr_operand = regfile[1][30:0];
      increment  = regfile[2][30:0];
   end

endmodule
