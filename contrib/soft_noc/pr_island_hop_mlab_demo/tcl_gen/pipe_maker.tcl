# Copyright (c) Intel Corporation
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

set qsf_file_name [lindex $argv 0]

set sector_col 40
set sector_row 41
set rule_of_eleven 11
set prr_sector_height 3
set prr_sector_width 4

if {$argc != 1} {
    puts -nonewline "usage :: tclsh pipe_maker.tcl <qsf file name>"
    exit
}

# Open the qsf file for appending
set qsf_file_handle [open $qsf_file_name "a"]

puts $qsf_file_handle "\n"

# North/South
puts $qsf_file_handle "\# North/South\n"

set start_x 66
set y_span 7
set north_constant_y_origin 167
set north_constant_y_top [expr {$north_constant_y_origin + $y_span}]
set south_constant_y_origin 36
set south_constant_y_top [expr {$south_constant_y_origin + $y_span}]

set skip_array {1 2 1 1 1 2 1 2 1 2}
set skip_index 0

set group_index 0

set mirror_x [expr {$start_x + 211}]

for {set i 0} {$i < $prr_sector_width/2} {incr i} {
    set mirror_i [expr {$prr_sector_width - $i - 1}]
    for {set j 0} {$j < $sector_col} {incr j} {
	set mirror_j [expr {$sector_col - $j - 1}]

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$start_x $north_constant_y_origin $start_x $north_constant_y_top\" -to north_in_reg\[$i\]\[$j\]"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to north_in_reg\[$i\]\[$j\]"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to north_in_reg\[$i\]\[$j\]"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME north_in_reg\[$i\]\[$j\] -to north_in_reg\[$i\]\[$j\]\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$start_x $north_constant_y_origin $start_x $north_constant_y_top\" -to north_to_south_sector_size_${i}_north_to_south_ip_size_${j}_bus_first_ingress*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to north_to_south_sector_size_${i}_north_to_south_ip_size_${j}_bus_first_ingress*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to north_to_south_sector_size_${i}_north_to_south_ip_size_${j}_bus_first_ingress*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME north_to_south_sector_size_${i}_north_to_south_ip_size_${j}_bus_first_ingress -to north_to_south_sector_size_${i}_north_to_south_ip_size_${j}_bus_first_ingress*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$start_x $north_constant_y_origin $start_x $north_constant_y_top\" -to north_to_south_sector_size_${i}_north_to_south_ip_size_${j}_bus_first_fifo_control*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to north_to_south_sector_size_${i}_north_to_south_ip_size_${j}_bus_first_fifo_control*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to north_to_south_sector_size_${i}_north_to_south_ip_size_${j}_bus_first_fifo_control*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME north_to_south_sector_size_${i}_north_to_south_ip_size_${j}_bus_first_fifo_control -to north_to_south_sector_size_${i}_north_to_south_ip_size_${j}_bus_first_fifo_control*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$start_x $north_constant_y_origin $start_x $north_constant_y_top\" -to south_to_north_sector_size_${i}_south_to_north_ip_size_${j}_bus_first_egress*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to south_to_north_sector_size_${i}_south_to_north_ip_size_${j}_bus_first_egress*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to south_to_north_sector_size_${i}_south_to_northth_ip_size_${j}_bus_first_egress*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME south_to_north_sector_size_${i}_south_to_north_ip_size_${j}_bus_first_egress -to south_to_north_sector_size_${i}_south_to_north_ip_size_${j}_bus_first_egress*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$start_x $north_constant_y_origin $start_x $north_constant_y_top\" -to north_out\[$i\]\[$j\]*~reg0"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to north_out\[$i\]\[$j\]*~reg0"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to north_out\[$i\]\[$j\]*~reg0"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME north_out_reg\[$i\]\[$j\] -to north_out\[$i\]\[$j\]*~reg0\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$start_x $south_constant_y_origin $start_x $south_constant_y_top\" -to south_in_reg\[$i\]\[$j\]"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to south_in_reg\[$i\]\[$j\]"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to south_in_reg\[$i\]\[$j\]"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME south_in_reg\[$i\]\[$j\] -to south_in_reg\[$i\]\[$j\]\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$start_x $south_constant_y_origin $start_x $south_constant_y_top\" -to south_to_north_sector_size_${i}_south_to_north_ip_size_${j}_bus_first_ingress*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to south_to_north_sector_size_${i}_south_to_north_ip_size_${j}_bus_first_ingress*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to south_to_north_sector_size_${i}_south_to_north_ip_size_${j}_bus_first_ingress*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME south_to_north_sector_size_${i}_south_to_north_ip_size_${j}_bus_first_ingress -to south_to_north_sector_size_${i}_south_to_north_ip_size_${j}_bus_first_ingress*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$start_x $south_constant_y_origin $start_x $south_constant_y_top\" -to south_to_north_sector_size_${i}_south_to_north_ip_size_${j}_bus_first_fifo_control*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to south_to_north_sector_size_${i}_south_to_north_ip_size_${j}_bus_first_fifo_control*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to south_to_north_sector_size_${i}_south_to_north_ip_size_${j}_bus_first_fifo_control*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME south_to_north_sector_size_${i}_south_to_north_ip_size_${j}_bus_first_fifo_control -to south_to_north_sector_size_${i}_south_to_north_ip_size_${j}_bus_first_fifo_control*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$start_x $south_constant_y_origin $start_x $south_constant_y_top\" -to north_to_south_sector_size_${i}_north_to_south_ip_size_${j}_bus_first_egress*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to north_to_south_sector_size_${i}_north_to_south_ip_size_${j}_bus_first_egress*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to north_to_south_sector_size_${i}_north_to_south_ip_size_${j}_bus_first_egress*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME north_to_south_sector_size_${i}_north_to_south_ip_size_${j}_bus_first_egress -to north_to_south_sector_size_${i}_north_to_south_ip_size_${j}_bus_first_egress*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$start_x $south_constant_y_origin $start_x $south_constant_y_top\" -to south_out\[$i\]\[$j\]*~reg0"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to south_out\[$i\]\[$j\]*~reg0"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to south_out\[$i\]\[$j\]*~reg0"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME south_out_reg\[$i\]\[$j\] -to south_out\[$i\]\[$j\]*~reg0\n\n"

	# mirror

	puts $qsf_file_handle "\# mirror\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$mirror_x $north_constant_y_origin $mirror_x $north_constant_y_top\" -to north_in_reg\[$mirror_i\]\[$mirror_j\]"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to north_in_reg\[$mirror_i\]\[$mirror_j\]"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to north_in_reg\[$mirror_i\]\[$mirror_j\]"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME north_in_reg\[$mirror_i\]\[$mirror_j\] -to north_in_reg\[$mirror_i\]\[$mirror_j\]\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$mirror_x $north_constant_y_origin $mirror_x $north_constant_y_top\" -to north_to_south_sector_size_${mirror_i}_north_to_south_ip_size_${mirror_j}_bus_first_ingress*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to north_to_south_sector_size_${mirror_i}_north_to_south_ip_size_${mirror_j}_bus_first_ingress*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to north_to_south_sector_size_${mirror_i}_north_to_south_ip_size_${mirror_j}_bus_first_ingress*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME north_to_south_sector_size_${mirror_i}_north_to_south_ip_size_${mirror_j}_bus_first_ingress -to north_to_south_sector_size_${mirror_i}_north_to_south_ip_size_${mirror_j}_bus_first_ingress*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$mirror_x $north_constant_y_origin $mirror_x $north_constant_y_top\" -to north_to_south_sector_size_${mirror_i}_north_to_south_ip_size_${mirror_j}_bus_first_fifo_control*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to north_to_south_sector_size_${mirror_i}_north_to_south_ip_size_${mirror_j}_bus_first_fifo_control*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to north_to_south_sector_size_${mirror_i}_north_to_south_ip_size_${mirror_j}_bus_first_fifo_control*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME north_to_south_sector_size_${mirror_i}_north_to_south_ip_size_${mirror_j}_bus_first_fifo_control -to north_to_south_sector_size_${mirror_i}_north_to_south_ip_size_${mirror_j}_bus_first_fifo_control*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$mirror_x $north_constant_y_origin $mirror_x $north_constant_y_top\" -to south_to_north_sector_size_${mirror_i}_south_to_north_ip_size_${mirror_j}_bus_first_egress*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to south_to_north_sector_size_${mirror_i}_south_to_north_ip_size_${mirror_j}_bus_first_egress*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to south_to_north_sector_size_${mirror_i}_south_to_north_ip_size_${mirror_j}_bus_first_egress*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME south_to_north_sector_size_${mirror_i}_south_to_north_ip_size_${mirror_j}_bus_first_egress -to south_to_north_sector_size_${mirror_i}_south_to_north_ip_size_${mirror_j}_bus_first_egress*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$mirror_x $north_constant_y_origin $mirror_x $north_constant_y_top\" -to north_out\[$mirror_i\]\[$mirror_j\]*~reg0"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to north_out\[$mirror_i\]\[$mirror_j\]*~reg0"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to north_out\[$mirror_i\]\[$mirror_j\]*~reg0"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME north_out_reg\[$mirror_i\]\[$mirror_j\] -to north_out\[$mirror_i\]\[$mirror_j\]*~reg0\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$mirror_x $south_constant_y_origin $mirror_x $south_constant_y_top\" -to south_in_reg\[$mirror_i\]\[$mirror_j\]"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to south_in_reg\[$mirror_i\]\[$mirror_j\]"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to south_in_reg\[$mirror_i\]\[$mirror_j\]"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME south_in_reg\[$mirror_i\]\[$mirror_j\] -to south_in_reg\[$mirror_i\]\[$mirror_j\]\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$mirror_x $south_constant_y_origin $mirror_x $south_constant_y_top\" -to south_to_north_sector_size_${mirror_i}_south_to_north_ip_size_${mirror_j}_bus_first_ingress*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to south_to_north_sector_size_${mirror_i}_south_to_north_ip_size_${mirror_j}_bus_first_ingress*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to south_to_north_sector_size_${mirror_i}_south_to_north_ip_size_${mirror_j}_bus_first_ingress*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME south_to_north_sector_size_${mirror_i}_south_to_north_ip_size_${mirror_j}_bus_first_ingress -to south_to_north_sector_size_${mirror_i}_south_to_north_ip_size_${mirror_j}_bus_first_ingress*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$mirror_x $south_constant_y_origin $mirror_x $south_constant_y_top\" -to south_to_north_sector_size_${mirror_i}_south_to_north_ip_size_${mirror_j}_bus_first_fifo_control*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to south_to_north_sector_size_${mirror_i}_south_to_north_ip_size_${mirror_j}_bus_first_fifo_control*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to south_to_north_sector_size_${mirror_i}_south_to_north_ip_size_${mirror_j}_bus_first_fifo_control*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME south_to_north_sector_size_${mirror_i}_south_to_north_ip_size_${mirror_j}_bus_first_fifo_control -to south_to_north_sector_size_${mirror_i}_south_to_north_ip_size_${mirror_j}_bus_first_fifo_control*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$mirror_x $south_constant_y_origin $mirror_x $south_constant_y_top\" -to north_to_south_sector_size_${mirror_i}_north_to_south_ip_size_${mirror_j}_bus_first_egress*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to north_to_south_sector_size_${mirror_i}_north_to_south_ip_size_${mirror_j}_bus_first_egress*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to north_to_south_sector_size_${mirror_i}_north_to_south_ip_size_${mirror_j}_bus_first_egress*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME north_to_south_sector_size_${mirror_i}_north_to_south_ip_size_${mirror_j}_bus_first_egress -to north_to_south_sector_size_${mirror_i}_north_to_south_ip_size_${mirror_j}_bus_first_egress*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$mirror_x $south_constant_y_origin $mirror_x $south_constant_y_top\" -to south_out\[$mirror_i\]\[$mirror_j\]*~reg0"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to south_out\[$mirror_i\]\[$mirror_j\]*~reg0"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to south_out\[$mirror_i\]\[$mirror_j\]*~reg0"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME south_out_reg\[$mirror_i\]\[$mirror_j\] -to south_out\[$mirror_i\]\[$mirror_j\]*~reg0\n"

	if {$group_index == 3} {
	    set group_index 0
	    incr start_x   [expr {[lindex $skip_array $skip_index] + 1}]
	    incr mirror_x -[expr {[lindex $skip_array $skip_index] + 1}]
	    incr skip_index
	    puts $qsf_file_handle ""
	} else {
	    incr group_index
	    incr start_x
	    incr mirror_x -1
	    puts $qsf_file_handle ""
	}
    }
    set skip_index 0
}

# East/West
puts $qsf_file_handle "\# East/West\n"

set x_span 10 
set east_constant_x_origin 280
set east_constant_x_right [expr {$east_constant_x_origin + $x_span}]
set west_constant_x_origin 53 
set west_constant_x_right [expr {$west_constant_x_origin + $x_span}]
set start_y 44

for {set i 0} {$i < $prr_sector_height} {incr i} {
    for {set j 0} {$j < $sector_row} {incr j} {

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$east_constant_x_origin $start_y $east_constant_x_right $start_y\" -to east_in_reg\[$i\]\[$j\]*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to east_in_reg\[$i\]\[$j\]*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to east_in_reg\[$i\]\[$j\]*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME east_in_reg\[$i\]\[$j\] -to east_in_reg\[$i\]\[$j\]*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$east_constant_x_origin $start_y $east_constant_x_right $start_y\" -to east_to_west_sector_size_${i}_east_to_west_ip_size_${j}_bus_first_ingress*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to east_to_west_sector_size_${i}_east_to_west_ip_size_${j}_bus_first_ingress*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to east_to_west_sector_size_${i}_east_to_west_ip_size_${j}_bus_first_ingress*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME east_to_west_sector_size_${i}_east_to_west_ip_size_${j}_bus_first_ingress -to east_to_west_sector_size_${i}_east_to_west_ip_size_${j}_bus_first_ingress*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$east_constant_x_origin $start_y $east_constant_x_right $start_y\" -to east_to_west_sector_size_${i}_east_to_west_ip_size_${j}_bus_first_fifo_control*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to east_to_west_sector_size_${i}_east_to_west_ip_size_${j}_bus_first_fifo_control*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to east_to_west_sector_size_${i}_east_to_west_ip_size_${j}_bus_first_fifo_control*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME east_to_west_sector_size_${i}_east_to_west_ip_size_${j}_bus_first_fifo_control -to east_to_west_sector_size_${i}_east_to_west_ip_size_${j}_bus_first_fifo_control*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$east_constant_x_origin $start_y $east_constant_x_right $start_y\" -to west_to_east_sector_size_${i}_west_to_east_ip_size_${j}_bus_first_egress*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to west_to_east_sector_size_${i}_west_to_east_ip_size_${j}_bus_first_egress*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to west_to_east_sector_size_${i}_west_to_east_ip_size_${j}_bus_first_egress*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME west_to_east_sector_size_${i}_west_to_east_ip_size_${j}_bus_first_egress -to west_to_east_sector_size_${i}_west_to_east_ip_size_${j}_bus_first_egress*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$east_constant_x_origin $start_y $east_constant_x_right $start_y\" -to east_out\[$i\]\[$j\]*~reg0"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to east_out\[$i\]\[$j\]*~reg0"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to east_out\[$i\]\[$j\]*~reg0"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME east_out_reg\[$i\]\[$j\] -to east_out\[$i\]\[$j\]*~reg0\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$west_constant_x_origin $start_y $west_constant_x_right $start_y\" -to west_in_reg\[$i\]\[$j\]*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to west_in_reg\[$i\]\[$j\]*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to west_in_reg\[$i\]\[$j\]*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME west_in_reg\[$i\]\[$j\] -to west_in_reg\[$i\]\[$j\]*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$west_constant_x_origin $start_y $west_constant_x_right $start_y\" -to west_to_east_sector_size_${i}_west_to_east_ip_size_${j}_bus_first_ingress*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to west_to_east_sector_size_${i}_west_to_east_ip_size_${j}_bus_first_ingress*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to west_to_east_sector_size_${i}_west_to_east_ip_size_${j}_bus_first_ingress*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME west_to_east_sector_size_${i}_west_to_east_ip_size_${j}_bus_first_ingress -to west_to_east_sector_size_${i}_west_to_east_ip_size_${j}_bus_first_ingress*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$west_constant_x_origin $start_y $west_constant_x_right $start_y\" -to west_to_east_sector_size_${i}_west_to_east_ip_size_${j}_bus_first_fifo_control*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to west_to_east_sector_size_${i}_west_to_east_ip_size_${j}_bus_first_fifo_control*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to west_to_east_sector_size_${i}_west_to_east_ip_size_${j}_bus_first_fifo_control*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME west_to_east_sector_size_${i}_west_to_east_ip_size_${j}_bus_first_fifo_control -to west_to_east_sector_size_${i}_west_to_east_ip_size_${j}_bus_first_fifo_control*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$west_constant_x_origin $start_y $west_constant_x_right $start_y\" -to east_to_west_sector_size_${i}_east_to_west_ip_size_${j}_bus_first_egress*"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to east_to_west_sector_size_${i}_east_to_west_ip_size_${j}_bus_first_egress*"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to east_to_west_sector_size_${i}_east_to_west_ip_size_${j}_bus_first_egress*"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME east_to_west_sector_size_${i}_east_to_west_ip_size_${j}_bus_first_egress -to east_to_west_sector_size_${i}_east_to_west_ip_size_${j}_bus_first_egress*\n"

	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$west_constant_x_origin $start_y $west_constant_x_right $start_y\" -to west_out\[$i\]\[$j\]*~reg0"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to west_out\[$i\]\[$j\]*~reg0"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to west_out\[$i\]\[$j\]*~reg0"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME west_out_reg\[$i\]\[$j\] -to west_out\[$i\]\[$j\]*~reg0\n"

	incr start_y		
	puts $qsf_file_handle ""
    }
}

# Close the qsf file
close $qsf_file_handle
