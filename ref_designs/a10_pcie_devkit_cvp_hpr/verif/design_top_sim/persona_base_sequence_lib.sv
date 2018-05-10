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

`ifndef INC_PERSONA_BASE_SEQUENCE_LIB_SV
`define INC_PERSONA_BASE_SEQUENCE_LIB_SV

`include "uvm_macros.svh"
import uvm_pkg::*;


class persona_base_seq_c extends bar4_avmm_pkg::bar4_avmm_base_seq_c;
   `uvm_object_utils(persona_base_seq_c)

   function new(string name = "[name]");
      super.new(name);
   endfunction

   task read_persona_id_block_until_response(string description, logic [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_ADDRESS_W-1:0] address);
      create_simple_read_transaction_block_until_response(description, address);
   endtask

   task read_persona_id(string description, logic [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_ADDRESS_W-1:0] address);
      create_simple_read_transaction(description, address);
   endtask

endclass

class read_persona_id_seq_c extends persona_base_seq_c;
   `uvm_object_utils(read_persona_id_seq_c)

   function new(string name = "[name]");
      super.new(name);
   endfunction

   task body();
      read_persona_id_block_until_response(description, PR_REGION_0_PERSONA_ID_ADDRESS);
   endtask

endclass


class read_parent_persona_child_0_persona_id_seq_c extends persona_base_seq_c;
   `uvm_object_utils(read_parent_persona_child_0_persona_id_seq_c)

   function new(string name = "[name]");
      super.new(name);
   endfunction

   task body();
      read_persona_id_block_until_response(description, PARENT_PERSONA_PR_REGION_0_PERSONA_ID_ADDRESS);
   endtask

endclass

class read_parent_persona_child_1_persona_id_seq_c extends persona_base_seq_c;
   `uvm_object_utils(read_parent_persona_child_1_persona_id_seq_c)

   function new(string name = "[name]");
      super.new(name);
   endfunction

   task body();
      read_persona_id_block_until_response(description, PARENT_PERSONA_PR_REGION_1_PERSONA_ID_ADDRESS);
   endtask

endclass

`endif //INC_PERSONA_BASE_SEQUENCE_LIB_SV
