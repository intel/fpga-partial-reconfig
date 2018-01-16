#! /bin/env perl

use warnings;
use strict;

print "PR Reference Design Flash Utility\n";
if (scalar(@ARGV) != 1) {
	print "Error: Usage flash.pl <cable num>\n";
}

my $cable_number = $ARGV[0];
my $soffile = "../../output_files/s10_pcie_devkit_pr.sof";

my $cof = <<END;
<?xml version="1.0" encoding="US-ASCII" standalone="yes"?>
<cof>
	<eprom_name>CFI_1GB</eprom_name>
	<output_filename>flash.pof</output_filename>
	<n_pages>1</n_pages>
	<width>1</width>
	<mode>21</mode>
	<sof_data>
		<start_address>00200000</start_address>
		<user_name>Page_0</user_name>
		<page_flags>1</page_flags>
		<bit0>
			<sof_filename>$soffile</sof_filename> 
		</bit0>
	</sof_data>
	<version>10</version>
	<create_cvp_file>0</create_cvp_file>
	<create_hps_iocsr>0</create_hps_iocsr>
	<auto_create_rpd>0</auto_create_rpd>
	<rpd_little_endian>1</rpd_little_endian>
	<options>
		<map_file>1</map_file>
		<option_start_address>000C0000</option_start_address>
		<dynamic_compression>0</dynamic_compression>
	</options>
	<advanced_options>
		<ignore_epcs_id_check>2</ignore_epcs_id_check>
		<ignore_condone_check>2</ignore_condone_check>
		<plc_adjustment>0</plc_adjustment>
		<post_chain_bitstream_pad_bytes>-1</post_chain_bitstream_pad_bytes>
		<post_device_bitstream_pad_bytes>-1</post_device_bitstream_pad_bytes>
		<bitslice_pre_padding>1</bitslice_pre_padding>
	</advanced_options>
</cof>
END

my $cdf = <<CDFEND;
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Ign)
		Device PartName(5M2210ZF256) MfrSpec(OpMask(0) SEC_Device(CFI_1GB CFI_1GB) Child_OpMask(4 1 1 1 0) PFLPath("flash.pof" ""));
	P ActionCode(Ign)
		Device PartName(ND_EMU_MINI) MfrSpec(OpMask(0));
		
ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
CDFEND

open COFFILE, ">flash.cof";
print COFFILE $cof;
close COFFILE;

open CDFFILE, ">flash.cdf";
print CDFFILE $cdf;
close CDFFILE;

system ("quartus_cpf --convert flash.cof");
$? == 0  or die "Error: quartus_cpf failed";

system ("jtagconfig --setparam $cable_number JtagClock 6M");
$? == 0 or die "Error: setting jtag clock frequency failed";

system ("quartus_pgm -c $cable_number flash.cdf");
$? == 0  or die "Error: quartus_pgm failed";
