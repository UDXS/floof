#include "instruction.h"

namespace am_wasabi {
namespace model_isa {

std::string sourcelike_annotation::as_string() {
    std::string resulting;
    if(file.has_value())
        resulting = *file + " ";
        
    if(line_n.has_value())
        resulting += "@ L" + *line_n;

    if(column_n.has_value())
        resulting += ":" + *column_n;

    return resulting;
}

instruction_annotation_type sourcelike_annotation::type() {
    return original_type;
}





}
}