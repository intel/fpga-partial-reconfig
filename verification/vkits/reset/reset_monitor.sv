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

`ifndef INC_RESET_MONITOR_SV
`define INC_RESET_MONITOR_SV

class reset_monitor_c extends uvm_monitor;
   `uvm_component_utils(reset_monitor_c)

   virtual reset_if vif;

   uvm_analysis_port #(reset_seq_item_c) aport;

   function new(string name = "[name]", uvm_component parent);
      super.new(name, parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      aport = new("aport", this);
   endfunction

   task run_phase(uvm_phase phase);
      reset_seq_item_c tr;

      forever begin
         // Sample if IF
         sample_if(tr);

         // Write the monitored transaction
         aport.write(tr);
      end
   endtask

   task sample_if(output reset_seq_item_c tr);
      tr = reset_seq_item_c::type_id::create("t");

      @(vif.reset);
      tr.reset = vif.reset;

      `uvm_info("RST", $sformatf("reset event: %s", tr.convert2string()), UVM_HIGH)
   endtask


endclass

`endif //INC_RESET_MONITOR_SV
