#include "fpga-pcie.h"
#include "altera-pr-ip-core.h"
#include <linux/debugfs.h>
#include <linux/delay.h>
#include <linux/module.h>
#include <linux/pci.h>

#include <linux/kernel.h>
#include <linux/version.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/errno.h>
#include <asm/uaccess.h>


#define FREEZE_CTRL_OFFSET 4
#define FREEZE_VERSION_OFFSET 12
#define FREEZE_BRIDGE_SUPPORTED_VERSION 0xad000003
#define FREEZE_STATUS_OFFSET 0x00

#define FREEZE_REQ_DONE	BIT(0)
#define UNFREEZE_REQ_DONE BIT(1)

#define FREEZE_REQ BIT(0)
#define RESET_REQ BIT(1)
#define UNFREEZE_REQ BIT(2)


/*
 * Confirms that the freeze bridge version is valid.
 * Returns 0 on success.
 */
static int freeze_bridge_read_version(struct fpga_pcie_priv *priv, u32 ctlr_offset)
{
	struct device *dev = &(priv->pci_dev->dev);
	u32 version = 0;
	u32 version_addr = ctlr_offset + FREEZE_VERSION_OFFSET;

	dev_info(dev, "Verifying region controller version register\n");
	dev_info(dev, "Accessing region controller at offset 0x%08X\n", version_addr);

	version = readl(priv->bar_addrs[ALTR_PCI_CVP_PR_BAR] + version_addr);

	if(version != FREEZE_BRIDGE_SUPPORTED_VERSION ){
		dev_info(dev, "\n ERROR, unsupported PR Region Controller version detected 0x%08X\nSupported Version: 0x%08X exiting.\n", version, FREEZE_BRIDGE_SUPPORTED_VERSION);
		return 0;

	} else {
		dev_info(dev, "\tVersion Register:0x%08X\n", version);
		return 1;
	}

	return 0;

}

/*
 * Polls for acknowledge of freeze request.
 * Returns 0 on success.
 */
static int freeze_bridge_req_ack( struct fpga_pcie_priv *priv, u32 offset, uint32_t req_ack)
{
	uint32_t ack = 0;
	uint32_t status = 0;
	u32 status_addr = offset + FREEZE_STATUS_OFFSET;
	do{
		status = 0;
		status = readl(priv->bar_addrs[ALTR_PCI_CVP_PR_BAR] + status_addr);
		ack = status & req_ack;
	}while(!ack);

	return 0;
}


/*
 * Asserts freeze and reset on the PR region.
 * Returns 0 on success.
 */
int fpga_pr_region_controller_freeze_enable(struct fpga_pcie_priv *priv, u32 offset) 
{
	struct device *dev = &(priv->pci_dev->dev);
	u32 status_addr = offset + FREEZE_STATUS_OFFSET;
	u32 freeze_addr = offset + FREEZE_CTRL_OFFSET;
	u32 status = 0;

	dev_info(dev, "Preparing to enable freeze at offset %d\n", offset);
	

	if(!freeze_bridge_read_version(priv, offset))
		return -EINVAL;

	status = readl(priv->bar_addrs[ALTR_PCI_CVP_PR_BAR] + status_addr);
	
	if (status & FREEZE_REQ_DONE) {
		dev_info(dev, "\t%s bridge already frozen %d\n", __func__, status);
		return 0;
	} else if (!(status & UNFREEZE_REQ_DONE)) {
		dev_info(dev, "\t%s bridge is still unfrozen %d\n", __func__, status);
		return -EINVAL;
	}

	dev_info(dev, "Asserting region freeze\n");
	writel(FREEZE_REQ, priv->bar_addrs[ALTR_PCI_CVP_PR_BAR] + freeze_addr);
	freeze_bridge_req_ack(priv, offset, FREEZE_REQ_DONE);
	dev_info(dev, "Asserting region reset\n");
	writel(RESET_REQ, priv->bar_addrs[ALTR_PCI_CVP_PR_BAR] + freeze_addr);
	dev_info(dev, "Ready for PR\n");

	
	return 0;


}

/*
 * Deasserts reset and freeze on the PR region.
 * Returns 0 on success.
 */
int fpga_pr_region_controller_freeze_disable(struct fpga_pcie_priv *priv, u32 offset)
{

	struct device *dev = &(priv->pci_dev->dev);
	u32 status_addr = offset + FREEZE_STATUS_OFFSET;
	u32 freeze_addr = offset + FREEZE_CTRL_OFFSET;
	u32 status = 0;

	dev_info(dev, "Attempting to disable freeze at offset %d\n", offset);

	if(!freeze_bridge_read_version(priv, offset))
		return -EINVAL;

	status = readl(priv->bar_addrs[ALTR_PCI_CVP_PR_BAR] + status_addr);

	if (status & UNFREEZE_REQ_DONE) {
		dev_info(dev, "\t%s bridge already unfrozen %d\n", __func__, status);
		return 0;
	} else if (!(status & FREEZE_REQ_DONE)) {
		dev_info(dev, "\t%s bridge is still frozen %d\n", __func__, status);
		return -EINVAL;
	}

	dev_info(dev, "Removing region reset\n");
	status = readl(priv->bar_addrs[ALTR_PCI_CVP_PR_BAR] + freeze_addr);
        status = status ^ RESET_REQ;
	writel(status, priv->bar_addrs[ALTR_PCI_CVP_PR_BAR] + freeze_addr);
	writel(UNFREEZE_REQ, priv->bar_addrs[ALTR_PCI_CVP_PR_BAR] + freeze_addr);
	freeze_bridge_req_ack(priv, offset, UNFREEZE_REQ_DONE);
	dev_info(dev, "Removing region freeze\n");
	writel(0, priv->bar_addrs[ALTR_PCI_CVP_PR_BAR] + freeze_addr);
	dev_info(dev, "Device Ready\n");
	return 0;
}

