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

`ifndef INC_CONFIG_STREAM_ENDPOINT_PR_TO_PR_REGION_TRANSLATOR_SV
`define INC_CONFIG_STREAM_ENDPOINT_PR_TO_PR_REGION_TRANSLATOR_SV

class config_stream_endpoint_pr_to_pr_region_translator_c extends uvm_subscriber #(config_stream_endpoint_pr_pkg::config_stream_endpoint_pr_seq_item_c);
   `uvm_component_utils(config_stream_endpoint_pr_to_pr_region_translator_c)

   uvm_tlm_analysis_fifo #(config_stream_endpoint_pr_pkg::config_stream_endpoint_pr_seq_item_c) trfifo;

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
   
   function void write(config_stream_endpoint_pr_pkg::config_stream_endpoint_pr_seq_item_c t);
      `altr_assert(trfifo.try_put(t));
   endfunction

   // This function must be overloaded in the concrete class. It is expected to determine the persona select ID for
   // a PR ID
   virtual function int get_persona_select_for_id(int id);
      `uvm_fatal("PR", "get_persona_select_for_id not implemented")
   endfunction

   // This function must be overloaded in the concrete class. It is expected to determine the sequencer for
   // a PR ID
   virtual function pr_region_pkg::pr_region_sequencer_c get_seq_for_id(int id);
      `uvm_fatal("PR", "get_seq_for_id not implemented")
   endfunction

   // This function must be overloaded in the concrete class. It is expected to set the sequencer
   // from the env
   virtual function void get_seq_for_region(int region_id, pr_region_pkg::pr_region_sequencer_c seq);
      `uvm_fatal("PR", "get_seq_for_region not implemented")
   endfunction

   virtual task run_phase(uvm_phase phase);
      config_stream_endpoint_pr_pkg::config_stream_endpoint_pr_seq_item_c tr;

      forever begin
         trfifo.get(tr);

         phase.raise_objection(this);

         //NONE,
         //IDLE,
         //PR_REQUEST,
         //PR_IN_PROGRESS,
         //PR_COMPLETE_SUCCESS,
         //PR_COMPLETE_ERROR,
         //PR_INCOMPLETE_SYS_BUSY,
         //PR_INCOMPLETE_BAD_DATA

         if (tr.event_type == config_stream_endpoint_pr_test_pkg::PR_IN_PROGRESS) begin
            `uvm_info("PR", $sformatf("Detected %s PR event. Asserting PR on region %s.", config_stream_endpoint_pr_test_pkg::pr_event_type_str(tr.event_type),get_seq_for_id(tr.pr_persona_id).get_name()), UVM_MEDIUM)
            assert_pr.start(get_seq_for_id(tr.pr_persona_id));
         end
         else if (tr.event_type == config_stream_endpoint_pr_test_pkg::PR_COMPLETE_SUCCESS) begin
            `uvm_info("PR", $sformatf("Detected %s PR event. Deactivating PR. Activating persona select to ID %0d (persona select %0d) on region %s", config_stream_endpoint_pr_test_pkg::pr_event_type_str(tr.event_type), tr.pr_persona_id, get_persona_select_for_id(tr.pr_persona_id), get_seq_for_id(tr.pr_persona_id).get_name()), UVM_MEDIUM)
            pr_to_persona.persona_select = get_persona_select_for_id(tr.pr_persona_id);
            pr_to_persona.start(get_seq_for_id(tr.pr_persona_id));
            deassert_pr.start(get_seq_for_id(tr.pr_persona_id));
         end
         else if (
            (tr.event_type == config_stream_endpoint_pr_test_pkg::PR_COMPLETE_ERROR) || 
            (tr.event_type == config_stream_endpoint_pr_test_pkg::PR_INCOMPLETE_SYS_BUSY) || 
            (tr.event_type == config_stream_endpoint_pr_test_pkg::PR_INCOMPLETE_BAD_DATA)
            ) begin
               `uvm_info("PR", $sformatf("Detected %s PR event. Activating PR on region %s", config_stream_endpoint_pr_test_pkg::pr_event_type_str(tr.event_type), get_seq_for_id(tr.pr_persona_id).get_name()), UVM_MEDIUM)
               assert_pr.start(get_seq_for_id(tr.pr_persona_id));
            end
         phase.drop_objection(this);
      end
   endtask

endclass

`endif //INC_CONFIG_STREAM_ENDPOINT_PR_TO_PR_REGION_TRANSLATOR_SV

