#include <iostream>
#include <fstream>
#include <stdint.h>
#include <backends/cxxrtl/cxxrtl_vcd.h>
#include "rtl.h"
#include <stdio.h>
#include <math.h>

enum format
{
	fmt_RGB_24 = 0b00000,
	fmt_RGBA_32 = 0b00100,
	fmt_RGB_16 = 0b00001,
	fmt_RGBA_16 = 0b00101,
	fmt_RGB_15 = 0b01001,
	fmt_RGBA_15_PUNCHTHROUGH = 0b01101,
	fmt_RGB_ETC2 = 0b00010,
	fmt_RGBA_ETC2 = 0b00110,
	fmt_RGBA_ETC2_PUNCHTHROUGH = 0b01010,
	fmt_R_EAC_UNSIGNED = 0b10010,
	fmt_R_EAC_SIGNED = 0b10110,
	fmt_RGB_24_TILED = 0b00011,
	fmt_RGBA_32_TILED = 0b00111,
	fmt_RGB_16_TILED = 0b10011,
	fmt_RGBA_16_TILED = 0b10111
};

struct TexMeta
{
	format fmt : 5;
	uint32_t heightExp : 4;
	uint32_t widthExp : 4;
	uint32_t reserved : 19;
	uint32_t address;
} __attribute__((packed));

union TexMetaConverter
{
	TexMeta meta;
	uint64_t integer;
};

cxxrtl_design::p_anfFl__tex__addrCalc device;
cxxrtl::vcd_writer vcd;
int step = 0;

void testAddrGen(uint32_t xPixel, uint32_t yPixel, TexMeta texMeta, uint32_t expected)
{
	TexMetaConverter conv;
	conv.meta = texMeta;
	uint64_t meta = conv.integer;
	printf("step %3d  xPixel = %5u;  yPixel = %5u;  texMeta = 0x%.16lX;  expected = 0x%.8X; ", step + 1, xPixel, yPixel, meta, expected);
	vcd.sample(step++);

	device.p_xPixel.set<uint16_t>(xPixel);
	device.p_yPixel.set<uint16_t>(yPixel);
	device.p_texMeta.set<uint64_t>(meta);
	device.p_yPixel.set<uint16_t>(yPixel);
	device.step();

	vcd.sample(step++);
	if (device.p_address.get<uint32_t>() != expected)
		printf("FAIL\n\tMismatch at Step %d: address = 0x%.8X != expected = 0x%.8X\n", step - 1, device.p_address.get<uint32_t>(), expected);
	else
		printf("PASS\n");
}

int main()
{
	cxxrtl::debug_items all_items;
	device.debug_info(all_items);

	vcd.timescale(10, "us");

	vcd.add_without_memories(all_items);

	puts("RGB24 8 x 8");
	TexMeta meta8x8_rgb24 {.fmt = format::fmt_RGB_24, .heightExp = 3, .widthExp = 3, .address = 0x00000000};
	testAddrGen(0, 0, meta8x8_rgb24, 0x00000000);
	testAddrGen(4, 0, meta8x8_rgb24, 0x0000000C);
	testAddrGen(7, 0, meta8x8_rgb24, 0x00000015);
	testAddrGen(0, 1, meta8x8_rgb24, 0x00000018);
	testAddrGen(0, 4, meta8x8_rgb24, 0x00000060);

	puts("\nRGBA32 8 x 8");
	TexMeta meta16x16_rgba32 {.fmt = format::fmt_RGBA_32, .heightExp = 4, .widthExp = 4, .address = 0x00000000};
	testAddrGen(0, 0, meta16x16_rgba32, 0x00000000);
	testAddrGen(4, 0, meta16x16_rgba32, 0x0000000C);
	testAddrGen(7, 0, meta16x16_rgba32, 0x00000015);
	testAddrGen(0, 1, meta16x16_rgba32, 0x00000018);
	testAddrGen(0, 4, meta16x16_rgba32, 0x00000060);

	std::ofstream waves("build/waves.vcd");
	waves << vcd.buffer;
	vcd.buffer.clear();
}