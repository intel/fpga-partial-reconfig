`ifndef INC_SB_PREDICTOR_BASE_SV
`define INC_SB_PREDICTOR_BASE_SV

`uvm_analysis_imp_decl(_bar4)
`uvm_analysis_imp_decl(_bar2)
`uvm_analysis_imp_decl(_prblock)
`uvm_analysis_imp_decl(_pr_region0)
`uvm_analysis_imp_decl(_parent_persona_region_0)
`uvm_analysis_imp_decl(_parent_persona_region_1)

class sb_predictor_base_c extends uvm_component;
   `uvm_component_utils(sb_predictor_base_c)

   uvm_analysis_imp_bar2 #(bar2_avmm_pkg::bar2_avmm_command_seq_item_c, sb_predictor_base_c) command_aport_mon_bar2;
   uvm_analysis_port #(bar2_avmm_pkg::bar2_avmm_response_seq_item_c) response_predict_aport_bar2;

   uvm_analysis_imp_bar4 #(bar4_avmm_pkg::bar4_avmm_command_seq_item_c, sb_predictor_base_c) command_aport_mon_bar4;
   uvm_analysis_port #(bar4_avmm_pkg::bar4_avmm_response_seq_item_c) response_predict_aport_bar4;
   
   uvm_analysis_imp_prblock #(twentynm_prblock_pkg::twentynm_prblock_seq_item_c, sb_predictor_base_c) prblock_aport_mon_prblock;

   uvm_analysis_imp_pr_region0 #(pr_region_pkg::pr_region_seq_item_c, sb_predictor_base_c) pr_region_aport_mon_pr_region0;
   uvm_analysis_imp_parent_persona_region_0 #(pr_region_pkg::pr_region_seq_item_c, sb_predictor_base_c) parent_persona_region_0_aport_mon;
   uvm_analysis_imp_parent_persona_region_1 #(pr_region_pkg::pr_region_seq_item_c, sb_predictor_base_c) parent_persona_region_1_aport_mon;

   function new(string name = "[name]", uvm_component parent);
      super.new(name, parent);

   endfunction

   virtual function void set_prblock_vif(virtual twentynm_prblock_if vif);
   endfunction

   virtual function set_pred_param(string name, string val);
   endfunction


   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      command_aport_mon_bar4 = new("command_aport_mon_bar4", this);
      response_predict_aport_bar4 = new("response_predict_aport_bar4", this);

      command_aport_mon_bar2 = new("command_aport_mon_bar2", this);
      response_predict_aport_bar2 = new("response_predict_aport_bar2", this);
      
      pr_region_aport_mon_pr_region0 = new("pr_region_aport_mon_pr_region0", this);
      parent_persona_region_0_aport_mon = new("parent_persona_region_0_aport_mon", this);
      parent_persona_region_1_aport_mon = new("parent_persona_region_1_aport_mon", this);

      prblock_aport_mon_prblock = new("prblock_aport_mon_prblock", this);

      endfunction

   virtual function void write_bar2(bar2_avmm_pkg::bar2_avmm_command_seq_item_c tr);
      bar2_avmm_pkg::bar2_avmm_response_seq_item_c exp_tr;
      `uvm_info("sb_prd", $sformatf("Observed command: %s", tr.convert2string()), UVM_MEDIUM);
      `uvm_info("sb_prd", $sformatf("Item\n%s", tr.sprint()), UVM_HIGH);

      //---------------------------
      exp_tr = predict_bar2(tr);
      //---------------------------

      `uvm_info("sb_prd", $sformatf("Predicted response: %s", exp_tr.convert2string()), UVM_MEDIUM);
      `uvm_info("sb_prd", $sformatf("Item\n%s", exp_tr.sprint()), UVM_HIGH);

      response_predict_aport_bar2.write(exp_tr);

   endfunction

   virtual function void write_bar4(bar4_avmm_pkg::bar4_avmm_command_seq_item_c tr);
      bar4_avmm_pkg::bar4_avmm_response_seq_item_c exp_tr;
      `uvm_info("sb_prd", $sformatf("Observed command: %s", tr.convert2string()), UVM_MEDIUM);
      `uvm_info("sb_prd", $sformatf("Item\n%s", tr.sprint()), UVM_HIGH);

      //---------------------------
      exp_tr = predict_bar4(tr);
      //---------------------------

      `uvm_info("sb_prd", $sformatf("Predicted response: %s", exp_tr.convert2string()), UVM_MEDIUM);
      `uvm_info("sb_prd", $sformatf("Item\n%s", exp_tr.sprint()), UVM_HIGH);

      response_predict_aport_bar4.write(exp_tr);

   endfunction

   virtual function void write_prblock(twentynm_prblock_pkg::twentynm_prblock_seq_item_c tr);
   endfunction

   virtual function void write_pr_region0(pr_region_pkg::pr_region_seq_item_c tr);
   endfunction

   virtual function void write_parent_persona_region_0(pr_region_pkg::pr_region_seq_item_c tr);
   endfunction

   virtual function void write_parent_persona_region_1(pr_region_pkg::pr_region_seq_item_c tr);
   endfunction

   virtual function bar2_avmm_pkg::bar2_avmm_response_seq_item_c predict_bar2(bar2_avmm_pkg::bar2_avmm_command_seq_item_c tr);
      `uvm_fatal("SB_PRED", "No implementation found for predict_bar2")
   endfunction

    virtual function bar4_avmm_pkg::bar4_avmm_response_seq_item_c predict_bar4(bar4_avmm_pkg::bar4_avmm_command_seq_item_c tr);
      `uvm_fatal("SB_PRED", "No implementation found for predict_bar4")
   endfunction

endclass


`endif //INC_SB_PREDICTOR_BASE_SV