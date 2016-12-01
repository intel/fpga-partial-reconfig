// Copyright (c) 2001-2016 Intel Corporation
//  
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//  
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//  
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

//standard libraries
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <unistd.h>
#include <fcntl.h>
#include <string>
#include <iostream>
#include <sstream>

//PCI IP constants
#include "hw_pcie_constants.h"
#include "version.h"
#include "pcie_linux_driver_exports.h"

#define KERNEL_DRIVER_VERSION_EXPECTED ACL_DRIVER_VERSION

//define some needed data types
typedef unsigned int        uintptr_t;
typedef unsigned int        DWORD;
typedef unsigned long long  QWORD;
#define INVALID_DEVICE (-1)

typedef ssize_t WDC_DEVICE_HANDLE;

struct ACL_PCIE_DEVICE_DESCRIPTION
{
   DWORD vendor_id;
   DWORD device_id;
   char  pcie_info_str[1024];
};


//sends a command to the PCIe driver to save the control registers
int save_pci_control_regs(WDC_DEVICE_HANDLE m_device)
{
   int save_failed = 1;
   struct acl_cmd cmd_save = { ACLPCI_CMD_BAR, ACLPCI_CMD_SAVE_PCI_CONTROL_REGS, NULL, NULL };

   //executes the save registers command and stores the pass/fail status in save_failed
   //because we only want to send a command and do not care about reading or writing a value
   //either read or write can be used to execute this command
   save_failed = read(m_device, &cmd_save, 0);

   return save_failed;
}

//sends a command to the PCIe driver to load the control registers
int load_pci_control_regs(WDC_DEVICE_HANDLE m_device)
{
   int load_failed = 1;
   struct acl_cmd cmd_load = { ACLPCI_CMD_BAR, ACLPCI_CMD_LOAD_PCI_CONTROL_REGS, NULL, NULL };

   //executes load registers command and stores the pass/fail status in load_failed
   //because we only want to send a command and do not care about reading or writing a value
   //either read or write can be used to execute this command
   load_failed = read(m_device, &cmd_load, 0);

   return load_failed;
}

//opens the pcie device and compares its driver version to the expected value
WDC_DEVICE_HANDLE open_device_linux(int dev_num)
{
   char buf[128] = {0};
   std::string mystr = "/dev/acl";
   mystr += ACL_BOARD_PKG_NAME;

   std::ostringstream temp;
   temp << dev_num;
   mystr += temp.str();

   //opening device
   ssize_t device = open(mystr.c_str(), O_RDWR);

   //expected version
   std::string expected_ver_string = ACL_BOARD_PKG_NAME;
   expected_ver_string += ".";
   expected_ver_string += KERNEL_DRIVER_VERSION_EXPECTED;

   // Return INVALID_DEVICE when the device is not available
   if (device == -1)
   {
      return INVALID_DEVICE;
   }

   // Make sure the Linux kernel driver is recent
   struct acl_cmd driver_cmd = { ACLPCI_CMD_BAR, ACLPCI_CMD_GET_DRIVER_VERSION,
                              NULL, buf, 0 };
   read (device, &driver_cmd, 0);

   /*if (expected_ver_string != std::string(buf))
   {
       std::cout << "ERROR: Kernel driver mismatch: "
                    "The board kernel driver version is " << buf <<
                    " but\nthis host program expects " << expected_ver_string <<
                    ".\n  Please reinstall the driver using aocl install.\n";

       return INVALID_DEVICE;
   }*/

   // Set the FD_CLOEXEC flag for the file handle to disable the child to
   // inherit this file handle. So the jtagd will not hold the file handle
   // of the device and keep sending bogus interrupts after we call quartus_pgm.
   int oldflags = fcntl( device, F_GETFD, 0);
   fcntl( device, F_SETFD, oldflags | FD_CLOEXEC );

   return device;
}

//programs the FPGA using quartus_pgm
bool program_over_jtag(const std::string& filename, bool pr, const std::string& cable,const std::string& device_index, bool slow_jtag)
{
   int program_failed = 1;

   std::string cmd;

   if (slow_jtag)
   {
       std::cout << "INFO: Reducing JTAG clock to 6M because slow_jtag flag was set\n";
       //sets JtagClock to 6M to reduce chances of programming failed due to bad signal integrity
       cmd = "jtagconfig --setparam " + cable + " JtagClock 6M";

       system(cmd.c_str());
   }


   if (!pr)
   {
       cmd = "quartus_pgm -c " + cable + " -m jtag -o \"P;" + filename + "@" + device_index +  "\"";//does full chip programming using SOF
   }
   else
   {
       cmd = "quartus_pgm -c " + cable + " -m JTAG --pr="+ filename;//does partial reconfiguration using RBF
   }

   //execute quartus_pgm
   std::cout << "INFO: executing command : " << cmd << std::endl;
   program_failed = system(cmd.c_str());



   return program_failed;
}

//writes to the driver to disable interrupts
int disable_interrupts(WDC_DEVICE_HANDLE m_device)
{
    int data                  = 0;
    int address               = PCIE_CRA_IRQ_ENABLE;

    struct acl_cmd driver_cmd;
    driver_cmd.bar_id         = ACL_PCI_GLOBAL_MEM_BAR;
    driver_cmd.command        = ACLPCI_CMD_DEFAULT;

    //both user_addr and device_addr fields need an address pointer
    driver_cmd.device_addr    = reinterpret_cast<void *>(address);//address to write to in the PCI address space, driver requires this to be a void pointer
    driver_cmd.user_addr      = &data;//address to read from in user address space
    driver_cmd.size           = sizeof(data);

    //endianness does not matter for this operation
    driver_cmd.is_diff_endian = 0;

    return write (m_device, &driver_cmd, sizeof(driver_cmd));
}

//takes a character pointer to a locally stored rbf and sends it to the PR controller
int program_core_with_PR ( WDC_DEVICE_HANDLE device, char *core_bitstream, size_t core_rbf_len)
{
    int pr_result = 1;   // set to default - failure
    struct acl_cmd cmd_pr = { ACLPCI_CMD_BAR, ACLPCI_CMD_DO_PR, NULL, NULL };
    cmd_pr.user_addr = core_bitstream;
    cmd_pr.size      = core_rbf_len;
    //this invoces a special driver function that is used to send the bitstream to the PR controller
    pr_result = read( device, &cmd_pr, sizeof(cmd_pr) );
    return pr_result;
}

template<typename T>
DWORD linux_read ( WDC_DEVICE_HANDLE device, DWORD bar, uintptr_t address, T *data )
{
   struct acl_cmd driver_cmd;
   driver_cmd.bar_id         = bar;
   driver_cmd.command        = ACLPCI_CMD_DEFAULT;
   driver_cmd.device_addr    = reinterpret_cast<void *>(address);
   driver_cmd.user_addr      = data;
   driver_cmd.size           = sizeof(*data);
   // function invoke linux_read will not write to global memory.
   // So is_diff_endian is always false
   driver_cmd.is_diff_endian = 0;

   return read (device, &driver_cmd, sizeof(driver_cmd));
}

template<typename T>
DWORD linux_write ( WDC_DEVICE_HANDLE device, DWORD bar, uintptr_t address, T data )
{
   struct acl_cmd driver_cmd;
   driver_cmd.bar_id         = bar;
   driver_cmd.command        = ACLPCI_CMD_DEFAULT;
   driver_cmd.device_addr    = reinterpret_cast<void *>(address);
   driver_cmd.user_addr      = &data;
   driver_cmd.size           = sizeof(data);
   // function invoke linux_write will not write to global memory.
   // So is_diff_endian is always false
   driver_cmd.is_diff_endian = 0;

   return write (device, &driver_cmd, sizeof(driver_cmd));
}
