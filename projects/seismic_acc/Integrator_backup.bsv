import FIFO::*;
import FIFOF::*;
import Vector::*;
import BRAMFIFO::*;

import SimpleFloat::*;
import FloatingPoint::*;
import BRAMWrapper::*;
//typedef enum { READY, NEG, SUB, ADDACCUM, CALCAVG, NEGAVG, SUBAVG, CALCTERM1, CALCRES} State deriving(Bits, Eq);

typedef enum { READY, FULL, STEP1, STEP2, STEP3, STEP4 } State deriving(Bits, Eq);

interface IntegratorInterface;
   method Action  addSample(Float sample);
   method ActionValue#(Float)   integrateOut;
   //method Bool isValid;
endinterface

module mkIntegrator(IntegratorInterface);
    
    FIFO#(Float) sampleIn   <- mkFIFO;
    FIFO#(Float) sampleOut  <- mkFIFO;

    FloatTwoOp fmult  <- mkFloatMult;
    FloatTwoOp fadd   <- mkFloatAdd;

    // FloatTwoOp fmult2 <- mkFloatMult;
    // FloatTwoOp fadd2  <- mkFloatAdd;

    Reg#(State) state  <- mkReg(READY);

    Reg#(Float) prev <- mkReg(0);
    Reg#(Float) curr <- mkReg(0);

    Reg#(Float) accum <- mkReg(0);

    //FIFOF#(Float) samples <- mkSizedBRAMFIFOF(512);

    BRAM_IFC mem <- mkBRAM; 
    Reg#(Bit#(9)) tail_addr <- mkReg(0);
    Reg#(Bit#(1)) full <- mkReg(0);

    //Reg#(Float) term1  <- mkReg(?);
    //Reg#(Float) term2  <- mkReg(?); 

    rule enqSample(state == READY);
        $write ("Integrator.bsv: ready state");
        sampleIn.deq;
        // let newValue = sampleIn.first;
        prev <= curr;
        curr <= sampleIn.first;

	Bit#(9) waddr = 9'b0;
        // Find the mean of last 512 samples

        if(full == 1'b0) begin 
            fadd.put(accum, sampleIn.first);              // accum + new_value
            fmult.put(sampleIn.first, unpack(32'h3ca3d70a));  // curr  * delta 
            state <= STEP1;

	    if(tail_addr == 9'h1FF) 
		    full <= 1'b1;
        end else begin 
            //samples.deq; 
            // let s = samples.first;
	    Float f = negate(unpack(mem.read(zeroExtend(tail_addr))));	    
            fadd.put(accum, f); // remove first element in accum
            state <= FULL;
        end            
	tail_addr <= tail_addr + 1;
	mem.write(zeroExtend(tail_addr), pack(sampleIn.first));
        //samples.enq(sampleIn.first);
    endrule 

// magic numbers
// (1-L) = 0.905 = 0x3f67ae14
// delta = 0.02  = 0x3ca3d70a
// 1/512 = 0.001953125 = 0x3b000000
// delta/512 =         = 0x3823d70a

    function Float negate(Float float32);
        Bit#(32) bits = pack(float32); 
        bits[31] = ~bits[31];
        return unpack(bits);
    endfunction

    rule bufferFull(state == FULL);
        $write("Integrator.bsv: full state");
        let adjusted_accum <- fadd.get; 
        fadd.put(accum, curr);                  // accum + new_value
        fmult.put(curr, unpack(32'h3ca3d70a));  // ci * delta

        state <= STEP1;
    endrule

    rule step1(state == STEP1);
        $write("Integrator.bsv: step1 state");
        let new_accum <- fadd.get;
        let cur_delta <- fmult.get;
        curr <= cur_delta;
        accum <= new_accum;

        fmult.put(new_accum, unpack(32'h3823d70a)); // accum * (delta/512) = M*delta
        state <= STEP2;
    endrule

    rule step2(state == STEP2);
        $write("Integrator.bsv: step2 state");

        let mean <- fmult.get; // mean

        fadd.put(curr, negate(mean)); //c_i*delta - M*delta
        fmult.put(prev, unpack(32'h3f67ae14)); // (ci-1)(1-L)
        state <= STEP3;
    endrule

    rule step3(state == STEP3);
        $write("Integrator.bsv: step3 state");
        let part1 <- fadd.get;
        let part2 <- fmult.get;

        fadd.put(part1, part2); //sum lhs and rhs
        state <= STEP4;
    endrule

    rule step4(state == STEP4);
        $write("Integrator.bsv: step4 state");
        let result <- fadd.get;
        sampleOut.enq(result);
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

endmodule
