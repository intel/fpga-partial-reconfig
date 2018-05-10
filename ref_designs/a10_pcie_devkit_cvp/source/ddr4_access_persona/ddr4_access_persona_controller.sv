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

// This is the register block for DDRaccess persona
// The register block is where PCIe Could access registers

module ddr4_access_persona_controller #( parameter REG_FILE_IO_SIZE = 8 )
   (
      input wire         clk, 
      input wire         pr_logic_rst, 
      output reg         clr_io_reg, 
      //Persona identification register, used by host in host program
      output wire [31:0] persona_id, 
      //Host control register, used for control signals.
      input wire [31:0]  host_cntrl_register, 
      // 8 registers for host -> PR logic communication
      input wire [31:0]  host_pr [0:REG_FILE_IO_SIZE-1],
      // 8 Registers for PR logic -> host communication
      output wire [31:0] pr_host [0:REG_FILE_IO_SIZE-1],
      // Register Field inputs
      input wire [31:0]  performance_cntr,
      input wire         ddr_access_completed,
      input wire         clear_start_operation,
      input wire         busy_reg,
      output reg         start_operation,
      output reg         load_seed,
      output reg [31:0]  mem_addr,
      output wire        post_wr_pulse,
      output reg [31:0]  seed,
      output reg [31:0]  final_address
   );


   reg [31:0]          mem_address_q;
   reg                 clr_io_reg_d;
   reg                 start_d;
   reg [31:0]          final_address_q;
   reg                 start_pulse;
   assign persona_id = 32'hef;
   assign pr_host[0] = performance_cntr;
   assign pr_host[1] = {31'h0, busy_reg};
   assign pr_host[2] = 32'h0;
   assign pr_host[3] = 32'h0;
   assign pr_host[4] = 32'h0;
   assign pr_host[5] = 32'h0;
   assign pr_host[6] = 32'h0;
   assign pr_host[7] = 32'h0;
   assign post_wr_pulse = ((mem_addr != mem_address_q) && ~pr_logic_rst);
   always @(posedge clk or posedge pr_logic_rst)  begin

      if (  pr_logic_rst == 1'b1 ) begin
         start_operation       <= 1'b0;
         mem_address_q         <= 0;
         start_pulse           <= 1'b0;
         start_d               <= 1'b0;
         mem_addr              <= 0;
         final_address_q       <= 0;
         final_address         <= 0;
         seed                  <= 0;
         load_seed             <= 1'b0;
      end
      else begin
         //Control registers
         if(start_pulse == 1'b1)
         begin
            start_operation   <= 1'b1;
         end else if ( ( clear_start_operation == 1'b1 ) || ( ddr_access_completed == 1'b1 )) begin
            start_operation   <=1'b0;
         end
         mem_address_q         <= mem_addr;
         load_seed             <= host_cntrl_register[1];
         start_d               <= host_cntrl_register[2];
         start_pulse           <= ~start_d && host_cntrl_register[2];
         mem_addr              <= host_pr[0][31:0];
         seed                  <= host_pr[1][31:0];
         final_address_q       <= host_pr[0][31:0] + host_pr[2][31:0];
         final_address         <= final_address_q;
      end

   end 
   // Register clear control logic
   always @(posedge clk or posedge pr_logic_rst)  begin
      if (  pr_logic_rst == 1'b1 ) begin
         clr_io_reg_d <= 1'b0;
         clr_io_reg <= 1'b0;
      end
      else begin
         clr_io_reg <= (~clr_io_reg_d && host_cntrl_register[0]);
         clr_io_reg_d <= host_cntrl_register[0];
      end

   end 
endmodule
