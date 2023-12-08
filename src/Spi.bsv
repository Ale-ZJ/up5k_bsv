/* Spi.bsv
 * Written by Alexandra Zhang Jiang
 * 
 * SPI (Slave) Interface only, no simulation (bsim)
 * SPI has four signals: spi_ssn, spi_sck, spi_mosi, spi_miso. 
 * 
 * This implementation is for SPI Mode 0
 *      CPOL=0 (spi_clk from master is low when idle)
 *      CPHA=0 (spi reads data from master on the rising edge of spi_clk)
 * 
 * There are two time domains: the FPGA's and SPI's signals. 
 * Meaning that there are two clock frequencies that would need to be 
 * syncronized.  Assume fpga's clk is higher than spi
 *
 */

import FIFO::*;
 
interface SpiUserIfc;
    method Action send(Bit#(8) word);
    method ActionValue#(Bit#(8)) get;
endinterface

// Interface for FPGA's pins
interface SpiIfc;
    interface SpiUserIfc user;

    // OUTPUT
    (* always_ready *)
    method Bit#(1) serial_out;
    
    // INPUTS 
	(* always_enabled, always_ready, prefix = "", result = "spi_mosi" *)
	method Action serial_in(Bit#(1) spi_mosi);
	(* always_enabled, always_ready, prefix = "", result = "spi_sck" *)
	method Action serial_clk(Bit#(1) spi_sck);
	(* always_enabled, always_ready, prefix = "", result = "spi_ssn" *)
	method Action serial_select(Bit#(1) spi_ssn);
endinterface


module mkSpi(SpiIfc);
    // Data signals
	FIFO#(Bit#(8)) outQ <- mkFIFO;  // word recived on MISO
	FIFO#(Bit#(8)) inQ <- mkFIFO;   // word to serialize to MISO

    // SPI signals
    Wire#(Bit#(1)) sckdw <- mkDWire(0); // input clk 
    Wire#(Bit#(1))  rxdw <- mkDWire(0); // input mosi bit
    Wire#(Bit#(1))  csdw <- mkDWire(1); // input cs bit, active low
    Reg#(Bit#(1))   txdr <- mkReg(0);   // output miso bit

    // Keep track of previous sck bit, this is used to detect 
    // rising edges or falling edges
    Reg#(Bit#(1)) prevSck <- mkReg(0);
    rule previousSck;
        prevSck <= sckdw;
    endrule

    // Write one bit at a time 
    //      1. Write at the falling edge (SPI clock goes from 1 to 0)
    //      2. spi_cs must remain low when writing complete word
	Reg#(Bit#(9)) tx_word <- mkReg(0);
	Reg#(Bit#(4)) tx_cnt <- mkReg(0);
    rule dataDriving;
        if (csdw==1) begin
            tx_cnt <= 8;
        end else begin
            // in the middle of transmitting word
            if (sckdw==0 && prevSck==1 && tx_cnt != 0) begin
                tx_word <= {1'b0, tx_word[8:1]};
                txdr <= tx_word[0];
                tx_cnt <= tx_cnt - 1;
            end
            // dequeue new word to transmit
            else if (sckdw==0 && prevSck==1) begin
                inQ.deq;
                let word = inQ.first;
                tx_word <= {word, 1'b0};
                tx_cnt <= 8;
            end
        end 
    endrule


    // Read one bit at a time until we get a word
    //      1. Read at spi_sck rising edge (SPI clock goes from 0 to 1)
    //      2. spi_cs must remain low when reading a word
    Reg#(Bit#(8)) rx_word <- mkReg(0);
    Reg#(Bit#(4)) rx_cnt <- mkReg(0);
    rule dataSampling;
        if (csdw==1) begin
            rx_cnt <= 8;
        end else begin
            // in the middle of sampling word
            if (sckdw==1 && prevSck==0 && rx_cnt!=0) begin
                rx_word <= {rxdw, rx_word[7:1]};
                rx_cnt <= rx_cnt - 1;
            end
            // done sampling 
            else if (sckdw==1 && prevSck==0) begin
                outQ.enq(rx_word);
            end
        end
    endrule

    

	Reg#(Bit#(4)) rxin <- mkReg(4'b1111);
	Reg#(Bit#(4)) sckin <- mkReg(4'b1111);
	Reg#(Bit#(4)) csin <- mkReg(4'b1111);

    interface SpiUserIfc user;
        method Action send(Bit#(8) word);
            inQ.enq(word);
        endmethod
        method ActionValue#(Bit#(8)) get;
            outQ.deq;
            return outQ.first;
        endmethod
    endinterface

    // OUT: Put txdr bit on the spi_miso pin
    method Bit#(1) serial_out;
        return txdr;
    endmethod

    // IN: Noise debouncing spi_mosi pin to read one bit into rxdw wire
	method Action serial_in(Bit#(1) spi_mosi);
        rxin <= {spi_mosi, rxin[3:1]};
        rxdw <= (rxin==0)?0:1;
    endmethod

    // IN: Noise debouncing spi_sck pin to read one bit into sckdw wire
	method Action serial_clk(Bit#(1) spi_sck);
        sckin <= {spi_sck, sckin[3:1]};
        sckdw <= (sckin==0)?0:1;
    endmethod
    
    // IN: Noise debouncing spi_ssn pin to read one bit into csdw wire
	method Action serial_select(Bit#(1) spi_ssn);
        csin <= {spi_ssn, csin[3:1]};
        csdw <= (csin==0)?0:1;
    endmethod
endmodule
