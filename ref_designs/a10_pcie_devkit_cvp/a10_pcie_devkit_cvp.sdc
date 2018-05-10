# Copyright (c) 2001-2018 Intel Corporation
#  
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#  
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#  
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

derive_pll_clocks -create_base_clocks

# PCIe IP sdc assignments

if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[0]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[0]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[1]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[1]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[2]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[2]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[3]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[3]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[4]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[4]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[5]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[5]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[6]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[6]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[7]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[7]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[8]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[8]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[9]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[9]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[10]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[10]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[11]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[11]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[12]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[12]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[13]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[13]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[14]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[14]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[15]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[15]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[16]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[16]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[17]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[17]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[18]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[18]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[19]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[19]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[20]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[20]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[21]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[21]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[22]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[22]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[23]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[23]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[24]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[24]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[25]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[25]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[26]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[26]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[27]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[27]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[28]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[28]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[29]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[29]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[30]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[30]}] -to *
}
if { [ get_collection_size [get_registers -nocase -nowarn {*altpcie_test_in_static_signal_to_be_false_path[31]}]] > 0 } {
   set_false_path -from [get_registers {*altpcie_test_in_static_signal_to_be_false_path[31]}] -to *
}
if { [ get_collection_size [get_ports -nocase -nowarn {*board_pins_lane_active_led[0]}]] > 0 } {
   set_false_path  -from * -to [get_ports {*board_pins_lane_active_led[0]}] 
}
if { [ get_collection_size [get_ports -nocase -nowarn {*board_pins_lane_active_led[1]}]] > 0 } {
   set_false_path  -from * -to [get_ports {*board_pins_lane_active_led[1]}] 
}
if { [ get_collection_size [get_ports -nocase -nowarn {*board_pins_lane_active_led[2]}]] > 0 } {
   set_false_path  -from * -to [get_ports {*board_pins_lane_active_led[2]}] 
}
if { [ get_collection_size [get_ports -nocase -nowarn {*board_pins_lane_active_led[3]}]] > 0 } {
   set_false_path  -from * -to [get_ports {*board_pins_lane_active_led[3]}] 
}
if { [ get_collection_size [get_ports -nocase -nowarn {*board_pins_gen2_led}]] > 0 } {
   set_false_path  -from * -to [get_ports {*board_pins_gen2_led}] 
}
if { [ get_collection_size [get_ports -nocase -nowarn {*board_pins_gen3_led}]] > 0 } {
   set_false_path  -from * -to [get_ports {*board_pins_gen3_led}] 
}
if { [ get_collection_size [get_ports -nocase -nowarn {*board_pins_L0_led}]] > 0 } {
   set_false_path  -from * -to [get_ports {*board_pins_L0_led}] 
}
if { [ get_collection_size [get_ports -nocase -nowarn {*board_pins_alive_led}]] > 0 } {
   set_false_path  -from * -to [get_ports {*board_pins_alive_led}] 
}
if { [ get_collection_size [get_ports -nocase -nowarn {*board_pins_comp_led}]] > 0 } {
   set_false_path  -from * -to [get_ports {*board_pins_comp_led}] 
}
if { [ get_collection_size [get_ports -nocase -nowarn {*board_pins_req_compliance_pb}]] > 0 } {
   set_false_path -from [get_ports {*board_pins_req_compliance_pb}] -to *
}
if { [ get_collection_size [get_ports -nocase -nowarn {*board_pins_set_compliance_mode}]] > 0 } {
   set_false_path -from [get_ports {*board_pins_set_compliance_mode}] -to *
}
if { [ get_collection_size [get_ports -nocase -nowarn {*hip_ctrl_*}]] > 0 } {
   set_false_path -from [get_ports {*hip_ctrl_*}] -to *
}
if { [ get_collection_size [get_ports -nocase -nowarn {*pcie_rstn_pin_perst}]] > 0 } {
   set_false_path -from [get_ports {*pcie_rstn_pin_perst}] -to *
}
if { [ get_collection_size [get_ports -nocase -nowarn {*pcie_rstn_npor}]] > 0 } {
   set_false_path -from [get_ports {*pcie_rstn_npor}] -to *
}
if { [ get_collection_size [get_ports -nocase -nowarn {*pipe_sim_only*ltssmstate[*]}]] > 0 } {
   set_false_path  -from * -to [get_ports {*pipe_sim_only*ltssmstate[*]}] 
}

