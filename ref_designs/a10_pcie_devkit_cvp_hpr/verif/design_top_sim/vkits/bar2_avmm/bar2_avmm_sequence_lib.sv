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

`ifndef INC_BAR2_AVMM_SEQUENCE_LIB_SV
`define INC_BAR2_AVMM_SEQUENCE_LIB_SV

class bar2_avmm_base_seq_c extends avmm_pkg::avmm_base_seq_c #(bar2_avmm_pkg::bar2_avmm_command_seq_item_c);
   `uvm_object_utils(bar2_avmm_base_seq_c)

   localparam PR_IP_BASE_ADDRESS = 32'h_0000_1000;
   localparam PR_IP_SIZE = 32'h_0000_003F;
   localparam PR_IP_DATA_ADDRESS = PR_IP_BASE_ADDRESS + (0<<2);
   localparam PR_IP_STATUS_ADDRESS = PR_IP_BASE_ADDRESS + (1<<2);
   localparam PR_IP_VERSION_ADDRESS = PR_IP_BASE_ADDRESS + (2<<2);
   localparam PR_IP_PR_POF_ID_ADDRESS = PR_IP_BASE_ADDRESS + (3<<2);


   localparam CONFIG_ROM_BASE_ADDRESS = 32'h_0000_0000;

   function new(string name = "[name]]");
      super.new(name);
   endfunction

endclass


`endif //INC_BAR2_AVMM_SEQUENCE_LIB_SV
