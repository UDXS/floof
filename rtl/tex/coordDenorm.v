/*
Anf Floof
32-bit Embedded 3D Graphics Processor

TEX - Texture Sampling Unit
Coordinate Denormalization Unit
*/

module anfFl_tex_coordDenorm
	(
		input [31:0] inCoord,
		input [3:0] lengthExp,
		output [15:0] outIndex
	);

	wire [31:0] signedFractional;
	wire [31:0] shifted;
	wire [15:0] truncated;
	wire [15:0] negativeTruncated;
	wire [15:0] length;
	wire [15:0] mirrored;

	assign signedFractional = {{16{inCoord[31]}}, inCoord[15:0]};
	assign shifted[31:1] = signedFractional << lengthExp;

	assign truncated = shifted[31:16];
	assign negativeTruncated = ~truncated + 1;
	assign length = 16'b1 << lengthExp;
	assign mirrored = length - negativeTruncated;
	assign outIndex = truncated[15] ? mirrored : truncated;
	
endmodule