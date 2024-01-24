import SimpleFloat::*;
import FloatingPoint::*;


typedef enum { READY, PA, PB, PC, PD, PE, PF, PG, PH, PI, PJ, PK} State deriving(Bits, Eq);

interface LogarithmIfc#(numeric type bitwidth);;
	method Action addSample#(Bit#(bitwidth));
	method ActionValue#(Bit#(bitwidth)) get;
endinterface

module mkLogarithm32(LogarithmIfc#(32))

	FIFO#(Float) sampleIn   <- mkFIFO;
    FIFO#(Float) sampleOut  <- mkFIFO;

    Reg#(Float) currSample <- mkReg(0);

	FloatTwoOp fmult <- mkFloatMult;
    FloatTwoOp fadd <- mkFloatAdd;

    rule relaySample(state == READY);
    	sampleIn.deq;
    	let sample = sampleIn.first;
    	currSample = sample;
    	fmult.put(sample, 32'h3c088889); //d5 * x
    	state <= PA;
    endrule

    rule relayPA(state == PA);
    	let partial = fmult.get;
        fadd.put(partial, unpack(32'h3cad82d8)); //d4 + partial
        state <= PB;
    endrule

    rule relayPB(state == PB);
    	let partial = fadd.get;
    	fmult.put(partial, currSample); // x * partial
    	state <= PC;
	endrule

	rule relayPC(state == PC);
    	let partial = fmult.get;
    	fadd.put(partial, unpack(32'h3dd3e93f)); // d3 + partial
    	state <= PD;
	endrule

	rule relayPD(state == PD);
    	let partial = fadd.get;
    	fmult.put(partial, currSample); // x * partial
    	state <= PE;
	endrule

	rule relayPE(state == PE);
    	let partial = fmult.get;
    	fadd.put(partial, unpack(32'h3e9aeeef)); // d2 + partial
    	state <= PF;
	endrule

	rule relayPF(state == PF);
    	let partial = fadd.get;
    	fmult.put(partial, currSample); // x * partial
    	state <= PG;
	endrule

	rule relayPG(state == PG);
    	let partial = fmult.get;
    	fadd.put(partial, unpack(32'h3f1b49f5)); // d1 + partial
    	state <= PH;
	endrule

	rule relayPH(state == PH);
    	let partial = fadd.get;
    	fmult.put(partial, currSample); // x * partial
    	state <= PI;
	endrule

	rule relayPI(state == PI);
    	let partial = fmult.get;
    	fadd.put(partial, unpack(32'h3f1b45b0)); // d0 + partial
    	state <= PJ;
	endrule

	rule relayPJ(state == PJ);
		let partial = fadd.get;
		fmult.put(partial, unpack(32'h3fd3094c)); //e^a + partial, where a=0.5
		state <= PK;
	endrule

	rule relayPK(state == PK);
		let result = fadd.get;
		sampleOut.enq(result);
		state <= READY;
	endrule
	

    method Action addSample(Float sample) if (state == READY);
        //$write("Integrator.bsv: added sample %d\n", sample);
        sampleIn.enq(sample);        
    endmethod

    method ActionValue#(Bit#(32)) get;
		sampleOut.deq;
		return sampleOut.first;
	endmethod

endmodule