#!/bin/bash
set -e
quartus_sh -t prpof_id_mif_gen.tcl init
quartus_sh --flow compile blinking_led -c blinking_led
quartus_sh --flow compile blinking_led -c hpr_parent_slow_child_default
quartus_cdb -r blinking_led -c hpr_parent_slow_child_default --export_block pr_parent_partition --snapshot final --file output_files/pr_parent_partition_slow_final.qdb
quartus_sh --flow compile blinking_led -c hpr_child_default 
quartus_sh --flow compile blinking_led -c hpr_child_slow
quartus_sh --flow compile blinking_led -c hpr_child_empty
quartus_sh --flow compile blinking_led -c hpr_parent_slow_child_slow
quartus_sh -t prpof_id_mif_gen.tcl update
