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

`ifndef INC_PR_REGION_MONITOR_SV
`define INC_PR_REGION_MONITOR_SV

class pr_region_monitor_c extends uvm_monitor;
   `uvm_component_utils(pr_region_monitor_c)

   int pr_region_id;

   virtual altera_pr_persona_if vif;

   uvm_analysis_port #(pr_region_seq_item_c) aport;

   function new(string name = "pr_region_monitor", uvm_component parent);
      super.new(name, parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      pr_region_id = -1;

      aport = new("aport", this);
   endfunction

   task run_phase(uvm_phase phase);
      pr_region_seq_item_c tr;

      if (pr_region_id == -1) begin
         `uvm_fatal("", $sformatf("Region ID not set on %s", get_full_name()))
      end

      forever begin
         // Sample if IF
         sample_if(tr);

         // Write the monitored transaction
         aport.write(tr);
      end
   endtask

   task sample_if(output pr_region_seq_item_c tr);
      tr = pr_region_seq_item_c::type_id::create("t");

      @(vif.persona_select or vif.pr_activate);
      tr.persona_select = vif.persona_select;
      tr.persona_select_enabled = 1;

      tr.pr_activate = vif.pr_activate;
      tr.pr_activate_enabled = 1;

      tr.pr_region_id = pr_region_id;

      `uvm_info("PR region event: ", tr.convert2string(), UVM_MEDIUM)
      `uvm_info("pr_mon", $sformatf("PR region event:\n%s", tr.sprint()), UVM_HIGH);
   endtask


endclass

`endif //INC_PR_REGION_MONITOR_SV
