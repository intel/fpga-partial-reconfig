# Intel&reg; FPGA Partial Reconfiguration Design Flow

This repository contains scripts, reference designs, and tutorials for the Intel FPGA Partial Reconfiguration design flow.

- [Tutorials](tutorials/) are located in the tutorials sub directory
- [Reference Designs](ref_designs/) are located in the ref_designs sub directory
- [Software](software/) and Linux drivers are located in the software sub directory 
- [Scripts](scripts/) are located in the scripts sub directory
- [Verification](verification/) components for simulation are located in the verification sub directory

The Partial Reconfiguration Design Flow is supported in the Intel Quartus Prime&reg; Pro Edition software for Intel Arria 10 Devices with the following key features:

   - Command line and graphical user interface for compilation and analysis
   - Hierarchical Partial Reconfiguration that allows you to create child PR partitions in your design
   - Simulation of Partial Reconfiguration that allows you to observe the resulting change and the intermediate effect in a reconfiguration partition
   - Signal Tap debug with simultaneous acquisition of both the Static region and Partial Reconfiguration regions
   - Quartus Prime documentation for *Creating a Partial Reconfiguration Design* is available in the [Quartus Prime Pro Edition Handbook Volume 1](https://www.altera.com/content/dam/altera-www/global/en_US/pdfs/literature/hb/qts/qts-qpp-5v1.pdf)
   - Refer to the [Partial Reconfiguration Solutions IP User Guide](https://www.altera.com/content/dam/altera-www/global/en_US/pdfs/literature/ug/ug-20066.pdf) for information about the Intel FPGA Partial Reconfiguration IP cores


[Releases](https://github.com/01org/fpga-partial-reconfig/releases) are created for each major version of Quartus Prime Software. It is recommended to use the release for your version of Quartus Prime.


![PR Logo](quartus-prime-partial-reconfiguration-diagram.jpg?raw=true)

More information available at [http://www.01.org/fpga-partial-reconfig](http://www.01.org/fpga-partial-reconfig)
