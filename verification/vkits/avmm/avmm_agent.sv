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

`ifndef INC_AVMM_AGENT_SV
`define INC_AVMM_AGENT_SV

class avmm_agent_c #(
    parameter type DRV_BFM_TYPE = virtual altera_avalon_mm_master_bfm_iface,
    parameter type MON_BFM_TYPE = virtual altera_avalon_mm_monitor_transactions_iface,
    parameter type CMD_T = avmm_command_seq_item_c,
    parameter type RSP_T = avmm_response_seq_item_c,
    int AV_ADDRESS_W = -1,
    int AV_DATA_W = -1,
    int USE_BURSTCOUNT = -1,
    int AV_BURSTCOUNT_W = -1,

    int AV_NUMSYMBOLS = -1,
    int AV_READRESPONSE_W = -1,
    int AV_WRITERESPONSE_W = -1,

    int USE_WRITE_RESPONSE = -1,
    int USE_READ_RESPONSE = -1
    
    
) extends uvm_agent;
   `uvm_component_param_utils(avmm_agent_c #(DRV_BFM_TYPE, MON_BFM_TYPE, CMD_T, RSP_T, AV_ADDRESS_W, AV_DATA_W, USE_BURSTCOUNT, AV_BURSTCOUNT_W, AV_NUMSYMBOLS, AV_READRESPONSE_W, AV_WRITERESPONSE_W, USE_WRITE_RESPONSE, USE_READ_RESPONSE))

   uvm_active_passive_enum is_active = UVM_ACTIVE;

   uvm_analysis_port #(CMD_T) command_aport;
   uvm_analysis_port #(RSP_T) response_aport;

   avmm_driver_c #(
      .T(CMD_T),
      .BFM_TYPE(DRV_BFM_TYPE),
      .AV_ADDRESS_W(AV_ADDRESS_W),
      .AV_DATA_W(AV_DATA_W),
      .USE_BURSTCOUNT(USE_BURSTCOUNT),
      .USE_WRITE_RESPONSE(USE_WRITE_RESPONSE),
      .USE_READ_RESPONSE(USE_READ_RESPONSE)
   ) drv;

   avmm_monitor_c #(
      .BFM_TYPE(MON_BFM_TYPE),
      .CMD_T(CMD_T),
      .RSP_T(RSP_T),
      .AV_ADDRESS_W(AV_ADDRESS_W),
      .AV_DATA_W(AV_DATA_W),
      .USE_BURSTCOUNT(USE_BURSTCOUNT),
      .AV_BURSTCOUNT_W(AV_BURSTCOUNT_W),
      .AV_NUMSYMBOLS(AV_NUMSYMBOLS),
      .AV_READRESPONSE_W(AV_READRESPONSE_W),
      .AV_WRITERESPONSE_W(AV_WRITERESPONSE_W),
      .USE_WRITE_RESPONSE(USE_WRITE_RESPONSE),
      .USE_READ_RESPONSE(USE_READ_RESPONSE)
   ) mon;

   avmm_sequencer_c #(
      .T(CMD_T)
   ) sqr;

   function new(string name = "avmm_agent", uvm_component parent);
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (is_active == UVM_ACTIVE) begin
         drv = 
         avmm_driver_c #(
            .T(CMD_T),
            .BFM_TYPE(DRV_BFM_TYPE),
            .AV_ADDRESS_W(AV_ADDRESS_W),
            .AV_DATA_W(AV_DATA_W),
            .USE_BURSTCOUNT(USE_BURSTCOUNT),
            .USE_WRITE_RESPONSE(USE_WRITE_RESPONSE),
            .USE_READ_RESPONSE(USE_READ_RESPONSE)
         )
         ::type_id::create("drv", this);

         sqr = 
         avmm_sequencer_c #(
            .T(CMD_T)
         ) 
         ::type_id::create("sqr", this);
      end

      mon = 
       avmm_monitor_c #(
         .BFM_TYPE(MON_BFM_TYPE),
         .CMD_T(CMD_T),
         .RSP_T(RSP_T),
         .AV_ADDRESS_W(AV_ADDRESS_W),
         .AV_DATA_W(AV_DATA_W),
         .USE_BURSTCOUNT(USE_BURSTCOUNT),
         .AV_BURSTCOUNT_W(AV_BURSTCOUNT_W),
         .AV_NUMSYMBOLS(AV_NUMSYMBOLS),
         .AV_READRESPONSE_W(AV_READRESPONSE_W),
         .AV_WRITERESPONSE_W(AV_WRITERESPONSE_W),
         .USE_WRITE_RESPONSE(USE_WRITE_RESPONSE),
         .USE_READ_RESPONSE(USE_READ_RESPONSE)
      )
      ::type_id::create("mon", this);

      command_aport = new("command_aport", this);
      response_aport = new("response_aport", this);
   endfunction

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);

      if (is_active == UVM_ACTIVE) begin
         drv.seq_item_port.connect(sqr.seq_item_export);
      end

      mon.command_aport.connect(command_aport);
      mon.response_aport.connect(response_aport);
      mon.upstream_command_port.connect(drv.upstream_command_port);
   endfunction

endclass

`endif //INC_AVMM_AGENT_SV
