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
