/*
Anf Floof
32-bit Embedded 3D Graphics Processor

Texture Address Generator
*/

`default_nettype none

module anfFl_tex_addrGen
	(
		input [15:0] yPixel,
		input [15:0] xPixel,
		input [63:0] texMeta,

		output reg [31:0] address,
		output reg [3:0] yTexel,
		output reg [3:0] xTexel
	);

	localparam fmt_RGB_24 = 5'b000_00;
	localparam fmt_ARGB_32 = 5'b001_00;

	localparam fmt_RGB_16 = 5'b000_01;
	localparam fmt_ARGB_16 = 5'b001_01;
	localparam fmt_RGB_15 = 5'b010_01;
	localparam fmt_ARGB_15_PUNCHTHROUGH  = 5'b011_01;

	localparam fmt_RGB_ETC2 = 5'b000_10;
	localparam fmt_ARGB_ETC2 = 5'b001_10;
	localparam fmt_ARGB_ETC2_PUNCHTHROUGH = 5'b010_10;
	localparam fmt_R_EAC_UNSIGNED = 5'b100_10;
	localparam fmt_R_EAC_SIGNED = 5'b101_10;
	
	localparam fmt_RGB_24_TILED = 5'b000_11;
	localparam fmt_ARGB_32_TILED = 5'b001_11;
	localparam fmt_RGB_16_TILED = 5'b010_11;
	localparam fmt_ARGB_16_TILED = 5'b011_11;
	localparam fmt_R_8_TILED = 5'b100_11;
	localparam fmt_R_16_TILED = 5'b101_11;


	localparam fc_8BPC = 2'b00;
	localparam fc_16BITS = 2'b01;
	localparam fc_COMPRESSED = 2'b10;
	localparam fc_TILED = 2'b11;

	wire [4:0] format;
	wire [1:0] formatClass;
	wire [3:0] heightExp;
	wire [3:0] widthExp;
	wire [31:0] baseAddr;

	assign format = texMeta[4:0];
	assign formatClass = format[1:0];
	assign baseAddr = texMeta[63:32];
	assign heightExp = texMeta[8:5];
	assign widthExp = texMeta[12:9];

	// Bitmaps
	wire [15:0] yOffset;
	wire [15:0] offsetPixels;

	assign yOffset = yPixel << widthExp;
	assign offsetPixels = yOffset + xPixel;

	// Tiled Textures
	wire [3:0] tiled_widthExp;
	wire [11:0] tiled_yBlock;
	wire [11:0] tiled_xBlock;
	wire [15:0] tiled_yOffset;
	wire [15:0] tiled_offsetBlocks;

	assign tiled_widthExp = widthExp - 4'd4;
	assign tiled_yBlock = yPixel[15:4];
	assign tiled_xBlock = xPixel[15:4];
	assign tiled_yOffset = {4'b0, tiled_yBlock} << tiled_widthExp;
	assign tiled_offsetBlocks = tiled_yOffset | {4'b0, tiled_xBlock};

	wire [3:0] tiled_yLocalPixel;
	wire [3:0] tiled_xLocalPixel;
	wire [7:0] tiled_localOffsetPixels;
	wire [31:0] tiled_offsetPixels; 

	assign tiled_yLocalPixel = yPixel[3:0];
	assign tiled_xLocalPixel = xPixel[3:0];
	assign tiled_localOffsetPixels = {tiled_yLocalPixel, tiled_xLocalPixel};
	assign tiled_offsetPixels = {8'b0, tiled_offsetBlocks, tiled_localOffsetPixels};

	// Compressed Textures
	// Only base address needed.
	wire [3:0] comp_widthExp;
	wire [13:0] comp_yBlock;
	wire [13:0] comp_xBlock;
	wire [15:0] comp_yOffset;
	wire [15:0] comp_offsetBlocks;

	// All supported compressed formats use 4x4 blocks, either 8 bytes or 16 bytes per block.
	assign comp_widthExp = widthExp - 4'd2;
	assign comp_yBlock = yPixel[15:2];
	assign comp_xBlock = xPixel[15:2];
	assign comp_yOffset = {2'b0, comp_yBlock} << comp_widthExp;
	assign comp_offsetBlocks = comp_yOffset | {2'b0, comp_xBlock};

	reg[31:0] relAddr;
	
	always @(*) begin
		yTexel = xPixel[3:0];
		xTexel = yPixel[3:0];

		case(formatClass)
			fc_8BPC: begin
				if(format == fmt_RGB_24) relAddr = {15'b0, offsetPixels, 1'b0} + {16'b0, offsetPixels};
				else if(format == fmt_ARGB_32) relAddr = {14'b0, offsetPixels, 2'b0}; 
			end
			fc_16BITS: begin 
				relAddr = {15'b0, offsetPixels, 1'b0};
			end
			fc_COMPRESSED: begin
				case(format)
					fmt_RGB_ETC2: relAddr = {13'b0, comp_offsetBlocks, 3'b0};
					fmt_ARGB_ETC2: relAddr = {12'b0, comp_offsetBlocks, 4'b0};
					fmt_R_EAC_UNSIGNED: relAddr = {13'b0, comp_offsetBlocks, 3'b0};
					default: relAddr = 32'b0;
				endcase
			end
			fc_TILED: begin 
				case(format)
					fmt_RGB_24_TILED: relAddr = {tiled_offsetPixels[30:0], 1'b0} + tiled_offsetPixels;
					fmt_ARGB_32_TILED: relAddr = {tiled_offsetPixels[29:0], 2'b0};
					fmt_RGB_16_TILED: relAddr = {tiled_offsetPixels[30:0], 1'b0};
					fmt_ARGB_16_TILED: relAddr = {tiled_offsetPixels[30:0], 1'b0};
					fmt_R_8_TILED: relAddr = tiled_offsetPixels;
					fmt_R_16_TILED: relAddr = {tiled_offsetPixels[30:0], 1'b0};
					default: relAddr = 32'b0;
				endcase
			end
		endcase

		address = baseAddr + relAddr;
	end

endmodule