/*
 *
 * Copyright (C) 2017 Intel Corporation
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "altera-pr-ip-core.h"
#include <linux/debugfs.h>
#include <linux/delay.h>
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/uio_driver.h>
#include "libfdt.h"

#define DRIVER_NAME "fpga-pcie"
static const const char* DRIVER_VERSION  = "1.0";
#define DRIVER_DESCRIPTION "Driver for PR Reference Design PCIe boards"

/* Shorthand PCIe properties */
#define ALTR_PCI_CVP_NUM_BARS (PCI_STD_RESOURCE_END+1)
#define ALTR_PCI_CVP_CONFIG_BAR 2
#define ALTR_PCI_CVP_PR_BAR 4
#define ALTR_PCI_PR_REGION_SLAVE_OFFSET 0x0
#define ALTR_PCI_CONFIG_ROM_OFFSET 0x0000
#define ALTR_PCI_CONFIG_ROM_LEN 0x400
#define ALTR_PCI_REGION_CONTROLLER_ROM_OFFSET 0x04
#define ALTR_PCI_CVP_PR_ROM_OFFSET 0x08

/* Define the PCIe device settings to match to */
#define ALTR_PCI_CVP_VENDOR_ID 0x1172
#define ALTR_PCI_CVP_DEVICE_ID 0x5052
#define ALTR_PCI_CVP_CLASSCODE 0xEA0001
#define ALTR_PCI_CVP_SUB_VENDOR_ID 0x1172
#define ALTR_PCI_CVP_SUB_DEVICE_ID 0x0001

#define DEV_LINK_WIDTH 8

/* Forward declarations */
static struct pci_driver fpga_pcie_driver;
static int fpga_pcie_register_driver(void);
static void fpga_pcie_unregister_driver(void);
static void dump_dtb(struct device *dev, const void *fdt);


static struct dentry *fpga_pcie_debugfs_root;
static const struct file_operations fpga_pcie_state_fops;
static const struct file_operations fpga_pcie_base_dtb_fops;

/* Register the device identification for the PCIe bus subsystem */
static struct pci_device_id fpga_pcie_pci_ids[] = {
	{ PCI_DEVICE_SUB(ALTR_PCI_CVP_VENDOR_ID, ALTR_PCI_CVP_DEVICE_ID,
			 ALTR_PCI_CVP_SUB_VENDOR_ID, ALTR_PCI_CVP_SUB_DEVICE_ID)
	},
	{0}
};
MODULE_DEVICE_TABLE(pci, fpga_pcie_pci_ids);

static const char *ST_IDLE = "Idle\n";
static const char *ST_AER_DISABLED = "Upstream AER disabled\n";
static const char *ST_BASE_PROBED = "Base probed\n";

struct fpga_pcie_priv {
	void __iomem *bar_addrs[ALTR_PCI_CVP_NUM_BARS];
	struct dentry *debugfs_root;
	struct pci_dev *pci_dev;
	struct pci_dev *pci_upstream_dev;
	u32 aer_uerr_mask_reg;
	const char *state;
	struct uio_info uio_info;
	struct list_head fdev_list;
	spinlock_t fdev_list_lock;
};

static int fpga_pcie_probe_all_subdrivers(struct fpga_pcie_priv *priv,
					  const void *fdt);
static int fpga_pcie_remove_all_subdrivers(struct fpga_pcie_priv *priv);

struct fdev {
	struct list_head list;
	int (*remove)(struct device *dev);
	struct device dev;
};

struct fpga_drv_entry {
	const char *id;
	const char *prefix;
	int (*probe)(struct device *dev, void __iomem *reg_base);
	int (*remove)(struct device *dev);
};

struct fpga_drv_entry fpga_drv_tab[] = {
	{
		.id = "altr,pr-ip-core",
		.prefix = "",
		.probe = alt_pr_probe,
		.remove = alt_pr_remove,
	}, 
	{}
};

static struct fpga_drv_entry *fpga_drv_lookup(const char *id)
{
	struct fpga_drv_entry *p;
	for (p = fpga_drv_tab; p->id; p++) {
		if (!strcmp(id, p->id))
			return p;
	}

	return NULL;
}

static u32 get_aer_uerr_mask_reg(struct pci_dev *dev)
{
	u32 reg = 0;
	int pos;

	pos = pci_find_ext_capability(dev, PCI_EXT_CAP_ID_ERR);

	if (!pos) {
		dev_err(&dev->dev, "failed to find AER extended capability\n");
		return -EIO;
	}

	pci_read_config_dword(dev, pos+PCI_EXP_DEVCAP, &reg);

	pci_read_config_dword(dev, pos+PCI_EXP_DEVCTL, &reg);

	return reg;
}

static void set_aer_uerr_mask_reg(struct pci_dev *dev, u32 val)
{
	int pos;

	pos = pci_find_ext_capability(dev, PCI_EXT_CAP_ID_ERR);

	if (!pos) {
		dev_err(&dev->dev, "failed to find AER extended capability\n");
		return;
	}


	pci_write_config_dword(dev, pos+PCI_EXP_DEVCAP, PCI_ERR_UNC_SURPDN | PCI_ERR_UNC_COMP_TIME | PCI_ERR_UNC_UNSUP);

	pci_write_config_dword(dev, pos+PCI_EXP_DEVCTL, val);
}

static u32 disable_upstream_aer(struct pci_dev *dev,
				struct pci_dev *upstream_dev)
{
	u32 reg = 0;

	if (dev == NULL) {
		pr_err("%s NULL dev\n", __func__);
		return -EINVAL;
	} else if (upstream_dev == NULL) {
		
		dev_err(&dev->dev, "%s NULL upstream_dev\n", __func__);
		return -EINVAL;
	}

	reg = get_aer_uerr_mask_reg(upstream_dev);

	set_aer_uerr_mask_reg(upstream_dev, reg | PCI_ERR_UNC_SURPDN | PCI_ERR_UNC_COMP_TIME | PCI_ERR_UNC_UNSUP);

	return reg;
}
/*
 * USed for after full chip configuration, to ensure the correct speed is reported, and if not,
 * re initialize
 */
static void retrain_device_speed(struct pci_dev *dev, struct pci_dev *upstream)
{
	u16 linkstat, speed, width;
	int pos, upos;
	u16 status_reg, control_reg, link_cap_reg;
	u16 status, control;
	u32 link_cap;
	int training, timeout;

	pos = pci_find_capability(dev, PCI_CAP_ID_EXP);

	if (!pos) {
		dev_err(&dev->dev, "Can't find PCI Express capability!\n");
		return;
	}

	upos = pci_find_capability(upstream, PCI_CAP_ID_EXP);
	status_reg = upos + PCI_EXP_LNKSTA;
	control_reg = upos + PCI_EXP_LNKCTL;
	link_cap_reg = upos + PCI_EXP_LNKCAP;
	pci_read_config_word(upstream, status_reg, &status);
	pci_read_config_word(upstream, control_reg, &control);
	pci_read_config_dword(upstream, link_cap_reg, &link_cap);
	
	
	pci_read_config_word(dev, pos + PCI_EXP_LNKSTA, &linkstat);
	pci_read_config_dword(upstream, link_cap_reg, &link_cap);
	speed = linkstat & PCI_EXP_LNKSTA_CLS;
	width = (linkstat & PCI_EXP_LNKSTA_NLW) >> PCI_EXP_LNKSTA_NLW_SHIFT;
	
	if (speed == PCI_EXP_LNKSTA_CLS_2_5GB) {
		dev_info(&dev->dev, "Link speed is 2.5 GT/s with %d lanes.\n",
			 width);
		dev_info(&dev->dev, "Need to retrain.");
	} else if (speed == PCI_EXP_LNKSTA_CLS_5_0GB) {
		dev_info(&dev->dev, "Link speed is 5.0 GT/s with %d lanes.\n",
			 width);
		if (width == DEV_LINK_WIDTH) {
			dev_info(&dev->dev, "  All is good!\n");
			return;
		} else {
			dev_info(&dev->dev, "  Need to retrain.\n");
		}
	} else if (speed == PCI_EXP_LNKSTA_CLS_8_0GB) {
		dev_info(&dev->dev, "Link speed is 8.0 GT/s with %d lanes.\n",
			 width);
		if (width == DEV_LINK_WIDTH) {
			dev_info(&dev->dev, "  All is good!\n");
			return;
		} else {
			dev_info(&dev->dev, "  Need to retrain.\n");
		}
	} else {
		dev_warn(&dev->dev, "Not sure what's going on. Retraining.\n");
	}
	
		  
	/* Perform the training. */
	training = 1;
	timeout = 0;
	pci_read_config_word(upstream, control_reg, &control);
	pci_write_config_word(upstream, control_reg,
			      control | PCI_EXP_LNKCTL_RL);
	
	while (training && timeout < 50)
	{
		pci_read_config_word (upstream, status_reg, &status);
		training = (status & PCI_EXP_LNKSTA_LT);
		msleep (1); /* 1 ms */
		++timeout;
	}
	if(training)
	{
		 dev_info(&dev->dev, "Error: Link training timed out.\n");
		 dev_info(&dev->dev, "PCIe link not established.\n");
	}
	else
	{
		 dev_info(&dev->dev, "Link training completed in %d ms.\n",
			  timeout);
	}
	 

	/* Verify that it's a 8 GT/s link now */
	pci_read_config_word(dev, pos + PCI_EXP_LNKSTA, &linkstat);
	pci_read_config_dword(upstream, link_cap_reg, &link_cap);
	speed = linkstat & PCI_EXP_LNKSTA_CLS;
	width = (linkstat & PCI_EXP_LNKSTA_NLW) >> PCI_EXP_LNKSTA_NLW_SHIFT;
	
	if(speed == PCI_EXP_LNKSTA_CLS_8_0GB)
	{
		dev_info(&dev->dev, "Link operating at 8 GT/s with %d lanes\n",
			 width);
	}
	else if(speed == PCI_EXP_LNKSTA_CLS_5_0GB)
	{
		dev_info(&dev->dev, "Link operating at 5 GT/s with %d lanes\n",
			 width);
	}
	else
	{
		dev_warn(&dev->dev, "** WARNING: Link training failed.\n");
		dev_warn(&dev->dev, "Link speed is 2.5 GT/s with %d lanes.\n",
			 width);
	}
}


static void fpga_pcie_shutdown_pci(struct pci_dev *dev,
				   struct fpga_pcie_priv *priv)
{
	int i;

	if (priv->uio_info.mem[0].size > 0) {
		uio_unregister_device(&priv->uio_info);
		priv->uio_info.mem[0].size = 0;
	}

	for (i = 0; i < ALTR_PCI_CVP_NUM_BARS; i++) {
		if (priv->bar_addrs[i])
			iounmap(priv->bar_addrs[i]);
	}
	pci_release_regions(dev);
	pci_disable_device(dev);
}
/*
 * Called upon deployment of driver, reads config space of pcie, and maps the memory to virtual
 * addresses
 */
static int fpga_pcie_setup_pci(struct pci_dev *dev, struct fpga_pcie_priv *priv)
{
	static const const char *bar_fmt =
		"BAR[%d] 0x%08lx-0x%08lx (%lu bytes) flags 0x%08lx\n";
	int i, err;
	int pos = 0;


	pci_set_drvdata(dev, priv);

	priv->pci_dev = dev;

	priv->pci_upstream_dev = pci_upstream_bridge(dev);

	if (priv->pci_upstream_dev == NULL) {
		dev_err(&dev->dev, "no upstream bridge\n");
		return -EINVAL;
	}

	/* Enable the device. This allows access to the device resources */
	if (pci_enable_device(dev)) {
		dev_err(&dev->dev, "pci_enable_device() failed\n");
		return -EIO;
	}

	/* Make sure that the card is set as a bus master. */
	pci_set_master(dev);

	/* Get some info on the PCI Express (PCI_CAP_ID_EXP) capabilities */
	pos = pci_find_capability(dev, PCI_CAP_ID_EXP);

	/* Read the link status */
	if (pos) {
		unsigned short linkstat = 0;
		int link_speed = 0;
		int link_width = 0;

		pci_read_config_word(dev, pos + PCI_EXP_LNKSTA, &linkstat);

		link_speed = linkstat & PCI_EXP_LNKSTA_CLS;
		link_width =
		    (linkstat & PCI_EXP_LNKSTA_NLW) >> PCI_EXP_LNKSTA_NLW_SHIFT;

		if (link_speed == PCI_EXP_LNKSTA_CLS_2_5GB) {
			dev_info(
			    &dev->dev,
			    "Link speed is 2.5 GT/s with %d lanes.\n",
			    link_width);
		} else if (link_speed == PCI_EXP_LNKSTA_CLS_5_0GB) {
			dev_info(
			    &dev->dev,
			    "Link speed is 5.0 GT/s with %d lanes.\n",
			    link_width);
		} else if (link_speed == PCI_EXP_LNKSTA_CLS_8_0GB) {
			dev_info(
			    &dev->dev,
			    "Link speed is 8.0 GT/s with %d lanes.\n",
			    link_width);
		}
	}

	if (pci_request_regions(dev, DRIVER_NAME)) {
		dev_err(&dev->dev, "Failed to request regions");
		pci_disable_device(dev);
		return -EIO;
	}

	for (i = 0; i < ALTR_PCI_CVP_NUM_BARS; i++) {
		/* BARs can return 0 meaning unused */
		unsigned long bar_start = pci_resource_start(dev, i);

		if (bar_start) {
			unsigned long bar_end =
			    pci_resource_end(dev, i);
			unsigned long bar_flags =
			    pci_resource_flags(dev, i);

			dev_info(&dev->dev, bar_fmt,
				 i, bar_start, bar_end,
				 (bar_end - bar_start + 1), bar_flags);
			priv->bar_addrs[i] = pci_ioremap_bar(dev, i);
			if (!priv->bar_addrs[i]) {
				dev_err(&dev->dev,
					"Failed to remap BAR[%d]\n", i);
				err = -EIO;
				goto fail_pci_enable_device;
			}

			if (i == ALTR_PCI_CVP_PR_BAR) {
				priv->uio_info.name = dev_name(&dev->dev);
				priv->uio_info.version = DRIVER_VERSION;
				priv->uio_info.mem[0].addr = bar_start;
				priv->uio_info.mem[0].internal_addr =
					priv->bar_addrs[i];
				priv->uio_info.mem[0].memtype = UIO_MEM_PHYS;
				priv->uio_info.mem[0].size =
					bar_end - bar_start + 1;
				if (uio_register_device(&dev->dev,
							&(priv->uio_info))) {
					dev_err(&dev->dev,
						"uio_register_device failed\n");
					priv->uio_info.mem[0].size = 0;
					err = -EIO;
					goto fail_pci_enable_device;
				}
			}
		} else {
			dev_info(&dev->dev, "BAR[%d] UNUSED\n", i);
		}
	}

	return 0;

fail_pci_enable_device:

	fpga_pcie_shutdown_pci(dev, priv);
	
	return err;

}

static void fpga_pcie_remove(struct pci_dev *dev)
{
	struct fpga_pcie_priv *priv = pci_get_drvdata(dev);

	dev_info(&dev->dev, "%s\n", __func__);

	fpga_pcie_remove_all_subdrivers(priv);

	fpga_pcie_shutdown_pci(dev, priv);

	if (priv->debugfs_root)
		debugfs_remove_recursive(priv->debugfs_root);
}

/*
 * Called for each PCIe Card that matches the ID fields we define
 * for our card, so multi card setups will have a driver deployed 
 * for each card.
 */
static int fpga_pcie_probe(struct pci_dev *dev,
				       const struct pci_device_id *id)
{
	struct fpga_pcie_priv *priv;
	int err = -EINVAL;
	u16 status = 0;

	/* Print some info on the PCIe device */
	dev_info(&dev->dev, "dev_name is %s\n", dev_name(&dev->dev));
	dev_info(&dev->dev, "probe (dev = 0x%p, pci id = 0x%p)\n", dev, id);
	dev_info(&dev->dev, "vendor = 0x%x, device = 0x%x, class = 0x%x\n",
		 dev->vendor, dev->device, dev->class);

	if (pcie_capability_read_word(dev, PCI_EXP_DEVCTL, &status)) {
		dev_err(&dev->dev, "pcie_capability_read_dword failed\n");
		return err;
	}

	dev_info(&dev->dev, "PCI_EXP_DEVCTL is 0x%x\n", status);

	priv = devm_kzalloc(&dev->dev, sizeof(*priv), GFP_KERNEL);
	if (!priv)
		return -ENOMEM;

	priv->state = ST_IDLE;

	INIT_LIST_HEAD(&priv->fdev_list);

	spin_lock_init(&priv->fdev_list_lock);

	priv->debugfs_root = debugfs_create_dir(dev_name(&dev->dev),
						fpga_pcie_debugfs_root);
	if(!priv->debugfs_root ){
		dev_err(&dev->dev, "subdirectory creation failed\n");
		return -EIO;
	}
	
	if (!debugfs_create_file("state", 0660,
				 priv->debugfs_root, priv,
				 &fpga_pcie_state_fops)) {
		dev_err(&dev->dev, "failed to create state debugfs file\n");
		debugfs_remove_recursive(priv->debugfs_root);
		return -EIO;
	}

	if (!debugfs_create_file("base_dtb", 0660,
				 priv->debugfs_root, priv,
				 &fpga_pcie_base_dtb_fops)) {
		dev_err(&dev->dev, "failed to create base_dtb debugfs file\n");
		debugfs_remove_recursive(priv->debugfs_root);
		return -EIO;
	}

	err = fpga_pcie_setup_pci(dev, priv);

	if (err) {
		dev_err(&dev->dev, "failed to setup pr pci: %d\n", err);
		return err;
	}

	return 0;
}

static int fpga_pcie_register_driver(void)
{
	return pci_register_driver(&fpga_pcie_driver);
}

static void fpga_pcie_unregister_driver(void)
{
	pci_unregister_driver(&fpga_pcie_driver);
}

static void fpga_pcie_print_rom(struct fpga_pcie_priv *priv)
{
	struct pci_dev *dev = priv->pci_dev;
	void __iomem *rom_base_addr = priv->bar_addrs[ALTR_PCI_CVP_CONFIG_BAR] +
		    		      ALTR_PCI_CONFIG_ROM_OFFSET;
	int i = fdt_check_header(rom_base_addr);

	if (i)
		dev_err(&dev->dev, "failed to check device tree %d\n", i);
	else {
		
		dump_dtb(&dev->dev, rom_base_addr);
		dev_info(&dev->dev, "successfully checked device tree\n");
	}

	for (i = 0; i < ALTR_PCI_CONFIG_ROM_LEN; i += 4) {
		dev_info(&dev->dev, "ROM %02x %08x\n", i,
			 readl(rom_base_addr+i));
	}
}
/*
 * FOP to write to state file, used as the main way to communicate with driver
 * depending on what is written, the driver responds by performing an action.
 * 0: Restore upstream AER, and restore last state, for Full Chip config, and PCIe reconfig. 
 * 1: Disable updstream AER and save current state, for Full Chip config, and PCIe reconfig,
 * 3: Probes device to deploy subdrivers, used after  PCIe reconfig
 * 4: Removes all subdrivers that are deployed, used to start PCIE reconfig.
 * 5: Debug feature, prints out conents of devices config ROM
 */
static ssize_t fpga_pcie_state_write_file(struct file *file,
					 const char __user *user_buf,
					 size_t count, loff_t *ppos)
{
	struct fpga_pcie_priv *priv = file->private_data;
	struct device *dev = &(priv->pci_dev->dev);
	char *buf;
	ssize_t ret = count;

	buf = devm_kzalloc(dev, count, GFP_KERNEL);
	if (!buf)
		return -ENOMEM;

	if (copy_from_user(buf, user_buf, count)) {
		ret = -EFAULT;
		goto error;
	}

	if (*buf == '1'){
		if (priv->state == ST_AER_DISABLED) {
			dev_info(dev, "Upstream AER already disabled\n");
		} else {
			fpga_pcie_remove_all_subdrivers(priv);
				
			priv->aer_uerr_mask_reg = 
				disable_upstream_aer(priv->pci_dev,
						     priv->pci_upstream_dev);

			dev_info(dev, "%s aer is %x\n", __func__,
				 priv->aer_uerr_mask_reg);

			pci_save_state(priv->pci_dev);

			priv->state = ST_AER_DISABLED;
		}
	} else if (*buf == '0'){
		if (priv->state == ST_AER_DISABLED) {
			pci_restore_state(priv->pci_dev);
			dev_info(dev, "%s setting aer to %x\n",
				 __func__, priv->aer_uerr_mask_reg);

			set_aer_uerr_mask_reg(priv->pci_upstream_dev,
					      priv->/*
* USed for after full chip configuration, to ensure the correct speed is reported, and if not,
* re initialize
					       */aer_uerr_mask_reg);
			retrain_device_speed(priv->pci_dev, priv->pci_upstream_dev);
			priv->state = ST_IDLE;
		} else if (priv->state == ST_IDLE) {
			dev_info(dev, "PR subsystem already idle\n");
		} else {
			dev_err(dev, "Invalid state for idling: %s",
				priv->state);
			ret = -EINVAL;
		}
	} else if (*buf == '3') {
		if (priv->state == ST_IDLE) {
			fpga_pcie_probe_all_subdrivers(priv,
				priv->bar_addrs[ALTR_PCI_CVP_CONFIG_BAR] +
				ALTR_PCI_CONFIG_ROM_OFFSET);
		} else if (priv->state == ST_BASE_PROBED) {
			dev_info(dev, "PR subsystem already probed\n");
		} else {
			dev_err(dev, "Invalid state for probing: %s",
				priv->state);
			ret = -EINVAL;
		}
	} else if (*buf == '4') {
		if (priv->state == ST_BASE_PROBED) {
			fpga_pcie_remove_all_subdrivers(priv);

			dev_info(dev, "PR subsystem unprobed\n");
		} else if (priv->state == ST_IDLE) {
			dev_info(dev, "PR subsystem already idle\n");
		} else {
			dev_err(dev, "Invalid state for unprobing: %s",
				priv->state);
			ret = -EINVAL;
		}
	} else if (*buf == '5') {
		fpga_pcie_print_rom(priv);
	} else {
		dev_err(dev, "Unknown data %c\n", *buf);
		ret = -EINVAL;
	}

error:
	devm_kfree(dev, buf);
	dev_info(dev, "Write to file %zu\n", ret);
	return ret;
}
/*
 * FOP for the state file stored in the debugfs file state,
 */
static ssize_t fpga_pcie_state_read_file(struct file *file,
					 char __user *user_buf,
					 size_t count, loff_t *ppos)
{
	struct fpga_pcie_priv *priv = file->private_data;
	struct device *dev = &(priv->pci_dev->dev);
	int len = strlen(priv->state);
	
	dev_info(dev, "Read to file %zu %llu\n",count, *ppos);
	if (*ppos == 0) {
		if (len < count) {
			if (!copy_to_user(user_buf, priv->state, len)) {
				*ppos = len;
				return len;
			}
		} else {
			dev_err(dev, "read %d >= %zu\n", len, count);
			return -EINVAL;
		}
	}
	return 0;
}
static const struct file_operations fpga_pcie_state_fops = {
	.open = simple_open,
	.read = fpga_pcie_state_read_file,
	.write = fpga_pcie_state_write_file,
	.llseek = default_llseek,
} ;
/*
 * Used for printing ouit the device tree info
 */
#define NUM_REGS 3
static void dump_dtb(struct device *dev, const void *fdt)
{
	int offset, len, i;
	const char *name;
	const char *compat;
	const u32 *reg;
	u32 regs[NUM_REGS];
	for (offset = fdt_next_node(fdt, 0, NULL);
	     offset >= 0;
	     offset = fdt_next_node(fdt, offset, NULL)) {

		name = fdt_get_name(fdt, offset, &len);
		if (!name) {
			dev_err(dev,
			        "no name for offset %d with err %d\n",
				offset, len);
			continue;
		}

		compat = fdt_getprop(fdt, offset, "compatible", &len);
		if (!compat) {
			dev_err(dev, "no compatible for %s %d\n", name, len);
			continue;
		}

		reg = fdt_getprop(fdt, offset, "reg", &len);
		if (!reg) {
			dev_err(dev, "failed to find reg for %s\n", name);
			continue;
		}

		if (len != NUM_REGS*sizeof(*reg)) {
			dev_err(dev, "unexpected reg data size for %s %d\n",
				name, len);
			continue;
		}
		for (i = 0; i < NUM_REGS; i++)
			regs[i] = fdt32_to_cpu(*reg++);

		dev_info(dev, "%s compatible %s %x %x %x\n", name, compat,
			 regs[0], regs[1], regs[2]);
	}
}
/*
 * Allows us to have a multi card machine setup, by probing each device,
 */
static int fpga_pcie_probe_one(struct fpga_pcie_priv *priv,
			struct fpga_drv_entry *drv, void __iomem *regs)
{
	struct device *dev = &(priv->pci_dev->dev);
	struct device *new_dev;
	struct fdev *fdev;
	int err;
	unsigned long flags;

	dev_info(dev, "%s 0x%p\n", __func__, regs);
	fdev = devm_kzalloc(dev, sizeof(*fdev), GFP_KERNEL);

	if (!fdev) {
		dev_err(dev, "zalloc failed in %s\n", __func__);
		return -ENOMEM;
	}

	new_dev = &fdev->dev;

	device_initialize(new_dev);
	
	new_dev->parent = dev;

	err = dev_set_name(new_dev, "%s%s", drv->prefix, dev_name(dev));

	if (err) {
		dev_err(dev, "dev_set_name failed in %s\n", __func__);
		goto error;
	}

	err = device_add(new_dev);

	if (err) {
		dev_err(dev, "device_add failed in %s\n", __func__);
		goto error;
	}

	err = (*drv->probe)(new_dev, regs);

	if (err) {
		dev_err(dev, "probe failed in %s with %d\n", __func__, err);
		device_del(new_dev);
		goto error;
	}

	fdev->remove = drv->remove;

	spin_lock_irqsave(&priv->fdev_list_lock, flags);
	list_add(&fdev->list, &priv->fdev_list);
	spin_unlock_irqrestore(&priv->fdev_list_lock, flags);
	return 0;

error:
	devm_kfree(dev, fdev);
	return err;
}
/*
 * Called after reconfiguration, enumerates the fpga, deploying drivers for all necessary
 * components as defined within the config ROM
 */
static int fpga_pcie_probe_all_subdrivers(struct fpga_pcie_priv *priv,
					  const void *fdt)
{
	struct device *dev = &(priv->pci_dev->dev);
	int offset, len, i;
	const char *name;
	const char *compat;
	const u32 *reg;
	struct fpga_drv_entry *drv;
	u32 regs[NUM_REGS];
	void __iomem *p;

	i = fdt_check_header(fdt);

	if (i) {
		dev_err(dev, "failed to check device tree in %s with %d\n",
			__func__, i);
		return i;
	}

	for (offset = fdt_next_node(fdt, 0, NULL);
	     offset >= 0;
	     offset = fdt_next_node(fdt, offset, NULL)) {

		name = fdt_get_name(fdt, offset, &len);
		if (!name) {
			dev_err(dev,
			        "no name for offset %d with err %d\n",
				offset, len);
			continue;
		}

		compat = fdt_getprop(fdt, offset, "compatible", &len);
		if (!compat) {
			dev_err(dev, "no compatible for %s %d\n", name, len);
			continue;
		}

		drv = fpga_drv_lookup(compat);

		if (!drv) {
			dev_info(dev, "no driver found for %s\n", compat);
			continue;
		}

		reg = fdt_getprop(fdt, offset, "reg", &len);
		if (!reg) {
			dev_err(dev, "failed to find reg for %s\n", name);
			continue;
		}

		if (len != NUM_REGS*sizeof(*reg)) {
			dev_err(dev, "unexpected reg data size for %s %d\n",
				name, len);
			continue;
		}
		for (i = 0; i < NUM_REGS; i++)
			regs[i] = fdt32_to_cpu(*reg++);

		dev_info(dev, "%s compatible %s %x %x %x\n", name, compat,
			 regs[0], regs[1], regs[2]);
		if ((regs[0] < ALTR_PCI_CVP_NUM_BARS) &&
		    priv->bar_addrs[regs[0]]) {
			p = priv->bar_addrs[regs[0]] + regs[1];
			fpga_pcie_probe_one(priv, drv, p);
		}
	}

	priv->state = ST_BASE_PROBED;

	return 0;
}

static int fpga_pcie_remove_one(struct fpga_pcie_priv *priv, struct fdev *fdev)
{
	struct device *dev = &(priv->pci_dev->dev);

	(*fdev->remove)(&fdev->dev);

	device_del(&fdev->dev);

	devm_kfree(dev, fdev);

	return 0;
}
/*
 * Removing all subdrivers that were deployed so that nothing talks upstream 
 * while we reconfigure the devicw
 * 
 */
static int fpga_pcie_remove_all_subdrivers(struct fpga_pcie_priv *priv)
{
	unsigned long flags;
	struct list_head *node, *next;
	struct fdev *fdev;

	list_for_each_safe(node, next, &priv->fdev_list) {
		fdev = list_entry(node, struct fdev, list);

		spin_lock_irqsave(&priv->fdev_list_lock, flags);
		list_del(&fdev->list);
		spin_unlock_irqrestore(&priv->fdev_list_lock, flags);

		fpga_pcie_remove_one(priv, fdev);
	}

	priv->state = ST_IDLE;

	return 0;
}
/*
 * Update the device tree without having to change the rom, used in the event of the rom having 
 * incorrect offsets.
 */
static ssize_t fpga_pcie_base_dtb_write_file(struct file *file,
					 const char __user *user_buf,
					 size_t count, loff_t *ppos)
{
	struct fpga_pcie_priv *priv = file->private_data;
	struct device *dev = &(priv->pci_dev->dev);
	char *buf;
	ssize_t ret = count;

	dev_info(dev, "%s %zu\n", __func__, count);

	buf = devm_kzalloc(dev, count, GFP_KERNEL);
	if (!buf)
		return -ENOMEM;

	if (copy_from_user(buf, user_buf, count)) {
		ret = -EFAULT;
		goto error;
	}

	fpga_pcie_remove_all_subdrivers(priv);

	fpga_pcie_probe_all_subdrivers(priv, buf);

error:
	devm_kfree(dev, buf);
	return ret;
};

static const struct file_operations fpga_pcie_base_dtb_fops = {
	.open = simple_open,
	.write = fpga_pcie_base_dtb_write_file,
	.llseek = default_llseek,
} ;

/*
 * Initialize the driver module (but not any device) and register
 * the module with the kernel PCI subsystem. This is called only 
 * once, when  the .ko is loaded into the kernel. Once registered,
 * the Kernel calls the probe routine for the drivers registered 
 * object
 */
static int __init fpga_pcie_init(void)
{
	int err = 0;

	pr_notice("%s %s\n", DRIVER_DESCRIPTION,
		  DRIVER_VERSION);
	fpga_pcie_debugfs_root = debugfs_create_dir("fpga_pcie", NULL);
	if (!fpga_pcie_debugfs_root)
		pr_err("fpga_pcie: Failed to create debugfs root\n");
	else
		pr_info("fpga_pcie created in debugfs root\n");

	err = fpga_pcie_register_driver();
	if (err < 0) {
		pr_err("fpga_pcie: PCI Registration FAIL\n");
		goto err_out;
	}


	pr_info("fpga_pcie: PCI Registration PASS %d\n", err);

	return 0;

err_out:
	fpga_pcie_unregister_driver();

	return err;
}
/*
 * Called when removing the driver goes through driver and "Cleans up
 * after ourselves"
 */
static void __exit fpga_pcie_exit(void)
{
	pr_info("fpga_pcie: Removing driver");

	/* unregister this driver from the PCI bus driver */
	debugfs_remove_recursive(fpga_pcie_debugfs_root);
	fpga_pcie_unregister_driver();
}

/*
* Declares the entry and exit points of the driver to the kernel
*/
module_init(fpga_pcie_init);
module_exit(fpga_pcie_exit);

/*
 * The main object that contains the information for our PCIe 
 * card, and how the kernel interacts with the card.
 */
static struct pci_driver fpga_pcie_driver = {
	.name = DRIVER_NAME,
	.id_table = fpga_pcie_pci_ids,
	.probe = fpga_pcie_probe,
	.remove = fpga_pcie_remove,
	/* resume and suspend are optional */
};

MODULE_AUTHOR("Kalen Brunham <kbrunham@intel.com>");
MODULE_DESCRIPTION(DRIVER_DESCRIPTION);
MODULE_SUPPORTED_DEVICE("PCIe Boards with FPGAs");
MODULE_LICENSE("GPL v2");
