module top (
			output wire led_blue,
            output wire led_green,
            output wire led_red,
			output spi_sdo,
			input spi_sdi,
            input spi_sck,
            input spi_ncs
			);

	

	wire clk; // 24 mhz clock
	SB_HFOSC# (
		.CLKHF_DIV("0b01") // divide clock by 2
	) inthosc(.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk));

	wire rst; 
	reg [3:0] cntr;
	assign rst = (cntr == 15);
	initial
	begin
		cntr <= 0;
	end
	always @ (posedge clk)
	begin
		if ( cntr != 15 ) begin
			cntr <= cntr + 1;
		end
	end



	mkBsvTop hwtop(.CLK(clk), .RST_N(rst), 
	.led_blue(led_blue), .led_green(led_green), .led_red(led_red),
		.spi_sdo(spi_sdo), .spi_sdi(spi_sdi), .spi_sck(spi_sck), .spi_ncs(spi_ncs));
endmodule