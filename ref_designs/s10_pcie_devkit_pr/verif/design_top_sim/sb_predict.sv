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

`ifndef INC_SB_PREDICT_SV
`define INC_SB_PREDICT_SV

class sb_predictor_c extends design_top_sim_pkg::sb_predictor_base_c;
   `uvm_component_utils(sb_predictor_c)

   bit region0_freeze_status;
   bit region0_unfreeze_status;
   int active_persona_select;
   logic [31:0] host_to_pr_0;
   logic [31:0] host_to_pr_1;
   logic [31:0] host_to_pr_2;

   function new(string name = "sb_predictor", uvm_component parent);
      super.new(name, parent);

      region0_freeze_status = 0;
      region0_unfreeze_status = 0;
   endfunction

   function int decode_persona_id(int persona_sel);
     
      case (active_persona_select)
         0 : decode_persona_id = 32'h0000_00D2; //basic_arithmetic_persona_top
         1 : decode_persona_id = 32'h0000_00EF; //ddr4_access_persona_top
         2 : decode_persona_id = 32'h0000_AEED; //basic_dsp_persona_top
         3 : decode_persona_id = 32'h0067_6F6C; //GOL
         default : `uvm_fatal("PRD", $sformatf("Unknown PR persona sel %0d", persona_sel))
      endcase
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
   endfunction

   virtual function void write_pr_region0(pr_region_pkg::pr_region_seq_item_c tr);

      // Decode the persona into the expected comp type
      active_persona_select = tr.persona_select;

      `uvm_info("PRD", $sformatf("Activating persona %0d", decode_persona_id(active_persona_select)), UVM_MEDIUM)

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
         if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_HOST_TO_PR_0_ADDRESS) begin
            host_to_pr_0 = tr.data[0];
         end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_HOST_TO_PR_1_ADDRESS) begin
            host_to_pr_1 = tr.data[0];
         end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_HOST_TO_PR_2_ADDRESS) begin
            host_to_pr_2 = tr.data[0];
         end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_CTRL) begin
            if (exp_tr.data[0] & 32'h_00001) begin // freeze request
               region0_freeze_status = 1;
               region0_unfreeze_status = 0;
            end else if (exp_tr.data[0] & 32'h_00004) begin // unfreeze request
               region0_freeze_status = 0;
               region0_unfreeze_status = 1;
            end
         end

      end else if (tr.request == avalon_mm_pkg::REQ_READ) begin
         exp_tr.request = tr.request;
         exp_tr.burst_count = 1;
         exp_tr.burst_size = 1;
         exp_tr.address = tr.address;
         exp_tr.data = 'X;

         if (
             (tr.address >= bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGFILE_BASE_ADDRESS) &&
             (tr.address < (bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGFILE_BASE_ADDRESS + bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGFILE_SIZE))
            ) begin // PR region

            if (region0_freeze_status) begin
               exp_tr.data[0] = 32'hdeadbeef;

            end else begin
               if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_PERSONA_ID_ADDRESS) begin
                  // Read the persona id
                  exp_tr.data[0] = decode_persona_id(active_persona_select);
               end else begin
                  if (active_persona_select == 32'd0) begin //basic_arith
                     //pr_operand : host_pr[0][31:0];
                     //increment  : host_pr[1][31:0];
                     if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_PR_TO_HOST_0_ADDRESS) begin                     
                        exp_tr.data[0] = host_to_pr_0 + host_to_pr_1;
                     end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_HOST_TO_PR_0_ADDRESS) begin
                        exp_tr.data[0] = host_to_pr_0;
                     end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_HOST_TO_PR_1_ADDRESS) begin
                        exp_tr.data[0] = host_to_pr_1;
                     end
                  end else if (active_persona_select == 32'd1) begin //ddr4_access
                     if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_HOST_TO_PR_0_ADDRESS) begin                     
                        exp_tr.data[0] = host_to_pr_0;
                     end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_HOST_TO_PR_1_ADDRESS) begin                     
                        exp_tr.data[0] = host_to_pr_1;
                     end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_HOST_TO_PR_2_ADDRESS) begin
                        exp_tr.data[0] = host_to_pr_2;
                     end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_PR_TO_HOST_0_ADDRESS) begin
                        exp_tr.data[0] = host_to_pr_2 + 32'd1;
                     end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_PR_TO_HOST_1_ADDRESS) begin
                        exp_tr.ignore_comparison = 1;
                        exp_tr.data[0]='X;
                     end
                  end else if (active_persona_select == 32'd2) begin //basic_dsp
                     //X : host_pr[0][26:0];
                     //Y  : host_pr[1][26:0];
                     logic [53:0] mult_res = host_to_pr_0[26:0] * host_to_pr_1[26:0];
                     
                     if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_PR_TO_HOST_0_ADDRESS) begin                     
                        exp_tr.data[0] = mult_res[31:0];
                     end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_PR_TO_HOST_1_ADDRESS) begin                     
                        exp_tr.data[0] = {10'b0, mult_res[53:32]};
                     end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_HOST_TO_PR_0_ADDRESS) begin
                        exp_tr.data[0] = host_to_pr_0;
                     end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_HOST_TO_PR_1_ADDRESS) begin
                        exp_tr.data[0] = host_to_pr_1;
                     end
                  end else if (active_persona_select == 32'd3) begin //gol
                     if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_HOST_TO_PR_0_ADDRESS) begin                     
                        exp_tr.data[0] = host_to_pr_0 ;
                     end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_HOST_TO_PR_1_ADDRESS) begin                     
                        exp_tr.data[0] = host_to_pr_1;
                     end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_HOST_TO_PR_2_ADDRESS) begin
                        exp_tr.data[0] = host_to_pr_2;
                     end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_PR_TO_HOST_0_ADDRESS) begin
                        exp_tr.ignore_comparison=1;
                     end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_PR_TO_HOST_1_ADDRESS) begin
                        exp_tr.data[0] = 32'd3164240;
                     end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_PR_TO_HOST_2_ADDRESS) begin
                        exp_tr.data[0] = 32'h20000000;
                     end 
                  end
               end
            end

         end else if (
                      (tr.address >= bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_BASE_ADDRESS) &&
                      (tr.address < (bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_BASE_ADDRESS + bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_SIZE))
                     ) begin // PR region controller
            if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_STATUS) begin
               exp_tr.data = 0;
               exp_tr.data[0] = {30'b0, region0_unfreeze_status, region0_freeze_status};
            end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_SWVERSION) begin
               exp_tr.data[0] = 32'hAD000003;
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

         // Nothing to update (yet)

      end else if (tr.request == avalon_mm_pkg::REQ_READ) begin
         exp_tr.request = tr.request;
         exp_tr.burst_count = 1;
         exp_tr.burst_size = 1;
         exp_tr.address = tr.address;
         exp_tr.data = 'X;

         if (
             (tr.address >= bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_BASE_ADDRESS) &&
             (tr.address < (bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_BASE_ADDRESS + bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_SIZE))
            ) begin // PR IP

            if (tr.address ==  bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_VERSION_ADDRESS) begin
               // Read the SW version
               exp_tr.data[0] = 32'h_AA50_0003;
            end
         end


      end else if (tr.request == avalon_mm_pkg::REQ_IDLE) begin
         exp_tr.request = tr.request;
      end

      return (exp_tr);
   endfunction

endclass


`endif //INC_SB_PREDICT_SV