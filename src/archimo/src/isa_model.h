#pragma once

#include <cstdint>
#include <exception>
#include <vector>
#include <array>
#include <optional>
#include <memory>
#include <string>
#include <functional>
#include "instruction.h"
#include "number.h"

namespace am_wasabi {
namespace model_isa {

	using gpr = uint8_t;
	using exec_mask = uint32_t;
	using T_flagset = uint32_t;


	constexpr gpr gpr_g(uint8_t index) {
		return 1 << 7 + index;
	}

	constexpr gpr gpr_s(uint8_t index) {
		return index;
	}

	// Refer to the MVI instruction in isa.md
	enum class imm_type {
		int_unisgned,
		int_signed,
		q6_6,
		q12_0,
		q2_10
	};

	struct immediate {
		uint32_t raw;
		uint32_t value;
		imm_type type;
	};

	enum class access_type {
		read,
		write
	};

	enum class op_status {
		success = 0,
		success_warning = 1,
		fail_exception = 2,
		fail_warning = 3
	};

	enum class special_reg {
		ExecMask,
		T_flag,
		IP
	};

	struct data_origin {
		enum class origin_type {
			gpr_direct,
			gpr_indirect_address,
			imm_direct,
			imm_addressing,
			special_direct
		};

		struct reg_resolution {
			gpr reg;
			uint32_t value;
		};

		struct rel_pair {
			uint32_t base;
			int32_t relative;
			uint32_t compute();
		};

		union origin_index {
			reg_resolution reg;
			rel_pair rel;
			special_reg special;
			uint32_t addr;
		};

		origin_type type;
		origin_index index;
	};

	struct access_record {
		access_type type;
		data_origin origin;
		std::optional<number> value;
		bool successful;
	};

	enum class sim_warning_type {
		undefined_register_access,
		undefined_memory_access,
		prohibited_register_access,
		improperly_zeroed_instruction,
		undecodable_instruction,
		unimplemented_instruction,
		notable_exception_triggered
	};

	struct sim_warning_annotation {
		sim_warning_type type;
		bool fatal;
		std::string message;
	};

	enum class exception_type {
		access_permission_violation,
		access_unmapped_violation,
		access_alignment_violation,
		divide_by_zero
	};

	struct exception_annotation {
		exception_type type;
		bool fatal;
	};

	struct access_exception_annotation : exception_annotation {
		access_record offender;
		bool unmapped_memory;
	};

	struct retirement_record {
		instruction_inst instr;
		std::vector<access_record> accesses;
		exec_mask mask;	
		T_flagset T;
		op_status status;
		std::optional<exception_annotation> exception;
		std::optional<std::vector<sim_warning_annotation>> warnings;
		std::optional<instruction_stream_event&> fetch_event;
	};

	struct slice_state {
		std::array<uint32_t, 64> regs;
		bool T;
		bool exec;
		uint64_t exec_ctr;
	}; 
 
	struct core_context {
		int slice_count;
		std::array<uint32_t, 64> globals;
		std::vector<slice_state> slices;
		std::vector<retirement_record> retirements;
		instruction_stream stream;
		memory_model mem;
		uint64_t exec_ctr;
	};

	template <class data_type = uint32_t, class origin_type = uint32_t>
	struct memory_result {
		std::optional<data_type> data;
		origin_type* origin;

		std::optional<exception_type> exception;
		std::optional<std::string> exception_string;
	};

	struct memory_model {
		virtual memory_result<> read32(uint32_t address) = 0;
		virtual memory_result<std::array<uint32_t, 4>> read128(uint32_t address) = 0;

		virtual std::optional<std::string> about(uint32_t address) = 0;
	};


	struct layered_memory_model : memory_model {
		std::vector<memory_model> mappings;

		virtual memory_result<> read32(uint32_t address);
		virtual memory_result<std::array<uint32_t, 4>> read128(uint32_t address);
	}

}
}