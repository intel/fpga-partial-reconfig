`ifndef INC_BAR4_AVMM_PKG_SV
`define INC_BAR4_AVMM_PKG_SV

`include "uvm_macros.svh"
`include "avmm_pkg.sv"

package bar4_avmm_pkg;
   import uvm_pkg::*;

   `include "bar4_avmm_response_seq_item.sv"
   `include "bar4_avmm_command_seq_item.sv"
   `include "bar4_avmm_agent.sv"
   `include "bar4_avmm_sequence_lib.sv"

   typedef avmm_pkg::avmm_sequencer_c #(bar4_avmm_command_seq_item_c) bar4_avmm_sequencer_c;

endpackage

`endif //INC_BAR4_AVMM_PKG_SV
