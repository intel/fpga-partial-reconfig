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

#include <asm/io.h> // __raw_writel
#include "aclpci.h"
#include "hw_pcie_cvp_constants.h"



/********************************************/
/* Code below is taken from quartus/pgm/cvp_drv/cvp_drv.c
 * When OpenCL becomes part of Quartus, remove the duplicate code */
 
/* Map VSEC_BIT to offset and bitmask. 
 * Taken from pgm/cvp_drv/cvp_drv.c */
static void get_mask_and_offset(unsigned char whichBit, unsigned char *bitMask, unsigned char *bitRegOffset)
{
  switch (whichBit) {
    case DATA_ENCRYPTED:
      *bitRegOffset = OFFSET_CVP_STATUS;
      *bitMask = MASK_DATA_ENCRYPTED;
      break;
    case DATA_COMPRESSED:
      *bitRegOffset = OFFSET_CVP_STATUS;
      *bitMask = MASK_DATA_COMPRESSED;
      break;
    case CVP_CONFIG_READY:
      *bitRegOffset = OFFSET_CVP_STATUS;
      *bitMask = MASK_CVP_CONFIG_READY;
      break;
    case CVP_CONFIG_ERROR:
      *bitRegOffset = OFFSET_CVP_STATUS;
      *bitMask = MASK_CVP_CONFIG_ERROR;
      break;
    case CVP_EN:
      *bitRegOffset = OFFSET_CVP_STATUS;
      *bitMask = MASK_CVP_EN;
      break;
    case USER_MODE:
      *bitRegOffset = OFFSET_CVP_STATUS;
      *bitMask =  MASK_USER_MODE;
      break;
    case PLD_CLK_IN_USE:
      *bitRegOffset = OFFSET_CVP_STATUS+1;
      *bitMask = MASK_PLD_CLK_IN_USE;
      break;
    case CVP_MODE:
      *bitRegOffset = OFFSET_CVP_MODE_CTRL;
      *bitMask = MASK_CVP_MODE;
      break;
    case HIP_CLK_SEL:
      *bitRegOffset = OFFSET_CVP_MODE_CTRL;
      *bitMask = MASK_HIP_CLK_SEL;
      break;
    case CVP_CONFIG:
      *bitRegOffset = OFFSET_CVP_PROG_CTRL;
      *bitMask = MASK_CVP_CONFIG;
      break;
    case START_XFER:
      *bitRegOffset = OFFSET_CVP_PROG_CTRL;
      *bitMask = MASK_START_XFER;
      break;
    case CVP_CFG_ERR_LATCH:
      *bitRegOffset = OFFSET_UNC_IE_STATUS;
      *bitMask = MASK_CVP_CFG_ERR_LATCH;
      break;
    default:
      *bitRegOffset = -1;
      *bitMask = -1;
      break;
  }
}

static unsigned char read_bit (struct pci_dev *dev, unsigned char whichBit)
{
  unsigned char bitMask, bitRegOffset;
  u8 byteRead;
  get_mask_and_offset(whichBit, &bitMask, &bitRegOffset);  
  pci_read_config_byte (dev, OFFSET_VSEC + bitRegOffset, &byteRead);
  return (byteRead & bitMask) ? 1 : 0;
}

static void write_bit (struct pci_dev *dev, unsigned char whichBit, unsigned char bitValue)
{
  unsigned char bitMask, bitRegOffset;
  u8 byteValue;
  switch (whichBit) {
    case CVP_MODE:
    case HIP_CLK_SEL:
    case CVP_CONFIG:
    case START_XFER:
    case CVP_CFG_ERR_LATCH:
      get_mask_and_offset (whichBit, &bitMask, &bitRegOffset);
      pci_read_config_byte (dev, OFFSET_VSEC + bitRegOffset, &byteValue);
      byteValue = bitValue ? (byteValue | bitMask) : (byteValue & ~bitMask);
      pci_write_config_byte (dev, OFFSET_VSEC + bitRegOffset, byteValue);
      break;
    default:
      break; // do nothing, the 5 bits above are the only writeable ones
  }
}


/* Dump state of PCIe VSEC region. Useful when detect an error during CvP */
static void dump_pcie_vsec_state (struct pci_dev *dev)
{
#define READ_PRINT16(x) pci_read_config_word  (dev, OFFSET_VSEC + x, &result16); ACL_DEBUG (KERN_DEBUG "%s = 0x%x", #x, result16);
#define READ_PRINT32(x) pci_read_config_dword (dev, OFFSET_VSEC + x, &result32); ACL_DEBUG (KERN_DEBUG "%s = 0x%x", #x, result32);

   u32 result32;
   u16 result16;

   ACL_DEBUG (KERN_DEBUG "Dump of PCIe VSEC");
   READ_PRINT16 (OFFSET_CVP_STATUS);
   READ_PRINT32 (OFFSET_CVP_MODE_CTRL);
   READ_PRINT32 (OFFSET_CVP_DATA);
   READ_PRINT32 (OFFSET_CVP_PROG_CTRL);
   READ_PRINT32 (OFFSET_UNC_IE_STATUS);
   
#undef READ_PRINT16
#undef READ_PRINT32
}


/* Wait for given bit to be given value, upto maximum value.
 * Returns 1 if the given value was reached. */
static unsigned char wait_for_bit (struct pci_dev *dev, unsigned char whichBit, unsigned char value)
{
  int max_num_tries = 10;
  int single_delay = 1; /* in milliseconds */
  int itry = 0;
  while (read_bit (dev, whichBit) != value && itry < max_num_tries) {
    itry++;
    msleep (single_delay);
  }
  return (itry < max_num_tries);
}


static void send_pgm_data (struct aclpci_dev *aclpci, u32 data)
{
  __raw_writel (data, aclpci->bar[0] + 0x0);
  mb();
}


#define OFFSET_CVP_NUMCLKS   0X21
static void CVP_DRV_SetNumClks(struct pci_dev *dev, unsigned char numClks)
{
  int write_addr = OFFSET_VSEC+OFFSET_CVP_NUMCLKS;
  
  if (numClks == 64) {
    pci_write_config_byte (dev, write_addr, 0x0);
  } else if (numClks > 0 && numClks < 64) {
    pci_write_config_byte (dev, write_addr, numClks);
  } else {
    // numClks is not a valid number!
  }
}


static void prepare_for_pgm_data(struct pci_dev *dev)
{
  if (read_bit(dev, DATA_COMPRESSED)) {
    CVP_DRV_SetNumClks(dev, 8);
  } else if (read_bit(dev, DATA_ENCRYPTED)) {
    CVP_DRV_SetNumClks(dev, 4);
  } else {
    CVP_DRV_SetNumClks(dev, 1);
  }
}



/* Issue "dummy" writes to the HIP's memory to make the CB switch between CvP and internal clocks.
 * The CB needs at least 244 125 MHz clock ticks, so we give it 64*4 = 256. */
#define NUM_REG_WRITES       244
#define VALUE_DUMMY          0x0
#define NUM_CVP_CLKS         1
static void switch_clock (struct aclpci_dev *aclpci)
{
  int i;
  CVP_DRV_SetNumClks(aclpci->pci_dev, NUM_CVP_CLKS);
  for (i = 0; i < NUM_REG_WRITES; i++) {
    writel (VALUE_DUMMY, aclpci->bar[0] + 0x0);
  }
}


/* check for CRC error that many 32-bit words */
#define ERR_CHK_INTERVAL 25000


/* Re-configure FPGA core with given bitstream via PCIe.
 * Support for Stratix V devices and higher */
int aclpci_cvp (struct aclpci_dev *aclpci, void __user* core_bitstream, ssize_t len) {

  struct pci_dev *dev = NULL;
  u32 *data;
  int i;
  int cvp_failed = 0;
  int result = -EFAULT;

  // ACL_DEBUG (KERN_DEBUG "aclpci_cvp (%p, %p, %lu)", aclpci, core_bitstream, len);
  
  /* Basic error checks */  
  if (aclpci == NULL) {
    ACL_DEBUG (KERN_WARNING "Need to open device before can do reconfigure!");
    return result;
  }
  if (core_bitstream == NULL) {
    ACL_DEBUG (KERN_WARNING "Programming bitstream is not provided!");
    return result;
  }
  if (len < 1000000) {
    ACL_DEBUG (KERN_WARNING "Programming bitstream length is suspiciously small. Not doing CvP!");
    return result;
  }
  
  dev = aclpci->pci_dev;
  if (dev == NULL) {
    ACL_DEBUG (KERN_WARNING "Dude, where is PCIe device?!");
    return result;
  }

  
  if (!read_bit (dev, CVP_EN)) {
    ACL_DEBUG (KERN_WARNING "CvP is not enabled in the design on the FPGA!");
    return result;
  }
  
  ACL_DEBUG (KERN_DEBUG "OK to proceed with CvP!");
  aclpci->cvp_in_progress = 1;
    
  write_bit(dev, HIP_CLK_SEL, 1);
  write_bit(dev, CVP_MODE, 1);  
  msleep (2);
  switch_clock(aclpci);
  
  write_bit(dev, CVP_CONFIG, 1);
  msleep (2);
  switch_clock(aclpci);

  /* wait for the CB to say it's ready for CvP */
  if (!wait_for_bit (dev, CVP_CONFIG_READY, 1)) {
    ACL_DEBUG (KERN_WARNING "Timed out waiting for CVP_CONFIG_READY to become 1! CvP has failed");
    dump_pcie_vsec_state(dev);
    cvp_failed = 1;
    goto teardown;
  }

  switch_clock(aclpci);
  write_bit(dev, START_XFER, 1);
  
  if (!wait_for_bit (dev, HIP_CLK_SEL, 1) || !wait_for_bit (dev, CVP_MODE, 1)) {
    ACL_DEBUG (KERN_WARNING "Timed out waiting for HIP_CLK_SEL and CVP_MODE to be 1! CvP has failed");
    dump_pcie_vsec_state(dev);
    cvp_failed = 1;
    goto teardown;
  }

  /* Transfer */
  prepare_for_pgm_data(dev);

  ACL_DEBUG (KERN_WARNING "Setup is done. Starting to write CvP data!");

  data = (u32 __user*)core_bitstream;
  for (i = 0; i < len; i++) {
    u32 curData;
    result = copy_from_user ( &curData, data + i, sizeof(curData));

    send_pgm_data (aclpci, curData);
    if ((i % ERR_CHK_INTERVAL == 0) && read_bit(dev, CVP_CONFIG_ERROR)) {
      ACL_DEBUG (KERN_WARNING "ERROR: CB detected a CRC error between words %d and %d!\n", (i - ERR_CHK_INTERVAL), i);
      dump_pcie_vsec_state(dev);
      cvp_failed = 1;
      break;
    }
  }

  if (i == len) {
    ACL_DEBUG (KERN_DEBUG "INFO: Reached the end of the core programming file.");
  }

teardown:
  // Teardown
  write_bit(dev, START_XFER, 0);
  write_bit(dev, CVP_CONFIG, 0);
  switch_clock(aclpci);

  // wait for the CB to say it's done with CvP
  if (!wait_for_bit (dev, CVP_CONFIG_READY, 0)) {
    ACL_DEBUG (KERN_WARNING "Timed out waiting for CVP_CONFIG_READY to become 0! CvP has failed");
    dump_pcie_vsec_state(dev);
  }

  if (read_bit(dev, CVP_CFG_ERR_LATCH)) {
    ACL_DEBUG (KERN_WARNING "ERROR: Configuration error detected!");
    dump_pcie_vsec_state(dev);
    cvp_failed = 1;
    write_bit(dev, CVP_CFG_ERR_LATCH, 1); // write a 1 to clear the config space error bit
  } else {
    cvp_failed = 0;
  }

  write_bit(dev, CVP_MODE, 0);
  write_bit(dev, HIP_CLK_SEL, 0);
  
  if (!cvp_failed) {
    // wait for the Application Layer to be ready for normal operation
    if (!wait_for_bit (dev, PLD_CLK_IN_USE, 1)) {
      ACL_DEBUG (KERN_WARNING "Timed out waiting for PLD_CLK_IN_USE to become 1! CvP has failed");
      dump_pcie_vsec_state(dev);
      cvp_failed = 1;
    }
    if (!wait_for_bit (dev, USER_MODE, 1)) {
      ACL_DEBUG (KERN_WARNING "Timed out waiting for USER_MODE to become 1! CvP has failed");
      dump_pcie_vsec_state(dev);
      cvp_failed = 1;
    }    
    if (!cvp_failed) {
      ACL_DEBUG (KERN_DEBUG "SUCCESS: CvP has finished.");
      ACL_DEBUG (KERN_DEBUG " The Application Layer is ready for normal operation!");
      msleep (200);
      result = 0;
    } else {
      result = 1;
    }
  } else {
    result = 1;
  }
  
  aclpci->cvp_in_progress = 0;
  return result;
}

