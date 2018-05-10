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

`ifndef INC_PR_REGION_SEQ_ITEM_SV
`define INC_PR_REGION_SEQ_ITEM_SV

class pr_region_seq_item_c extends uvm_sequence_item;

   bit pr_activate;
   bit pr_activate_enabled;

   int persona_select;
   bit persona_select_enabled;

   int pr_region_id;

   `uvm_object_utils_begin(pr_region_seq_item_c)

   `uvm_field_int(pr_activate, UVM_DEFAULT)
   `uvm_field_int(pr_activate_enabled, UVM_DEFAULT | UVM_DEC)
   `uvm_field_int(persona_select, UVM_DEFAULT)
   `uvm_field_int(persona_select_enabled, UVM_DEFAULT | UVM_DEC)
   `uvm_field_int(pr_region_id, UVM_DEFAULT | UVM_DEC)

   `uvm_object_utils_end


   function new(string name = "pr_region_seq_item");
      super.new(name);

      pr_region_id = -1;
      pr_activate_enabled = 0;
      persona_select_enabled = 0;

   endfunction


   function void do_copy(uvm_object rhs);
      pr_region_seq_item_c rhs_;

      super.do_copy(rhs);

      if (!$cast(rhs_, rhs)) begin
         `uvm_fatal("do_copy", "cast failed, check types");
      end
   endfunction

   function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      pr_region_seq_item_c tr;
      bit    eq;

      if (!$cast(tr, rhs)) begin
         `uvm_fatal("do_copy", "cast failed, check types");
      end

      eq &= (pr_activate_enabled == tr.pr_activate_enabled);
      if (pr_activate_enabled) begin
         eq &=(pr_activate == tr.pr_activate);
      end

      eq &= (persona_select_enabled == tr.persona_select_enabled);
      if (persona_select_enabled) begin
         eq &=(persona_select == tr.persona_select);
      end

      eq &= (pr_region_id == tr.pr_region_id);

      return (eq);
   endfunction


   function string convert2string();
      convert2string = $sformatf("pr_region_id:%0d", pr_region_id);

      if (pr_activate_enabled) begin
         convert2string = $sformatf("%s pr_activate:%0d", convert2string, pr_activate);
      end
      if (persona_select_enabled) begin
         convert2string = $sformatf("%s persona_select:%0d", convert2string, persona_select);
      end

   endfunction: convert2string

endclass

`endif
