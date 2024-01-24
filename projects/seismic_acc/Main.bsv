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

interface MainIfc;
	method Action uartIn(Bit#(8) data);
	method ActionValue#(Bit#(8)) uartOut;
	method Bit#(3) rgbOut;
endinterface

module mkMain(MainIfc);

	FIFO#(Bit#(8)) dataInQ <- mkFIFO;	// bytes received from RPi
	FIFO#(Bit#(8)) dataOutQ <- mkFIFO;	// bytes to be transmitted to RPi

	// FIFO#(Bit#(32)) floatQ <- mkFIFO; 	// debugging: floats read
	Reg#(Bit#(32)) inputBuffer <- mkReg(0);
	Reg#(Bit#(2)) inputBufferCnt <- mkReg(0);
	IntegratorInterface integrator1 <- mkIntegrator;

	LaplaceRandFloat32Ifc dpModule <- mkLaplaceRandFloat32;

	rule readFloat;
		dataInQ.deq;
		let msb_byte = dataInQ.first;
		Bit#(32) doubleword = (inputBuffer>>8)|(zeroExtend(msb_byte)<<24);
		inputBuffer <= doubleword;
		if ( inputBufferCnt == 3 ) begin
			inputBufferCnt <= 0;
			//floatQ.enq(unpack(doubleword));
			integrator1.addSample(unpack(doubleword));
		end else begin
			inputBufferCnt <= inputBufferCnt + 1;
		end 
	endrule

	IntegratorInterface integrator2 <- mkIntegrator;
	rule relayFirstIntegral;
		let fi <- integrator1.integrateOut; // QUESTION: the rule will only fire when integrator1 has a value ready?
		integrator2.addSample(fi);
	endrule

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
			let float <- integrator2.integrateOut;
			Bit#(8) lsb_byte = truncate(pack(float));
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
