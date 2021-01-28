`ifndef INC_REGION0_PRBLOCK_LISTENER_SV
`define INC_REGION0_PRBLOCK_LISTENER_SV

class region0_prblock_listener_c extends uvm_subscriber #(twentynm_prblock_pkg::twentynm_prblock_seq_item_c);
   `uvm_component_utils(region0_prblock_listener_c)

   uvm_tlm_analysis_fifo #(twentynm_prblock_pkg::twentynm_prblock_seq_item_c) trfifo;

   pr_region_pkg::pr_region_sequencer_c region_seq;

   pr_region_pkg::pr_region_assert_pr_seq_c assert_pr;
   pr_region_pkg::pr_region_deassert_pr_seq_c deassert_pr;
   pr_region_pkg::pr_region_assert_pr_to_persona_seq_c pr_to_persona;

   function new(string name = "[name]", uvm_component parent);
      super.new(name, parent);

      trfifo = new("trfifo", this);

   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      assert_pr = pr_region_pkg::pr_region_assert_pr_seq_c::type_id::create("assert_pr");
      deassert_pr = pr_region_pkg::pr_region_deassert_pr_seq_c::type_id::create("deassert_pr");
      pr_to_persona = pr_region_pkg::pr_region_assert_pr_to_persona_seq_c::type_id::create("pr_to_persona");
   endfunction
   
   function void write(twentynm_prblock_pkg::twentynm_prblock_seq_item_c t);
      `altr_assert(trfifo.try_put(t));
   endfunction

   task run_phase(uvm_phase phase);
      twentynm_prblock_pkg::twentynm_prblock_seq_item_c tr;

      forever begin
         trfifo.get(tr);

         phase.raise_objection(this);

         if (tr.event_type == twentynm_prblock_test_pkg::PR_IN_PROGRESS) begin
            `uvm_info("SEQ", $sformatf("Detected %s PR event. Activating persona select to ID %0d on region 0", twentynm_prblock_test_pkg::pr_event_type_str(tr.event_type), tr.pr_persona_id), UVM_MEDIUM)
            pr_to_persona.persona_select = tr.pr_persona_id;
            pr_to_persona.start(region_seq);
         end
         else if (tr.event_type == twentynm_prblock_test_pkg::PR_COMPLETE_SUCCESS) begin
            `uvm_info("SEQ", $sformatf("Detected %s PR event. Deactivating PR on region 0", twentynm_prblock_test_pkg::pr_event_type_str(tr.event_type)), UVM_MEDIUM)
            deassert_pr.start(region_seq);
         end
         else if (
            (tr.event_type == twentynm_prblock_test_pkg::PR_COMPLETE_ERROR) || 
            (tr.event_type == twentynm_prblock_test_pkg::PR_INCOMPLETE_EARLY_WITHDRAWL) || 
            (tr.event_type == twentynm_prblock_test_pkg::PR_INCOMPLETE_LATE_WITHDRAWL)
            ) begin
               `uvm_info("SEQ", $sformatf("Detected %s PR event. Activating PR on region 0", twentynm_prblock_test_pkg::pr_event_type_str(tr.event_type)), UVM_MEDIUM)
               assert_pr.start(region_seq);
            end
         phase.drop_objection(this);
      end
   endtask

endclass

`endif //INC_REGION0_PRBLOCK_LISTENER_SV

