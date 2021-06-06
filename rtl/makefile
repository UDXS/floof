default:
	@echo "Available targets:"
	@echo "  - cxxrtl [MODULE=<Verilog file>]"
	@echo "  - lint [MODULE=<Verilog file>]"
	@echo
	@echo "Please select a build target."

builddir:
	@mkdir -p ../build
	@mkdir -p ../build/rtl

clean:
	@rm -rf ../build/rtl 

YOSYS ?= yosys
YOSYS_FLAGS += -q -p 'read_verilog "$(COMPILE.v)"' -p 'write_cxxrtl "$(CXXTRL_OUTPUT)";'
YOSYS_CMD = $(YOSYS) $(YOSYS_FLAGS)

ifeq ($(MODULE),)
COMPILE.v = floof.v
CXXTRL_OUTPUT ?= ../build/rtl/floof.h
else
COMPILE.v = $(MODULE)
CXXTRL_OUTPUT ?= $(addprefix ../build/rtl/, rtl_$(subst .v,.h,$(subst /,_,$(MODULE))))
endif

cxxrtl: builddir lint
	@$(YOSYS_CMD)


VERILATOR ?= verilator
VERILATOR_FLAGS += --lint-only -Wall
VERILATOR_CMD = $(VERILATOR) $(VERILATOR_FLAGS) $(COMPILE.v)

lint:
	@$(VERILATOR_CMD)