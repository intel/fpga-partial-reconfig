`include "uvm_macros.svh"

`ifndef INC_SIMPLE_DDR4_ACCESS_SV
`define INC_SIMPLE_DDR4_ACCESS_SV

class simple_ddr4_access extends base_test;
   `uvm_component_utils(simple_ddr4_access)

   pr_region_pkg::pr_region_set_persona_seq_c set_persona_seq;
   bar4_avmm_pkg::bar4_idle_seq_c idle_seq;

   basic_ddr4_access_region0_seq_c basic_ddr4_access_region0_seq;

   read_persona_id_seq_c read_persona_id_seq;

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      idle_seq = bar4_avmm_pkg::bar4_idle_seq_c::type_id::create("idle_seq", this);
      read_persona_id_seq = read_persona_id_seq_c::type_id::create("read_persona_id_seq", this);
      set_persona_seq = pr_region_pkg::pr_region_set_persona_seq_c::type_id::create("set_persona_seq", this);

      basic_ddr4_access_region0_seq = basic_ddr4_access_region0_seq_c::type_id::create("basic_ddr4_access_region0_seq",this);
   endfunction

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
   endfunction

   task run_phase(uvm_phase phase);
      phase.raise_objection(this);

      `uvm_info("TST", "Preparing to run simple basic ddr4 test", UVM_LOW)

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

      // Perform the basic check for the basic ddr persona
      basic_ddr4_access_region0_seq.bar4_sqr = env.bar4_agnt.sqr;
      basic_ddr4_access_region0_seq.start();

      // Send 100 idle sequence items
      idle_seq.num_idle_trans = 100;
      idle_seq.start(env.bar4_agnt.sqr);

      phase.drop_objection(this);
   endtask

endclass


`endif //INC_SIMPLE_DDR4_ACCESS_SV
