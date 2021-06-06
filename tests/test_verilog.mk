TB_NAME ?= testbench

IVERILOG ?= iverilog
IVERILOG_FLAGS ?= -s $(TB_NAME) -o build/$(TEST_NAME)

VERILATOR ?= verilator
VERILATOR_FLAGS += --lint-only --top-module $(TB_NAME) -Wall
VERILATOR_CMD = $(VERILATOR) $(VERILATOR_FLAGS) $(RTL_DEP)

.PHONY: lint compile test clean notice

notice:
	@echo "Anf Floof Test (Verilog TB): $(TEST_NAME)"

clean: notice
	@rm -rf build

build:
	@mkdir build

lint:
	@$(VERILATOR_CMD)

build/$(TEST_NAME): lint
	@$(IVERILOG) $(RTL_DEP) $(IVERILOG_FLAGS)

compile: clean build build/$(TEST_NAME)

test: compile
	@vvp build/$(TEST_NAME)

.DEFAULT_GOAL := test