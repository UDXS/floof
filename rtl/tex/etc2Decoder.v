/*
Anf Floof
32-bit Embedded 3D Graphics Processor

ETC2 Texture Block Decoder
*/

module anfFl_tex_etc2Decoder
	(
		input [127:0] data,
		input [4:0] format,

		output reg [7:0] R,
		output reg [7:0] G,
		output reg [7:0] B,
		output reg [7:0] A,

		input reg [1:0] xTexel,
		input reg [1:0] yTexel
	);

	wire [7:0] redChannel;
	wire [7:0] blueChannel;
	wire [7:0] greenChannel;

	assign redChannel = data[7:0];
	assign blueChannel = data[15:8];
	assign greenChannel = data[23:16];

	wire [7:0] cwf;
	assign cwf = data[31:24];
	
	wire [2:0] cw0;
	wire [2:0] cw1;
	wire diff;
	wire flip;

	assign cw0 = cwf[2:0];
	assign cw1 = cwf[5:3];
	assign diff = cwf[6];
	assign flip = cwf[7];
	
	wire [31:0] pixelIndicies;
	
	assign pixelIndicies = data[63:32];

	reg [7:0] codebookETC1 [0:15]; // 8 codewords x 4 pixel indicies / 2 (last 16 values = -1 * first 16)
	reg [7:0] codebookETC2 [0:15]; // 8 codewords x 4 pixel indicies / 2 (last 16 values = -1 * first 16)
	
	initial begin
		$readmemh("codebookETC1.dat", codebookETC1);
		$readmemh("codebookETC2.dat", codebookETC2);
	end


	wire [7:0] c0R;
	wire [7:0] c0B;
	wire [7:0] c0G;

	wire [7:0] c1R;
	wire [7:0] c1B;
	wire [7:0] c1G;

	wire [7:0] baseR;
	wire [7:0] baseG;
	wire [7:0] baseB;

	wire [7:0] diffR;
	wire [7:0] diffG;
	wire [7:0] diffB;

	assign baseR = {2{redChannel[4:0]}}[9:2];
	assign baseG = {2{greenChannel[4:0]}}[9:2];
	assign baseB = {2{blueChannel[4:0]}}[9:2];

	assign diffR = {5{redChannel[2]}, redChannel[2:0]};
	assign diffG = {5{greenChannel[2]}, greenChannel[2:0]};
	assign diffB = {5{blueChannel[2]}, blueChannel[2:0]};

	assign c0R = diff ? baseR : {2{redChannel[3:0]}};
	assign c0G = diff ? baseG : {2{blueChannel[3:0]}};
	assign c0B = diff ? baseB : {2{greenChannel[3:0]}};

	assign c1R = diff ? (baseR + diffR) : {2{redChannel[7:4]}};
	assign c1G = diff ? (baseG + diffG) : {2{blueChannel[7:4]}};
	assign c1B = diff ? (baseB + diffB) : {2{greenChannel[7:4]}};

	// ETC2 modes are engaged by triggering overflow on various channels in differential mode.


	/*
		Codewords for each 2x2 quadrant
	 	0	1
		2	3

		flip = 0: q0, q2 = cw0; q1, q3 = cw1;  
		flip = 1: q0, q1 = cw0; q2, q3 = cw1;  
	*/

	wire [2:0] quadCodeword [0:3];

	assign quadCodeword[0] = cw0;
	assign quadCodeword[1] = flip ? cw0 : cw1;
	assign quadCodeword[2] = flip ? cw1 : cw0;
	assign q3cw[3] = cw1;

	wire [23:0] quadColor [0:3];
	assign quadColor[0] = {c0R, c0G, c0B};
	assign quadColor[1] = flip ? {c0R, c0G, c0B} : {c1R, c1G, c1B};
	assign quadColor[2] = flip ? {c1R, c1G, c1B} : {c0R, c0G, c0B};
	assign quadColor[3] = {c1R, c1G, c1B};

	wire [3:0] texelOffset;
	wire [4:0] texelIndex;
	wire [2:0] codeword;

	wire codebookRowIndex;
	wire codebookRowSign;

	wire [3:0] codebookValueIndex;
	wire [7:0] codebookValueUnsigned;

	assign texelOffset = {yTexel, texelX};
	assign texelIndex = {texelOffset, 1'b0};

	assign codeword = quadCodeword[{y[1], x[1]}];

	assign codebookRowIndex = pixelIndicies[texelIndex | 5'b1];
	assign codebookRowSign = pixelIndicies[texelIndex];

	assign codebookValueIndex = {codeword, codebookRowIndex};
	assign codebookValueUnsigned = codebookETC1[codebookValueIndex];


	// Move 8-bit value into middle of 10-bit container to allow underflow/overflow checking.
	wire [9:0] blockColorShifted;
	wire [9:0] codebookValueShifted;

	wire [9:0] texelColorShiftedR;
	wire [9:0] texelColorShiftedG;
	wire [9:0] texelColorShiftedB;

	assign blockColorShiftedR = {1'b0, quadColor[{y[1], x[1]}][23:15], 1'b0};
	assign blockColorShiftedG = {1'b0, quadColor[{y[1], x[1]}][15:8], 1'b0};
	assign blockColorShiftedB = {1'b0, quadColor[{y[1], x[1]}][7:0], 1'b0};
	assign codebookValueShifted = {1'b0, codebookValueUnsigned, 1'b0};

	assign texelColorShiftedR = codebookRowSign ? blockColorShiftedR - codebookValueShifted : blockColorShiftedR + codebookValueShifted;
	assign texelColorShiftedG = codebookRowSign ? blockColorShiftedG - codebookValueShifted : blockColorShiftedG + codebookValueShifted;
	assign texelColorShiftedB = codebookRowSign ? blockColorShiftedB - codebookValueShifted : blockColorShiftedB + codebookValueShifted;

	always @(*) begin

		R = texelColorShiftedR[8:1];
		G = texelColorShiftedR[8:1];
		B = texelColorShiftedR[8:1];

		//Clamps
		if(texelColorShiftedR[0])
			R = 8'h00;
		else if(texelColorShiftedR[9])
			R = 8'hFF

		if(texelColorShiftedG[0])
			G = 8'h00;
		else if(texelColorShiftedG[9])
			G = 8'hFF

		if(texelColorShiftedB[0])
			B = 8'h00;
		else if(texelColorShiftedB[9])
			B = 8'hFF
		
	end

endmodule