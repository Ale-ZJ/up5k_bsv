/* Spi.bsv
 * Written by Alexandra Zhang Jiang
 * 
 * SPI (Slave) implementation only, no simulation (bsim)
 * SPI has four signals: spi_ncs, spi_sck, spi_sdi, spi_sdo. 
 * 
 * This implementation is for SPI Mode 0
 *      CPOL=0 (spi_sck from master is low when idle)
 *      CPHA=0 (spi reads data from master on the rising edge of spi_sck)
 * 
 * There are two time domains: the FPGA's and SPI's signals. 
 * Meaning that there are two clock frequencies that would need to be 
 * syncronized.  Assume fpga's clk is higher than spi's.
 *
 */

import FIFO::*;
 
// Interface for FPGA's pins
interface SpiSlavePins;
    // slave out
    (* always_ready *)
    method Bit#(1) sdo;
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

// Interface for users
interface SpiIfc;
    method Action send(Bit#(8) word); // shift-out word to SDO pin
    method ActionValue#(Bit#(8)) get; // sample-in word from SDI pin
    method Bit#(3) rgbOut();
    (* prefix = "" *)
    interface SpiSlavePins pins;
endinterface

module mkSpi(SpiIfc);
    Reg#(Bit#(3)) led <- mkReg(0);
    // Data signals
	FIFO#(Bit#(8)) outQ <- mkFIFO;  // words sampled-in
	FIFO#(Bit#(8))  inQ <- mkFIFO;   // words to shift-out

    // SPI signals
    Reg#(Bit#(1)) currSck <- mkReg(0); // input clk 
    Reg#(Bit#(1))  ncsBit <- mkReg(1); // input ncs bit, active low
    Reg#(Bit#(1))      rx <- mkReg(0); // input sdi bit
    Reg#(Bit#(1))      tx <- mkReg(0); // output sdo bit

    // Keep track of previous clock bit, this is used to detect 
    // rising edges or falling edges
    Reg#(Bit#(1)) prevSck <- mkReg(0);
    rule previousSck;
        prevSck <= currSck;
    endrule

    // Write a word, one bit at a time 
    //      1. Write at the falling edge (SPI clock goes from 1 to 0)
    //      2. Active-Low Chip Select must remain low when writing complete word
	Reg#(Bit#(8)) tx_word <- mkReg(0);
	Reg#(Bit#(4))  tx_cnt <- mkReg(0);
    rule shiftoutWord (prevSck == 0 && currSck == 1 && tx_cnt != 0 && ncsBit == 0);
        tx <= tx_word[7];
        tx_word <= {tx_word[6:0], 1'b0};
        tx_cnt <= tx_cnt - 1;        
    endrule 

    rule setupTx (tx_cnt == 0);
        inQ.deq;
        let t = inQ.first;
        tx_word <= t;
        tx_cnt <= 8;
    endrule


    // Read one bit at a time until we get a word
    //      1. Read at spi_sck rising edge (SPI clock goes from 0 to 1)
    //      2. spi_cs must remain low when reading a word
    Reg#(Bit#(8)) rx_word <- mkReg(0);
    Reg#(Bit#(4))  rx_cnt <- mkReg(0);
    rule sampleWord (prevSck==0 && currSck==1); // reading on rising
		// rx_word <= {rx, rx_word[7:1]};
        rx_word <= {rx_word[6:0], rx}; // msb
		if ( rx_cnt >= 7 ) begin
			rx_cnt <= 0;
			outQ.enq(rx_word);
			led <= 3'b111;
		end else begin
			rx_cnt <= rx_cnt + 1;
		end
    endrule


    


    Reg#(Bit#(4)) rxin <- mkReg(4'b1111);
	Reg#(Bit#(4)) sckin <- mkReg(4'b1111);
	Reg#(Bit#(4)) ncsin <- mkReg(4'b1111);

    interface SpiSlavePins pins;
        // OUT: Put txdr bit on the spi_sdo pin
        method Bit#(1) sdo;
            return tx;
        endmethod

        // IN: Noise debouncing spi_sdi pin to read one bit into rxdw wire
        method Action sdi(Bit#(1) spi_sdi);
            rxin <= {spi_sdi, rxin[3:1]};
            rx <= (rxin==0)?0:1; 
        endmethod

        // IN: Noise debouncing spi_sck pin to read one bit into sckdw wire
        method Action sck(Bit#(1) spi_sck);
            sckin <= {spi_sck, sckin[3:1]};
            currSck <= (sckin==4'b1111)?1:0; // clock must be 1 when the fpga reads it four times
        endmethod
        
        // IN: Noise debouncing spi_ncs pin to read one bit into ncsBit
        method Action ncs(Bit#(1) spi_ncs);
            ncsin <= {spi_ncs, ncsin[3:1]};
            ncsBit <= (ncsin==0)?0:1; 
        endmethod
    endinterface

    method Bit#(3) rgbOut();
        return led;
    endmethod    
    method Action send(Bit#(8) word);
        inQ.enq(word);
    endmethod
    method ActionValue#(Bit#(8)) get;
        outQ.deq;
        return outQ.first;
    endmethod
    
endmodule