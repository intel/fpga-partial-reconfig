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

// This is the register block for DDRaccess persona
// The register block is where PCIe Could access registers

module reg_blk (
      input  wire         pr_logic_clk_clk,                 //       pr_logic_clk.clk

      // Register Field inputs
      input  wire [3:0]   pr_op_err,
      input  wire         local_cal_success,
      input  wire         local_cal_fail,
      input  wire         iopll_locked,
      input  wire [31:0]  performance_cntr,
      input  wire         ddr_access_completed,
      input  wire         clear_start_operation,

      // Register Field outputs
      // PR_CTRL
      output reg  [1:0]   mode,
      output reg          start_operation,
      output reg          sw_reset,
      output reg          emif_reset,
      output reg          load_seed,
      output reg  [7:0]   limit,
      // PR_MEM_ADDR
      output reg  [31:0]  mem_addr,
      output reg          post_wr_pulse,

      // PR_RANDOM_DATA
      output reg  [31:0]  seed,

      // PCIe interface
      output reg          pr_logic_cra_waitrequest,         //       pr_logic_cra.waitrequest
      output reg  [31:0]  pr_logic_cra_readdata,            //                   .readdata
      output reg          pr_logic_cra_readdatavalid,       //                   .readdatavalid
      input  wire [0:0]   pr_logic_cra_burstcount,          //                   .burstcount
      input  wire [31:0]  pr_logic_cra_writedata,           //                   .writedata
      input  wire [13:0]  pr_logic_cra_address,             //                   .address
      input  wire         pr_logic_cra_write,               //                   .write
      input  wire         pr_logic_cra_read,                //                   .read
      input  wire [3:0]   pr_logic_cra_byteenable,          //                   .byteenable
      input  wire         pr_logic_cra_debugaccess,         //                   .debugaccess
      input  wire         pr_logic_reset_reset_n            //     pr_logic_reset.reset_n
   );


   // The following is a dummy register file with primary intention of
   // testing board setup
   reg   [31:0]    regfile [0:7];
   reg   [31:0]    pr_logic_cra_readdata_reg;
   reg             pr_logic_cra_readdatavalid_reg;

   reg             sw_reset_d;

   // Register write control logic
   always @(posedge pr_logic_clk_clk or negedge pr_logic_reset_reset_n)  begin

      if (  pr_logic_reset_reset_n == 1'b0 ) begin

         // Register file initial reset values
         regfile[0] <= 32'hace0_beef;
         regfile[1] <= 32'h0;
         regfile[2] <= 32'h0;
         regfile[3] <= 32'hbee3_beef;
         regfile[4] <= 32'hcab4_beef;
         regfile[5] <= 32'hdab5_beef;
         regfile[6] <= 32'hdad6_beef;
         regfile[7] <= 32'hebb7_beef;

         post_wr_pulse <= 1'b0;

      end
      else begin

         // Read-Only Registers updates value
         regfile[0][7:0]   <= 8'hef;  // persona_version
         regfile[0][11:8]  <= pr_op_err;  // pr_op_err
         regfile[0][12]    <= local_cal_success;
         regfile[0][13]    <= local_cal_fail;
         regfile[0][15:14] <= 2'h0;  // RESERVED
         regfile[0][16]    <= iopll_locked;
         regfile[0][31:17] <= 2'h0;  // RESERVED

         regfile[3]        <= performance_cntr;

         post_wr_pulse <= 1'b0;

         // Register Writes
         if (pr_logic_cra_write) begin

            if (~|pr_logic_cra_address[13:5]) begin
               // Registers at Byte Address 0x00 and 0x0c are Read-Only registers and PCIe cannot write to them
               if (( pr_logic_cra_address[4:2] != 3'h0 ) && ( pr_logic_cra_address[4:2] != 3'h3 )) begin
                  // update register value based on dword address
                  regfile[pr_logic_cra_address[4:2]][7:0]   <= pr_logic_cra_byteenable[0] ? pr_logic_cra_writedata[7:0]   : regfile[pr_logic_cra_address[4:2]][7:0];
                  regfile[pr_logic_cra_address[4:2]][15:8]  <= pr_logic_cra_byteenable[1] ? pr_logic_cra_writedata[15:8]  : regfile[pr_logic_cra_address[4:2]][15:8];
                  regfile[pr_logic_cra_address[4:2]][23:16] <= pr_logic_cra_byteenable[2] ? pr_logic_cra_writedata[23:16] : regfile[pr_logic_cra_address[4:2]][23:16];
                  regfile[pr_logic_cra_address[4:2]][31:24] <= pr_logic_cra_byteenable[3] ? pr_logic_cra_writedata[31:24] : regfile[pr_logic_cra_address[4:2]][31:24];
               end

               // Generate a pulse whenever PR_MEM_ADDR value gets updated
               if ( pr_logic_cra_address[4:2] == 3'h2 ) begin
                  post_wr_pulse <= 1;
               end
               else begin
                  post_wr_pulse <= 0;
               end
            end


         end
         else if ( ( clear_start_operation == 1'b1 ) || ( ddr_access_completed == 1'b1 )) begin
            regfile[1][2] <= 1'b0;
         end
      end

   end 
   

   // Register read control logic
   always @(posedge pr_logic_clk_clk or negedge pr_logic_reset_reset_n)  begin

      if (  pr_logic_reset_reset_n == 1'b0 ) begin

         pr_logic_cra_readdata_reg <= 32'b0;
         pr_logic_cra_readdatavalid_reg <= 1'b0;
         pr_logic_cra_waitrequest <= 1'b1;
         sw_reset <= 1'b0;

      end
      else begin


         // Register Reads
         if (pr_logic_cra_read) begin

            if (~|pr_logic_cra_address[13:5]) begin
               // select value based on dword address
               pr_logic_cra_readdata_reg <= regfile[pr_logic_cra_address[4:2]];
            end
            else begin
               // for the rest of the registers output constant
               pr_logic_cra_readdata_reg <= 32'haabb_ccdd;
            end

         end

         // assert readdatavalid immediately when we receive a 
         // read request
         pr_logic_cra_readdatavalid_reg <= pr_logic_cra_read;

         // never need to assert waitrequest (except during reset
         // condition)
         pr_logic_cra_waitrequest <= 1'b0;

         sw_reset <= sw_reset_d;


      end

   end 
 
   always_comb begin  
      // Configuration Register Read Data output assignments 
      pr_logic_cra_readdata        = pr_logic_cra_readdata_reg;
      pr_logic_cra_readdatavalid   = pr_logic_cra_readdatavalid_reg;

      // Register Field outputs
      // PR_CTRL
      mode             = regfile[1][1:0];
      start_operation  = regfile[1][2];
      sw_reset_d       = regfile[1][3];
      emif_reset       = regfile[1][4];
      load_seed        = regfile[1][5];
      limit            = regfile[1][15:8];

      // PR_MEM_ADDR
      mem_addr         = regfile[2][31:0];

      // PR_RANDOM_DATA
      seed             = regfile[4][31:0];
   end

endmodule
