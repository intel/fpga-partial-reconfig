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
#include "altera-pr-ip-core.h"
#include <linux/delay.h>
#include <linux/fpga/fpga-mgr.h>
#include <linux/module.h>
#include <linux/time.h>

#define ALT_PR_DATA_OFST		0x00
#define ALT_PR_CSR_OFST			0x04
#define ALT_PR_VER_OFST			0x08
#define ALT_PR_POF_ID_OFST		0x0c


#define ALT_PR_CSR_PR_START		BIT(0)
#define ALT_PR_CSR_STATUS_SFT		1
#define ALT_PR_CSR_STATUS_MSK		(7 << ALT_PR_CSR_STATUS_SFT)
#define ALT_PR_CSR_STATUS_NRESET	(0 << ALT_PR_CSR_STATUS_SFT)
#define ALT_PR_CSR_STATUS_BUSY	    (1 << ALT_PR_CSR_STATUS_SFT)
#define ALT_PR_CSR_STATUS_PR_IN_PROG	(2 << ALT_PR_CSR_STATUS_SFT)
#define ALT_PR_CSR_STATUS_PR_SUCCESS	(3 << ALT_PR_CSR_STATUS_SFT)
#define ALT_PR_CSR_STATUS_PR_ERR	    (4 << ALT_PR_CSR_STATUS_SFT)

#define ALT_P_BASE 0x0c 
#define ALT_P_STARTUP 0x00
#define ALT_P_DATA_LO 0x04
#define ALT_P_DATA_HI 0x08
#define ALT_P_PROCESS_LO 0x0c
#define ALT_P_PROCESS_HI 0x10
#define ALT_P_COMPLETE 0x14


#define ALT_PR_VER_POF_ID		0xaa500003
#define ALT_PR_RBF_ID_OFST		(unsigned int)(71*sizeof(u32))

struct alt_pr_priv {
	void __iomem *reg_base;
};

static void read_p_reg(struct fpga_manager *mgr, u64 total_time_for_pr)
{
	struct alt_pr_priv *priv = mgr->priv;
	u64 p_startup, p_data, p_process, p_complete, p_total;

	p_startup = readl(priv->reg_base + ALT_P_BASE + ALT_P_STARTUP);
	p_data = readl(priv->reg_base + ALT_P_BASE + ALT_P_DATA_LO)
		+ ((u64)readl(priv->reg_base + ALT_P_BASE + ALT_P_DATA_HI) << 32);
	p_process = readl(priv->reg_base + ALT_P_BASE + ALT_P_PROCESS_LO)
		+ ((u64)readl(priv->reg_base + ALT_P_BASE + ALT_P_PROCESS_HI) << 32);
	p_complete = readl(priv->reg_base + ALT_P_BASE + ALT_P_COMPLETE);

	p_total =  p_startup + p_data + p_process + p_complete;


	pr_info("Total Time taken to complete PR: %llu seconds.\n", total_time_for_pr);
	dev_info(&mgr->dev, "PR_PRSE_STR A REG %llu END_PRSE\n", total_time_for_pr);

	dev_info(&mgr->dev, "TOTAL: %llu. Broken down as follows:\n",
		p_total);
	dev_info(&mgr->dev, "PR_PRSE_STR B REG %llu END_PRSE\n", p_total);

	dev_info(&mgr->dev, "Read from 0x3: %llu \n",
		p_startup); 
	dev_info(&mgr->dev, "PR_PRSE_STR C REG %llu END_PRSE\n", p_startup);

	dev_info(&mgr->dev, "Read from 0x4 and 0x5: %llu \n",
		p_data);
	dev_info(&mgr->dev, "PR_PRSE_STR D REG %llu END_PRSE\n", p_data);

	dev_info(&mgr->dev, "Read from 0x6 and 0x7: %llu \n",
		p_process);
	dev_info(&mgr->dev, "PR_PRSE_STR E REG %llu END_PRSE\n", p_process);

	dev_info(&mgr->dev, "Read from 0x8: %llu \n",
		p_complete);
	dev_info(&mgr->dev, "PR_PRSE_STR F REG %llu END_PRSE\n", p_complete);

}

static int alt_pr_wait_for_initial_state (struct fpga_manager *mgr)
{
	struct alt_pr_priv *priv = mgr->priv;
	u32 val;
	u32 i;
	u32 timeout = 1;
	u32 timeout_time = 5000;

	val = readl(priv->reg_base + ALT_PR_CSR_OFST);

	val &= ALT_PR_CSR_STATUS_MSK;

	if (val == ALT_PR_CSR_STATUS_BUSY) { 

		dev_info(&mgr->dev, "PR IP in BUSY state. Waiting. \n");

		
		for (i = 0; i < timeout_time; i++) 
		{
			if ((val != ALT_PR_CSR_STATUS_NRESET) || (val != ALT_PR_CSR_STATUS_PR_SUCCESS))
			{
				val = readl(priv->reg_base + ALT_PR_CSR_OFST);
				val &= ALT_PR_CSR_STATUS_MSK;
				msleep (1); /* 1 ms */
			}
			else 
			{
				timeout = 0;
				dev_info(&mgr->dev, "PR IP entered reset state after %d ms. \n", i);
				break;
			}

		}

		if (timeout)
		{
			dev_err(&mgr->dev, "PR IP was not ready after %d ms. \n", timeout_time);
			return -ETIMEDOUT;
		}

	}

	return 0;
}

static enum fpga_mgr_states alt_pr_fpga_state(struct fpga_manager *mgr)
{
	struct alt_pr_priv *priv = mgr->priv;
	const char *err = "unknown";
	enum fpga_mgr_states ret = FPGA_MGR_STATE_UNKNOWN;
	u32 val;

	val = readl(priv->reg_base + ALT_PR_CSR_OFST);

	val &= ALT_PR_CSR_STATUS_MSK;

	switch (val) {
	case ALT_PR_CSR_STATUS_NRESET:
		dev_info(&mgr->dev, "PR IP in state: FPGA_MGR_STATE_RESET. \n");
		return FPGA_MGR_STATE_RESET;

	case ALT_PR_CSR_STATUS_PR_ERR:
		err = "pr error";
		dev_info(&mgr->dev, "PR IP in state: FPGA_MGR_WRITE_ERR. \n");
		ret = FPGA_MGR_STATE_WRITE_ERR;
		break;

	case ALT_PR_CSR_STATUS_PR_IN_PROG:
		dev_info(&mgr->dev, "PR IP in state: FPGA_MGR_STATE_WRITE. \n");
		return FPGA_MGR_STATE_WRITE;

	case ALT_PR_CSR_STATUS_PR_SUCCESS:
		dev_info(&mgr->dev, "PR IP in state: FPGA_MGR_STATE_OPERATING. \n");
		return FPGA_MGR_STATE_OPERATING;

	case ALT_PR_CSR_STATUS_BUSY:
		err = "pr busy";
		dev_info(&mgr->dev, "PR IP returned CSR_STATUS_BUSY. \n");
		break;

	default:
		break;
	}

	dev_err(&mgr->dev, "encountered error code %d (%s) in %s()\n",
		val >> ALT_PR_CSR_STATUS_SFT, err, __func__);
	return ret;
}

static int alt_pr_fpga_write_init(struct fpga_manager *mgr,
				  struct fpga_image_info *info,
				  const char *buf, size_t count)
{
	struct alt_pr_priv *priv = mgr->priv;
	u32 val;
	u32 *prbf;

	dev_info(&mgr->dev, "Checking PR IP FLAGS\n");

	if (!(info->flags & FPGA_MGR_PARTIAL_RECONFIG)) {
		dev_err(&mgr->dev, "%s Partial Reconfiguration flag not set\n",
			__func__);
		return -EINVAL;
	}

	val = readl(priv->reg_base + ALT_PR_CSR_OFST);

	if (val & ALT_PR_CSR_PR_START) {
		dev_err(&mgr->dev,
			"%s Partial Reconfiguration already started\n",
		       __func__);
		return -EINVAL;
	}

	val = readl(priv->reg_base + ALT_PR_VER_OFST);

	if (val == ALT_PR_VER_POF_ID) {
		if (count < ALT_PR_RBF_ID_OFST) {
			dev_err(&mgr->dev, "%s count is too small %zu < %u\n",
				__func__,
				count, ALT_PR_RBF_ID_OFST);
			return -EINVAL;
		}

		prbf = (u32*)(buf + ALT_PR_RBF_ID_OFST);

		val = readl(priv->reg_base + ALT_PR_POF_ID_OFST);

		if (val) {
			if (val != *prbf) {
				dev_err(&mgr->dev,
					"%s POF ID does not match RBF %x != %x",
					__func__, val, *prbf);
				return -EINVAL;
			}
			dev_info(&mgr->dev, "%s POF ID matches RBF\n",
				 __func__);
		} else
			dev_info(&mgr->dev, "POF ID check disabled\n");
	}

	dev_info(&mgr->dev, "Done checking PR IP FLAGS\n");

	dev_info(&mgr->dev, "Waiting for PR IP initial state\n");
	if (alt_pr_wait_for_initial_state(mgr))
		return -ETIMEDOUT;

	dev_info(&mgr->dev, "PR IP not busy\n");


	dev_info(&mgr->dev, "Checking initial state\n");
	alt_pr_fpga_state(mgr);
	dev_info(&mgr->dev, "Done checking initial state\n");

	writel(val | ALT_PR_CSR_PR_START, priv->reg_base + ALT_PR_CSR_OFST);

	return 0;
}

static int alt_pr_fpga_write(struct fpga_manager *mgr, const char *buf,
			     size_t count)
{
	struct alt_pr_priv *priv = mgr->priv;
	u32 *buffer_32 = (u32 *)buf;
	size_t i = 0;
	u32 j = 0;
	u32 chunk_num = 0;
	u32 time_to_wait = WAIT_TIME; //compile parameter
	struct timeval start_time;
	struct timeval end_time;

	if (count <= 0)
		return -EINVAL;

	dev_info(&mgr->dev, "Checking pre-write state\n");
	alt_pr_fpga_state(mgr);
	dev_info(&mgr->dev, "Done checking pre-write state\n");

	do_gettimeofday(&start_time);


	/* Write out the complete 32-bit chunks */
	/* Wait for a designated amount of time between 4K chunks */
	while (count >= sizeof(u32)) {
		j++;
		writel(buffer_32[i++], priv->reg_base);
		count -= sizeof(u32);

		if (j >= 1024)
		{
			chunk_num++;
			j = 0;
#ifdef VERBOSE_TRUE
			dev_info(&mgr->dev, "4K RBF chunk # %d written. Checking state and pausing for %d ms\n", chunk_num, time_to_wait);
			if (alt_pr_fpga_state(mgr) != FPGA_MGR_STATE_WRITE)
			{
				dev_err(&mgr->dev, "PR IP Error while writing RBF\n");
				return -EIO;
			}
#endif
			msleep(time_to_wait);
		}
	}

	/* Write out remaining non 32-bit chunks */
	switch (count) {
	case 3:
		writel(buffer_32[i++] & 0x00ffffff, priv->reg_base);
		break;
	case 2:
		writel(buffer_32[i++] & 0x0000ffff, priv->reg_base);
		break;
	case 1:
		writel(buffer_32[i++] & 0x000000ff, priv->reg_base);
		break;
	case 0:
		break;
	default:
		/* This will never happen */
		return -EFAULT;
	}


	if (alt_pr_fpga_state(mgr) == FPGA_MGR_STATE_WRITE_ERR)
		return -EIO;

	do_gettimeofday(&end_time);

	read_p_reg(mgr, (u64)(end_time.tv_sec - start_time.tv_sec)); 

	return 0;
}

static int alt_pr_fpga_write_complete(struct fpga_manager *mgr,
				      struct fpga_image_info *info)
{
	u32 i;

	for (i = 0; i < info->config_complete_timeout_us; i++) {
		msleep(200); /*200ms*/ 
		switch (alt_pr_fpga_state(mgr)) {
		case FPGA_MGR_STATE_WRITE_ERR:
			return -EIO;

		case FPGA_MGR_STATE_OPERATING:
			dev_info(&mgr->dev,
				 "successful partial reconfiguration\n");
			return 0;

		default:
			break;
		}
		udelay(1);
	}
	dev_err(&mgr->dev, "timed out waiting for write to complete\n");
	return -ETIMEDOUT;
}

static const struct fpga_manager_ops alt_pr_ops = {
	.state = alt_pr_fpga_state,
	.write_init = alt_pr_fpga_write_init,
	.write = alt_pr_fpga_write,
	.write_complete = alt_pr_fpga_write_complete,
};

int alt_pr_probe(struct device *dev, void __iomem *reg_base)
{
	struct alt_pr_priv *priv;
	u32 val;

	priv = devm_kzalloc(dev, sizeof(*priv), GFP_KERNEL);
	if (!priv)
		return -ENOMEM;

	priv->reg_base = reg_base;

	val = readl(priv->reg_base + ALT_PR_CSR_OFST);

	dev_info(dev, "%s status=%d start=%d ver=0x%x\n", __func__,
		 (val & ALT_PR_CSR_STATUS_MSK) >> ALT_PR_CSR_STATUS_SFT,
		 (int)(val & ALT_PR_CSR_PR_START),
		 readl(priv->reg_base + ALT_PR_VER_OFST));

	return fpga_mgr_register(dev, dev_name(dev), &alt_pr_ops, priv);
}
EXPORT_SYMBOL_GPL(alt_pr_probe);

int alt_pr_remove(struct device *dev)
{
	dev_dbg(dev, "%s\n", __func__);

	fpga_mgr_unregister(dev);

	return 0;
}
EXPORT_SYMBOL_GPL(alt_pr_remove);

MODULE_AUTHOR("Matthew Gerlach <matthew.gerlach@linux.intel.com>");
MODULE_DESCRIPTION("Altera Partial Reconfiguration IP Core");
MODULE_LICENSE("GPL v2");

