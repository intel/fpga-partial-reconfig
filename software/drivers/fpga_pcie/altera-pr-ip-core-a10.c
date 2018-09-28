/*
 * Driver for Altera Partial Reconfiguration IP Core
 *
 * Copyright (C) 2016 Intel Corporation
 *
 * Based on socfpga-a10.c Copyright (C) 2015-2016 Altera Corporation
 *  by Alan Tull <atull@opensource.altera.com>
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

#include "fpga-pcie.h"
#include "altera-pr-ip-core.h"
#include <linux/delay.h>
#include <linux/module.h>
#include <linux/time.h>

#define ALT_PR_DATA_OFST		0x00
#define ALT_PR_CSR_OFST			0x04
#define ALT_PR_VER_OFST			0x08
#define ALT_PR_POF_ID_OFST		0x0c

#define ALT_PR_CSR_PR_START		BIT(0)
#define ALT_PR_CSR_STATUS_SFT		2
#define ALT_PR_CSR_STATUS_MSK		(7 << ALT_PR_CSR_STATUS_SFT)
#define ALT_PR_CSR_STATUS_NRESET	(0 << ALT_PR_CSR_STATUS_SFT)
#define ALT_PR_CSR_STATUS_PR_ERR	(1 << ALT_PR_CSR_STATUS_SFT)
#define ALT_PR_CSR_STATUS_CRC_ERR	(2 << ALT_PR_CSR_STATUS_SFT)
#define ALT_PR_CSR_STATUS_BAD_BITS	(3 << ALT_PR_CSR_STATUS_SFT)
#define ALT_PR_CSR_STATUS_PR_IN_PROG	(4 << ALT_PR_CSR_STATUS_SFT)
#define ALT_PR_CSR_STATUS_PR_SUCCESS	(5 << ALT_PR_CSR_STATUS_SFT)

#define ALT_PR_VER_POF_ID		0xaa500003
#define ALT_PR_RBF_ID_OFST		(unsigned int)(71*sizeof(u32))

static enum fpga_pr_ip_states alt_pr_ip_fpga_state(struct fpga_pcie_priv *priv)
{
	struct device *dev = &(priv->pci_dev->dev);
	const char *err = "unknown";
	enum fpga_pr_ip_states ret = FPGA_PR_IP_STATE_UNKNOWN;
	u32 val;

	val = readl(priv->reg_base + ALT_PR_CSR_OFST);

	val &= ALT_PR_CSR_STATUS_MSK;

	switch (val) {
	case ALT_PR_CSR_STATUS_NRESET:
		return FPGA_PR_IP_STATE_RESET;

	case ALT_PR_CSR_STATUS_PR_ERR:
		err = "pr error";
		ret = FPGA_PR_IP_STATE_WRITE_ERR;
		break;

	case ALT_PR_CSR_STATUS_CRC_ERR:
		err = "crc error";
		ret = FPGA_PR_IP_STATE_WRITE_ERR;
		break;

	case ALT_PR_CSR_STATUS_BAD_BITS:
		err = "bad bits";
		ret = FPGA_PR_IP_STATE_WRITE_ERR;
		break;

	case ALT_PR_CSR_STATUS_PR_IN_PROG:
		return FPGA_PR_IP_STATE_WRITE;

	case ALT_PR_CSR_STATUS_PR_SUCCESS:
		return FPGA_PR_IP_STATE_OPERATING;

	default:
		break;
	}

	dev_err(dev, "encountered error code %d (%s) in %s()\n",
		val, err, __func__);
	return ret;
}

int alt_pr_ip_write_init(struct fpga_pcie_priv *priv,
				  const char *buf, size_t count)
{
	struct device *dev = &(priv->pci_dev->dev);
	u32 val;
	u32 *prbf;

	dev_info(dev, "Starting write init.\n");

	val = readl(priv->reg_base + ALT_PR_CSR_OFST);

	if (val & ALT_PR_CSR_PR_START) {
		dev_err(dev, "%s Partial Reconfiguration already started\n",
		       __func__);
		return -EINVAL;
	}

	val = readl(priv->reg_base + ALT_PR_VER_OFST);

	if (val == ALT_PR_VER_POF_ID) {
		if (count < ALT_PR_RBF_ID_OFST) {
			dev_err(dev, "%s count is too small %zu < %u\n",
				__func__,
				count, ALT_PR_RBF_ID_OFST);
			return -EINVAL;
		}

		prbf = (u32*)(buf + ALT_PR_RBF_ID_OFST);

		val = readl(priv->reg_base + ALT_PR_POF_ID_OFST);

		if (val) {
			if (val != *prbf) {
				dev_err(dev, "%s POF ID does not match RBF %x != %x",
					__func__, val, *prbf);
				return -EINVAL;
			}
			dev_info(dev, "%s POF ID matches RBF\n",
				 __func__);
		} else
			dev_info(dev, "POF ID check disabled\n");
	}

	writel(val | ALT_PR_CSR_PR_START, priv->reg_base + ALT_PR_CSR_OFST);

	dev_info(dev, "Ending write init.\n");

	return 0;
}

int alt_pr_ip_fpga_write(struct fpga_pcie_priv *priv, struct file *fp)
{
	int offset = 0;
	int ret = 0;
	char buf[4];

	struct device *dev = &(priv->pci_dev->dev);
	dev_info(dev, "Starting write.\n");
	ret = kernel_read(fp, offset, buf, 4);

	do {
		offset = offset + ret;
		writel(((u32 *)buf)[0], priv->reg_base);
		ret = kernel_read(fp, offset, buf, 4);

	} while (ret >= 4);


	/* Write out remaining non 32-bit chunks */
	switch (ret) {
	case 3:
		writel(((u32 *)buf)[0] & 0x00ffffff, priv->reg_base);
		break;
	case 2:
		writel(((u32 *)buf)[0] & 0x0000ffff, priv->reg_base);
		break;
	case 1:
		writel(((u32 *)buf)[0] & 0x000000ff, priv->reg_base);
		break;
	case 0:
		break;
	default:
		/* This will never happen */
		return -EFAULT;
	}


	if (alt_pr_ip_fpga_state(priv) == FPGA_PR_IP_STATE_WRITE_ERR)
		return -EIO;

	dev_info(dev, "Ending write.\n");

	return 0;
}

int alt_pr_ip_fpga_write_complete(struct fpga_pcie_priv *priv,
				      int config_timeout_us)
{
	struct device *dev = &(priv->pci_dev->dev);
	u32 i;

	for (i = 0; i < config_timeout_us; i++) {
		switch (alt_pr_ip_fpga_state(priv)) {
		case FPGA_PR_IP_STATE_WRITE_ERR:
			return -EIO;

		case FPGA_PR_IP_STATE_OPERATING:
			dev_info(dev, "successful partial reconfiguration\n");
			return 0;

		default:
			break;
		}
		udelay(1);
	}
	dev_err(dev, "timed out waiting for write to complete\n");
	return -ETIMEDOUT;
}





