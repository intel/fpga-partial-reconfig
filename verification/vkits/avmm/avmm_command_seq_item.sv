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

`ifndef INC_AVMM_COMMAND_SEQ_ITEM_SV
`define INC_AVMM_COMMAND_SEQ_ITEM_SV

class avmm_command_seq_item_c
#(
  ////////////////////////////////////////////////////////////////////
  // NOTE: These parameters must be overridden in the concrete class
  ////////////////////////////////////////////////////////////////////
  int AV_ADDRESS_W = -1,
  int AV_BURSTCOUNT_W = -1,
  int USE_BURSTCOUNT = -1,
  int AV_DATA_W = -1,
  int AV_NUMSYMBOLS = -1,
  int AV_READRESPONSE_W = -1,
  int AV_WRITERESPONSE_W = -1,
  int USE_WRITE_RESPONSE = -1,
  int USE_READ_RESPONSE = -1,
  int USE_ARBITERLOCK = -1,
  int USE_LOCK = -1

  ////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////
 ) extends uvm_sequence_item;

   localparam RESP_COMPLETE_TRIGGER = "RESP_COMPLETE";

   localparam INT_W = 32;

   localparam MAX_BURST_SIZE = USE_BURSTCOUNT ? 2**(AV_BURSTCOUNT_W-1): 1;
   localparam AV_TRANSACTIONID_W = 8;

   typedef logic[AV_ADDRESS_W-1:0]  AvalonAddress_t;
   typedef logic[AV_BURSTCOUNT_W-1:0]  AvalonBurstCount_t;
   typedef logic[AV_TRANSACTIONID_W-1:0]  AvalonTransactionId_t;
   typedef logic[MAX_BURST_SIZE-1:0][AV_DATA_W-1:0]  AvalonData_t;
   typedef logic[MAX_BURST_SIZE-1:0][AV_NUMSYMBOLS-1:0]  AvalonByteEnable_t;
   typedef logic[MAX_BURST_SIZE-1:0][INT_W-1:0]  AvalonIdle_t;
   typedef logic[MAX_BURST_SIZE-1:0][INT_W-1:0] AvalonWaitPos_t;

   string description;

   // Common fields
   avalon_mm_pkg::Request_t request;
   AvalonAddress_t         address;
   AvalonBurstCount_t      burst_count;
   AvalonData_t            data;
   AvalonByteEnable_t      byte_enable;
   AvalonIdle_t            idle;
   logic                   arbiterlock;
   logic                   lock;
   logic                   debugaccess;
   AvalonTransactionId_t   transaction_id;

   // Command to driver only fields
   int                     init_latency;
   int                     burst_size;

   // Driver response
   avmm_response_seq_item_c #(AV_ADDRESS_W, AV_BURSTCOUNT_W, USE_BURSTCOUNT, AV_DATA_W, AV_NUMSYMBOLS, AV_READRESPONSE_W, AV_WRITERESPONSE_W, USE_WRITE_RESPONSE, USE_READ_RESPONSE) response;

   // Monitored only fields
   time begin_time;
   AvalonWaitPos_t wait_seq;
   int burst_cycle;

   // Event pool:
   uvm_event_pool events;

   `uvm_object_param_utils_begin(avmm_command_seq_item_c #(AV_ADDRESS_W, AV_BURSTCOUNT_W, USE_BURSTCOUNT, AV_DATA_W, AV_NUMSYMBOLS, AV_READRESPONSE_W, AV_WRITERESPONSE_W, USE_WRITE_RESPONSE, USE_READ_RESPONSE, USE_ARBITERLOCK, USE_LOCK))
   `uvm_field_enum(avalon_mm_pkg::Request_t, request, UVM_DEFAULT)
   `uvm_field_string(description, UVM_DEFAULT | UVM_NOCOMPARE | UVM_NOCOPY)
   `uvm_field_int(address, UVM_DEFAULT)
   `uvm_field_int(burst_count, UVM_DEFAULT | UVM_DEC)
   `uvm_field_sarray_int(data, UVM_DEFAULT | UVM_NOCOMPARE)
   `uvm_field_sarray_int(byte_enable, UVM_DEFAULT | UVM_NOCOMPARE)
   `uvm_field_sarray_int(idle, UVM_DEFAULT | UVM_DEC)
   `uvm_field_int(init_latency, UVM_DEFAULT | UVM_DEC)
   `uvm_field_int(burst_size, UVM_DEFAULT | UVM_DEC | UVM_NOCOMPARE)
   `alt_cond_uvm_field(`uvm_field_int(arbiterlock, UVM_DEFAULT), USE_ARBITERLOCK == 1)
   `alt_cond_uvm_field(`uvm_field_int(lock, UVM_DEFAULT), USE_LOCK == 1)
   //`uvm_field_int(debugaccess, UVM_DEFAULT) // KALEN HACK. This should be from USE_DEBUGACCESS
   //`uvm_field_int(transaction_id, UVM_DEFAULT) //KALEN HACK. This should be from USE_TRANSACTIONID
   `uvm_field_int(begin_time, UVM_DEFAULT | UVM_TIME | UVM_NOCOMPARE)
   `uvm_field_sarray_int(wait_seq, UVM_DEFAULT | UVM_DEC)
   `uvm_field_int(burst_cycle, UVM_DEFAULT | UVM_DEC)
   `uvm_object_utils_end

   function new(string name = "avmm_command_seq_item");
      super.new(name);

      description = "";

      request = avalon_mm_pkg::REQ_IDLE;
      address = 0;
      burst_count = 0;

      for (int i = 0; i < MAX_BURST_SIZE; i++) begin
         data[i] = 0;
         byte_enable[i] = 0;
         idle[i] = 0;
         wait_seq[i] = 0;
      end

      init_latency = 0;
      burst_size = 0;
      arbiterlock = 0;
      lock = 0;
      debugaccess = 0;
      transaction_id = 0;
      begin_time = 0;
      burst_cycle = 0;

      events = get_event_pool();

   endfunction

   function void do_copy(uvm_object rhs);
      avmm_command_seq_item_c #(AV_ADDRESS_W,
                              AV_BURSTCOUNT_W,
                              USE_BURSTCOUNT,
                              AV_DATA_W,
                              AV_NUMSYMBOLS,
                              AV_READRESPONSE_W,
                              AV_WRITERESPONSE_W,
                              USE_READ_RESPONSE,
                              USE_WRITE_RESPONSE,
                              USE_ARBITERLOCK,
                              USE_LOCK) rhs_;

      super.do_copy(rhs);

      if (!$cast(rhs_, rhs)) begin
         `uvm_fatal("do_copy", "cast failed, check types");
      end
   endfunction

   function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      avmm_command_seq_item_c #(AV_ADDRESS_W,
                              AV_BURSTCOUNT_W,
                              USE_BURSTCOUNT,
                              AV_DATA_W,
                              AV_NUMSYMBOLS,
                              AV_READRESPONSE_W,
                              AV_WRITERESPONSE_W,
                              USE_READ_RESPONSE,
                              USE_WRITE_RESPONSE,
                              USE_ARBITERLOCK,
                              USE_LOCK) tr;
      bit eq;

      eq = super.do_compare(rhs, comparer);

      if (!$cast(tr, rhs)) begin
         `uvm_fatal("do_copy", "cast failed, check types");
      end

      // Only compare byte enable and data for write
      if (request == avalon_mm_pkg::REQ_WRITE) begin
         for (int i = 0; i < MAX_BURST_SIZE; i++) begin
            eq &= (byte_enable[i] === tr.byte_enable[i]);
            eq &= (data[i] === tr.data[i]);
         end
      end

      return (eq);
   endfunction


   function string convert2string();
      if (request == avalon_mm_pkg::REQ_IDLE) begin
         convert2string = "AVMM Idle";
      end else if (request == avalon_mm_pkg::REQ_WRITE) begin
         convert2string = $sformatf("AVMM Write - Addr:0x%x - Data:0x%x", address, data);
      end else if (request == avalon_mm_pkg::REQ_READ) begin
         convert2string = $sformatf("AVMM Read - Addr:0x%x - Data:0x%x", address, data);
      end

   endfunction: convert2string


   // Wait for an event - called by sequence
   task wait_trigger(string evnt);
      uvm_event e = events.get(evnt);
      e.wait_trigger();
   endtask: wait_trigger

   // Trigger an event - called by driver
   task trigger(string evnt);
      uvm_event e = events.get(evnt);
      e.trigger();
   endtask: trigger

endclass

`endif
