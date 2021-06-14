/*
Anf Floof
32-bit Embedded 3D Graphics Processor

ETC2 Texture Block Decoder
*/

`default_nettype none


function [7:0] ext5bTo8b(input [4:0] in);
	ext5bTo8b = {in, in[4:2]}}
endfunction

function [7:0] ext6bTo8b(input [5:0] in);
	ext6bTo8b = {in, in[5:4]};
endfunction

function #(parameter W) [W-1:0] addSat
	(
		input [W-1] addendA;
		input [W-1] addendB;
	);

	reg [W:0] unsaturatedOut;
	unsaturatedOut = addendA + addendB;

	addSat = unsaturatedOut[W] ? {W{1'b1}} : unsaturatedOut[W-1:0];
endfunction

function #(parameter W) [W-1:0] subSat
	(
		input [W-1] minuend;
		input [W-1] subtrahend;
	);
	reg [W:0] unsaturatedOut;
	unsaturatedOut = {minuend, 1'b0} + {subtrahend, 1'b0};

	subSat = unsaturatedOut[0] ? {W{1'b0}} : unsaturatedOut[W:1];
endfunction


function [9:0] mul8Sx2U(
		input [7:0] multiplicand;
		input [1:0] multiplier;
	);
	reg [7:0] multiplicandUnsigned;
	reg [7:0] mulA;
	reg [8:0] mulB;
	reg [9:0] mulResUnsigned;
	
	multiplicandUnsigned = multiplicand[7] ? -multiplicand : multiplicand;
	mulA = multiplier[0] ? multiplicandUnsigned : 8'b0;
	mulB = multiplier[1] ? {multiplicandUnsigned, 1'b0} : 9'b0;
	mulResUnsigned = mulA + mulB;

	mul8Sx2U = multiplicand[7] ? -mulRegUnsigned : mulResUnsigned
	 
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

	assign c0R = diff ? ext5bTo8b(baseR) : {2{redChannel[7:4]}};
	assign c0G = diff ? ext5bTo8b(baseG) : {2{blueChannel[7:4]}};
	assign c0B = diff ? ext5bTo8b(baseB) : {2{greenChannel[7:4]}};

	wire [5:0] shortDiffR;
	wire [5:0] shortDiffG;
	wire [5:0] shortDiffB;

	assign shortDiffR = baseR + diffR;
	assign shortDiffG = baseG + diffG;
	assign shortDiffB = baseB + diffB;

	assign c1R = diff ? ext5bTo8b(shortDiffR[4:0]) : {2{redChannel[3:0]}};
	assign c1G = diff ? ext5bTo8b(shortDiffG[4:0]) : {2{greenChannel[3:0]}};
	assign c1B = diff ? ext5bTo8b(shortDiffB[4:0]) : {2{blueChannel[3:0]}};

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

	wire [7:0] texelColorR;
	wire [7:0] texelColorG;
	wire [7:0] texelColorB;

	assign texelColorR = pixelIndexValue[1] ? subSat(quadColor[quadIndex][23:16], codebookValueShifted) : addSat(blockColorShiftedR + codebookValueUnsigned);
	assign texelColorG = pixelIndexValue[1] ? subSat(quadColor[quadIndex][15:8], codebookValueShifted) : addSat(blockColorShiftedG + codebookValueUnsigned);
	assign texelColorB = pixelIndexValue[1] ? subSat(quadColor[quadIndex][7:0], codebookValueShifted) : addSat(blockColorShiftedB + codebookValueUnsigned);


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

	wire [7:0] tResR;
	wire [7:0] tResG;
	wire [7:0] tResB;

	assign tAddend = tMode[1] ? -tDist : tDist;
	assign tColor = |tMode ?  {tR1, tG1, tB1} : {tR0, tG0, tB0};

	assign tResR = tMode[0] ? addSat(tColor[23:16], tAddend) : tColor[23:16]
	assign tResG = tMode[0] ? addSat(tColor[15:8], tAddend) : tColor[15:8]
	assign tResB = tMode[0] ? addSat(tColor[7:0], tAddend) : tColor[7:0]
	

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

	wire [7:0] hResR;
	wire [7:0] hResG;
	wire [7:0] hResB;

	assign hResR = addSat(hBaseR, hAddend);
	assign hResG = addSat(hBaseG, hAddend);
	assign hResB = addSat(hBaseB, hAddend);


	// ETC2 Planar Mode decoding

	wire [7:0] pR0;
	wire [7:0] pG0;
	wire [7:0] pB0;

	assign pR0 = ext5bTo8b(data[62:57]);
	assign pG0 = ext6bTo8b({data[56], data[54:49]});
	assign pB0 = ext5bTo8b({data[48], data[44:43], data[41:40]});

	wire [7:0] pRh;
	wire [7:0] pGh;
	wire [7:0] pBh;

	assign pRh = ext5bTo8b({data[38:34], data[32]});
	assign pGh = ext6bTo8b(data[31:25]);
	assign pBh = ext5bTo8b(data[24:19]);

	wire [7:0] pRv;
	wire [7:0] pGv;
	wire [7:0] pBv;

	assign pRv = ext5bTo8b(data[18:13]);
	assign pGv = ext6bTo8b(data[12:6]);
	assign pBv = ext5bTo8b(data[5:0]);

	wire [7:0] pR;
	wire [7:0] pG;
	wire [7:0] pB;

	assign pR =  addSat(addSat(mul8Sx2U(pRh - pR0, xTexel) >> 2, mul8Sx2U(pRv - pR0, xTexel) >> 2) + pR0);
	assign pG =  addSat(addSat(mul8Sx2U(pGh - pG0, xTexel) >> 2, mul8Sx2U(pGv - pG0, xTexel) >> 2) + pG0);
	assign pB =  addSat(addSat(mul8Sx2U(pBh - pB0, xTexel) >> 2, mul8Sx2U(pBv - pB0, xTexel) >> 2) + pB0);

	always @(*) begin

		if (diff && |{diffOverflowR, diffOverflowG, diffOverflowB}) begin // ETC2 Modes
			if (diffOverflowR) begin // T-mode

				R = tResR;
				G = tResG;
				B = tResB;

			end else if (diffOverflowG) begin // H-mode

				R = hResR;
				G = hResG;
				B = hResB;

			end else if (diffOverflowB) begin // Planar mode

				R = pR;
				G = pG;
				B = pB;

			end

		end else begin // ETC1 mode
			
			R = texelColorR;
			G = texelColorG;
			B = texelColorB;
		
		end

	end

endmodule