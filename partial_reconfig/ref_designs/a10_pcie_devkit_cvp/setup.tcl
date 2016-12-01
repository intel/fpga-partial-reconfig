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

# Define the name of the project.
define_project a10_pcie_devkit_cvp

# Define the base revision name. This revision represents the static
# region of the design
define_base_revision a10_pcie_devkit_cvp

# Define each of the partial reconfiguration implementation revisions
define_pr_impl_partition -impl_rev_name a10_pcie_devkit_cvp_ddr4_access \
	-partition_name pr_partition \
    -source_rev_name  ddr4_access

define_pr_impl_partition -impl_rev_name a10_pcie_devkit_cvp_register_file \
	-partition_name pr_partition \
    -source_rev_name  register_file

define_pr_impl_partition -impl_rev_name a10_pcie_devkit_cvp_basic_arithmetic \
    -partition_name pr_partition \
    -source_rev_name  basic_arithmetic

define_pr_impl_partition -impl_rev_name pr_example_template_impl \
    -partition_name pr_partition \
    -source_rev_name  pr_example_template_synth
