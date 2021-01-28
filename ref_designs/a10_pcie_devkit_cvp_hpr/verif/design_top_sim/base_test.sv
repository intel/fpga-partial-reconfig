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
