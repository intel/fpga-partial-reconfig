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

`ifndef INC_CONFIG_STREAM_ENDPOINT_PR_MONITOR_SV
`define INC_CONFIG_STREAM_ENDPOINT_PR_MONITOR_SV

class config_stream_endpoint_pr_monitor_c extends uvm_monitor;
   `uvm_component_utils(config_stream_endpoint_pr_monitor_c)

   virtual config_stream_endpoint_pr_if vif;

   uvm_analysis_port #(config_stream_endpoint_pr_seq_item_c) aport;

   function new(string name = "config_stream_endpoint_pr_monitor", uvm_component parent);
      super.new(name, parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      aport = new("aport", this);
   endfunction

   task run_phase(uvm_phase phase);
      config_stream_endpoint_pr_seq_item_c tr;

      forever begin
         // Sample if IF
         sample_if(tr);

         // Write the monitored transaction
         aport.write(tr);
      end
   endtask

   task sample_if(output config_stream_endpoint_pr_seq_item_c tr);
      tr = config_stream_endpoint_pr_seq_item_c::type_id::create("tr");

      // Do not use clocking block because sim_only_state and outputs are async
      @(vif.sim_only_state)
      $cast(tr.event_type, vif.sim_only_state);
      tr.pr_persona_id = vif.sim_only_pr_id;

      `uvm_info("PR Endpoint event: ", tr.convert2string(), UVM_HIGH)
   endtask


endclass

`endif //INC_CONFIG_STREAM_ENDPOINT_PR_MONITOR_SV
