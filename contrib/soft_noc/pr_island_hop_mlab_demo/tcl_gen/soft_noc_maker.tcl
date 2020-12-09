# Copyright (c) 2020 Intel Corporation
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

set input_file_name       [lindex $argv 0]
set qsf_file_name         [lindex $argv 1]
set verilog_file_name     [lindex $argv 2]
set vertical_pipe_depth   [lindex $argv 3]
set horizontal_pipe_depth [lindex $argv 4]
set x_start               [lindex $argv 5] 
set y_start               [lindex $argv 6]
set x_end                 [lindex $argv 7]
set y_end                 [lindex $argv 8]

if {$argc != 9} {
    puts "usage :: tclsh soft_noc_maker.tcl <input file name> <qsf file name> <verilog file name> <vertical pipe depth> <horizontal pipe depth> <x_start> <y_start> <x_end> <y_end>"
    exit
}

# Open the input file for reading
set input_file_handle [open $input_file_name "r"]
set input_lines_data [read -nonewline $input_file_handle]
set input_lines [split $input_lines_data]
close $input_file_handle

# Open the qsf file for appending
set qsf_file_handle [open $qsf_file_name "a"]
puts $qsf_file_handle "\n\# Auto-generated constraints start here\n"

# Open the verilog file for appending
set verilog_file_handle [open $verilog_file_name "a"]

# Parameters
puts $verilog_file_handle "\tparameter DATA_WIDTH=20;"
puts $verilog_file_handle "\tparameter ADDR_WIDTH=5;\n"

# Mirror point
set mirror_point 172

set exclusion_list {}

foreach input_line $input_lines {
    if {[string first "\"" $input_line] == 0 && [string first "@" $input_line] == 2} {
	
        # Extract and trim the input line of quotes
	set input_line [string trimleft $input_line "\""]
	set input_line [string trimright $input_line "\""]
	set split_input_strings [split $input_line @]

	# Extract the type (C=control, I=ingress fifo, E=egress fifo)
	set type [lindex $split_input_strings 0]

	# Extract the logic lock location
	set location [lindex $split_input_strings 1]
	
	# Extract the bus components
	set bus [lindex $split_input_strings 2]
	set bus [string trimleft $bus "{"]
	set bus [string trimright $bus "}"]
	set bus [split $bus ","]
	set bus0 [lindex $bus 0]
	set bus1 [lindex $bus 1]

	# Extract indices on bus0
	regexp {[A-Z]*\[([0-9]*)\]\[([0-9]*)\]} $bus0 junk bus0_index0 bus0_index1

	# Extract indices on bus1
	regexp {[A-Z]*\[([0-9]*)\]\[([0-9]*)\]} $bus1 junk bus1_index0 bus1_index1
	
	# Extract location X and Y
	regexp {X([0-9]*)_Y([0-9]*)} $location junk X Y	

	# Collect the X,Y locations to exclude from the PR Region
	lappend exclusion_list X${X}_Y${Y}

	# Bus direction and name
	if {[string index $bus1 0] == "N"} {
	    set direction "horizontal"
	    set bus_name "north"
	} elseif {[string index $bus1 0] == "S"} {
	    set direction "horizontal"
	    set bus_name "south"
	} elseif {[string index $bus1 0] == "E"} {
	    set direction "vertical"
	    set bus_name "east"
	} else {
	    set direction "vertical"
	    set bus_name "west"
	}
	    
	# Extract the pipe stage
	set stage [lindex $split_input_strings 3]	

	# Component generator
	puts $verilog_file_handle "\t/* generated from $input_line */\n"

	if {$bus_name == "north"} {
	    set bus_first_instance_name "north_to_south_sector_size_${bus1_index0}_north_to_south_ip_size_${bus1_index1}_bus_first"
	    if {$type == "E"} {
		set bus_first_bus0 "south_out_reg\[${bus0_index0}\]\[${bus0_index1}\]"
		set bus_first_bus1 "south_out_reg\[${bus1_index0}\]\[${bus1_index1}\]"
		set pipe_depth [expr {$vertical_pipe_depth - $stage + 1}]
	    } else {
		set bus_first_bus0 "north_in_reg\[${bus0_index0}\]\[${bus0_index1}\]"
		set bus_first_bus1 "north_in_reg\[${bus1_index0}\]\[${bus1_index1}\]"
		set pipe_depth [expr {$stage + 1}]
	    }
	} elseif {$bus_name == "south"} {
	    set bus_first_instance_name "south_to_north_sector_size_${bus1_index0}_south_to_north_ip_size_${bus1_index1}_bus_first"
	    if {$type == "E"} {
		set bus_first_bus0 "north_out_reg\[${bus0_index0}\]\[${bus0_index1}\]"
		set bus_first_bus1 "north_out_reg\[${bus1_index0}\]\[${bus1_index1}\]"
		set pipe_depth [expr {$vertical_pipe_depth - $stage + 1}]
	    } else {
		set bus_first_bus0 "south_in_reg\[${bus0_index0}\]\[${bus0_index1}\]"
		set bus_first_bus1 "south_in_reg\[${bus1_index0}\]\[${bus1_index1}\]"
		set pipe_depth [expr {$stage + 1}]
	    }
	} elseif {$bus_name == "east"} {
	    set bus_first_instance_name "east_to_west_sector_size_${bus1_index0}_east_to_west_ip_size_${bus1_index1}_bus_first"
	    if {$type == "E"} {
		set bus_first_bus0 "west_out_reg\[${bus0_index0}\]\[${bus0_index1}\]"
		set bus_first_bus1 "west_out_reg\[${bus1_index0}\]\[${bus1_index1}\]"
		set pipe_depth [expr {$horizontal_pipe_depth - $stage + 1}]
	    } else {
		set bus_first_bus0 "east_in_reg\[${bus0_index0}\]\[${bus0_index1}\]"
		set bus_first_bus1 "east_in_reg\[${bus1_index0}\]\[${bus1_index1}\]"
		set pipe_depth [expr {$stage + 1}]
	    }
	} else {
	    set bus_first_instance_name "west_to_east_sector_size_${bus1_index0}_west_to_east_ip_size_${bus1_index1}_bus_first"
	    if {$type == "E"} {
		set bus_first_bus0 "east_out_reg\[${bus0_index0}\]\[${bus0_index1}\]"
		set bus_first_bus1 "east_out_reg\[${bus1_index0}\]\[${bus1_index1}\]"
		set pipe_depth [expr {$horizontal_pipe_depth - $stage + 1}]
	    } else {
		set bus_first_bus0 "west_in_reg\[${bus0_index0}\]\[${bus0_index1}\]"
		set bus_first_bus1 "west_in_reg\[${bus1_index0}\]\[${bus1_index1}\]"
		set pipe_depth [expr {$stage + 1}]
	    }
	}

	# FIFO control
	if {$type == "C"} {
	    
	    # Define the incr_waddr and incr_raddr
	    puts $verilog_file_handle "\tlogic ${location}_incr_waddr; // ingress control"
	    puts $verilog_file_handle "\tlogic ${location}_incr_raddr; // egress control\n"
	    
	    # Mirror the X offset of the alias
	    # Swap to bus0/bus1
	    if {$X < $mirror_point} {
		set alias_X [expr {$X+1}]
		set control_bus $bus_first_bus1
	    } else {
		set alias_X [expr {$X-1}]
		set control_bus $bus_first_bus0
	    }

	    # bus_pipe incr_waddr instantiation
	    puts $verilog_file_handle "\tbus_pipe \#(.WIDTH(1), .DEPTH($pipe_depth)) ${bus_first_instance_name}_fifo_control_incr_waddr(.clock(bus_clock),"
	    puts $verilog_file_handle "\t\t.in(${control_bus}\[0\]),"
	    puts $verilog_file_handle "\t\t.out(${location}_incr_waddr));\n"

	    # bus_pipe incr_raddr instantiation
	    puts $verilog_file_handle "\tbus_pipe \#(.WIDTH(1), .DEPTH($pipe_depth)) ${bus_first_instance_name}_fifo_control_incr_raddr(.clock(bus_clock),"
	    puts $verilog_file_handle "\t\t.in(${control_bus}\[1\]),"
	    puts $verilog_file_handle "\t\t.out(${location}_incr_raddr));\n"
	    
	    # Wires for the FIFO control
	    puts $verilog_file_handle "\tlogic \[ADDR_WIDTH-1:0\] ${location}_waddr;"
	    puts $verilog_file_handle "\tlogic \[ADDR_WIDTH-1:0\] ${location}_raddr;\n"

	    # Aliases based on positional geomerty
	    puts $verilog_file_handle "\t/* positional aliases */\n"
	    
	    if {$bus_name == "north"} {
		puts $verilog_file_handle "\twire X${alias_X}_Y${Y}_incr_waddr;"
		puts $verilog_file_handle "\tassign X${alias_X}_Y${Y}_incr_waddr = ${location}_incr_waddr;"
		puts $verilog_file_handle "\twire \[ADDR_WIDTH-1:0\] X${alias_X}_Y${Y}_waddr;"
		puts $verilog_file_handle "\tassign X${alias_X}_Y${Y}_waddr = ${location}_waddr;"
		puts $verilog_file_handle "\twire X${alias_X}_Y[expr {$Y-1}]_incr_raddr;"
		puts $verilog_file_handle "\tassign X${alias_X}_Y[expr {$Y-1}]_incr_raddr = ${location}_incr_raddr;"
		puts $verilog_file_handle "\twire \[ADDR_WIDTH-1:0\] X${alias_X}_Y[expr {$Y-1}]_raddr;"
		puts $verilog_file_handle "\tassign X${alias_X}_Y[expr {$Y-1}]_raddr = ${location}_raddr;\n"
	    } elseif {$bus_name == "south"} {
		puts $verilog_file_handle "\twire X${alias_X}_Y${Y}_incr_waddr;"
		puts $verilog_file_handle "\tassign X${alias_X}_Y${Y}_incr_waddr = ${location}_incr_waddr;"
		puts $verilog_file_handle "\twire \[ADDR_WIDTH-1:0\] X${alias_X}_Y${Y}_waddr;"
		puts $verilog_file_handle "\tassign X${alias_X}_Y${Y}_waddr = ${location}_waddr;"
		puts $verilog_file_handle "\twire X${alias_X}_Y[expr {$Y+1}]_incr_raddr;"
		puts $verilog_file_handle "\tassign X${alias_X}_Y[expr {$Y+1}]_incr_raddr = ${location}_incr_raddr;"
		puts $verilog_file_handle "\twire \[ADDR_WIDTH-1:0\] X${alias_X}_Y[expr {$Y+1}]_raddr;"
		puts $verilog_file_handle "\tassign X${alias_X}_Y[expr {$Y+1}]_raddr = ${location}_raddr;\n"
	    } elseif {$bus_name == "east"} {
		puts $verilog_file_handle "\twire X[expr {$X-1}]_Y${Y}_incr_waddr;"
		puts $verilog_file_handle "\tassign X[expr {$X-1}]_Y${Y}_incr_waddr = ${location}_incr_waddr;"
		puts $verilog_file_handle "\twire \[ADDR_WIDTH-1:0\] X[expr {$X-1}]_Y${Y}_waddr;"
		puts $verilog_file_handle "\tassign X[expr {$X-1}]_Y${Y}_waddr = ${location}_waddr;"
		puts $verilog_file_handle "\twire X[expr {$X-1}]_Y[expr {$Y-1}]_incr_raddr;"
		puts $verilog_file_handle "\tassign X[expr {$X-1}]_Y[expr {$Y-1}]_incr_raddr = ${location}_incr_raddr;"
		puts $verilog_file_handle "\twire \[ADDR_WIDTH-1:0\] X[expr {$X-1}]_Y[expr {$Y-1}]_raddr;"
		puts $verilog_file_handle "\tassign X[expr {$X-1}]_Y[expr {$Y-1}]_raddr = ${location}_raddr;\n"
	    } else {
		puts $verilog_file_handle "\twire X[expr {$X+1}]_Y${Y}_incr_waddr;"
		puts $verilog_file_handle "\tassign X[expr {$X+1}]_Y${Y}_incr_waddr = ${location}_incr_waddr;"
		puts $verilog_file_handle "\twire \[ADDR_WIDTH-1:0\] X[expr {$X+1}]_Y${Y}_waddr;"
		puts $verilog_file_handle "\tassign X[expr {$X+1}]_Y${Y}_waddr = ${location}_waddr;"
		puts $verilog_file_handle "\twire X[expr {$X+1}]_Y[expr {$Y-1}]_incr_raddr;"
		puts $verilog_file_handle "\tassign X[expr {$X+1}]_Y[expr {$Y-1}]_incr_raddr = ${location}_incr_raddr;"
		puts $verilog_file_handle "\twire \[ADDR_WIDTH-1:0\] X[expr {$X+1}]_Y[expr {$Y-1}]_raddr;"
		puts $verilog_file_handle "\tassign X[expr {$X+1}]_Y[expr {$Y-1}]_raddr = ${location}_raddr;\n"
	    }

	    # fifo_control instantiation
	    #puts $verilog_file_handle "\t(* noprune *)"
	    set instance_name "fifo_control_${location}"
	    puts $verilog_file_handle "\tfifo_control \#(.ADDR_WIDTH(ADDR_WIDTH)) ${instance_name}(.clk(bus_clock),"
	    puts $verilog_file_handle "\t\t.incr_waddr(${location}_incr_waddr),"
	    puts $verilog_file_handle "\t\t.waddr(${location}_waddr),"
	    puts $verilog_file_handle "\t\t.incr_raddr(${location}_incr_raddr),"
	    puts $verilog_file_handle "\t\t.raddr(${location}_raddr));\n\n"

	} elseif {$type == "I"} { # Ingress FIFO

	    # Define the incr_waddr
	    puts $verilog_file_handle "\tlogic \[DATA_WIDTH-1:0\] ${location}_bus_wdata; // ingress\n"

	    # bus_pipe instantiation
	    puts $verilog_file_handle "\tbus_pipe \#(.WIDTH(DATA_WIDTH), .DEPTH($pipe_depth)) ${bus_first_instance_name}_ingress_fifo(.clock(bus_clock),"
	    puts $verilog_file_handle "\t\t.in(\{${bus_first_bus0}\[10:0\], ${bus_first_bus1}\[10:2\]\}),"
	    puts $verilog_file_handle "\t\t.out(${location}_bus_wdata));\n"

	    # ingress_fifo instantiation
	    puts $verilog_file_handle "\t(* noprune *)"
	    set instance_name "ingress_fifo_${location}"
	    puts $verilog_file_handle "\tmlab_fifo ${instance_name}(.data(${location}_bus_wdata),"
	    puts $verilog_file_handle "\t\t.q(/* to design */),"
	    puts $verilog_file_handle "\t\t.wraddress(${location}_waddr),"
	    puts $verilog_file_handle "\t\t.rdaddress(/* from design */),"
	    puts $verilog_file_handle "\t\t.wren(${location}_incr_waddr),"
	    puts $verilog_file_handle "\t\t.wrclock(bus_clock),"
	    puts $verilog_file_handle "\t\t.rdclock(/* from design */));\n\n"

	    # logic lock constraints

	} elseif {$type == "E"} { # Egress FIFO

	    # Define the incr_waddr
	    puts $verilog_file_handle "\tlogic \[DATA_WIDTH-1:0\] ${location}_bus_rdata_in;  // egress"
	    puts $verilog_file_handle "\tlogic \[DATA_WIDTH-1:0\] ${location}_bus_rdata_out; // egress\n"

	    # bus_pipe instantiation
	    puts $verilog_file_handle "\tbus_pipe \#(.WIDTH(DATA_WIDTH), .DEPTH($pipe_depth)) ${bus_first_instance_name}_egress_fifo(.clock(bus_clock),"
	    puts $verilog_file_handle "\t\t.in(${location}_bus_rdata_in),"
	    puts $verilog_file_handle "\t\t.out(${location}_bus_rdata_out));\n"
	    puts $verilog_file_handle "\tassign ${bus_first_bus0}\[10:0\] = ${location}_bus_rdata_out\[DATA_WIDTH-1:DATA_WIDTH-11\];"
	    puts $verilog_file_handle "\tassign ${bus_first_bus1}\[10:2\] = ${location}_bus_rdata_out\[DATA_WIDTH-12:0];\n"

	    # egress_fifo instantiation
	    #puts $verilog_file_handle "\t(* noprune *)"
	    set instance_name "egress_fifo_${location}"
	    puts $verilog_file_handle "\tmlab_fifo ${instance_name}(.data(/* from design */),"
	    puts $verilog_file_handle "\t\t.q(${location}_bus_rdata_in),"
	    puts $verilog_file_handle "\t\t.wraddress(/* from design */),"
	    puts $verilog_file_handle "\t\t.rdaddress(${location}_raddr),"
	    puts $verilog_file_handle "\t\t.wren(/* from design */),"
	    puts $verilog_file_handle "\t\t.wrclock(/* from design */),"
	    puts $verilog_file_handle "\t\t.rdclock(bus_clock));\n\n"

	    # logic lock constraints

	} else {
	    puts "illegal generator format $input_line"
	    set instance_name ""
	    exit
	}

	# logic lock constraints
	puts $qsf_file_handle "set_instance_assignment -name PLACE_REGION \"$X $Y $X $Y\" -to $instance_name"
	puts $qsf_file_handle "set_instance_assignment -name RESERVE_PLACE_REGION OFF -to $instance_name"
	puts $qsf_file_handle "set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to $instance_name"
	puts $qsf_file_handle "set_instance_assignment -name REGION_NAME ${instance_name}_${bus_name} -to $instance_name\n"

    }
}

puts $verilog_file_handle "endmodule"

# Collect the X,Y locations to exclude from the PR Region
set count 0
set new_rectangle 1

puts -nonewline $qsf_file_handle "set_instance_assignment -name PLACE_REGION \""

for {set x $x_start} {$x <= $x_end} {incr x} {
    set ll_x $x
    set ll_y $y_start
    for {set y $y_start} {$y <= $y_end} {incr y} {
	if {[lsearch $exclusion_list "X${x}_Y${y}"] != -1 && $new_rectangle == 1} {
	    # blockage found, draw the rectangle
	    puts -nonewline $qsf_file_handle "$ll_x $ll_y $x [expr {$y-1}] ; "
	    set new_rectangle 0
	    incr count
	} elseif {[lsearch $exclusion_list "X${x}_Y${y}"] == -1 && $new_rectangle == 0} {
	    set new_rectangle 1
	    set ll_x $x
	    set ll_y $y
	}
    }
    puts -nonewline $qsf_file_handle "$ll_x $ll_y $x $y_end ; "
    set new_rectangle 0
    incr count
}
puts $qsf_file_handle "\" -to u_blinking_led"
#puts $count

close $qsf_file_handle
close $verilog_file_handle
