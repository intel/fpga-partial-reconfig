#//START_MODULE_HEADER/////////////////////////////////////////////////////////
#
#  $Header: //acds/rel/16.0/quartus/periph/makefile.gmake#1 $
#
#  Description: Makefile for the A10 PCIe devkit using CVPupdate
#
#  Authors:     Kalen Brunham
#
#               Copyright (c)  Altera Corporation 2016-
#               All rights reserved.
#
#
#//END_MODULE_HEADER///////////////////////////////////////////////////////////

###############################################################################
# Set up the base environment
###############################################################################
include ../../../../bcommon/environ.mk

###############################################################################
# Set macros for targets
###############################################################################

SOURCE_FILES = \
	example_host_uio.c 

example_host_uio.c.COPY_ONLY = 1
	
###############################################################################
# Targets
###############################################################################
# Create the targets using the COPY_SOURCE_FILES macro
SOURCE_FILES_BUILD_TARGETS =
$(foreach file,$(SOURCE_FILES),$(eval $(call COPY_SOURCE_FILES,$(file))))

$(PR_WORK_DIR)/Makefile : Makefile.target | $(PR_WORK_DIR)
		$(COPY) $< $@

$(PR_DEST_DIR)/Makefile : $(PR_WORK_DIR)/Makefile
		$(COPY) $< $@

$(PR_WORK_DIR)/example_host_uio : copy_design_files
	make -C $(PR_WORK_DIR)

.PHONY : copy_design_files
copy_design_files : $(SOURCE_FILES_BUILD_TARGETS)

.PHONY : test_design_files
test_design_files : smoketest_exe

.PHONY : smoketest_exe
smoketest_exe : $(PR_WORK_DIR)/example_host_uio
	@echo "Preparing to smoketest exe"
	$(PR_WORK_DIR)/example_host_uio -h
	
.PHONY : fpga_pcie
fpga_pcie :
	$(MAKE) -C fpga_pcie

CLEAN_FILES += 

ALL_TARGETS += copy_design_files $(PR_DEST_DIR)/Makefile fpga_pcie

TEST_TARGETS += test_design_files smoketest_exe

###############################################################################
# Common.mk
###############################################################################
include ../../../../bcommon/common.mk



