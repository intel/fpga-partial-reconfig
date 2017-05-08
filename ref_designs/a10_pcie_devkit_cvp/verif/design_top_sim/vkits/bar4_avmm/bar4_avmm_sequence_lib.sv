// Copyright (c) 2001-2017 Intel Corporation
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

`ifndef INC_BAR4_AVMM_SEQUENCE_LIB_SV
`define INC_BAR4_AVMM_SEQUENCE_LIB_SV

class bar4_avmm_base_seq_c extends avmm_pkg::avmm_base_seq_c #(bar4_avmm_pkg::bar4_avmm_command_seq_item_c);
   `uvm_object_utils(bar4_avmm_base_seq_c)

   localparam PR_REGION_0_BASE_ADDRESS = 32'h_0000_0000;
   localparam PR_REGION_0_REGFILE_BASE_ADDRESS = 32'h_0000_0000;
   localparam PR_REGION_0_REGFILE_SIZE = 32'h_0000_4000;

   localparam PR_REGION_0_REGION_CTRL_BASE_ADDRESS = 32'h_0001_0000;
   localparam PR_REGION_0_REGION_CTRL_SIZE = 32'h_0000_0010;

   localparam PR_REGION_0_REGION_CTRL_STATUS = PR_REGION_0_REGION_CTRL_BASE_ADDRESS + (0<<2);
   localparam PR_REGION_0_REGION_CTRL_CTRL = PR_REGION_0_REGION_CTRL_BASE_ADDRESS + (1<<2);
   localparam PR_REGION_0_REGION_CTRL_ILLEGAL_REQ = PR_REGION_0_REGION_CTRL_BASE_ADDRESS + (2<<2);
   localparam PR_REGION_0_REGION_CTRL_SWVERSION = PR_REGION_0_REGION_CTRL_BASE_ADDRESS + (3<<2);

   localparam PERSONA_ID_ADDRESS = PR_REGION_0_REGFILE_BASE_ADDRESS + 0;

   localparam DDR4_CALIB_INTERFACE_BASE_ADDRESS = 32'h_0000_8100;

   function new(string name = "[name]]");
      super.new(name);
   endfunction

endclass

class bar4_idle_seq_c extends bar4_avmm_base_seq_c;
   `uvm_object_utils(bar4_idle_seq_c)

   // This parameter should be set after creation
   int num_idle_trans;

   function new(string name = "Idle transactions");
      super.new(name);

      num_idle_trans = -1;
   endfunction

   virtual task body();
      create_idle_transaction(description, num_idle_trans);
   endtask


endclass

`endif //INC_BAR4_AVMM_SEQUENCE_LIB_SV
