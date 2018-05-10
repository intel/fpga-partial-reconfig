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

   sb_pr_ip_model pr_ip_model;
   bit region0_freeze_status;
   bit region0_unfreeze_status;
   bit pr_parent_region0_freeze_status;
   bit pr_parent_region0_unfreeze_status;
   bit pr_parent_region1_freeze_status;
   bit pr_parent_region1_unfreeze_status;
   int active_persona_select;
   int active_parent_perasona_child_0_persona_select;
   int active_parent_perasona_child_1_persona_select;
   
   logic [31:0] host_to_pr_0;
   logic [31:0] host_to_pr_1;
   logic [31:0] host_to_pr_2;
   
   logic [31:0] parent_persona_child0_host_to_pr_0;
   logic [31:0] parent_persona_child0_host_to_pr_1;
   logic [31:0] parent_persona_child0_host_to_pr_2;

   logic [31:0] parent_persona_child1_host_to_pr_0;
   logic [31:0] parent_persona_child1_host_to_pr_1;
   logic [31:0] parent_persona_child1_host_to_pr_2;

   function new(string name = "sb_predictor", uvm_component parent);
      super.new(name, parent);

      pr_ip_model = new();
      region0_freeze_status = 0;
      region0_unfreeze_status = 0;
      pr_parent_region0_freeze_status = 0;
      pr_parent_region0_unfreeze_status = 0;
      pr_parent_region1_freeze_status = 0;
      pr_parent_region1_unfreeze_status = 0;
   endfunction

   virtual function void set_prblock_vif(virtual twentynm_prblock_if vif);
      pr_ip_model.set_vif(vif);
   endfunction

   function int decode_persona_id(int persona_sel);
     
      case (persona_sel)
         0 : decode_persona_id = 32'h0000_00D2; //basic_arithmetic_persona_top
         1 : decode_persona_id = 32'h0000_00EF; //ddr4_access_persona_top
         2 : decode_persona_id = 32'h0000_AEED; //basic_dsp_persona_top
         3 : decode_persona_id = 32'h0067_6F6C; //GOL
         4 : decode_persona_id = 32'h6870_7261; //HPR parent
         default : `uvm_fatal("PRD", $sformatf("Unknown PR persona sel %0d", persona_sel))
      endcase
   endfunction

   function int decode_child0_persona_id(int persona_sel);
     
      case (persona_sel)
         0 : decode_child0_persona_id = 32'h0000_00EF; //ddr4_access_persona_top
         default : `uvm_fatal("PRD", $sformatf("Unknown PR persona sel %0d", persona_sel))
      endcase
   endfunction

   function int decode_child1_persona_id(int persona_sel);
     
      case (persona_sel)
         0 : decode_child1_persona_id = 32'h0000_00EF; //ddr4_access_persona_top
         default : `uvm_fatal("PRD", $sformatf("Unknown PR persona sel %0d", persona_sel))
      endcase
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

   virtual function void write_pr_region0(pr_region_pkg::pr_region_seq_item_c tr);

      // Decode the persona into the expected comp type
      active_persona_select = tr.persona_select;

      `uvm_info("PRD", $sformatf("Activating persona 0x%0h", decode_persona_id(active_persona_select)), UVM_MEDIUM)

   endfunction

   virtual function void write_parent_persona_region_0(pr_region_pkg::pr_region_seq_item_c tr);

      // Decode the persona into the expected comp type
      active_parent_perasona_child_0_persona_select = tr.persona_select;

      `uvm_info("PRD", $sformatf("Activating child0 persona 0x%0h", decode_child0_persona_id(active_parent_perasona_child_0_persona_select)), UVM_MEDIUM)
   endfunction

   virtual function void write_parent_persona_region_1(pr_region_pkg::pr_region_seq_item_c tr);

      // Decode the persona into the expected comp type
      active_parent_perasona_child_1_persona_select = tr.persona_select;

      `uvm_info("PRD", $sformatf("Activating child1 persona 0x%0h", decode_child1_persona_id(active_parent_perasona_child_1_persona_select)), UVM_MEDIUM)
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
         if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_CTRL) begin
            if (exp_tr.data[0] & 32'h_00001) begin // freeze request
               region0_freeze_status = 1;
               region0_unfreeze_status = 0;
            end else if (exp_tr.data[0] & 32'h_00004) begin // unfreeze request
               region0_freeze_status = 0;
               region0_unfreeze_status = 1;
            end
         end else if (active_persona_select != 4) begin
            if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_HOST_TO_PR_0_ADDRESS) begin
               host_to_pr_0 = tr.data[0];
            end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_HOST_TO_PR_1_ADDRESS) begin
               host_to_pr_1 = tr.data[0];
            end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_HOST_TO_PR_2_ADDRESS) begin
               host_to_pr_2 = tr.data[0];
            end
         end else if (active_persona_select == 4) begin // Is the active persona the HPR persona? If not proceed.
            if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_0_REGION_CTRL_CTRL) begin
               if (exp_tr.data[0] & 32'h_00001) begin // freeze request
                  pr_parent_region0_freeze_status = 1;
                  pr_parent_region0_unfreeze_status = 0;
               end else if (exp_tr.data[0] & 32'h_00004) begin // unfreeze request
                  pr_parent_region0_freeze_status = 0;
                  pr_parent_region0_unfreeze_status = 1;
               end
            end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_1_REGION_CTRL_CTRL) begin
               if (exp_tr.data[0] & 32'h_00001) begin // freeze request
                  pr_parent_region1_freeze_status = 1;
                  pr_parent_region1_unfreeze_status = 0;
               end else if (exp_tr.data[0] & 32'h_00004) begin // unfreeze request
                  pr_parent_region1_freeze_status = 0;
                  pr_parent_region1_unfreeze_status = 1;
               end
            end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_0_HOST_TO_PR_0_ADDRESS) begin
               parent_persona_child0_host_to_pr_0 = tr.data[0];
            end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_0_HOST_TO_PR_1_ADDRESS) begin
               parent_persona_child0_host_to_pr_1 = tr.data[0];
            end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_0_HOST_TO_PR_2_ADDRESS) begin
               parent_persona_child0_host_to_pr_2 = tr.data[0];

            end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_1_HOST_TO_PR_0_ADDRESS) begin
               parent_persona_child1_host_to_pr_0 = tr.data[0];
            end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_1_HOST_TO_PR_1_ADDRESS) begin
               parent_persona_child1_host_to_pr_1 = tr.data[0];
            end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_1_HOST_TO_PR_2_ADDRESS) begin
               parent_persona_child1_host_to_pr_2 = tr.data[0];
            end
         
         end

      end else if (tr.request == avalon_mm_pkg::REQ_READ) begin
         exp_tr.request = tr.request;
         exp_tr.burst_count = 1;
         exp_tr.burst_size = 1;
         exp_tr.address = tr.address;
         exp_tr.data = 'X;

         if (
            (tr.address >= bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_BASE_ADDRESS) &&
            (tr.address < (bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_BASE_ADDRESS + bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_SIZE))
           ) begin // PR region controller in static region
            if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_STATUS) begin
               exp_tr.data[0] = {30'b0, region0_unfreeze_status, region0_freeze_status};
            end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_REGION_CTRL_SWVERSION) begin
               exp_tr.data[0] = 32'hAD000003;
            end
         end else if (active_persona_select != 4) begin // Is the active persona the HPR persona? If not proceed.
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
            end   
         end else if (active_persona_select == 4) begin // Is the active persona the HPR persona
            if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PR_REGION_0_PERSONA_ID_ADDRESS) begin
               // Read the persona id
               exp_tr.data[0] = decode_persona_id(active_persona_select);
            end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_0_PERSONA_ID_ADDRESS) begin
               // Read the persona id
               exp_tr.data[0] = decode_child0_persona_id(active_parent_perasona_child_0_persona_select);
            end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_1_PERSONA_ID_ADDRESS) begin
               // Read the persona id
               exp_tr.data[0] = decode_child1_persona_id(active_parent_perasona_child_1_persona_select);
            end else if (
                         (tr.address >= bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_0_REGION_CTRL_BASE_ADDRESS) &&
                         (tr.address < (bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_0_REGION_CTRL_BASE_ADDRESS + bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_0_REGION_CTRL_SIZE))
                        ) begin // PR region controller
               if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_0_REGION_CTRL_STATUS) begin
                  exp_tr.data[0] = {30'b0, pr_parent_region0_unfreeze_status, pr_parent_region0_freeze_status};
               end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_0_REGION_CTRL_SWVERSION) begin
                  exp_tr.data[0] = 32'hAD000003;
               end
            end else if (
                         (tr.address >= bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_1_REGION_CTRL_BASE_ADDRESS) &&
                         (tr.address < (bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_1_REGION_CTRL_BASE_ADDRESS + bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_1_REGION_CTRL_SIZE))
                        ) begin // PR region controller
               if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_1_REGION_CTRL_STATUS) begin
                  exp_tr.data[0] = {30'b0, pr_parent_region1_unfreeze_status, pr_parent_region1_freeze_status};
               end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_1_REGION_CTRL_SWVERSION) begin
                  exp_tr.data[0] = 32'hAD000003;
               end

            end else if (
                         (tr.address >= bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_0_BASE_ADDRESS) &&
                         (tr.address < (bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_0_BASE_ADDRESS + bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_0_REGFILE_SIZE))
                        ) begin // Child 0
               if (active_parent_perasona_child_0_persona_select == 32'd0) begin //ddr4_access
                  if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_0_HOST_TO_PR_0_ADDRESS) begin                     
                     exp_tr.data[0] = parent_persona_child0_host_to_pr_0;
                  end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_0_HOST_TO_PR_1_ADDRESS) begin                     
                     exp_tr.data[0] = parent_persona_child0_host_to_pr_1;
                  end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_0_HOST_TO_PR_2_ADDRESS) begin
                     exp_tr.data[0] = parent_persona_child0_host_to_pr_2;
                  end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_0_PR_TO_HOST_0_ADDRESS) begin
                     exp_tr.data[0] = parent_persona_child0_host_to_pr_2 + 32'd1;
                  end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_0_PR_TO_HOST_1_ADDRESS) begin
                     exp_tr.ignore_comparison = 1;
                     exp_tr.data[0]='X;
                  end
               end
            end else if (
                         (tr.address >= bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_1_BASE_ADDRESS) &&
                         (tr.address < (bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_1_BASE_ADDRESS + bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_1_REGFILE_SIZE))
                        ) begin // Child 1
               if (active_parent_perasona_child_1_persona_select == 32'd0) begin //ddr4_access
                  if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_1_HOST_TO_PR_0_ADDRESS) begin                     
                     exp_tr.data[0] = parent_persona_child1_host_to_pr_0;
                  end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_1_HOST_TO_PR_1_ADDRESS) begin                     
                     exp_tr.data[0] = parent_persona_child1_host_to_pr_1;
                  end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_1_HOST_TO_PR_2_ADDRESS) begin
                     exp_tr.data[0] = parent_persona_child1_host_to_pr_2;
                  end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_1_PR_TO_HOST_0_ADDRESS) begin
                     exp_tr.data[0] = parent_persona_child1_host_to_pr_2 + 32'd1;
                  end else if (tr.address == bar4_avmm_pkg::bar4_avmm_base_seq_c::PARENT_PERSONA_PR_REGION_1_PR_TO_HOST_1_ADDRESS) begin
                     exp_tr.ignore_comparison = 1;
                     exp_tr.data[0]='X;
                  end
               end
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
         exp_tr.data = 'X;

         if (
             (tr.address >= bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_BASE_ADDRESS) &&
             (tr.address < (bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_BASE_ADDRESS + bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_SIZE))
            ) begin // PR IP

            if (tr.address ==  bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_VERSION_ADDRESS) begin
               // Read the SW version
               exp_tr.data[0] = 32'h_AA50_0003;
            end else if (tr.address ==  bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_PR_POF_ID_ADDRESS) begin
               // Read the SW version
               exp_tr.data[0] = 32'h_DEAD_BEEF;
            end else if (tr.address ==  bar2_avmm_pkg::bar2_avmm_base_seq_c::PR_IP_STATUS_ADDRESS) begin
               // Read the PR IP status
               exp_tr.data[0] = pr_ip_model.get_pr_status();
            end
         end


      end else if (tr.request == avalon_mm_pkg::REQ_IDLE) begin
         exp_tr.request = tr.request;
      end

      return (exp_tr);
   endfunction

endclass


`endif //INC_SB_PREDICT_SV