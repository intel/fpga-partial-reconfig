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

//This is a quartus_pgm wrapper that saves the PCIe control registers and then does configuration over JTAG
//This program supports both full chip configuration and Partial reconfiguration over JTAG
//
//without needing to reboot the host computer

//import functions for saving and loading configurations
#include "lib.h"


//PCI IP constants
#include "hw_pcie_constants.h"
#include "version.h"
#include "pcie_linux_driver_exports.h"

int main (int argc, char *argv[]){
    bool pr = false;
    std::string filename = "";
    std::string cable = "1";
    std::string device_index = "1";
    bool slow_jtag=true;

    std::string usage = "usage:\n-pr \t\t\tprogram .RBF using Partial Reconfiguration, will do full chip programming using .SOF by default \n"
            "-f <filename> \t\tthe name of the file to be used\n"
            "-c <cable number> \tthe programmer cable to be used, set to 1 by default\n"
            "-d <device index> \tthe device index to be used, set to 1 by default\n"
            "-h \t\t\thelp/usage\n";

    if (argc == 1)
    {
        std::cout <<"ERROR: a filename must be provided to this program\n\n\n";
        std::cout << usage;
        return 1;
    }
    else
    {
        std::string mystring = argv[1];
    
        if ( ( argc < 3 ) && ( mystring != "-h" ) )
        {
            std::cout <<"ERROR: a filename must be provided to this program\n\n\n";
            std::cout << usage;
            return 1;
        }
        else
        {
            for (int i = 1;i < argc; i++)
            {
                mystring = argv[i];
    
                if (mystring == "-pr")
                {
                    pr = true;
                }
                else if (mystring == "-f")
                {
                    filename = argv[i+1];
                    i++;
                }
                else if (mystring == "-c")
                {
                    cable = argv[i+1];
                    i++;
                }
                else if(mystring == "-d")
                {
                    device_index = argv[i+1];
                    i++;
                }
                else if(mystring == "-h")
                {
                    std::cout << usage;
                    return 0;
                }
                else
                {
                    std::cout << "ERROR: Unrecognized argument\n";
                    std::cout << usage;
                    return 1;
                }
            }
        }
    }
    
    if (std::string(filename) == "")
    {
        std::cout <<"ERROR: a filename must be provided to this program\n\n\n";
        std::cout << usage;
        return 1;
    }

    int dev_num = 0;

    std::cout << "INFO: opening device\n";

    WDC_DEVICE_HANDLE m_device = open_device_linux(dev_num);
    if (m_device == INVALID_DEVICE)
    {
        std::cout << "ERROR: failed to open device, now exiting\n";
        return 1;
    }
    int reprogram_failed = 1;

    std::cout << "INFO: saving pci control registers before programming\n";
    save_pci_control_regs(m_device);

    std::cout << "INFO: disabling interrupts\n";
    //no need to re-enable interrupts after programming is complete
    disable_interrupts(m_device);

    std::cout << "INFO: programming fpga using file name " << filename << " over jtag cable " << cable << " at index " << device_index << "\n";
    reprogram_failed = program_over_jtag(filename, pr, cable, device_index, slow_jtag);

    sleep(2);

    std::cout << "INFO: restoring pci control registers to previous configuration\n";
    load_pci_control_regs(m_device);

    close(m_device);
    std::cout << "INFO: programming complete\n";

    if (reprogram_failed)
    {
        std::cout<< "ERROR: programming failed, try adding the -s flag to slow the JTAG clock to 6M and try again\n";
    }
    return reprogram_failed;
}
