import FIFO::*;
import FIFOF::*;
import Vector::*;
import BRAMFIFO::*;

import SimpleFloat::*;
import FloatingPoint::*;


typedef enum { READY, NEG, SUB, ADDACCUM, CALCAVG, NEGAVG, SUBAVG, CALCTERM1, CALCRES} State deriving(Bits, Eq);

interface IntegratorInterface;
   method Action  addSample(Float sample);
   method Float   integrateOut;
   method Bool isValid;
endinterface

module mkIntegrator(IntegratorInterface);

    Reg#(Float) prev <- mkReg(0);
    Reg#(Float) curr <- mkReg(0);
    
    Reg#(Float) accum <- mkReg(0);
    Reg#(Float) avg   <- mkReg(0);
    
    FIFOF#(Float) samples <- mkSizedFIFOF(512);
   
    Reg#(Float) term1  <- mkReg(?);
    Reg#(Float) term2  <- mkReg(?); 
    Reg#(Float) result <- mkReg(?);

    Reg#(Bool) valid <- mkReg(False);

    FIFO#(Float) sampleIn               <- mkFIFO;
    FIFO#(Tuple2#(Float, Float)) fmultQ <- mkFIFO;
    FIFO#(Tuple2#(Float, Float)) faddQ  <- mkFIFO;

    FloatTwoOp fmult <- mkFloatMult;
    FloatTwoOp fadd  <- mkFloatAdd;
    
    Reg#(State) state        <- mkReg(READY);

    rule enqSample(state == READY);
        sampleIn.deq;
        prev <= curr;
        curr <= sampleIn.first;
        if(samples.notFull) begin
            samples.enq(sampleIn.first);

            fmult.put(sampleIn.first, accum);
            state <= ADDACCUM;
        end else begin
            samples.deq;    
            fmult.put(unpack(32'hbf800000), samples.first);
            samples.enq(sampleIn.first);
            state <= NEG;
        end
    endrule 

    rule relayFmult;
        fmultQ.deq;
        //let ops <- fmultQ.first;
        fmult.put(tpl_1(fmultQ.first), tpl_2(fmultQ.first));
    endrule

    rule relayFadd;
        faddQ.deq;
        //let ops <- faddQ.first;
        fadd.put(tpl_1(faddQ.first), tpl_2(faddQ.first));
    endrule

    rule relayNegate(state == NEG);
        let tempNegate <- fmult.get;
        faddQ.enq(tuple2(curr, tempNegate));

        state <= SUB;
    endrule 

    rule relaySubtract(state == SUB);
        let tempSubtract <- fadd.get;
        faddQ.enq(tuple2(tempSubtract, accum));

        state <= ADDACCUM;
    endrule

    rule relayAccum(state == ADDACCUM);
        let tempAccum <- fadd.get;
        accum <= tempAccum;
        fmultQ.enq(tuple2(accum, unpack(32'h3b000000)));

        state <= CALCAVG;
    endrule 

    rule relayAvg(state == CALCAVG);
        let tempAvg <- fmult.get;
        fmultQ.enq(tuple2(tempAvg, unpack(32'hbf800000)));

        state <= NEGAVG;
    endrule 

    rule relayNegAvg(state == NEGAVG);
        let tempNegAvg <- fmult.get;
        faddQ.enq(tuple2(curr, tempNegAvg)); // ci - M
        fmultQ.enq(tuple2(prev, unpack(32'h3f67ae14))); //ci-1*(1-L)
        state <= SUBAVG;
    endrule 

    rule relaySubAvg(state == SUBAVG);
        let tempSubAvg <- fadd.get;
        let tempTerm2  <- fmult.get;
        fmultQ.enq(tuple2(tempSubAvg, unpack(32'h3ca3d70a)));

        term2 <= tempTerm2;

        state <= CALCTERM1;
    endrule 

    rule relayTerm1(state == CALCTERM1);
        let tempTerm1 <- fmult.get;
        term1 <= tempTerm1;

        faddQ.enq(tuple2(term1, term2));

        state <= CALCRES;
    endrule 

    rule relayResult(state == CALCRES);
        let tempResult <- fadd.get;

        result <= tempResult;
        valid  <= True;

        state <= READY;
    endrule

    method Action addSample(Float sample) if (state == READY);
        sampleIn.enq(sample);        
    endmethod

    method Float integrateOut() if (valid);
        return result;
    endmethod 

    method Bool isValid = valid;
endmodule
