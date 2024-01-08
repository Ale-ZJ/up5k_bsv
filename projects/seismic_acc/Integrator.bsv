import FIFO::*;
import FIFOF::*;
import Vector::*;
import BRAMFIFO::*;

import SimpleFloat::*;
import FloatingPoint::*;


typedef enum { READY, NEG, SUB, ADDACCUM, CALCAVG, NEGAVG, SUBAVG, CALCTERM1, CALCRES} State deriving(Bits, Eq);

interface IntegratorInterface;
   method Action  addSample(Float sample);
   method ActionValue#(Float)   integrateOut;
   //method Bool isValid;
endinterface

module mkIntegrator(IntegratorInterface);

    Reg#(Float) curr <- mkReg(0);
    Reg#(Float) dummy <- mkReg(2);

    FIFO#(Float) sampleIn   <- mkFIFO;
    FIFO#(Float) sampleOut  <- mkFIFO;

    FloatTwoOp fmult0  <- mkFloatMult;
    Reg#(State) state  <- mkReg(READY);

    // receives floats and doubles it

    rule putMult(state == READY);
        $write("Integrator.bsv: testing\n");
	    sampleIn.deq;
	    curr <= sampleIn.first;
	    fmult0.put(curr, dummy);
        state <= NEG;
    endrule

    rule readMult(state == NEG);
        let r <- fmult0.get;
        sampleOut.enq(r);
        state <= READY;
    endrule

    method Action addSample(Float sample) if (state == READY);
        $write("Integrator.bsv: added sample %d\n", sample);
        sampleIn.enq(sample);        
    endmethod

    method ActionValue#(Float) integrateOut();
    	$write("Integrator.bsv: intgrateOut called\n");
        sampleOut.deq;
        let res = sampleOut.first;
        return res;
    endmethod 

    //method Bool isValid = valid;
endmodule
