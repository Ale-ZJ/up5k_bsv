import FIFO::*;
import FIFOF::*;
import Vector::*;
import SimpleFloat::*;
import FloatingPoint::*;
import Logarithm::*;
import IntToFloat::*;

typedef enum { SEED, ACTIVE } State deriving(Bits, Eq);

Bit#(32) const1 = 4294967294;
Bit#(32) const2 = 4294967288;
Bit#(32) const3 = 4294967280;

interface TauswortheIfc;
	method Action setSeed(Bit#(8) seed);
	method Action startSeed;
	method ActionValue#(Bit#(23)) get;
endinterface

module mkTausworthe(TauswortheIfc);

	Reg#(Bit#(32)) lsfr1 <- mkReg(32'h2a85eacf); //mkReg(32'h884c2686);
	Reg#(Bit#(32)) lsfr2 <- mkReg(32'h5de46c20);
	Reg#(Bit#(32)) lsfr3 <- mkReg(32'h884c2686); //mkReg(30'h2a85eacf);

	// Reg#(Bit#(32)) const1 <- mkReg(4294967294);
	// Reg#(Bit#(32)) const2 <- mkReg(4294967288);
	// Reg#(Bit#(32)) const3 <- mkReg(4294967280);

	FIFO#(Bit#(23)) outQ <- mkFIFO;

	Reg#(Bit#(4)) seedCount <- mkReg(0);
	FIFO#(Bit#(8)) seedQ <- mkFIFO;
	FIFOF#(Bit#(1)) seedEnQ <- mkFIFOF;

	Reg#(State) state <- mkReg(ACTIVE);

	rule fillSeed(state == SEED);
		seedQ.deq;
		let seed_in = seedQ.first;

		if(seedCount < 4) begin 
			lsfr1 <= {lsfr1[23:0], seed_in};
		end else if (seedCount < 8) begin 
			lsfr2 <= {lsfr2[23:0], seed_in};
		end else if (seedCount < 12) begin 
			lsfr3 <= {lsfr3[23:0], seed_in};
		end else begin 
			state <= ACTIVE;
		end 
		seedCount <= (seedCount < 12) ? seedCount + 1 : 0;
		// if (seedCount < 12) begin 
		// 	seedCount <= seedCount + 1;
		// end else begin 
		// 	seedCount <= 0;
		// end 
	endrule 


	rule which_lsfr(state == ACTIVE);

		if(seedEnQ.notEmpty) begin 
			seedEnQ.deq;
			// if (seedEnQ.first == 1'b1) begin 
			state <= SEED;
			// end 
		end else begin 

			lsfr1 <= (((lsfr1 << 13)^lsfr1) >> 19)^((lsfr1 & const1) << 12);
			lsfr2 <= (((lsfr2 << 2)^lsfr2) >> 25)^((lsfr2 & const2) << 4);
			lsfr3 <= (((lsfr3 << 3)^lsfr3) >> 11)^((lsfr3 & const3) << 17);
		end 
		outQ.enq((lsfr1^lsfr2^lsfr3)[22:0]);
	endrule 

	method Action setSeed(Bit#(8) seed);
		seedQ.enq(seed);
	endmethod 

	method Action startSeed;
		seedEnQ.enq(1'b1);
	endmethod 

	method ActionValue#(Bit#(23)) get;
		outQ.deq;
		return outQ.first;
	endmethod
endmodule 
