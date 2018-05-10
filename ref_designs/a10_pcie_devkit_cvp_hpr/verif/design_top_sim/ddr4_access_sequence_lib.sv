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


`ifndef INC_DDR4_ACCESS_SEQUENCE_LIB_SV
`define INC_DDR4_ACCESS_SEQUENCE_LIB_SV

class ddr4_access_persona_base_seq_c #(REGFILE_BASE_ADDRESS) extends bar4_avmm_pkg::bar4_avmm_base_seq_c;
   `uvm_object_param_utils(ddr4_access_persona_base_seq_c #(REGFILE_BASE_ADDRESS))

   localparam DDR4_MEM_ADDRESS = REGFILE_BASE_ADDRESS + 32'hA0;
   localparam DDR4_SEED_ADDRESS = REGFILE_BASE_ADDRESS + 32'hB0;
   localparam DDR4_FINAL_OFFSET = REGFILE_BASE_ADDRESS + 32'hC0;
   localparam PERFORMANCE_COUNTER = REGFILE_BASE_ADDRESS + 32'h20;
   localparam DDR4_BUSY_REGISTER = REGFILE_BASE_ADDRESS + 32'h30;
   localparam DDR4_START_MASK = 2;
   localparam DDR4_LOAD_SEED_MASK = 1;
   localparam DDR4_ADDRESS_MAX = 32'h40000000;
   localparam DDR4_CAL_MASK = 3;
   localparam DDR4_CAL_OFFSET = REGFILE_BASE_ADDRESS + 32'h10010;
   localparam PR_CONTROL_REGISTER = REGFILE_BASE_ADDRESS + 32'h10;

   function new(string name = "[name]]");
      super.new(name);
   endfunction

endclass

class ddr4_access_load_address_rand_seq_c #(REGFILE_BASE_ADDRESS) extends ddr4_access_persona_base_seq_c #(REGFILE_BASE_ADDRESS);
   `uvm_object_param_utils(ddr4_access_load_address_rand_seq_c #(REGFILE_BASE_ADDRESS))

   rand logic [31:0] base_address;
   rand logic [31:0] final_offset;

   rand int pre_mem_address_idle_cycles;
   rand int pre_final_offset_idle_cycles;

   /*constraint reasonable_cycle_limits {
      pre_mem_address_idle_cycles >= 0;
      pre_mem_address_idle_cycles < 10;

      pre_final_offset_idle_cycles >= 0;
      pre_final_offset_idle_cycles < 10;
   }

   constraint address_constraints {

      base_address + final_offset < DDR4_ADDRESS_MAX;
   
   }*/
   function new(string name = "[name]]");
      super.new(name);

      base_address = 0;
      final_offset = 0;


      pre_mem_address_idle_cycles = 0;
      pre_final_offset_idle_cycles = 0;
   endfunction

   task body();
      create_idle_transaction($sformatf("%s - Pre-mem address Idle", description), pre_mem_address_idle_cycles);
      create_simple_write_transaction($sformatf("%s - Mem Address", description), DDR4_MEM_ADDRESS, base_address);


      create_idle_transaction($sformatf("%s - Pre-final offset Idle", description), pre_final_offset_idle_cycles);
      create_simple_write_transaction($sformatf("%s - Final Offset", description), DDR4_FINAL_OFFSET, final_offset);
   endtask
endclass

class ddr4_access_load_seed_seq_c #(REGFILE_BASE_ADDRESS) extends ddr4_access_persona_base_seq_c #(REGFILE_BASE_ADDRESS);
   `uvm_object_param_utils(ddr4_access_load_seed_seq_c #(REGFILE_BASE_ADDRESS))
   
   rand logic [31:0] seed;
   
   rand int pre_seed_idle_cycles;
   rand int pre_load_seed_idle_cycles;
   rand int post_load_seed_idle_cycles;

   function new(string name = "Poll DDR4 Busy");
      super.new(name);
      seed = 0;
      pre_seed_idle_cycles = 0;
      pre_load_seed_idle_cycles=0;
      post_load_seed_idle_cycles=0;
   endfunction

   task body();

      create_idle_transaction($sformatf("%s - Pre-seed Idle", description), pre_seed_idle_cycles);
      create_simple_write_transaction($sformatf("%s - Seed", description), DDR4_SEED_ADDRESS, seed);

      create_idle_transaction($sformatf("%s - Pre-load seed Idle", description), pre_load_seed_idle_cycles);
      create_simple_write_transaction($sformatf("%s - Assert Load Seed", description), PR_CONTROL_REGISTER, 2);

      create_idle_transaction($sformatf("%s - Post-load seed Idle", description), pre_load_seed_idle_cycles);
      create_simple_write_transaction($sformatf("%s - Deassert Load Seed", description), PR_CONTROL_REGISTER, 0);
   endtask

endclass

class ddr4_access_start_seq_c #(REGFILE_BASE_ADDRESS) extends ddr4_access_persona_base_seq_c #(REGFILE_BASE_ADDRESS);
   `uvm_object_param_utils(ddr4_access_start_seq_c #(REGFILE_BASE_ADDRESS))
   
   rand int pre_start_assert_idle_cycles;
   rand int post_start_assert_idle_cycles;
   rand int pre_start_deassert_idle_cycles;

   function new(string name = "Strobe Start sequence");
      super.new(name);
      pre_start_assert_idle_cycles = 0;
      post_start_assert_idle_cycles=0;
      pre_start_deassert_idle_cycles=0;
   endfunction

   task body();

      create_idle_transaction($sformatf("%s - Pre-start assert Idle", description), pre_start_assert_idle_cycles);
      create_simple_write_transaction($sformatf("%s - Start Assert", description), PR_CONTROL_REGISTER, 12);
      create_idle_transaction($sformatf("%s - Post-start assertIdle", description), post_start_assert_idle_cycles);

      create_idle_transaction($sformatf("%s - Pre-start deassert Idle", description), pre_start_deassert_idle_cycles);
      create_simple_write_transaction($sformatf("%s - Start Deassert", description), PR_CONTROL_REGISTER, 8);

   endtask
endclass

class ddr4_access_busy_seq_c #(REGFILE_BASE_ADDRESS) extends ddr4_access_persona_base_seq_c #(REGFILE_BASE_ADDRESS);
   `uvm_object_param_utils(ddr4_access_busy_seq_c #(REGFILE_BASE_ADDRESS))

   function new(string name = "Poll DDR4 Busy");
      super.new(name);
   endfunction

   virtual task body();
      logic [31:0] busy;

      busy = 1;
      fork : wait_busy_done
         begin
            while (busy[0] == 1'b1) begin
               create_idle_transaction($sformatf("%s - Pre-start deassert Idle", description), 100);
               create_simple_read_transaction_get_data($sformatf("%s - Poll for busy", description), DDR4_BUSY_REGISTER, busy);
            end
         end
         begin
            #5000ns `uvm_fatal("SEQ", "Busy exceeded time allowed")
            $finish;
         end
      join_any
      disable wait_busy_done;
   endtask
endclass

class ddr4_access_read_res_seq_c #(REGFILE_BASE_ADDRESS) extends ddr4_access_persona_base_seq_c #(REGFILE_BASE_ADDRESS);
   `uvm_object_param_utils(ddr4_access_read_res_seq_c #(REGFILE_BASE_ADDRESS))
   
   rand int pre_read_idle_cycles;

   function new(string name = "Strobe Start sequence");
      super.new(name);
      pre_read_idle_cycles = 0;
   endfunction

   task body();
      create_idle_transaction($sformatf("%s - Pre-start assert Idle", description), pre_read_idle_cycles);
      create_simple_read_transaction($sformatf("%s - Performance Counter[31:0]", description), PERFORMANCE_COUNTER);
   endtask
endclass

class basic_ddr4_access_seq_c #(parameter REGFILE_BASE_ADDRESS) extends uvm_object;
   `uvm_object_param_utils(basic_ddr4_access_seq_c #(REGFILE_BASE_ADDRESS))

   string description;
   
   bar4_avmm_pkg::bar4_avmm_sequencer_c bar4_sqr;
   
   ddr4_access_load_address_rand_seq_c #(REGFILE_BASE_ADDRESS) ddr4_access_load_address_rand_seq;
   ddr4_access_start_seq_c #(REGFILE_BASE_ADDRESS) ddr4_access_start_seq;
   ddr4_access_load_seed_seq_c #(REGFILE_BASE_ADDRESS) ddr4_access_load_seed_seq;
   ddr4_access_busy_seq_c #(REGFILE_BASE_ADDRESS) ddr4_access_busy_seq;
   ddr4_access_read_res_seq_c #(REGFILE_BASE_ADDRESS) ddr4_access_read_res_seq;

   function new(string name = "[name]");
      super.new(name);
      
      description = "";
   endfunction

   virtual task start();
      ddr4_access_load_address_rand_seq = ddr4_access_load_address_rand_seq_c#(REGFILE_BASE_ADDRESS)::type_id::create("ddr4_access_load_address_rand_seq");
      ddr4_access_start_seq = ddr4_access_start_seq_c#(REGFILE_BASE_ADDRESS)::type_id::create("ddr4_access_start_seq");
      ddr4_access_load_seed_seq = ddr4_access_load_seed_seq_c#(REGFILE_BASE_ADDRESS)::type_id::create("ddr4_access_load_seed_seq");
      ddr4_access_busy_seq = ddr4_access_busy_seq_c#(REGFILE_BASE_ADDRESS)::type_id::create("ddr4_access_busy_seq");
      ddr4_access_read_res_seq = ddr4_access_read_res_seq_c#(REGFILE_BASE_ADDRESS)::type_id::create("ddr4_access_read_res_seq");

      ddr4_access_load_address_rand_seq.description = description;
      ddr4_access_start_seq.description = description;
      ddr4_access_load_seed_seq.description = description;
      ddr4_access_busy_seq.description = description;
      ddr4_access_read_res_seq.description = description;

      // Perform the basic check for the basic ddr persona
      ddr4_access_load_seed_seq.seed=1;
      ddr4_access_load_seed_seq.pre_seed_idle_cycles=1;
      ddr4_access_load_seed_seq.pre_load_seed_idle_cycles=1;
      ddr4_access_load_seed_seq.post_load_seed_idle_cycles=1;
      ddr4_access_load_seed_seq.start(bar4_sqr);

      ddr4_access_load_address_rand_seq.base_address=0;
      ddr4_access_load_address_rand_seq.final_offset=100;
      ddr4_access_load_address_rand_seq.pre_mem_address_idle_cycles=1;
      ddr4_access_load_address_rand_seq.pre_final_offset_idle_cycles=1;
      ddr4_access_load_address_rand_seq.start(bar4_sqr);

      ddr4_access_start_seq.pre_start_assert_idle_cycles=1;
      ddr4_access_start_seq.post_start_assert_idle_cycles=1;
      ddr4_access_start_seq.pre_start_deassert_idle_cycles=1;
      ddr4_access_start_seq.start(bar4_sqr);

      ddr4_access_busy_seq.start(bar4_sqr);

      ddr4_access_read_res_seq.pre_read_idle_cycles=1;
      ddr4_access_read_res_seq.start(bar4_sqr);
   endtask
endclass

typedef basic_ddr4_access_seq_c#(bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_BASE_ADDRESS) basic_ddr4_access_region0_seq_c;
typedef basic_ddr4_access_seq_c#(bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_0_BASE_ADDRESS) basic_ddr4_access_pr_parent_child0_seq_c;
typedef basic_ddr4_access_seq_c#(bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_1_BASE_ADDRESS) basic_ddr4_access_pr_parent_child1_seq_c;


`endif 

