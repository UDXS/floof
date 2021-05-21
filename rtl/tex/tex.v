/*
Anf Floof
32-bit Embedded 3D Graphics Processor

TEX - Texture Sampling Unit
*/
`include "bus/fmpa.v"
`include "bus/mem.v"
`include "tex/memMeta.v"
`include "tex/memData.v"
`include "tex/coordDenorm.v"
`include "tex/addrGen.v"

module anfFl_tex
	(
		input			reset,
		input			clk,
		`anfFl_FMPA_PORTS,
		`anfFl_MEM_RD_PORTS
	);

	reg [2:0] state;

	reg waitingForTexMeta;
	reg waitingForTexData;
	reg waitingForFMPA;

	wire dataWaiting;
	assign dataWaiting = waitingForTexMeta | waitingForTexData;


	reg [31:0] texMetaAddress;
	reg [63:0] texMetadata;
	
	wire [4:0] format;
	wire [1:0] formatClass;
	wire [3:0] heightExp;
	wire [3:0] widthExp;
	wire [31:0] baseAddr;

	anfFl_tex_memMeta metaIF ();

	assign format = texMetadata[4:0];
	assign formatClass = format[1:0];
	assign baseAddr = texMetadata[63:32];
	assign heightExp = texMetadata[8:5];
	assign widthExp = texMetadata[12:9];

	reg [31:0] samplingY;
	reg [31:0] samplingX;
	reg [15:0] pixelY;
	reg [15:0] pixelX;
	reg [31:0] pixelAddr;

	anfFl_tex_coordDenorm coordDenormY	(	
										.inCoord(samplingY), 
										.lengthExp(heightExp), 
										.outIndex(pixelY)
										);
	anfFl_tex_coordDenorm coordDenormX	(
										.inCoord(samplingX),
										.lengthExp(widthExp),
										.outIndex(pixelX)
										);


	reg [127:0] colorPacket;
	reg [31:0] output_r, output_g, output_b, output_a;
	reg hasMultipleChannels, hasAlpha;

	anfFl_tex_memData dataIF ();

	localparam stage1_c0 = 3'b000;
	localparam stage1_c1 = 3'b001;
	localparam stage1_c2 = 3'b010;


	localparam cmd_setTexture = 3'b000;
	localparam cmd_streamCoords = 3'b001;

	always @(posedge clk) begin
	
	dev_ack <= 0;

	// Stage 1.
	

	
endmodule