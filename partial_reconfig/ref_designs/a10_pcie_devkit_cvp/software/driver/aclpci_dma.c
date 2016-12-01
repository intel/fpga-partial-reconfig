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

/* DMA logic imlementation.
 *
 * The basic flow of DMA transfer is as follows:
 *  1. Pin user memory (a contiguous set of address in processor address space)
 *     to get a list of physical pages (almost never contiguous list of 4KB
 *     blocks).
 *  2. Setup descriptor table entries. The table has 128 entries, each entry has 
 *     64 bit dma host address, 64 bit device address, size of transfer in dwords
 *     and the id number of the transfer.
 *  3. Send address descriptor table dma host address, device descriptor table
 *     FIFO address, size of the descriptor table and last transfer id to DMA
 *     controller
 *  4. Go to step 2 if have not transfered all currently pinned memory yet.
 *  5. Go to step 1 if need to pin more memory.
 *
 * DMA controller writes back the last transfer id status bit of the descriptor table 
 * back into the host memory. At the same time, it signals an MSI interrupt
 *
 * Due to hardware restrictions, DMA can only do minimum transfer of 32-bits.
 * The DMA driver logic assumed that MMD will not ask for transfers not divisible by 4
 */


#include <linux/mm.h>
#include <linux/scatterlist.h>
#include <linux/sched.h>
#include <asm/page.h>
#include <linux/spinlock.h>
#include <linux/jiffies.h>
#include <linux/version.h>
#include <linux/dma-mapping.h>
#include <linux/time.h>
#include <linux/delay.h>

#include "aclpci.h"


#include <linux/mm.h>
#include <asm/siginfo.h>    //siginfo

#if USE_DMA

/* Map/Unmap pages for DMA transfer.
 * All docs say I need to do it but unmapping pages after
 * reading clears their content. */

#ifdef ACL_BIG_ENDIAN
#  define MAP_UNMAP_PAGES 1
#else
#  define MAP_UNMAP_PAGES 0
#endif

#define DEBUG_UNLOCK_PAGES 0

#if LINUX_VERSION_CODE < KERNEL_VERSION(2, 6, 20)
void wq_func_dma_update(void *data);
#else
void wq_func_dma_update(struct work_struct *pwork);
#endif

/* Forward declarations */
static int set_desc_table_header(struct dma_desc_header *header);
int read_write (struct aclpci_dev* aclpci, void* src, void *dst, size_t bytes, int reading);
void unlock_dma_buffer (struct aclpci_dev *aclpci, struct dma_t *dma);
void unlock_all_dma (struct aclpci_dev *aclpci);


void *get_dma_desc_offset(struct aclpci_dev *aclpci) {
  return aclpci->bar[ACL_PCIE_DMA_INTERNAL_BAR]+ACL_PCIE_DMA_INTERNAL_CTR_BASE; 
}


int is_idle (struct aclpci_dev *aclpci) {
  struct aclpci_dma *d = &(aclpci->dma_data);
  return d->m_idle;
}


/* Add a byte-offset to a void* pointer */
void* compute_address (void* base, unsigned long offset)
{
   unsigned long p = (unsigned long)(base);
   return (void*)(p + offset);
}


/* Init DMA engine. Should be done at device load time */
void aclpci_dma_init(struct aclpci_dev *aclpci) {

  struct aclpci_dma *d = &(aclpci->dma_data);
  memset( &d->m_active_mem, 0, sizeof(struct pinned_mem) );
  d->m_idle=1;
  
  d->m_aclpci = aclpci;
  d->m_pci_dev = aclpci->pci_dev;
  
  // create a workqueue with a single thread and a work structure
  d->my_wq   = create_singlethread_workqueue("aclkmdq");
  d->my_work = (struct work_struct_t*) kmalloc(sizeof(struct work_struct_t), GFP_KERNEL);
  if(d->my_work) {
    d->my_work->data = (void *)aclpci;
#if LINUX_VERSION_CODE < KERNEL_VERSION(2, 6, 20)
    INIT_WORK( &d->my_work->work, wq_func_dma_update, (void *)d->my_work->data); 
#else
    INIT_WORK( &d->my_work->work, wq_func_dma_update);
#endif
  }
}


void aclpci_dma_finish(struct aclpci_dev *aclpci) {
  
  struct aclpci_dma *d = &(aclpci->dma_data);
  
  d->dma_wr_last_id = ACL_PCIE_DMA_RESET_ID;
  d->dma_rd_last_id = ACL_PCIE_DMA_RESET_ID;
  
  unlock_all_dma(aclpci);
  
  flush_workqueue(d->my_wq);
  destroy_workqueue(d->my_wq);
  kfree(d->my_work);
  d->m_idle = 1;

}

void aclpci_dma_stop(struct aclpci_dev *aclpci) {

  struct aclpci_dma *d = &(aclpci->dma_data);
  
  d->dma_wr_last_id = ACL_PCIE_DMA_RESET_ID;
  d->dma_rd_last_id = ACL_PCIE_DMA_RESET_ID;
  
  unlock_all_dma(aclpci);
  
  /* Flush any pending work on the workqueue */
  flush_workqueue(d->my_wq);
  d->m_idle = 1;
}


/* Called by main interrupt handler in aclpci.c. By the time we get here,
 * we know it's a DMA interrupt. So only need to do DMA-related stuff. */
irqreturn_t aclpci_dma_service_interrupt (struct aclpci_dev *aclpci)
{
  // Keep this to not affect aclpci.c.
  // Add in code here for MSI
  struct aclpci_dma *d = &(aclpci->dma_data);
  struct timeval us_end_time;
  long int seconds, useconds;
  int reading = d->m_read;
  
  if (reading) {
    set_desc_table_header(&d->desc_table_wr_cpu_virt_addr->header);
  } else {
    set_desc_table_header(&d->desc_table_rd_cpu_virt_addr->header);
  }
  
  if (d->m_us_valid == 1) {
    d->m_us_valid = 0;
    do_gettimeofday(&us_end_time);
    seconds = us_end_time.tv_sec - d->m_us_dma_start_time.tv_sec;
    useconds = us_end_time.tv_usec - d->m_us_dma_start_time.tv_usec;
    ACL_VERBOSE_DEBUG (KERN_DEBUG "Last table transfer measured %06ld usec :: check seconds %ld should be zero", useconds, seconds);
  }
  
  queue_work(d->my_wq, &d->my_work->work);
  
  return IRQ_HANDLED;
}


/* Read/Write large amounts of data using DMA.
 *   dev_addr  -- address on device to read to/write from
 *   dest_addr -- address in user space to read to/write from
 *   len       -- number of bytes to transfer
 *   reading   -- 1 if doing read (from device), 0 if doing write (to device)
 */
ssize_t aclpci_dma_rw (struct aclpci_dev *aclpci,
                       void *dev_addr, void __user* user_addr, 
                       ssize_t len, int reading) {

  ACL_VERBOSE_DEBUG (KERN_DEBUG "DMA: %sing %lu bytes", reading ? "Read" : "Writ", len);
  if (reading) {
    read_write (aclpci, dev_addr,  user_addr, len, reading);
  } else {
    read_write (aclpci, user_addr,  dev_addr, len, reading);
  }
  
  return 0;
}


/* Return idle status of the DMA hardware. */
int aclpci_dma_get_idle_status(struct aclpci_dev *aclpci) {
  return aclpci->dma_data.m_idle;
}


int lock_dma_buffer (struct aclpci_dev *aclpci, void *addr, ssize_t len, struct pinned_mem *active_mem) {

  int ret;
  unsigned int num_act_pages;
  struct aclpci_dma *d = &(aclpci->dma_data);
  ssize_t start_page, end_page, num_pages;
  u64 ej, startj = get_jiffies_64();
  struct dma_t *dma = &(active_mem->dma);
  
  #if MAP_UNMAP_PAGES
  unsigned int i;  
  dma_addr_t phys;
  #endif

  dma->ptr = addr;
  dma->len = len;
  dma->dir = d->m_read ? PCI_DMA_FROMDEVICE : PCI_DMA_TODEVICE;
  /* num_pages that [addr, addr+len] map to. */
  start_page = (ssize_t)addr >> PAGE_SHIFT;
  end_page = ((ssize_t)addr + len - 1) >> PAGE_SHIFT;
  num_pages = end_page - start_page + 1;
  
  dma->num_pages = num_pages;
  dma->pages = (struct page**)kzalloc ( sizeof(struct page*) * dma->num_pages, GFP_KERNEL );
  if (dma->pages == NULL) {
    ACL_DEBUG (KERN_WARNING "Couldn't allocate array of %u ptrs!", dma->num_pages);
    return -EFAULT;
  }
  
  dma->dma_addrs = (dma_addr_t*)kzalloc ( sizeof(dma_addr_t) * dma->num_pages, GFP_KERNEL );
  if (dma->dma_addrs == NULL) {
    ACL_DEBUG (KERN_WARNING "Couldn't allocate array of %u dma_addr_t's!", dma->num_pages);
    return -EFAULT;
  }
  ACL_VERBOSE_DEBUG (KERN_DEBUG "pages = [%p, %p), dma_addrs = [%p, %p)", 
                     dma->pages, dma->pages+num_pages, dma->dma_addrs, dma->dma_addrs+num_pages);
  
  /* pin user memory and get set of physical pages back in 'p' ptr. */
  ret = aclpci_get_user_pages(aclpci->user_task, (unsigned long)addr & PAGE_MASK, num_pages, dma->pages);
  if (ret != 0) {
    ACL_DEBUG (KERN_WARNING "Couldn't pin all user pages. %d!\n", ret);
    return -EFAULT;
  }
  
  
  /* map pages for PCI access. */
  num_act_pages = 0;
  #if MAP_UNMAP_PAGES

  for (i = 0; i < dma->num_pages; i++) {
    struct page *cur = dma->pages[i];
    // ACL_DEBUG (KERN_DEBUG "p[%d] = 0x%p", i, cur);
    if (cur != NULL) {
      // ACL_DEBUG (KERN_DEBUG "  phys_addr = 0x%llx", page_to_phys(cur));
      phys = pci_map_page (d->m_pci_dev, cur, 0, PAGE_SIZE, dma->dir);
      if (phys == 0) {
        ACL_DEBUG (KERN_DEBUG "  Couldn't pci_map_page!");
        return -EFAULT;
      }
      dma->dma_addrs[i] = phys;
      num_act_pages++;
    }
  }
  #endif

  active_mem->pages_rem = dma->num_pages;
  active_mem->next_page = dma->pages;
  active_mem->next_dma_addr = dma->dma_addrs;
  active_mem->first_page_offset = (unsigned long)addr & (PAGE_SIZE - 1);
  active_mem->last_page_offset = (unsigned long)(addr + len) & (PAGE_SIZE - 1);
  
  //ACL_DEBUG (KERN_DEBUG  "Content of first page (addr  = %p): %s", 
  //             page_to_phys(dma->pages[0]), (char*)phys_to_virt(page_to_phys(dma->pages[0])));
  ej = get_jiffies_64();
  
  ACL_VERBOSE_DEBUG (KERN_DEBUG  "DMA: Pinned %u bytes (%lu pages) at 0x%p in %u usec", 
      (unsigned int)len, num_pages, addr, jiffies_to_usecs(ej - startj));
  ACL_VERBOSE_DEBUG (KERN_DEBUG  "DMA: first page offset is %u, last page offset is %u", 
         active_mem->first_page_offset, active_mem->last_page_offset);
         
  d->m_pin_time += (ej - startj);
  d->m_lock_time += (ej - startj);
  return 0;
}


void unlock_dma_buffer (struct aclpci_dev *aclpci, struct dma_t *dma) {

  struct aclpci_dma *d = &(aclpci->dma_data);
  u64 ej, startj = get_jiffies_64();
  
  #if DEBUG_UNLOCK_PAGES
  char *s = (char*)phys_to_virt(page_to_phys(dma->pages[0]));
  
  ACL_DEBUG (KERN_DEBUG  "1. Content of first page (addr  = %p): %s", 
               page_to_phys(dma->pages[0]), s);
  #endif
  
  #if MAP_UNMAP_PAGES
  int i;
  /* Unmap pages to make the data available for CPU */      
  for (i = 0; i < dma->num_pages; i++) {
    struct page *cur = dma->pages[i];
    // ACL_DEBUG (KERN_DEBUG "p[%d] = %p", i, cur);
    if (cur != NULL) {
      dma_addr_t phys = dma->dma_addrs[i];
      pci_unmap_page (d->m_pci_dev, phys, PAGE_SIZE, dma->dir);
    }
  }
  #endif
  
  // TODO: If do map/unmap for reads, the data is 0 by now!!!!
  #if DEBUG_UNLOCK_PAGES
    ACL_DEBUG (KERN_DEBUG  "2. Content of first page: %s", s);
  #endif

  /* Unpin pages */
  aclpci_release_user_pages (aclpci->user_task, dma->pages, dma->num_pages);
    
  /* TODO: try to re-use these buffers on future allocs */
  kfree (dma->pages);
  kfree (dma->dma_addrs);

  ej = get_jiffies_64();
  ACL_VERBOSE_DEBUG (KERN_DEBUG  "DMA: Unpinned %u pages in %u usec", 
                          dma->num_pages,
                          jiffies_to_usecs(ej - startj));
                          
  /* Reset all dma fields. */
  memset (dma, 0, sizeof(struct dma_t));
  
  d->m_pin_time += (ej - startj);
  d->m_unlock_time += (ej - startj);
}

void unlock_all_dma(struct aclpci_dev *aclpci)
{
  struct aclpci_dma *d = &(aclpci->dma_data);
  struct dma_t *dma = &(d->m_active_mem.dma);
  
  if (d->m_active_mem.dma.ptr != NULL) {
    unlock_dma_buffer (aclpci, dma);
  }
  dma = &(d->m_pre_pinned_mem.dma);
  if (d->m_pre_pinned_mem.dma.ptr != NULL) {
    unlock_dma_buffer (aclpci, dma);
  }
  dma = &(d->m_done_mem.dma);
  if (d->m_done_mem.dma.ptr != NULL) {
    unlock_dma_buffer (aclpci, dma);
  }
  
}


static int set_write_desc(struct dma_desc_entry *wr_desc, u64 source, dma_addr_t dest, u32 ctl_dma_len, u32 id)
{
    wr_desc->src_addr_ldw = cpu_to_le32(source & 0xffffffffUL);
    wr_desc->src_addr_udw = cpu_to_le32((source >> 32));
    wr_desc->dest_addr_ldw = cpu_to_le32(dest & 0xffffffffUL);
    wr_desc->dest_addr_udw = cpu_to_le32((dest >> 32));
    wr_desc->ctl_dma_len = cpu_to_le32(ctl_dma_len | (id << 18));
    wr_desc->reserved[0] = cpu_to_le32(0x0);
    wr_desc->reserved[1] = cpu_to_le32(0x0);
    wr_desc->reserved[2] = cpu_to_le32(0x0);
    return 0;
}

static int set_read_desc(struct dma_desc_entry *rd_desc, dma_addr_t source, u64 dest, u32 ctl_dma_len, u32 id)
{
    rd_desc->src_addr_ldw = cpu_to_le32(source & 0xffffffffUL);
    rd_desc->src_addr_udw = cpu_to_le32((source >> 32));
    rd_desc->dest_addr_ldw = cpu_to_le32(dest & 0xffffffffUL);
    rd_desc->dest_addr_udw = cpu_to_le32((dest >> 32));
    rd_desc->ctl_dma_len = cpu_to_le32(ctl_dma_len | (id << 18));
    rd_desc->reserved[0] = cpu_to_le32(0x0);
    rd_desc->reserved[1] = cpu_to_le32(0x0);
    rd_desc->reserved[2] = cpu_to_le32(0x0);
    return 0;
}

static int set_desc_table_header(struct dma_desc_header *header)
{
    int i;
    for (i = 0; i < 128; i++)
        header->flags[i] = cpu_to_le32(0x0); 
    return 0;
}

void send_dma_desc(struct aclpci_dev *aclpci, int reading, int first, int last_id)
{
  struct aclpci_dma *d = &(aclpci->dma_data);
  void *dma_desc_base = get_dma_desc_offset(aclpci);
  // TODO: int first is from get_start_id function. Right now always set to 0.
  // When the last pointer loops back to 0, we don't have to write the FIFO address for some reason
  ACL_VERBOSE_DEBUG (KERN_DEBUG "Set desc table\n");
  if (reading) {
    iowrite32 ((dma_addr_t)d->desc_table_wr_bus_addr, dma_desc_base+ACL_PCIE_DMA_RC_WR_DESC_BASE_LOW);
    iowrite32 (((dma_addr_t)d->desc_table_wr_bus_addr)>>32, dma_desc_base+ACL_PCIE_DMA_RC_WR_DESC_BASE_HIGH);
    if (first == 0) {
      ACL_VERBOSE_DEBUG (KERN_DEBUG "Set EP registers\n");
      wmb();
      iowrite32 (ACL_PCIE_DMA_ONCHIP_WR_FIFO_BASE_LO, dma_desc_base+ACL_PCIE_DMA_EP_WR_FIFO_BASE_LOW);
      iowrite32 (ACL_PCIE_DMA_ONCHIP_WR_FIFO_BASE_HI, dma_desc_base+ACL_PCIE_DMA_EP_WR_FIFO_BASE_HIGH);
      iowrite32 (ACL_PCIE_DMA_TABLE_SIZE-1, dma_desc_base+ACL_PCIE_DMA_WR_TABLE_SIZE);
      // Add this for debug. Setting DMA control register to 1 makes it write 1 to all dma table status entry
      // iowrite32 (1, dma_desc_base+ACL_PCIE_DMA_WR_CONTROL);
    }
    wmb();
    d->dma_wr_last_id = last_id;
    iowrite32 (last_id, dma_desc_base+ACL_PCIE_DMA_WR_LAST_PTR);
  } else {
    iowrite32 ((dma_addr_t)d->desc_table_rd_bus_addr, dma_desc_base+ACL_PCIE_DMA_RC_RD_DESC_BASE_LOW);
    iowrite32 (((dma_addr_t)d->desc_table_rd_bus_addr)>>32, dma_desc_base+ACL_PCIE_DMA_RC_RD_DESC_BASE_HIGH);
    if (first == 0) {
      ACL_VERBOSE_DEBUG (KERN_DEBUG "Set EP registers\n");
      wmb();
      iowrite32 (ACL_PCIE_DMA_ONCHIP_RD_FIFO_BASE_LO, dma_desc_base+ACL_PCIE_DMA_EP_RD_FIFO_BASE_LOW);
      iowrite32 (ACL_PCIE_DMA_ONCHIP_RD_FIFO_BASE_HI, dma_desc_base+ACL_PCIE_DMA_EP_RD_FIFO_BASE_HIGH);
      iowrite32 (ACL_PCIE_DMA_TABLE_SIZE-1, dma_desc_base+ACL_PCIE_DMA_RD_TABLE_SIZE);
      // Add this for debug. Setting DMA control register to 1 makes it write 1 to all dma table status entry
      //iowrite32 (1, dma_desc_base+ACL_PCIE_DMA_RD_CONTROL);
    }
    wmb();
    d->dma_rd_last_id = last_id;
    iowrite32 (last_id, dma_desc_base+ACL_PCIE_DMA_RD_LAST_PTR);
  }
}

int get_start_id (struct aclpci_dev *aclpci, int reading, int *start_id, int *first) {
  struct aclpci_dma *d = &(aclpci->dma_data);
  int check_last_id;
  
  if (reading) {
    check_last_id = d->dma_wr_last_id;
    set_desc_table_header(&d->desc_table_wr_cpu_virt_addr->header);
  } else {
    check_last_id = d->dma_rd_last_id;
    set_desc_table_header(&d->desc_table_rd_cpu_virt_addr->header);
  }
  ACL_VERBOSE_DEBUG (KERN_DEBUG "check_last_id = %i", check_last_id);
  
  // TODO: first can be changed to 1 for check_last_id==ACL_PCIE_DMA_TABLE_SIZE - 1 to optimize DMA behaviour
  //       Safer to leave it at 0 for now though.
  if (check_last_id == ACL_PCIE_DMA_RESET_ID) {
    *start_id = 0;
    *first = 0;
  } else if (check_last_id == ACL_PCIE_DMA_TABLE_SIZE - 1) {
    *start_id = 0;
    *first = 0;
  } else if (check_last_id < ACL_PCIE_DMA_TABLE_SIZE - 1) {
    *start_id = check_last_id + 1;
    *first = 0;
  } else {
    ACL_DEBUG (KERN_WARNING "WARNING :: Unrecognized last id %i", check_last_id);
    return 1;
  }
  return 0;
}

int non_aligned_page_handler
(
  struct aclpci_dev *aclpci,
  dma_addr_t pcie_addr,
  u64 qsys_addr,
  size_t bytes,
  int reading
)
{
  struct aclpci_dma *d = &(aclpci->dma_data);
  struct page *next_page;
  size_t transfer_bytes_w, remaining, temp, transfer_bytes, transferred, transfer_words;
  int result, i, last_id, max_transfer, start_id, first;
  
  if (bytes >= PAGE_SIZE) {
    ACL_DEBUG(KERN_WARNING "WARNING :: non aligned handler asked to transfer %u bytes. Max is %u", (unsigned int) bytes, (unsigned int) PAGE_SIZE);
    return 1;
  }
  
  remaining = bytes;
  last_id = ACL_PCIE_DMA_RESET_ID;

  first = 0;
  
  result = get_start_id(aclpci, reading, &start_id, &first);
  if (result != 0) {
    ACL_DEBUG(KERN_WARNING "WARNING :: Failed get start id");
    return 1;
  }
  max_transfer = ACL_PCIE_DMA_TABLE_SIZE - start_id;
  
  for (transfer_bytes_w = ACL_PCIE_DMA_NON_ALIGNED_TRANS_LOG; transfer_bytes_w > 1; transfer_bytes_w--) {
    temp = remaining >> transfer_bytes_w;
    transfer_bytes = 1 << transfer_bytes_w;
    transfer_words = transfer_bytes/4;
    
    // Sanity check.
    // When PAGE_SIZE <= 4096 and ACL_PCIE_DMA_NON_ALIGNED_TRANS_LOG >= 11,
    // Non-aligned page handler transfers 1 descriptor at a time with size 2048 -> 1024 -> 512 -> ... -> 4
    // So temp is never greater than 1.
    if (PAGE_SIZE <= 4096 && ACL_PCIE_DMA_NON_ALIGNED_TRANS_LOG >= 11 && temp > 1) {
      ACL_DEBUG(KERN_WARNING "WARNING :: non aligned handler transferring %u with max at %i", (unsigned int)temp, max_transfer);
      return 1;
    }
    
    if (temp >= max_transfer) {
      for (i = 0; i < max_transfer; i++) {
        if (reading) {
          set_write_desc(&d->desc_table_wr_cpu_virt_addr->descriptors[i], (u64)qsys_addr + i*transfer_bytes, (dma_addr_t)pcie_addr + i*transfer_bytes, transfer_words, i+start_id);
        } else {
          set_read_desc(&d->desc_table_rd_cpu_virt_addr->descriptors[i], (dma_addr_t)pcie_addr + i*transfer_bytes, (u64)qsys_addr + i*transfer_bytes, transfer_words, i+start_id);
        }
        ACL_VERBOSE_DEBUG (KERN_DEBUG "Building descriptor :: Transferring %u bytes :: pcie addr %llx%llx :: qsys addr %llx%llx :: descriptor %i", (unsigned int)transfer_bytes, (u64) (pcie_addr + i*transfer_bytes) >> 32, (u64) (pcie_addr + i*transfer_bytes) & 0xffffffff, (u64) (qsys_addr + i*transfer_bytes) >> 32, (u64) (qsys_addr + i*transfer_bytes) & 0xffffffff, i+start_id);
      }
      transferred = transfer_bytes*max_transfer;
      last_id = ACL_PCIE_DMA_TABLE_SIZE - 1;
      ACL_VERBOSE_DEBUG (KERN_DEBUG "DMA Transfering page unaligned %u bytes",
                  (unsigned int)transfer_bytes*max_transfer);
      break;
    } else if (temp > 0) {
      for (i = 0; i < temp; i++) {
        if (reading) {
          set_write_desc(&d->desc_table_wr_cpu_virt_addr->descriptors[i], (u64)qsys_addr + i*transfer_bytes, (dma_addr_t)pcie_addr + i*transfer_bytes, transfer_words, i+start_id);
        } else {
          set_read_desc(&d->desc_table_rd_cpu_virt_addr->descriptors[i], (dma_addr_t)pcie_addr + i*transfer_bytes, (u64)qsys_addr + i*transfer_bytes, transfer_words, i+start_id);
        }
        ACL_VERBOSE_DEBUG (KERN_DEBUG "Building descriptor :: Transferring %u bytes :: pcie addr %llx%llx :: qsys addr %llx%llx :: descriptor %i", (unsigned int)transfer_bytes, (u64) (pcie_addr + i*transfer_bytes) >> 32, (u64) (pcie_addr + i*transfer_bytes) & 0xffffffff, (u64) (qsys_addr + i*transfer_bytes) >> 32, (u64) (qsys_addr + i*transfer_bytes) & 0xffffffff, i+start_id);
      }
      transferred = transfer_bytes*temp;
      last_id = start_id + temp - 1;
      ACL_VERBOSE_DEBUG (KERN_DEBUG "DMA Transfering page unaligned %u bytes",
                  (unsigned int)transfer_bytes*temp);
      break;
    }
  }
  if (last_id == ACL_PCIE_DMA_RESET_ID) {
    ACL_DEBUG(KERN_WARNING "DMA non-aligned transfer failed");
    return 1;
  }
  send_dma_desc(aclpci, reading, first, last_id);
  
  d->m_device_addr += transferred;
  d->m_bytes_sent += transferred;
  d->m_host_addr += transferred;
  d->m_active_mem.first_page_offset += transferred;
  remaining -= transferred;
  
  if (d->m_done_mem.dma.ptr != NULL) {
    unlock_dma_buffer (aclpci, &(d->m_done_mem.dma));
  }
  if (remaining == 0) {
    d->m_active_mem.first_page_offset = 0;
    ++d->m_active_mem.next_page;
    ++d->m_active_mem.next_dma_addr;
    d->m_active_mem.pages_rem--;
    next_page = *(d->m_active_mem.next_page);
    d->m_cur_dma_addr = page_to_phys (next_page);
  }
  
  return 0;
}

// Return 1 if something was done. 0 otherwise.
int aclpci_dma_update (struct aclpci_dev *aclpci, int forced)
{
   struct aclpci_dma *d = &(aclpci->dma_data);
   struct dma_t *dma = &(d->m_active_mem.dma);
   struct page *next_page;
   
   size_t remaining, lock_size;
   u32 first;
   unsigned int first_size, single_page;
   int i, max_transfer, start_id, last_id, reading, result = 1;
   
   u64 ej;
   
   reading = d->m_read;
     
   remaining = d->m_bytes - d->m_bytes_sent;
   max_transfer = 0;
   
   // DMA transaction complete. Reset values and return.
   if (remaining == 0) {
     d->dma_wr_last_id = ACL_PCIE_DMA_RESET_ID;
     d->dma_rd_last_id = ACL_PCIE_DMA_RESET_ID;
     d->m_page_last_id = ACL_PCIE_DMA_TABLE_SIZE-1;

     unlock_dma_buffer (aclpci, dma);
     if (d->m_done_mem.dma.ptr != NULL) {
        unlock_dma_buffer (aclpci, &(d->m_done_mem.dma));
      }
     
     ACL_VERBOSE_DEBUG (KERN_DEBUG "Done DMA for device_addr: %llx host_addr: %llx reading: %i bytes: %u\n", (u64)d->m_device_addr, (u64)d->m_host_addr, reading, (unsigned int) d->m_bytes);
     
     ej = get_jiffies_64();
     ACL_VERBOSE_DEBUG (KERN_DEBUG "Spent %u msec %sing %u bytes", jiffies_to_msecs(ej - d->m_start_time), 
                           reading ? "read" : "writ", (unsigned int) d->m_bytes);
     
     // Interrupt to MMD layer for DMA done
     d->m_idle = 1;
     if(aclpci->user_task != NULL) {
           if( send_sig_info(SIG_INT_NOTIFY, &aclpci->signal_info_dma, aclpci->user_task) < 0) {
              printk("Error sending signal to host!\n");
           }
     }
     return 1;
   }
   
   if (remaining > 0) {
      first = 0;
      
      if (d->m_active_mem.dma.ptr == NULL || d->m_active_mem.pages_rem == 0) {
        
        if (d->m_active_mem.pages_rem == 0) {
          d->m_done_mem = d->m_active_mem;
          d->m_active_mem.dma.ptr = NULL;
        }
        
        if (d->m_pre_pinned_mem.dma.ptr == NULL) {
          lock_size = (remaining > ((ACL_PCIE_DMA_PAGES_LOCKED * PAGE_SIZE) + ((ACL_PCIE_DMA_TABLE_SIZE - d->m_page_last_id) * PAGE_SIZE))) ?
                  ((ACL_PCIE_DMA_PAGES_LOCKED * PAGE_SIZE) + ((ACL_PCIE_DMA_TABLE_SIZE-1 - d->m_page_last_id) * PAGE_SIZE)) : remaining;

          if (lock_dma_buffer (aclpci, d->m_host_addr, lock_size, &d->m_active_mem) != 0) {
            ACL_DEBUG (KERN_WARNING "Failed lock dma buffer for %u bytes", (unsigned)lock_size);
            return -EFAULT;
          }
          ACL_VERBOSE_DEBUG (KERN_DEBUG "Pinning %u bytes %i pages remaining", (unsigned int)lock_size, d->m_active_mem.pages_rem);
        } else {
          d->m_active_mem = d->m_pre_pinned_mem;
          d->m_pre_pinned_mem.dma.ptr = NULL;
        }
        
        d->m_handle_last = (d->m_active_mem.last_page_offset != 0) ? 1 : 0;
        
        // First page offset causes last page to have offset when max number of pages is pinned
        if ((d->m_active_mem.pages_rem > (ACL_PCIE_DMA_PAGES_LOCKED)) && d->m_handle_last) {
          d->m_active_mem.pages_rem--;
          d->m_handle_last = 0;
        }
        next_page = *(d->m_active_mem.next_page);
        d->m_cur_dma_addr = page_to_phys (next_page);
      }
      
      single_page = (d->m_active_mem.pages_rem == 1) ? 1 : 0;
      
      first_size = PAGE_SIZE;
      first_size = (single_page) ? remaining : PAGE_SIZE - d->m_active_mem.first_page_offset;
      first_size = (first_size > PAGE_SIZE) ? PAGE_SIZE : first_size;
      
      ACL_VERBOSE_DEBUG (KERN_DEBUG "single_page %i :: remaining %u :: first_size %u :: offset %u", single_page, (unsigned int)remaining, (unsigned int)first_size, d->m_active_mem.first_page_offset);
      
      // Handler for non-aligned pages
      if ((first_size != PAGE_SIZE) && (first_size != 0)) {
        ACL_VERBOSE_DEBUG (KERN_DEBUG "Handling first page with offset :: Transferring %u bytes :: page start %llx%llx :: offset %u", first_size, d->m_cur_dma_addr >> 32, d->m_cur_dma_addr & 0xffffffff, d->m_active_mem.first_page_offset);
        result = non_aligned_page_handler(aclpci, (dma_addr_t) (d->m_cur_dma_addr + d->m_active_mem.first_page_offset), d->m_device_addr, first_size, reading);

        if (result != 0) {
          unlock_all_dma(aclpci);
          printk(KERN_ERR "aclpci_dma: Failed DMA First Page Transfer\n");
          return -EFAULT;
        }
        return 1;
      }
      // Handler for page size transactions
      if (d->m_active_mem.pages_rem > d->m_handle_last) {
        result = get_start_id(aclpci, reading, &start_id, &first);
        if (result != 0) {
          unlock_all_dma(aclpci);
          printk(KERN_ERR "aclpci_dma: Failed get start id\n");
          return -EFAULT;
        }
        max_transfer = (d->m_active_mem.pages_rem - d->m_handle_last > ACL_PCIE_DMA_TABLE_SIZE - start_id) ?
                ACL_PCIE_DMA_TABLE_SIZE - start_id : d->m_active_mem.pages_rem - d->m_handle_last;
        wmb();

        ACL_VERBOSE_DEBUG (KERN_DEBUG "Doing full table transfer :: pcie addr %llx%llx :: device addr %llx%llx", (u32) (d->m_cur_dma_addr >> 32), (u32) (d->m_cur_dma_addr & 0xffffffff), ((u64)(d->m_device_addr)) >> 32, ((u64)(d->m_device_addr)) & 0xffffffff);
        for (i = 0; i < max_transfer; i++) {
          if (reading) {
            set_write_desc(&d->desc_table_wr_cpu_virt_addr->descriptors[i], (u64)d->m_device_addr, (dma_addr_t) d->m_cur_dma_addr, PAGE_SIZE/4, i+start_id);
            ++d->m_active_mem.next_page;
            ++d->m_active_mem.next_dma_addr;
            d->m_device_addr += PAGE_SIZE;
            next_page = *(d->m_active_mem.next_page);
            d->m_cur_dma_addr = page_to_phys (next_page);
          } else {
            set_read_desc(&d->desc_table_rd_cpu_virt_addr->descriptors[i], (dma_addr_t) d->m_cur_dma_addr, (u64)d->m_device_addr, PAGE_SIZE/4, i+start_id);
            ++d->m_active_mem.next_page;
            ++d->m_active_mem.next_dma_addr;
            d->m_device_addr += PAGE_SIZE;
            next_page = *(d->m_active_mem.next_page);
            d->m_cur_dma_addr = page_to_phys (next_page);
          }
        }
        d->m_bytes_sent += PAGE_SIZE*max_transfer;
        d->m_host_addr += PAGE_SIZE*max_transfer;
        d->m_active_mem.pages_rem -= max_transfer;
        remaining -= PAGE_SIZE*max_transfer;
        
        last_id = max_transfer + start_id - 1;
        d->m_page_last_id = last_id;
        ACL_VERBOSE_DEBUG (KERN_DEBUG "Transfer pages start id = %i :: last id = %i :: max_transfer %i :: num pages %i", start_id, last_id, max_transfer, dma->num_pages);
        
        d->m_us_valid = 1;
        do_gettimeofday(&(d->m_us_dma_start_time));
        send_dma_desc(aclpci, reading, first, last_id);
        
        // pre-pin/unpin memory. Coupled with above pinning of memory.
        if (d->m_done_mem.dma.ptr != NULL) {
          unlock_dma_buffer (aclpci, &(d->m_done_mem.dma));
        }
        if (remaining > 0 && d->m_active_mem.pages_rem == 0) {
          lock_size = (remaining > ((ACL_PCIE_DMA_PAGES_LOCKED * PAGE_SIZE) + ((ACL_PCIE_DMA_TABLE_SIZE - d->m_page_last_id) * PAGE_SIZE))) ?
                    ((ACL_PCIE_DMA_PAGES_LOCKED * PAGE_SIZE) + ((ACL_PCIE_DMA_TABLE_SIZE-1 - d->m_page_last_id) * PAGE_SIZE)) : remaining;

          if (lock_dma_buffer (aclpci, d->m_host_addr, lock_size, &d->m_pre_pinned_mem) != 0) {
            // Don't EFAULT, since this will be re-tried on next interrupt.
            ACL_DEBUG (KERN_WARNING "Failed lock dma buffer for %u bytes", (unsigned)lock_size);
            return 1;
          }
        
          ACL_VERBOSE_DEBUG (KERN_DEBUG "Pre-pinning %u bytes %i pages remaining", (unsigned int)lock_size, d->m_pre_pinned_mem.pages_rem);
        }
          
        return 1;
      } // end :: if (remaining pages > 0)
   } // end :: if (remaining > 0)
   
   return 0;
}


#if LINUX_VERSION_CODE < KERNEL_VERSION(2, 6, 20)
void wq_func_dma_update(void *data){
   struct aclpci_dev *aclpci = (struct aclpci_dev *)data;
#else
void wq_func_dma_update(struct work_struct *pwork){
   struct work_struct_t * my_work_struct_t = container_of(pwork, struct work_struct_t, work);
   struct aclpci_dev *aclpci = (struct aclpci_dev *)my_work_struct_t->data;
#endif

   aclpci_dma_update(aclpci, 1);
   
   return;
}


int read_write
(
   struct aclpci_dev *aclpci, 
   void* src,
   void *dst,
   size_t bytes,
   int reading
)
{  
   size_t dev_addr;
   void *dma_desc_base;
   struct aclpci_dma *d = &(aclpci->dma_data);

    // TODO: For now, only handle one transfer at a time
   assert(d->m_active_mem.dma.ptr == NULL);

   // Copy the parameters over and mark the job as running
   d->m_read = reading;
   d->m_bytes = (bytes);
   assert(d->m_bytes == bytes);
   d->m_host_addr = reading ? dst : src;
   dev_addr = (size_t)(reading ? src : dst);
   d->m_device_addr = (size_t)(dev_addr);
   d->m_idle = 0;
   d->m_page_last_id = 127;
   
   //Keep local copy of last_id for current transfer. We don't have to read from pcie every table.
   dma_desc_base = get_dma_desc_offset(aclpci);
   if (reading) {
     d->dma_wr_last_id = ioread32(dma_desc_base+ACL_PCIE_DMA_WR_LAST_PTR);
   } else {
     d->dma_rd_last_id = ioread32(dma_desc_base+ACL_PCIE_DMA_RD_LAST_PTR);
   }

   // Start processing the request
   d->m_bytes_sent = 0;
   
   d->m_update_time = 0;
   d->m_pin_time = d->m_lock_time = d->m_unlock_time = 0;
   d->m_start_time = get_jiffies_64();
   
   ACL_VERBOSE_DEBUG (KERN_DEBUG "Entered DMA for src: %llx dst: %llx reading: %i bytes: %u\n", src, dst, reading, bytes);
   
   if( !queue_work(d->my_wq, &d->my_work->work) ){
      printk("fail to schedule the work\n");
   }
   
   return 1;
}


#else // USE_DMA is 0

irqreturn_t aclpci_dma_service_interrupt (struct aclpci_dev *aclpci) {
  return IRQ_HANDLED;
}
ssize_t aclpci_dma_rw (struct aclpci_dev *aclpci, 
                       void *dev_addr, void __user* user_addr, 
                       ssize_t len, int reading) {return 0; }
void aclpci_dma_init(struct aclpci_dev *aclpci) {}
void aclpci_dma_finish(struct aclpci_dev *aclpci) {}
int aclpci_dma_get_idle_status(struct aclpci_dev *aclpci) { return 1; }

#endif // USE_DMA
