#!/bin/bash

set -e

# Compile the design using the normal PR flow. The SUPR partition is exported
# from the base revision compile and is reused in the subsequent PR
# implementation compiles

##############################################################################
# Compile the base revision
##############################################################################
quartus_ipgenerate blinking_led -c blinking_led
quartus_syn blinking_led -c blinking_led
quartus_fit blinking_led -c blinking_led
# Export Static Region, SUPR region, and default PR region
quartus_cdb blinking_led -c blinking_led --export_partition root_partition --snapshot final --file blinking_led.root_partition.qdb --exclude_pr_subblocks
quartus_cdb blinking_led -c blinking_led --export_partition supr_partition --snapshot final --file blinking_led.supr_partition.qdb
quartus_cdb blinking_led -c blinking_led --export_partition pr_partition --snapshot final --file blinking_led.pr_partition.qdb
# ASM and create RBFs
quartus_asm blinking_led -c blinking_led
quartus_cpf -c output_files/blinking_led.pr_partition.pmsf output_files/blinking_led.pr_partition.rbf

##############################################################################
# Compile the blinking_led personas Alpha, Bravo and Charlie
# These will all be compiled with the base supr persona logic
##############################################################################
# Synthesize PR Persona
quartus_ipgenerate blinking_led -c blinking_led
quartus_syn blinking_led -c blinking_led_default
# Export Persona
quartus_cdb blinking_led -c blinking_led_default --export_partition root_partition --snapshot synthesized --file blinking_led_default.qdb
# Alpha Compile
# Import Blocks (SUPR, Static, PR)
quartus_cdb blinking_led -c blinking_led_pr_alpha --import_partition root_partition --file blinking_led.root_partition.qdb
quartus_cdb blinking_led -c blinking_led_pr_alpha --import_partition supr_partition --file blinking_led.supr_partition.qdb
quartus_cdb blinking_led -c blinking_led_pr_alpha --import_partition pr_partition --file blinking_led_default.qdb
# Run fitter
quartus_fit blinking_led -c blinking_led_pr_alpha
# ASM and convert programming files
quartus_asm blinking_led -c blinking_led_pr_alpha
quartus_cpf -c output_files/blinking_led_pr_alpha.pr_partition.pmsf output_files/blinking_led_pr_alpha.pr_partition.rbf

# Bravo Compile
quartus_ipgenerate blinking_led -c blinking_led
quartus_syn blinking_led -c blinking_led_slow
# Export Persona
quartus_cdb blinking_led -c blinking_led_slow --export_partition root_partition --snapshot synthesized --file blinking_led_slow.qdb
# Import Blocks (SUPR, Static, PR)
quartus_cdb blinking_led -c blinking_led_pr_bravo --import_partition root_partition --file blinking_led.root_partition.qdb
quartus_cdb blinking_led -c blinking_led_pr_bravo --import_partition supr_partition --file blinking_led.supr_partition.qdb
quartus_cdb blinking_led -c blinking_led_pr_bravo --import_partition pr_partition --file blinking_led_slow.qdb
# Run fitter
quartus_fit blinking_led -c blinking_led_pr_bravo
# ASM and convert programming files
quartus_asm blinking_led -c blinking_led_pr_bravo
quartus_cpf -c output_files/blinking_led_pr_bravo.pr_partition.pmsf output_files/blinking_led_pr_bravo.pr_partition.rbf

# Charlie Compile
quartus_ipgenerate blinking_led -c blinking_led
quartus_syn blinking_led -c blinking_led_empty
# Export Persona
quartus_cdb blinking_led -c blinking_led_empty --export_partition root_partition --snapshot synthesized --file blinking_led_empty.qdb
# Import Blocks (SUPR, Static, PR)
quartus_cdb blinking_led -c blinking_led_pr_charlie --import_partition root_partition --file blinking_led.root_partition.qdb
quartus_cdb blinking_led -c blinking_led_pr_charlie --import_partition supr_partition --file blinking_led.supr_partition.qdb
quartus_cdb blinking_led -c blinking_led_pr_charlie --import_partition pr_partition --file blinking_led_empty.qdb
# Run fitter
quartus_fit blinking_led -c blinking_led_pr_charlie
# ASM and convert programming files
quartus_asm blinking_led -c blinking_led_pr_charlie
quartus_cpf -c output_files/blinking_led_pr_charlie.pr_partition.pmsf output_files/blinking_led_pr_charlie.pr_partition.rbf

##############################################################################
# Compile the new SUPR partition and create a new base SOF that
# is compatible with all previously generated PR personas
##############################################################################
# Synthesize SUPR Persona
quartus_syn blinking_led -c synth_blinking_led_supr_new
# Export SUPR Persona
quartus_cdb blinking_led -c synth_blinking_led_supr_new --export_partition root_partition --snapshot synthesized --file synth_blinking_led_supr_new.supr_partition.qdb
# Import Blocks (SUPR, Static, PR)
quartus_cdb blinking_led -c impl_blinking_led_supr_new --import_partition root_partition --file blinking_led.root_partition.qdb
quartus_cdb blinking_led -c impl_blinking_led_supr_new --import_partition supr_partition --file synth_blinking_led_supr_new.supr_partition.qdb
quartus_cdb blinking_led -c impl_blinking_led_supr_new --import_partition pr_partition --file blinking_led.pr_partition.qdb
# Run fitter
quartus_fit blinking_led -c impl_blinking_led_supr_new
# ASM, only use sof
quartus_asm blinking_led -c impl_blinking_led_supr_new

