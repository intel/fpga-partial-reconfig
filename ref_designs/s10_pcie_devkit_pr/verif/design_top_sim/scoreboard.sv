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

`ifndef INC_SCOREBOARD_SV
`define INC_SCOREBOARD_SV

class sb_comparator_c
#(
  ////////////////////////////////////////////////////////////////////
  // NOTE: These parameters must be overridden in the instantiation
  ////////////////////////////////////////////////////////////////////
  parameter type RSP_T = avmm_pkg::avmm_response_seq_item_c
 ////////////////////////////////////////////////////////////////////
 ) extends uvm_component;
   `uvm_component_param_utils(sb_comparator_c #(RSP_T))

   uvm_analysis_export #(RSP_T) response_aport_mon_out;
   uvm_analysis_export #(RSP_T) response_aport_mon_exp;

   uvm_tlm_analysis_fifo #(RSP_T) expfifo;
   uvm_tlm_analysis_fifo #(RSP_T) monfifo;
   uvm_tlm_fifo #(RSP_T) monfifo_read;
   uvm_tlm_fifo #(RSP_T) monfifo_write;

   sim_reporting test_report;

   RSP_T exp_tr;

   function new(string name = "sb_comparator", uvm_component parent);
      super.new(name, parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      response_aport_mon_exp = new("response_aport_mon_exp", this);
      response_aport_mon_out = new("response_aport_mon_out", this);

      expfifo = new("expfifo", this);
      monfifo = new("monfifo", this);
      monfifo_read = new("monfifo_read", this, 10); // KALEN HACK: Use 10 (?) as initial size
      monfifo_write = new("monfifo_write", this, 10);

   endfunction

   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);

      response_aport_mon_exp.connect(expfifo.analysis_export);
      response_aport_mon_out.connect(monfifo.analysis_export);

   endfunction

   // Read and write can come back out of order, but within each type they are in order.
   // As a result, sort them into 2 FIFOs
   task sort_responses;
      RSP_T mon_tr;

      fork : sort_tr
         forever begin
            monfifo.get(mon_tr);
            if (mon_tr.request == avalon_mm_pkg::REQ_WRITE) begin
               monfifo_write.put(mon_tr);
            end else if (mon_tr.request == avalon_mm_pkg::REQ_READ) begin
               monfifo_read.put(mon_tr);
            end else begin
               `uvm_fatal("SB_CMP", "Unknown request type")
            end
         end
      join_none
   endtask

   task run_phase(uvm_phase phase);
      RSP_T mon_tr;
      sim_report test;
      string test_description;

      sort_responses();

      forever begin
         `uvm_info("SB_CMP", "WAITING for expected output", UVM_HIGH)
         expfifo.get(exp_tr);

         phase.raise_objection(this);
         if (exp_tr.request ==  avalon_mm_pkg::REQ_WRITE) begin
            fork : wait_queues_write begin
                  `uvm_info("SB_CMP", "WAITING for actual WRITE output", UVM_HIGH)
                  monfifo_write.get(mon_tr);
               end
               begin
                  #10000 `uvm_fatal("SB_CMP", "Scoreboard watchdog timeout")
                  $finish;

               end
            join_any
            disable wait_queues_write;
         end else if (exp_tr.request ==  avalon_mm_pkg::REQ_READ) begin
            fork : wait_queues_read begin
                  `uvm_info("SB_CMP", "WAITING for actual READ output", UVM_HIGH)
                  monfifo_read.get(mon_tr);
               end
               begin
                  #10000 `uvm_fatal("SB_CMP", "Scoreboard watchdog timeout")
                  $finish;

               end
            join_any
            disable wait_queues_read;
         end

         if (exp_tr.request ==  avalon_mm_pkg::REQ_WRITE) begin
            test_description = $sformatf("%s - %s", exp_tr.description, mon_tr.convert2string());
         end else if (exp_tr.request ==  avalon_mm_pkg::REQ_READ) begin
            string data_str = "";

            if (exp_tr.ignore_comparison) begin
               data_str = "IGNORED";
            end else begin
               for (int i = 0; i < exp_tr.burst_size; i = i + 1)  begin
                  data_str = $sformatf("%s0x%H ", data_str, exp_tr.data[i]);
               end
            end

            test_description = $sformatf("%s - %s : expect %s", exp_tr.description, mon_tr.convert2string(), data_str);
         end

         test = test_report.add_test(test_description);
         test.test_active = 1;
         test.start_time = mon_tr.begin_time;
         test.end_time = mon_tr.end_time;

         `uvm_info("sb_cmp", $sformatf("Monitored trans: %s", mon_tr.convert2string()), UVM_MEDIUM);
         `uvm_info("sb_cmp", $sformatf("Expected trans: %s", exp_tr.convert2string()), UVM_MEDIUM);

         if (exp_tr.ignore_comparison) begin
            test.test_active = 0;
            test.pass_fail = 1;
            `uvm_info("sb_cmp", "PASS: Ignored monitored", UVM_HIGH);
         end else begin
            if (exp_tr.compare(mon_tr)) begin
               test.test_active = 0;
               test.pass_fail = 1;
               `uvm_info("sb_cmp", "PASS: Expected matches monitored", UVM_HIGH);
            end else begin
               test.test_active = 0;
               test.pass_fail = 0;
               `uvm_error("sb_cmp", "Expected does not match monitored");
               `uvm_error("sb_cmp", $sformatf("Monitored trans:\n%s", mon_tr.sprint()));
               `uvm_error("sb_cmp", $sformatf("Expected trans:\n%s", exp_tr.sprint()));
            end
         end

         phase.drop_objection(this);
      end
   endtask

endclass



class scoreboard_c extends uvm_scoreboard;
   `uvm_component_utils(scoreboard_c)

   uvm_analysis_export #(bar4_avmm_pkg::bar4_avmm_command_seq_item_c) bar4_command_aport_mon;
   uvm_analysis_export #(bar4_avmm_pkg::bar4_avmm_response_seq_item_c) bar4_response_aport_mon;

   uvm_analysis_export #(bar2_avmm_pkg::bar2_avmm_command_seq_item_c) bar2_command_aport_mon;
   uvm_analysis_export #(bar2_avmm_pkg::bar2_avmm_response_seq_item_c) bar2_response_aport_mon;

   uvm_analysis_export #(pr_region_pkg::pr_region_seq_item_c) pr_region_0_aport_mon;

   sb_predictor_base_c prd;
   sb_comparator_c #(bar2_avmm_pkg::bar2_avmm_response_seq_item_c) cmp_bar2;
   sb_comparator_c #(bar4_avmm_pkg::bar4_avmm_response_seq_item_c) cmp_bar4;

   sim_reporting test_report;


   /*
   covergroup cg_alt_pr_status;
   
      cg_status:   coverpoint drv.status {
         bins status[] = {
                alt_pr_status_transaction::IDLE,
                alt_pr_status_transaction::PR_ERROR,
                alt_pr_status_transaction::PR_IN_PROGRESS,
                alt_pr_status_transaction::PR_SUCCESS
            };
      }
   
   endgroup: cg_alt_pr_status
   */

   function new(string name = "Scoreboard", uvm_component parent);
      super.new(name, parent);

      //this.name = name;
      //cg_alt_pr_status = new();

   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      bar4_command_aport_mon = new("bar4_command_aport_mon", this);
      bar4_response_aport_mon = new("bar4_response_aport_mon", this);

      bar2_command_aport_mon = new("bar2_command_aport_mon", this);
      bar2_response_aport_mon = new("bar2_response_aport_mon", this);

      pr_region_0_aport_mon = new("pr_region_0_aport_mon", this);

      prd = sb_predictor_c::type_id::create("prd", this); // KALEN Move to env

      cmp_bar2 = sb_comparator_c#(bar2_avmm_pkg::bar2_avmm_response_seq_item_c)::type_id::create("cmp_bar2", this);
      cmp_bar4 = sb_comparator_c#(bar4_avmm_pkg::bar4_avmm_response_seq_item_c)::type_id::create("cmp_bar4", this);

   endfunction


   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);

      cmp_bar2.test_report = test_report;
      cmp_bar4.test_report = test_report;

      bar4_command_aport_mon.connect(prd.command_aport_mon_bar4);
      bar4_response_aport_mon.connect(cmp_bar4.response_aport_mon_out);

      bar2_command_aport_mon.connect(prd.command_aport_mon_bar2);
      bar2_response_aport_mon.connect(cmp_bar2.response_aport_mon_out);

      prd.response_predict_aport_bar4.connect(cmp_bar4.response_aport_mon_exp);
      prd.response_predict_aport_bar2.connect(cmp_bar2.response_aport_mon_exp);

      pr_region_0_aport_mon.connect(prd.pr_region_aport_mon_pr_region0);

   endfunction

endclass

`endif //INC_SCOREBOARD_SV
