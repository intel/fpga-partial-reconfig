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
