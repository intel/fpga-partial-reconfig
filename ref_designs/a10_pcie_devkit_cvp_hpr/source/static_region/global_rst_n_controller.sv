`timescale 1 ps / 1 ps
`default_nettype none

// This module generates the global reset to be used by the BSP

module global_rst_n_controller 
   (
   input wire  io_pll_locked,
   input wire  pcie_global_rst_n,
   output wire global_rst_n
   );

   assign global_rst_n = (io_pll_locked & pcie_global_rst_n);

endmodule
