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

`ifndef INC_PR_REGION_SEQUENCE_LIB_SV
`define INC_PR_REGION_SEQUENCE_LIB_SV

class pr_region_base_seq_c extends uvm_sequence #(pr_region_pkg::pr_region_seq_item_c);
   `uvm_object_utils(pr_region_base_seq_c)

   int pr_region_id;
   // persona_select should be set after the object is created
   int persona_select;

   function new(string name = "Region Controller Sequence");
      super.new(name);

      persona_select = -1;
      pr_region_id = -1;
   endfunction

   function set_persona_select(int sel);
      persona_select = sel;
   endfunction

endclass


class pr_region_set_persona_seq_c extends pr_region_base_seq_c;
   `uvm_object_utils(pr_region_set_persona_seq_c)
   
   function new(string name = "Set persona sequence (No PR)");
      super.new(name);
   endfunction

   // persona_select should be set after the object is created
   virtual task body();
      pr_region_pkg::pr_region_seq_item_c tr;

      `altr_assert(persona_select != -1)

      tr = pr_region_pkg::pr_region_seq_item_c::type_id::create("cur_trans");

      start_item(tr);
      tr.pr_activate = 0;
      tr.pr_activate_enabled = 0;
      tr.persona_select = persona_select;
      tr.persona_select_enabled = 1;
      tr.pr_region_id = pr_region_id;
      finish_item(tr);
   endtask

endclass

class pr_region_assert_pr_to_persona_seq_c extends pr_region_base_seq_c;
   `uvm_object_utils(pr_region_assert_pr_to_persona_seq_c)

   // persona_select should be set after the object is created
   function new(string name = "PR to persona sequence");
      super.new(name);
   endfunction

   virtual task body();
      pr_region_pkg::pr_region_seq_item_c tr;

      tr = pr_region_pkg::pr_region_seq_item_c::type_id::create("tr");

      start_item(tr);
      tr.pr_activate = 1;
      tr.pr_activate_enabled = 1;
      tr.persona_select = persona_select;
      tr.persona_select_enabled = 1;
      tr.pr_region_id = pr_region_id;
      finish_item(tr);
   endtask

endclass

class pr_region_assert_pr_seq_c extends pr_region_base_seq_c;
   `uvm_object_utils(pr_region_assert_pr_seq_c)

   function new(string name = "Assert PR sequence");
      super.new(name);
   endfunction

   virtual task body();
      pr_region_pkg::pr_region_seq_item_c tr;

      tr = pr_region_pkg::pr_region_seq_item_c::type_id::create("tr");

      start_item(tr);
      tr.pr_activate = 1;
      tr.pr_activate_enabled = 1;
      tr.persona_select_enabled = 0;
      tr.pr_region_id = pr_region_id;
      finish_item(tr);
   endtask

endclass

class pr_region_deassert_pr_seq_c extends pr_region_base_seq_c;
   `uvm_object_utils(pr_region_deassert_pr_seq_c)

   function new(string name = "Deassert PR sequence");
      super.new(name);
   endfunction

   virtual task body();
      pr_region_pkg::pr_region_seq_item_c tr;

      tr = pr_region_pkg::pr_region_seq_item_c::type_id::create("tr");

      start_item(tr);
      tr.pr_activate = 0;
      tr.pr_activate_enabled = 1;
      tr.persona_select_enabled = 0;
      tr.pr_region_id = pr_region_id;
      finish_item(tr);
   endtask

endclass


`endif //INC_PR_REGION_SEQUENCE_LIB_SV
