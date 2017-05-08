# Arria 10 Blinking LED Partial Reconfiguration Tutorial and Hierarchical Partial Reconfiguration Tutorial for the Arria 10 GX FPGA Development Kit

This readme file accompanies the Arria 10 Blinking LED Partial Reconfiguration Tutorial for the Arria 10 GX FPGA Development Kit. This directory contains the design files for the traditional PR and Hierarchical PR (HPR) tutorials. This version of the design has been verified using Quartus Prime Pro v17.0.

This readme file contains the following information:

*  Arria 10 Blinking LED Partial Reconfiguration Tutorial Contents--lists the contents of this tutorial.
*  Technical Documentation--directs you where to find documentation for Arria 10 Blinking LED Partial Reconfiguration and HPR walkthrough.
*  System Requirements--lists the system requirements.

## Arria 10 Blinking LED Partial Reconfiguration Tutorial Contents

*  **flat/** - This directory contains the *flat* version of the reference design. The following are the design files available in this folder:
	* top.sv--top-level file containing the flat implementation of the design.
	* blinking_led.sdc--defines the timing constraints for the project.
	* blinking_led.sv--System Verilog file that causes the LEDs to blink using a 32-bit counter.
	* blinking_led.qpf--Quartus Prime project file containing the base revision information.
	* blinking_led.qsf--Quartus Prime settings file containing the assignments and settings for the project.

*  **pr/** - This directory contains the traditional PR version of the reference design. The following are the complete set of files you will be creating with this tutorial:
	* blinking_led.sv--System Verilog file that causes the LEDs to blink using a 32-bit counter.
	* blinking_led.qpf--Quartus Prime project file containing the synthesis revision information for the personas.
	* blinking_led.qsf--Quartus Prime settings file containing the assignments and settings for the PR project.
	* blinking_led.sdc--Defines the timing constraints for the PR project.
	* blinking_led_default.qsf--Quartus Prime settings file containing the assignments and settings for the blinking_led_default persona.
	* blinking_led_empty.qsf--Quartus Prime project file containing the assignments and settings for blinking_led_empty persona.
	* blinking_led_empty.sv--System Verilog file that causes the LEDs to stay ON.
	* blinking_led_pr_alpha.qsf--Quartus Prime settings file containing the assignments and settings for the blinking_led project.
	* blinking_led_pr_bravo.qsf--Quartus Prime settings file containing the assignments and settings for the blinking_led project.
	* blinking_led_pr_charlie.qsf--Quartus Prime settings file containing the assignments and settings for the blinking_led project.
	* blinking_slow_led.qsf--Quartus Prime project file containing the assignments and settings for blinking_led_slow persona.
	* blinking_slow_led.sv--System Verilog file that causes the LEDs to blink slower.
	* jtag.sdc--Timing constraints for JTAG
	* pr_ip.ip--IP variation file for instantiating PR IP core in the design
	* setup.tcl--contains configuration for the a10_partial_reconfig.tcl flow script   
	* top.sv--top-level file containing the PR implementation of the design.

*  **hpr/** - This directory contains the hierarchical PR (HPR) version of the reference design. The following are the complete set of files you will be creating with this tutorial:

## Technical Documentation

*  AN-797.pdf Application Note provides information about the traditional PR tutorial, and walks you through partially reconfiguring a flat design.
   *  This document is available on the GitHub: [here](AN-797.pdf)
*  AN-???.pdf Application Note provides information about the hierarchical PR tutorial, and walks you through partially reconfiguring a flat design using HPR.


## System Requirements

*  Quartus Prime Pro Edition software version 17.0
*  [Arria 10 GX FPGA Development Kit](https://www.altera.com/products/boards_and_kits/dev-kits/altera/kit-a10-gx-fpga.html)

