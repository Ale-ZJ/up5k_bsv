/* Main.Bsv
 * 
 * RPi sends data to spi_mosi pin
 * Main.Bsv processes the data
 * FPGA sends procced data to spi_miso pin

	When reading and writing a float, we need to queue
	one float in four parts bc of how we defined UART
 */

import FIFO::*;
import Integrator::*;

interface MainIfc;
	method Action uartIn(Bit#(8) data);
	method ActionValue#(Bit#(8)) uartOut;
	method Bit#(3) rgbOut;
endinterface

module mkMain(MainIfc);

	FIFO#(Bit#(8)) dataInQ <- mkFIFO;	// bytes received from RPi
	FIFO#(Bit#(8)) dataOutQ <- mkFIFO;	// bytes to be transmitted to RPi
	FIFO#(Bit#(32)) floatQ <- mkFIFO; 	// floats read

	Reg#(Bit#(32)) inputBuffer <- mkReg(0);
	Reg#(Bit#(2)) inputBufferCnt <- mkReg(0);
    Reg#(Bit#(32)) outputBuffer <- mkReg(0);
	Reg#(Bit#(2)) outputBufferCnt <- mkReg(0);

	IntegratorInterface integrator1 <- mkIntegrator;
	// IntegratorInterface integrator2 <- mkIntegrator;

	rule readFloat;
		$write("Main.bsv: readFloat\n");
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

	rule writeFloat;
		$write("Main.bsv: inside writeFloat\n");

		if (outputBufferCnt > 0 ) begin
			outputBufferCnt <= outputBufferCnt - 1;
			Bit#(8) lsb_byte = truncate(outputBuffer); // read 8 LSB
			outputBuffer <= (outputBuffer>>8);
			dataOutQ.enq(lsb_byte);
		end else begin
			$write("Main.bsv: read float into buffer \n");
			// floatQ.deq;
			// let float = floatQ.first;
			let float <- integrator1.integrateOut;
			Bit#(8) lsb_byte = truncate(pack(float));
			outputBuffer <= (pack(float)>>8);
			outputBufferCnt <= 3;
			dataOutQ.enq(lsb_byte);
		end
	endrule	

	



	// Reg#(Bit#(4)) count <- mkReg(0);
	// Reg#(Bit#(4)) shiftCount <- mkReg(0);
	// Reg#(Bit#(8)) first <- mkReg(?);
	// Reg#(Bit#(8)) second <- mkReg(?);
	// Reg#(Bit#(8)) third <- mkReg(?);
	// Reg#(Bit#(8)) fourth <- mkReg(?);


	// Reg#(Bit#(32)) shiftout <- mkReg(?);

	// rule relayDataToIntegrator;
	// 	dataInQ.deq;
	// 	let d = dataInQ.first;
	// 	first <= second; second <= third; third <= fourth; fourth <= d;

	// 	if(count >= 3) begin 
	// 		count <= 0;
	// 		integrator1.addSample(unpack({first, second, third, fourth}));
	// 	end else begin
	// 		count <= count + 1;
	// 	end
	// endrule


	// rule relayData1 (shiftCount == 0);
	// 	shiftout <= pack(integrator2.integrateOut());

	// 	dataOutQ.enq(shiftout[7:0]);
	// 	shiftCount <= shiftCount + 1;
	// endrule

	// rule relayData2 (shiftCount == 1);
	// 	shiftout <= shiftout >> 8;
	// 	dataOutQ.enq(shiftout[7:0]);
	// 	shiftCount <= shiftCount + 1;
	// endrule

	// rule relayData3 (shiftCount == 2);
	// 	shiftout <= shiftout >> 8;
	// 	dataOutQ.enq(shiftout[7:0]);
	// 	shiftCount <= shiftCount + 1;
	// endrule
	
	// rule relayData4 (shiftCount == 3);
	// 	shiftout <= shiftout >> 8;
	// 	dataOutQ.enq(shiftout[7:0]);
	// 	shiftCount <= 0;
	// endrule

	method Action uartIn(Bit#(8) data);
		// $write( "urart in\n");
		dataInQ.enq(data);
		// if ( data[0] == 1 ) ram.req(zeroExtend(data), zeroExtend(data), True, 4'b1111);
		// else ram.req(zeroExtend(data), ?, False, ?);
		$write( "Main.bsv: uartIn%d\n", data);

	endmethod
	method ActionValue#(Bit#(8)) uartOut;
		// $write( "urart out\n");
		dataOutQ.deq;
		let d = dataOutQ.first;
		$write( "Main.bsv: uartOut %d \n", d );
		return d;

	endmethod

	method Bit#(3) rgbOut;
		return 0;
	endmethod


endmodule
