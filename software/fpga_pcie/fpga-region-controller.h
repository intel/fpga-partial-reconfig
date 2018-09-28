#ifndef _ALT_FPGA_RGN_CTRL_H
#define _ALT_FPGA_RGN_CTRL_H
#include <linux/io.h>

int freeze_bridge_read_version(struct fpga_pcie_priv *priv, u32 ctlr_offset);

int freeze_bridge_req_ack( struct fpga_pcie_priv *priv, u32 offset, uint32_t req_ack);

int fpga_pr_region_controller_freeze_enable(struct fpga_pcie_priv *priv, u32 offset);

int fpga_pr_region_controller_freeze_disable(struct fpga_pcie_priv *priv, u32 offset);

#endif /*_ALT_FPGA_RGN_CTRL_H */
