# Arria 10 Hierarchical Partial Reconfiguration over PCIe Reference Design

This readme file accompanies the Arria 10 PR over PCIe reference design using hierarchical partial reconfiguration (HPR) for the Arria 10 GX FPGA Development Kit. This version of the design has been verified using Quartus Prime Pro v18.0.0.

This readme file contains the following information:

*  Design Description
*  Technical Documentation
*  System Requirements
  

## Design Description

* This design targets the Arria 10 GX PCIe development kit with the following features:
   * PCIe Gen 3 x8 support
   * DDR4 EMIF with 2GB of supported space
   * 8KB of mapped memory for use within the PR design core
   * All necessary interface and communication for each component of the design
   * Templates for extending the reference design to instantiate ones own logic
   * Linux driver with upstreamed components
   * Host side programming utilities for full chip and partial reconfiguration, with full driver support
   * Host side example application that demo's the design
   * Example personas with floorplans to accommodate 2 HPR children
      * Both children have region controllers contained within their parent persona, and are controlled independentl

* This version of the design includes the following PR personas:
   * DDR4 Access:
     * Sweeps from a set of specified addresses, writing and then reading randomly generated data
   * Basic DSP:
     * 27x27 Unsigned multiplier with signal tap logic inserted for supporting on chip debugging of a PR persona
   * Basic Arithmetic:
     * Performs 32 bit unsigned addition
   * GOL
     * Hardware accleration of Conways GOL, 8x8 grid with full wrap around
     * The example host also performs the same calculations and compares the time of both results

## Technical Documentation

*  AN-813.pdf Application Note provides information about the reference design, and walks you through using the design.
   *  This document is available on the GitHub: [here](AN-813.pdf)

## System Requirements

*  Quartus Prime Pro Edition software version 18.0
*  [Arria 10 GX FPGA Development Kit](https://www.altera.com/products/boards_and_kits/dev-kits/altera/kit-a10-gx-fpga.html)
