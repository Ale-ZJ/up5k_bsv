import FIFO::*;
import FIFOF::*;
import Vector::*;
import SimpleFloat::*;
import FloatingPoint::*;
import Logarithm::*;
import IntToFloat::*;
interface RandomIfc#(numeric type bitwidth);
	method Action setSeed(Bit#(32) seed);
	method ActionValue#(Bit#(bitwidth)) get;
endinterface

module mkRandomLinearCongruential(RandomIfc#(bitwidth))
	provisos(Add#(bitwidth,a__,32));
	Reg#(Bit#(32)) curVal <- mkReg(7);
	FIFO#(Bit#(bitwidth)) outQ <- mkFIFO;
	FIFOF#(Bit#(32)) seedQ <- mkFIFOF;
	rule genRand;
		if ( seedQ.notEmpty ) begin
			seedQ.deq;
			curVal <= seedQ.first;
		end else begin 
			curVal <= (curVal * 22695477 ) + 1; // magic numbers for linear congruential source : https://nuclear.llnl.gov/CNP/rng/rngman/node4.html
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


interface RandIntToFloatIfc;
	method Action randVal(Bit#(23) data);
	method ActionValue#(Bit#(32)) get;
endinterface

module mkRandIntToFloat(RandIntToFloatIfc);

	FIFO#(Bit#(23)) inQ  <- mkFIFO;
	FIFO#(Bit#(32)) outQ <- mkFIFO;

	FloatTwoOp fadd <- mkFloatAdd;
	//FloatTwoOp fmult <- mkFloatMult;
        
	rule relayRand;
		inQ.deq;
		Bit#(23) randInt  = inQ.first;
	        Bit#(32) adjusted = {9'b001111111, randInt}; 	
		fadd.put(unpack(adjusted), unpack(32'hbf800000));
		//fmult.put(unpack(truncate(randInt>>8)), unpack(32'h33800000));
        endrule

	method Action randVal(Bit#(23) data);
		inQ.enq(data);
		//fmult.put(unpack(zeroExtend(data)), unpack(32'h33800000));
		//fmult.put(unpack(truncate(data >> 8)), unpack(32'h33800000));
	endmethod

	method ActionValue#(Bit#(32)) get;
		let result <- fadd.get;
		return pack(result);
	endmethod
endmodule



interface LaplaceRandFloat32Ifc;
	method Action randVal(Bit#(8) data1, Bit#(8) data2);
	method ActionValue#(Bit#(32)) get;
endinterface

module mkLaplaceRandFloat32(LaplaceRandFloat32Ifc);
	//FIFO#(Tuple2#(Bit#(32), Bit#(32))) inQ <- mkFIFO;
	//FIFO#(Bit#(32)) outQ <- mkFIFO;

	LogarithmIfc#(8) log1 <- mkFastLog32;
	LogarithmIfc#(8) log2 <- mkFastLog32;

	//Reg#(Bit#(1)) log_valid <- mkReg(0);
	//Reg#(Bit#(32)) log_buffer <- mkReg(?);

	IntToFloatIfc itf <- mkIntToFloat;

	//rule enqLog;
	//	inQ.deq;
	//	let d = inQ.first;
	//	log1.addSample(tpl_1(d));
	//	log2.addSample(tpl_2(d));
	//endrule
	rule relayLog;
	        let partial1 <- log1.get;
		let partial2 <- log2.get;
		Bit#(8) diff = partial1 - partial2; //should i multiply by the -scale?
		itf.put(diff);
	endrule
	
	method Action randVal(Bit#(8) data1, Bit#(8) data2);
		//inQ.enq(tuple2(data1,data2));
		log1.addSample(data1);
		log2.addSample(data2);
	endmethod
	method ActionValue#(Bit#(32)) get;
		let res <- itf.get;
		return res;
	endmethod
endmodule 


interface ASGIfc#(numeric type bitwidth);
	method ActionValue#(Bit#(bitwidth)) get;
endinterface

module mkASG32(ASGIfc#(23));

	Reg#(Bit#(30)) lsfr0 <- mkReg(30'h2a85eacf); //mkReg(32'h884c2686);
	Reg#(Bit#(31)) lsfr1 <- mkReg(31'h5de46c20);
	Reg#(Bit#(32)) lsfr2 <- mkReg(32'h884c2686); //mkReg(30'h2a85eacf);
	//ff0001df
	//7f000083
	//3f0000e1
	Reg#(Bit#(6))  count <- mkReg(6'b0);
	Reg#(Bit#(23)) shift <- mkReg(23'b0);

	FIFO#(Bit#(23)) outQ <- mkFIFO;
	rule step;

		if(count >= 6'h17) begin 
			outQ.enq(shift);
			count <= 1;
		end else begin 
			count <= count + 6'b1;
		end 
		shift <= {shift[21:0], (lsfr0[0]^lsfr1[0])};
		
		Bit#(1) which = 1'b0;
		if(lsfr2[0] == 1'b1) begin 
			Bit#(32) tempReg = 32'hff0001df ^ (lsfr2 >> 1);
			lsfr2 <= tempReg;
			which = tempReg[0];
		end else begin
			which = lsfr2[0];
		end

		if(which == 1'b1) begin 
			lsfr1 <= 31'h7f000083 ^ (lsfr1 >> 1);
		end else begin 
			lsfr0 <= 30'h3f0000e1 ^ (lsfr0 >> 1);
		end 

	endrule 

	method ActionValue#(Bit#(23)) get;
		outQ.deq;
		return outQ.first;
	endmethod
endmodule
