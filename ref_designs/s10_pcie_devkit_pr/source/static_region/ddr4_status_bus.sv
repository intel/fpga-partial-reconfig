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

// ddr4_status_bus.v

//This takes the ddr4 calibration feedback, crosses the clock domain from ddr4 to pcie, then sends it to the PIO for the calubration status

`timescale 1 ps / 1 ps
module ddr4_status_bus 
(
   input wire         ddr4_clk_in,
   input wire         ddr4_rstn_in,
   input wire         pcie_clk_in,
   input wire         pcie_rstn_in, 
   input wire         input_unsynchronized_cal_success,
   input wire         input_unsynchronized_cal_fail,
   output wire [31:0] ddr4_calibration_outterface_external_connection_export  
);
 
   wire                synchronized_cal_success;
   wire                synchronized_cal_fail;

   assign ddr4_calibration_outterface_external_connection_export = {30'h0, synchronized_cal_success, synchronized_cal_fail};
   synchronizer  #( .WIDTH (1), .STAGES(5) )
   u_synch_success 
   (
      .clk_in    ( ddr4_clk_in ),
      .arstn_in  ( 1'b1 ),
      .clk_out   ( pcie_clk_in ),
      .arstn_out ( 1'b1 ),
      .dat_in    ( input_unsynchronized_cal_success ),
      .dat_out   ( synchronized_cal_success )  
   );

   synchronizer  #( .WIDTH (1), .STAGES(5) )
   u_synch_fail 
   (
      .clk_in    ( ddr4_clk_in ),
      .arstn_in  ( 1'b1 ),
      .clk_out   ( pcie_clk_in ),
      .arstn_out ( 1'b1 ),
      .dat_in    ( input_unsynchronized_cal_fail ),
      .dat_out   ( synchronized_cal_fail )  
   );
endmodule
