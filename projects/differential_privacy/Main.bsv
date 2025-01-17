/* Main.Bsv
 * 
 * RPi sends floating point samples to UART_RX pin of FPGA
 * Main.Bsv receives one sample as four bytes. It assembles the sample
 * and takes two integral of the sample. 
 * FPGA sends the processed data as four bytes to UART_TX pin
 */

import FIFO::*;
import Integrator::*;
import Random::*;
import SimpleFloat::*;
import FloatingPoint::*;

import Tausworthe::*;

interface MainIfc;
	method Action uartIn(Bit#(8) data);
	method ActionValue#(Bit#(8)) uartOut;
	method Bit#(3) rgbOut;
endinterface

module mkMain(MainIfc);

	FIFO#(Bit#(8)) dataInQ <- mkFIFO;	// bytes received from RPi
	FIFO#(Bit#(8)) dataOutQ <- mkFIFO;	// bytes to be transmitted to RPi

	FIFO#(Bit#(32)) sampleIn <- mkFIFO;

	Reg#(Bit#(32)) inputBuffer <- mkReg(0);
	Reg#(Bit#(2)) inputBufferCnt <- mkReg(0);


	TauswortheIfc rand1 <- mkTausworthe;
	TauswortheIfc rand2 <- mkTausworthe;
	Reg#(Bit#(23)) randshift1 <- mkReg(?);
	Reg#(Bit#(23)) randshift2 <- mkReg(?);
	Reg#(Bit#(5))  count  <- mkReg(?);

	RandIntToFloatIfc itf <- mkRandIntToFloat;
	RandIntToFloatIfc itf2 <- mkRandIntToFloat;
	//RandIfc#(32) rand2
	
	LaplaceRandFloat32Ifc dpModule <- mkLaplaceRandFloat32;

	FloatTwoOp fadd <- mkFloatAdd;

	FIFO#(Float) outQ <- mkFIFO;

	// Reg#(Bit#(2)) rand_sel <- mkReg(0);
	//Reg#(Bit#(32)) randSample <- mkReg(0);

	// Reg#(Bit#(1)) init_flag <- mkReg(0);
	// Reg#(Bool) rand_sel <- mkReg(False);
	// rule initialize(init_flag == 0);
	// 	rand1.setSeed(truncate(96'h2facf7c9e445afa9844d1d3b));
	// 	rand2.setSeed(truncate(96'he74f2c5a38e112c88699361b));
	// 	init_flag <= 1'b1;
	// endrule

    rule relayRand;
		let rv1 <- rand1.get;
		// let rv2 <- rand2.get;

		//$display("rand  : %8d, %8d", rv1, rv2);
		// if(rand_sel == True) begin 
		// 	itf.randVal(rv1);
		// end else begin 
		// 	itf2.randVal(rv1);
		// end
		itf.randVal(rv1);
		// itf2.randVal(rv2);
	endrule

	rule relayConvert;
		let randFloat <- itf.get;
		// let randFloat2 <- itf2.get;
		//$display("float : %f, %f", randFloat1, randFloat2);
		dpModule.enqRand(randFloat);
		// rand_sel <= 2'b0;
	endrule

	rule relayNoise;
		sampleIn.deq;
		let noise <- dpModule.get;
		Bit#(32) data = sampleIn.first;
		Float float_noise = unpack(noise);
		//$display("noise : %32u", float_noise);

		fadd.put(unpack(noise), unpack(data));
	endrule

	rule relayResult;
		let result <- fadd.get;
		outQ.enq(result);
	endrule

	// Reg#(Bit#(32)) ticks <- mkReg(0);
	// rule cycleCounting;
	// 	ticks <= ticks + 1;
	// endrule

	rule readFloat;
		dataInQ.deq;
		let msb_byte = dataInQ.first;
		Bit#(32) doubleword = {msb_byte[7:0], inputBuffer[31:8]}; //(inputBuffer>>8)|(zeroExtend(msb_byte)<<24);
		inputBuffer <= doubleword;
		if ( inputBufferCnt == 3 ) begin
			inputBufferCnt <= 0;
			//floatQ.enq(unpack(doubleword));
			//$write("Main.bsv: IN integrator1, ticks: %d\n", ticks);
			//integrator1.addSample(unpack(doubleword));
			sampleIn.enq(inputBuffer);
		end else begin
			inputBufferCnt <= inputBufferCnt + 1;
		end 
	endrule

	//rule relayFirstIntegral;
	//	let fi <- integrator1.integrateOut; // QUESTION: the rule will only fire when integrator1 has a value ready?
	//	integrator2.addSample(fi);
	//endrule

    Reg#(Bit#(32)) outputBuffer <- mkReg(0);
	Reg#(Bit#(2)) outputBufferCnt <- mkReg(0);
	rule writeResult;
		if (outputBufferCnt > 0 ) begin
			outputBufferCnt <= outputBufferCnt - 1;
			Bit#(8) lsb_byte = truncate(outputBuffer); // read 8 LSB 
			outputBuffer <= (outputBuffer>>8);
			dataOutQ.enq(lsb_byte);
		end else begin
			// floatQ.deq;
			// let float = floatQ.first;
			// let float <- integrator2.integrateOut;
			outQ.deq;
			let float = outQ.first;
			Bit#(8) lsb_byte = truncate(pack(float));
			//$write("Main.bsv: OUT integrator 2, ticks: %d\n", ticks);
			outputBuffer <= (pack(float)>>8);
			outputBufferCnt <= 3;
			dataOutQ.enq(lsb_byte);
		end
	endrule	

	method Action uartIn(Bit#(8) data);
		//$write( "Main.bsv: uartIn%d\n", data);
		dataInQ.enq(data);
	endmethod

	method ActionValue#(Bit#(8)) uartOut;
		dataOutQ.deq;
		let d = dataOutQ.first;
		//$write( "Main.bsv: uartOut %d\n", d );
		return d;
	endmethod

	method Bit#(3) rgbOut;
		return 0;
	endmethod


endmodule
