/*
Anf Floof
32-bit Embedded 3D Graphics Processor

Memory Bus
*/

`default_nettype none

`define anfFl_MEM_RD_PORTS   output [31:0]	rd_addr,	\
							input [63:0]	rd_data,	\
							output			rd_ready,	\
							input			rd_valid

`define anfFl_MEM_RD_ARGS	.rd_addr(rd_addr),		\
							.rd_data(rd_data),		\
							.rd_ready(rd_ready),	\
							.rd_valid(rd_valid)

`define anfFl_MEM_WR_PORTS   output [31:0]	wr_addr,	\
							output [31:0]	wr_data,	\
							output			wr_ready,	\
							input			wr_valid

`define anfFl_MEM_WR_ARGS	.wr_addr(wr_addr),		\
							.wr_data(wr_data),		\
							.wr_ready(wr_ready),	\
							.wr_valid(wr_valid)		\
	