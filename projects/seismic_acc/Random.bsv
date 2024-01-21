import FIFO::*;
import FIFOF::*;
import Vector::*;

interface RandomIfc#(numeric type bitwidth);
	method Action setSeed(Bit#(32) seed);
	method ActionValue#(Bit#(bitwidth)) get;
endinterface

module mkRandomLinearCongruential(RandomIfc#(bitwidth))
	provisos(Add#(bitwidth,a__,32));
	Reg#(Bit#(32)) curVal <- mkReg(0);
	FIFO#(Bit#(bitwidth)) outQ <- mkFIFO;
	FIFOF#(Bit#(32)) seedQ <- mkFIFOF;
	rule genRand;
		if ( seedQ.notEmpty ) begin
			seedQ.deq;
			curVal <= seedQ.first;
		end else begin
			curVal <= (curVal * 22695477 ) + 1;
		end
		outQ.enq(truncate(curVal));
	endrule
	method Action setSeed(Bit#(32) seed);
		seedQ.enq(seed);
	endmethod
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


