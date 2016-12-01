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

////////////////////////////////////////////////////////////
//                                                        //
// hw_pcie_constants.h                                    //
// Constants to keep in sync with the HW board design     //
//                                                        //
// Note: This file *MUST* be kept in sync with any        //
//       changes to the HW board design!                  //
//                                                        //
////////////////////////////////////////////////////////////

#ifndef HW_PCIE_CONSTANTS_H
#define HW_PCIE_CONSTANTS_H


/***************************************************************/
/********************* Branding/Naming the BSP *****************/
/***************************************************************/

// Branding/Naming the BSP
#define ACL_BOARD_PKG_NAME                          "a10_ref"
#define ACL_VENDOR_NAME                             "Altera Corporation"
#define ACL_BOARD_NAME                              "Arria 10 Reference Platform"

/***************************************************************/
/******************* PCI ID values (VID,DID,etc.) **************/
/***************************************************************/

// Required PCI ID's - DO NOT MODIFY 
#define ACL_PCI_ALTERA_VENDOR_ID              0x1172
#define ACL_PCI_CLASSCODE                   0xEA0001

// PCI SubSystem ID's - MUST be customized by BSP
//     - Must also match the HW string in acl_boards*.inf
#define ACL_PCI_SUBSYSTEM_VENDOR_ID           0x1172
#define ACL_PCI_SUBSYSTEM_DEVICE_ID           0x0001
#define ACL_PCI_REVISION                           1

// PCI Capability
#define ACL_LINK_WIDTH                             8

/***************************************************************/
/*************** Address/Word/Bit Maps used by the HW **********/
/***************************************************************/

// Number of Base Address Registers in the PCIe core
#define ACL_PCI_NUM_BARS 5
 
// Global memory
#define ACL_PCI_GLOBAL_MEM_BAR                     4

// PCIe control register addresses
#define ACL_PCI_CRA_BAR                            4
#define ACL_PCI_CRA_OFFSET                         0
#define ACL_PCI_CRA_SIZE                      0x4000

// Kernel control/status register addresses
#define ACL_KERNEL_CSR_BAR                         4
#define ACL_KERNEL_CSR_OFFSET                 0x4000 

// PCIE DMA Controller Registers on BAR0 (Hidden from QSYS)
#define ACL_PCIE_DMA_INTERNAL_BAR                  0
#define ACL_PCIE_DMA_INTERNAL_CTR_BASE        0x0000

#define ACL_PCIE_DMA_RC_RD_DESC_BASE_LOW      0x0000
#define ACL_PCIE_DMA_RC_RD_DESC_BASE_HIGH     0x0004
#define ACL_PCIE_DMA_EP_RD_FIFO_BASE_LOW      0x0008
#define ACL_PCIE_DMA_EP_RD_FIFO_BASE_HIGH     0x000C
#define ACL_PCIE_DMA_RD_LAST_PTR              0x0010
#define ACL_PCIE_DMA_RD_TABLE_SIZE            0x0014
#define ACL_PCIE_DMA_RD_CONTROL               0x0018

#define ACL_PCIE_DMA_RC_WR_DESC_BASE_LOW      0x0100
#define ACL_PCIE_DMA_RC_WR_DESC_BASE_HIGH     0x0104
#define ACL_PCIE_DMA_EP_WR_FIFO_BASE_LOW      0x0108
#define ACL_PCIE_DMA_EP_WR_FIFO_BASE_HIGH     0x010C
#define ACL_PCIE_DMA_WR_LAST_PTR              0x0110
#define ACL_PCIE_DMA_WR_TABLE_SIZE            0x0114
#define ACL_PCIE_DMA_WR_CONTROL               0x0118

// PCIE descriptor offsets
// Location of FIFO on qsys address where descriptor table is stored
// Same space as memory. Memory starts at 0.
#define ACL_PCIE_DMA_ONCHIP_RD_FIFO_BASE_LO   0xffff0000
#define ACL_PCIE_DMA_ONCHIP_RD_FIFO_BASE_HI   0x00007fff
#define ACL_PCIE_DMA_ONCHIP_WR_FIFO_BASE_LO   0xffff2000
#define ACL_PCIE_DMA_ONCHIP_WR_FIFO_BASE_HI   0x00007fff

#define ACL_PCIE_DMA_TABLE_SIZE                  128

// DMA controller current descriptor ID
#define ACL_PCIE_DMA_RESET_ID                   0xFF

// Avalon Tx port address as seen by the DMA read/write masters
#define ACL_PCIE_TX_PORT               0x2000000000ll

// Global memory window slave address.  The host has different "view" of global
// memory: it sees only 512megs segments of memory at a time for non-DMA xfers
#define ACL_PCIE_MEMWINDOW_BAR                     4 
#define ACL_PCIE_MEMWINDOW_CRA               0x0c870 
#define ACL_PCIE_MEMWINDOW_BASE              0x10000 
#define ACL_PCIE_MEMWINDOW_SIZE              0x10000 

// PCI express control-register offsets
#define PCIE_CRA_IRQ_STATUS                   0xcf90
#define PCIE_CRA_IRQ_ENABLE                   0xcfa0
#define PCIE_CRA_ADDR_TRANS                   0x1000

// IRQ vector mappings (as seen by the PCIe RxIRQ port)
#define ACL_PCIE_KERNEL_IRQ_VEC                    0

// PLL related
#define USE_KERNELPLL_RECONFIG                     1 
#define ACL_PCIE_KERNELPLL_RECONFIG_BAR            4
#define ACL_PCIE_KERNELPLL_RECONFIG_OFFSET   0x0b000

// DMA descriptor control bits
#define DMA_ALIGNMENT_BYTES                       64
#define DMA_ALIGNMENT_BYTE_MASK                     (DMA_ALIGNMENT_BYTES-1)

// Temperature sensor presence and base address macros
#define ACL_PCIE_HAS_TEMP_SENSOR                   1
#define ACL_PCIE_TEMP_SENSOR_ADDRESS          0xcff0

// Version ID and Uniphy Status
#define ACL_VERSIONID_BAR                          4
#define ACL_VERSIONID_OFFSET                  0xcfc0 
#define ACL_VERSIONID                     0xA0C7C1E2

// Uniphy Status - used to confirm controller is calibrated
#define ACL_UNIPHYRESET_BAR                        4
#define ACL_UNIPHYRESET_OFFSET                0xcfd0
#define ACL_UNIPHYSTATUS_BAR                       4
#define ACL_UNIPHYSTATUS_OFFSET               0xcfe0

// Partial reconfiguration IP	
#define ACL_PRCONTROLLER_BAR                       4
#define ACL_PRCONTROLLER_OFFSET               0xcfb0

// Base revision PR ID
#define ACL_PRBASEID_BAR                           4
#define ACL_PRBASEID_OFFSET                   0xcf80

// Handy macros
#define ACL_PCIE_READ_BIT( w, b ) (((w) >> (b)) & 1)
#define ACL_PCIE_READ_BIT_RANGE( w, h, l ) (((w) >> (l)) & ((1 << ((h) - (l) + 1)) - 1))
#define ACL_PCIE_SET_BIT( w, b ) ((w) |= (1 << (b)))
#define ACL_PCIE_CLEAR_BIT( w, b ) ((w) &= (~(1 << (b))))
#define ACL_PCIE_GET_BIT( b ) (unsigned) (1 << (b))

#endif // HW_PCIE_CONSTANTS_H
