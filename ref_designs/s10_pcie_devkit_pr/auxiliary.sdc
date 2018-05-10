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

# set asynchronous clock domains
set_false_path -from {u_top|design_core|ddr4_status_bus|u_synch_fail|d[0]} -to {u_top|design_core|ddr4_status_bus|u_synch_fail|c[0]}
set_false_path -from {u_top|design_core|ddr4_status_bus|u_synch_success|d[0]} -to {u_top|design_core|ddr4_status_bus|u_synch_success|c[0]}
#set_false_path -from {u_top|design_core|global_rst_n_controller|global_rst_n_d} -to {u_top|design_core|ddr4_status_bus|u_synch_success|c[*]}
#set_false_path -from {u_top|design_core|global_rst_n_controller|global_rst_n_d} -to {u_top|design_core|ddr4_status_bus|u_synch_fail|c[*]}
#set_false_path -from {u_top|s10_pcie|s10_pcie|rst_sync|sync_rst_n_rr[*]} -to {u_top|design_core|global_rst_n_controller|global_rst_n_d}
set_clock_groups -asynchronous -group [get_clocks {u_top|bsp_top_emif_s10_0|bsp_top_emif_s10_0_core_usr_clk}] -group [get_clocks {u_top|design_core|design_top_iopll|design_top_iopll_clock_125MHz}]
set_clock_groups -asynchronous -group [get_clocks {u_top|s10_pcie|s10_pcie|hip|altera_pcie_s10_hip_ast_pipen1b_inst|altera_pcie_s10_hip_ast_pllnphy_inst|g_phy_g2x8.phy_g2x8|phy_g2x8|xcvr_hip_native|ch0}] -group [get_clocks {u_top|design_core|design_top_iopll|design_top_iopll_refclk}]
set_false_path -from {auto_fab_0|alt_sld_fab_0|alt_sld_fab_0|mboxfabric|stream_active_0_clock_crosser_0|d[0]} -to {auto_fab_0|alt_sld_fab_0|alt_sld_fab_0|mboxfabric|stream_active_0_clock_crosser_0|c[0]}
