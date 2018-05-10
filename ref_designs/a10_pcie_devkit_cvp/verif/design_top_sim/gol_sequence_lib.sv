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


`ifndef INC_GOL_SEQUENCE_LIB_SV
`define INC_GOL_SEQUENCE_LIB_SV

class gol_persona_base_seq_c extends  persona_base_seq_c;
   `uvm_object_utils(gol_persona_base_seq_c)

   localparam GOL_COUNTER_REG = PR_REGION_0_BASE_ADDRESS + 32'hA0;
   localparam GOL_TOP_START = PR_REGION_0_BASE_ADDRESS + 32'hB0;
   localparam GOL_BOT_START = PR_REGION_0_BASE_ADDRESS + 32'hC0;
   localparam GOL_BUSY_REG = PR_REGION_0_BASE_ADDRESS + 32'h20;
   localparam GOL_TOP_END = PR_REGION_0_BASE_ADDRESS + 32'h30;
   localparam GOL_BOT_END = PR_REGION_0_BASE_ADDRESS + 32'h40;
   localparam PR_CONTROL_REGISTER = PR_REGION_0_BASE_ADDRESS + 32'h10;
   localparam GOL_START_MASK = 1;
   function new(string name = "[name]]");
      super.new(name);
   endfunction

endclass

class gol_load_limit_rand_seq_c extends gol_persona_base_seq_c;
   `uvm_object_utils(gol_load_limit_rand_seq_c)

   rand logic [31:0] num_runs;

   rand int pre_num_runs_idle_cycles;

   /*constraint reasonable_cycle_limits {
   }*/

   function new(string name = "[name]]");
      super.new(name);

      num_runs = 0;
      pre_num_runs_idle_cycles = 0;
   endfunction

   task body();
      create_idle_transaction($sformatf("%s - Pre-limit Idle", description), pre_num_runs_idle_cycles);
      create_simple_write_transaction($sformatf("%s - Number of iterations", description), GOL_COUNTER_REG, num_runs);
   endtask
endclass

class gol_load_board_seq_c extends gol_persona_base_seq_c;
   `uvm_object_utils(gol_load_board_seq_c)
   
   rand logic [31:0] top_half_start;
   rand logic [31:0] bot_half_start;
   
   rand int pre_top_start_idle_cycles;
   rand int pre_bot_start_idle_cycles;

   function new(string name = "[name]]");
      super.new(name);
      top_half_start = 0;
      bot_half_start = 0;
      pre_top_start_idle_cycles=0;
      pre_bot_start_idle_cycles=0;
   endfunction

   task body();

      create_idle_transaction($sformatf("%s - Pre-top half start Idle", description), pre_top_start_idle_cycles);
      create_simple_write_transaction($sformatf("%s - Top Half Start", description), GOL_TOP_START, top_half_start);

      create_idle_transaction($sformatf("%s - Pre-bot half start Idle", description), pre_bot_start_idle_cycles);
      create_simple_write_transaction($sformatf("%s - Bot Half Start", description), GOL_BOT_START, bot_half_start);
   endtask

endclass

class gol_start_seq_c extends gol_persona_base_seq_c;
   `uvm_object_utils(gol_start_seq_c)
   
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
      create_simple_write_transaction($sformatf("%s - Start Assert", description), PR_CONTROL_REGISTER,2);
      create_idle_transaction($sformatf("%s - Post-start assertIdle", description), post_start_assert_idle_cycles);

      create_idle_transaction($sformatf("%s - Pre-start deassert Idle", description), pre_start_deassert_idle_cycles);
      create_simple_write_transaction($sformatf("%s - Start Deassert", description), PR_CONTROL_REGISTER, 0);

   endtask
endclass

class gol_busy_seq_c extends gol_persona_base_seq_c;
   `uvm_object_utils(gol_busy_seq_c)

   function new(string name = "Poll DDR4 Busy");
      super.new(name);
   endfunction

   virtual task body();
      logic [31:0] busy;

      busy = 1;
      fork : wait_busy_done
         begin
            while (busy[0] == 1'b1) begin
               create_simple_read_transaction_get_data($sformatf("%s - Poll for busy", description), GOL_BUSY_REG, busy);
            end
         end
         begin
            #500000 `uvm_fatal("SEQ", "Busy exceeded time allowed")
            $finish;
         end
      join_any
      disable wait_busy_done;
   endtask
endclass

class gol_read_res_seq_c extends gol_persona_base_seq_c;
   `uvm_object_utils(gol_read_res_seq_c)
   
   rand int pre_top_end_idle_cycles;
   rand int pre_bot_end_idle_cycles;

   function new(string name = "Strobe Start sequence");
      super.new(name);
      pre_top_end_idle_cycles = 0;
      pre_bot_end_idle_cycles = 0;
   endfunction

   task body();
      create_idle_transaction($sformatf("%s - Pre-top end read Idle", description), pre_top_end_idle_cycles);
      create_simple_read_transaction($sformatf("%s - Top Half Final[31:0]", description), GOL_TOP_END);
      create_idle_transaction($sformatf("%s - Pre-bot end read Idle", description), pre_bot_end_idle_cycles);
      create_simple_read_transaction($sformatf("%s - Bot Half Final[31:0]", description), GOL_BOT_END);
   endtask
endclass


`endif 
