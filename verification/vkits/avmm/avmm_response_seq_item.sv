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


`ifndef INC_AVMM_RESPONSE_SEQ_ITEM_SV
`define INC_AVMM_RESPONSE_SEQ_ITEM_SV

class avmm_response_seq_item_c
#(
  ////////////////////////////////////////////////////////////////////
  // NOTE: These parameters must be overridden in the concrete class
  ////////////////////////////////////////////////////////////////////
  int AV_ADDRESS_W = -1,
  int AV_BURSTCOUNT_W = -1,
  int USE_BURSTCOUNT = -1,
  int AV_DATA_W = -1,
  int AV_NUMSYMBOLS = -1,
  int AV_READRESPONSE_W = 1,
  int AV_WRITERESPONSE_W = 1,
  int USE_WRITE_RESPONSE = -1,
  int USE_READ_RESPONSE = -1
  ////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////
 ) extends uvm_sequence_item;

   localparam INT_W = 32;

   localparam MAX_BURST_SIZE = USE_BURSTCOUNT ? 2**(AV_BURSTCOUNT_W-1): 1;
   localparam AV_TRANSACTIONID_W = 8;

   typedef logic[AV_ADDRESS_W-1:0] AvalonAddress_t;
   typedef logic[AV_BURSTCOUNT_W-1:0] AvalonBurstCount_t;
   typedef logic[AV_TRANSACTIONID_W-1:0] AvalonTransactionId_t;
   typedef logic[MAX_BURST_SIZE-1:0][AV_DATA_W-1:0] AvalonData_t;
   typedef logic[MAX_BURST_SIZE-1:0][AV_NUMSYMBOLS-1:0] AvalonByteEnable_t;
   typedef bit[MAX_BURST_SIZE-1:0][INT_W-1:0] AvalonLatency_t;
   typedef bit[MAX_BURST_SIZE-1:0][AV_READRESPONSE_W-1:0] AvalonReadResponse_t;

   string description;

   avalon_mm_pkg::Request_t request;
   AvalonAddress_t address;
   AvalonBurstCount_t burst_count;
   AvalonData_t data;
   AvalonByteEnable_t byte_enable;
   AvalonLatency_t read_latency;
   int write_latency;
   AvalonLatency_t wait_latency;
   int seq_count;
   int burst_size;
   AvalonTransactionId_t read_id;
   AvalonReadResponse_t read_response;
   AvalonTransactionId_t write_id;
   avalon_mm_pkg::AvalonResponseStatus_t write_response;
   time begin_time;
   time end_time;

   `uvm_object_param_utils_begin(avmm_response_seq_item_c #(AV_ADDRESS_W, AV_BURSTCOUNT_W, USE_BURSTCOUNT, AV_DATA_W, AV_NUMSYMBOLS, AV_READRESPONSE_W, AV_WRITERESPONSE_W, USE_WRITE_RESPONSE, USE_READ_RESPONSE))
   `uvm_field_enum(avalon_mm_pkg::Request_t, request, UVM_DEFAULT)
   `uvm_field_int(address, UVM_DEFAULT)
   `uvm_field_int(burst_count, UVM_DEFAULT)
   `uvm_field_sarray_int(data, UVM_DEFAULT)
   `uvm_field_sarray_int(byte_enable, UVM_DEFAULT | UVM_NOCOMPARE)
   `uvm_field_sarray_int(read_latency, UVM_DEFAULT | UVM_NOCOMPARE)
   `uvm_field_int(write_latency, UVM_DEFAULT | UVM_NOCOMPARE)
   `uvm_field_sarray_int(wait_latency, UVM_DEFAULT | UVM_NOCOMPARE)
   `uvm_field_int(seq_count, UVM_DEFAULT)
   `uvm_field_int(burst_size, UVM_DEFAULT)
   `alt_cond_uvm_field(`uvm_field_int(read_id, UVM_DEFAULT | UVM_NOCOMPARE), USE_READ_RESPONSE)
   `alt_cond_uvm_field(`uvm_field_sarray_int(read_response, UVM_DEFAULT), USE_READ_RESPONSE)
   `alt_cond_uvm_field(`uvm_field_int(write_id, UVM_DEFAULT | UVM_NOCOMPARE), USE_WRITE_RESPONSE)
   `alt_cond_uvm_field(`uvm_field_enum(avalon_mm_pkg::AvalonResponseStatus_t, write_response, UVM_DEFAULT), USE_WRITE_RESPONSE)
   `uvm_field_int(begin_time, UVM_TIME | UVM_NOCOMPARE)
   `uvm_field_int(end_time, UVM_TIME | UVM_NOCOMPARE)
   `uvm_object_utils_end

   function new(string name = "avmm_response_seq_item");
      super.new(name);

      request = avalon_mm_pkg::REQ_IDLE;
      address = 0;
      burst_count = 0;
      burst_size = 0;
      seq_count = 0;
      begin_time = 0;
      end_time = 0;
      write_latency = 0;
      write_response = avalon_mm_pkg::AV_RESERVED;

      for (int i = 0; i < MAX_BURST_SIZE; i++) begin
         data[i] = '0;
         byte_enable[i] = '0;
         read_latency[i] = '0;
         wait_latency[i] = '0;
         read_id[i]       = '0;
         read_response[i] = '0;
         write_id[i]       = '0;
      end

   endfunction


   function void do_copy(uvm_object rhs);
      avmm_response_seq_item_c #(AV_ADDRESS_W,
                               AV_BURSTCOUNT_W,
                               USE_BURSTCOUNT,
                               AV_DATA_W,
                               AV_NUMSYMBOLS,
                               AV_READRESPONSE_W,
                               AV_WRITERESPONSE_W,
                               USE_WRITE_RESPONSE,
                               USE_READ_RESPONSE) rhs_;

      super.do_copy(rhs);

      if (!$cast(rhs_, rhs)) begin
         `uvm_fatal("do_copy", "cast failed, check types");
      end
   endfunction

   function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      avmm_response_seq_item_c #(AV_ADDRESS_W,
                               AV_BURSTCOUNT_W,
                               USE_BURSTCOUNT,
                               AV_DATA_W,
                               AV_NUMSYMBOLS,
                               AV_READRESPONSE_W,
                               AV_WRITERESPONSE_W,
                               USE_WRITE_RESPONSE,
                               USE_READ_RESPONSE) tr;
      bit eq;

      eq = super.do_compare(rhs, comparer);

      if (eq == 1) begin
         if (!$cast(tr, rhs)) begin
            `uvm_fatal("do_compare", $sformatf("cast failed, check types. Cannot cast to avmm_response_seq_item from %s", rhs.sprint()));
         end

         // Only compare byte enable for write
         if (request == avalon_mm_pkg::REQ_WRITE) begin
            for (int i = 0; i < MAX_BURST_SIZE; i++) begin
               eq &=(byte_enable[i] === tr.byte_enable[i]);
            end
         end
      end
      return (eq);
   endfunction


   function string convert2string();
      if (request == avalon_mm_pkg::REQ_IDLE) begin
         convert2string = "AVMM Idle Response";
      end else if (request == avalon_mm_pkg::REQ_WRITE) begin
         convert2string = $sformatf("AVMM Write Response - Addr:0x%x - Data:0x%x", address, data);
      end else if (request == avalon_mm_pkg::REQ_READ) begin
         convert2string = $sformatf("AVMM Read Response - Addr:0x%x - Data:0x%x", address, data);
      end

   endfunction: convert2string

endclass

`endif //INC_AVMM_RESPONSE_SEQ_ITEM_SV
