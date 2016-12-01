MODULENAME ?= altr_aclpci_cvp_drv

# Final module
obj-m := $(MODULENAME).o

# List of object files to compile for the final module.
$(MODULENAME)-y :=

#Enable debug
ccflags-$(CONFIG_DRIVER) += -DDEBUG

# List of object files to compile for the final module.
$(MODULENAME)-y := aclpci_queue.o aclpci.o aclpci_fileio.o aclpci_dma.o aclpci_pr.o aclpci_cmd.o
