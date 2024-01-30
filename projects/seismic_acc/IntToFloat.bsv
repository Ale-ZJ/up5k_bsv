import FIFO::*;
import FIFO::*;
import Vector::*;
import BRAMFIFO::*;
import SimpleFloat::*;
import FloatingPoint::*;

//typedef enum { READY, SET_MSB_INDEX, CONVERT_RHS, CONVERT } State deriving(Bits, Eq);

interface IntToFloatIfc;
	method Action put(Bit#(8) int_in);
	method ActionValue#(Bit#(32)) get;
endinterface

module mkIntToFloat(IntToFloatIfc);
	
	FIFO#(Bit#(8)) inQ  <- mkFIFO;
        FIFO#(Bit#(32)) outQ <- mkFIFO;
	
        rule processFloat;
		inQ.deq;
		Bit#(8) data = inQ.first;
		Bit#(1) sign     = data[7];

		data = data << 1;
		Bit#(3) shift_dist = 0;
		while(data[7] != 1'b1 && shift_dist != 3'b111) begin
			shift_dist = shift_dist + 3'b1;
			data = data << 1;
		end

		Bit#(8)  exponent = (zeroExtend(shift_dist) + 8'h7F);
		Bit#(23) mantissa = {data[7:0], 15'b0};

		outQ.enq({sign, exponent, mantissa});
	endrule

		


	method Action put(Bit#(8) int_in);
		inQ.enq(int_in);
	endmethod

	method ActionValue#(Bit#(32)) get;
		outQ.deq;
		let res = outQ.first;
		return res;
	endmethod

	
endmodule
