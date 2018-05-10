// Copyright (c) 2001-2018 Intel Corporation
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

`timescale 1 ps / 1 ps
`default_nettype none

`include "altr_cmn_macros.sv"

module testbench();


//==================================================================================================
// Parameters
//==================================================================================================
//DUT

covergroup cg_input_parametrization;

endgroup: cg_input_parametrization

cg_input_parametrization input_parametrization;


//==================================================================================================
// Local Signals
//==================================================================================================

// BFM Wires

// BFM -> Monitor
wire bfm_bar4_avmm_waitrequest;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_DATA_W-1:0] bfm_bar4_avmm_readdata;
wire bfm_bar4_avmm_readdatavalid;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_BURSTCOUNT_W-1:0] bfm_bar4_avmm_burstcount;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_DATA_W-1:0] bfm_bar4_avmm_writedata;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_ADDRESS_W-1:0] bfm_bar4_avmm_address;
wire bfm_bar4_avmm_write;
wire bfm_bar4_avmm_read;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_NUMSYMBOLS-1:0] bfm_bar4_avmm_byteenable;

// Monitor -> DUT
wire dut_bar4_avmm_waitrequest;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_DATA_W-1:0] dut_bar4_avmm_readdata;
wire dut_bar4_avmm_readdatavalid;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_BURSTCOUNT_W-1:0] dut_bar4_avmm_burstcount;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_DATA_W-1:0] dut_bar4_avmm_writedata;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_ADDRESS_W-1:0] dut_bar4_avmm_address;
wire dut_bar4_avmm_write;
wire dut_bar4_avmm_read;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR4_BFM_AV_NUMSYMBOLS-1:0] dut_bar4_avmm_byteenable;
wire dut_bar4_avmm_debugaccess;

// BFM -> Monitor
wire bfm_bar2_avmm_waitrequest;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_DATA_W-1:0] bfm_bar2_avmm_readdata;
wire bfm_bar2_avmm_readdatavalid;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_BURSTCOUNT_W-1:0] bfm_bar2_avmm_burstcount;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_DATA_W-1:0] bfm_bar2_avmm_writedata;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_ADDRESS_W-1:0] bfm_bar2_avmm_address;
wire bfm_bar2_avmm_write;
wire bfm_bar2_avmm_read;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_NUMSYMBOLS-1:0] bfm_bar2_avmm_byteenable;

// Monitor -> DUT
wire dut_bar2_avmm_waitrequest;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_DATA_W-1:0] dut_bar2_avmm_readdata;
wire dut_bar2_avmm_readdatavalid;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_BURSTCOUNT_W-1:0] dut_bar2_avmm_burstcount;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_DATA_W-1:0] dut_bar2_avmm_writedata;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_ADDRESS_W-1:0] dut_bar2_avmm_address;
wire dut_bar2_avmm_write;
wire dut_bar2_avmm_read;
wire [design_top_sim_cfg_pkg::DESIGN_TOP_BAR2_BFM_AV_NUMSYMBOLS-1:0] dut_bar2_avmm_byteenable;
wire dut_bar2_avmm_debugaccess;

wire ddr4_waitrequest;
wire [127:0] ddr4_readdata;
wire ddr4_readdatavalid;
wire [6:0] ddr4_burstcount;
wire [127:0] ddr4_writedata;
wire [24:0] ddr4_address;
wire ddr4_write;
wire ddr4_read;
wire [15:0] ddr4_byteenable;

// Clock and reset
logic tb_clk;
logic nreset;


//==================================================================================================
// BAR4 Driver BFM
//==================================================================================================
// -------------------------------------------------------------------
// Instantiate avalon_mm master bfm
// -------------------------------------------------------------------
bar4_avalon_mm_master_bfm bar4_avmm_bfm
(
 .clk                      (tb_clk),                
 .reset                    (~nreset),         
 .avm_address              (bfm_bar4_avmm_address),      
 .avm_readdata             (bfm_bar4_avmm_readdata),     
 .avm_writedata            (bfm_bar4_avmm_writedata),    
 .avm_write                (bfm_bar4_avmm_write),        
 .avm_read                 (bfm_bar4_avmm_read),         
 .avm_burstcount           (bfm_bar4_avmm_burstcount),                                
 .avm_waitrequest          (bfm_bar4_avmm_waitrequest),         
 .avm_byteenable           (bfm_bar4_avmm_byteenable),                                
 .avm_readdatavalid        (bfm_bar4_avmm_readdatavalid)
 );


//==================================================================================================
// BAR4 Monitor BFM
//==================================================================================================
// -------------------------------------------------------------------
// Instantiate avalon_mm monitor bfm
// -------------------------------------------------------------------
bar4_avalon_mm_monitor_bfm bar4_avmm_monitor
(
 .clk                      (tb_clk),                
 .reset                    (~nreset),         

 .avs_address              (bfm_bar4_avmm_address),      
 .avs_readdata             (bfm_bar4_avmm_readdata),     
 .avs_writedata            (bfm_bar4_avmm_writedata),    
 .avs_write                (bfm_bar4_avmm_write),        
 .avs_read                 (bfm_bar4_avmm_read),         
 .avs_burstcount           (bfm_bar4_avmm_burstcount),                                
 .avs_waitrequest          (bfm_bar4_avmm_waitrequest),         
 .avs_byteenable           (bfm_bar4_avmm_byteenable),                                
 .avs_readdatavalid        (bfm_bar4_avmm_readdatavalid),          

 .avm_address              (dut_bar4_avmm_address),      
 .avm_readdata             (dut_bar4_avmm_readdata),     
 .avm_writedata            (dut_bar4_avmm_writedata),    
 .avm_write                (dut_bar4_avmm_write),        
 .avm_read                 (dut_bar4_avmm_read),         
 .avm_burstcount           (dut_bar4_avmm_burstcount),                                
 .avm_waitrequest          (dut_bar4_avmm_waitrequest),         
 .avm_byteenable           (dut_bar4_avmm_byteenable),                                
 .avm_readdatavalid        (dut_bar4_avmm_readdatavalid)
 );

//==================================================================================================
// BAR2 Driver BFM
//==================================================================================================
// -------------------------------------------------------------------
// Instantiate avalon_mm master bfm
// -------------------------------------------------------------------
bar2_avalon_mm_master_bfm bar2_avmm_bfm
(
 .clk                      (tb_clk),                
 .reset                    (~nreset),         
 .avm_address              (bfm_bar2_avmm_address),      
 .avm_readdata             (bfm_bar2_avmm_readdata),     
 .avm_writedata            (bfm_bar2_avmm_writedata),    
 .avm_write                (bfm_bar2_avmm_write),        
 .avm_read                 (bfm_bar2_avmm_read),         
 .avm_burstcount           (bfm_bar2_avmm_burstcount),                                
 .avm_waitrequest          (bfm_bar2_avmm_waitrequest),         
 .avm_byteenable           (bfm_bar2_avmm_byteenable),                                
 .avm_readdatavalid        (bfm_bar2_avmm_readdatavalid)
 );


//==================================================================================================
// BAR2 Monitor BFM
//==================================================================================================
// -------------------------------------------------------------------
// Instantiate avalon_mm monitor bfm
// -------------------------------------------------------------------
bar2_avalon_mm_monitor_bfm bar2_avmm_monitor
(
 .clk                      (tb_clk),                
 .reset                    (~nreset),         

 .avs_address              (bfm_bar2_avmm_address),      
 .avs_readdata             (bfm_bar2_avmm_readdata),     
 .avs_writedata            (bfm_bar2_avmm_writedata),    
 .avs_write                (bfm_bar2_avmm_write),        
 .avs_read                 (bfm_bar2_avmm_read),         
 .avs_burstcount           (bfm_bar2_avmm_burstcount),                                
 .avs_waitrequest          (bfm_bar2_avmm_waitrequest),         
 .avs_byteenable           (bfm_bar2_avmm_byteenable),                                
 .avs_readdatavalid        (bfm_bar2_avmm_readdatavalid),          

 .avm_address              (dut_bar2_avmm_address),      
 .avm_readdata             (dut_bar2_avmm_readdata),     
 .avm_writedata            (dut_bar2_avmm_writedata),    
 .avm_write                (dut_bar2_avmm_write),        
 .avm_read                 (dut_bar2_avmm_read),         
 .avm_burstcount           (dut_bar2_avmm_burstcount),                                
 .avm_waitrequest          (dut_bar2_avmm_waitrequest),         
 .avm_byteenable           (dut_bar2_avmm_byteenable),                                
 .avm_readdatavalid        (dut_bar2_avmm_readdatavalid)
 );

//==================================================================================================
// DDR4 Model
//==================================================================================================
ddr4_memory_simulation ddr4
(
 .clk(tb_clk),
 .rst_n(nreset),
 .avmm_waitrequest(ddr4_waitrequest),
 .avmm_readdata(ddr4_readdata),
 .avmm_readdatavalid(ddr4_readdatavalid),
 .avmm_burstcount(ddr4_burstcount),
 .avmm_writedata(ddr4_writedata),
 .avmm_address(ddr4_address),
 .avmm_write(ddr4_write),
 .avmm_read(ddr4_read),
 .avmm_byteenable(ddr4_byteenable)
 );
//==================================================================================================
// DUT
//==================================================================================================


design_top dut
(
 .bar_avmm_reset_reset_n(nreset),
 .emif_usr_reset_n_reset_n(nreset),
 .emif_global_rst_n_reset_n(),

 .pll_refclk_clk(tb_clk),
 .bar_avmm_clk_clk(tb_clk),
 .emif_usr_clk_clk(tb_clk),

 .bar2_avmm_waitrequest(dut_bar2_avmm_waitrequest),
 .bar2_avmm_readdata(dut_bar2_avmm_readdata),
 .bar2_avmm_readdatavalid(dut_bar2_avmm_readdatavalid),
 .bar2_avmm_burstcount(dut_bar2_avmm_burstcount),
 .bar2_avmm_writedata(dut_bar2_avmm_writedata),
 .bar2_avmm_address(dut_bar2_avmm_address),
 .bar2_avmm_write(dut_bar2_avmm_write),
 .bar2_avmm_read(dut_bar2_avmm_read),
 .bar2_avmm_byteenable(dut_bar2_avmm_byteenable),
 .bar2_avmm_debugaccess(dut_bar2_avmm_debugaccess),

 .bar4_avmm_waitrequest(dut_bar4_avmm_waitrequest),
 .bar4_avmm_readdata(dut_bar4_avmm_readdata),
 .bar4_avmm_readdatavalid(dut_bar4_avmm_readdatavalid),
 .bar4_avmm_burstcount(dut_bar4_avmm_burstcount),
 .bar4_avmm_writedata(dut_bar4_avmm_writedata),
 .bar4_avmm_address(dut_bar4_avmm_address),
 .bar4_avmm_write(dut_bar4_avmm_write),
 .bar4_avmm_read(dut_bar4_avmm_read),
 .bar4_avmm_byteenable(dut_bar4_avmm_byteenable),
 .bar4_avmm_debugaccess(dut_bar4_avmm_debugaccess),

 .emif_avmm_m0_waitrequest(ddr4_waitrequest),
 .emif_avmm_m0_readdata(ddr4_readdata),
 .emif_avmm_m0_readdatavalid(ddr4_readdatavalid),
 .emif_avmm_m0_burstcount(ddr4_burstcount),
 .emif_avmm_m0_writedata(ddr4_writedata),
 .emif_avmm_m0_address(ddr4_address),
 .emif_avmm_m0_write(ddr4_write),
 .emif_avmm_m0_read(ddr4_read),
 .emif_avmm_m0_byteenable(ddr4_byteenable),
 .emif_avmm_m0_debugaccess(),

 .emif_status_local_cal_fail(1'b0),
 .emif_status_local_cal_success(1'b1)
 );

reset_if reset_bfm (tb_clk);
assign nreset = ~reset_bfm.reset;

reset_watchdog_if dut_reset_watchdog_if(tb_clk);
assign dut_reset_watchdog_if.reset = ~dut.global_rst_n_controller.global_rst_n;


//==================================================================================================
// clk and reset
//==================================================================================================

// Clock generators
initial begin
   tb_clk <= 1'b0;
   forever
      #1 tb_clk <= ~tb_clk;
end

initial begin
`ifdef ENABLE_VCS_DEBUG
   // Enable debugging
   $vcdplusdeltacycleon();
   $vcdpluson();
`ifdef ENABLE_VCS_MEM_DEBUG
   $vcdplusmemon();
`endif
`endif

   // Register the interfaces to the BFMs
   `altr_set_if(virtual reset_if, "testbench", "reset_bfm", reset_bfm)
   `altr_set_if(virtual reset_watchdog_if, "testbench", "dut_reset_watchdog_if", dut_reset_watchdog_if)
   `altr_set_if(virtual bar4_avalon_mm_master_bfm, "testbench", "bar4_avmm_bfm", bar4_avmm_bfm)
   `altr_set_if(virtual bar4_avalon_mm_monitor_bfm, "testbench", "bar4_avmm_monitor", bar4_avmm_monitor)
   `altr_set_if(virtual bar2_avalon_mm_master_bfm, "testbench", "bar2_avmm_bfm", bar2_avmm_bfm)
   `altr_set_if(virtual bar2_avalon_mm_monitor_bfm, "testbench", "bar2_avmm_monitor", bar2_avmm_monitor)

   // Register the PR region IF
   //`altr_set_if(virtual altera_pr_persona_if, "testbench", "pr_region0", dut.pr_region_wrapper.pr_persona_wrapper.persona_bfm)

   // Run the test
   uvm_pkg::run_test("flat_basic_arith");
end

// Sample the input parameterization
initial begin
   input_parametrization = new();
   input_parametrization.sample();
end

endmodule
