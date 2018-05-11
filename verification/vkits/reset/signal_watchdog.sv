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

`ifndef INC_SIGNAL_WATCHDOG_SV
`define INC_SIGNAL_WATCHDOG_SV

class signal_watchdog_c #(DELAY) extends uvm_object;

   `uvm_object_param_utils(signal_watchdog_c#(DELAY))

   virtual signal_watchdog_if vif;
   
   string signal_name = "UNNAMED SIGNAL";
   int post_done_cycles = 0;

   function new(string name = "signal_watchdog");
      super.new(name);
   endfunction

   task run();

      // Wait for IOPLL lock
      `uvm_info("TST", $sformatf("Waiting for %s", signal_name), UVM_LOW)
      fork : wait_watched
         begin
            while (vif.watched != 1'b1) begin
               @vif.cb1;
            end
         end
         begin
            #DELAY `uvm_fatal("TST", $sformatf("%s Not Done", signal_name))
            $finish;
         end
      join_any
      disable wait_watched;
      `uvm_info("TST", $sformatf("%s Done", signal_name), UVM_LOW)
      
      // Post watched cycles
      if (post_done_cycles > 0) begin
         `uvm_info("TST", $sformatf("Waiting %0d cycles after %s Done", post_done_cycles, signal_name), UVM_LOW)
         repeat(post_done_cycles) @vif.cb1;
      end
   
   endtask: run

endclass

`endif
