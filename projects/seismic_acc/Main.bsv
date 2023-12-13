/* Main.Bsv
 * 
 * RPi sends data to spi_mosi pin
 * Main.Bsv processes the data
 * FPGA sends procced data to spi_miso pin
 */

import FIFO::*;
import Spi::*;
import Integrator::*;

interface MainIfc;
	method Action spiIn(Bit#(8) data);
	method ActionValue#(Bit#(8)) spiOut;
	//method Bit#(3) rgbOut;
endinterface

module mkMain(MainIfc);

	FIFO#(Bit#(8)) dataInQ <- mkFIFO;	// bytes received from RPi
	FIFO#(Bit#(8)) dataOutQ <- mkFIFO;	// bytes to be transmitted to RPi


	Reg#(Bit#(4)) count <- mkReg(0);
	Reg#(Bit#(4)) shiftCount <- mkReg(0);
	Reg#(Bit#(8)) first <- mkReg(?);
	Reg#(Bit#(8)) second <- mkReg(?);
	Reg#(Bit#(8)) third <- mkReg(?);
	Reg#(Bit#(8)) fourth <- mkReg(?);

	IntegratorInterface integrator1 <- mkIntegrator;
	IntegratorInterface integrator2 <- mkIntegrator;

	Reg#(Bit#(32)) shiftout <- mkReg(?);

	rule relayDataToIntegrator;
		dataInQ.deq;
		
		let d = dataInQ.first;

		first <= second; second <= third; third <= fourth; fourth <= d;


		if(count >= 3) begin 
			count <= 0;
			integrator1.addSample(unpack({first, second, third, fourth}));
		end else begin
			count <= count + 1;
		end

	endrule

	rule relayIntegratorToIntegrator;
		integrator2.addSample(integrator1.integrateOut());
	endrule

	rule relayData1 (shiftCount == 0);

		shiftout <= pack(integrator2.integrateOut());

		dataOutQ.enq(shiftout[7:0]);
		shiftCount <= shiftCount + 1;
	endrule

	rule relayData2 (shiftCount == 1);
		shiftout <= shiftout >> 8;
		dataOutQ.enq(shiftout[7:0]);
		shiftCount <= shiftCount + 1;
	endrule

	rule relayData3 (shiftCount == 2);
		shiftout <= shiftout >> 8;
		dataOutQ.enq(shiftout[7:0]);
		shiftCount <= shiftCount + 1;
	endrule
	
	rule relayData4 (shiftCount == 3);
		shiftout <= shiftout >> 8;
		dataOutQ.enq(shiftout[7:0]);
		shiftCount <= 0;
	endrule

	method Action spiIn(Bit#(8) data);
		dataInQ.enq(data);
	endmethod

	method ActionValue#(Bit#(8)) spiOut;
		dataOutQ.deq;
		let d = dataOutQ.first;
		return d;
	endmethod

	//method Bit#(3) rgbOut;
	//	return 0;
	//endmethod


endmodule
