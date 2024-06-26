# Signal Tap Tutorial for Intel Agilex 7 Partial Reconfiguration Designs

This readme file accompanies the Signal Tap Tutorial for Intel Agilex 7 Partial Reconfiguration Design. This directory contains the design files for the PR + signal tap tutorial. This version of the design has been verified using Quartus Prime Pro v23.3.

This readme file contains the following information:

*  Signal Tap Tutorial for Intel Agilex 7 Partial Reconfiguration Design Contents--lists the contents of this tutorial.
*  Technical Documentation--directs you where to find documentation for Agilex 7 Blinking LED Partial Reconfiguration walkthrough.
*  System Requirements--lists the system requirements.

## Signal Tap Tutorial for Intel Agilex Partial Reconfiguration Design Contents

*  **start/** - This directory contains the *flat* version of the design. The following are the design files available in this folder:
	* top.sv--top-level file containing the flat implementation of the design.
	* blinking_led.sdc--defines the timing constraints for the project.
	* top_counter.sv--System Verilog file that causes the LEDs to blink using a 32-bit counter.
	* blinking_led.sv--System Verilog file that causes the LEDs to blink using a 32-bit counter.
	* blinking_led.qpf--Quartus Prime project file containing the base revision information.
	* blinking_led.qsf--Quartus Prime settings file containing the assignments and settings for the project.
	* blinking_led_default.qsf--Quartus Prime settings file containing the assignments and settings for the blinking_led_default persona.
	* blinking_led_empty.qsf--Quartus Prime project file containing the assignments and settings for blinking_led_empty persona.
	* blinking_led_empty.sv--System Verilog file that causes the LEDs to stay ON.	
	* blinking_led_slow.qsf--Quartus Prime project file containing the assignments and settings for blinking_led_slow persona.
	* blinking_led_slow.sv--System Verilog file that causes the LEDs to blink slower.

*  **finish/** - This directory contains the traditional PR + Signal Tap version of the design. The following are the complete set of files you will be creating with this tutorial:
	* blinking_led.sv--System Verilog file that causes the LEDs to blink using a 32-bit counter.
	* top_counter.sv--System Verilog file that causes the LEDs to blink using a 32-bit counter.
	* blinking_led.qpf--Quartus Prime project file containing the synthesis revision information for the personas.
	* blinking_led.qsf--Quartus Prime settings file containing the assignments and settings for the PR project.
	* blinking_led.sdc--Defines the timing constraints for the PR project.
	* blinking_led_default.qsf--Quartus Prime settings file containing the assignments and settings for the blinking_led_default persona.
	* blinking_led_empty.qsf--Quartus Prime project file containing the assignments and settings for blinking_led_empty persona.
	* blinking_led_empty.sv--System Verilog file that causes the LEDs to stay ON.	
	* blinking_led_slow.qsf--Quartus Prime project file containing the assignments and settings for blinking_led_slow persona.
	* blinking_led_slow.sv--System Verilog file that causes the LEDs to blink slower.
	* top.sv--top-level file containing the PR implementation of the design.
	* sld_agent.ip--IP variation file for instantiating SLD JTAG Bridge Agent Intel FPGA IP in the design
	* sld_host.ip--IP variation file for instantiating SLD JTAG Bridge Host Intel FPGA IP in the design
	* reset_release.ip--IP variation file for instantiating Reset Release Intel FPGA IP in the design
	* config_reset_release_endpoint.ip--IP variation file for instantiating Intel Configuration Reset Release Endpoint to Debug Logic IP in the design
	* stp_default.stp--The signal tap file for the default persona
	* stp_empty.stp--The signal tap file for the empty persona
	* stp_slow.stp--The signal tap file for the slow persona
	
## Technical Documentation

*  AN-964.pdf Application Note provides information about the debugging traditional PR using signal tap tutorial, and walks you through debugging a PR design.
   *  This document is available on the GitHub: [here](AN-964.pdf)

## System Requirements

*  Quartus Prime Pro Edition software version 23.3
*  [Agilex 7 FPGA Development Kit](https://www.intel.com/content/www/us/en/products/details/fpga/development-kits/agilex.html)

