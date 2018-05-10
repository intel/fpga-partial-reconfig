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

`ifndef INC_PR_REGION_DRIVER_SV
`define INC_PR_REGION_DRIVER_SV

class pr_region_driver_c extends uvm_driver #(pr_region_seq_item_c);

   `uvm_component_utils(pr_region_driver_c)

   bit enable_region_id = 0;
   int pr_region_id = -1;
   REQ req;
   int default_persona_select = 0;

   virtual altera_pr_persona_if vif;

   function new(string name = "pr_region_driver", uvm_component parent = null);
      super.new(name, parent);
   endfunction

   task run_phase(uvm_phase phase);

      if (pr_region_id == -1) begin
         `uvm_fatal("", $sformatf("Region ID not set on %s", get_full_name()))
      end

      // Default conditions:
      vif.pr_activate <= 0;
      vif.persona_select <= default_persona_select;

      forever begin
         seq_item_port.get_next_item(req);

         `uvm_info("PR region tr: ", req.convert2string(), UVM_MEDIUM)
         `uvm_info("pr_drv", $sformatf("PR region tr:\n%s", req.sprint()), UVM_HIGH);
         if (enable_region_id) begin
            `altr_assert(req.pr_region_id != -1)
         end


         // Only process for this region ID
         if ((req.pr_region_id == pr_region_id) || !enable_region_id) begin
            if (req.pr_activate_enabled) begin
               vif.pr_activate <= req.pr_activate;
            end
            if (req.persona_select_enabled) begin
               vif.persona_select <= req.persona_select;
            end
         end
         else begin
            `uvm_info("pr_drv", $sformatf("Ignoring transaction as pr_region_id != %0d : PR region tr:\n%s", pr_region_id, req.sprint()), UVM_HIGH);
         end

         seq_item_port.item_done();
      end
   endtask: run_phase

endclass

`endif
