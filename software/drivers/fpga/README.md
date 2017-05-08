The FPGA-PCIe driver features an up-streamed driver for the Intel FPGA Partial Reconfiguration IP.  The driver for the Intel FPGA PR IP works with the upstreamed FPGA Manager linux framework to allow reprogramming of a Partial Reconfiguration FPGA region while linux is running.  In order to facilitate bringup of fpga designs for PR regions, the FPGA-PCIe driver exports the address space of the PR region via the linux UIO framework.  

The provided example host program demonstrates how easy it is to access the FPGA region's address space from user-level program.

