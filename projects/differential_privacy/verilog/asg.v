
module asg (
	output reg        randout,
	input             clk,
	input             rst_n	
);

parameter [27:0] MASK0 = 28'hff0000c;
parameter [28:0] MASK1 = 29'h1ffe0000;
parameter [29:0] MASK2 = 30'h3ff00011;

reg [27:0] lsfr0 = 28'ha85eacf;//28'h2a85eacf;
reg [28:0] lsfr1 = 29'h1de46c20;//29'h5de46c20;
reg [29:0] lsfr2 = 30'h384c2686;//30'h884c2686;

//reg [5:0]  count = 6'b0;
//reg [22:0] shift;

wire [31:0] lsfr2_next;
wire        which_lsfr;



assign lsfr2_next = MASK2 ^ (lsfr2 >> 1);
assign which_lsfr = lsfr2[0] == 1'b1 ? lsfr2_next[0] : lsfr2[0]; 
/**
always@(posedge clk or negedge rst_n) begin 
	if(~rst_n) begin 
		count <= 6'b0;
	end else if(count == 6'h17) begin
		out <= shift;
		count <= 6'b1;
	end else begin
		count <= count + 6'b1;
	end 
	shift <= {shift[21:0], lsfr0[0]^lsfr1[0]};
end**/

always@(posedge clk) begin
	randout <= lsfr0[0] ^ lsfr1[0];
end

always@(posedge clk or negedge rst_n) begin 
	if(~rst_n) begin 
		lsfr0 <= 30'h2a85eacf;
		lsfr1 <= 31'h5de46c20;
		lsfr2 <= 32'h884c2686;
	end else begin 
		if(lsfr2[0] == 1'b1) begin 
			lsfr2 <= lsfr2_next;
		end

		if(which_lsfr == 1'b1)  
			lsfr1 <= MASK1 ^ (lsfr1 >> 1);
		else 
			lsfr0 <= MASK0 ^ (lsfr0 >> 1);
	end
end
endmodule

