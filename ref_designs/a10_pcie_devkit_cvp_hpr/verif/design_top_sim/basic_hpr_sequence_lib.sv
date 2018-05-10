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


`ifndef INC_BASIC_HPR_SEQUENCE_LIB_SV
`define INC_BASIC_HPR_SEQUENCE_LIB_SV

class basic_hpr_persona_base_seq_c extends persona_base_seq_c;
   `uvm_object_utils(basic_hpr_persona_base_seq_c)

   function new(string name = "[name]]");
      super.new(name);
   endfunction

endclass


class basic_hpr_persona_read_persona_id_c extends basic_hpr_persona_base_seq_c;
   `uvm_object_utils(basic_hpr_persona_read_persona_id_c)

   rand avalon_mm_pkg::Request_t request;
   rand logic [31:0] data;
   rand logic [8:0] address; // Persona address space is 9bits in the persona reg file
   rand int num_idle;

   constraint valid_address {
      (request == avalon_mm_pkg::REQ_IDLE) -> address == 0;
      (request == avalon_mm_pkg::REQ_READ) -> address inside {PERSONA_ID_ADDRESS};
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

      description = "Basic hpr simple avmm";
   endfunction

   virtual task body();
      if (request == avalon_mm_pkg::REQ_READ) begin
         create_simple_read_transaction(description, address);
      end
      else if (request == avalon_mm_pkg::REQ_IDLE) begin
         create_idle_transaction(description, num_idle);
      end

   endtask
endclass

`endif
