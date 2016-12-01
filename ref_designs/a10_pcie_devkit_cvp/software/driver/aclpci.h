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

/* Global declarations shared by all files of this driver. */

#ifndef ACLPCI_H
#define ACLPCI_H


#include <linux/kobject.h>
#include <linux/kdev_t.h>
#include <linux/list.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/delay.h>
#include <linux/dma-mapping.h>
#include <linux/delay.h>
#include <linux/init.h>
#include <linux/interrupt.h>
#include <linux/io.h>
#include <linux/jiffies.h>
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/uaccess.h>
#include <linux/sched.h>


/* includes from opencl/include/pcie */
#include "hw_pcie_constants.h"
#include "pcie_linux_driver_exports.h"

/* Local includes */
#include "version.h"


/* Use Message Signalled Interrupt (MSI).
 * If not used will get many visibly-distinct interrupts for a single
 * logical one (because it takes a while to reset the interrupt in the FPGA).
 * MSIs are faster. HOWEVER, currently seem to loose MSIs once in a while. :( */
#define USE_MSI           1

#define USE_DMA           1

#include "aclpci_dma.h"


#define DRIVER_NAME       "altr_aclpci_cvp_drv"
#define BOARD_NAME        "acl" ACL_BOARD_PKG_NAME

#define ACLPCI_MAX_MINORS 16

/* Set to 1 to use Polling (instead of interrupts) to communicate
 * with hal. HAL must be compiled in the same mode */
#define POLLING           0


/* Debugging defines */
#define VERBOSE_DEBUG     0 
#define ACL_DEBUG(...)					\
  do {						\
    printk("%s (%d): ", __func__, __LINE__);	\
    printk(__VA_ARGS__);			\
    printk("\n");				\
  } while (0)
  
#if VERBOSE_DEBUG
# define ACL_VERBOSE_DEBUG(...) ACL_DEBUG(__VA_ARGS__)
#else 
# define ACL_VERBOSE_DEBUG(...)
#endif

/* Don't actually bring down the kernel on an error condition */
#define assert(expr) \
do { \
   if (!(expr)) { \
      printk(KERN_ERR "Assertion failed! %s, %s, %s, line %d\n", \
            #expr, __FILE__, __func__, __LINE__); \
   } \
} while (0)



/* Maximum size of driver buffer (allocated with kalloc()).
 * Needed to copy data from user to kernel space, among other
 * things. */
static const size_t BUF_SIZE = PAGE_SIZE;


/* Device data used by this driver. */
struct aclpci_dev {
  /* the kernel pci device data structure */
  struct pci_dev *pci_dev;
  
  /* upstream root node */
  struct pci_dev *upstream;
  
  /* kernels virtual addr. for the mapped BARs */
  void * __iomem bar[ACL_PCI_NUM_BARS];
  
  /* length of each memory region. Used for error checking. */
  size_t bar_length[ACL_PCI_NUM_BARS];
  
  /* Controls which section of board's DDR maps to BAR */
  u64 global_mem_segment;
  
  /* Kernel irq - mustn't assume it's safe to enable kernel irq */
  char saved_kernel_irq_mask;
  
  /* Location of global_mem_segment value on the board. */
  void *global_mem_segment_addr;
  
  /* temporary buffer. If allocated, will be BUF_SIZE. */
  char *buffer;
  
  /* Mutex for this device. */
  struct semaphore sem;
  
  /* PID of process that called open() */
  int user_pid;
  /* Number of handles referencing this device */
  int num_handles_open;
 
  /* character device */
  dev_t cdev_num;
  struct cdev cdev;
  struct class *my_class;
  struct device *device;


  /* signal sending structs */
  struct siginfo signal_info;
  struct siginfo signal_info_dma;
  struct task_struct *user_task;
  int user_filehandle;

  /* 1 if doing core reconfig via PCIe. 
   * Ignore all interrupts when this is going on. */
  int pr_in_progress;
  
  /* State of uncorrectable error mask register, AER ext capability.
   * Saved during reprogramming */
  u32 aer_uerr_mask_reg;
  
  /* All the DMA data */
  struct aclpci_dma dma_data;
  
  /* Debug data */  
  /* number of hw interrupts handled. */
  size_t num_handled_interrupts;
  size_t num_undelivered_signals;
  int pci_gen;
  int pci_num_lanes;
  
  /* PCI dma table and msi controls */
  u8 revision;
  u8 irq_pin;
  u8 irq_line;

  wait_queue_head_t wait_q;
  atomic_t status;

};


/* aclpci_fileio.c funciton */
int aclpci_open(struct inode *inode, struct file *file);
int aclpci_close(struct inode *inode, struct file *file);
ssize_t aclpci_read(struct file *file, char __user *buf, size_t count, loff_t *pos);
ssize_t aclpci_write(struct file *file, const char __user *buf, size_t count, loff_t *pos);
void* aclpci_get_checked_addr (int bar_id, void *device_addr, size_t count,
                               struct aclpci_dev *aclpci, ssize_t *errno, int print_error_msg);

/* aclpci.c functions */
void load_signal_info (struct aclpci_dev *aclpci);
int init_irq (struct pci_dev *dev, void *dev_id);
void release_irq (struct pci_dev *dev, void *aclpci);
void unmask_kernel_irq(struct aclpci_dev *aclpci);
void mask_kernel_irq(struct aclpci_dev *aclpci);

/* aclpci_dma.c functions */
void aclpci_dma_init(struct aclpci_dev *aclpci);
void aclpci_dma_finish(struct aclpci_dev *aclpci);
void aclpci_dma_stop(struct aclpci_dev *aclpci);
int aclpci_dma_get_idle_status(struct aclpci_dev *aclpci);
ssize_t aclpci_dma_rw (struct aclpci_dev *aclpci, void *dev_addr, void __user* use_addr, ssize_t len, int reading);
irqreturn_t aclpci_dma_service_interrupt (struct aclpci_dev *aclpci);

/* aclpci_cmd.c functions */
void retrain_gen2 (struct aclpci_dev *aclpci);
ssize_t aclpci_exec_cmd (struct aclpci_dev *aclpci, struct acl_cmd kcmd, size_t count);
int aclpci_get_user_pages(struct task_struct *target_task, unsigned long start_page, size_t num_pages, struct page **p);
void aclpci_release_user_pages(struct task_struct *target_task, struct page **p, size_t num_pages);

/* aclpci_pr.c functions */
int aclpci_pr (struct aclpci_dev *aclpci, void __user* core_bitstream, ssize_t len);

#endif /* ACLPCI_H */
