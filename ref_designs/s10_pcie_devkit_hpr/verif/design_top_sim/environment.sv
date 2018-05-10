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

`ifndef INC_ENVIRONMENT_SV
`define INC_ENVIRONMENT_SV

class environment extends uvm_env;
   `uvm_component_utils(environment)

   sim_reporting test_report;

   virtual reset_if reset_bfm;
   virtual bar4_avalon_mm_master_bfm bar4_mm_master_bfm;
   virtual bar4_avalon_mm_monitor_bfm bar4_mm_monitor_bfm;

   virtual bar2_avalon_mm_master_bfm bar2_mm_master_bfm;
   virtual bar2_avalon_mm_monitor_bfm bar2_mm_monitor_bfm;

   virtual altera_pr_persona_if region0_if;
   virtual reset_watchdog_if dut_reset_watchdog_if;

   scoreboard_c sb;
   reset_watchdog_c reset_watchdog;

   bar4_avmm_pkg::bar4_avmm_agent_c bar4_agnt;
   bar2_avmm_pkg::bar2_avmm_agent_c bar2_agnt;
   pr_region_pkg::pr_region_agent_c region0_agnt;

   reset_pkg::reset_agent_c reset_agnt;

   function new(string name, uvm_component parent);
      super.new(name, parent);

      if ($test$plusargs("ntb_random_seed")) begin
         int seed;
         $value$plusargs("ntb_random_seed=%d", seed);
         `uvm_info("ENV", $sformatf("Running simulation with random seed=%0d", seed), UVM_LOW);
      end else begin
         `uvm_info("ENV", "Running simulation with default random seed", UVM_LOW);
      end

      // Initialize the test reporting
      test_report = new();

   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      `uvm_info("", "Env build phase", UVM_LOW)

      // Build the simulation components
      `uvm_info("ENV", "Building components", UVM_LOW);

      // Create the testbench transactors
      sb = scoreboard_c::type_id::create("sb", this);
      sb.test_report = test_report;

      bar4_agnt = bar4_avmm_pkg::bar4_avmm_agent_c::type_id::create("bar4_agnt", this);

      bar2_agnt = bar2_avmm_pkg::bar2_avmm_agent_c::type_id::create("bar2_agnt", this);

      region0_agnt = pr_region_pkg::pr_region_agent_c::type_id::create("region0_agnt", this);

      reset_agnt = reset_pkg::reset_agent_c::type_id::create("reset_agnt", this);
      reset_watchdog = reset_watchdog_c::type_id::create("reset_watchdog");

   endfunction

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);

      // Connect the simulation components as required
      `uvm_info("ENV", "Connecting components", UVM_LOW);

      // Get the BFM IF from the resource DB
      `altr_get_if(virtual reset_if, "testbench", "reset_bfm", reset_bfm)

      `altr_get_if(virtual bar4_avalon_mm_master_bfm, "testbench", "bar4_avmm_bfm", bar4_mm_master_bfm)
      `altr_get_if(virtual bar4_avalon_mm_monitor_bfm, "testbench", "bar4_avmm_monitor", bar4_mm_monitor_bfm)

      `altr_get_if(virtual bar2_avalon_mm_master_bfm, "testbench", "bar2_avmm_bfm", bar2_mm_master_bfm)
      `altr_get_if(virtual bar2_avalon_mm_monitor_bfm, "testbench", "bar2_avmm_monitor", bar2_mm_monitor_bfm)

      `altr_get_if(virtual altera_pr_persona_if, "testbench", "pr_region0", region0_if)

      `altr_get_if(virtual reset_watchdog_if, "testbench", "dut_reset_watchdog_if", dut_reset_watchdog_if)

      reset_agnt.drv.vif = reset_bfm;
      reset_agnt.mon.vif = reset_bfm;

      bar4_agnt.drv.mm_master_bfm = bar4_mm_master_bfm;
      bar4_agnt.mon.mm_monitor = bar4_mm_monitor_bfm;
      bar4_agnt.command_aport.connect(sb.bar4_command_aport_mon);
      bar4_agnt.response_aport.connect(sb.bar4_response_aport_mon);

      bar2_agnt.drv.mm_master_bfm = bar2_mm_master_bfm;
      bar2_agnt.mon.mm_monitor = bar2_mm_monitor_bfm;
      bar2_agnt.command_aport.connect(sb.bar2_command_aport_mon);
      bar2_agnt.response_aport.connect(sb.bar2_response_aport_mon);

      region0_agnt.set_region_id(0);
      region0_agnt.drv.vif = region0_if;
      region0_agnt.mon.vif = region0_if;
      region0_agnt.aport.connect(sb.pr_region_0_aport_mon);
      reset_watchdog.vif = dut_reset_watchdog_if;

   endfunction

   virtual function void end_of_elaboration_phase(uvm_phase phase);
      super.end_of_elaboration_phase(phase);

      // Print the testbench
      uvm_top.print_topology();
   endfunction

   virtual task run_phase(uvm_phase phase);
      super.run_phase(phase);

   endtask

   virtual function void report_phase(uvm_phase phase);
      super.report_phase(phase);

      // Report the results
      `uvm_info("ENV", "Generating report", UVM_LOW);

      // Print the overall test status
      test_report.summarize_test_results();
   endfunction

   virtual function void final_phase(uvm_phase phase);
      super.final_phase(phase);

      // Cleanup
      `uvm_info("ENV", "Finalizing simulation", UVM_LOW);
   endfunction

endclass


`endif //INC_ENVIRONMENT_SV
