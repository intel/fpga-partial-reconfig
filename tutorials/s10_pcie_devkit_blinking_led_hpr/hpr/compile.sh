#!/bin/bash
set -e
quartus_sh --flow compile blinking_led -c blinking_led
quartus_sh --flow compile blinking_led -c hpr_parent_slow_child_default
quartus_cdb -r blinking_led -c hpr_parent_slow_child_default --export_block pr_parent_partition --snapshot final --include_sdc_entity_in_partition --file output_files/pr_parent_partition_slow_final.qdb
quartus_sh --flow compile blinking_led -c hpr_child_default 
quartus_sh --flow compile blinking_led -c hpr_child_slow
quartus_sh --flow compile blinking_led -c hpr_child_empty
quartus_sh --flow compile blinking_led -c hpr_parent_slow_child_slow
