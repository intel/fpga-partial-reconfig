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


`ifndef INC_AVMM_SEQUENCE_LIB_SV
`define INC_AVMM_SEQUENCE_LIB_SV

class avmm_base_seq_c #(parameter type T = avmm_command_seq_item_c) extends uvm_sequence #(T);
   `uvm_object_param_utils(avmm_base_seq_c #(T))

   string description;

   function new(string name = "[name]]");
      super.new(name);

      description = "";

   endfunction

   task create_simple_read_transaction_get_item(string description, input logic [REQ::AV_ADDRESS_W-1:0] address, output REQ tr);
      tr = REQ::type_id::create("tr");

      start_item(tr);
      tr.description = description;
      tr.request = avalon_mm_pkg::REQ_READ;
      tr.address = address;
      tr.burst_count = 1;
      tr.burst_size = 1;
      finish_item(tr);
   endtask

   task create_simple_read_transaction(string description, input logic [REQ::AV_ADDRESS_W-1:0] address);
      REQ tr;

      create_simple_read_transaction_get_item(description, address, tr);
   endtask

   task create_simple_read_transaction_get_data(string description, input logic [REQ::AV_ADDRESS_W-1:0] address,  output logic [REQ::AV_DATA_W-1:0] data);
      REQ tr;

      create_simple_read_transaction_get_item(description, address, tr);

      fork : wait_queues_write begin
            // Block until response recieved
            tr.wait_trigger(REQ::RESP_COMPLETE_TRIGGER);
         end
         begin
            #100000 `uvm_fatal("SEQ", "Response for read never recieved")
            $finish;

         end
      join_any
      disable wait_queues_write;

      data = tr.response.data[0];

   endtask

   task create_simple_read_transaction_block_until_response(string description, input logic [REQ::AV_ADDRESS_W-1:0] address);
      logic [REQ::AV_DATA_W-1:0] data;

      create_simple_read_transaction_get_data(description, address, data);
   endtask

   task create_simple_write_transaction(string description, input logic [REQ::AV_ADDRESS_W-1:0] address, input logic [REQ::AV_DATA_W-1:0] data);
      REQ tr;

      tr = REQ::type_id::create("tr");

      start_item(tr);
      tr.description = description;
      tr.request = avalon_mm_pkg::REQ_WRITE;
      tr.address = address;
      tr.data[0] = data;
      tr.byte_enable[0] = '1;
      tr.burst_count = 1;
      tr.burst_size = 1;
      finish_item(tr);
   endtask

   task create_idle_transaction(string description, int num_transaction = 1);
      REQ tr;

      `altr_assert(num_transaction >= 0)

      for (int i = 0; i < num_transaction; i = i + 1)  begin
         tr = REQ::type_id::create("tr");

         start_item(tr);
         tr.description = description;
         tr.request = avalon_mm_pkg::REQ_IDLE;
         tr.burst_count = 1;
         tr.burst_size = 1;
         finish_item(tr);
      end

   endtask

endclass


`endif //INC_AVMM_SEQUENCE_LIB_SV
