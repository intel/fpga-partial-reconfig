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


`ifndef INC_ALTR_CMN_MACROS_SV
`define INC_ALTR_CMN_MACROS_SV

`include "uvm_macros.svh"

// Conditionally enable a UVM field if a condition is met
`define alt_cond_uvm_field(FIELD,COND) \
  begin \
     if (COND) begin \
        FIELD \
     end \
  end


`define altr_stringify(x) `"x`"

`define altr_assert(COND) \
  begin \
     if (!(COND)) begin \
        if (uvm_report_enabled(UVM_NONE,UVM_FATAL,"ASSERT")) \
          uvm_report_fatal ("ASSERT", $sformatf("ASSERT: %s at File:%s Line:%0d", `altr_stringify(COND), `__FILE__, `__LINE__), UVM_NONE, `__FILE__, `__LINE__, "", 1); \
     end \
  end

//==================================================================================================
// Common use macros
//==================================================================================================
`define altr_set_if(TYPE, SCOPE, NAME, VAL) \
   begin \
       uvm_pkg::uvm_resource_db#(TYPE)::set(SCOPE, NAME, VAL); \
   end

`define altr_get_if(TYPE, SCOPE, NAME, VAR) \
   begin \
       if (!uvm_pkg::uvm_resource_db#(TYPE)::read_by_name(SCOPE, NAME, VAR)) \
           uvm_report_fatal("ASSERT", $sformatf("Could not find interface name %s::%s in resource DB", SCOPE, NAME), UVM_NONE, `__FILE__, `__LINE__, "", 1); \
   end

`endif //INC_ALTR_CMN_MACROS_SV
