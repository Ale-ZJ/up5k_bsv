import FIFO::*;
import RegFile::*;


//Verilog interface
interface BRAM_IFC;
	
	method Action write(Bit#(11) waddr, Bit#(32) wdata);
	method Bit#(32) read(Bit#(11) raddr);
endinterface

import "BVI" BRAM512 = module mkVBRAM(BRAM_IFC ifc);
	
	method write(waddr, wdata) enable(we) clocked_by (clk);
	method rdata read(raddr) clocked_by (clk);

	//input_clock wclk(wclk) <- exposeCurrentClock;
	//input_clock rclk(rclk) <- exposeCurrentClock;
	default_clock clk(clk);
	default_reset no_reset; 

	schedule (read, write) CF (read, write);

	//schedule (read) SB (write);
	//schedule (read) CF (read);
	//schedule (write) C (write);

	//schedule 
	//CF conflict-free
	//SB sequences before
	//SBR sequences before, with range conflict
	//C conflicts
endmodule

module mkSimBRAM(BRAM_IFC);

	RegFile#(Bit#(11), Bit#(32)) mem <- mkRegFile(0, 1024);

	method Action write(Bit#(11) waddr, Bit#(32) wdata);
		mem.upd(waddr, wdata);
	endmethod

	method Bit#(32) read(Bit#(11) raddr) = mem.sub(raddr);
endmodule

module mkBRAM(BRAM_IFC);
	BRAM_IFC mem <- genVerilog ? mkVBRAM : mkSimBRAM;

	method Action write(Bit#(11) waddr, Bit#(32) wdata);
		mem.write(waddr, wdata);
	endmethod

	method Bit#(32) read(Bit#(11) raddr) = mem.read(raddr);
endmodule
