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

`ifndef INC_SIMPLE_DDR4_ACCESS_SV
`define INC_SIMPLE_DDR4_ACCESS_SV

class simple_ddr4_access extends base_test;
   `uvm_component_utils(simple_ddr4_access)

   pr_region_pkg::pr_region_set_persona_seq_c set_persona_seq;
   bar4_avmm_pkg::bar4_idle_seq_c idle_seq;
   ddr4_access_load_address_rand_seq_c ddr4_access_load_address_rand_seq;
   ddr4_access_start_seq_c ddr4_access_start_seq;
   ddr4_access_load_seed_seq_c ddr4_access_load_seed_seq;
   ddr4_access_busy_seq_c ddr4_access_busy_seq;
   ddr4_access_read_res_seq_c ddr4_access_read_res_seq;
   read_persona_id_seq_c read_persona_id_seq;

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      idle_seq = bar4_avmm_pkg::bar4_idle_seq_c::type_id::create("idle_seq", this);
      read_persona_id_seq = read_persona_id_seq_c::type_id::create("read_persona_id_seq", this);
      set_persona_seq = pr_region_pkg::pr_region_set_persona_seq_c::type_id::create("set_persona_seq", this);
      ddr4_access_load_address_rand_seq =ddr4_access_load_address_rand_seq_c::type_id::create("ddr4_load_address_rand_seq",this);
      ddr4_access_start_seq =ddr4_access_start_seq_c::type_id::create("ddr4_access_start_seq",this);
      ddr4_access_load_seed_seq =ddr4_access_load_seed_seq_c::type_id::create("ddr4_access_load_seed_seq",this);
      ddr4_access_busy_seq =ddr4_access_busy_seq_c::type_id::create("ddr4_access_busy_seq",this);
      ddr4_access_read_res_seq =ddr4_access_read_res_seq_c::type_id::create("ddr4_access_read_res_seq_c",this);
   endfunction

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
   endfunction

   task run_phase(uvm_phase phase);
      phase.raise_objection(this);

      `uvm_info("TST", "Preparing to run simple basic arith test", UVM_LOW)

      // Set the active persona to be the ddr4
      set_persona_seq.persona_select = 1;
      set_persona_seq.start(env.region0_agnt.sqr);

      // Reset the system
      reset_seq.start(env.reset_agnt.sqr);

      // KALEN HACK: Make this a driver
      // Wait for reset to complete
      @(posedge $root.sim_top.tb.dut.global_rst_n_controller.global_rst_n);

      // Send 20 idle sequence items
      idle_seq.num_idle_trans = 20;
      idle_seq.start(env.bar4_agnt.sqr);

      // Read the persona ID
      read_persona_id_seq.start(env.bar4_agnt.sqr);


      // Perform the basic check for the basic_arithmetic persona
      ddr4_access_load_seed_seq.seed=1;
      ddr4_access_load_seed_seq.pre_seed_idle_cycles=1;
      ddr4_access_load_seed_seq.pre_load_seed_idle_cycles=1;
      ddr4_access_load_seed_seq.post_load_seed_idle_cycles=1;
      ddr4_access_load_seed_seq.start(env.bar4_agnt.sqr);

      ddr4_access_load_address_rand_seq.base_address=0;
      ddr4_access_load_address_rand_seq.final_offset=100;
      ddr4_access_load_address_rand_seq.pre_mem_address_idle_cycles=1;
      ddr4_access_load_address_rand_seq.pre_final_offset_idle_cycles=1;
      ddr4_access_load_address_rand_seq.start(env.bar4_agnt.sqr);

      ddr4_access_start_seq.pre_start_assert_idle_cycles=1;
      ddr4_access_start_seq.post_start_assert_idle_cycles=1;
      ddr4_access_start_seq.pre_start_deassert_idle_cycles=1;
      ddr4_access_start_seq.start(env.bar4_agnt.sqr);
      ddr4_access_busy_seq.start(env.bar4_agnt.sqr);
      ddr4_access_read_res_seq.pre_read_idle_cycles=1;
      ddr4_access_read_res_seq.start(env.bar4_agnt.sqr);
      // Send 100 idle sequence items
      idle_seq.num_idle_trans = 100;
      idle_seq.start(env.bar4_agnt.sqr);

      phase.drop_objection(this);
   endtask

endclass


`endif //INC_SIMPLE_DDR4_ACCESS_SV
