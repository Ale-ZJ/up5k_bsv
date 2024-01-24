import SimpleFloat::*;
import FloatingPoint::*;


typedef enum { READY, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11} State deriving(Bits, Eq);

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
    	state <= P1;
    endrule

    rule relayP1(state == P1);
    	let partial = fmult.get;
        fadd.put(partial, unpack(32'h3cad82d8)); //d4 + partial
        state <= P2;
    endrule

    rule relayP2(state == P2);
    	let partial = fadd.get;
    	fmult.put(partial, currSample); // x * partial
    	state <= P3;
	endrule

	rule relayP3(state == P3);
    	let partial = fmult.get;
    	fadd.put(partial, unpack(32'h3dd3e93f)); // d3 + partial
    	state <= P4;
	endrule

	rule relayP4(state == P4);
    	let partial = fadd.get;
    	fmult.put(partial, currSample); // x * partial
    	state <= P5;
	endrule

	rule relayP5(state == P5);
    	let partial = fmult.get;
    	fadd.put(partial, unpack(32'h3e9aeeef)); // d2 + partial
    	state <= P6;
	endrule

	rule relayP6(state == P6);
    	let partial = fadd.get;
    	fmult.put(partial, currSample); // x * partial
    	state <= P7;
	endrule

	rule relayP7(state == P7);
    	let partial = fmult.get;
    	fadd.put(partial, unpack(32'h3f1b49f5)); // d1 + partial
    	state <= P8;
	endrule

	rule relayP8(state == P8);
    	let partial = fadd.get;
    	fmult.put(partial, currSample); // x * partial
    	state <= P9;
	endrule

	rule relayP9(state == P9);
    	let partial = fmult.get;
    	fadd.put(partial, unpack(32'h3f1b45b0)); // d0 + partial
    	state <= P10;
	endrule

	rule relayP10(state == P10);
		let partial = fadd.get;
		fmult.put(partial, unpack(32'h3fd3094c)); //e^a + partial, where a=0.5
		state <= P11;
	endrule

	rule relayP11(state == P11);
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