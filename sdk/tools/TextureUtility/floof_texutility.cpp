/*
Anf Floof SDK

TextureUtility
Texture Conversion Utility
*/

#define STB_IMAGE_IMPLEMENTATION
#include "lib/stb_image.h"

int main(){
	int x, y, z;
	stbi_uc* img =  stbi_load("test.png", &x, &y, &z, 3);
	
}