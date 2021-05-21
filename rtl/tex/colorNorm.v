module anfFl_tex_addrCalc
	(
		input[7:0] color,
        output [31:0] normalized
	);

    assign normalized = {16'b0, color, 8'b0};
endmodule