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


`ifndef INC_ALTR_CMN_MACROS_SV
`define INC_ALTR_CMN_MACROS_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

//==================================================================================================
// Conditionally enable a UVM field if a condition is met
//==================================================================================================
`define alt_cond_uvm_field(FIELD,COND) \
  begin \
     if (COND) begin \
        FIELD \
     end \
  end


//==================================================================================================
// Stringify a variable type
//==================================================================================================
`define altr_stringify(x) `"x`"

//==================================================================================================
// Assert
//==================================================================================================
`define altr_assert(COND) \
  begin \
     if (!(COND)) begin \
        if (uvm_report_enabled(UVM_NONE,UVM_FATAL,"ASSERT")) \
          uvm_report_fatal ("ASSERT", $sformatf("ASSERT: %s at File:%s Line:%0d", `altr_stringify(COND), `__FILE__, `__LINE__), UVM_NONE, `__FILE__, `__LINE__, "", 1); \
     end \
  end

//==================================================================================================
// Cast or assert
//==================================================================================================
`define altr_cast(dest_t, source_t) \
   `altr_assert($cast(dest_t, source_t) == 1)

//==================================================================================================
// Common use macros for getting interfaces from the resource DB
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

//==================================================================================================
// Color setting macros
//==================================================================================================
// TYPE specifiers
// 1 set bold 
// 2 set half-bright
// 4 set underscore
// 5 set blink 
// 7 set reverse video 

// COLOR specifiers
// 30 black
// 31 red
// 32 green
// 33 brown
// 34 blue
// 35 magenta
// 36 cyan
// 37 white
`define altr_color_default $write("%c[0m",27); // Normal
`define altr_color_red $write("%c[1;31m",27); // Red Bold
`define altr_color_green $write("%c[1;32m",27); // Green Bold


`endif //INC_ALTR_CMN_MACROS_SV
