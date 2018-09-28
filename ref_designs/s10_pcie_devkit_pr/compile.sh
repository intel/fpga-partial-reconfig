#! /bin/bash

set -e

quartus_sh --flow compile s10_pcie_devkit_pr -c s10_pcie_devkit_pr
#quartus_cdb -r s10_pcie_devkit_pr -c s10_pcie_devkit_pr --export_block root_partition --snapshot final --file s10_pcie_devkit_pr_static.qdb --preserve_sdc
quartus_sh --flow compile s10_pcie_devkit_pr -c s10_pcie_devkit_pr_basic_arithmetic
quartus_sh --flow compile s10_pcie_devkit_pr -c s10_pcie_devkit_pr_basic_dsp
quartus_sh --flow compile s10_pcie_devkit_pr -c s10_pcie_devkit_pr_gol
quartus_sh --flow compile s10_pcie_devkit_pr -c s10_pcie_devkit_pr_ddr4_access
