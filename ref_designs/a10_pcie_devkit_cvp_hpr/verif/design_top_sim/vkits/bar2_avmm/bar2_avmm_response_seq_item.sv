`ifndef INC_BAR2_AVMM_RESPONSE_SEQ_ITEM_SV
`define INC_BAR2_AVMM_RESPONSE_SEQ_ITEM_SV

class bar2_avmm_response_seq_item_c extends avmm_pkg::avmm_response_seq_item_c
#(
  .AV_ADDRESS_W(design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_ADDRESS_W),
  .AV_BURSTCOUNT_W(design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_BURSTCOUNT_W),
  .USE_BURSTCOUNT(design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_USE_BURSTCOUNT),
  .AV_DATA_W(design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_DATA_W),
  .AV_NUMSYMBOLS(design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_NUMSYMBOLS),
  .AV_READRESPONSE_W(design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_READRESPONSE_W),
  .AV_WRITERESPONSE_W(design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_WRITERESPONSE_W),
  .USE_WRITE_RESPONSE(design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_USE_WRITERESPONSE),
  .USE_READ_RESPONSE(design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_USE_READRESPONSE)
 );

   int ignore_comparison;

   `uvm_object_utils_begin(bar2_avmm_response_seq_item_c)
   `uvm_field_int(ignore_comparison, UVM_NOCOMPARE)
   `uvm_object_utils_end

   function new(string name = "bar2_response_seq_item");
      super.new(name);
      
      ignore_comparison = 0;
   endfunction

   function void do_copy(uvm_object rhs);
      bar2_avmm_response_seq_item_c rhs_;

      super.do_copy(rhs);

      if (!$cast(rhs_, rhs)) begin
         `uvm_fatal("do_copy", "cast failed, check types");
      end
   endfunction

   function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      bar2_avmm_response_seq_item_c tr;
      bit eq;

      eq = super.do_compare(rhs, comparer);

      if (!$cast(tr, rhs)) begin
         `uvm_fatal("do_copy", "cast failed, check types");
      end

      return (eq);
   endfunction

endclass

`endif //INC_BAR2_AVMM_RESPONSE_SEQ_ITEM_SV
