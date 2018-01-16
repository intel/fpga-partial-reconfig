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


`ifndef INC_BASIC_DSP_SEQUENCE_LIB_SV
`define INC_BASIC_DSP_SEQUENCE_LIB_SV

class basic_dsp_persona_base_seq_c extends persona_base_seq_c;
   `uvm_object_utils(basic_dsp_persona_base_seq_c)

   localparam OPERAND_X_ADDRESS = PR_REGION_0_HOST_TO_PR_0_ADDRESS;
   localparam OPERAND_Y_ADDRESS = PR_REGION_0_HOST_TO_PR_1_ADDRESS;
   localparam RESULT_ADDRESS_0 = PR_REGION_0_PR_TO_HOST_0_ADDRESS;
   localparam RESULT_ADDRESS_1 = PR_REGION_0_PR_TO_HOST_1_ADDRESS;   

   function new(string name = "[name]");
      super.new(name);
   endfunction

endclass

 class basic_dsp_rand_seq_c extends basic_dsp_persona_base_seq_c;
   `uvm_object_utils(basic_dsp_rand_seq_c)

   rand logic [26:0] operand_x;
   rand logic [26:0] operand_y;

   rand int pre_operand_idle_cycles;
   rand int pre_result_idle_cycles;
   rand int post_result_idle_cycles;

   constraint reasonable_cycle_limits {
      pre_operand_idle_cycles >= 0;
      pre_operand_idle_cycles < 10;

      pre_result_idle_cycles >= 1;
      pre_result_idle_cycles < 10;

      post_result_idle_cycles >= 0;
      post_result_idle_cycles < 10;
   }

   function new(string name = "[name]");
      super.new(name);

      operand_x = 0;
      operand_y = 0;

      pre_operand_idle_cycles = 0;
      pre_result_idle_cycles = 1;
      post_result_idle_cycles = 0;

   endfunction

   task body();
      create_idle_transaction($sformatf("%s - Pre-operand Idle", description), pre_operand_idle_cycles);
      create_simple_write_transaction($sformatf("%s - Operand X", description), OPERAND_X_ADDRESS, {5'b0, operand_x});
      create_simple_write_transaction($sformatf("%s - Operand Y", description), OPERAND_Y_ADDRESS, {5'b0, operand_y});

      create_idle_transaction($sformatf("%s - Pre-result Idle", description), pre_result_idle_cycles);
      create_simple_read_transaction($sformatf("%s - Result[31:0]", description), RESULT_ADDRESS_0);
      create_simple_read_transaction($sformatf("%s - Result[63:32]", description), RESULT_ADDRESS_1);
      create_idle_transaction($sformatf("%s - Post-result Idle", description), post_result_idle_cycles);
   endtask

 endclass


class basic_dsp_single_seq_c extends basic_dsp_rand_seq_c;
   `uvm_object_utils(basic_dsp_single_seq_c)

   constraint constant_parameters {
      operand_x == 5;
      operand_y == 2;

      pre_operand_idle_cycles == 1;
      pre_result_idle_cycles == 1;
      post_result_idle_cycles == 0;
   }

   function new(string name = "[name]");
      super.new(name);

      description = "Basic DSP const params";
   endfunction

endclass


class basic_dsp_simple_seq_c extends basic_dsp_persona_base_seq_c;
   `uvm_object_utils(basic_dsp_simple_seq_c)

   int num_rand_seq;

   function new(string name = "[name]");
      super.new(name);

      description = "Basic DSP simple seq";

      num_rand_seq = 1;
   endfunction

   virtual task body();
      basic_dsp_rand_seq_c rand_seq = basic_dsp_rand_seq_c::type_id::create("rand_seq");

      `uvm_info("SEQ", $sformatf("Starting generator %s - %s", get_name(), description), UVM_LOW);

      // Generate transactions
      read_persona_id_block_until_response($sformatf("%s - Read persona ID", description));

      for(int i = 0; i < num_rand_seq; i = i+1) begin
         `altr_assert(rand_seq.randomize() with {pre_operand_idle_cycles == 0; pre_result_idle_cycles == 1; post_result_idle_cycles == 0;});
         rand_seq.description = $sformatf("%s rand iter %0d", description, i);
         rand_seq.start(m_sequencer);
      end

      read_persona_id_block_until_response($sformatf("%s - Read persona ID", description));
   endtask

endclass

class basic_dsp_rand_avmm_single_seq_c extends basic_dsp_persona_base_seq_c;
   `uvm_object_utils(basic_dsp_rand_avmm_single_seq_c)

   rand avalon_mm_pkg::Request_t request;
   rand logic [31:0] data;
   rand logic [8:0] address; // Persona address space is 9bits in the persona reg file
   rand int num_idle;

   constraint valid_address {
      (request == avalon_mm_pkg::REQ_IDLE) -> address == 0;
    (request == avalon_mm_pkg::REQ_READ) -> address inside {PR_REGION_0_PERSONA_ID_ADDRESS, RESULT_ADDRESS_0, RESULT_ADDRESS_1, OPERAND_X_ADDRESS, OPERAND_Y_ADDRESS};
//      (request == avalon_mm_pkg::REQ_READ) -> address inside {[0:9'h11f]}; KALEN HACK: Scoreboard model does not completely model all registers
    (request == avalon_mm_pkg::REQ_WRITE) -> address inside {PR_REGION_0_PERSONA_ID_ADDRESS, RESULT_ADDRESS_0, RESULT_ADDRESS_1, OPERAND_X_ADDRESS, OPERAND_Y_ADDRESS};
//      (request == avalon_mm_pkg::REQ_WRITE) -> address inside {[0:9'h11f]};
      address % 4 == 0;
   }

   constraint solve_request_before_address {
      solve request before address;
   }

   constraint valid_idle_delay {
      num_idle >= 0;
      num_idle < 10;
   }


   function new(string name = "[name]");
      super.new(name);

      description = "Basic DSP simple avmm";
   endfunction

   virtual task body();
      if (request == avalon_mm_pkg::REQ_READ) begin
         create_simple_read_transaction(description, address);
      end
      else if (request == avalon_mm_pkg::REQ_WRITE) begin
         create_simple_write_transaction(description, address, data);
      end
      else if (request == avalon_mm_pkg::REQ_IDLE) begin
         create_idle_transaction(description, num_idle);
      end

   endtask
endclass

class basic_dsp_rand_avmm_seq_c extends basic_dsp_persona_base_seq_c;
   `uvm_object_utils(basic_dsp_rand_avmm_seq_c)

   int num_rand_seq;

   function new(string name = "[name]");
      super.new(name);

      description = "Basic DSP rand avmm seq";

      num_rand_seq = 1;
   endfunction

   virtual task body();
      basic_dsp_rand_avmm_single_seq_c rand_seq = basic_dsp_rand_avmm_single_seq_c::type_id::create("rand_seq");

      `uvm_info("SEQ", $sformatf("Starting generator %s - %s", get_name(), description), UVM_LOW);

      // Generate transactions
      read_persona_id_block_until_response($sformatf("%s - Read persona ID", description));

      for(int i = 0; i < num_rand_seq; i = i+1) begin
         `altr_assert(rand_seq.randomize());
         rand_seq.description = $sformatf("%s rand iter %0d", description, i);
         rand_seq.start(m_sequencer);
      end

      read_persona_id_block_until_response($sformatf("%s - Read persona ID", description));
   endtask

endclass

`endif //INC_PR_REGION_SEQUENCE_LIB_SV
