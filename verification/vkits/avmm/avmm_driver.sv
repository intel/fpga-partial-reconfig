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

`ifndef INC_AVMM_DRIVER_SV
`define INC_AVMM_DRIVER_SV

`uvm_analysis_imp_decl(_upstream_metadata)

class avmm_driver_c
#(
  ////////////////////////////////////////////////////////////////////
  // NOTE: These parameters must be overridden in the concrete class
  ////////////////////////////////////////////////////////////////////
  parameter type T = avmm_command_seq_item_c,
  parameter type BFM_TYPE = virtual altera_avalon_mm_master_bfm_iface,
  int USE_BURSTCOUNT = -1,
  int AV_ADDRESS_W = -1,
  int AV_DATA_W = -1,
  int USE_WRITE_RESPONSE = -1,
  int USE_READ_RESPONSE = -1

  ////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////
 ) extends uvm_driver #(T);

   `uvm_component_param_utils(avmm_driver_c #(T, BFM_TYPE, USE_BURSTCOUNT, AV_ADDRESS_W, AV_DATA_W, USE_WRITE_RESPONSE, USE_READ_RESPONSE))

   ////////////////////////////////////////////////////////////////////
   // NOTE: These parameters can optionally be overridden
   ////////////////////////////////////////////////////////////////////
   int BFM_TIMEOUT = 5000;
   int BFM_DELAY = 1;
   int MAX_BFM_PENDING_COMMAND_QUEUE_SIZE = 10;
   ////////////////////////////////////////////////////////////////////

   typedef logic[AV_ADDRESS_W-1:0] address_t;
   typedef logic[AV_DATA_W-1:0] data_t;

   BFM_TYPE mm_master_bfm;

   mailbox #(T) cmd_expecting_rsp_queue;
   mailbox #(T) cmd_expecting_mon_metadata_queue;

   uvm_analysis_imp_upstream_metadata #(T, avmm_driver_c #(T, BFM_TYPE, USE_BURSTCOUNT, AV_ADDRESS_W, AV_DATA_W, USE_WRITE_RESPONSE, USE_READ_RESPONSE)) upstream_command_port;

   event signal_command_sent_to_bfm;

   function new(string name = "Driver", uvm_component parent);
      super.new(name, parent);

      cmd_expecting_rsp_queue = new();
      cmd_expecting_mon_metadata_queue = new();

      upstream_command_port = new("upstream_command_port", this);

   endfunction

   virtual task initialize();
      mm_master_bfm.bfm.set_idle_state_output_configuration(avalon_utilities_pkg::LOW);
      mm_master_bfm.bfm.set_response_timeout(BFM_TIMEOUT);
      mm_master_bfm.bfm.set_command_timeout(BFM_TIMEOUT);

      mm_master_bfm.bfm.init();
   endtask

   virtual task start_monitor_responses(uvm_phase phase);
      `uvm_info("drv", $sformatf("Starting driver %s", get_full_name()), UVM_HIGH);

      fork
         forever begin
            // Monitor the BFM and create response transations
            while (mm_master_bfm.bfm.get_response_queue_size() > 0) begin
               phase.raise_objection(this);
               pop_bfm_response_transaction();
               phase.drop_objection(this);
            end
            @mm_master_bfm.bfm.signal_response_complete;
         end
      join_none
   endtask

   virtual task start_monitor_commands(uvm_phase phase);
      fork
         forever begin
            // Monitor the BFM for command queue
            while (mm_master_bfm.bfm.get_command_pending_queue_size() > 0) begin
               phase.raise_objection(this);
               @mm_master_bfm.bfm.signal_command_issued;
               phase.drop_objection(this);
            end
            @signal_command_sent_to_bfm;
         end
      join_none
   endtask

   virtual task pop_bfm_response_transaction();
      T next_command;

      if (mm_master_bfm.bfm.get_response_queue_size() > 0) begin
         cmd_expecting_rsp_queue.get(next_command);

         next_command.response = new();
         mm_master_bfm.bfm.pop_response();

         next_command.response.request = avalon_mm_pkg::Request_t'(mm_master_bfm.bfm.get_response_request());
         next_command.response.address = mm_master_bfm.bfm.get_response_address();
         next_command.response.burst_size = mm_master_bfm.bfm.get_response_burst_size();

         for (int i = 0; i < next_command.response.burst_size; i++) begin
            next_command.response.data[i] = mm_master_bfm.bfm.get_response_data(i);
            next_command.response.byte_enable[i] = mm_master_bfm.bfm.get_response_byte_enable(i);
            next_command.response.wait_latency[i] = mm_master_bfm.bfm.get_response_wait_time(i);
         end

         if (next_command.response.request == avalon_mm_pkg::REQ_WRITE) begin
            next_command.response.write_latency = mm_master_bfm.bfm.get_response_latency(0);
            next_command.response.write_id = mm_master_bfm.bfm.get_response_write_id();
            if (USE_WRITE_RESPONSE == 1) begin
               // Write response only supported when enabled
               next_command.response.write_response = mm_master_bfm.bfm.get_write_response_status();
            end
         end else if (next_command.response.request == avalon_mm_pkg::REQ_READ) begin
            for (int i = 0; i < next_command.response.burst_size; i++) begin
               next_command.response.read_latency[i] = mm_master_bfm.bfm.get_response_latency(i);
            end
            next_command.response.read_id = mm_master_bfm.bfm.get_response_read_id();
         end

         `uvm_info("drv_rsp", "Observed command response", UVM_HIGH);
         `uvm_info("drv_rsp", next_command.response.convert2string(), UVM_HIGH);
         `uvm_info("drv_rsp", $sformatf("Item\n%s", next_command.response.sprint()), UVM_HIGH);

         next_command.trigger(T::RESP_COMPLETE_TRIGGER);
      end

   endtask

   task bfm_wait_if_busy;
      bfm_wait_till_no_pending_command;
      if (mm_master_bfm.bfm.command_issued_counter > 0) begin
         bfm_wait_till_transaction_completed;
      end
   endtask

   task bfm_wait_till_no_pending_command;
      int timeout_period = 0;

      `uvm_info("drv", $sformatf("Pending command queue = %0d", mm_master_bfm.bfm.get_command_pending_queue_size()), UVM_HIGH);
      while (mm_master_bfm.bfm.get_command_pending_queue_size() != 0) begin
         repeat (BFM_DELAY)
            @mm_master_bfm.bfm.cb1;
         if (timeout_period
                ++>= BFM_TIMEOUT) begin
            `uvm_error("drv", "Timeout when waiting for pending transaction")
         end
      end
   endtask

   task bfm_wait_till_transaction_completed;
      int timeout_period = 0;

      `uvm_info("drv", $sformatf("All transactions complete = %0d", mm_master_bfm.bfm.all_transactions_complete()), UVM_HIGH);
      while (mm_master_bfm.bfm.all_transactions_complete() != 1) begin
         repeat (BFM_DELAY)
            @mm_master_bfm.bfm.cb1;
         if (timeout_period
                ++>= BFM_TIMEOUT) begin
            `uvm_error("drv", "Timeout when waiting for pending transaction")
         end
      end
   endtask

   task bfm_push_transaction(input T tr);
      mm_master_bfm.bfm.set_command_request(tr.request);
      mm_master_bfm.bfm.set_command_address(tr.address);
      mm_master_bfm.bfm.set_command_burst_count(tr.burst_count);
      mm_master_bfm.bfm.set_command_burst_size(tr.burst_size);
      mm_master_bfm.bfm.set_command_init_latency(tr.init_latency);
      mm_master_bfm.bfm.set_command_debugaccess(tr.debugaccess);
      mm_master_bfm.bfm.set_command_transaction_id(tr.transaction_id);

      if (tr.request == avalon_mm_pkg::REQ_WRITE) begin
         for (int i = 0; i < tr.burst_count; i++) begin
            mm_master_bfm.bfm.set_command_data(tr.data[i], i);
            mm_master_bfm.bfm.set_command_byte_enable(tr.byte_enable[i], i);
         end
      end

      for (int i = 0; i < tr.burst_count; i++) begin
         mm_master_bfm.bfm.set_command_idle(tr.idle[i], i);
      end

      if (USE_BURSTCOUNT) begin
      end
      else begin
         // Arbiterlock only supported when not in burst mode
         mm_master_bfm.bfm.set_command_arbiterlock(tr.arbiterlock);
         // Lock only supported when not in burst mode
         mm_master_bfm.bfm.set_command_lock(tr.lock);
      end

      // If there are too many pending commands, then wait
      while (mm_master_bfm.bfm.get_command_pending_queue_size() > MAX_BFM_PENDING_COMMAND_QUEUE_SIZE) begin
         `uvm_info("drv_cmd", $sformatf("BFM pending command queue = %0d, wating until queue < %0d", mm_master_bfm.bfm.get_command_pending_queue_size(), MAX_BFM_PENDING_COMMAND_QUEUE_SIZE), UVM_HIGH);
         @(mm_master_bfm.bfm.signal_command_issued);
      end

      `uvm_info("drv_cmd", "Pushing command to BFM", UVM_HIGH);
      `uvm_info("drv_cmd", tr.convert2string(), UVM_HIGH);
      `uvm_info("drv_cmd", $sformatf("Item\n%s", tr.sprint()), UVM_HIGH);

      mm_master_bfm.bfm.push_command();
      -> signal_command_sent_to_bfm;

      // Track responses for read and write transactions
      if ((tr.request == avalon_mm_pkg::REQ_WRITE) || (tr.request == avalon_mm_pkg::REQ_READ)) begin
         cmd_expecting_rsp_queue.put(tr);
      end

      // Track read/write for annotation of metadata on monitored commands
      if ((tr.request == avalon_mm_pkg::REQ_WRITE) || (tr.request == avalon_mm_pkg::REQ_READ)) begin
         cmd_expecting_mon_metadata_queue.put(tr);
      end

      endtask

   task run_phase(uvm_phase phase);
      T cur_trans;

      initialize();
      start_monitor_commands(phase);
      start_monitor_responses(phase);

      forever begin
         // Get the next transaction. This is a blocking call
         seq_item_port.get_next_item(cur_trans);

         phase.raise_objection(this);

         // Process the transaction
         drive_transaction(cur_trans);

         // Pop it off the queue now that we are done with it
         seq_item_port.item_done();

         phase.drop_objection(this);
      end

   endtask

   virtual task drive_transaction(T cur_trans);
      data_t read_data;

      `uvm_info("drv", $sformatf("Preparing to drive transaction: %s", cur_trans.convert2string()), UVM_HIGH)
      bfm_push_transaction(cur_trans);

   endtask

   // Upstream write
   virtual task write_upstream_metadata(T tr);
      T exp_tr;

      if (cmd_expecting_mon_metadata_queue.try_get(exp_tr)) begin
         if (tr.compare(exp_tr)) begin
            `uvm_info("drv", "Updating metadata for monitored command", UVM_HIGH)
            do_write_metadata(exp_tr, tr);
         end
         else begin
            `uvm_error("drv", "Expected command did not match monitored command")
        end
      end
   endtask


   virtual function do_write_metadata(T driven_tr, T monitored_tr);
      //monitored_tr.uid = driven_tr.uid;
      monitored_tr.description = driven_tr.description;
   endfunction


endclass

`endif //INC_AVMM_DRIVER_SV
