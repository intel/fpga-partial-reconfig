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

`ifndef INC_AVMM_MONITOR_SV
`define INC_AVMM_MONITOR_SV

class avmm_monitor_c
#(
  ////////////////////////////////////////////////////////////////////
  // NOTE: These parameters must be overridden in the concrete class
  ////////////////////////////////////////////////////////////////////
  parameter type CMD_T = avmm_command_seq_item_c,
  parameter type RSP_T = avmm_response_seq_item_c,
  parameter type BFM_TYPE = virtual altera_avalon_mm_monitor_iface,
  int AV_ADDRESS_W = -1,
  int AV_DATA_W = -1,
  int USE_BURSTCOUNT = -1,
  int AV_BURSTCOUNT_W = -1,

  int AV_NUMSYMBOLS = -1,
  int AV_READRESPONSE_W = -1,
  int AV_WRITERESPONSE_W = -1,

  int USE_WRITE_RESPONSE = -1,
  int USE_READ_RESPONSE = -1
  ////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////
 ) extends uvm_monitor;

   `uvm_component_param_utils(avmm_monitor_c #(CMD_T, RSP_T, BFM_TYPE, AV_ADDRESS_W, AV_DATA_W, USE_BURSTCOUNT, AV_BURSTCOUNT_W, AV_NUMSYMBOLS, AV_READRESPONSE_W, AV_WRITERESPONSE_W, USE_WRITE_RESPONSE, USE_READ_RESPONSE))

   BFM_TYPE mm_monitor;

   uvm_analysis_port #(CMD_T) upstream_command_port;

   uvm_analysis_port #(CMD_T) command_aport;
   uvm_analysis_port #(RSP_T) response_aport;

   function new(string name = "Monitor", uvm_component parent);
      super.new(name, parent);

      command_aport = new("command_aport", this);
      response_aport = new("response_aport", this);

      upstream_command_port = new("upstream_command_port", this);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);

   endfunction

   task run_phase(uvm_phase phase);
      super.run_phase(phase);

      `uvm_info("mon", $sformatf("Starting monitor %s", get_full_name()), UVM_LOW);

      initialize();

      fork
         sample_commands();
         sample_responses();
      join_none

   endtask

   virtual task sample_commands();
      CMD_T tr;

      // Monitor commands
      forever begin
         `uvm_info("avmm_mon", "Waiting for command received", UVM_DEBUG);
         @(mm_monitor.bfm.monitor_trans.signal_command_received);
         `uvm_info("avmm_mon", "Received signal_command_received", UVM_DEBUG);

         mm_monitor.bfm.monitor_trans.pop_command();
         if (mm_monitor.bfm.monitor_trans.get_command_address() > 45) begin
            mm_monitor.bfm.monitor_trans.set_command_transaction_mode(1);
         end

         tr = CMD_T::type_id::create("client_command");

         tr.request        = avalon_mm_pkg::Request_t'(mm_monitor.bfm.monitor_trans.get_command_request());
         tr.address        = mm_monitor.bfm.monitor_trans.get_command_address();
         tr.burst_count    = mm_monitor.bfm.monitor_trans.get_command_burst_count();

         for (int i = 0; i < tr.burst_count; i++) begin
            tr.data[i] = mm_monitor.bfm.monitor_trans.get_command_data(.index(i));
            tr.byte_enable[i] = mm_monitor.bfm.monitor_trans.get_command_byte_enable(.index(i));
            tr.wait_seq[i] = mm_monitor.bfm.monitor_trans.get_command_wait_sequence(.index(i));
         end

         tr.burst_cycle    = mm_monitor.bfm.monitor_trans.get_command_burst_cycle();
         tr.arbiterlock    = mm_monitor.bfm.monitor_trans.get_command_arbiterlock();
         tr.lock           = mm_monitor.bfm.monitor_trans.get_command_lock();
         tr.debugaccess    = mm_monitor.bfm.monitor_trans.get_command_debugaccess();
         tr.transaction_id = mm_monitor.bfm.monitor_trans.get_command_transaction_id();
         tr.begin_time = mm_monitor.bfm.monitor_trans.get_command_begin_time();

         // Update with expected metadata
         upstream_command_port.write(tr);

         `uvm_info("mon_cmd", tr.convert2string(), UVM_HIGH);
         `uvm_info("mon_cmd", $sformatf("Item\n%s", tr.sprint()), UVM_HIGH);

         command_aport.write(tr);
      end
   endtask

   virtual task sample_responses();
      RSP_T tr;

      // Monitor responses
      forever begin
         `uvm_info("avmm_mon", "Waiting for command responses", UVM_DEBUG);
         @(mm_monitor.bfm.monitor_trans.signal_response_complete);
         `uvm_info("avmm_mon", "Received signal_response_complete", UVM_DEBUG);

         mm_monitor.bfm.monitor_trans.pop_response();

         `uvm_info("avmm_mon", $sformatf("Creating transaction for monitored response"), UVM_DEBUG);

         tr = RSP_T::type_id::create("client_response");

         tr.request        = mm_monitor.bfm.monitor_trans.get_response_request();
         tr.address        = mm_monitor.bfm.monitor_trans.get_response_address();
         // Burst count and burst size are the same for the response
         tr.burst_count    = mm_monitor.bfm.monitor_trans.get_response_burst_size();
         tr.burst_size     = mm_monitor.bfm.monitor_trans.get_response_burst_size();

         tr.begin_time = mm_monitor.bfm.monitor_trans.get_response_begin_time();
         tr.end_time = mm_monitor.bfm.monitor_trans.get_response_end_time();

         if (tr.request == avalon_mm_pkg::REQ_WRITE) begin
            `uvm_info("avmm_mon", $sformatf("Request = WRITE"), UVM_DEBUG);

            tr.write_id       = mm_monitor.bfm.monitor_trans.get_response_write_id();
            tr.read_id       = 'x;

            if (USE_WRITE_RESPONSE) begin
               tr.write_response     = mm_monitor.bfm.monitor_trans.get_write_response_status();
            end else begin
               tr.write_response     = avalon_mm_pkg::AV_RESERVED;
            end

         end else if (tr.request == avalon_mm_pkg::REQ_READ) begin
            `uvm_info("avmm_mon", $sformatf("Request = READ"), UVM_DEBUG);

            tr.write_id       = 'x;
            tr.read_id        = mm_monitor.bfm.monitor_trans.get_response_read_id();
            tr.write_response     = avalon_mm_pkg::AV_RESERVED;
         end else if (tr.request == avalon_mm_pkg::REQ_IDLE) begin
            `uvm_info("avmm_mon", $sformatf("Request = IDLE"), UVM_DEBUG);
            tr.write_id       = 'x;
            tr.read_id        = 'x;
            tr.write_response = avalon_mm_pkg::AV_RESERVED;
         end

         `uvm_info("avmm_mon", $sformatf("Burst count = %0d", tr.burst_count) , UVM_DEBUG);
         for (int i = 0; i < tr.burst_count; i++) begin
            tr.data[i]             = mm_monitor.bfm.monitor_trans.get_response_data(.index(i));

            tr.data             = mm_monitor.bfm.monitor_trans.get_response_data(.index(i));
            `uvm_info("avmm_mon", $sformatf("Data[%0d] = 0x%0X", i, tr.data) , UVM_DEBUG);

            tr.byte_enable[i]      = mm_monitor.bfm.monitor_trans.get_response_byte_enable(.index(i));
            tr.read_latency[i]     = mm_monitor.bfm.monitor_trans.get_response_latency(.index(i));

            if (tr.request == avalon_mm_pkg::REQ_WRITE) begin
               tr.write_latency[i]   = mm_monitor.bfm.monitor_trans.get_response_latency(.index(i));
               tr.read_latency[i]    = 'x;
               tr.read_response[i]   = 'x;
            end else if (tr.request == avalon_mm_pkg::REQ_READ) begin
               if (USE_READ_RESPONSE) begin
                  tr.read_response[i]     = mm_monitor.bfm.monitor_trans.get_read_response_status(.index(i));
               end else begin
                  tr.read_response[i]     = 'x;
               end

               tr.write_latency[i]   = 'x;
               tr.read_latency[i]    = mm_monitor.bfm.monitor_trans.get_response_latency(.index(i));
               tr.write_response     = avalon_mm_pkg::AV_RESERVED;
            end

            tr.wait_latency[i]     = mm_monitor.bfm.monitor_trans.get_response_wait_time(.index(i));

         end

         `uvm_info("mon_rsp", tr.convert2string(), UVM_HIGH);
         `uvm_info("mon_rsp", $sformatf("Item\n%s", tr.sprint()), UVM_HIGH);

         response_aport.write(tr);
      end
   endtask

   virtual task initialize();
      mm_monitor.bfm.monitor_trans.init();
   endtask

endclass

`endif //INC_AVMM_MONITOR_SV
