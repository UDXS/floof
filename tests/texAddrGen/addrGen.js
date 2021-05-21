const FloofTest = require("../testframe");

const test = new FloofTest("TextureAddressGeneration");
test.addVerilog("tex/addrGen.v").addCpp("addrGen.cpp").buildAndRun();