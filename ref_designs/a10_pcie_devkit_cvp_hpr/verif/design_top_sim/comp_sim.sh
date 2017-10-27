#! /bin/bash

# PR subsystem top
PR_SUBSYS_SIM_DIR=../design/source/static_region/design_top/sim
cp ${PR_SUBSYS_SIM_DIR}/synopsys/vcsmx/synopsys_sim.setup .
echo "UVM_LIB:           ./libraries/UVM_LIB/" >> synopsys_sim.setup
source ${PR_SUBSYS_SIM_DIR}/synopsys/vcsmx/vcsmx_setup.sh QSYS_SIMDIR=${PR_SUBSYS_SIM_DIR} SKIP_ELAB=1 SKIP_SIM=1 SKIP_COM=0 SKIP_DEV_COM=0

# Regfile
REGFILE_SIM_DIR=../design/source/common/reg_file/reg_file/sim
cat ${REGFILE_SIM_DIR}/synopsys/vcsmx/synopsys_sim.setup | egrep "^[a-z]" | egrep -v "^work" >> ./synopsys_sim.setup
source ${REGFILE_SIM_DIR}/synopsys/vcsmx/vcsmx_setup.sh QSYS_SIMDIR=${REGFILE_SIM_DIR} SKIP_ELAB=1 SKIP_SIM=1 SKIP_COM=0 SKIP_DEV_COM=0
