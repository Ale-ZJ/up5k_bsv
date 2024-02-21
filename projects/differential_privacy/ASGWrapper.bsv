
interface VASGIfc;
	method Bit#(1) get();
endinterface

import "BVI" asg = module mkASG(VASGIfc);

	method randout get();

	default_clock clk(clk);
	default_reset rst_n(rst_n);
endmodule

