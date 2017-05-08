// Copyright (c) 2001-2017 Intel Corporation
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

`ifndef INC_SB_PREDICT_SV
`define INC_SB_PREDICT_SV

class sb_basic_arith_model;
   logic [31:0] operand;
   logic [31:0] increment;

   function new();
      operand = 0;
      increment = 0;
   endfunction

   function set_operand(logic [31:0] op);
      operand = op;
   endfunction

   function logic[31:0] get_operand();
      return operand;
   endfunction

   function set_increment(logic [31:0] incr);
      increment = incr;
   endfunction

   function logic[31:0] get_increment();
      return increment;
   endfunction

   function int get_result();
      get_result = operand + increment;
   endfunction

   function void reset();
      operand = 0;
      increment = 0;
   endfunction

endclass

class sb_pr_ip_model;

   bit pr_start;
   bit [2:0] pr_status;
   int pr_data_count;

   virtual twentynm_prblock_if prblock_if;

   function new();
      pr_start = 0;
      pr_status = 0;
      pr_data_count = 0;
   endfunction

   function void set_vif( virtual twentynm_prblock_if vif);
      prblock_if = vif;
   endfunction

   // 000 : power-up
   // 001 : PR error
   // 010 : CRC error
   // 011 : incompatible bitstream
   // 100 : PR in progress
   // 101 : PR success
   // 110 : UNUSED
   // 111 : UNUSED

   function void set_pr_request();
      pr_status = 3'b100; // PR in progress
      pr_data_count = 0;
   endfunction

   function void set_pr_data(logic [31:0] data);
      if (data != 0) begin
         pr_data_count = pr_data_count + 1;
      end

      if (pr_data_count == 4) begin
      end
   endfunction

   function void set_pr_complete();
      if (pr_status == 3'b100) begin
         fork
            begin
               // Wait 5 clock cycles after the last data
               repeat (5) @(posedge prblock_if.clk); 
               pr_status = 3'b101;
            end
         join_none
      end
   endfunction

   function void set_pr_error();
      if (pr_status == 3'b100) begin
         pr_status = 3'b001;
      end
   endfunction


   function logic [31:0] get_pr_status();
      get_pr_status = {26'b0, 1'b0, pr_status, 1'b0, pr_start};
   endfunction


endclass

class sb_predictor_c extends design_top_sim_pkg::sb_predictor_base_c;
   `uvm_component_utils(sb_predictor_c)

   sb_basic_arith_model basic_arith_model;
   sb_pr_ip_model pr_ip_model;
   bit region0_freeze_status;
   bit region0_unfreeze_status;

   function new(string name = "sb_predictor", uvm_component parent);
      super.new(name, parent);

      basic_arith_model = new();
      pr_ip_model = new();
      region0_freeze_status = 0;
      region0_unfreeze_status = 0;
   endfunction

   virtual function void set_prblock_vif(virtual twentynm_prblock_if vif);
      pr_ip_model.set_vif(vif);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
   endfunction

   virtual function void write_prblock(twentynm_prblock_pkg::twentynm_prblock_seq_item_c tr);
      if (tr.event_type == twentynm_prblock_test_pkg::PR_COMPLETE_SUCCESS) begin
         pr_ip_model.set_pr_complete();
      end else if (tr.event_type == twentynm_prblock_test_pkg::PR_COMPLETE_ERROR) begin
         pr_ip_model.set_pr_error();
      end
   endfunction


   virtual function bar4_avmm_pkg::bar4_avmm_response_seq_item_c predict_bar4(bar4_avmm_pkg::bar4_avmm_command_seq_item_c tr);
      bar4_avmm_pkg::bar4_avmm_response_seq_item_c exp_tr;

      exp_tr = bar4_avmm_pkg::bar4_avmm_response_seq_item_c::type_id::create("exp_tr");

      // Copy the metadata
      exp_tr.description = tr.description;

      if (tr.request == avalon_mm_pkg::REQ_WRITE) begin
         // For write commands, just copy the data

         exp_tr.request = tr.request;
         exp_tr.address = tr.address;
         exp_tr.data = tr.data;
         exp_tr.burst_count = tr.burst_count;
         exp_tr.burst_size = tr.burst_count; // Note size == burst_count
         exp_tr.byte_enable = tr.byte_enable;

         // Update the models
         if (
             (tr.address >= bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGFILE_BASE_ADDRESS) &&
             (tr.address < (bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGFILE_BASE_ADDRESS + bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGFILE_SIZE))
            ) begin // PR region
            if (tr.address == (bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGFILE_BASE_ADDRESS + 'hA0)) begin
               basic_arith_model.set_operand(tr.data [0]);
            end else if (tr.address == (bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGFILE_BASE_ADDRESS + 'hB0)) begin
               basic_arith_model.set_increment(tr.data [0]);
            end
         end else if (
                      (tr.address >= bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_BASE_ADDRESS) &&
                      (tr.address < (bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_BASE_ADDRESS + bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_SIZE))
                     ) begin // PR region controller
            if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_CTRL) begin
               if (exp_tr.data [0] & 32'h_00001) begin // freeze request
                  region0_freeze_status = 1;
                  region0_unfreeze_status = 0;
               end else if (exp_tr.data [0] & 32'h_00002) begin // reset
                  basic_arith_model.reset();
               end else if (exp_tr.data [0] & 32'h_00004) begin // unfreeze request
                  region0_freeze_status = 0;
                  region0_unfreeze_status = 1;
               end
            end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_SWVERSION) begin
               exp_tr.data = 32'hAD000003;
            end

         end

      end else if (tr.request == avalon_mm_pkg::REQ_READ) begin
         exp_tr.request = tr.request;
         exp_tr.burst_count = 1;
         exp_tr.burst_size = 1;
         exp_tr.address = tr.address;

         if (
             (tr.address >= bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGFILE_BASE_ADDRESS) &&
             (tr.address < (bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGFILE_BASE_ADDRESS + bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGFILE_SIZE))
            ) begin // PR region

            if (region0_freeze_status) begin
               exp_tr.data [0] = 32'hdeadbeef;
            end else begin
               if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PERSONA_ID_ADDRESS) begin
                  // Read the persona id
                  exp_tr.data [0] = 32'h000000d2;
               end else if (tr.address == (bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGFILE_BASE_ADDRESS + 'h20)) begin
                  exp_tr.data [0] = basic_arith_model.get_result();
               end else if (tr.address == (bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGFILE_BASE_ADDRESS + 'hA0)) begin
                  exp_tr.data [0] = basic_arith_model.get_operand();
               end else if (tr.address == (bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGFILE_BASE_ADDRESS + 'hB0)) begin
                  exp_tr.data [0] = basic_arith_model.get_increment();
               end
            end
         end else if (
                      (tr.address >= bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_BASE_ADDRESS) &&
                      (tr.address < (bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_BASE_ADDRESS + bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_SIZE))
                     ) begin // PR region controller
            if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_STATUS) begin
               exp_tr.data = 0;
               exp_tr.data [0] = {30'b0, region0_unfreeze_status, region0_freeze_status};
            end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_SWVERSION) begin
               exp_tr.data [0] = 32'hAD000003;
            end

         end

      end else if (tr.request == avalon_mm_pkg::REQ_IDLE) begin
         exp_tr.request = tr.request;
      end

      return (exp_tr);
   endfunction

   virtual function bar2_avmm_pkg::bar2_avmm_response_seq_item_c predict_bar2(bar2_avmm_pkg::bar2_avmm_command_seq_item_c tr);
      bar2_avmm_pkg::bar2_avmm_response_seq_item_c exp_tr;

      exp_tr = bar2_avmm_pkg::bar2_avmm_response_seq_item_c::type_id::create("exp_tr");

      // Copy the metadata
      exp_tr.description = tr.description;

      if (tr.request == avalon_mm_pkg::REQ_WRITE) begin
         // For write commands, just copy the data

         exp_tr.request = tr.request;
         exp_tr.address = tr.address;
         exp_tr.data = tr.data;
         exp_tr.burst_count = tr.burst_count;
         exp_tr.burst_size = tr.burst_count; // Note size == burst_count
         exp_tr.byte_enable = tr.byte_enable;

         // Update the models
         if (
             (tr.address >= bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_BASE_ADDRESS) &&
             (tr.address < (bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_BASE_ADDRESS + bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_SIZE))
            ) begin // PR IP
            if (tr.address == (bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_STATUS_ADDRESS)) begin
               pr_ip_model.set_pr_request();
            end else if (tr.address == (bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_DATA_ADDRESS)) begin
               pr_ip_model.set_pr_data(tr.data [0]);
            end
         end
      end else if (tr.request == avalon_mm_pkg::REQ_READ) begin
         exp_tr.request = tr.request;
         exp_tr.burst_count = 1;
         exp_tr.burst_size = 1;
         exp_tr.address = tr.address;

         if (
             (tr.address >= bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_BASE_ADDRESS) &&
             (tr.address < (bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_BASE_ADDRESS + bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_SIZE))
            ) begin // PR IP

            if (tr.address ==  bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_VERSION_ADDRESS) begin
               // Read the SW version
               exp_tr.data [0] = 32'h_AA50_0003;
            end else if (tr.address ==  bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_PR_POF_ID_ADDRESS) begin
               // Read the SW version
               exp_tr.data [0] = 32'h_DEAD_BEEF;
            end else if (tr.address ==  bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_STATUS_ADDRESS) begin
               // Read the PR IP status
               exp_tr.data [0] = pr_ip_model.get_pr_status();
            end
         end


      end else if (tr.request == avalon_mm_pkg::REQ_IDLE) begin
         exp_tr.request = tr.request;
      end

      return (exp_tr);
   endfunction

endclass

`endif //INC_SB_PREDICT_SV