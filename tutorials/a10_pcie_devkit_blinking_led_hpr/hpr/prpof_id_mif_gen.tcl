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

# ##########################################################
#   Generate MIF files for PR IP's M20K blocks update
#       folder  : output_files
#       input   : <revision>.hprpofid.txt
#       output  : pr_hierarchy_index.mif
#                 pr_pof_id.mif
# ##########################################################
set OUTPUT_DIR          "output_files"
set PROJECT_NAME        "blinking_led"
set BASE_REVISION_NAME  "blinking_led"

# Load required packages
load_package flow
load_package project

proc generate_init_mif_files {out_dir} {
    set OUTPUT_PR_HIER_MIF_NAME     "$out_dir/pr_hierarchy_index.mif"
    set OUTPUT_PR_POFID_MIF_NAME    "$out_dir/pr_pof_id.mif"
    set MAX_RAM_DEPTH 20

    # create output_files folder
    file mkdir $out_dir;

    # write init file for PR Hierarchy Index block    
    set fname [open $OUTPUT_PR_HIER_MIF_NAME w+]
    generate_mif_header $fname $MAX_RAM_DEPTH
    generate_mif_init_content $fname $MAX_RAM_DEPTH
    generate_mif_footer $fname
    close $fname

    # write init file for PR POF ID block    
    set fname [open $OUTPUT_PR_POFID_MIF_NAME w+]
    generate_mif_header $fname $MAX_RAM_DEPTH
    generate_mif_init_content $fname $MAX_RAM_DEPTH
    generate_mif_footer $fname
    close $fname
}


proc generate_mif_header {fname max_line} {    
    puts $fname "WIDTH=32;"
    puts $fname "DEPTH=$max_line;\n"
    puts $fname "ADDRESS_RADIX=UNS;"
    puts $fname "DATA_RADIX=HEX;\n"
    puts $fname "CONTENT BEGIN"
}


proc generate_mif_init_content {fname max_line} {
    set end_line [expr {$max_line - 1}]
    puts $fname "    [0..$end_line] : 00000000;"
}


proc generate_mif_content {fname block_list total_line max_line} {
    set end_line [expr {$max_line - 1}]
    set count 0
    
    while { $count < $total_line } {
        set s1 [string trim "[lindex $block_list $count]"]
        puts $fname "    $count : $s1;"
        incr count
    }
    
    if { $total_line < $end_line} {
        puts $fname "    [$total_line..$end_line] : 00000000;"
    }
}


proc generate_mif_footer {fname} {
    puts $fname "END;"
}


proc generate_final_mif_files {out_dir base_rev} {
    set INPUT_TXT_NAME              "$out_dir/$base_rev.hpr_pof_id.txt"
    set OUTPUT_PR_HIER_MIF_NAME     "$out_dir/pr_hierarchy_index.mif"
    set OUTPUT_PR_POFID_MIF_NAME    "$out_dir/pr_pof_id.mif"
    set MAX_RAM_DEPTH 20
    
    set hier_block_list [list]
    set pofid_block_list [list]
    set count_line 0
    
    set fp [open $INPUT_TXT_NAME r]
    while { [gets $fp data] >= 0 } {
        puts $data
        
        lappend hier_block_list [lindex [split $data :] 1]
        lappend pofid_block_list [lindex [split $data :] 2]
        incr count_line
    }
    close $fp
    
    if {$count_line >= $MAX_RAM_DEPTH} {
        puts "Error: Total number of PR/HPR regions exceeds supported limit. Please turn off the HPR bitstream compatibility feature to proceed."
        error "PR IP's RAM run out of space"
    }
    
    # write final file for PR Hierarchy Index block    
    set fname [open $OUTPUT_PR_HIER_MIF_NAME w+]
    generate_mif_header $fname $MAX_RAM_DEPTH
    generate_mif_content $fname $hier_block_list $count_line $MAX_RAM_DEPTH
    generate_mif_footer $fname
    close $fname

    # write final file for PR POF ID block    
    set fname [open $OUTPUT_PR_POFID_MIF_NAME w+]
    generate_mif_header $fname $MAX_RAM_DEPTH
    generate_mif_content $fname $pofid_block_list $count_line $MAX_RAM_DEPTH
    generate_mif_footer $fname
    close $fname
}


# ##########################################################
#   Script starts here!
#   Run this script with below commands:
#       quartus_sh -t prpof_id_mif_gen.tcl <argument: init | update>
# ##########################################################
if {[llength $argv] != 1} {
	puts "Error: Required argument for operation (init/update) not supplied"
	error "Missing args"
}

set operation [string tolower [lindex $argv 0]]

if {[string equal $operation "init"]} {
    # allow initialize MIF files generation
    generate_init_mif_files   $OUTPUT_DIR
    
} elseif {[string equal $operation "update"]} {
    # allow base deisng .sof update with MIF files after PR compilation
    generate_final_mif_files  $OUTPUT_DIR $BASE_REVISION_NAME
    
    project_open $PROJECT_NAME -rev $BASE_REVISION_NAME
    execute_module -tool cdb -args "--update_mif -c $BASE_REVISION_NAME"
    execute_module -tool asm -args "-c $BASE_REVISION_NAME"
    project_close
    
} else {
    puts "Error: Required argument for operation (init/update) not supplied"
	error "Invalid operation!"
    
}

