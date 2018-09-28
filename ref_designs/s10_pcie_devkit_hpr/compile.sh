#! /bin/bash

set -e

quartus_sh --flow compile s10_pcie_devkit_hpr -c s10_pcie_devkit_hpr
quartus_sh --flow compile s10_pcie_devkit_hpr -c s10_pcie_devkit_hpr_ddr4_access
quartus_cdb -r s10_pcie_devkit_hpr -c s10_pcie_devkit_hpr_ddr4_access --export_block pr_partition --snapshot final --file output_files/s10_pcie_devkit_hpr_ddr4_access_pr_partition_final.qdb --preserve_sdc
quartus_sh --flow compile s10_pcie_devkit_hpr -c s10_pcie_devkit_hpr_basic_arithmetic
quartus_sh --flow compile s10_pcie_devkit_hpr -c s10_pcie_devkit_hpr_basic_dsp
quartus_sh --flow compile s10_pcie_devkit_hpr -c s10_pcie_devkit_hpr_gol
quartus_sh --flow compile s10_pcie_devkit_hpr -c s10_pcie_devkit_hpr_normal_ddr4_access.qsf
quartus_sh --flow compile s10_pcie_devkit_hpr -c s10_pcie_devkit_hpr_normal_basic_arithmetic.qsf
quartus_sh --flow compile s10_pcie_devkit_hpr -c s10_pcie_devkit_hpr_normal_basic_dsp.qsf
quartus_sh --flow compile s10_pcie_devkit_hpr -c s10_pcie_devkit_hpr_normal_gol.qsf
