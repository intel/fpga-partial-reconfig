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

`ifndef INC_SB_PREDICTOR_BASE_SV
`define INC_SB_PREDICTOR_BASE_SV

`uvm_analysis_imp_decl(_bar4)
`uvm_analysis_imp_decl(_bar2)
`uvm_analysis_imp_decl(_prblock)
`uvm_analysis_imp_decl(_pr_region0)

class sb_predictor_base_c extends uvm_component;
   `uvm_component_utils(sb_predictor_base_c)

   uvm_analysis_imp_bar2 #(bar2_avmm_pkg::bar2_avmm_command_seq_item_c, sb_predictor_base_c) command_aport_mon_bar2;
   uvm_analysis_port #(bar2_avmm_pkg::bar2_avmm_response_seq_item_c) response_predict_aport_bar2;

   uvm_analysis_imp_bar4 #(bar4_avmm_pkg::bar4_avmm_command_seq_item_c, sb_predictor_base_c) command_aport_mon_bar4;
   uvm_analysis_port #(bar4_avmm_pkg::bar4_avmm_response_seq_item_c) response_predict_aport_bar4;
   

   uvm_analysis_imp_pr_region0 #(pr_region_pkg::pr_region_seq_item_c, sb_predictor_base_c) pr_region_aport_mon_pr_region0;

   function new(string name = "[name]", uvm_component parent);
      super.new(name, parent);

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


   virtual function void write_pr_region0(pr_region_pkg::pr_region_seq_item_c tr);
   endfunction

   virtual function bar2_avmm_pkg::bar2_avmm_response_seq_item_c predict_bar2(bar2_avmm_pkg::bar2_avmm_command_seq_item_c tr);
      `uvm_fatal("SB_PRED", "No implementation found for predict_bar2")
   endfunction

    virtual function bar4_avmm_pkg::bar4_avmm_response_seq_item_c predict_bar4(bar4_avmm_pkg::bar4_avmm_command_seq_item_c tr);
      `uvm_fatal("SB_PRED", "No implementation found for predict_bar4")
   endfunction

endclass


`endif //INC_SB_PREDICTOR_BASE_SV
