module top (output spi_miso,
			input spi_mosi,
            input spi_sck,
            input spi_ssn
			);

			//output wire led_blue,
            //output wire led_green,
            //output wire led_red,
	

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


	//.blue(led_blue), .green(led_green), .red(led_red),

	mkBsvTop hwtop(.CLK(clk), .RST_N(rst), 
		.spi_miso(spi_miso), .spi_mosi(spi_mosi), .spi_sck(spi_sck), .spi_ssn(spi_ssn));
endmodule