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
    
    FIFO#(Float) sampleIn   <- mkFIFO;
    FIFO#(Float) sampleOut  <- mkFIFO;

    FloatTwoOp fmult <- mkFloatMult;
    FloatTwoOp fadd <- mkFloatAdd;

    Reg#(State) state  <- mkReg(READY);

    Reg#(Float) prev <- mkReg(0);
    Reg#(Float) curr <- mkReg(0);

    Reg#(Float) accum <- mkReg(0);

    FIFOF#(Float) samples <- mkSizedFIFOF(512);

    Reg#(Float) term1  <- mkReg(?);
    Reg#(Float) term2  <- mkReg(?); 

    rule enqSample(state == READY);
        sampleIn.deq;
        prev <= curr;
        curr <= sampleIn.first;

        // Find the mean of last 512 samples
        samples.enq(sampleIn.first);
        fadd.put(accum, sampleIn.first);

        if(samples.notFull) begin
            state <= ADDACCUM;
        end else begin
            state <= NEG;
        end

    endrule 

    rule relayNegate(state == NEG);
        samples.deq;
        fmult.put(samples.first, unpack(32'hbf800000));

        state <= SUB;
    endrule 

    rule relaySubtract(state == SUB);
        let tempNegate <- fmult.get;
        let tempAccum  <- fadd.get;
        fadd.put(tempAccum, tempNegate);

        state <= ADDACCUM;
    endrule

    rule relayAccum(state == ADDACCUM);
        let tempAccum <- fadd.get;
        fmult.put(tempAccum, unpack(32'h3b000000));

        state <= CALCAVG;
    endrule 

    rule relayAvg(state == CALCAVG);
        let tempAvg <- fmult.get;
        fmult.put(unpack(32'hbf800000), tempAvg); 

        state <= NEGAVG;
    endrule 

    rule relayNegAvg(state == NEGAVG);
        let tempNegAvg <- fmult.get;
        fadd.put(curr, tempNegAvg); // ci - M
        fmult.put(prev, unpack(32'h3f67ae14)); //ci-1*(1-L)

        state <= SUBAVG;
    endrule 

    rule relaySubAvg(state == SUBAVG);
        let tempSubAvg <- fadd.get;
        let tempTerm2  <- fmult.get;
        fmult.put(tempSubAvg, unpack(32'h3ca3d70a)); // multiply by delta 0.02 
        term2 <= tempTerm2;

        state <= CALCTERM1;
    endrule 

    rule relayTerm1(state == CALCTERM1);
        let tempTerm1 <- fmult.get;
        term1 <= tempTerm1;
        fadd.put(term1, term2);

        state <= CALCRES;
    endrule 

    rule relayResult(state == CALCRES);
        let tempResult <- fadd.get;
        sampleOut.enq(tempResult);

        state <= READY;
    endrule


    method Action addSample(Float sample) if (state == READY);
        //$write("Integrator.bsv: added sample %d\n", sample);
        sampleIn.enq(sample);        
    endmethod

    method ActionValue#(Float) integrateOut();
    	//$write("Integrator.bsv: intgrateOut called\n");
        sampleOut.deq;
        let res = sampleOut.first;
        return res;
    endmethod 

endmodule
