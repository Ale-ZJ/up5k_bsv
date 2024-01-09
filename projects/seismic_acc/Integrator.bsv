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

    FloatTwoOp fmult0  <- mkFloatMult;
    FloatTwoOp fmult1  <- mkFloatMult;
    FloatTwoOp fmult2  <- mkFloatMult;
    FloatTwoOp fmult3  <- mkFloatMult;
    FloatTwoOp fmult4  <- mkFloatMult;
    FloatTwoOp fadd0 <- mkFloatAdd;
    FloatTwoOp fadd1 <- mkFloatAdd;
    FloatTwoOp fadd2 <- mkFloatAdd;

    Reg#(State) state  <- mkReg(READY);

    Reg#(Float) prev <- mkReg(0);
    Reg#(Float) curr <- mkReg(0);

    Reg#(Float) accum <- mkReg(0);
    // Reg#(Float) avg   <- mkReg(0);

    FIFOF#(Float) samples <- mkSizedFIFOF(512);

    Reg#(Float) term1  <- mkReg(?);
    Reg#(Float) term2  <- mkReg(?); 


    rule enqSample(state == READY);
        sampleIn.deq;
        prev <= curr;
        curr <= sampleIn.first;

        // Find the mean of last 512 samples
        if(samples.notFull) begin
            samples.enq(sampleIn.first);
            fadd0.put(sampleIn.first, accum);
            state <= ADDACCUM;
        end 
        else begin
            samples.deq;    
            fmult0.put(unpack(32'hbf800000), samples.first); // multiply by -1
            samples.enq(sampleIn.first);
            state <= NEG;
        end
    endrule 

    /*
    rule relayNegate(state == NEG);
        let tempNegate <- fmult0.get;
        fadd0.put(accum, tempNegate);
        // faddQ.enq(tuple2(curr, tempNegate)); //

        state <= ADDACCUM;
    endrule 

    // rule relaySubtract(state == SUB);
    //     let tempSubtract <- fadd.get;
    //     faddQ.enq(tuple2(tempSubtract, accum));

    //     state <= ADDACCUM;
    // endrule

    rule relayAccum(state == ADDACCUM);
        let tempAccum <- fadd0.get;
        accum <= tempAccum;
        fmult1.put(tempAccum, unpack(32'h3b000000));
        // fmultQ.enq(tuple2(accum, unpack(32'h3b000000)));

        state <= CALCAVG;
    endrule 

    rule relayAvg(state == CALCAVG);
        let tempAvg <- fmult1.get;
        fmult2.put(unpack(32'hbf800000), tempAvg); // multiply by -1

        // fmultQ.enq(tuple2(tempAvg, unpack(32'hbf800000)));

        state <= NEGAVG;
    endrule 

    rule relayNegAvg(state == NEGAVG);
        let tempNegAvg <- fmult2.get;
        fadd1.put(curr, tempNegAvg);
        fmult3.put(prev, unpack(32'h3f67ae14));
        // faddQ.enq(tuple2(curr, tempNegAvg)); // ci - M
        // fmultQ.enq(tuple2(prev, unpack(32'h3f67ae14))); //ci-1*(1-L)

        state <= SUBAVG;
    endrule 

    rule relaySubAvg(state == SUBAVG);
        let tempSubAvg <- fadd1.get;
        let tempTerm2  <- fmult3.get;
        fmult4.put(tempSubAvg, unpack(32'h3ca3d70a)); // multiply by delta 0.02 
        // fmultQ.enq(tuple2(tempSubAvg, unpack(32'h3ca3d70a)));
        term2 <= tempTerm2;

        state <= CALCTERM1;
    endrule 

    rule relayTerm1(state == CALCTERM1);
        let tempTerm1 <- fmult4.get;
        term1 <= tempTerm1;
        fadd2.put(term1, term2);
        // faddQ.enq(tuple2(term1, term2));

        state <= CALCRES;
    endrule 

    rule relayResult(state == CALCRES);
        let tempResult <- fadd2.get;
        sampleOut.enq(tempResult);

        state <= READY;
    endrule
    */

    // rule putMult(state == READY);
    //     //$write("Integrator.bsv: testing\n");
	//     sampleIn.deq;
	//     curr <= sampleIn.first;
	//     fmult0.put(curr, dummy);
    //     state <= NEG;
    // endrule

    // rule readMult(state == NEG);
    //     let r <- fmult0.get;
    //     sampleOut.enq(r);
    //     state <= READY;
    // endrule

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

    //method Bool isValid = valid;
endmodule
