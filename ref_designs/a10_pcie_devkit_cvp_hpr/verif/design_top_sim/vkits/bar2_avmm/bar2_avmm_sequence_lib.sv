`ifndef INC_BAR2_AVMM_SEQUENCE_LIB_SV
`define INC_BAR2_AVMM_SEQUENCE_LIB_SV

class bar2_avmm_base_seq_c extends avmm_pkg::avmm_base_seq_c #(bar2_avmm_pkg::bar2_avmm_command_seq_item_c);
   `uvm_object_utils(bar2_avmm_base_seq_c)

   localparam PR_IP_BASE_ADDRESS = 32'h_0000_1000;
   localparam PR_IP_SIZE = 32'h_0000_003F;
   localparam PR_IP_DATA_ADDRESS = PR_IP_BASE_ADDRESS + (0<<2);
   localparam PR_IP_STATUS_ADDRESS = PR_IP_BASE_ADDRESS + (1<<2);
   localparam PR_IP_VERSION_ADDRESS = PR_IP_BASE_ADDRESS + (2<<2);
   localparam PR_IP_PR_POF_ID_ADDRESS = PR_IP_BASE_ADDRESS + (3<<2);


   localparam CONFIG_ROM_BASE_ADDRESS = 32'h_0000_0000;

   function new(string name = "[name]]");
      super.new(name);
   endfunction

endclass


`endif //INC_BAR2_AVMM_SEQUENCE_LIB_SV
