const FloofTest = require("../testframe");

const test = new FloofTest("TextureColorNormalization");
test.addVerilog("tex/colorNorm.v").addCpp("colorNorm.cpp").buildAndRun();