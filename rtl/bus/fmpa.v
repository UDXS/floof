/*
Anf Floof
32-bit Fixed-Point Embedded 3D Graphics Processor

FMPA - Floof MultiProcessor Bus
*/

`default_nettype none

`define anfFl_FMPA_PORTS	output			FMPA_ready,	\
							input			FMPA_valid, \
							output [7:0]	FMPA_tag,	\
							output [63:0]	FMPA_out,	\
							input [63:0]	FMPA_in,	\


`define anfFl_FMPA_ARGS	.FMPA_ready(FMPA_ready),		\
						.FMPA_valid(FMPA_valid),		\
						.FMPA_tag(FMPA_tag),			\
						.FMPA_out(FMPA_out),			\
						.FMPA_in(FMPA_in)