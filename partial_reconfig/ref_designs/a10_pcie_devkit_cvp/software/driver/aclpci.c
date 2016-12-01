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

/* Top-level file for the driver.
 * Deal with device init and shutdown, BAR mapping, and interrupts. */

#include "aclpci.h"
#include <asm/siginfo.h>    //siginfo
#include <linux/rcupdate.h> //rcu_read_lock
#include <linux/version.h>  //kernel_version


MODULE_AUTHOR  ("Dmitry Denisenko");
MODULE_DESCRIPTION ("Driver for Altera OpenCL Acceleration Boards");
MODULE_SUPPORTED_DEVICE ("Altera OpenCL Boards");
MODULE_LICENSE("GPL");


/* Static function declarations */
#if LINUX_VERSION_CODE > KERNEL_VERSION(3, 7, 0)
# define MY_PROBE
# define MY_INIT __init
# define MY_EXIT __exit
#else
# define MY_PROBE __devinit
# define MY_INIT __devinit
# define MY_EXIT __devexit
#endif

static int MY_PROBE probe(struct pci_dev *dev, const struct pci_device_id *id);
static int MY_INIT init_chrdev (struct aclpci_dev *aclpci);
static void MY_EXIT remove(struct pci_dev *dev);
static int MY_INIT scan_bars(struct aclpci_dev *aclpci, struct pci_dev *dev);
static int MY_INIT map_bars(struct aclpci_dev *aclpci, struct pci_dev *dev);
static void free_bars(struct aclpci_dev *aclpci, struct pci_dev *dev);

/* Populating kernel-defined data structures */
static struct pci_device_id aclpci_ids[] = {
  { .vendor = ACL_PCI_ALTERA_VENDOR_ID, .device = PCI_ANY_ID, \
    .class = ACL_PCI_CLASSCODE, .class_mask = 0x00ff00ff, \
    .subvendor = ACL_PCI_SUBSYSTEM_VENDOR_ID, .subdevice = ACL_PCI_SUBSYSTEM_DEVICE_ID },
  { 0 },
};
MODULE_DEVICE_TABLE(pci, aclpci_ids);


static struct pci_driver aclpci_driver = {
  .name = DRIVER_NAME,
  .id_table = aclpci_ids,
  .probe = probe,
  .remove = remove,
  /* resume, suspend are optional */
};


struct file_operations aclpci_fileops = {
  .owner =    THIS_MODULE,
  .read =     aclpci_read,
  .write =    aclpci_write,
/*  .ioctl =    aclpci_ioctl, */
  .open =     aclpci_open,
  .release =  aclpci_close,
};


static int aclpci_major;
static unsigned char aclpci_devices[ACLPCI_MAX_MINORS];
static struct class *aclpci_class = NULL;

/* Allocate coherent memory and zero them */
/* Local implementation of dma_zalloc_coherent */
/* Customers using older version of kernel was running into issues using dma_zalloc_coherent */
static inline void *dma_zalloc_coherent_local(struct device *dev, size_t size, dma_addr_t *dma_handle, gfp_t flag)
{
  void *ret = dma_alloc_coherent(dev, size, dma_handle, flag);
  if (ret)
    memset(ret, 0, size);
    
  return ret;
}

/* Find a free minor id */
static unsigned int aclpci_get_free(void)
{
  unsigned int i;

  for (i = 0; i < ACLPCI_MAX_MINORS; i++)
    if (aclpci_devices[i] == 0)
      break;

  return i;
}

/* Allocate /dev/BOARD_NAME device */
static int MY_INIT init_chrdev (struct aclpci_dev *aclpci) {

  int dev_major =   aclpci_major; 
  int dev_minor =   aclpci_get_free();
  int devno = -1;
  int result;

  /* request minor number for device */
  if (dev_minor == ACLPCI_MAX_MINORS) {
    printk (KERN_ERR "can't get minor ID -- too many devices");
    goto fail_alloc;
  }
  aclpci_devices[dev_minor] = 1;
  devno = MKDEV(dev_major, dev_minor);
    
  cdev_init (&aclpci->cdev, &aclpci_fileops);
  aclpci->cdev.owner = THIS_MODULE;
  aclpci->cdev.ops = &aclpci_fileops;
  result = cdev_add (&aclpci->cdev, devno, 1);
  /* Fail gracefully if need be */
  if (result) {
    printk(KERN_NOTICE "Error %d adding aclpci (%d, %d)", result, dev_major, dev_minor);
    goto fail_add;
  }
  ACL_DEBUG (KERN_DEBUG "aclpci = %d:%d", MAJOR(devno), MINOR(devno));
  aclpci->cdev_num = devno;

  /* create device nodes under /dev/ using udev */
#if LINUX_VERSION_CODE < KERNEL_VERSION(2, 6, 26)
  aclpci->device = device_create(aclpci_class, NULL, devno, BOARD_NAME "%d", dev_minor);
#else
  aclpci->device = device_create(aclpci_class, NULL, devno, NULL, BOARD_NAME "%d", dev_minor);
#endif
  if (IS_ERR(aclpci->device)) {
    printk(KERN_NOTICE "Can't create device\n");
    goto fail_dev_create;
  }
  
  return 0;
  
/* ERROR HANDLING */
fail_dev_create:
  cdev_del(&aclpci->cdev);
fail_add:
  /* free the dynamically allocated character device node */
  unregister_chrdev_region(devno, 1/*count*/);
  
fail_alloc:
  return -1;
}


/* Returns virtual mem address corresponding to location of IRQ control
 * register of the board */
static void* get_interrupt_enable_addr(struct aclpci_dev *aclpci) {

  /* Bar 2, register PCIE_CRA_IRQ_ENABLE is the IRQ enable register
   * (among other things). */
  return (void*)(aclpci->bar[ACL_PCI_CRA_BAR] + (unsigned long)PCIE_CRA_IRQ_ENABLE);
}


static void* get_interrupt_status_addr(struct aclpci_dev *aclpci) {

  /* Bar 2, register PCIE_CRA_IRQ_ENABLE is the IRQ enable register
   * (among other things). */
  return (void*)(aclpci->bar[ACL_PCI_CRA_BAR] + (unsigned long)PCIE_CRA_IRQ_STATUS);
}



/* Disable interrupt generation on the device. */
static void mask_irq(struct aclpci_dev *aclpci) {

  /* Save kernel irq mask */
  aclpci->saved_kernel_irq_mask = ACL_PCIE_READ_BIT(
      readl(get_interrupt_enable_addr(aclpci)),ACL_PCIE_KERNEL_IRQ_VEC);

  writel (0x0, get_interrupt_enable_addr(aclpci));
  //Read again to ensure the writel is finished
  //Without doing this might cause the programe moving
  //forward without properly mask the irq.
  readl(get_interrupt_enable_addr(aclpci));
}


/* Enable interrupt generation on the device. */
static void unmask_irq(struct aclpci_dev *aclpci) {

  u32 val = 0;
  
  /* Restore kernel irq mask */
  if (aclpci->saved_kernel_irq_mask)
    val = ACL_PCIE_GET_BIT(ACL_PCIE_KERNEL_IRQ_VEC);

  writel (val, get_interrupt_enable_addr(aclpci));
}

/* Enable interrupt generation on the device. */
void unmask_kernel_irq(struct aclpci_dev *aclpci) {

  u32 val = 0;
  val = readl(get_interrupt_enable_addr(aclpci));
  val |= ACL_PCIE_GET_BIT(ACL_PCIE_KERNEL_IRQ_VEC);

  writel (val, get_interrupt_enable_addr(aclpci));
}

//
// IDENTICAL COPY OF THIS FUNCTION IS IN HAL/PCIE.
// KEEP THE TWO COPIES IN SYNC!!!
//
// Given irq status, determine type of interrupt
// Result is returned in kernel_update/dma_update arguments.
// Using 'int' instead of 'bool' for returns because the kernel code
// is pure C and doesn't support bools.
void get_interrupt_type (struct aclpci_dma *aclpci_dma_data, unsigned int irq_status, 
                         unsigned int *kernel_update, unsigned int *dma_update)
{
   int dma_last_id, reading;
   *kernel_update = ACL_PCIE_READ_BIT( irq_status, ACL_PCIE_KERNEL_IRQ_VEC );
  
   reading = aclpci_dma_data->m_read;
   
   if (reading) {
     if (aclpci_dma_data->dma_wr_last_id < 128) {
       dma_last_id = aclpci_dma_data->dma_wr_last_id;
       *dma_update = (aclpci_dma_data->desc_table_wr_cpu_virt_addr->header.flags[dma_last_id]);
     } else {
       *dma_update = 0;
     }
   } else {
     if (aclpci_dma_data->dma_rd_last_id < 128) {
       dma_last_id = aclpci_dma_data->dma_rd_last_id;
       *dma_update = (aclpci_dma_data->desc_table_rd_cpu_virt_addr->header.flags[dma_last_id]);
     } else {
       *dma_update = 0;
     }
   }
    
   
}


void mask_kernel_irq(struct aclpci_dev *aclpci){
  u32 val;
  val = readl(get_interrupt_enable_addr(aclpci));

  if((val & ACL_PCIE_GET_BIT(ACL_PCIE_KERNEL_IRQ_VEC)) != 0){
    val ^= ACL_PCIE_GET_BIT(ACL_PCIE_KERNEL_IRQ_VEC);
  }

  writel (val, get_interrupt_enable_addr(aclpci));
  //Read again to ensure the writel is finished
  //Without doing this might cause the programe moving
  //forward without properly mask the irq.
  val = readl(get_interrupt_enable_addr(aclpci));
}
#if LINUX_VERSION_CODE < KERNEL_VERSION(2, 6, 19)
irqreturn_t aclpci_irq (int irq, void *dev_id, struct pt_regs * not_used) {
#else
irqreturn_t aclpci_irq (int irq, void *dev_id) {
#endif


  struct aclpci_dev *aclpci = (struct aclpci_dev *)dev_id;
  struct aclpci_dma *aclpci_dma_data = &(aclpci->dma_data);
  
  u32 irq_status;
  irqreturn_t res;
  unsigned int kernel_update = 0, dma_update = 0;
 
  if (aclpci == NULL) {
    return IRQ_NONE;
  }
  
  /* During core reconfiguration, ignore interrupts. */
  if (aclpci->pr_in_progress) {
    ACL_VERBOSE_DEBUG (KERN_WARNING "Ignoring interrupt while PR is in progress");
    return IRQ_HANDLED;
  }
  
  /* From this point on, this is our interrupt. So return IRQ_HANDLED
   * no matter what (since nobody else in the system will handle this
   * interrupt for us). */
  aclpci->num_handled_interrupts++;
  

  
  /* Can get interrupt for two reasons --  DMA descriptor processing is done
   * or kernel has finished. DMA is done entirely in the driver, so check for
   * that first and do NOT notify the user. */
  irq_status = readl ( get_interrupt_status_addr(aclpci) );

  get_interrupt_type (aclpci_dma_data, irq_status, &kernel_update, &dma_update);
  
  ACL_VERBOSE_DEBUG (KERN_WARNING "irq_status = 0x%x, kernel = %d, dma = %d",
                     irq_status, kernel_update, dma_update);

  if(!dma_update && !kernel_update){
    return IRQ_HANDLED;
  }
  if (kernel_update) {
  
  mask_kernel_irq(aclpci);
  #if !POLLING
    /* Send SIGNAL to user program to notify about the kernel update interrupt. */
    if (aclpci->user_task != NULL) {
      int ret = send_sig_info(SIG_INT_NOTIFY, &aclpci->signal_info, aclpci->user_task);      
      if (ret < 0) {
        /* Can get to this state if the host is suspended for whatever reason.
         * Just print a warning message the first few times. The FPGA will keep
         * the interrupt level high until the kernel done bit is cleared (by the host).
         * See Case:84460. */
        aclpci->num_undelivered_signals++;
        if (aclpci->num_undelivered_signals < 5) {
          ACL_DEBUG (KERN_DEBUG "Error sending signal to host! irq_status is 0x%x\n", irq_status);
        }
      }
    }
  #else
    ACL_VERBOSE_DEBUG (KERN_WARNING "Kernel update interrupt. Letting host POLL for it.");
  #endif
    res = IRQ_HANDLED;
     
  }
  if (dma_update) {
    /* A DMA-status interrupt - let the DMA object handle this without going to
      * user space */
    res = aclpci_dma_service_interrupt(aclpci);
  }
  return res;
}


void load_signal_info (struct aclpci_dev *aclpci) {

  /* Setup siginfo struct to send signal to user process. Doing it once here
   * so don't waste time inside the interrupt handler. */
  struct siginfo *info = &aclpci->signal_info;
  memset(info, 0, sizeof(struct siginfo));
  info->si_signo = SIG_INT_NOTIFY;
  /* this is bit of a trickery: SI_QUEUE is normally used by sigqueue from user
   * space,  and kernel space should use SI_KERNEL. But if SI_KERNEL is used the
   * real_time data is not delivered to the user space signal handler function. */
  info->si_code = SI_QUEUE;
  info->si_int = 0;  /* Signal payload. Will be filled later with 
                        ACLPCI_CMD_SET_SIGNAL_PAYLOAD cmd from user. */

  /* Perform the same setup for struct siginfo for dma */
  info = &aclpci->signal_info_dma;
  memset(info, 0, sizeof(struct siginfo));
  info->si_signo = SIG_INT_NOTIFY;
  info->si_code  = SI_QUEUE;
  info->si_int   = 0;
}


int init_irq (struct pci_dev *dev, void *dev_id) {

  u32 irq_type;
  struct aclpci_dev *aclpci = (struct aclpci_dev*)dev_id;
  int rc;

  if (dev == NULL || aclpci == NULL) {
    ACL_DEBUG (KERN_WARNING "Invalid inputs to init_irq (%p, %p)", dev, dev_id);
    return -1;
  }
  
  /* Message Signalled Interrupts. */  
  #if USE_MSI
  if(pci_enable_msi(dev) != 0){
    ACL_DEBUG (KERN_WARNING "Could not enable MSI");
  }
  if (!pci_set_dma_mask(dev, DMA_BIT_MASK(64))) {
    pci_set_consistent_dma_mask(dev, DMA_BIT_MASK(64));
    ACL_DEBUG (KERN_WARNING "using a 64-bit irq mask\n");
  } else {
    ACL_DEBUG (KERN_WARNING "unable to use 64-bit irq mask\n");
    pci_disable_msi(dev);
    return -1;
  }
  #endif

  /* Do NOT use PCI_INTERRUPT_LINE config register. Its value is different
   * from dev->irq and doesn't work! Why? Who knows! */
  
  /* IRQF_SHARED   -- allow sharing IRQs with other devices */
  #if !USE_MSI 
    irq_type = IRQF_SHARED;
  #else
    /* No need to share MSI interrupts since they don't use dedicated wires.*/
    irq_type = 0;
  #endif
  
  pci_read_config_byte(dev, PCI_REVISION_ID, &aclpci->revision);
  pci_read_config_byte(dev, PCI_INTERRUPT_PIN, &aclpci->irq_pin);
  pci_read_config_byte(dev, PCI_INTERRUPT_LINE, &aclpci->irq_line);
  
  ACL_VERBOSE_DEBUG (KERN_WARNING "irq pin: %d\n", aclpci->irq_pin);
  ACL_VERBOSE_DEBUG (KERN_WARNING "irq line: %d\n", aclpci->irq_line);
  ACL_VERBOSE_DEBUG (KERN_WARNING "irq: %d\n", dev->irq);
  
  rc = request_irq (dev->irq, aclpci_irq, irq_type, DRIVER_NAME, dev_id);
  if (rc) {
    ACL_DEBUG (KERN_WARNING "Could not request IRQ #%d, error %d", dev->irq, rc);
    return -1;
  }
  pci_write_config_byte(dev, PCI_INTERRUPT_LINE, dev->irq);
  ACL_VERBOSE_DEBUG (KERN_DEBUG "Succesfully requested IRQ #%d", dev->irq);
  
  aclpci->num_handled_interrupts = 0;
  aclpci->num_undelivered_signals = 0;
  
  aclpci_dma_init(aclpci);
  
  /* Enable interrupts */
  unmask_irq(aclpci);
  
  return 0;
}


void release_irq (struct pci_dev *dev, void *aclpci) {

  int num_usignals;
  
  aclpci_dma_finish(aclpci);
  
  /* Disable interrupts before going away. If something bad happened in
   * user space and the user program crashes, the interrupt assigned to the device
   * will be freed (on automatic close()) call but the device will continue 
   * generating interrupts. Soon the kernel will notice, complain, and bring down
   * the whole system. */
  mask_irq(aclpci);
  
  ACL_VERBOSE_DEBUG (KERN_DEBUG "Freeing IRQ %d", dev->irq);
  free_irq (dev->irq, aclpci);
  
  ACL_VERBOSE_DEBUG (KERN_DEBUG "Handled %d interrupts", 
        ((struct aclpci_dev*)aclpci)->num_handled_interrupts);
        
  num_usignals = ((struct aclpci_dev*)aclpci)->num_undelivered_signals;
  if (num_usignals > 0) {
    ACL_DEBUG (KERN_DEBUG "Number undelivered signals is %d", num_usignals);
  }
    
  /* Perform software reset on the FPGA.
   * If the host is killed after launching a kernel but before the kernel
   * finishes, the FPGA will keep sending "kernel done" interrupt. That might
   * kill a *new* host before it can do anything. 
   *
   * WARNING: THIS RESET LOGIC IS ALSO IN THE HAL/PCIE.
   *          IF YOU CHANGE IT, UPDATE THE HAL AS WELL!!! */
  ACL_VERBOSE_DEBUG (KERN_DEBUG "Reseting kernel on FPGA");
  //PETE - disable this for now
  //pio_out_addr_base = ((struct aclpci_dev*)aclpci)->bar[ACL_PCIE_PIO_OUT_BAR] + ACL_PCIE_PIO_OUT_OFFSET - ACL_PCIE_MEMWINDOW_SIZE;
  /* Do the reset */
  //writel (ACL_PCIE_GET_BIT(PIO_OUT_SWRESET), pio_out_addr_base + PIO_SET);
  /* De-assert the reset */
  //for (i = 0; i < 10; i++) {
    //writel (ACL_PCIE_GET_BIT(PIO_OUT_SWRESET), pio_out_addr_base + PIO_CLR);
  //}
  
  #if USE_MSI
    pci_disable_msi (dev);
  #endif
  mask_irq(aclpci);
}


/* Find upstream PCIe root node. 
 * Used for re-training and disabling AER. */
static struct pci_dev* find_upstream_dev (struct pci_dev *dev) {
  struct pci_bus *bus = 0;
  struct pci_dev *bridge = 0;
  struct pci_dev *cur = 0;
  int found_dev = 0;
  
  bus = dev->bus;
  if (bus == 0) {
    ACL_DEBUG (KERN_WARNING "Device doesn't have an associated bus!\n");
    return 0;
  }
  
  bridge = bus->self;
  if (bridge == 0) {
    ACL_DEBUG (KERN_WARNING "Can't get the bridge for the bus!\n");
    return 0;
  }
  
  ACL_DEBUG (KERN_DEBUG "Upstream device %x/%x, bus:slot.func %02x:%02x.%02x", 
             bridge->vendor, bridge->device,
             bridge->bus->number, PCI_SLOT(bridge->devfn), PCI_FUNC(bridge->devfn));
             
  ACL_DEBUG (KERN_DEBUG "List of downstream devices:");
  list_for_each_entry (cur, &bus->devices, bus_list) {
    if (cur != 0) {
      ACL_DEBUG (KERN_DEBUG "  %x/%x", cur->vendor, cur->device);
      if (cur == dev) {
        found_dev = 1;
      }
    }
  }
  
  if (found_dev) {
    return bridge;
  } else {
    ACL_DEBUG (KERN_WARNING "Couldn't find upstream device!");
    return 0;
  }
}

static int MY_PROBE probe(struct pci_dev *dev, const struct pci_device_id *id) {

  struct aclpci_dev *aclpci = 0;
  struct aclpci_dma *aclpci_dma_data = 0;
  int res;
  
  ACL_VERBOSE_DEBUG (KERN_DEBUG " probe (dev = 0x%p, pciid = 0x%p)", dev, id);
  ACL_DEBUG (KERN_DEBUG " vendor = 0x%x, device = 0x%x, class = 0x%x, bus:slot.func = %02x:%02x.%02x",
        dev->vendor, dev->device, dev->class, 
        dev->bus->number, PCI_SLOT(dev->devfn), PCI_FUNC(dev->devfn));
  
  aclpci = kzalloc(sizeof(struct aclpci_dev), GFP_KERNEL);
  if (!aclpci) {
    ACL_DEBUG(KERN_WARNING "Couldn't allocate memory!\n");
    goto fail_kzalloc;
  }
  

  sema_init (&aclpci->sem, 1);
  aclpci->pci_dev = dev;
  dev_set_drvdata(&dev->dev, (void*)aclpci);
  aclpci->user_pid = -1;
  aclpci->pr_in_progress = 0;
  aclpci->pci_gen = 0;
  aclpci->pci_num_lanes = 0;
  aclpci->upstream = find_upstream_dev (dev);
  aclpci->num_handles_open = 0;

  retrain_gen2 (aclpci);
        
  aclpci->buffer = kmalloc (BUF_SIZE * sizeof(char), GFP_KERNEL);
  if (!aclpci->buffer) {
    ACL_DEBUG(KERN_WARNING "Couldn't allocate memory for buffer!\n");
    goto fail_kmalloc;
  }
  
  res = init_chrdev (aclpci);
  if (res) {
    goto fail_chrdev_init;
  }
  
  if (pci_enable_device(dev)) {
    ACL_DEBUG (KERN_WARNING "pci_enable_device() failed");
    goto fail_enable;
  }

  pci_set_master(dev);

  if (pci_request_regions(dev, DRIVER_NAME)) {
    goto fail_regions;
  }
  scan_bars(aclpci, dev);  
  if (map_bars(aclpci, dev)) {
    goto fail_map_bars;
  }
  
  // DMA initialization required at driver installation
  // Keep descriptor table in memory
  aclpci_dma_data = &(aclpci->dma_data);
  aclpci_dma_data->dma_rd_last_id = 255;
  aclpci_dma_data->dma_wr_last_id = 255;
  
  aclpci_dma_data->desc_table_rd_cpu_virt_addr = (struct dma_desc_table *)dma_zalloc_coherent_local(&dev->dev, sizeof(struct dma_desc_table), &aclpci_dma_data->desc_table_rd_bus_addr, GFP_KERNEL);
  if (!aclpci_dma_data->desc_table_rd_cpu_virt_addr) {
      res = -ENOMEM;
      goto err_rd_table;
  }
  aclpci_dma_data->desc_table_wr_cpu_virt_addr = (struct dma_desc_table *)dma_zalloc_coherent_local(&dev->dev, sizeof(struct dma_desc_table), &aclpci_dma_data->desc_table_wr_bus_addr, GFP_KERNEL);
  if (!aclpci_dma_data->desc_table_wr_cpu_virt_addr) {
      res = -ENOMEM;
      goto err_wr_table;
  }
  
  return 0;


/* ERROR HANDLING */
err_wr_table:
    dma_free_coherent(&dev->dev, sizeof(struct dma_desc_table), aclpci_dma_data->desc_table_wr_cpu_virt_addr, aclpci_dma_data->desc_table_wr_bus_addr);
    
err_rd_table:
    dma_free_coherent(&dev->dev, sizeof(struct dma_desc_table), aclpci_dma_data->desc_table_rd_cpu_virt_addr, aclpci_dma_data->desc_table_rd_bus_addr);

fail_map_bars:
  pci_release_regions(dev);
  pci_disable_device (dev);
  
fail_regions:

fail_enable:
  unregister_chrdev_region (aclpci->cdev_num, 1);
  aclpci_devices[MINOR(aclpci->cdev_num)] = 0;
 
fail_chrdev_init:
  kfree (aclpci->buffer);
  
fail_kmalloc:
  kfree (aclpci);
  
fail_kzalloc:
  return -1;
}


static int MY_INIT scan_bars(struct aclpci_dev *aclpci, struct pci_dev *dev)
{
  int i;
  for (i = 0; i < ACL_PCI_NUM_BARS; i++) {
    unsigned long bar_start = pci_resource_start(dev, i);
    if (bar_start) {
      unsigned long bar_end = pci_resource_end(dev, i);
      unsigned long bar_flags = pci_resource_flags(dev, i);
      ACL_DEBUG (KERN_DEBUG "BAR[%d] 0x%08lx-0x%08lx flags 0x%08lx",
         i, bar_start, bar_end, bar_flags);
    }
  }
  return 0;
}


/**
 * Map the device memory regions into kernel virtual address space
 * after verifying their sizes respect the minimum sizes needed, given
 * by the bar_min_len[] array.
 */
static int MY_INIT map_bars(struct aclpci_dev *aclpci, struct pci_dev *dev)
{
  int i;
  for (i = 0; i < ACL_PCI_NUM_BARS; i++){
    unsigned long bar_start = pci_resource_start(dev, i);
    unsigned long bar_end = pci_resource_end(dev, i);
    unsigned long bar_length = bar_end - bar_start + 1;
    aclpci->bar_length[i] = bar_length;

    if (!bar_start || !bar_end) {
      aclpci->bar_length[i] = 0;
      continue;
    }

    if (bar_length < 1) {
      ACL_DEBUG (KERN_WARNING "BAR #%d length is less than 1 byte", i);
      continue;
    }

    /* map the device memory or IO region into kernel virtual
     * address space */  
    aclpci->bar[i] = ioremap (bar_start, bar_length);

    if (!aclpci->bar[i]) {
      ACL_DEBUG (KERN_WARNING "Could not map BAR #%d.", i);
      return -1;
    }

    ACL_DEBUG (KERN_DEBUG "BAR[%d] mapped at 0x%p with length %lu.", i,
         aclpci->bar[i], bar_length);
  }
  return 0;
}  



static void free_bars(struct aclpci_dev *aclpci, struct pci_dev *dev) {

  int i;
  for (i = 0; i < ACL_PCI_NUM_BARS; i++) {
    if (aclpci->bar[i]) {
      pci_iounmap(dev, aclpci->bar[i]);
      aclpci->bar[i] = NULL;
    }
  }
}

static void MY_EXIT remove(struct pci_dev *dev) {

  struct aclpci_dev *aclpci = 0;
  struct aclpci_dma *aclpci_dma_data;
  ACL_DEBUG (KERN_DEBUG ": dev is %p", dev);
  
  if (dev == 0) {
    ACL_DEBUG (KERN_WARNING ": dev is 0");
    return;
  }
  
  aclpci = (struct aclpci_dev*) dev_get_drvdata(&dev->dev);
  if (aclpci == 0) {
    ACL_DEBUG (KERN_WARNING ": aclpci_dev is 0");
    return;
  }
  
  aclpci_dma_data = &(aclpci->dma_data);
  
  dma_free_coherent(&dev->dev, sizeof(struct dma_desc_table), aclpci_dma_data->desc_table_wr_cpu_virt_addr, aclpci_dma_data->desc_table_wr_bus_addr);
  dma_free_coherent(&dev->dev, sizeof(struct dma_desc_table), aclpci_dma_data->desc_table_rd_cpu_virt_addr, aclpci_dma_data->desc_table_rd_bus_addr);
  
  #if USE_MSI
    pci_disable_msi(dev);
    if (aclpci->irq_line >= 0) {
      printk(KERN_DEBUG "Freeing IRQ #%d", aclpci->irq_line);
      free_irq(aclpci->irq_line, (void *)aclpci);
    }
  #endif
  
  device_destroy(aclpci_class, aclpci->cdev_num);
  cdev_del (&aclpci->cdev);
  aclpci_devices[MINOR(aclpci->cdev_num)] = 0;
  free_bars (aclpci, dev);
  pci_disable_device(dev);
  pci_release_regions(dev);

  kfree (aclpci->buffer);
  kfree (aclpci);
}


/* Initialize the driver module (but not any device) and register
 * the module with the kernel PCI subsystem. */
static int __init aclpci_init(void) {

  unsigned int i;
  int retval;
  dev_t dev;

  ACL_DEBUG (KERN_DEBUG "----------------------------");
  ACL_DEBUG (KERN_DEBUG "Driver version: %s", ACL_DRIVER_VERSION);

  /* initialize the allocated minor devices */
  for (i = 0; i < ACLPCI_MAX_MINORS; i++) {
    aclpci_devices[i] = 0;
  }

  retval = alloc_chrdev_region(&dev, 0, ACLPCI_MAX_MINORS, BOARD_NAME);
  if (retval) {
    printk(KERN_ERR "aclpci: can't register character device\n");
    goto err_attr;
  }
  aclpci_major = MAJOR(dev);
  
  aclpci_class = class_create(THIS_MODULE, DRIVER_NAME);
  if (IS_ERR(aclpci_class)) {
    printk(KERN_ERR "aclpci: can't create class\n");
    goto err_unchr;
  }
 
  /* register this driver with the PCI bus driver */
  ACL_DEBUG (KERN_DEBUG "pci_register_driver");
  retval =  pci_register_driver(&aclpci_driver);
  if (retval) {
    printk(KERN_ERR "aclpci: can't register pci driver\n");
    goto err_class_create;
  }
  ACL_DEBUG (KERN_DEBUG "success");
  return 0;

  /* error handling */
err_class_create:
  class_destroy(aclpci_class);
err_unchr:
  unregister_chrdev_region(dev, ACLPCI_MAX_MINORS);
err_attr:
  return retval;
}

static void __exit aclpci_exit(void)
{
  ACL_DEBUG (KERN_DEBUG "");

  /* unregister this driver from the PCI bus driver */
  pci_unregister_driver(&aclpci_driver);

  class_destroy(aclpci_class);
  
  unregister_chrdev_region (MKDEV(aclpci_major,0), ACLPCI_MAX_MINORS);  
}


module_init (aclpci_init);
module_exit (aclpci_exit);
