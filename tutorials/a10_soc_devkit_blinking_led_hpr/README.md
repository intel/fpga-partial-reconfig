# Arria 10 Blinking LED Hierarchical Partial Reconfiguration Tutorial for the Arria 10 SoC Development Kit

This readme file accompanies the Arria 10 Blinking LED Hierarchical Partial Reconfiguration (PR) Tutorial for the Arria 10 SoC Development Kit. This directory contains the design files for the Hierarchical PR (HPR) tutorial. This version of the design has been verified using Quartus Prime Pro v17.0.

This readme file contains the following information:

*  Arria 10 Blinking LED Partial Reconfiguration Tutorial Contents--lists the contents of this tutorial.
*  Technical Documentation--directs you where to find documentation for Arria 10 Blinking LED Partial Reconfiguration and HPR walkthrough.
*  System Requirements--lists the system requirements.

## Arria 10 Blinking LED Partial Reconfiguration Tutorial Contents

*  **flat/** - This directory contains the *flat* version of the design. The following are the design files available in this folder:
	* top.sv--top-level file containing the flat implementation of the design.
	* blinking_led.sdc--defines the timing constraints for the project.
	* blinking_led.sv--System Verilog file that causes the LEDs to blink using a 32-bit counter.
	* blinking_led.qpf--Quartus Prime project file containing the base revision information.
	* blinking_led.qsf--Quartus Prime settings file containing the assignments and settings for the project.

*  **hpr/** - This directory contains the hierarchical PR version of the design. The following are the complete set of files you will be creating with this tutorial:

## Technical Documentation

*  AN-???.pdf Application Note provides information about the hierarchical PR tutorial, and walks you through partially reconfiguring a flat design using HPR.

## System Requirements

*  Quartus Prime Pro Edition software version 17.0
*  [Arria 10 SoC development kit](https://www.altera.com/products/boards_and_kits/dev-kits/altera/arria-10-soc-development-kit.html)

