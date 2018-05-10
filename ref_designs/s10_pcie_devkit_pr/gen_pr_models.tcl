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

load_package flow

set module_names [list \
    basic_arithmetic_persona_top \
    basic_dsp_persona_top \
    ddr4_access_persona_top \
    gol_persona_top

]

set rev_names [list \
    s10_pcie_devkit_pr_basic_arithmetic \
    s10_pcie_devkit_pr_basic_dsp \
    s10_pcie_devkit_pr_ddr4_access \
    s10_pcie_devkit_pr_gol

]
project_open s10_pcie_devkit_pr -rev s10_pcie_devkit_pr
execute_module -tool syn
execute_module -tool cdb -args "--export_pr_static_block root_partition --snapshot synthesized --file s10_pcie_devkit_pr_static.qdb"
project_close
foreach rev $rev_names module $module_names {
    project_open s10_pcie_devkit_pr -rev $rev
    execute_module -tool ipg -args "--synthesis=verilog --simulation=verilog"
    execute_module -tool syn
    execute_module -tool eda -args "--pr --simulation --tool=vcsmx --format=verilog --partition=pr_partition --module=pr_partition=$module"
    project_close
}

