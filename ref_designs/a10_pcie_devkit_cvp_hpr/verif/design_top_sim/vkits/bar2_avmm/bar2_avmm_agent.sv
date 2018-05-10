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

`ifndef INC_BAR2_AVMM_AGENT_SV
`define INC_BAR2_AVMM_AGENT_SV

class bar2_avmm_agent_c extends avmm_pkg::avmm_agent_c
#(
  .DRV_BFM_TYPE(virtual bar2_avalon_mm_master_bfm),
  .MON_BFM_TYPE(virtual bar2_avalon_mm_monitor_bfm),

  .CMD_T(bar2_avmm_command_seq_item_c),
  .RSP_T(bar2_avmm_response_seq_item_c),

  .AV_ADDRESS_W(design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_ADDRESS_W),
  .AV_DATA_W(design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_DATA_W),
  .USE_BURSTCOUNT(design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_USE_BURSTCOUNT),
  .AV_BURSTCOUNT_W(design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_BURSTCOUNT_W),
  .AV_NUMSYMBOLS(design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_SYMBOL_W),
  .AV_READRESPONSE_W(8),
  .AV_WRITERESPONSE_W(8),
  .USE_WRITE_RESPONSE(design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_USE_WRITERESPONSE),
  .USE_READ_RESPONSE(design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_USE_READRESPONSE)
 );
   `uvm_component_utils(bar2_avmm_agent_c)

   function new(string name = "Agent", uvm_component parent);
      super.new(name, parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
   endfunction

   task run_phase(uvm_phase phase);
      super.run_phase(phase);
   endtask

endclass

`endif //INC_BAR2_AVMM_AGENT_SV
