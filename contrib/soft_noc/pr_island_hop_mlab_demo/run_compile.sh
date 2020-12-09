#!/bin/sh
quartus_sh --flow compile soft_noc -c soft_noc
quartus_cdb soft_noc -c soft_noc --export_partition root_partition --snapshot final --file blinking_led_static.qdb --include_sdc_entity_in_partition
