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


	rule relayData;
		dataInQ.deq;
		let d = dataInQ.first;
		dataOutQ.enq(8'b01000001); // always send char 'A'
		// dataOutQ.enq(8'b00000000); // always send 0
		// dataOutQ.enq(8'b10101010); // always send this
		// dataOutQ.enq(d); 
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