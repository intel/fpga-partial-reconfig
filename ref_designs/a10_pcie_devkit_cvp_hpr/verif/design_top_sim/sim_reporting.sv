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

`ifndef INC_SIM_REPORTING_SV
`define INC_SIM_REPORTING_SV


// ----------------------------------------------
// Package of commonly used test registration and reporting functions
// ----------------------------------------------

class sim_report;

   // Define the reporting struct
   string test_name;
   bit pass_fail;
   bit test_active;
   time start_time;
   time end_time;

   function new(string name);

      test_name = name;
      pass_fail = 0;

      // Write the test message to STDOUT
      `uvm_info("RPT", $sformatf("*** Registered test %s ***", test_name), UVM_LOW)

   endfunction


   virtual function start_test();
      test_active = 1;
      start_time = $time;

      // Write the test message to STDOUT
      `uvm_info("RPT", $sformatf("*** Preparing to run test %s ***", test_name), UVM_LOW)

   endfunction

   // Call this method at the end of every test
   virtual function end_test(
      bit test_pass_fail
      );

      // Make sure the test is active
      assert (test_active == 1)
      else begin
         `uvm_fatal("RPT", $sformatf("[INTERNAL ERROR] %t\tTest is not active \n", $time))
         $finish;
      end

      `uvm_info("RPT", $sformatf("Ending test called %s with pass = %d", test_name, pass_fail), UVM_LOW)

      // Mark the test as complete, update the status
      test_active = 0;
      pass_fail = test_pass_fail;
      end_time = $time;

      // Write the test status to STDOUT
      `uvm_info("RPT", $sformatf("*** Test: %s %s ***", test_name, pass_fail_string()), UVM_MEDIUM)
   endfunction

   function automatic string pass_fail_string();
      if (pass_fail)
         pass_fail_string = "Pass";
      else
         pass_fail_string = "Fail";
   endfunction

endclass

class sim_reporting;

   sim_report tests_list [$];

   function new();
      tests_list.delete();
   endfunction

   virtual function sim_report add_test(string test_name);
      sim_report new_test;

      new_test = new(test_name);
      tests_list.push_back(new_test);
      return new_test;
   endfunction

   virtual function summarize_test_results();
      integer i;
      integer passed_tests = 0;
      sim_report cur_report_test;
      bit failed_tests = 0;

      // Make sure there is no active test
      for (i = 0; i < tests_list.size(); i++) begin
         assert (tests_list [i].test_active == 0)
         else begin
            `uvm_fatal("RPT", $sformatf("[INTERNAL ERROR] %t\tAn active tests still exists called %s\n", $time, tests_list [i].test_name))
            $finish;
         end
      end

      // Count test statistics
      for (i = 0; i < tests_list.size(); i++) begin
         if (tests_list [i].pass_fail == 1)
            passed_tests++;
         else
            failed_tests = 1;
      end


      `uvm_info("RPT", $sformatf("*** number_of_successful_tests: %0d (successful assertions) ***", passed_tests), UVM_LOW)

      // verbosity_pkg::print the test report table
      $display("******************** TEST SUMMARY ********************");
      while (tests_list.size() > 0) begin
         cur_report_test = tests_list.pop_front();
         $display($sformatf( "Test (@%0t-%0t): %s => %s", cur_report_test.start_time, cur_report_test.end_time, cur_report_test.test_name, cur_report_test.pass_fail_string()));
      end
      $display("*****************************************************");

      if (failed_tests) begin
         $display("*** Test(s) failed ***");
         $display("TEST_ERROR");
      end else begin
         $display("*** Test(s) passed ***");
         $display("TEST_PASS");
      end

   endfunction

endclass

`endif //INC_SIM_REPORTING_SV
