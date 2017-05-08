// Copyright (c) 2001-2017 Intel Corporation
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

`ifndef INC_CRA_TRANSACTION_GENERATOR_SV
`define INC_CRA_TRANSACTION_GENERATOR_SV

// main test
// contains contrained-random tests

class cra_transaction_generator extends uvm_sequence #(bar4_avmm_pkg::bar4_avmm_command_seq_item);
   `uvm_object_utils(cra_transaction_generator)

   function new(string name = "Stimulus Generator");
      super.new(name);
   endfunction

   task create_idle_transaction(int num_transaction = 1);
      REQ tr;

      `altr_assert(num_transaction > 0)

      for (int i = 0; i < num_transaction; i = i + 1)  begin
         tr = REQ::type_id::create("tr");

         start_item(tr);
         tr.request = avalon_mm_pkg::REQ_IDLE;
         tr.data = 1;
         tr.burst_count = 1;
         tr.burst_size = 1;
         finish_item(tr);
      end

   endtask

endclass


class pr_region_ctrl_seq extends cra_transaction_generator;
   `uvm_object_utils(pr_region_ctrl_seq)

   function new(string name = "pr_region_ctrl_seq");
      super.new(name);
   endfunction

   task freeze_region();
      bar4_avmm_pkg::bar4_avmm_command_seq_item cur_trans;
      cur_trans = bar4_avmm_pkg::bar4_avmm_command_seq_item::type_id::create("cur_trans");

      start_item(cur_trans);
      cur_trans.request = avalon_mm_pkg::REQ_WRITE;
      cur_trans.address = 32'h4000 + (32'h1 << 2);
      cur_trans.data = 1;
      cur_trans.burst_count = 1;
      cur_trans.burst_size = 1;
      finish_item(cur_trans);
   endtask

   task reset_region();
      bar4_avmm_pkg::bar4_avmm_command_seq_item cur_trans;
      cur_trans = bar4_avmm_pkg::bar4_avmm_command_seq_item::type_id::create("cur_trans");

      start_item(cur_trans);
      cur_trans.request = avalon_mm_pkg::REQ_WRITE;
      cur_trans.address = 32'h4000 + (32'h1 << 2);
      cur_trans.data = 2;
      cur_trans.burst_count = 1;
      cur_trans.burst_size = 1;
      finish_item(cur_trans);
   endtask

   task unfreeze_region();
      bar4_avmm_pkg::bar4_avmm_command_seq_item cur_trans;
      cur_trans = bar4_avmm_pkg::bar4_avmm_command_seq_item::type_id::create("cur_trans");

      start_item(cur_trans);
      cur_trans.request = avalon_mm_pkg::REQ_WRITE;
      cur_trans.address = 32'h4000 + (32'h1 << 2);
      cur_trans.data = 4;
      cur_trans.burst_count = 1;
      cur_trans.burst_size = 1;
      finish_item(cur_trans);
   endtask
endclass

class pr_region0_region_ctrl_freeze_seq extends pr_region_ctrl_seq;
   `uvm_object_utils(pr_region0_region_ctrl_freeze_seq)

   function new(string name = "pr_region0_region_ctrl_freeze_seq");
      super.new(name);
   endfunction

   virtual task body();
      freeze_region();
   endtask

endclass

class pr_region0_region_ctrl_reset_seq extends pr_region_ctrl_seq;
   `uvm_object_utils(pr_region0_region_ctrl_reset_seq)

   function new(string name = "pr_region0_region_ctrl_reset_seq");
      super.new(name);
   endfunction

   virtual task body();
      reset_region();
   endtask

endclass

class pr_region0_region_ctrl_unfreeze_seq extends pr_region_ctrl_seq;
   `uvm_object_utils(pr_region0_region_ctrl_unfreeze_seq)

   function new(string name = "pr_region0_region_ctrl_unfreeze_seq");
      super.new(name);
   endfunction

   virtual task body();
      unfreeze_region();
   endtask

endclass

class basic_arithmetic_transaction_generator extends cra_transaction_generator;
   `uvm_object_utils(basic_arithmetic_transaction_generator)

   function new(string name = "Stimulus Generator 1");
      super.new(name);
   endfunction

   virtual task body();
      verbosity_pkg::print(VERBOSITY_INFO, $sformatf("Starting generator %s", get_full_name()));

      // Generate transactions
      read_pr_id(32'h000000d2);
      basic_arith(0, 0, 0);
      basic_arith(1, 1, 2);
      read_pr_id(32'h000000d2);
   endtask

   task read_pr_id(int expected_persona_id);
      bar4_avmm_pkg::bar4_avmm_command_seq_item cur_trans;
      cur_trans = bar4_avmm_pkg::bar4_avmm_command_seq_item::type_id::create("cur_trans");

      start_item(cur_trans);
      cur_trans.request = avalon_mm_pkg::REQ_READ;
      cur_trans.address = 0;
      cur_trans.burst_count = 1;
      cur_trans.burst_size = 1;
      finish_item(cur_trans);

      fork : wait_queues_write begin
            // Block until response recieved
            cur_trans.wait_trigger(bar4_avmm_pkg::bar4_avmm_command_seq_item::RESP_COMPLETE_TRIGGER);
         end
         begin
            #10000 `uvm_fatal("SEQ", "Response for read never recieved")
            $finish;

         end
      join_any
      disable wait_queues_write;
   endtask

   task basic_arith(int operand, int increment, int expected_result);
      bar4_avmm_pkg::bar4_avmm_command_seq_item operand_trans;
      bar4_avmm_pkg::bar4_avmm_command_seq_item increment_trans;
      bar4_avmm_pkg::bar4_avmm_command_seq_item result_trans;

      operand_trans = bar4_avmm_pkg::bar4_avmm_command_seq_item::type_id::create("operand_trans");
      increment_trans = bar4_avmm_pkg::bar4_avmm_command_seq_item::type_id::create("increment_trans");
      result_trans = bar4_avmm_pkg::bar4_avmm_command_seq_item::type_id::create("result_trans");

      start_item(operand_trans);
      operand_trans.request = avalon_mm_pkg::REQ_WRITE;
      operand_trans.address = 32'hA0;
      operand_trans.data = operand;
      operand_trans.burst_count = 1;
      operand_trans.burst_size = 1;
      finish_item(operand_trans);

      start_item(increment_trans);
      increment_trans.request = avalon_mm_pkg::REQ_WRITE;
      increment_trans.address = 32'hB0;
      increment_trans.data = increment;
      increment_trans.burst_count = 1;
      increment_trans.burst_size = 1;
      finish_item(increment_trans);

      start_item(result_trans);
      result_trans.request = avalon_mm_pkg::REQ_READ;
      result_trans.address = 32'h20;
      result_trans.burst_count = 1;
      result_trans.burst_size = 1;
      finish_item(result_trans);
   endtask

endclass

class ddr4_access_transaction_generator extends cra_transaction_generator;
   `uvm_object_utils(ddr4_access_transaction_generator)

   function new(string name = "Stimulus Generator 1");
      super.new(name);
   endfunction

   virtual task body();
      verbosity_pkg::print(VERBOSITY_INFO, $sformatf("Starting generator %s", get_full_name()));

      // Generate transactions
      read_pr_id(32'h000000ef);
      ddr4_test(0, 15);
      ddr4_test(0, 1023);
      ddr4_test(16, 15);

   endtask

   task read_pr_id(int expected_persona_id);
      bar4_avmm_pkg::bar4_avmm_command_seq_item cur_trans;
      cur_trans = bar4_avmm_pkg::bar4_avmm_command_seq_item::type_id::create("cur_trans");

      start_item(cur_trans);
      cur_trans.request = avalon_mm_pkg::REQ_READ;
      cur_trans.address = 0;
      cur_trans.burst_count = 1;
      cur_trans.burst_size = 1;
      finish_item(cur_trans);
   endtask

   task ddr4_test(int mem_address, int final_address);
      bar4_avmm_pkg::bar4_avmm_command_seq_item mem_address_trans;
      bar4_avmm_pkg::bar4_avmm_command_seq_item write_final_address;
      bar4_avmm_pkg::bar4_avmm_command_seq_item load_parameter_trans;
      bar4_avmm_pkg::bar4_avmm_command_seq_item result_trans;

      perform_host_cntrl_reset();

      mem_address_trans = bar4_avmm_pkg::bar4_avmm_command_seq_item::type_id::create("cur_trans");
      start_item(mem_address_trans);
      mem_address_trans.request = avalon_mm_pkg::REQ_WRITE;
      mem_address_trans.address = 32'hA0;
      mem_address_trans.data = mem_address;
      mem_address_trans.burst_count = 1;
      mem_address_trans.burst_size = 1;
      finish_item(mem_address_trans);


      write_final_address = bar4_avmm_pkg::bar4_avmm_command_seq_item::type_id::create("cur_trans");
      start_item(write_final_address);
      write_final_address.request = avalon_mm_pkg::REQ_WRITE;
      write_final_address.address = 32'hC0;
      write_final_address.data = final_address + mem_address;
      write_final_address.burst_count = 1;
      write_final_address.burst_size = 1;
      finish_item(write_final_address);

      load_parameter_trans = bar4_avmm_pkg::bar4_avmm_command_seq_item::type_id::create("cur_trans");
      start_item(load_parameter_trans);
      load_parameter_trans.request = avalon_mm_pkg::REQ_WRITE;
      load_parameter_trans.address = 32'h10;
      load_parameter_trans.data = (32'b0 | {1'b1, 1'b1, 1'b0, 1'b0});
      load_parameter_trans.burst_count = 1;
      load_parameter_trans.burst_size = 1;
      finish_item(load_parameter_trans);

      repeat (100000)
         @(posedge `TB.tb_clk);

      result_trans = bar4_avmm_pkg::bar4_avmm_command_seq_item::type_id::create("cur_trans");
      start_item(result_trans);
      result_trans.request = avalon_mm_pkg::REQ_READ;
      result_trans.address = 32'h30;
      result_trans.burst_count = 1;
      result_trans.burst_size = 1;
      finish_item(result_trans);

   endtask


   task perform_host_cntrl_reset();
      deassert_host_cntrl_reset();
      repeat (10)
         @(posedge `TB.tb_clk);
      assert_host_cntrl_reset();
      repeat (10)
         @(posedge `TB.tb_clk);
      deassert_host_cntrl_reset();
   endtask

   task assert_host_cntrl_reset();
      bar4_avmm_pkg::bar4_avmm_command_seq_item cur_trans;

      cur_trans = bar4_avmm_pkg::bar4_avmm_command_seq_item::type_id::create("cur_trans");
      start_item(cur_trans);
      cur_trans.request = avalon_mm_pkg::REQ_WRITE;
      cur_trans.address = 32'h10;
      cur_trans.data = 32'h1;
      cur_trans.burst_count = 1;
      cur_trans.burst_size = 1;
      finish_item(cur_trans);
   endtask

   task deassert_host_cntrl_reset();
      bar4_avmm_pkg::bar4_avmm_command_seq_item cur_trans;

      cur_trans = bar4_avmm_pkg::bar4_avmm_command_seq_item::type_id::create("cur_trans");
      start_item(cur_trans);
      cur_trans.request = avalon_mm_pkg::REQ_WRITE;
      cur_trans.address = 32'h10;
      cur_trans.data = 32'h0;
      cur_trans.burst_count = 1;
      cur_trans.burst_size = 1;
      finish_item(cur_trans);
   endtask

endclass

`endif //INC_CRA_TRANSACTION_GENERATOR_SV
