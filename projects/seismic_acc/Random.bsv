import FIFO::*;
import FIFOF::*;
import Vector::*;
import SimpleFloat::*;
import FloatingPoint::*;
import Logarithm::*;

interface RandomIfc#(numeric type bitwidth);
	//method Action setSeed(Bit#(32) seed);
	method ActionValue#(Bit#(bitwidth)) get;
endinterface

module mkRandomLinearCongruential(RandomIfc#(bitwidth))
	provisos(Add#(bitwidth,a__,32));
	Reg#(Bit#(32)) curVal <- mkReg(7);
	FIFO#(Bit#(bitwidth)) outQ <- mkFIFO;
	//FIFOF#(Bit#(32)) seedQ <- mkFIFOF;
	rule genRand;
                curVal <= (curVal * 22695477 ) + 1; // magic numbers for linear congruential source : https://nuclear.llnl.gov/CNP/rng/rngman/node4.html
		//end
		outQ.enq(truncate(curVal));
	endrule
	method ActionValue#(Bit#(bitwidth)) get;
		outQ.deq;
		return outQ.first;
	endmethod
endmodule

interface LaplaceRand16Ifc;
	method Action randVal(Bit#(16) data1, Bit#(16) data2);
	method ActionValue#(Bit#(8)) get;
endinterface

function Bit#(4) msbidx(Bit#(16) data);
	Vector#(4,Bit#(1)) indxv = replicate(0);
	if ( data[15:8] != 0 ) indxv[0] = 1;
	if ( data[15:12] != 0 || data[7:4] != 0 ) indxv[1] = 1;
	if ( data[15:14] != 0 || data[11:10] != 0 || data[7:6] != 0|| data[3:2] != 0 ) indxv[2] = 1;
	if ( data[15] != 0 || data[13] != 0 || data[11] != 0 || data[9] != 0 || data[7] != 0 || data[5] != 0 || data[3] != 0 || data[1] != 0 ) indxv[3] = 1;

	return {indxv[0],indxv[1],indxv[2],indxv[3]};
endfunction

module mkLaplaceRand16(LaplaceRand16Ifc);

	
	FIFO#(Bit#(32)) inQ <- mkFIFO;
	FIFO#(Bit#(8)) outQ <- mkFIFO;
	rule dosample;
		inQ.deq;
		let d = inQ.first;
		Bit#(5) m1 = zeroExtend(msbidx(truncate(d)));
		Bit#(5) m2 = zeroExtend(msbidx(truncate(d>>16)));
		outQ.enq(zeroExtend(m1-m2));
	endrule
	
	method Action randVal(Bit#(16) data1, Bit#(16) data2);
		inQ.enq({data1,data2});
	endmethod
	method ActionValue#(Bit#(8)) get;
		outQ.deq;
		return outQ.first;
	endmethod
endmodule


interface RandIntToFloatIfc;
	method Action randVal(Bit#(24) data);
	method ActionValue#(Bit#(32)) get;
endinterface

module mkRandIntToFloat(RandIntToFloatIfc);

	FIFO#(Bit#(32)) inQ  <- mkFIFO;
	FIFO#(Bit#(32)) outQ <- mkFIFO;

	FloatTwoOp fmult <- mkFloatMult;
        
	rule relayRand;
		inQ.deq;
		Bit#(32) randInt = inQ.first;
		//fmult.put(unpack(truncate(randInt>>8)), unpack(32'h33800000));
        endrule

	method Action randVal(Bit#(24) data);
		fmult.put(unpack(zeroExtend(data)), unpack(32'h33800000));
		//fmult.put(unpack(truncate(data >> 8)), unpack(32'h33800000));
	endmethod

	method ActionValue#(Bit#(32)) get;
		let result <- fmult.get;
		return pack(result);
	endmethod
endmodule



interface LaplaceRandFloat32Ifc;
	method Action randVal(Bit#(8) data1, Bit#(8) data2);
	method ActionValue#(Bit#(32)) get;
endinterface

module mkLaplaceRandFloat32(LaplaceRandFloat32Ifc);
	//FIFO#(Tuple2#(Bit#(32), Bit#(32))) inQ <- mkFIFO;
	FIFO#(Bit#(32)) outQ <- mkFIFO;

	LogarithmIfc#(8) log1 <- mkFastLog32;
	LogarithmIfc#(8) log2 <- mkFastLog32;

	Reg#(Bit#(1)) log_valid <- mkReg(0);
	Reg#(Bit#(32)) log_buffer <- mkReg(?);

	//rule enqLog;
	//	inQ.deq;
	//	let d = inQ.first;
	//	log1.addSample(tpl_1(d));
	//	log2.addSample(tpl_2(d));
	//endrule
	rule relayLog;
	        let partial1 <- log1.get;
		let partial2 <- log2.get;
		outQ.enq(zeroExtend(partial1 - partial2)); //should i multiply by the -scale?
	endrule
	
	method Action randVal(Bit#(8) data1, Bit#(8) data2);
		//inQ.enq(tuple2(data1,data2));
		log1.addSample(data1);
		log2.addSample(data2);
	endmethod
	method ActionValue#(Bit#(32)) get;
		outQ.deq;
		return outQ.first;
	endmethod
endmodule 
