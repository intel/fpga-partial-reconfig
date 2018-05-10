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

`ifndef INC_BASE_TEST_SV
`define INC_BASE_TEST_SV

`include "uvm_macros.svh"

class base_test extends uvm_test;
   `uvm_component_utils(base_test)

   design_top_sim_pkg::environment env;
   reset_pkg::reset_cycle_reset_seq_c reset_seq;

   function new(string name, uvm_component parent);
      super.new(name, parent);

   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      env = design_top_sim_pkg::environment::type_id::create("env", this);
      reset_seq = reset_pkg::reset_cycle_reset_seq_c::type_id::create("reset_seq", this);

   endfunction

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
   endfunction

/*   task run_phase(uvm_phase phase);
      phase.raise_objection(this);

      tb_reset();

      // Wait for reset to complete
      @(posedge `TB_DUT.global_rst_n_controller.global_rst_n);

      repeat (20)
         @(posedge `TB.tb_clk);

      repeat (200)
         @(posedge `TB.tb_clk);
      phase.drop_objection(this);
   endtask



   // KALEN HACK: Make this a real driver
   virtual task tb_reset();
      // Initialize testbench signals
      $root.sim_top.tb.nreset <= 1'b0;

      // Reset
      $root.sim_top.tb.nreset <= 1'b0;
      repeat (5)
         @(posedge $root.sim_top.tb.tb_clk);
      $root.sim_top.tb.nreset <= 1'b1;
      repeat (5)
         @(posedge $root.sim_top.tb.tb_clk);

   endtask
*/
endclass


`endif //INC_BASE_TEST_SV
