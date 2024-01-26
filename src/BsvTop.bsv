import Clocks :: *;
import Vector::*;

import Main::*;

import Uart::*;
import Spi::*;

import "BDPI" function Action bdpiSwInit();

// Declare all pins
interface BsvTopIfc;

	// OUTPUT
	(* always_ready *)
	method Bit#(1) led_blue;
	(* always_ready *)
	method Bit#(1) led_green;
	(* always_ready *)
	method Bit#(1) led_red;
	// slave out
    (* always_ready *)
    method Bit#(1) spi_sdo;
	// INPUT
    // slave in
	(* always_enabled, always_ready, prefix = "", result = "spi_sdi" *)
	method Action sdi(Bit#(1) spi_sdi);
    // slave clock
	(* always_enabled, always_ready, prefix = "", result = "spi_sck" *)
	method Action sck(Bit#(1) spi_sck);
    // active-low chip select
	(* always_enabled, always_ready, prefix = "", result = "spi_ncs" *)
	method Action ncs(Bit#(1) spi_ncs);
endinterface

module mkBsvTop(BsvTopIfc);
	// UartIfc uart <- mkUart(2500);
	MainIfc hwmain <- mkMain;
	SpiIfc spi <- mkSpi;

	// rule relayUartIn;
	// 	Bit#(8) d <- uart.user.get;
	// 	hwmain.uartIn(d);
	// endrule
	// rule relayUartOut;
	// 	let d <- hwmain.uartOut;
	// 	uart.user.send(d);
	// endrule

	rule relaySpiIn;
		Bit#(8) d <- spi.get;
		hwmain.spiIn(d);
	endrule

	rule relaySpiOut;
		let d <- hwmain.spiOut;
		spi.send(d);
	endrule

	// LEDs
	method Bit#(1) led_blue;
		return spi.rgbOut()[2];
	endmethod
	method Bit#(1) led_green;
		return spi.rgbOut()[1];
	endmethod
	method Bit#(1) led_red;
		return spi.rgbOut()[0];
	endmethod

	// UART
	// method Bit#(1) serial_txd;
	// 	return uart.serial_txd;
	// endmethod
	// method Action serial_rx(Bit#(1) serial_rxd);
	// 	uart.serial_rx(serial_rxd);
	// endmethod

	// SPI
	method Bit#(1) spi_sdo;
		return spi.pins.sdo;
	endmethod
	method Action sdi(Bit#(1) spi_sdi);
		spi.pins.sdi(spi_sdi);
	endmethod
	method Action sck(Bit#(1) spi_sck);
		spi.pins.sck(spi_sck);
	endmethod
	method Action ncs(Bit#(1) spi_ncs);
		spi.pins.ncs(spi_ncs);
	endmethod

endmodule

/*
module mkBsvTop_bsim(Empty);
	UartUserIfc uart <- mkUart_bsim;
	MainIfc hwmain <- mkMain;
	Reg#(Bool) initialized <- mkReg(False);
	rule doinit ( !initialized );
		initialized <= True;
		bdpiSwInit();
	endrule

	rule relayUartIn;
		Bit#(8) d <- uart.get;
		hwmain.uartIn(d);
	endrule
	rule relayUartOut;
		let d <- hwmain.uartOut;
		uart.send(d);
	endrule
endmodule
*/