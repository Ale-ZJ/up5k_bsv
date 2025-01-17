import SimpleFloat::*;
import FloatingPoint::*;
import FIFO::*;
import Vector::*;
import BRAMFIFO::*;

typedef enum { READY, PA, PB, PC, PD, PE, PF, PG, PH, PI, PJ, PK} State deriving(Bits, Eq);

interface LogarithmIfc#(numeric type bitwidth);
	method Action addSample(Bit#(bitwidth) samples);
	method ActionValue#(Bit#(bitwidth)) get;
endinterface

module mkFastLog32(LogarithmIfc#(32));
    //FIFO#(Bit#(32)) sampleIn  <- mkFIFO;
    FIFO#(Bit#(32)) sampleOut <- mkFIFO;


    method Action addSample(Bit#(32) float_sample); //assume sample is float exp
	    
	    Bit#(8)  exponent = float_sample[30:23];
	    Bit#(23) mantissa = float_sample[22:0];

	    Bit#(9) integer_part = zeroExtend(exponent) + 9'b110000001;

	    Bit#(31) new_mantissa;

	    if(integer_part[8] == 0) begin 
	    	//is positive

	    	new_mantissa = (zeroExtend(integer_part[7:0]) << 23) + zeroExtend(mantissa) + 31'h00040000;
	    end else begin 
	    	new_mantissa = (zeroExtend(negate(integer_part)) << 23) + negate(zeroExtend(mantissa)) + 31'h00040000;
	    end	
	    

	    sampleOut.enq({integer_part[8], 8'd135, new_mantissa[30:8]});
    endmethod

    method ActionValue#(Bit#(32)) get;
	    sampleOut.deq;
	    return sampleOut.first;
    endmethod
endmodule

module mkLogarithm32(LogarithmIfc#(32));
    FIFO#(Float) sampleIn   <- mkFIFO;
    FIFO#(Float) sampleOut  <- mkFIFO;

    Reg#(Float) currSample <- mkReg(?);

	FloatTwoOp fmult <- mkFloatMult;
    FloatTwoOp fadd <- mkFloatAdd;

    Reg#(State) state  <- mkReg(READY);

    rule relaySample(state == READY);
    	sampleIn.deq;
    	let sample = sampleIn.first;
    	currSample <= sample;
    	fmult.put(sample, unpack(32'h3c088889)); //d5 * x
    	state <= PA;
    endrule

    rule relayPA(state == PA);
    	let partial <- fmult.get;
        fadd.put(partial, unpack(32'h3cad82d8)); //d4 + partial
        state <= PB;
    endrule

    rule relayPB(state == PB);
    	let partial <- fadd.get;
    	fmult.put(partial, currSample); // x * partial
    	state <= PC;
	endrule

	rule relayPC(state == PC);
    	let partial <- fmult.get;
    	fadd.put(partial, unpack(32'h3dd3e93f)); // d3 + partial
    	state <= PD;
	endrule

	rule relayPD(state == PD);
    	let partial <- fadd.get;
    	fmult.put(partial, currSample); // x * partial
    	state <= PE;
	endrule

	rule relayPE(state == PE);
    	let partial <- fmult.get;
    	fadd.put(partial, unpack(32'h3e9aeeef)); // d2 + partial
    	state <= PF;
	endrule

	rule relayPF(state == PF);
    	let partial <- fadd.get;
    	fmult.put(partial, currSample); // x * partial
    	state <= PG;
	endrule

	rule relayPG(state == PG);
    	let partial <- fmult.get;
    	fadd.put(partial, unpack(32'h3f1b49f5)); // d1 + partial
    	state <= PH;
	endrule

	rule relayPH(state == PH);
    	let partial <- fadd.get;
    	fmult.put(partial, currSample); // x * partial
    	state <= PI;
	endrule

	rule relayPI(state == PI);
    	let partial <- fmult.get;
    	fadd.put(partial, unpack(32'h3f1b45b0)); // d0 + partial
    	state <= PJ;
	endrule

	rule relayPJ(state == PJ);
		let partial <- fadd.get;
		fmult.put(partial, unpack(32'h3fd3094c)); //e^a + partial, where a=0.5
		state <= PK;
	endrule

	rule relayPK(state == PK);
		let result <- fadd.get;
		sampleOut.enq(result);
		state <= READY;
	endrule
	

    method Action addSample(Bit#(32) sample) if (state == READY);
        //$write("Integrator.bsv: added sample %d\n", sample);
        sampleIn.enq(unpack(sample));        
    endmethod

    method ActionValue#(Bit#(32)) get;
		sampleOut.deq;
		return pack(sampleOut.first);
	endmethod

endmodule

module mkLogarithm(LogarithmIfc#(32));
    FIFO#(Float) sampleIn   <- mkFIFO;
    FIFO#(Float) sampleOut  <- mkFIFO;

    Reg#(Float) currSample <- mkReg(?);

	FloatTwoOp fmult <- mkFloatMult;
    FloatTwoOp fadd <- mkFloatAdd;

    Reg#(State) state  <- mkReg(READY);

    rule relaySample(state == READY);
    	sampleIn.deq;
    	let sample = sampleIn.first;
    	currSample <= sample;
    	fmult.put(sample, unpack(32'h3c088889)); //d5 * x
    	state <= PA;
    endrule

    rule relayPA(state == PA);
    	let partial <- fmult.get;
        fadd.put(partial, unpack(32'h3cad82d8)); //d4 + partial
        state <= PB;
    endrule

    rule relayPB(state == PB);
    	let partial <- fadd.get;
    	fmult.put(partial, currSample); // x * partial
    	state <= PC;
	endrule

	rule relayPC(state == PC);
    	let partial <- fmult.get;
    	fadd.put(partial, unpack(32'h3dd3e93f)); // d3 + partial
    	state <= PD;
	endrule

	rule relayPD(state == PD);
    	let partial <- fadd.get;
    	fmult.put(partial, currSample); // x * partial
    	state <= PE;
	endrule

	rule relayPE(state == PE);
    	let partial <- fmult.get;
    	fadd.put(partial, unpack(32'h3e9aeeef)); // d2 + partial
    	state <= PF;
	endrule

	rule relayPF(state == PF);
    	let partial <- fadd.get;
    	fmult.put(partial, currSample); // x * partial
    	state <= PG;
	endrule

	rule relayPG(state == PG);
    	let partial <- fmult.get;
    	fadd.put(partial, unpack(32'h3f1b49f5)); // d1 + partial
    	state <= PH;
	endrule

	rule relayPH(state == PH);
    	let partial <- fadd.get;
    	fmult.put(partial, currSample); // x * partial
    	state <= PI;
	endrule

	rule relayPI(state == PI);
    	let partial <- fmult.get;
    	fadd.put(partial, unpack(32'h3f1b45b0)); // d0 + partial
    	state <= PJ;
	endrule

	rule relayPJ(state == PJ);
		let partial <- fadd.get;
		fmult.put(partial, unpack(32'h3fd3094c)); //e^a + partial, where a=0.5
		state <= PK;
	endrule

	rule relayPK(state == PK);
		let result <- fadd.get;
		sampleOut.enq(result);
		state <= READY;
	endrule
	

    method Action addSample(Bit#(32) sample) if (state == READY);
        //$write("Integrator.bsv: added sample %d\n", sample);
        sampleIn.enq(unpack(sample));        
    endmethod

    method ActionValue#(Bit#(32)) get;
		sampleOut.deq;
		return pack(sampleOut.first);
	endmethod

endmodule
