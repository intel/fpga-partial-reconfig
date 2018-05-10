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


`ifndef INC_TWENTYNM_PRBLOCK_AGENT_SV
`define INC_TWENTYNM_PRBLOCK_AGENT_SV

class twentynm_prblock_agent_c extends uvm_agent;
   `uvm_component_utils(twentynm_prblock_agent_c)

   uvm_analysis_port #(twentynm_prblock_seq_item_c) aport;

   twentynm_prblock_monitor_c mon;

   function new(string name = "twentynm_prblock_agent", uvm_component parent);
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      mon = twentynm_prblock_monitor_c::type_id::create("mon", this);
      aport = new("aport", this);
   endfunction

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);

      mon.aport.connect(aport);
   endfunction

endclass

`endif //INC_TWENTYNM_PRBLOCK_AGENT_SV
