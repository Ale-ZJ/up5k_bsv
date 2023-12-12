import Clocks :: *;
import Vector::*;

import Main::*;

// import Uart::*;
import Spi::*;

// import "BDPI" function Action bdpiSwInit();

// Declare all pins
interface BsvTopIfc;

	// OUTPUT
	(* always_ready *)
	method Bit#(1) blue;
	(* always_ready *)
	method Bit#(1) green;
	(* always_ready *)
	method Bit#(1) red;
	(* always_ready *)
        method Bit#(1) serial_out;

		method Bit#(1) spi_miso;
	
    // INPUTS 
	(* always_enabled, always_ready, prefix = "", result = "spi_mosi" *)
	method Action serial_in(Bit#(1) spi_mosi);
	(* always_enabled, always_ready, prefix = "", result = "spi_sck" *)
	method Action serial_clk(Bit#(1) spi_sck);
	(* always_enabled, always_ready, prefix = "", result = "spi_ssn" *)
	method Action serial_select(Bit#(1) spi_ssn);
endinterface

module mkBsvTop(BsvTopIfc);
	// UartIfc uart <- mkUart(2500);
	MainIfc hwmain <- mkMain;
	SpiIfc spi <- mkSpi;

	rule relaySpiIn;
		Bit#(8) d <- spi.user.get;
		hwmain.spiIn(d);
	endrule

	rule relaySpiOut;
		let d <- hwmain.spiOut;
		spi.user.send(d);
	endrule

	// LEDs
	method Bit#(1) blue;
		return hwmain.rgbOut()[2];
	endmethod
	method Bit#(1) green;
		return hwmain.rgbOut()[1];
	endmethod
	method Bit#(1) red;
		return hwmain.rgbOut()[0];
	endmethod

	// Spi
	method Bit#(1) serial_out;
		return spi.serial_out;
	endmethod
	method Action serial_in(Bit#(1) spi_mosi);
		spi.serial_in(spi_mosi);
	endmethod
	method Action serial_clk(Bit#(1) spi_sck);
		spi.serial_clk(spi_sck);
	endmethod
	method Action serial_select(Bit#(1) spi_ssn);
		spi.serial_select(spi_ssn);
	endmethod

	method Bit#(1) spi_miso;
		return spi.serial_out;
	endmethod

endmodule

// module mkBsvTop_bsim(Empty);
// 	UartUserIfc uart <- mkUart_bsim;
// 	MainIfc hwmain <- mkMain;
// 	Reg#(Bool) initialized <- mkReg(False);
// 	rule doinit ( !initialized );
// 		initialized <= True;
// 		bdpiSwInit();
// 	endrule

// 	rule relayUartIn;
// 		Bit#(8) d <- uart.get;
// 		hwmain.uartIn(d);
// 	endrule
// 	rule relayUartOut;
// 		let d <- hwmain.uartOut;
// 		uart.send(d);
// 	endrule
// endmodule
