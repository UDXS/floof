/*
Anf Floof
32-bit Embedded 3D Graphics Processor

Texture Color Parser
*/

module anfFl_tex_colorDecoder
	(
		input [127:0] data,
		input [4:0] format,
		
		output reg [7:0] R,
		output reg [7:0] G,
		output reg [7:0] B,
		output reg [7:0] A,
		
		input reg [1:0] texelX,
		input reg [1:0] texelY
	);

	localparam fmt_RGB_24 = 5'b000_00;
	localparam fmt_RGBA_32 = 5'b001_00;

	localparam fmt_RGB_16 = 5'b000_01;
	localparam fmt_RGBA_16 = 5'b001_01;
	localparam fmt_RGB_15 = 5'b010_01;
	localparam fmt_RGBA_15_PUNCHTHROUGH = 5'b011_01;

	localparam fmt_RGB_ETC2 = 5'b000_10;
	localparam fmt_RGBA_ETC2 = 5'b001_10;
	localparam fmt_R_EAC_UNSIGNED = 5'b100_10;
	localparam fmt_R_EAC_SIGNED = 5'b101_10;
	
	localparam fmt_RGB_24_TILED = 5'b000_11;
	localparam fmt_RGBA_32_TILED = 5'b001_11;
	localparam fmt_RGB_16_TILED = 5'b010_11;
	localparam fmt_RGBA_16_TILED = 5'b011_11;
	localparam fmt_R_8_TILED = 5'b100_11;
	localparam fmt_R_16_TILED = 5'b101_11;


	localparam fc_8BPC = 2'b00;
	localparam fc_16BITS = 2'b01;
	localparam fc_COMPRESSED = 2'b10;
	localparam fc_TILED = 2'b11;

	wire [4:0] format;
	wire [1:0] formatClass;

	assign format = texMeta[4:0];
	assign formatClass = format[1:0];

	always @(*) begin
		case (formatClass)
			fc_8BPC: begin
				R = data[7:0];
				G = data[15:8];
				B = data[23:16];
				if (format == fmt_RGBA_32)
					A = data[31:24];
				else
					A = 8'hFF;
			end

			fc_16BITS: begin
				case (format)
					fmt_RGB_16: begin
						R = {data[4:0], data[4:2]};
						G = {data[10:5], data[10:9]};
						B = {data[15:11], data[15:13]};
						A = 8'hFF;
					end

					fmt_RGBA_16: begin
						R = {2{data[3:0]}};
						G = {2{data[7:4]}};
						B = {2{data[11:8]}};
						A = {2{data[15:12]}};
					end

					fmt_RGB_15:
					fmt_RGBA_15_PUNCHTHROUGH: begin
						R = {data[4:0], data[4:2]]};
						G = {data[9:5], data[9:7]};
						B = {data[14:10], data[14:13]};
						if(format == fmt_RGBA_15_PUNCHTHROUGH)
							A = {8{data[15]}};
						else 
							A = 8'hFF;
					end

				endcase
			end

			fc_COMPRESSED: begin
				
			end

			fc_TILED: begin
				case(format)
					fmt_RGB_24_TILED:
					fmt_RGBA_32_TILED: begin
						R = data[7:0];
						G = data[15:8];
						B = data[23:16];
						if (format == fmt_RGBA_32_TILED)
							A = data[31:24];
						else
							A = 8'hFF;
					end

					fmt_RGB_16_TILED: begin
						R = {data[4:0], data[4:2]};
						G = {data[10:5], data[10:9]};
						B = {data[15:11], data[15:13]};
						A = 8'hFF;
					end

					fmt_RGBA_16_TILED: begin
						R = {2{data[3:0]}};
						G = {2{data[7:4]}};
						B = {2{data[11:8]}};
						A = {2{data[15:12]}};
					end
					
				endcase
			end

		endcase
		
	end

endmodule