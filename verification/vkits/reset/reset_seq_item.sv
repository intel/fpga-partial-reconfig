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

`ifndef INC_RESET_SEQ_ITEM_SV
`define INC_RESET_SEQ_ITEM_SV

class reset_seq_item_c extends uvm_sequence_item;

   bit reset;
   int post_drive_cycles;

   `uvm_object_utils_begin(reset_seq_item_c)
   `uvm_field_int(reset, UVM_DEFAULT)
   `uvm_field_int(post_drive_cycles, UVM_DEFAULT | UVM_NOCOMPARE)
   `uvm_object_utils_end

   function new(string name = "[name]");
      super.new(name);

      reset = 0;
      post_drive_cycles = 0;

   endfunction


   function void do_copy(uvm_object rhs);
      reset_seq_item_c rhs_;

      if (!$cast(rhs_, rhs)) begin
         `uvm_fatal("do_copy", "cast failed, check types");
      end

   endfunction

   function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      reset_seq_item_c tr;
      bit    eq;

      if (!$cast(tr, rhs)) begin
         `uvm_fatal("do_copy", "cast failed, check types");
      end

      eq = super.do_compare(rhs, comparer);

      return (eq);
   endfunction


   function string convert2string();
      convert2string = $sformatf("reset:\t%0d", reset);

   endfunction: convert2string

endclass

`endif
