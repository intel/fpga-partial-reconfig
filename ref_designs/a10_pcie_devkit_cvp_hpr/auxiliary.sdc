# Copyright (c) 2001-2017 Intel Corporation
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

# set asynchronous clock domains
set_false_path -from {u_top|design_core|ddr4_status_bus|u_synch_fail|d[0]} -to {u_top|design_core|ddr4_status_bus|u_synch_fail|c[0]}
set_false_path -from {u_top|design_core|ddr4_status_bus|u_synch_success|d[0]} -to {u_top|design_core|ddr4_status_bus|u_synch_success|c[0]}
set_clock_groups -asynchronous -group [get_clocks {u_top|ddr4_emif|ddr4_ctlr_emif_0_core_usr_clk}] -group [get_clocks {u_top|design_core|top_iopll|top_iopll_0|outclk_250mhz}]

set tx_ser_clk [get_clocks *tx_serial_clk]

if {[get_collection_size $tx_ser_clk] != 1} {
    puts "Error: tx_serial_clk does not exist or more than 1 tx_serial_clk"
    puts "Error: make sure derive_pll_clocks -create_base_clocks is run"
} else {
    set clk_prefix [join [lrange [split [query_collection $tx_ser_clk] {|}] 0 {end-1}] {|}] 
}

set byte_ser_clk_pins [get_pins  -compatibility_mode *|byte_deserializer_pcs_clk_div_by_4_txclk_reg]

if {[get_collection_size $byte_ser_clk_pins] < 1} {
    puts "Error: possibly a timing model issue"
} else {
    set byte_ser_clk_pin0 [lindex [query_collection $byte_ser_clk_pins] 0]
    set hip_presence [regexp {(^.*)\|altpcie_a10_hip_pipen1b} $byte_ser_clk_pin0 all clk_pin_prefix]
}

set phy_lane0_size 0 ;#Gen 3x1
set phy_lane1_size 0 ;#Gen 3x2
set phy_lane3_size 0 ;#Gen 3x4
set phy_lane7_size 0 ;#Gen 3x8

set phy_lane0 [get_registers {*phy_g3x*|g_xcvr_native_insts[0]*}]
set phy_lane1 [get_registers {*phy_g3x*|g_xcvr_native_insts[1]*}]
set phy_lane3 [get_registers {*phy_g3x*|g_xcvr_native_insts[3]*}]
set phy_lane7 [get_registers {*phy_g3x*|g_xcvr_native_insts[7]*}]

set phy_lane0_size [get_collection_size $phy_lane0]
set phy_lane1_size [get_collection_size $phy_lane1]
set phy_lane3_size [get_collection_size $phy_lane3]
set phy_lane7_size [get_collection_size $phy_lane7]

if {$phy_lane7_size > 0} {
               set stop 8
               } elseif {$phy_lane3_size > 0} {
               set stop 4
               } elseif {$phy_lane1_size > 0} {
               set stop 2
               } elseif {$phy_lane0_size > 0} {
               set stop 1
               } else {
               set stop 0
               }

for {set i 0} {$i != $stop} {incr i} {
   create_generated_clock -divide_by 1 \
      -source     "$clk_pin_prefix|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x*.phy_g3x*|phy_g3x*|g_xcvr_native_insts[$i].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|byte_deserializer_pcs_clk_div_by_2_txclk_reg" \
      -name       "$clk_prefix|rx_pcs_clk_div_by_4[$i]" \
                  "$clk_pin_prefix|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x*.phy_g3x*|phy_g3x*|g_xcvr_native_insts[$i].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|sta_rx_clk2_by2_1" ;# target

   create_generated_clock -multiply_by 1 -divide_by 1 \
      -source     "$clk_pin_prefix|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x*.phy_g3x*|phy_g3x*|g_xcvr_native_insts[$i].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|byte_serializer_pcs_clk_div_by_2_reg" \
      -name       "$clk_prefix|tx_pcs_clk_div_by_4[$i]" \
                  "$clk_pin_prefix|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x*.phy_g3x*|phy_g3x*|g_xcvr_native_insts[$i].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|sta_tx_clk2_by2_1" ;# target
}

#Constraint for Gen 3x2 and up
if {$phy_lane1_size > 0} {
create_generated_clock -multiply_by 1 -divide_by 5 \
   -source        "$clk_pin_prefix|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_pll.g_pll_g3n.lcpll_g3xn|lcpll_g3xn|a10_xcvr_atx_pll_inst|twentynm_hssi_pma_cgb_master_inst|clk_fpll_*" \
   -master_clock  "$clk_prefix|tx_serial_clk" \
   -name          "$clk_prefix|tx_bonding_clocks[0]" \
                  "$clk_pin_prefix|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_pll.g_pll_g3n.lcpll_g3xn|lcpll_g3xn|a10_xcvr_atx_pll_inst|twentynm_hssi_pma_cgb_master_inst|cpulse_out_bus[0]"
                                                                                                                                                                                                                                                                                                                                                                                                                                    
}

set rx_clkouts [list]
for {set i 0} {$i != $stop} {incr i} {

               create_generated_clock -multiply_by 1 \
      -source        "$clk_pin_prefix|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x*.phy_g3x*|phy_g3x*|g_xcvr_native_insts[$i].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|byte_deserializer_pcs_clk_div_by_4_txclk_reg" \
      -master_clock  "$clk_prefix|tx_bonding_clocks[0]" \
      -name          "$clk_prefix|g_xcvr_native_insts[$i]|rx_clk" \
                     "$clk_pin_prefix|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x*.phy_g3x*|phy_g3x*|g_xcvr_native_insts[$i].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|sta_rx_clk2_by4_1" ;# target

               create_generated_clock -multiply_by 1 \
      -source        "$clk_pin_prefix|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x*.phy_g3x*|phy_g3x*|g_xcvr_native_insts[$i].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|byte_deserializer_pld_clk_div_by_4_txclk_reg" \
      -master_clock  "$clk_prefix|tx_bonding_clocks[0]" \
      -name          "$clk_prefix|g_xcvr_native_insts[$i]|rx_clkout" \
                     "$clk_pin_prefix|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x*.phy_g3x*|phy_g3x*|g_xcvr_native_insts[$i].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|sta_rx_clk2_by4_1_out"

  set_clock_groups -exclusive -group "$clk_prefix|tx_bonding_clocks[0]" -group "$clk_prefix|g_xcvr_native_insts[$i]|rx_clkout"
   set_clock_groups -exclusive -group "$clk_prefix|tx_bonding_clocks[0]"    -group "$clk_prefix|rx_pcs_clk_div_by_4[$i]"
}

