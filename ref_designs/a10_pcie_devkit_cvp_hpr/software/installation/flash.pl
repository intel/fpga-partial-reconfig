#! /bin/env perl

use warnings;
use strict;

print "PR Reference Design Flash Utility\n";
if (scalar(@ARGV) != 1) {
	print "Error: Usage flash.pl <cable num>\n";
}

my $cable_number = $ARGV[0];

my $cdf = <<CDFEND;
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Ign)
		Device PartName(10AX115S2E2) MfrSpec(OpMask(0));
	P ActionCode(Ign)
		Device PartName(5M2210Z) MfrSpec(OpMask(0) SEC_Device(CFI_2GB) Child_OpMask(3 1 1 1) PFLPath("flash.pof"));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
CDFEND

open CDFFILE, ">flash.cdf";
print CDFFILE $cdf;
close CDFFILE;
system ("jtagconfig --setparam $cable_number JtagClock 6M");
$? == 0  or die "Error: Jtag Clock setting failed";

system ("quartus_pgm -c $cable_number flash.cdf");
$? == 0  or die "Error: quartus_pgm failed";
