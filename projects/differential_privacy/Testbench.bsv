



(* synthesize *)
module mkTestbench(Empty);
	ASGIfc#(23) rand1 <- mkASG32;
	ASGIfc#(23) rand2 <- mkASG32;

	RandIntToFloatIfc itf1 <- mkRandIntToFloat;
	RandIntToFloatIfc itf2 <- mkRandIntToFloat;

	LaplaceRandFloat32Ifc dpModule <- mkLaplaceRandFloat32;

	Reg#(Integer) counter <- mkReg(0);

	rule relayRand;
		let randSample1 <- rand1.get;
		let randSample2 <- rand2.get;

		itf1.randVal(randSample1);
		itf2.randVal(randSample2);
	endrule

	rule relayConversion;
		let randFloat1 <- itf1.get;
		let randFloat2 <- itf2.get;

		dpModule.randVal(randFloat1, randFloat2);
	endrule

	rule relayNoise;
		let noise <- dpModule.get;

		$display("%f", unpack(noise));
		if(counter == 100) $finish;
	endrule
