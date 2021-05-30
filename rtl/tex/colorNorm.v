/*
Anf Floof
32-bit Embedded 3D Graphics Processor

Texture Color Fixed-Point Normalizer
*/

`default nettype none

module anfFl_tex_colorNorm
	(
		input[7:0] channel,
        output [31:0] normalized
	);

    assign normalized = {16'b0, 2{channel}};
endmodule