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

/* Defines used only by aclpci_dma.c. */


#if USE_DMA

/* Enable Linux-specific defines in the hw_pcie_dma.h file */
#define LINUX
#include <linux/workqueue.h>
#include "hw_pcie_dma.h"
#include "aclpci_queue.h"

struct dma_t {
  void *ptr;         /* if ptr is NULL, the whole struct considered invalid */
  size_t len;
  enum dma_data_direction dir;
  struct page **pages;     /* one for each struct page */
  dma_addr_t *dma_addrs;   /* one for each struct page */
  unsigned int num_pages;
};

struct pinned_mem {
  struct dma_t dma;
  struct page **next_page;
  dma_addr_t *next_dma_addr;
  unsigned int pages_rem;
  unsigned int first_page_offset;
  unsigned int last_page_offset;
};

struct work_struct_t{
   struct work_struct work;
   void *data;
};

struct dma_desc_entry {                  
    u32 src_addr_ldw;
    u32 src_addr_udw;
    u32 dest_addr_ldw;
    u32 dest_addr_udw;
    u32 ctl_dma_len;
    u32 reserved[3];
} __attribute__ ((packed));

struct dma_desc_header {
    volatile u32 flags[128];
} __attribute__ ((packed));


struct dma_desc_table {
    struct dma_desc_header header;
    struct dma_desc_entry descriptors[128];
} __attribute__ ((packed));

struct aclpci_dma {

  // Pci-E DMA IP description table
  struct dma_desc_table *desc_table_rd_cpu_virt_addr;
  struct dma_desc_table *desc_table_wr_cpu_virt_addr;

  dma_addr_t desc_table_rd_bus_addr;
  dma_addr_t desc_table_wr_bus_addr;

  // Local copy of last transfer id. Read once when DMA transfer starts
  int dma_rd_last_id;
  int dma_wr_last_id;
  int m_page_last_id;

  // Pinned memory we're currently building DMA transactions for
  struct pinned_mem m_active_mem;
  struct pinned_mem m_pre_pinned_mem;
  struct pinned_mem m_done_mem;

  // The transaction we are currently working on
  unsigned long m_cur_dma_addr;
  int m_handle_last;

  struct pci_dev *m_pci_dev;
  struct aclpci_dev *m_aclpci;

  // workqueue and work structure for bottom-half interrupt routine
  struct workqueue_struct *my_wq;
  struct work_struct_t *my_work;
  
  // Transfer information
  size_t m_device_addr;
  void* m_host_addr;
  int m_read;
  size_t m_bytes;
  size_t m_bytes_sent;
  int m_idle;

  u64 m_update_time, m_pin_time, m_start_time;
  u64 m_lock_time, m_unlock_time;
  
  // Time measured to us accuracy to measure DMA transfer time
  struct timeval m_us_dma_start_time;
  int m_us_valid;
};

#else
struct aclpci_dma {};
#endif
