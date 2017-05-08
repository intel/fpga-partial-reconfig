# Configured Linux kernel source.
KDIR ?= /lib/modules/`uname -r`/build/

EXTRA_CFLAGS=-I$(M) -I$(M)/libfdt -DCONFIG_FPGA_MGR_DEBUG_FS

all:
	$(MAKE) -C $(KDIR) M=`pwd` modules

install:
	$(MAKE) -C $(KDIR) M=`pwd` modules_install

# Final modules
obj-m := fpga-mgr-mod.o fpga-pcie-mod.o

fpga-pcie-mod-objs := fpga-pcie.o libfdt/fdt.o libfdt/fdt_ro.o

fpga-mgr-mod-objs := fpga-mgr.o fpga-mgr-debugfs.o altera-pr-ip-core.o

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

.PHONY: all clean clean-intermediates clean-module
