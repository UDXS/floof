#pragma once 

#include "isa_model.h"

namespace am_wasabi {
namespace model_isa {


	enum class encoding {
		A0,
		A1,
		A2,
		A3,
		B,
		None
	};
	
	enum class op_grouping : uint32_t {
		reg_mem,
		ctrl_flow,
		logic,
		math,
		raster
	};


	enum class instruction_annotation_type {
		SourceAnnotation,
		AssemblerAnnotation
	};


	struct sourcelike_annotation {
		std::optional<std::string> file;  
		std::optional<uint32_t> line_n;
		std::optional<uint32_t> column_n;
		std::optional<std::string> line_str;
	};

	struct instruction_def {
		std::string op_name;

		op_grouping op_group; 
		uint32_t op_code;
		encoding enc;

		std::function<retirement_record(core_context, uint32_t)> execute;
		std::function<std::string(uint32_t)> as_asm;
	};

	struct instruction_inst {
		uint32_t bitfield;
		uint32_t address;
		std::optional<sourcelike_annotation> origin_asm;
		std::optional<sourcelike_annotation> origin_hll;
		instruction_def* definition;
	};

	struct instruction_fetch {
		std::optional<instruction_inst> instruction;
		access_record access;
		std::optional<access_exception_annotation> exception;
	};

	enum class instruction_stream_event_type {
		fetch,
		branch_point,
		exception_point
	};

	struct instruction_stream_event {
		instruction_stream_event_type type;
		uint32_t dest;
	};

	struct instruction_stream_logger {
		std::vector<instruction_stream_event> events;
		bool log_fetches;

		void log(instruction_stream_event event);
	};

	struct instruction_stream {
		uint32_t ip;
		memory_model& model;
		std::optional<instruction_stream_logger&> logger;

		instruction_fetch fetch_next();
		instruction_fetch prefetch_next();

		void schedule_branch(uint32_t dest_ip, bool exception);
		instruction_fetch prefetch_branch(uint32_t dest_ip);
	};

	}
}