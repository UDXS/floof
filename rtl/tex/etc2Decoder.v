/*
Anf Floof
32-bit Embedded 3D Graphics Processor

ETC2 Texture Block Decoder
*/

`default_nettype none


function [7:0] extend5bTo8b(input [4:0] in);
	reg [9:0] extended;
	extended = {2{in}};

	extend5bTo8b = extended[9:2];
endfunction


module anfFl_tex_etc2Decoder
	(
		input [127:0] data,
		input [4:0] format,

		output reg [7:0] R,
		output reg [7:0] G,
		output reg [7:0] B,
		output reg [7:0] A,

		input [1:0] uTexel,
		input [1:0] vTexel
	);

	wire [7:0] redChannel;
	wire [7:0] blueChannel;
	wire [7:0] greenChannel;

	assign redChannel = data[63:56];
	assign blueChannel = data[55:48];
	assign greenChannel = data[47:40];

	wire [7:0] cwf;
	assign cwf = data[39:32];
	
	wire [2:0] cw0;
	wire [2:0] cw1;
	wire diff;
	wire flip;

	assign cw0 = cwf[7:5];
	assign cw1 = cwf[4:2];
	assign diff = cwf[1];
	assign flip = cwf[0];
	
	wire [31:0] pixelIndicies;
	
	assign pixelIndicies = data[31:0];

	reg [7:0] codebookETC1 [0:15]; // 8 codewords x 4 pixel indicies / 2 (last 16 values = -1 * first 16)
	reg [7:0] codebookETC2 [0:7]; // 8 codewords
	
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

	wire [4:0] baseR;
	wire [4:0] baseG;
	wire [4:0] baseB;

	wire [4:0] diffR;
	wire [4:0] diffG;
	wire [4:0] diffB;

	assign baseR = redChannel[7:3];
	assign baseG = greenChannel[7:3];
	assign baseB = blueChannel[7:3];

	assign diffR = {{2{redChannel[2]}}, redChannel[2:0]};
	assign diffG = {{2{greenChannel[2]}}, greenChannel[2:0]};
	assign diffB = {{2{blueChannel[2]}}, blueChannel[2:0]};

	assign c0R = diff ? extend5bTo8b(baseR) : {2{redChannel[7:4]}};
	assign c0G = diff ? extend5bTo8b(baseG) : {2{blueChannel[7:4]}};
	assign c0B = diff ? extend5bTo8b(baseB) : {2{greenChannel[7:4]}};

	wire [5:0] shortDiffR;
	wire [5:0] shortDiffG;
	wire [5:0] shortDiffB;

	assign shortDiffR = baseR + diffR;
	assign shortDiffG = baseG + diffG;
	assign shortDiffB = baseB + diffB;

	assign c1R = diff ? extend5bTo8b(shortDiffR[4:0]) : {2{redChannel[3:0]}};
	assign c1G = diff ? extend5bTo8b(shortDiffG[4:0]) : {2{greenChannel[3:0]}};
	assign c1B = diff ? extend5bTo8b(shortDiffB[4:0]) : {2{blueChannel[3:0]}};

	// ETC2 modes are engaged by triggering overflow on various channels in differential mode.
	wire diffOverflowR;
	wire diffOverflowG;
	wire diffOverflowB;

	assign diffOverflowR = shortDiffR[5];
	assign diffOverflowG = shortDiffG[5];
	assign diffOverflowB = shortDiffB[5];


	/*
		Codewords for each 2x2 quadrant
	 	0	1
		2	3

		flip = 0: {q0, q2} = cw0; {q1, q3} = cw1;  
		flip = 1: {q0, q1} = cw0; {q2, q3} = cw1;  
	*/

	wire [2:0] quadCodeword [0:3];

	assign quadCodeword[0] = cw0;
	assign quadCodeword[1] = flip ? cw0 : cw1;
	assign quadCodeword[2] = flip ? cw1 : cw0;
	assign quadCodeword[3] = cw1;

	wire [23:0] quadColor [0:3];
	assign quadColor[0] = {c0R, c0G, c0B};
	assign quadColor[1] = flip ? {c0R, c0G, c0B} : {c1R, c1G, c1B};
	assign quadColor[2] = flip ? {c1R, c1G, c1B} : {c0R, c0G, c0B};
	assign quadColor[3] = {c1R, c1G, c1B};

	wire [1:0] quadIndex;
	wire [2:0] codeword;

	assign quadIndex = {vTexel[1], uTexel[1]};

	assign codeword = quadCodeword[quadIndex];

	wire [3:0] texelIndex;
	wire [1:0] pixelIndexValue;

	assign texelIndex = {uTexel, vTexel};
	assign pixelIndexValue = {pixelIndicies[{1'b1, texelIndex}], pixelIndicies[{1'b0, texelIndex}]};

	wire [3:0] codebookValueIndex;
	wire [7:0] codebookValueUnsigned;

	assign codebookValueIndex = {codeword, pixelIndexValue[0]};
	assign codebookValueUnsigned = codebookETC1[codebookValueIndex];

	// Move 8-bit value into middle of 10-bit container to allow underflow/overflow checking.
	wire [9:0] blockColorShiftedR;
	wire [9:0] blockColorShiftedG;
	wire [9:0] blockColorShiftedB;
	wire [9:0] codebookValueShifted;

	wire [9:0] texelColorShiftedR;
	wire [9:0] texelColorShiftedG;
	wire [9:0] texelColorShiftedB;

	assign blockColorShiftedR = {1'b0, quadColor[quadIndex][23:16], 1'b0};
	assign blockColorShiftedG = {1'b0, quadColor[quadIndex][15:8], 1'b0};
	assign blockColorShiftedB = {1'b0, quadColor[quadIndex][7:0], 1'b0};
	assign codebookValueShifted = {1'b0, codebookValueUnsigned, 1'b0};

	assign texelColorShiftedR = pixelIndexValue[1] ? blockColorShiftedR - codebookValueShifted : blockColorShiftedR + codebookValueShifted;
	assign texelColorShiftedG = pixelIndexValue[1] ? blockColorShiftedG - codebookValueShifted : blockColorShiftedG + codebookValueShifted;
	assign texelColorShiftedB = pixelIndexValue[1] ? blockColorShiftedB - codebookValueShifted : blockColorShiftedB + codebookValueShifted;


	// ETC2 T-Mode decoding

	wire [7:0] tR0;
	wire [7:0] tG0;
	wire [7:0] tB0;

	wire [7:0] tR1;
	wire [7:0] tG1;
	wire [7:0] tB1;

	assign tR0 = {2{redChannel[4:3], redChannel[1:0]}};
	assign tG0 = {2{greenChannel[7:4]}};
	assign tB0 = {2{greenChannel[3:0]}};

	assign tR1 = {2{blueChannel[7:4]}};
	assign tG1 = {2{blueChannel[3:0]}};
	assign tB1 = {2{cwf[7:4]}};

	wire [2:0] tDistIndex;
	wire [7:0] tDist;
	wire [1:0] tMode;

	assign tDistIndex = {cwf[3:2],cwf[0]};
	assign tDist = codebookETC2[tDistIndex];
	assign tMode = pixelIndexValue;

	wire [7:0] tAddend;
	wire [23:0] tColor;

	wire [9:0] tResR;
	wire [9:0] tResG;
	wire [9:0] tResB;

	assign tAddend = tMode[1] ? -tDist : tDist;
	assign tColor = |tMode ?  {tR1, tG1, tB1} : {tR0, tG0, tB0};

	assign tResR = tMode[0] ? {1'b0, tColor[23:16], 1'b0} + {1'b0, tAddend, 1'b0} : {1'b0, tColor[23:16], 1'b0};
	assign tResG = tMode[0] ? {1'b0, tColor[15:8], 1'b0} + {1'b0, tAddend, 1'b0} : {1'b0, tColor[15:8], 1'b0};
	assign tResB = tMode[0] ? {1'b0, tColor[7:0], 1'b0} + {1'b0, tAddend, 1'b0} : {1'b0, tColor[7:0], 1'b0};
	

	// ETC2 H-Mode decoding

	wire [3:0] hR0;
	wire [3:0] hG0;
	wire [3:0] hB0;

	wire [3:0] hR1;
	wire [3:0] hG1;
	wire [3:0] hB1;

	assign hR0 = data[62:59];
	assign hG0 = {data[58:56], data[52]};
	assign hB0 = {data[51], data[49:47]};

	assign hR1 = data[47:44];
	assign hG1 = data[42:39];
	assign hB1 = data[38:35];

	wire [11:0] hVal0;
	wire [11:0] hVal1;

	assign hVal0 = {hR0, hG0, hB0};
	assign hVal1 = {hR1, hG1, hB1};

	wire [1:0] hMode;
	wire [2:0] hDistIndex;
	wire [7:0] hDist;

	assign hMode = pixelIndexValue;
	assign hDistIndex = {data[34], data[32], hVal0 >= hVal1};
	assign hDist = codebookETC2[hDistIndex];

	wire [7:0] hBaseR;
	wire [7:0] hBaseG;
	wire [7:0] hBaseB;
	wire [7:0] hAddend;

	assign hBaseR = hMode[1] ? {2{hR1}} : {2{hR0}};
	assign hBaseG = hMode[1] ? {2{hG1}} : {2{hG0}};
	assign hBaseB = hMode[1] ? {2{hB1}} : {2{hB0}};

	assign hAddend = hMode[0] ? -hDist : hDist;

	wire [9:0] hResR;
	wire [9:0] hResG;
	wire [9:0] hResB;

	assign hResR = {1'b0, hBaseR, 1'b0} + {1'b0, hAddend, 1'b0};
	assign hResG = {1'b0, hBaseG, 1'b0} + {1'b0, hAddend, 1'b0};
	assign hResB = {1'b0, hBaseB, 1'b0} + {1'b0, hAddend, 1'b0};



	always @(*) begin

		if (diff && |{diffOverflowR, diffOverflowG, diffOverflowB}) begin // ETC2 Modes
			if (diffOverflowR) begin // T-mode

				R = tResR[8:1];
				G = tResG[8:1];
				B = tResB[8:1];

				//Clamps
				if (tResR[0]) 
					R = 8'h00;
				else if (tResR[9]) 
					R = 8'hFF;

				if (tResG[0])
					G = 8'h00;
				else if(tResG[9])
					G = 8'hFF;

				if (tResB[0])
					B = 8'h00;
				else if (tResB[9])
					B = 8'hFF;

			end else if (diffOverflowG) begin // H-mode

				R = hResR[8:1];
				G = hResG[8:1];
				B = hResB[8:1];

				//Clamps
				if (hResR[0]) 
					R = 8'h00;
				else if (hResR[9]) 
					R = 8'hFF;

				if (hResG[0])
					G = 8'h00;
				else if(hResG[9])
					G = 8'hFF;

				if (hResB[0])
					B = 8'h00;
				else if (hResB[9])
					B = 8'hFF;

			end else if (diffOverflowB) begin // Planar mode
			
			end

		end else begin // ETC1 mode
			
			R = texelColorShiftedR[8:1];
			G = texelColorShiftedR[8:1];
			B = texelColorShiftedR[8:1];

			//Clamps
			if (texelColorShiftedR[0]) 
				R = 8'h00;
			else if (texelColorShiftedR[9]) 
				R = 8'hFF;
			
			if (texelColorShiftedG[0])
				G = 8'h00;
			else if(texelColorShiftedG[9])
				G = 8'hFF;
			
			if (texelColorShiftedB[0])
				B = 8'h00;
			else if (texelColorShiftedB[9])
				B = 8'hFF;
		
		end

	end

endmodule