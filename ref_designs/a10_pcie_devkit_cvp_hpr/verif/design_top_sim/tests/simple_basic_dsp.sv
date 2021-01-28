`include "uvm_macros.svh"

`ifndef INC_SIMPLE_BASIC_DSP_SV
`define INC_SIMPLE_BASIC_DSP_SV

class simple_basic_dsp extends base_test;
   `uvm_component_utils(simple_basic_dsp)

   pr_region_pkg::pr_region_set_persona_seq_c set_persona_seq;
   bar4_avmm_pkg::bar4_idle_seq_c idle_seq;
   read_persona_id_seq_c read_persona_id_seq;
   basic_dsp_rand_seq_c basic_dsp_seq;


   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      idle_seq = bar4_avmm_pkg::bar4_idle_seq_c::type_id::create("idle_seq", this);
      set_persona_seq = pr_region_pkg::pr_region_set_persona_seq_c::type_id::create("set_persona_seq", this);
      read_persona_id_seq = read_persona_id_seq_c::type_id::create("read_persona_id_seq", this);

      basic_dsp_seq = basic_dsp_rand_seq_c::type_id::create("basic_dsp_seq", this);

   endfunction

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
   endfunction

   task run_phase(uvm_phase phase);
      phase.raise_objection(this);

      `uvm_info("TST", "Preparing to run simple basic DSP test", UVM_LOW)

      // Set the active persona to be the basic dsp
      set_persona_seq.persona_select = 2;
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

      // Perform the basic check for the basic_dsp persona
      // Perform the basic check for the basic_arithmetic persona
      basic_dsp_seq.operand_x = 5;
      basic_dsp_seq.operand_y = 6;
      basic_dsp_seq.pre_operand_idle_cycles = 1;
      basic_dsp_seq.pre_result_idle_cycles = 1;
      basic_dsp_seq.post_result_idle_cycles = 1;
      basic_dsp_seq.start(env.bar4_agnt.sqr);

      // Send 100 idle sequence items
      idle_seq.num_idle_trans = 100;
      idle_seq.start(env.bar4_agnt.sqr);

      phase.drop_objection(this);
   endtask

endclass


`endif //INC_SIMPLE_BASIC_DSP_SV
