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

//This is a quartus_pgm wrapper that saves the PCIe control registers to allow full chip programming to be done
//without needing to reboot the host computer

//import functions for saving and loading configurations
#include "lib.h"


//PCI IP constants
#include "hw_pcie_constants.h"
#include "version.h"
#include "pcie_linux_driver_exports.h"


int main (int argc, char *argv[]) {
    int dev_num = 0;

    std::cout << "INFO: opening device\n";

    WDC_DEVICE_HANDLE m_device = open_device_linux(dev_num);
    if (m_device == INVALID_DEVICE)
    {
        std::cout << "ERROR: failed to open device, now exiting";
        return 1;
    }

    //
    //  put code here
    //


    // detecting if in verbose debug mode
    int verbose = 0;

    if ( getenv("VERBOSE_DEBUG") )
    {
        verbose = 1;
    }
    else
    {
        verbose = 0;
    }


    //
    int data = 0;
    long int temp = 0;

    // DDRaccess persona register address offset
    // PR_DATA
    int persona_version = 0;

    int PR_DATA = 0x0;
    int PR_CTRL = 0x4;
    int PR_MEM_ADDR = 0x8;
    int PR_PERF_CNTR = 0xC;

    // RegisterFile persona register address offset
    int PR_REGFILE_ADDR = 0x100;
    int PR_REGFILE_SIZE = 0x0ff;

    // BasicArithmetic persona register address offset
    int PR_OPERAND = 0x4;
    int PR_INCR = 0x8;
    int PR_RESULT = 0xC;

    int core_is_busy = 0;

    // variable declaration for DDRaccess Mode 1 testing
    int target_address = 0x12233;
    int limit = 0xf;
    int expected_data = (limit << 8) | 0x01;


    // Detect Persona Version
    linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_DATA, &data );
    persona_version = data & 0xff;
    printf("Persona version is (%#x) \n\n", persona_version);


    if ( persona_version == 0xef )
    {
        printf("\tThis is DDRAccess Persona \n\n");

        data = 0x0;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_MEM_ADDR, data );

        ///////////////////////////////////////////////////////////
        // Reset PR Logic
        data = 0x8;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, data );

        if (verbose == 1)  printf("Assert field sw_reset:       Write PR_CTRL (%#x) is  \t%x\n", PR_CTRL, data) ;
        if (verbose == 1)  printf("The value written is 0x00000008 \n");

        data = 0x0;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, data );
        if (verbose == 1)  printf("Clear field sw_reset:       Write PR_CTRL (%#x) is  \t%x\n", PR_CTRL, data);
        if (verbose == 1)  printf("The value written is 0x00000000 \n");

        // Reset PR Logic Done.
        ///////////////////////////////////////////////////////////

        linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_DATA, &data );
        if (verbose == 1)  printf("To Idendify Persona Version, PLL Locked and calibration siccessful: Read PR_DATA (%#x) is  \t%x\n", PR_DATA, data);
        if (verbose == 1)  printf("Expecting 0x000110ef \n");


        if ( data != 0x000110ef )
        {
            printf("\tERROR! -- PR_DATA value does not match expecting value\n\n");

            printf("\tpr_op_err is         (%#x)\n", (data & 0xf << 8) >> 8);
            printf("\tlocal_cal_success is (%#x)\n", (data & 0x1 << 12) >> 12);
            printf("\tlocal_cal_fail is    (%#x)\n", (data & 0x1 << 13) >> 13);
            printf("\tiopll_locked is data (%#x)\n", (data & 0x1 << 16) >> 16);
            printf("\n\n");
            exit(EXIT_FAILURE);
        }

        ///////////////////////////////////////////////////////////
        //  Testing Mode 1
        ///////////////////////////////////////////////////////////
        if (verbose == 1)  printf("\n\tTesting Mode 1: Reding back a segment of DDR Memory Space \n\n");
        //
        // A dummy read to provide some time
        data = 0x0;
        linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, &data );

        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_MEM_ADDR, target_address );
        if (verbose == 1)    printf("Set an Offset Address of 0x0:       Write PR_MEM_ADDR (%#x) is  \t%x\n", PR_MEM_ADDR, data);
        if (verbose == 1)    printf("The value written is 0x00000000 \n\n");


        // Need a sw_reset to load the new target_address
        data = 0x8;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, data );

        if (verbose == 1)   printf("Assert field sw_reset:       Write PR_CTRL (%#x) is  \t%x\n", PR_CTRL, data);
        if (verbose == 1)   printf("The value written is 0x00000008 \n");


        data = 0x0;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, data );

        if (verbose == 1)   printf("Clear field sw_reset:       Write PR_CTRL (%#x) is  \t%x\n", PR_CTRL, data);
        if (verbose == 1)   printf("The value written is 0x00000000 \n");

        //  A dummy read to provide some time
        data = 0x0;
        linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, &data );
        data = 0x0;
        linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, &data );


        data = (limit << 8) | 0x05;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, data );
        if (verbose == 1)    printf("Start operation, mode=1, limit=f:       Write PR_CTRL (%#x) is  \t%x\n", PR_CTRL, data);
        if (verbose == 1)    printf("The value written is (%#x) \n\n", data);

        data = 0x0;
        linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, &data );
        core_is_busy = (data & 0x1 << 2) >> 2;

        while ( core_is_busy )
        {
            data = 0x0;
            linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, &data );
            core_is_busy = (data & 0x1 << 2) >> 2;
        }

        if (verbose == 1)  printf("Read back PR_CTRL value as a check:     Read PR_CTRL (%#x) is  \t%x\n", PR_CTRL, data);
        if (verbose == 1)  printf("Expecting (%#x) \n", expected_data);

        if ( data != expected_data )
        {
            printf("\tERROR! -- PR_CTRL value does not match expecting value\n\n");

            printf("\tmode is         (%#x)\n", (data & 0x3));
            printf("\tbusy is         (%#x)\n", (data & 0x1 << 2) >> 2);
            printf("\tsw_reset is     (%#x)\n", (data & 0x1 << 3) >> 3);
            printf("\temif_reset is   (%#x)\n", (data & 0x1 << 4) >> 4);
            printf("\tlimit is        (%#x)\n", (data & 0xff << 8) >> 8);
            printf("\n\n");
            exit(EXIT_FAILURE);
        }

        data = 0x0;
        linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_PERF_CNTR, &data );
        if (verbose == 1)    printf("Read back PR_PERF_CNTR value to observe PR_PERF_CNTR:     Read PR_PERF_CNTR (%#x) is  \t%x\n", PR_PERF_CNTR, data);
        if (verbose == 1)    printf("Expecting 0x00000010 \n\n");

        if ( data != (limit + 1) )
        {
            printf("\tERROR in Mode 1! -- PR_PERF_CNTR value does not match expecting value\n\n");
            printf("\tperformance_cntr is         (%#x)\n", (data));
            data = 0x0;
            linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_DATA, &data );
            printf("Read back PR_CTRL value as a check:     Read PR_DATA (%#x) is  \t%x\n", PR_DATA, data);
            printf("\tpr_op_err is         (%#x)\n", (data & 0xf << 8) >> 8);
            printf("\tlocal_cal_success is (%#x)\n", (data & 0x1 << 12) >> 12);
            printf("\tlocal_cal_fail is    (%#x)\n", (data & 0x1 << 13) >> 13);
            printf("\tiopll_locked is data (%#x)\n", (data & 0x1 << 16) >> 16);
            exit(EXIT_FAILURE);
        }
        else
        {
            if (verbose == 1)      printf("\tperformance_cntr is         (%#x)\n", (data));
            printf("Mode 1 PASS\n");
        }

        ///////////////////////////////////////////////////////////
        // Testing Mode 0
        ///////////////////////////////////////////////////////////

        if (verbose == 1)   printf("\n\tTesting Mode 0: Accessing the entire DDR Memory Space \n\n");


        data = 0x0;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_MEM_ADDR, data );

        if (verbose == 1)  printf("Clear the Offset Address :       Write PR_MEM_ADDR (%#x) is  \t%x\n", PR_MEM_ADDR, data);
        if (verbose == 1)  printf("The value written is 0x0 \n\n");


        data = 0x8;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, data );

        if (verbose == 1)  printf("Assert field sw_reset:       Write PR_CTRL (%#x) is  \t%x\n", PR_CTRL, data);
        if (verbose == 1)  printf("The value written is 0x00000008 \n");


        data = 0x0;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, data );

        if (verbose == 1)  printf("Clear field sw_reset:       Write PR_CTRL (%#x) is  \t%x\n", PR_CTRL, data);
        if (verbose == 1)  printf("The value written is 0x00000000 \n");

        //  A dummy read to provide some time
        data = 0x0;
        linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, &data );
        data = 0x0;
        linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, &data );



        data = 0x004;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, data );

        if (verbose == 1)  printf("Start operation, mode=0, limit=0:       Write PR_CTRL (%#x) is  \t%x\n", PR_CTRL, data);
        if (verbose == 1)  printf("The value written is 0x00000004 \n");


        data = 0x0;
        linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, &data );

        if (verbose == 1)  printf("Read back PR_CTRL value as a check:     Read PR_CTRL (%#x) is  \t%x\n", PR_CTRL, data);
        if (verbose == 1)  printf("Expecting 0x00000004 \n");


        core_is_busy = (data & 0x1 << 2) >> 2;

        // Wait while system is busy
        while ( core_is_busy )
        {
            data = 0x0;
            linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, &data );
            core_is_busy = (data & 0x1 << 2) >> 2;
        }



        if (verbose == 1)     printf("\tmode is         (%#x)\n", (data & 0x3));
        if (verbose == 1)     printf("\tbusy is         (%#x)\n", (data & 0x1 << 2) >> 2);
        if (verbose == 1)     printf("\tsw_reset is     (%#x)\n", (data & 0x1 << 3) >> 3);
        if (verbose == 1)     printf("\temif_reset is   (%#x)\n", (data & 0x1 << 4) >> 4);
        if (verbose == 1)     printf("\tlimit is        (%#x)\n", (data & 0xff << 8) >> 8);
        if (verbose == 1)     printf("\n\n");


        data = 0x0;
        linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_PERF_CNTR, &data );

        if (verbose == 1)  printf("Read back PR_PERF_CNTR value to observe PR_PERF_CNTR:     Read PR_PERF_CNTR (%#x) is  \t%x\n", PR_PERF_CNTR, data);
        if (verbose == 1)  printf("Expecting 0x04000000 \n");


        if ( data != 0x400000 )
        {
            printf("\tERROR in Mode 0! -- PR_PERF_CNTR value does not match expecting value\n\n");
            printf("\tperformance_cntr is         (%#x)\n", (data));
            data = 0x0;
            linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_DATA, &data );
            printf("Read back PR_CTRL value as a check:     Read PR_DATA (%#x) is  \t%x\n", PR_DATA, data);
            printf("\tpr_op_err is         (%#x)\n", (data & 0xf << 8) >> 8);
            printf("\tlocal_cal_success is (%#x)\n", (data & 0x1 << 12) >> 12);
            printf("\tlocal_cal_fail is    (%#x)\n", (data & 0x1 << 13) >> 13);
            printf("\tiopll_locked is data (%#x)\n", (data & 0x1 << 16) >> 16);
            exit(EXIT_FAILURE);
        }
        else
        {
            if (verbose == 1)     printf("\tperformance_cntr is         (%#x)\n", (data));
            printf("Mode 0 PASS\n");
        }

        if (verbose == 1)   printf("\tperformance_cntr is         (%#x)\n", (data));
        if (verbose == 1)   printf("\n\n");
    }
    else if ( persona_version == 0xce )
    {
        printf("\tThis is RegisterFile Persona \n\n");

        if (verbose == 1)  printf("Read Register, Write back, Read modified value\n");

        // Reset PR Logic
        if (verbose == 1)  printf("Reset PR Logic\n");
        data = 0x0;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, data );

        data = 0x1;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, data );

        data = 0x0;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, data );



        int reference_data = 0;

        for (int i = PR_REGFILE_ADDR; i <= PR_REGFILE_ADDR + PR_REGFILE_SIZE; i += 4)
        {
            data = 0x0;
            linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, i, &data );
            if (verbose == 1)      printf("Read Reg File address (%#x) :  \t%x\n", i, data);
            if (verbose == 1)      printf("Expecting 0x00000000 \n\n");
            if ( (unsigned int) data != 0x00000000)
            {
                printf("Read back of reset value at address (%#x) failed\n", i);
                exit(EXIT_FAILURE);
            }

            reference_data = i ^ 0xffffffff;
            linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, i, reference_data );
            if (verbose == 1)     printf("Modify Reg at address (%#x) writing :  \t%x\n", i, reference_data);

            data = 0x0;
            linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, i, &data );
            if (verbose == 1)      printf("Read Reg File address (%#x) :  \t%x\n", i, data);
            if (verbose == 1)      printf("Expecting (%#x) value \n\n", reference_data);
        }

        if (verbose == 1)  printf("Reset the design\n");
        data = 0x0;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, data );

        data = 0x1;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, data );

        data = 0x0;
        if (verbose == 1) printf("Read back PR_CTRL and observe HW cleared the sw_reset bit after completing the reset task\n");
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_CTRL, data );


        if (verbose == 1)  printf("Read Registers and observe the reset value of 0x00000000\n");

        for (int i = PR_REGFILE_ADDR; i <= PR_REGFILE_ADDR + PR_REGFILE_SIZE; i += 4)
        {
            data = 0x0;
            linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, i, &data );
            if (verbose == 1)      printf("Read Reg File address (%#x) :  \t%x\n", i, data);
            if (verbose == 1)      printf("Expecting 0x00000000 \n\n");
            if ( 0x00000000 != (unsigned int) data )
            {
                printf("Read back of reset value at address (%#x) failed\n", i);
                exit(EXIT_FAILURE);
            }
        }
        printf("RegisterFile persona PASS\n");
    }
    else if ( persona_version == 0xd2 )
    {
        printf("\tThis is BasicArithmetic Persona \n\n");

        data = 0xa5a5;
        if (verbose == 1)  printf("Write to PR_OPERAND value: 0xa5a5\n");
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_OPERAND, data );

        data = 0x5a5a;
        if (verbose == 1)   printf("Write to PR_INCR value:    0x5a5a\n");
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_INCR, data );

        data = 0x0;
        linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, PR_RESULT, &data );
        if (verbose == 1)   printf("Read PR_RESULT value (%#x) :  \t%#x\n", PR_RESULT, data);
        if (verbose == 1)   printf("Expecting 0xffff \n\n");
        if ( 0xffff != data )
        {
            printf("Read back of Result value failed: (%#x) failed\n", data);
            exit(EXIT_FAILURE);
        }
        printf("BasicArithmetic persona PASS\n");
    }
    else if (persona_version == 0xed)
    {

        printf("\t This is the template example persona\n\n");
        data = 0;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, 0x10, data );
        data = 1;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, 0x10, data );
        data = 0;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, 0x10, data );
        
        data = 0;
        linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, 0xa0, &data );
        printf("Read back of Result value : (%#x)\n", data);
        data = 0;
        linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, 0xb0, &data );
        printf("Read back of Result value : (%#x)\n", data);
        data = 0x5a5;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, 0xa0, data );

        data = 0xa5a;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, 0xb0, data );

        temp = 0;
        linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, 0x30, &data );
        temp = data;
        temp = temp <<  32;
        data = 0;
        linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, 0x20, &data );
        temp = temp + data;
        if (temp != (long int)(0x5a5 * 0xa5a)) {
            printf("Read back of Result value failed: (%#lx) failed\n", temp);
            exit(EXIT_FAILURE);
        }
        printf("PASS Case 1\n");
        data = 0x1ccc;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, 0xa0, data );
        data = 0x1ddd;
        linux_write (m_device, ACL_PCI_GLOBAL_MEM_BAR, 0xb0, data );

        temp = 0;
        linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, 0x30, &data );
        temp = data;
        temp = temp <<  32;
        linux_read (m_device, ACL_PCI_GLOBAL_MEM_BAR, 0x20, &data );
        temp = temp + data;
        if (temp != (unsigned long int)(0x1ccc * 0x1ddd)) {
            printf("Read back of Result value failed: (%#lx) failed\n", temp);
            exit(EXIT_FAILURE);
        }
        printf("PASS Case 2\n");
    }
    else
    {
        printf("\tThis is an unknown Persona \n\n");
        exit(EXIT_FAILURE);
    }

    //
    //  put code here
    //
    //
    //
    //
    //
    //
    //
    //
    //
    //
    //
    //
    //
    //
    std::cout << "INFO: closing device\n";
    close(m_device);
    return 0;
}
