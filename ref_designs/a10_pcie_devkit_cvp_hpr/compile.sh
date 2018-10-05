#!/bin/bash

set -e
quartus_sh --flow compile a10_pcie_devkit_cvp -c a10_pcie_devkit_cvp
quartus_sh --flow compile a10_pcie_devkit_cvp -c a10_pcie_devkit_cvp_ddr4_access
quartus_cdb -r a10_pcie_devkit_cvp -c a10_pcie_devkit_cvp_ddr4_access --export_block pr_partition --snapshot final --file output_files/a10_pcie_devkit_cvp_ddr4_access_pr_partition_final.qdb
quartus_sh --flow compile a10_pcie_devkit_cvp -c a10_pcie_devkit_cvp_basic_arithmetic
quartus_sh --flow compile a10_pcie_devkit_cvp -c a10_pcie_devkit_cvp_basic_dsp
quartus_sh --flow compile a10_pcie_devkit_cvp -c a10_pcie_devkit_cvp_gol
quartus_sh --flow compile a10_pcie_devkit_cvp -c a10_pcie_devkit_cvp_normal_ddr4_access.qsf
quartus_sh --flow compile a10_pcie_devkit_cvp -c a10_pcie_devkit_cvp_normal_basic_arithmetic.qsf
quartus_sh --flow compile a10_pcie_devkit_cvp -c a10_pcie_devkit_cvp_normal_basic_dsp.qsf
quartus_sh --flow compile a10_pcie_devkit_cvp -c a10_pcie_devkit_cvp_normal_gol.qsf
