#include <linux/debugfs.h>
#include <linux/delay.h>
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/uio_driver.h>

#include <linux/kernel.h>
#include <linux/version.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/errno.h>
#include <asm/uaccess.h>

#include <linux/firmware.h>

 
#include "fpga-ioctl.h"

/* Shorthand PCIe properties */
#define ALTR_PCI_CVP_NUM_BARS (PCI_STD_RESOURCE_END+1)
#define ALTR_PCI_CVP_CONFIG_BAR 2
#define ALTR_PCI_CVP_PR_BAR 4
#define ALTR_PCI_PR_REGION_SLAVE_OFFSET 0x0
#define ALTR_PCI_CONFIG_ROM_OFFSET 0x0000
#define ALTR_PCI_CONFIG_ROM_LEN 0x400
#define ALTR_PCI_REGION_CONTROLLER_ROM_OFFSET 0x04
#define ALTR_PCI_CVP_PR_ROM_OFFSET 0x08
#define ALTR_PR_IP_OFFSET 0x1000

/* Define the PCIe device settings to match to */
#define ALTR_PCI_CVP_VENDOR_ID 0x1172
#define ALTR_PCI_CVP_DEVICE_ID 0x5052
#define ALTR_PCI_CVP_CLASSCODE 0xEA0001
#define ALTR_PCI_CVP_SUB_VENDOR_ID 0x1172
#define ALTR_PCI_CVP_SUB_DEVICE_ID 0x0001

#define DEV_LINK_WIDTH 8

enum fpga_config_states {
	/* default FPGA states */
	FPGA_CONFIG_STATE_UNKNOWN,
	FPGA_CONFIG_STATE_POWER_OFF,
	FPGA_CONFIG_STATE_POWER_UP,
	FPGA_CONFIG_STATE_RESET,

	/* getting an image for loading */
	FPGA_CONFIG_STATE_FIRMWARE_REQ,
	FPGA_CONFIG_STATE_FIRMWARE_REQ_ERR,

	/* write sequence: init, write, complete */
	FPGA_CONFIG_STATE_WRITE_INIT,
	FPGA_CONFIG_STATE_WRITE_INIT_ERR,
	FPGA_CONFIG_STATE_WRITE,
	FPGA_CONFIG_STATE_WRITE_ERR,
	FPGA_CONFIG_STATE_WRITE_COMPLETE,
	FPGA_CONFIG_STATE_WRITE_COMPLETE_ERR,

	/* fpga is programmed and operating */
	FPGA_CONFIG_STATE_OPERATING,
};

struct fpga_pcie_priv {
	void __iomem *bar_addrs[ALTR_PCI_CVP_NUM_BARS];
	struct dentry *debugfs_root;
	struct pci_dev *pci_dev;
	struct pci_dev *pci_upstream_dev;
	u32 aer_uerr_mask_reg;
	const char *state;
	enum fpga_config_states config_state;
	struct uio_info uio_info;
	struct list_head fdev_list;
	spinlock_t fdev_list_lock;
	struct cdev cdev;
	void __iomem *reg_base;
	struct device *my_device;
	
};
