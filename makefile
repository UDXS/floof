
.build_header:
	@echo "Anf Floof Build Script"
	@echo "Copyright (c) 2021 Davit Markarian"
	@echo

default: .build_header
	@echo "Available targets:"
	@echo "  - rtl_tests [TEST=<subfolder of ./tests>]"
	@echo "  - rtl_cxxrtl [COMPONENT=<subfolder of ./rtl>]"
	@echo "  - cdk_ise [COMPONENT=<subfolder of ./cdk/ise>]"
	@echo "  - sdk_tools [TOOL=<subfolder of ./sdk/tools>]"
	@echo
	@echo "Please select a build target."


rtl_cxxrtl: 


rtl_tests: 
	@make 

build:
	mkdir build
	mkdir build/deps	