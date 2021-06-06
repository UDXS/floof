RTL_OUT ?= rtl.h
FLOOF_RTL_DIR ?= ../../rtl

YOSYS ?= yosys
YOSYS_INCDIR ?= `yosys-config --datdir`/include
YOSYS_SCRIPT ?= read_verilog $(FLOOF_RTL_DIR)/$(RTL_DEP); write_cxxrtl build/$(RTL_OUT);

CXX_WARNING_FLAGS += -Wno-array-bounds -Wno-shift-count-overflow
CXX_PRE_FLAGS += -g -O0 -std=c++17 $(CXX_WARNING_FLAGS) -I $(YOSYS_INCDIR)
CXX_FLAGS +=  -o build/$(TEST_NAME)

CXX = g++


.PHONY: compile test clean notice

notice:
	@echo "Anf Floof Test (C++ TB): $(TEST_NAME)"

clean: notice
	@rm -rf build

build:
	@mkdir build

build/$(RTL_OUT): $(FLOOF_RTL_DIR)/$(RTL_DEP)
	$(YOSYS) -p '$(YOSYS_SCRIPT)'

build/$(TEST_NAME):  build/$(RTL_OUT)
	$(CXX) $(CXX_PRE_FLAGS) $(CXX_DEPS) $(CXX_FLAGS)

compile: clean build build/$(TEST_NAME)

test: compile
	@build/$(TEST_NAME)

.DEFAULT_GOAL := test