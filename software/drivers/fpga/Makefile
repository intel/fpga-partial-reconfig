# Configured Linux kernel source.
KDIR ?= /lib/modules/`uname -r`/build/

EXTRA_CFLAGS=-I$(M) -I$(M)/libfdt -DCONFIG_FPGA_MGR_DEBUG_FS -DWAIT_TIME=$(WAIT_TIME)

DEVICE=a10

VERBOSE=false

DEBUG=true

WAIT_TIME=5

all:
	$(MAKE) -C $(KDIR) M=`pwd` modules
	gcc fpga_region_controller.c -o fpga_region_controller

install:
	$(MAKE) -C $(KDIR) M=`pwd` modules_install

# Final modules
obj-m := fpga-mgr-mod.o fpga-pcie-mod.o

fpga-pcie-mod-objs := fpga-pcie.o libfdt/fdt.o libfdt/fdt_ro.o

ifeq ($(DEVICE), s10)
	fpga-mgr-mod-objs := fpga-mgr.o fpga-mgr-debugfs.o altera-pr-ip-core_s10.o
else
	fpga-mgr-mod-objs := fpga-mgr.o fpga-mgr-debugfs.o altera-pr-ip-core.o
endif

ifeq ($(VERBOSE), true)
	EXTRA_CFLAGS += -DVERBOSE_TRUE
endif

ifeq ($(DEBUG), true)
	EXTRA_CFLAGS += -DDEBUG
endif

clean : clean-intermediates clean-module

clean-module :
	rm -f *.ko

clean-intermediates:
	rm -f $(obj-m)
	rm -f *.o libfdt/*.o
	rm -f *.mod.*
	rm -f *.symvers
	rm -f *.order
	rm -f ./.*cmd
	rm -rf .tmp_versions
	rm -rf fpga_region_controller

.PHONY: all clean clean-intermediates clean-module
