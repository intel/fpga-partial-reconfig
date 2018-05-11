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

`ifndef INC_CONFIG_STREAM_ENDPOINT_PR_SEQ_ITEM_SV
`define INC_CONFIG_STREAM_ENDPOINT_PR_SEQ_ITEM_SV

class config_stream_endpoint_pr_seq_item_c extends uvm_sequence_item;

   config_stream_endpoint_pr_test_pkg::PR_EVENT_TYPE event_type;
   logic [31:0] pr_persona_id;

   `uvm_object_utils_begin(config_stream_endpoint_pr_seq_item_c)
   `uvm_field_enum(config_stream_endpoint_pr_test_pkg::PR_EVENT_TYPE, event_type, UVM_DEFAULT)
   `uvm_field_int(pr_persona_id, UVM_DEFAULT)
   `uvm_object_utils_end

   function new(string name = "config_stream_endpoint_pr_seq_item");
      super.new(name);

   endfunction


   function void do_copy(uvm_object rhs);
      config_stream_endpoint_pr_seq_item_c rhs_;

      if (!$cast(rhs_, rhs)) begin
         `uvm_fatal("do_copy", "cast failed, check types");
      end

   endfunction

   function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      config_stream_endpoint_pr_seq_item_c tr;
      bit eq;

      if (!$cast(tr, rhs)) begin
         `uvm_fatal("do_copy", "cast failed, check types");
      end

      eq = super.do_compare(rhs, comparer);

      return (eq);
   endfunction


   function string convert2string();
      convert2string = $sformatf("Event = %s Persona ID = %h", config_stream_endpoint_pr_test_pkg::pr_event_type_str(event_type), pr_persona_id);
   endfunction

endclass

`endif //INC_CONFIG_STREAM_ENDPOINT_PR_SEQ_ITEM_SV
