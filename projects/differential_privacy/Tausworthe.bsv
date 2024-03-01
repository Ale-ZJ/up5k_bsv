import FIFO::*;
import FIFOF::*;
import Vector::*;
import SimpleFloat::*;
import FloatingPoint::*;
import Logarithm::*;
import IntToFloat::*;


interface TauswortheIfc;
	method Action seed(Bit#(96) seed);
	method ActionValue#(Bit#(32)) get;
endinterface

module mkTausworthe(ASGIfc);

	Reg#(Bit#(32)) lsfr1 <- mkReg(32'h2a85eacf); //mkReg(32'h884c2686);
	Reg#(Bit#(32)) lsfr2 <- mkReg(32'h5de46c20);
	Reg#(Bit#(32)) lsfr3 <- mkReg(32'h884c2686); //mkReg(30'h2a85eacf);

	Reg#(Bit#(32)) const1 <- mkReg(4294967294);
	Reg#(Bit#(32)) const2 <- mkReg(4294967288);
	Reg#(Bit#(32)) const3 <- mkReg(4294967280);

	FIFO#(Bit#(23)) outQ <- mkFIFO;

	FIFO#(Bit#(96)) seedQ <- mkFIFO;
	

	rule which_lsfr;

		if(seedQ.notEmpty) begin 
			seedQ.deq;
			Bit#(96) seed = seedQ.first;
			lsfr1 <= seed[95:64];
			lsfr2 <= seed[63:32];
			lsfr3 <= seed[31:0];
		end else begin 

			lsfr1 <= (((lsfr1 << 13)^lsfr1) >> 19)^((lsfr1 & const1) << 12);
			lsfr2 <= (((lsfr2 << 2)^lsfr2) >> 25)^((lsfr2 & const2) << 4);
			lsfr3 <= (((lsfr3 << 3)^lsfr3) >> 11)^((lsfr3 & const3) << 17);
		end 
		outQ.enq((lsfr1^lsfr2^lsfr3)[22:0]);
	endrule 

	method Action seed(Bit#(96) seed);
		seedQ.enq(seed);
	endmethod 

	method ActionValue#(Bit#(23)) get;
		outQ.deq;
		return outQ.first;
	endmethod
endmodule 
