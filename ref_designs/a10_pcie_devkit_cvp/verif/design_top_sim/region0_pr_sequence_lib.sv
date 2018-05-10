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

`ifndef INC_REGION0_PR_SEQUENCE_LIB_SV
`define INC_REGION0_PR_SEQUENCE_LIB_SV

class region0_stop_req_seq_c extends bar4_avmm_pkg::bar4_avmm_base_seq_c;
   `uvm_object_utils(region0_stop_req_seq_c)

   function new(string name = "[name]");
      super.new(name);
   endfunction

   task body();
      logic [31:0] data;

      // Read the region controller version
      create_simple_read_transaction($sformatf("%s - Read region controller version", description), PR_REGION_0_REGION_CTRL_SWVERSION);

      // Issue stop request to the region controller
      create_simple_write_transaction($sformatf("%s - Request stop req", description), PR_REGION_0_REGION_CTRL_CTRL, 32'h_0001);

      // Poll until freeze granted
      data = 0;
      fork : wait_freeze_granted
         begin
            while (data[0] != 1'b1) begin
               create_simple_read_transaction_get_data($sformatf("%s - Poll for freeze granted", description), PR_REGION_0_REGION_CTRL_STATUS, data);
            end
         end
         begin
            #100000 `uvm_fatal("SEQ", "Freeze not granted within time allowed")
            $finish;
         end
      join_any
      disable wait_freeze_granted;

   endtask

endclass

class region0_start_req_seq_c extends bar4_avmm_pkg::bar4_avmm_base_seq_c;
   `uvm_object_utils(region0_start_req_seq_c)

   function new(string name = "[name]");
      super.new(name);
   endfunction

   task body();
      logic [31:0] data;

      // Read the region controller version
      create_simple_read_transaction($sformatf("%s - Read region controller version", description), PR_REGION_0_REGION_CTRL_SWVERSION);

      // Issue start request to the region controller
      create_simple_write_transaction($sformatf("%s - Request start req", description), PR_REGION_0_REGION_CTRL_CTRL, 32'h_0004);

      // Poll until unfreeze granted
      data = 0;
      fork : wait_unfreeze_granted
         begin
            while (data[1] != 1'b1) begin
               create_simple_read_transaction_get_data($sformatf("%s - Poll for unfreeze granted", description), PR_REGION_0_REGION_CTRL_STATUS, data);
            end
         end
         begin
            #100000 `uvm_fatal("SEQ", "Freeze not granted within time allowed")
            $finish;
         end
      join_any
      disable wait_unfreeze_granted;

   endtask

endclass

class region0_assert_reset_seq_c extends bar4_avmm_pkg::bar4_avmm_base_seq_c;
   `uvm_object_utils(region0_assert_reset_seq_c)

   function new(string name = "[name]");
      super.new(name);
   endfunction

   task body();
      logic [31:0] data;

      // Issue reset assert to the region controller
      create_simple_write_transaction($sformatf("%s - Request start req", description), PR_REGION_0_REGION_CTRL_CTRL, 32'h_0002);

      // Issue a blocking read so that this sequence will not complete until reset is asserted
      create_simple_read_transaction_block_until_response($sformatf("%s - Read region controller version", description), PR_REGION_0_REGION_CTRL_SWVERSION);
   endtask

endclass

class region0_deassert_reset_seq_c extends bar4_avmm_pkg::bar4_avmm_base_seq_c;
   `uvm_object_utils(region0_deassert_reset_seq_c)

   function new(string name = "[name]");
      super.new(name);
   endfunction

   task body();
      // Issue reset deassert to the region controller
      create_simple_write_transaction($sformatf("%s - Request start req", description), PR_REGION_0_REGION_CTRL_CTRL, 32'h_0000);

      // Issue a blocking read so that this sequence will not complete until reset is deasserted
      create_simple_read_transaction_block_until_response($sformatf("%s - Read region controller version", description), PR_REGION_0_REGION_CTRL_SWVERSION);
endtask

endclass

class success_pr_seq_c extends bar2_avmm_pkg::bar2_avmm_base_seq_c;
   `uvm_object_utils(success_pr_seq_c)

   function new(string name = "[name]");
      super.new(name);
   endfunction

   task body();
      logic [31:0] data;

      // Read the PR IP version
      create_simple_read_transaction($sformatf("%s - Read PR IP version", description), PR_IP_VERSION_ADDRESS);

      // Read the PR POF ID
      create_simple_read_transaction($sformatf("%s - Read PR POF ID version", description), PR_IP_PR_POF_ID_ADDRESS);

      // Send the PR request to the IP
      create_simple_write_transaction($sformatf("%s - PR request", description), PR_IP_STATUS_ADDRESS, 32'h_0000_0001);

      // Poll until pr start
      data = 0;
      fork : wait_pr_start
         begin
            while (data[4:2] != 3'b100) begin
               create_simple_read_transaction_get_data($sformatf("%s - Poll for PR ready", description), PR_IP_STATUS_ADDRESS, data);
            end
         end
         begin
            #100000 `uvm_fatal("SEQ", "Freeze not granted within time allowed")
            $finish;
         end
      join_any
      disable wait_pr_start;

      // Send the RBF to the IP
      create_simple_write_transaction($sformatf("%s - PR Header", description), PR_IP_DATA_ADDRESS, 32'h_0000_A65C);
      create_simple_write_transaction($sformatf("%s - PR ID", description), PR_IP_DATA_ADDRESS, 32'h_0000_0001);
      create_simple_write_transaction($sformatf("%s - PR Data", description), PR_IP_DATA_ADDRESS, 32'h_0123_4567);
      create_simple_write_transaction($sformatf("%s - PR Data", description), PR_IP_DATA_ADDRESS, 32'h_89AB_CDEF);
      create_simple_write_transaction($sformatf("%s - PR Data", description), PR_IP_DATA_ADDRESS, 32'h_0246_8ACE);
      create_simple_write_transaction($sformatf("%s - PR Data", description), PR_IP_DATA_ADDRESS, 32'h_1357_9BDF);

      // Poll until success/fail
      data = 0;
      data[4:2] = 3'b100; // PR in progress
      fork : wait_pr_complete
         begin
            while (data[4:2] == 3'b100) begin
               create_simple_read_transaction_get_data($sformatf("%s - Poll for PR complete", description), PR_IP_STATUS_ADDRESS, data);
            end
         end
         begin
            #100000 `uvm_fatal("SEQ", "Freeze not granted within time allowed")
            $finish;
         end
      join_any
      disable wait_pr_complete;

   endtask


endclass

class error_pr_seq_c extends bar2_avmm_pkg::bar2_avmm_base_seq_c;
   `uvm_object_utils(error_pr_seq_c)

   function new(string name = "[name]");
      super.new(name);
   endfunction

   task body();
      logic [31:0] data;

      // Read the PR IP version
      create_simple_read_transaction($sformatf("%s - Read PR IP version", description), PR_IP_VERSION_ADDRESS);

      // Read the PR POF ID
      create_simple_read_transaction($sformatf("%s - Read PR POF ID version", description), PR_IP_PR_POF_ID_ADDRESS);

      // Send the PR request to the IP
      create_simple_write_transaction($sformatf("%s - PR request", description), PR_IP_STATUS_ADDRESS, 32'h_0000_0001);

      // Poll until pr start
      data = 0;
      fork : wait_pr_start
         begin
            while (data[4:2] != 3'b100) begin
               create_simple_read_transaction_get_data($sformatf("%s - Poll for PR ready", description), PR_IP_STATUS_ADDRESS, data);
            end
         end
         begin
            #100000 `uvm_fatal("SEQ", "Freeze not granted within time allowed")
            $finish;
         end
      join_any
      disable wait_pr_start;

      // Send the RBF to the IP. Because of a limitation in the scoreboard predictor, we need the 
      // error to be detected in the first word
      create_simple_write_transaction($sformatf("%s - PR Header", description), PR_IP_DATA_ADDRESS, 32'h_0000_CCCC);
      create_simple_write_transaction($sformatf("%s - PR ID", description), PR_IP_DATA_ADDRESS, 32'h_0000_0001);
      create_simple_write_transaction($sformatf("%s - PR Data", description), PR_IP_DATA_ADDRESS, 32'h_0123_4567);
      create_simple_write_transaction($sformatf("%s - PR Data", description), PR_IP_DATA_ADDRESS, 32'h_89AB_CDEF);
      create_simple_write_transaction($sformatf("%s - PR Data", description), PR_IP_DATA_ADDRESS, 32'h_0246_8ACE);
      create_simple_write_transaction($sformatf("%s - PR Data", description), PR_IP_DATA_ADDRESS, 32'h_1357_9BDF);

      // Poll until success/fail
      data = 0;
      data[4:2] = 3'b100; // PR in progress
      fork : wait_pr_complete
         begin
            while (data[4:2] == 3'b100) begin
               create_simple_read_transaction_get_data($sformatf("%s - Poll for PR complete", description), PR_IP_STATUS_ADDRESS, data);
            end
         end
         begin
            #100000 `uvm_fatal("SEQ", "Freeze not granted within time allowed")
            $finish;
         end
      join_any
      disable wait_pr_complete;

   endtask


endclass

//// Read the region controller version
//create_simple_read_transaction($sformatf("%s - Read region controller version", description), PR_REGION_0_REGION_CTRL_SWVERSION);
//
//// Issue stop request to the region controller
//create_simple_write_transaction($sformatf("%s - Request stop req", description), PR_REGION_0_REGION_CTRL_CTRL, 32'h_0001);
//
//// Poll until freeze granted
//data = 0;
//fork : wait_freeze_granted
//   begin
//      while (data[0] != 1'b1) begin
//         create_simple_read_transaction_get_data($sformatf("%s - Poll for freeze granted", description), PR_REGION_0_REGION_CTRL_STATUS, data);
//      end
//   end
//   begin
//      #100000 `uvm_fatal("SEQ", "Freeze not granted within time allowed")
//      $finish;
//   end
//join_any
//disable wait_freeze_granted;



class region0_success_pr_seq_c extends uvm_object;
   `uvm_object_utils(region0_success_pr_seq_c)

   int persona_select;
   bar4_avmm_pkg::bar4_avmm_sequencer_c bar4_sqr;
   bar2_avmm_pkg::bar2_avmm_sequencer_c bar2_sqr;
   pr_region_pkg::pr_region_sequencer_c region0_sqr;

   region0_stop_req_seq_c region0_stop_req_seq;
   region0_start_req_seq_c region0_start_req_seq;
   success_pr_seq_c success_pr_seq;
   region0_assert_reset_seq_c region0_assert_reset_seq;
   region0_deassert_reset_seq_c region0_deassert_reset_seq;

   pr_region_pkg::pr_region_assert_pr_to_persona_seq_c region0_pr_to_persona_seq;
   pr_region_pkg::pr_region_deassert_pr_seq_c region0_deassert_pr_seq;

   read_persona_id_seq_c region0_read_persona_id_seq;

   function new(string name = "[name]");
      super.new(name);

      persona_select = -1;

   endfunction

   task start();
      region0_stop_req_seq = region0_stop_req_seq_c::type_id::create("region0_stop_req_seq");
      region0_start_req_seq = region0_start_req_seq_c::type_id::create("region0_start_req_seq");
      success_pr_seq = success_pr_seq_c::type_id::create("success_pr_seq");
      region0_assert_reset_seq = region0_assert_reset_seq_c::type_id::create("region0_assert_reset_seq");
      region0_deassert_reset_seq = region0_deassert_reset_seq_c::type_id::create("region0_deassert_reset_seq");

      region0_pr_to_persona_seq = pr_region_pkg::pr_region_assert_pr_to_persona_seq_c::type_id::create("region0_pr_to_persona_seq");
      region0_deassert_pr_seq = pr_region_pkg::pr_region_deassert_pr_seq_c::type_id::create("region0_pr_to_persona_seq");

      region0_read_persona_id_seq = read_persona_id_seq_c::type_id::create("region0_read_persona_id_seq");

      // Initiate stop_req for the region
      region0_stop_req_seq.start(bar4_sqr);

      // Assert Reset to PR region
      region0_assert_reset_seq.start(bar4_sqr);

      // Send bitstream to PR IP
      success_pr_seq.start(bar2_sqr);

      //repeat (10) @ (posedge `TB.tb_clk);
      // KALEN HACK: Need some interface with time
      #1000;
      
//    region0_pr_to_persona_seq.persona_select = persona_select;
//    region0_pr_to_persona_seq.start(region0_sqr);

      // Do a dummy read to the PR persona
      //region0_read_persona_id_seq.start(bar4_sqr);

      // KALEN HACK: Need some interface with time
      #1000;
      //repeat (20) @ (posedge `TB.tb_clk);
      //region0_deassert_pr_seq.start(region0_sqr);

      // Deassert Reset to PR region
      region0_deassert_reset_seq.start(bar4_sqr);

      // Initiate start_req for the region
      region0_start_req_seq.start(bar4_sqr);

      // Do a dummy read to the PR persona
      region0_read_persona_id_seq.start(bar4_sqr);

   endtask
   endclass

   class region0_error_pr_seq_c extends uvm_object;
      `uvm_object_utils(region0_error_pr_seq_c)

      int persona_select;
      bar4_avmm_pkg::bar4_avmm_sequencer_c bar4_sqr;
      bar2_avmm_pkg::bar2_avmm_sequencer_c bar2_sqr;
      pr_region_pkg::pr_region_sequencer_c region0_sqr;

      region0_stop_req_seq_c region0_stop_req_seq;
      region0_start_req_seq_c region0_start_req_seq;
      error_pr_seq_c error_pr_seq;
      region0_assert_reset_seq_c region0_assert_reset_seq;
      region0_deassert_reset_seq_c region0_deassert_reset_seq;

      pr_region_pkg::pr_region_assert_pr_to_persona_seq_c region0_pr_to_persona_seq;
      pr_region_pkg::pr_region_deassert_pr_seq_c region0_deassert_pr_seq;

      read_persona_id_seq_c region0_read_persona_id_seq;

      function new(string name = "[name]");
         super.new(name);

         persona_select = -1;

      endfunction

      task start();
         region0_stop_req_seq = region0_stop_req_seq_c::type_id::create("region0_stop_req_seq");
         region0_start_req_seq = region0_start_req_seq_c::type_id::create("region0_start_req_seq");
         error_pr_seq = error_pr_seq_c::type_id::create("error_pr_seq");
         region0_assert_reset_seq = region0_assert_reset_seq_c::type_id::create("region0_assert_reset_seq");
         region0_deassert_reset_seq = region0_deassert_reset_seq_c::type_id::create("region0_deassert_reset_seq");

         region0_pr_to_persona_seq = pr_region_pkg::pr_region_assert_pr_to_persona_seq_c::type_id::create("region0_pr_to_persona_seq");
         region0_deassert_pr_seq = pr_region_pkg::pr_region_deassert_pr_seq_c::type_id::create("region0_pr_to_persona_seq");

         region0_read_persona_id_seq = read_persona_id_seq_c::type_id::create("region0_read_persona_id_seq");

         // Initiate stop_req for the region
         region0_stop_req_seq.start(bar4_sqr);

         // Assert Reset to PR region
         region0_assert_reset_seq.start(bar4_sqr);

         // Send bitstream to PR IP
         error_pr_seq.start(bar2_sqr);

         //repeat (10) @ (posedge `TB.tb_clk);
      // KALEN HACK: Need some interface with time
      #1000;
         
   //    region0_pr_to_persona_seq.persona_select = persona_select;
   //    region0_pr_to_persona_seq.start(region0_sqr);

         // Do a dummy read to the PR persona
         //region0_read_persona_id_seq.start(bar4_sqr);

         //repeat (20) @ (posedge `TB.tb_clk);
      // KALEN HACK: Need some interface with time
      #1000;
         
         //region0_deassert_pr_seq.start(region0_sqr);

   endtask

endclass

`endif //INC_REGION0_PR_SEQUENCE_LIB_SV
