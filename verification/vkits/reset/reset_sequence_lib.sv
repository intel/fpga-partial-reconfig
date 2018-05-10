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

`ifndef INC_RESET_SEQUENCE_LIB_SV
`define INC_RESET_SEQUENCE_LIB_SV

class reset_base_seq_c extends uvm_sequence #(reset_seq_item_c);
   `uvm_object_utils(reset_base_seq_c)

   function new(string name = "[name]");
      super.new(name);
   endfunction

endclass


class reset_assert_seq_c extends reset_base_seq_c;
   `uvm_object_utils(reset_assert_seq_c)

   int post_drive_cycles;

   function new(string name = "Assert reset");
      super.new(name);
      
      post_drive_cycles = 0;
   endfunction

   virtual task body();
      reset_seq_item_c tr;

      tr = reset_seq_item_c::type_id::create("tr");

      start_item(tr);
      tr.reset = 1;
      tr.post_drive_cycles = post_drive_cycles;
      finish_item(tr);
   endtask

endclass

class reset_deassert_seq_c extends reset_base_seq_c;
   `uvm_object_utils(reset_deassert_seq_c)

   int post_drive_cycles;

   function new(string name = "Deassert reset");
      super.new(name);
      
      post_drive_cycles = 0;
   endfunction

   virtual task body();
      reset_seq_item_c tr;

      tr = reset_seq_item_c::type_id::create("tr");

      start_item(tr);
      tr.reset = 0;
      tr.post_drive_cycles = post_drive_cycles;
      finish_item(tr);
   endtask

endclass

class reset_cycle_reset_seq_c extends reset_base_seq_c;
   `uvm_object_utils(reset_cycle_reset_seq_c)

   reset_assert_seq_c assert_seq;
   reset_deassert_seq_c deassert_seq;
   
   function new(string name = "Cycle reset");
      super.new(name);
   endfunction

   virtual task body();
      assert_seq = reset_assert_seq_c::type_id::create("assert_seq");
      deassert_seq = reset_deassert_seq_c::type_id::create("deassert_seq");
      
      // Reset for 5 cycles
      assert_seq.post_drive_cycles = 5;
      
      // Deassert for 2 cycles
      deassert_seq.post_drive_cycles = 2;
      
      assert_seq.start(m_sequencer);
      deassert_seq.start(m_sequencer);

   endtask

endclass

`endif //INC_RESET_SEQUENCE_LIB_SV
