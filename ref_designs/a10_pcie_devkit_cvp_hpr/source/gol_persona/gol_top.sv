`timescale 1 ps / 1 ps
`default_nettype none

module gol_top #(parameter REG_FILE_IO_SIZE = 8) 
(
   //clock
   input wire          clk ,
   input wire          pr_logic_rst ,
   output reg          clr_io_reg ,
   //Persona identification register, used by host in host program
   output reg [31:0]   persona_id ,
   //Host control register, used for control signals.
   input wire [31:0]   host_cntrl_register ,
   // 8 registers for host -> PR logic communication
   input wire [31:0]   host_pr [0:REG_FILE_IO_SIZE-1],
   // 8 Registers for PR logic -> host communication
   output wire [31:0]  pr_host [0:REG_FILE_IO_SIZE-1],
   // DDR4 interface
   input wire          emif_avmm_waitrequest , 
   input wire [511:0]  emif_avmm_readdata , 
   input wire          emif_avmm_readdatavalid ,
   output reg [6:0]    emif_avmm_burstcount , 
   output reg [511:0]  emif_avmm_writedata , 
   output reg [24:0]   emif_avmm_address , 
   output reg          emif_avmm_write , 
   output reg          emif_avmm_read , 
   output reg [63:0]   emif_avmm_byteenable       
);

   always_comb
   begin
      emif_avmm_burstcount  = 5'b0;
      emif_avmm_writedata   = 512'b0;
      emif_avmm_address     = 31'b0;
      emif_avmm_write       = 1'b0;
      emif_avmm_read        = 1'b0;
      emif_avmm_byteenable  = 64'b0;
   end
   moderator wrapper
   (
      .clk                 ( clk ),             
      .pr_logic_rst        ( pr_logic_rst ),
      .clr_io_reg          ( clr_io_reg ),
      .persona_id          ( persona_id ), 
      .host_cntrl_register ( host_cntrl_register ), 
      .host_pr             ( host_pr ),
      .pr_host             ( pr_host )
   );




endmodule
