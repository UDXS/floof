/*
Anf Floof SDK

TextureUtility
Texture Conversion Utility
*/

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