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

`ifndef INC_ALTR_VERBOSITY_UVM_PKG_SV
`define INC_ALTR_VERBOSITY_UVM_PKG_SV

`include "uvm_macros.svh"

package verbosity_pkg;
   import uvm_pkg::*;

   typedef enum int {
      VERBOSITY_NONE,
      VERBOSITY_FAILURE,
      VERBOSITY_ERROR,
      VERBOSITY_WARNING,
      VERBOSITY_INFO,
      VERBOSITY_DEBUG
   } Verbosity_t;

   function automatic void print( 
      Verbosity_t level,
      string message
      );

      case (level)
         VERBOSITY_NONE: `uvm_info("VERB", message, UVM_LOW)
         VERBOSITY_FAILURE: `uvm_fatal("VERB", message)
         VERBOSITY_ERROR: `uvm_error("VERB", message)
         VERBOSITY_WARNING: `uvm_warning("VERB", message)
         VERBOSITY_INFO: `uvm_info("VERB", message, UVM_LOW)
         VERBOSITY_DEBUG: `uvm_info("VERB", message, UVM_DEBUG)
         default: `uvm_info("VERB", message, UVM_LOW)
      endcase
   endfunction

   function automatic void abort_simulation();
      string message;
      $sformat(message, "%m: Abort the simulation due to fatal error incident.");
      print(VERBOSITY_FAILURE, message);
   endfunction

   function automatic void print_divider(
      Verbosity_t level
      );
      string message;
      $sformat(message,
               "------------------------------------------------------------");
      print(level, message);
   endfunction

endpackage


`endif //INC_ALTR_VERBOSITY_UVM_PKG_SV
   

