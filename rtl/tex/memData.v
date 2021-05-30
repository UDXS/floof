/*
Anf Floof
32-bit Embedded 3D Graphics Processor

Texture Data Fetcher
*/

`default nettype none

module anfFl_tex_memData
	(
		input reset,
		input clk,

		input [15:0] yPixel,
		input [15:0] xPixel,
		input [63:0] texMeta,
		output [127:0] colorPkt
		
		input ready,
		output valid,

		`anfFl_MEM_RD_PORTS
	);

	reg [31:0] colorPktAddr;

	anfFl_tex_addrCalc pixelAddrGen	(
									.yPixel(yPixel),
									.xPixel(xPixel),
									.texMeta(texMetadata),
									.address(colorPktAddr)
									);

	always @(*) begin
		
	end

endmodule