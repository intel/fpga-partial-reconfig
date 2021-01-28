`ifndef INC_BAR4_AVMM_COMMAND_SEQ_ITEM_SV
`define INC_BAR4_AVMM_COMMAND_SEQ_ITEM_SV

class bar4_avmm_command_seq_item_c extends avmm_pkg::avmm_command_seq_item_c
#(
  .AV_ADDRESS_W(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_ADDRESS_W),
  .AV_BURSTCOUNT_W(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_BURSTCOUNT_W),
  .USE_BURSTCOUNT(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_USE_BURSTCOUNT),
  .AV_DATA_W(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_DATA_W),
  .AV_NUMSYMBOLS(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_NUMSYMBOLS),
  .AV_READRESPONSE_W(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_READRESPONSE_W),
  .AV_WRITERESPONSE_W(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_WRITERESPONSE_W),
  .USE_WRITE_RESPONSE(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_USE_WRITERESPONSE),
  .USE_READ_RESPONSE(design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_USE_READRESPONSE)
 );

   `uvm_object_utils(bar4_avmm_command_seq_item_c)

   function new(string name = "cra_transaction");
      super.new(name);

   endfunction

   function void do_copy(uvm_object rhs);
      bar4_avmm_command_seq_item_c rhs_;

      super.do_copy(rhs);

      if (!$cast(rhs_, rhs)) begin
         `uvm_fatal("do_copy", "cast failed, check types");
      end

   endfunction

   function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      bar4_avmm_command_seq_item_c tr;
      bit eq;

      eq = super.do_compare(rhs, comparer);

      if (!$cast(tr, rhs)) begin
         `uvm_fatal("do_copy", "cast failed, check types");
      end
      return (eq);

   endfunction

endclass

`endif //INC_BAR4_AVMM_COMMAND_SEQ_ITEM_SV
