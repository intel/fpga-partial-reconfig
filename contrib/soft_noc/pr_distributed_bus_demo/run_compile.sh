#!/bin/sh
quartus_sh --flow compile blinking_led -c blinking_led 
quartus_cdb blinking_led -c blinking_led --export_partition root_partition --snapshot final --file blinking_led_static.qdb --include_sdc_entity_in_partition
quartus_sh --flow compile blinking_led -c blinking_led_default
quartus_sh --flow compile blinking_led -c blinking_led_empty
quartus_sh --flow compile blinking_led -c blinking_led_slow
quartus_sh --flow compile blinking_led -c adder_grid_1d
quartus_sh --flow compile blinking_led -c adder_grid_2d
