#include <iostream>
#include <fstream>
#include <stdint.h>
#include <backends/cxxrtl/cxxrtl_vcd.h>
#include "rtl.h"
#include <stdio.h>
#include <math.h>

cxxrtl_design::p_anfFl__tex__coordDenorm device;
cxxrtl::vcd_writer vcd;
int step = 0;

constexpr int Q = 16;
constexpr int Qnorm = 1 << Q;

uint32_t floatToFixed(double n)
{
	return (uint32_t)round(n * Qnorm);
}

void testDenorm(float inCoord, uint32_t lengthExp, uint16_t expected)
{
	printf("step %3d  inCoord = %9f = 0x%.8x;  lengthExp = %2u;  length = %5u;  expected = %5u; ", step + 1, inCoord, floatToFixed(inCoord), lengthExp, 1 << lengthExp, expected);
	vcd.sample(step++);

	device.p_inCoord.set<uint32_t>(floatToFixed(inCoord));
	device.p_lengthExp.set<uint32_t>(lengthExp);
	device.step();

	vcd.sample(step++);
	if (device.p_outIndex.get<uint16_t>() != expected)
		printf("FAIL\n\tMismatch at Step %d: outIndex = %u != expected = %u\n", step - 1, device.p_outIndex.get<uint16_t>(), expected);
	else
		printf("PASS\n");
}

int main()
{
	cxxrtl::debug_items all_items;
	device.debug_info(all_items);

	vcd.timescale(10, "us");

	vcd.add_without_memories(all_items);

	testDenorm(0.5, 5, 16); // 2^5 = 32
	testDenorm(-0.5, 5, 16); 
	
	testDenorm(0.5, 6, 32); // 2^6 = 64
	testDenorm(-0.5, 6, 32);
	testDenorm(0.25, 6, 16);
	testDenorm(-0.25, 6, 48);

	testDenorm(0.0, 8, 0); //2^8 = 256
	testDenorm(1.0, 8, 0); // This is equivalent to sampling 0.0

	testDenorm(0.0, 0, 0); //2^0 = 1;
	testDenorm(0.5, 0, 0); 
	testDenorm(0.5, 1, 1); //2^1 = 2;

	testDenorm(0.75, 7, 96); // 2^7 = 128
	testDenorm(-0.75, 7, 32);

	testDenorm(4.25, 9, 128); // 2^9 = 512
	testDenorm(-7.625, 9, 192); // 2^9 = 512


	std::ofstream waves("build/waves.vcd");
	waves << vcd.buffer;
	vcd.buffer.clear();
}