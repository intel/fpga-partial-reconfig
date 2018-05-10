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

###############################################################################
# CONFIGURE YOUR COMPILATION HERE:
#   This file must be renamed to setup.tcl or specified to the flow
#   script using the -setup_script parameter
###############################################################################
# Define the name of the project. This corresponds to the name of the QPF
# file. Note that all revisions must be present in the QPF file.
define_project blinking_led

# Define the base revision name. This revision represents the static
# region of the design
define_base_revision blinking_led

# Define each of the partial reconfiguration implementation revisions by
# providing the PR implementation revision name, the synthesis revision name
# and partition name. This provides the mapping from the synthesis revision for
# use in implementing the partition for the given implementation compilation.
# For designs with multiple PR regions, you must provide multiple synthesis
# revisions and partition names. The partition name is the name assigned to the
# partition using the PARTITION assignment in the Quartus Settings File (.qsf).
#
# The define_pr_impl_partition accepts a single -impl_rev_name argument
# which defines the implementation revision name, a single
# -partition_name argument which specifies the partition name, a single
# -source_rev_name argument which specifies the synthesis revision name
# for the partition. During the compilation, the PR implementation revision
# imports all necessary synthesis revisions to implement the partitions
# required. The define_pr_impl_partition command is called multiple times
# with the same -impl_rev_name argument for designs with multiple PR
# partitions.
#
# The example defines a PR implementation revision named top_v2 where the
# partition named auto_partition is to be implemented using the synthesized
# snapshot from the synth_auto_pr_v2 revision, and the time_partition
# is to be implemented using the synthesized snapshot from the
# synth_time_pr_v2 revision. To compile only the first implementation in this 
# example you can run this script using command:
# qpro_sh -t s10_partial_reconfig/flow.tcl -impl top_v2 

# Define the top_v2 PR implementation revision. Since there are 2 PR partitions
# in this revision, we run define_pr_impl_partition twice for the same
# revision name.

define_pr_impl_partition -impl_rev_name blinking_led_pr_alpha \
-partition_name pr_partition\
-source_rev_name blinking_led_default

define_pr_impl_partition -impl_rev_name blinking_led_pr_charlie \
-partition_name pr_partition\
-source_rev_name blinking_led_empty

define_pr_impl_partition -impl_rev_name blinking_led_pr_bravo \
-partition_name pr_partition\
-source_rev_name blinking_led_slow

# The set_flow_option can be used to specify different options for the
# compilation flow. The first parameter to set_flow_option is the option
# name and the second parameter is the option value.
#
# Enable the Power Analyzer
#set_flow_option -name ENABLE_POWER_ANALYZER on
#
