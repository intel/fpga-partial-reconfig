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

/* Implementation of all I/O functions except DMA transfers.
 * See aclpci_dma.c for DMA code.
 */

#include <linux/jiffies.h>
#include <linux/sched.h>
#include <asm/io.h> // __raw_write, __raw_read
#include "aclpci.h"


static ssize_t aclpci_rw_large (void *dev_addr, void __user* use_addr, ssize_t len, char *buffer, int reading, int access_le);



/* Given (bar_id, device_addr) pair, make sure they're valid and return
 * the resulting address. errno will contain error code, if any. */
void* aclpci_get_checked_addr (int bar_id, void *device_addr, size_t count,
                               struct aclpci_dev *aclpci, ssize_t *errno,
                               int print_error_msg) {

  if (bar_id >= ACL_PCI_NUM_BARS) {
    ACL_DEBUG (KERN_WARNING "Requested read/write from BAR #%d. Only have %d BARs!",
               bar_id, ACL_PCI_NUM_BARS);
    *errno = -EFAULT;
    return 0;
  }
  /* Make sure the final address is within range */
  if ((count) > (unsigned long) aclpci->bar_length[bar_id]) {
    if (print_error_msg) {
      ACL_DEBUG (KERN_WARNING "Requested read/write from BAR #%d from range (0x%lx, 0x%lx). Length is %lu. BAR length is only %lu!",
                 bar_id, 
                 (unsigned long)device_addr,
                 (unsigned long)device_addr + count, 
                 count,
                 aclpci->bar_length[bar_id]);
    }
    *errno = -EFAULT;
    return 0;
  }

  *errno = 0;
  return (void*)(aclpci->bar[bar_id] + (unsigned long)device_addr);  
}


/* Compute address that contains memory window segment control */
static void *get_segment_ctrl_addr (struct aclpci_dev *aclpci) {

  void *dev_addr = 0;
  ssize_t errno = 0;
  void *ctrl_addr = (void*) (ssize_t)ACL_PCIE_MEMWINDOW_CRA;

  ACL_VERBOSE_DEBUG (KERN_DEBUG "get_segment_ctrl_addr ctrl_addr = %llx.", ctrl_addr);
  dev_addr = aclpci_get_checked_addr (ACL_PCIE_MEMWINDOW_BAR, ctrl_addr, sizeof(u64), aclpci, &errno, 1);
  if (errno != 0) {
    ACL_DEBUG (KERN_DEBUG "ERROR: ctrl_addr %p failed check", ctrl_addr);
    return NULL;
  }
  return dev_addr;
}


static void aclpci_set_segment_by_val (struct aclpci_dev *aclpci, u64 new_val) {

  void *ctrl_addr =  aclpci->global_mem_segment_addr;
  if (ctrl_addr == NULL) {
    return;
  }
  
  if (new_val != aclpci->global_mem_segment) {
    writeq (new_val, ctrl_addr);
    aclpci->global_mem_segment = new_val;
  }
  ACL_VERBOSE_DEBUG (KERN_DEBUG " Changed global memory segment to %llu.", new_val);
}


/* Response to user's open() call */
int aclpci_open(struct inode *inode, struct file *file) {

  struct aclpci_dev *aclpci = 0;
  int result = 0;
  /* pointer to containing data structure of the character device inode */
  aclpci = container_of(inode->i_cdev, struct aclpci_dev, cdev);
  
  if (down_interruptible(&aclpci->sem)) {
    return -ERESTARTSYS;
  }
  /* create a reference to our device state in the opened file */
  file->private_data = aclpci;
  ACL_DEBUG (KERN_DEBUG "aclpci = %p, pid = %d (%s)", 
             aclpci, current->pid, current->comm); 
  
  aclpci->user_pid = current->pid;
  aclpci->user_task = current;

  aclpci->global_mem_segment = 0;
  aclpci->saved_kernel_irq_mask = 0;
  aclpci->global_mem_segment_addr = get_segment_ctrl_addr(aclpci);
#if 0
  if (aclpci->user_pid == -1) {
    aclpci->user_pid = current->pid;
  } else {
    ACL_DEBUG (KERN_WARNING "Tried open() by pid %d. Already opened by %d", current->pid, aclpci->user_pid);
    result = -EFAULT;
    goto done;
  }
#endif
  ++aclpci->num_handles_open;
  
  if (aclpci->num_handles_open > 1) {
     /* Only perform the setup on the first open for this device */
     goto done;
  }

  if (init_irq (aclpci->pci_dev, aclpci)) {
    ACL_DEBUG (KERN_WARNING "Could not allocate IRQ!");
    result = -EFAULT;
    goto done;
  }

  load_signal_info (aclpci);
  #if !POLLING
    if (aclpci->user_task == NULL) {
      ACL_DEBUG (KERN_WARNING "Tried open() by pid %d but couldn't find associated task_info", current->pid);
      result = -EFAULT;
      goto done;
    }
  #endif
  
  result = 0;
  
done:
  up (&aclpci->sem);
  return result;
}


/* Response to user's close() call. Will also be called by the kernel
 * if the user process dies for any reason. */
int aclpci_close(struct inode *inode, struct file *file) {

  ssize_t result = 0;
  struct aclpci_dev *aclpci = (struct aclpci_dev *)file->private_data;
  ACL_DEBUG (KERN_DEBUG "aclpci = %p, pid = %d, dma_idle = %d",
             aclpci, current->pid, aclpci_dma_get_idle_status(aclpci)); 
  
  if (down_interruptible(&aclpci->sem)) {
    return -ERESTARTSYS;
  }

#if 0  
  if (aclpci->user_pid == current->pid) {
    aclpci->user_pid = -1;
  } else {
    ACL_DEBUG (KERN_WARNING "Tried close() by pid %d. Opened by %d", current->pid, aclpci->user_pid);
    result = -EFAULT;
    goto done;
  }
#endif
  --aclpci->num_handles_open;

  if (aclpci->num_handles_open == 0) {
    /* only when all handles are closed, do we perform the device finalization */
    release_irq (aclpci->pci_dev, aclpci);
  }

  atomic_set(&aclpci->status, 0);
  up (&aclpci->sem);
  return result;
}


/* Read a small number of bytes and put them into user space */
ssize_t aclpci_read_small (void *read_addr, void __user* dest_addr, ssize_t len, int access_le) {

  ssize_t copy_res = 0;
  switch (len) {
  case 1: {
    u8 d = readb ( read_addr );
    copy_res = copy_to_user ( dest_addr, &d, sizeof(d) );
    break;
  }
  case 2: {
    u16 d = access_le ? readw ( read_addr ) : __raw_readw ( read_addr );
    copy_res = copy_to_user ( dest_addr, &d, sizeof(d) );
    break;
  }
  case 4: {
    u32 d = access_le ? readl ( read_addr ) : __raw_readl ( read_addr );
    copy_res = copy_to_user ( dest_addr, &d, sizeof(d) );
    break;
  }
  case 8: {
    u32 ibuffer[2];
    if(access_le){
      ibuffer[0] = readl (((u32*)read_addr));
      ibuffer[1] = readl (((u32*)read_addr)+1);
    }else {
      ibuffer[0] = __raw_readl(((u32*)read_addr));
      mb();
      ibuffer[1] = __raw_readl(((u32*)read_addr)+1);
    }

    copy_res = copy_to_user ( dest_addr, ibuffer, sizeof(ibuffer) );
    break;
  }
  default:
    break;
  }
  
  if(!access_le){
    mb();
  }

  if (copy_res) {
    return -EFAULT;
  } else {
    return 0;
  }
}


/* Write a small number of bytes taken from user space */
ssize_t aclpci_write_small (void *write_addr, void __user* src_addr, ssize_t len, int access_le) {

  ssize_t copy_res = 0;
  switch (len) {
  case 1: {
    u8 d;
    copy_res = copy_from_user ( &d, src_addr, sizeof(d) );
    writeb ( d, write_addr );
    break;
  }
  case 2: {
    u16 d;
    copy_res = copy_from_user ( &d, src_addr, sizeof(d) );
    if(access_le){
      writew ( d, write_addr );
    } else {
      __raw_writew ( d, write_addr );
      mb();
    }
    break;
  }
  case 4: {
    u32 d;
    copy_res = copy_from_user ( &d, src_addr, sizeof(d) );
    if(access_le){
      writel ( d, write_addr );
    } else {
      __raw_writel ( d, write_addr );
      mb();
    }
    break;
  }
  case 8: {
    u32 ibuffer[2];
    copy_res = copy_from_user (ibuffer, src_addr, sizeof(ibuffer));
    if(access_le){
      writel ( ibuffer[0], (u32*)write_addr);
      writel ( ibuffer[1], ((u32*)write_addr) + 1 );
    }else {
      __raw_writel( ibuffer[0], (u32*)write_addr);
      mb();
      __raw_writel( ibuffer[1], ((u32*)write_addr) + 1 );
    }
    break;
  }
  default:
    break;
  }

  if (copy_res) {
    return -EFAULT;
  } else {
    return 0;
  }
}



/* Read or Write arbitrary length sequency starting at read_addr and put it into
 * user space at dest_addr. if 'reading' is set to 1, doing the read. If 0, doing
 * the write. */
static ssize_t aclpci_rw_large (void *dev_addr, void __user* user_addr,
                                  ssize_t len, char *buffer, int reading, int access_le) {
  size_t bytes_left = len;
  size_t i, num_missed;
  u32 *ibuffer = (u32*)buffer;
  char *cbuffer;
  size_t offset, num_to_read;
  size_t chunk = BUF_SIZE;
  
  u64 startj, ej;
  u64 sj = 0, acc_readj = 0, acc_transfj = 0;
  
  startj = get_jiffies_64();
  
  /* Reading upto BUF_SIZE values, one int at a time, and then transfer
   * the buffer at once to user space. Repeat as necessary. */
  while (bytes_left > 0) {
    if (bytes_left < BUF_SIZE) {
      chunk = bytes_left;
    } else {
      chunk = BUF_SIZE;
    }
    
    if (!reading) {
      sj = get_jiffies_64();
      if (copy_from_user (ibuffer, user_addr, chunk)) {
        return -EFAULT;
      }
      acc_transfj += get_jiffies_64() - sj;
    }

    /* Read one u32 at a time until fill the buffer. Then copy the whole
     * buffer at once to user space. */
    sj = get_jiffies_64();
    num_to_read = chunk / sizeof(u32);
    for (i = 0; i < num_to_read; i++) {
      if (reading) {
        if(access_le){
          ibuffer[i] = readl (((u32*)dev_addr) + i);
        }else {
          ibuffer[i] = __raw_readl(((u32*)dev_addr) + i);
          mb();
        }
      } else {
        if(access_le){
          writel ( ibuffer[i], ((u32*)dev_addr) + i );
        }else {
          __raw_writel( ibuffer[i], ((u32*)dev_addr) + i );
          mb();
        }
      }
    }
    
    /* If length is not a multiple of sizeof(u32), will miss last few bytes.
     * In that case, read it one byte at a time. This can only happen on 
     * last iteration of the while() loop. */
    offset = num_to_read * sizeof(u32);
    num_missed = chunk - offset;
    cbuffer = (char*)(ibuffer + num_to_read);
    
    for (i = 0; i < num_missed; i++) {
      if (reading) {
        cbuffer[i] = readb ( (u8*)(dev_addr) + offset + i );
      } else {
        writeb ( cbuffer[i], (u8*)(dev_addr) + offset + i );
      }
    }
    acc_readj += get_jiffies_64() - sj;
    
    if (reading) {
      sj = get_jiffies_64();
      if (copy_to_user (user_addr, ibuffer, chunk)) {
        return -EFAULT;
      }
      acc_transfj += get_jiffies_64() - sj;
    }
    
    dev_addr += chunk;
    user_addr += chunk;
    bytes_left -= chunk;
  }
  
  ej = get_jiffies_64();
  ACL_VERBOSE_DEBUG (KERN_DEBUG "Spent %u msec %sing %lu bytes", jiffies_to_msecs(ej - startj), 
                          reading ? "read" : "writ", len);
  ACL_VERBOSE_DEBUG (KERN_DEBUG "  Dev access %u msec. User space transfer %u msec",
                        jiffies_to_msecs(acc_readj),
                        jiffies_to_msecs(acc_transfj));
  return 0;
}

/* Set CRA window so raw_user_ptr is "visible" to the BAR.
 * Return pointer to use to access the user memory */
static void* aclpci_set_segment (struct aclpci_dev *aclpci, void * raw_user_ptr) {

  //ssize_t cur_segment = ((ssize_t)raw_user_ptr) / ACL_PCIE_MEMWINDOW_SIZE;  
  ssize_t cur_segment = ((ssize_t)raw_user_ptr) & ((size_t)1 - (ACL_PCIE_MEMWINDOW_SIZE-1));
  aclpci_set_segment_by_val (aclpci, cur_segment);  

  /* Can use the return value in all read/write functions in this file now */
  return (void*)((ssize_t)ACL_PCIE_MEMWINDOW_BASE + ((ssize_t)raw_user_ptr % ACL_PCIE_MEMWINDOW_SIZE));
}


/* Both start and end, user and device addresses must be 
 * 64-byte aligned to use DMA */
int aligned_request (struct acl_cmd *cmd, size_t count) {
  
  return (( (unsigned long)cmd->user_addr   & DMA_ALIGNMENT_BYTE_MASK) | 
          ( (unsigned long)cmd->device_addr & DMA_ALIGNMENT_BYTE_MASK) |
          ( count                           & DMA_ALIGNMENT_BYTE_MASK)
         ) == 0;
}                           


/* High-level read/write dispatcher. */
ssize_t aclpci_rw(struct file *file, char __user *buf, 
                  size_t count, loff_t *pos,
                  int reading) {
  
  struct aclpci_dev *aclpci = (struct aclpci_dev *)file->private_data;
  struct acl_cmd __user *ucmd;
  struct acl_cmd kcmd;
  u64 old_segment = 0;
  int restore_segment = 0;
  void *addr = 0;
  int access_le = 0;
  int aligned = 0;
  int use_dma = 0;
  ssize_t result = 0;
  ssize_t errno = 0;
  size_t size = 0;

  if (down_interruptible(&aclpci->sem)) {
    return -ERESTARTSYS;
  }
  
  /* For now we will support the case where processes can all open/close the device
   * but there is only a single process performing an operation per device 
   * Here we record the the task that is performing the operation. It is the one who will receive the signals back.
   */
  aclpci->user_task = current; 

  ucmd = (struct acl_cmd __user *) buf;
  if (copy_from_user (&kcmd, ucmd, sizeof(*ucmd))) {
		result = -EFAULT;
    goto done;
	}

  size = kcmd.size;
  if (kcmd.bar_id == ACLPCI_CMD_BAR) {
    /* This is not a read but a special command. */
    result = aclpci_exec_cmd (aclpci, kcmd, size);
    goto done;
  }

  /* If access_le is true, it explicitly shows that we want to interpret the target memory as 
   * little-endian. Otherwise, the same endianess as the host will be used. 
   */
  access_le = !kcmd.is_diff_endian;
  
  /* Only using DMA for large aligned reads/writes on global memory
   * (due to some assumptions inside the DMA hardware). */
  aligned = aligned_request (&kcmd, size);
  use_dma = USE_DMA && (size >= 1024) && 
            aligned && kcmd.bar_id == ACLPCI_DMA_BAR;
  ACL_VERBOSE_DEBUG (KERN_DEBUG "\n\n-----------------------");
  ACL_VERBOSE_DEBUG (KERN_DEBUG " kcmd = {%u, %p, %p}, count = %lu", 
             kcmd.bar_id, (void*)kcmd.device_addr, (void*)kcmd.user_addr, size);

  if (!use_dma) {
    /* Do bounds checking on addresses, for DMA we don't know memory size */
    if (kcmd.bar_id != ACLPCI_DMA_BAR) {
      addr = aclpci_get_checked_addr (kcmd.bar_id, kcmd.device_addr, size, aclpci, &errno, 0);
    }
    else {
      /* If not using DMA, but command specifies addresses in DMA's address
       * space, we need to translate these to accesses to the memwindow.  The
       * user-space written HAL currently also does this so we need to restore
       * the current segment in hardware. */

      ACL_VERBOSE_DEBUG (KERN_DEBUG "For global memory accesses, trying to change segment so the address is mapped into PCIe BAR");
      old_segment = aclpci->global_mem_segment;
      restore_segment = 1;
      kcmd.bar_id = ACL_PCIE_MEMWINDOW_BAR;
      kcmd.device_addr = aclpci_set_segment (aclpci, kcmd.device_addr);
      addr = aclpci_get_checked_addr (kcmd.bar_id, kcmd.device_addr, size, aclpci, &errno, 1);
    }

    if (errno != 0) {
      result = -EFAULT;
      goto done;
    }
  }


  /* Intercept global mem segment changes to keep internal structures up-to-date */
  if (kcmd.bar_id == ACL_PCIE_MEMWINDOW_BAR) {
    if (addr == aclpci->global_mem_segment_addr && reading == 0) {
      u64 d;
      if (copy_from_user ( &d, kcmd.user_addr, sizeof(d) )) {
        result = -EFAULT;
        goto done;
      }
      ACL_VERBOSE_DEBUG (KERN_DEBUG "Intercepted mem segment change to %llu", d);
      aclpci->global_mem_segment = d;
    }
  }
  
  
  /* Offset value is always an address offset, not element offset. */
  /* ACL_DEBUG (KERN_DEBUG "Read address is %p", addr); */
  
  switch (size) {
  case 1:
  case 2:
  case 4:
  case 8: {
    if (reading) {
      result = aclpci_read_small  (addr, (void __user*) kcmd.user_addr, size, access_le);
    } else {
      result = aclpci_write_small (addr, (void __user*) kcmd.user_addr, size, access_le);
    }
    break;
  }
    
  default:
    if (use_dma) {
      result = aclpci_dma_rw (aclpci, kcmd.device_addr, (void __user*) kcmd.user_addr, size, reading);
    } else {
      result = aclpci_rw_large (addr, (void __user*) kcmd.user_addr, size, aclpci->buffer, reading, access_le );
    }
    break;
  }
  
  /* If had to change the segment to get this read through, restore the value */
  if (restore_segment) {
    ACL_VERBOSE_DEBUG (KERN_DEBUG "Restoring mem segment to %llu", old_segment);
    aclpci_set_segment_by_val (aclpci, old_segment);
  }
  
done:
  up (&aclpci->sem);
  return result;
}


/* Response to user's read() call */
ssize_t aclpci_read(struct file *file, char __user *buf, 
                    size_t count, loff_t *pos) {
  return aclpci_rw (file, buf, count, pos, 1 /* reading */);
}


/* Response to user's write() call */
ssize_t aclpci_write(struct file *file, const char __user *buf, 
                     size_t count, loff_t *pos) {
  return aclpci_rw (file, (char __user *)buf, count, pos, 0 /* writing */);
}

