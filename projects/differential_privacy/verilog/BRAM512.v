module BRAM512(
	output reg [31:0] rdata,
	input         clk, re, we,
	input  [8:0] raddr,
	input  [8:0] waddr,
	input  [31:0] mask, wdata
);

reg [31:0] mem [511:0];

always@(posedge clk) begin
	if(re)
		rdata <= mem[raddr];
end

always@(posedge clk) begin 
	if(we)
		mem[waddr] <= wdata;
end
endmodule
