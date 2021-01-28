`ifndef INC_BAR2_AVMM_PKG_SV
`define INC_BAR2_AVMM_PKG_SV

`include "uvm_macros.svh"
`include "avmm_pkg.sv"

package bar2_avmm_pkg;
   import uvm_pkg::*;

   `include "bar2_avmm_response_seq_item.sv"
   `include "bar2_avmm_command_seq_item.sv"
   `include "bar2_avmm_agent.sv"
   `include "bar2_avmm_sequence_lib.sv"

   typedef avmm_pkg::avmm_sequencer_c #(bar2_avmm_command_seq_item_c) bar2_avmm_sequencer_c;

endpackage

`endif //INC_BAR2_AVMM_PKG_SV
