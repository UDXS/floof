module anfFl_tex_colorNorm
	(
		input[7:0] channel,
        output [31:0] normalized
	);

    assign normalized = {16'b0, 2{channel}};
endmodule