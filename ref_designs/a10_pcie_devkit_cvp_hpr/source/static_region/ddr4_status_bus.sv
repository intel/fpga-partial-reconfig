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
   synchronizer  #( .WIDTH (1), .STAGES(3) )
   u_synch_success 
   (
      .clk_in    ( ddr4_clk_in ),
      .arstn_in  ( ddr4_rstn_in ),
      .clk_out   ( pcie_clk_in ),
      .arstn_out ( pcie_rstn_in ),
      .dat_in    ( input_unsynchronized_cal_success ),
      .dat_out   ( synchronized_cal_success )  
   );

   synchronizer  #( .WIDTH (1), .STAGES(3) )
   u_synch_fail 
   (
      .clk_in    ( ddr4_clk_in ),
      .arstn_in  ( ddr4_rstn_in ),
      .clk_out   ( pcie_clk_in ),
      .arstn_out ( pcie_rstn_in ),
      .dat_in    ( input_unsynchronized_cal_fail ),
      .dat_out   ( synchronized_cal_fail )  
   );
endmodule
