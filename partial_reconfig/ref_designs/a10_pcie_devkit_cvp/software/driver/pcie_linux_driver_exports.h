// Copyright (c) 2001-2016, Altera Corporation.
// All rights reserved.
//  
// This software is available to you under a choice of one of two
// licenses.  You may choose to be licensed under the terms of the GNU
// General Public License (GPL) Version 2, available from the file
// COPYING in the main directory of this source tree, or the
// BSD 3-Clause license below:
//  
//     Redistribution and use in source and binary forms, with or
//     without modification, are permitted provided that the following
//     conditions are met:
//  
//      - Redistributions of source code must retain the above
//        copyright notice, this list of conditions and the following
//        disclaimer.
//  
//      - Redistributions in binary form must reproduce the above
//        copyright notice, this list of conditions and the following
//        disclaimer in the documentation and/or other materials
//        provided with the distribution.
//  
//      - Neither Altera nor the names of its contributors may be 
//        used to endorse or promote products derived from this 
//        software without specific prior written permission.
//  
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//  

/* All defines necessary to communicate with the Linux PCIe driver.
 * The actual communication functions are open()/close()/read()/write().
 *
 * Example read call (read single ushort from BAR 0, device address 0x2):
 *   ssize_t f = open ("/dev/de4", O_RDWR);
 *   unsigned short val;
 *   struct acl_cmd read_cmd = { 0, ACLPCI_CMD_DEFAULT, 0x2, &val };
 *   read (f, &read_cmd, sizeof(val));
 *
 * See user.c for a tester of all functions and more elaborate examples.
 */

#ifndef PCIE_LINUX_DRIVER_EXPORTS_H
#define PCIE_LINUX_DRIVER_EXPORTS_H


/* if bar_id in acl_cmd is set to this, this is a special command,
 * not a usual read/write request. So the command field is used. Otherwise,
 * command field is ignored. */
#define ACLPCI_CMD_BAR 23

/* A PCI device can have multiple address spaces accessible through each bar,
 * but another possible address space is defined by the DMA controller.  It
 * connects directly to all memory which the PCI device may not be able to do.
 * Hence we define a special "bar id" to tell the driver these addresses are in
 * the DMA space. */
#define ACLPCI_DMA_BAR 25

/* Values for 'command' field of acl_cmd. */

/* Default value -- noop. */
#define ACLPCI_CMD_DEFAULT                0

/* Save/Restore all board PCI control registers to user_addr.
 * Allows user program to reprogram the board without having root
 * priviliges (which is required to change PCI control registers). */
#define ACLPCI_CMD_SAVE_PCI_CONTROL_REGS  1
#define ACLPCI_CMD_LOAD_PCI_CONTROL_REGS  2

/* Lock/Unlock user_addr memory to physical RAM ("pin" it) */
#define ACLPCI_CMD_PIN_USER_ADDR          3
#define ACLPCI_CMD_UNPIN_USER_ADDR        4

/* Get m_idle status of DMA */
#define ACLPCI_CMD_GET_DMA_IDLE_STATUS    5
#define ACLPCI_CMD_DMA_UPDATE             6

/* Get vendor_id and device_id of loaded PCIe device */
#define ACLPCI_CMD_GET_DEVICE_ID          7
#define ACLPCI_CMD_GET_VENDOR_ID          8

/* Change FPGA kernel region by using PR.
 * The caller must provide the .core.rbf file loaded into memory */
#define ACLPCI_CMD_DO_PR                  9

/* PCIe link status queries (PCIe gen and number of lanes) */
#define ACLPCI_CMD_GET_PCI_GEN            10
#define ACLPCI_CMD_GET_PCI_NUM_LANES      11

/* Set id to receive back on signal from kernel */
#define ACLPCI_CMD_SET_SIGNAL_PAYLOAD     12

/* Get full driver version, as string */
#define ACLPCI_CMD_GET_DRIVER_VERSION     13

#define ACLPCI_CMD_ENABLE_KERNEL_IRQ      14

#define ACLPCI_CMD_REPROGRAM_VIA_FPGA_MANAGER 15

/* Map virtual to physical address.
 * Virtual address is passed in user_addr.
 * Physical address is returned in device_addr */
#define ACLPCI_CMD_GET_PHYS_PTR_FROM_VIRT 16

#define ACLPCI_CMD_GET_PCI_DEV_ID         17

#define ACLPCI_CMD_GET_PCI_SLOT_INFO      18

#define ACLPCI_CMD_DMA_STOP               19

#define ACLPCI_CMD_MAX_CMD                20


/* Signal from driver to user (hal) to notify about hw interrupt */
#define SIG_INT_NOTIFY 44

/* Main structure to communicate any command (including read/write)
 * from user space to the driver. */
struct acl_cmd {

  /* base address register of PCIe device. device_addr is interpreted
   * as an offset from this BAR's start address. */
  unsigned int bar_id;
  
  /* Special command to execute. Only used if bar_id is set
   * to ACLPCI_CMD_BAR. */
  unsigned int command;
  
  /* Address in device space where to read/write data. */
  void* device_addr;
  
  /* Address in user space where to write/read data.
   * Always virtual address. */
  void* user_addr;
  
  /* Bypass system restrictions on file I/O size.
   * Pass actual size of transfer here */
  size_t size;
  
  /* Tell the system if the conversion of endianness is needed. This is only */
  /* meaningful when the command is read/write to global memmory, so other   */
  /* command can still function correctly without setting this value.        */
  int is_diff_endian;
};

#endif /* PCIE_LINUX_DRIVER_EXPORTS_H */
