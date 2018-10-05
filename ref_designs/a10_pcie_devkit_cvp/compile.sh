#! /bin/bash

set -e

quartus_sh --flow compile a10_pcie_devkit_cvp -c a10_pcie_devkit_cvp
#quartus_cdb -r a10_pcie_devkit_cvp -c a10_pcie_devkit_cvp --export_block root_partition --snapshot final --file a10_pcie_devkit_cvp_static.qdb
quartus_sh --flow compile a10_pcie_devkit_cvp -c a10_pcie_devkit_cvp_basic_arithmetic
quartus_sh --flow compile a10_pcie_devkit_cvp -c a10_pcie_devkit_cvp_basic_dsp
quartus_sh --flow compile a10_pcie_devkit_cvp -c a10_pcie_devkit_cvp_gol
quartus_sh --flow compile a10_pcie_devkit_cvp -c a10_pcie_devkit_cvp_ddr4_access
