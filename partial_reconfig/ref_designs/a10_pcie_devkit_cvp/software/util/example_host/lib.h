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

#ifndef LIB_H
#define LIB_H
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <unistd.h>
#include <fcntl.h>
#include <string>
#include <iostream>
#include "pcie_linux_driver_exports.h"

//define some needed data types
typedef unsigned int        uintptr_t;
typedef unsigned int        DWORD;
typedef unsigned long long  QWORD;
#define INVALID_DEVICE (-1)

typedef ssize_t WDC_DEVICE_HANDLE;

int save_pci_control_regs(WDC_DEVICE_HANDLE m_device);

int load_pci_control_regs(WDC_DEVICE_HANDLE m_device);

WDC_DEVICE_HANDLE open_device_linux(int dev_num);

bool program_over_jtag(const std::string& filename, bool use_sof, const std::string& cable, const std::string& device_index, bool slow_jtag);

int disable_interrupts(WDC_DEVICE_HANDLE m_device);

int program_core_with_PR ( WDC_DEVICE_HANDLE device, char *core_bitstream, size_t core_rbf_len);


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


#endif // LIB_H
