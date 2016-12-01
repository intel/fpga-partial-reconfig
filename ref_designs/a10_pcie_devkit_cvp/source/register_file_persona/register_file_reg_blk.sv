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

// This is the register block for RegisterFile persona

module register_file_reg_blk (
      input  wire         pr_logic_clk_clk,                 //       pr_logic_clk.clk
      input  wire         iopll_locked,

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

   localparam REGFILE_SIZE = 256;

   reg   [31:0]    pr_data;
   reg   [31:0]    pr_ctrl;

   reg   [31:0]    regfile [0:REGFILE_SIZE-1];
   reg   [31:0]    pr_logic_cra_readdata_reg;
   reg             pr_logic_cra_readdatavalid_reg;

   reg             local_reset;
   reg             local_reset_q;

   always_comb begin
      // Register at address 0x0 contains Persona Identity Value and it is
      // Read-Only
      pr_data  <= 32'h0000_00ce;
   end        


   // Register write control logic
   always_ff @(posedge pr_logic_clk_clk or negedge pr_logic_reset_reset_n)  begin


      if (  pr_logic_reset_reset_n == 1'b0 ) begin

         pr_ctrl <= '0;

         for ( int i = 0; i < 256; i++) begin

            regfile [i] <= 32'h0;

         end
      end
      else if ( local_reset_q == 1'b1 ) begin

         pr_ctrl <= '0;

         for ( int i = 0; i < 256; i++) begin

            regfile [i] <= 32'h0;

         end
      end
      else begin

         // Register Writes
         if (pr_logic_cra_write) begin

            // Limit to the REGFILE_SIZE segment of space
            if (~|pr_logic_cra_address[13:9]) begin

               if ( |pr_logic_cra_address[8:0] ) begin // Register at address 0x0 is Read-Only

                  // handling access to pr_ctrl.rest at byte address 0x4
                  if (pr_logic_cra_address[8:0] == 3'h4) begin
                     if (pr_logic_cra_byteenable[0])
                        pr_ctrl[7 : 0] <= pr_logic_cra_writedata[7:0];
                     
                     if (pr_logic_cra_byteenable[1])
                        pr_ctrl[15: 8] <= pr_logic_cra_writedata[15: 8];
                     
                     if (pr_logic_cra_byteenable[2])
                        pr_ctrl[23:16] <= pr_logic_cra_writedata[23:16];
                     
                     if (pr_logic_cra_byteenable[3])
                        pr_ctrl[31:24] <= pr_logic_cra_writedata[31:24];
                  end

                  // Updating Register File segment from byte address
                  // 0x100 up until and including 0x1FF
                  if (pr_logic_cra_address[8]) begin
                     if (pr_logic_cra_byteenable[0])
                        regfile[pr_logic_cra_address[7:2]][7 : 0] <= pr_logic_cra_writedata[7:0];
                     
                     if (pr_logic_cra_byteenable[1])
                        regfile[pr_logic_cra_address[7:2]][15: 8] <= pr_logic_cra_writedata[15: 8];
                     
                     if (pr_logic_cra_byteenable[2])
                        regfile[pr_logic_cra_address[7:2]][23:16] <= pr_logic_cra_writedata[23:16];
                     
                     if (pr_logic_cra_byteenable[3])
                        regfile[pr_logic_cra_address[7:2]][31:24] <= pr_logic_cra_writedata[31:24];
                  end
               end 
            end

         end
      end
   end

   // Register read control logic
   always_ff @(posedge pr_logic_clk_clk or negedge pr_logic_reset_reset_n)  begin

      if (  pr_logic_reset_reset_n == 1'b0 ) begin

         pr_logic_cra_readdata_reg <= 32'b0;
         pr_logic_cra_readdatavalid_reg <= 1'b0;
         pr_logic_cra_waitrequest <= 1'b1;

      end
      else begin

         // Register Reads
         if (pr_logic_cra_read) begin

            if (~|pr_logic_cra_address[13:9]) begin

               // handling access to pr_data.persona_version at byte address 0x0
               if (pr_logic_cra_address[8:0] == 3'h0) begin
                  pr_logic_cra_readdata_reg <= pr_data;
               end

               // handling access to pr_ctrl.rest at byte address 0x4
               else if (pr_logic_cra_address[8:0] == 3'h4) begin
                  pr_logic_cra_readdata_reg <= pr_ctrl;
               end

               // Updating Register File segment from byte address
               // 0x100 up until and including 0x1FF
               else if (pr_logic_cra_address[8]) begin
                  // select value based on dword address
                  pr_logic_cra_readdata_reg <= regfile[pr_logic_cra_address[7:2]];
               end
               else begin
                  // for the rest of the registers output constant
                  pr_logic_cra_readdata_reg <= 32'heeee_ffff;
               end
            end
            else begin
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

   // local_reset generation logic
   always_ff @(posedge pr_logic_clk_clk or negedge pr_logic_reset_reset_n)  begin

      if (  pr_logic_reset_reset_n == 1'b0 ) begin

         local_reset <= 1'b0;
         local_reset_q <= 1'b0;

      end
      else begin

         local_reset <= pr_ctrl[0]; // pr_ctrl.reset 
         local_reset_q <= ~local_reset && pr_ctrl[0]; // creating a active high pulse for local reset

      end

   end
endmodule
