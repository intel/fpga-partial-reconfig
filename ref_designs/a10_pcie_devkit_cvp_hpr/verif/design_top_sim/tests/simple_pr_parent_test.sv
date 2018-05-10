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

`include "uvm_macros.svh"

`ifndef SIMPLE_PR_PARENT_TEST
`define SIMPLE_PR_PARENT_TEST

class simple_pr_parent_test extends base_test;
   `uvm_component_utils(simple_pr_parent_test)

   bar4_avmm_pkg::bar4_idle_seq_c idle_seq;

   read_persona_id_seq_c read_parent_persona_id_seq;
   read_parent_persona_child_0_persona_id_seq_c read_parent_persona_child_0_persona_id_seq;
   read_parent_persona_child_1_persona_id_seq_c read_parent_persona_child_1_persona_id_seq;

   pr_region_pkg::pr_region_set_persona_seq_c set_parent_persona_seq;
   pr_region_pkg::pr_region_set_persona_seq_c set_child0_persona_seq;
   pr_region_pkg::pr_region_set_persona_seq_c set_child1_persona_seq;

   region0_pr_seq_c region0_pr_seq;

   basic_ddr4_access_pr_parent_child0_seq_c basic_ddr4_access_pr_parent_child0_seq;
   basic_ddr4_access_pr_parent_child1_seq_c basic_ddr4_access_pr_parent_child1_seq;
   
   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      idle_seq = bar4_avmm_pkg::bar4_idle_seq_c::type_id::create("idle_seq", this);
      
      read_parent_persona_id_seq = read_persona_id_seq_c::type_id::create("read_parent_persona_id_seq", this);
      read_parent_persona_child_0_persona_id_seq = read_parent_persona_child_0_persona_id_seq_c::type_id::create("read_parent_persona_child_0_persona_id_seq", this);
      read_parent_persona_child_1_persona_id_seq = read_parent_persona_child_1_persona_id_seq_c::type_id::create("read_parent_persona_child_1_persona_id_seq", this);

      set_parent_persona_seq = pr_region_pkg::pr_region_set_persona_seq_c::type_id::create("set_parent_persona_seq", this);
      set_child0_persona_seq = pr_region_pkg::pr_region_set_persona_seq_c::type_id::create("set_child0_persona_seq", this);
      set_child1_persona_seq = pr_region_pkg::pr_region_set_persona_seq_c::type_id::create("set_child1_persona_seq", this);
      
      region0_pr_seq = region0_pr_seq_c::type_id::create("region0_pr_seq", this);
      
      basic_ddr4_access_pr_parent_child0_seq = basic_ddr4_access_pr_parent_child0_seq_c::type_id::create("basic_ddr4_access_pr_parent_child0_seq",this);
      basic_ddr4_access_pr_parent_child1_seq = basic_ddr4_access_pr_parent_child1_seq_c::type_id::create("basic_ddr4_access_pr_parent_child1_seq",this);

   endfunction

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
   endfunction

   task run_phase(uvm_phase phase);
      phase.raise_objection(this);

      // Set parameters
      basic_ddr4_access_pr_parent_child0_seq.bar4_sqr = env.bar4_agnt.sqr;
      basic_ddr4_access_pr_parent_child0_seq.description = "PR Parent Child 0 DDR4 Persona";

      basic_ddr4_access_pr_parent_child1_seq.bar4_sqr = env.bar4_agnt.sqr;
      basic_ddr4_access_pr_parent_child1_seq.description = "PR Parent Child 1 DDR4 Persona";

      `uvm_info("TST", "Preparing to run simple basic hpr test", UVM_LOW)

      // Set the active persona to be the HPR parent
      set_parent_persona_seq.persona_select = 4;
      set_parent_persona_seq.start(env.region0_agnt.sqr);

      // Set the active HPR child 0 persona to be the DDR4 access
      set_child0_persona_seq.persona_select = 0;
      set_child0_persona_seq.start(env.parent_persona_region0_agnt.sqr);

      // Set the active HPR child 1 persona to be the DDR4 access
      set_child1_persona_seq.persona_select = 0;
      set_child1_persona_seq.start(env.parent_persona_region1_agnt.sqr);

      // Reset the system
      reset_seq.start(env.reset_agnt.sqr);

      // KALEN HACK: Make this a driver
      // Wait for reset to complete
      @(posedge $root.sim_top.tb.dut.global_rst_n_controller.global_rst_n);

      // Send 20 idle sequence items
      idle_seq.num_idle_trans = 20;
      idle_seq.start(env.bar4_agnt.sqr);

      // Read the parent persona ID
      read_parent_persona_id_seq.start(env.bar4_agnt.sqr);

      // Read the child 0 persona ID
      read_parent_persona_child_0_persona_id_seq.start(env.bar4_agnt.sqr);

      // Read the child 1 persona ID
      read_parent_persona_child_1_persona_id_seq.start(env.bar4_agnt.sqr);

      // Perform the basic check for the basic ddr persona on child 0
      basic_ddr4_access_pr_parent_child0_seq.start();

      // Perform the basic check for the basic ddr persona on child 1
      basic_ddr4_access_pr_parent_child1_seq.start();

      // Send 100 idle sequence items
      idle_seq.num_idle_trans = 100;
      idle_seq.start(env.bar4_agnt.sqr);

      // PR to persona 4 on the toplevel PR region
      region0_pr_seq.persona_select = 4;
      region0_pr_seq.bar4_sqr = env.bar4_agnt.sqr;
      region0_pr_seq.region0_sqr = env.region0_agnt.sqr;
      region0_pr_seq.pr_parent_region0_sqr = env.parent_persona_region0_agnt.sqr;
      region0_pr_seq.pr_parent_region1_sqr = env.parent_persona_region1_agnt.sqr;
      region0_pr_seq.start();

      // Send 100 idle sequence items
      idle_seq.num_idle_trans = 100;
      idle_seq.start(env.bar4_agnt.sqr);
      
      // Read the parent persona ID
      read_parent_persona_id_seq.start(env.bar4_agnt.sqr);

      // Read the child 0 persona ID
      read_parent_persona_child_0_persona_id_seq.start(env.bar4_agnt.sqr);

      // Read the child 1 persona ID
      read_parent_persona_child_1_persona_id_seq.start(env.bar4_agnt.sqr);

      // Perform the basic check for the basic ddr persona on child 0
      basic_ddr4_access_pr_parent_child0_seq.start();

      // Perform the basic check for the basic ddr persona on child 1
      basic_ddr4_access_pr_parent_child1_seq.start();

      // Send 100 idle sequence items
      idle_seq.num_idle_trans = 100;
      idle_seq.start(env.bar4_agnt.sqr);

      phase.drop_objection(this);
   endtask

endclass


`endif //SIMPLE_PR_PARENT_TEST
