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

#ifndef _ALT_PR_IP_CORE_H
#define _ALT_PR_IP_CORE_H
#include <linux/io.h>

/**
 * enum fpga_PR_IP_states - fpga framework states
 * @FPGA_PR_IP_STATE_UNKNOWN: can't determine state
 * @FPGA_PR_IP_STATE_POWER_OFF: FPGA power is off
 * @FPGA_PR_IP_STATE_POWER_UP: FPGA reports power is up
 * @FPGA_PR_IP_STATE_RESET: FPGA in reset state
 * @FPGA_PR_IP_STATE_FIRMWARE_REQ: firmware request in progress
 * @FPGA_PR_IP_STATE_FIRMWARE_REQ_ERR: firmware request failed
 * @FPGA_PR_IP_STATE_WRITE_INIT: preparing FPGA for programming
 * @FPGA_PR_IP_STATE_WRITE_INIT_ERR: Error during WRITE_INIT stage
 * @FPGA_PR_IP_STATE_WRITE: writing image to FPGA
 * @FPGA_PR_IP_STATE_WRITE_ERR: Error while writing FPGA
 * @FPGA_PR_IP_STATE_WRITE_COMPLETE: Doing post programming steps
 * @FPGA_PR_IP_STATE_WRITE_COMPLETE_ERR: Error during WRITE_COMPLETE
 * @FPGA_PR_IP_STATE_OPERATING: FPGA is programmed and operating
 */
enum fpga_pr_ip_states {
        /* default FPGA states */
        FPGA_PR_IP_STATE_UNKNOWN,
        FPGA_PR_IP_STATE_POWER_OFF,
        FPGA_PR_IP_STATE_POWER_UP,
        FPGA_PR_IP_STATE_RESET,

        /* getting an image for loading */
        FPGA_PR_IP_STATE_FIRMWARE_REQ,
        FPGA_PR_IP_STATE_FIRMWARE_REQ_ERR,

        /* write sequence: init, write, complete */
        FPGA_PR_IP_STATE_WRITE_INIT,
        FPGA_PR_IP_STATE_WRITE_INIT_ERR,
        FPGA_PR_IP_STATE_WRITE,
        FPGA_PR_IP_STATE_WRITE_ERR,
        FPGA_PR_IP_STATE_WRITE_COMPLETE,
        FPGA_PR_IP_STATE_WRITE_COMPLETE_ERR,

        /* fpga is programmed and operating */
        FPGA_PR_IP_STATE_OPERATING,
};


int alt_pr_probe(struct device *dev, void __iomem *reg_base);
int alt_pr_remove(struct device *dev);

int alt_pr_ip_write_init(struct fpga_pcie_priv *priv,
				  const char *buf, size_t count);

int alt_pr_ip_fpga_write(struct fpga_pcie_priv *priv, struct file *fp);

int alt_pr_ip_fpga_write_complete(struct fpga_pcie_priv *priv,
				      int config_timeout_us);


#endif /* _ALT_PR_IP_CORE_H */
