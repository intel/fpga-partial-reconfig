#! /bin/bash
set -e 

if  [  ! -e ../../output_files/a10_pcie_devkit_cvp.sof  ]
then
	echo
	echo "ERROR! Need to generate base sof for design"
	exit 1
fi

cp "../../output_files/a10_pcie_devkit_cvp.sof" "."
mv "a10_pcie_devkit_cvp.sof" "top.sof"

quartus_cpf --convert flash.cof

exit 0

