#!/bin/bash

set -e

# Compile the design using the simplified PR flow. The SUPR partition is exported
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

# Alpha Compile
# Import Blocks (SUPR, Static) is done in qsf
# Run the entire flow
quartus_ipgenerate blinking_led -c blinking_led_pr_alpha_simplified
quartus_syn blinking_led -c blinking_led_pr_alpha_simplified
quartus_fit blinking_led -c blinking_led_pr_alpha_simplified
# ASM and convert programming files
quartus_asm blinking_led -c blinking_led_pr_alpha_simplified
quartus_cpf -c output_files/blinking_led_pr_alpha_simplified.pr_partition.pmsf output_files/blinking_led_pr_alpha_simplified.pr_partition.rbf

# Bravo Compile
# Import Blocks (SUPR, Static) is done in qsf
# Run the entire flow
quartus_ipgenerate blinking_led -c blinking_led_pr_bravo_simplified
quartus_syn blinking_led -c blinking_led_pr_bravo_simplified
quartus_fit blinking_led -c blinking_led_pr_bravo_simplified
# ASM and convert programming files
quartus_asm blinking_led -c blinking_led_pr_bravo_simplified
quartus_cpf -c output_files/blinking_led_pr_bravo_simplified.pr_partition.pmsf output_files/blinking_led_pr_bravo_simplified.pr_partition.rbf

# Charlie Compile
# Import Blocks (SUPR, Static) is done in qsf
# Run the entire flow
quartus_ipgenerate blinking_led -c blinking_led_pr_charlie_simplified
quartus_syn blinking_led -c blinking_led_pr_charlie_simplified
quartus_fit blinking_led -c blinking_led_pr_charlie_simplified
# ASM and convert programming files
quartus_asm blinking_led -c blinking_led_pr_charlie_simplified
quartus_cpf -c output_files/blinking_led_pr_charlie_simplified.pr_partition.pmsf output_files/blinking_led_pr_charlie_simplified.pr_partition.rbf

##############################################################################
# Compile the new SUPR partition and create a new base SOF that
# is compatible with all previously generated PR personas
##############################################################################
# Import Blocks (Static) id done in qsf
# Run entire flow
quartus_ipgenerate blinking_led -c impl_blinking_led_supr_new_simplified
quartus_syn blinking_led -c impl_blinking_led_supr_new_simplified
quartus_fit blinking_led -c impl_blinking_led_supr_new_simplified
# ASM, only use sof
quartus_asm blinking_led -c impl_blinking_led_supr_new_simplified

