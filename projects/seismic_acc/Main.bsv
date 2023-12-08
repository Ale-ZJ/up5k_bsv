/* Main.Bsv
 * 
 * RPi sends data to spi_mosi pin
 * Main.Bsv processes the data
 * FPGA sends procced data to spi_miso pin
 */

import FIFO::*;
import Spi::*;

interface MainIfc;
	method Action spiIn(Bit#(8) data);
	method ActionValue#(Bit#(8)) spiOut;
	method Bit#(3) rgbOut;
endinterface

module mkMain(MainIfc);

	FIFO#(Bit#(8)) dataInQ <- mkFIFO;	// bytes received from RPi
	FIFO#(Bit#(8)) dataOutQ <- mkFIFO;	// bytes to be transmitted to RPi


	rule relayDataNoProcessing;
		dataInQ.deq;
		let d = dataInQ.first;
		dataOutQ.enq(d);
	endrule


	method Action spiIn(Bit#(8) data);
		dataInQ.enq(data);
	endmethod

	method ActionValue#(Bit#(8)) spiOut;
		dataOutQ.deq;
		let d = dataOutQ.first;
		return d;
	endmethod

	method Bit#(3) rgbOut;
		return 0;
	endmethod


endmodule
