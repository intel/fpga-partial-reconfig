# Copyright (c) 2001-2016 Intel Corporation
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
set_clock_groups -asynchronous -group {u_pcie_subsystem|a10_pcie|a10_pcie|wys~CORE_CLK_OUT} -group {u_mem_ctlr|ddr4a|ddr4a_phy_clk_0 u_mem_ctlr|ddr4a|ddr4a_phy_clk_1 u_mem_ctlr|ddr4a|ddr4a_phy_clk_2 u_mem_ctlr|ddr4a|ddr4a_phy_clk_l_0 u_mem_ctlr|ddr4a|ddr4a_phy_clk_l_1 u_mem_ctlr|ddr4a|ddr4a_phy_clk_l_2 u_mem_ctlr|ddr4a|ddr4a_core_cal_slave_clk} -group {u_iopll|iopll_0|outclk1 u_iopll|iopll_0|outclk_50mhz}

# set false path on the signals crossing the async clock domains
set_false_path -from {u_freeze_wrapper|u_pr_logic|u_synchronizer_cal_success|d[0]} -to {u_freeze_wrapper|u_pr_logic|u_synchronizer_cal_success|c[0]}
set_false_path -from {u_freeze_wrapper|u_pr_logic|u_synchronizer_cal_fail|d[0]} -to {u_freeze_wrapper|u_pr_logic|u_synchronizer_cal_fail|c[0]}
set_false_path -from [get_keepers {u_freeze_wrapper|u_pr_logic|u_rst_blk|ddr4a_global_reset}] -to [get_clocks {u_ddr4_ctlr|*}]
