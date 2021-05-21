const FloofTest = require("../testframe");

const test = new FloofTest("TextureCoordsDenormalization");
test.addVerilog("tex/coordDenorm.v").addCpp("coordDenorm.cpp").buildAndRun();