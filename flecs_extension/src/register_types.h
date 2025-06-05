#ifndef FLECS_EXTENSION_REGISTER_TYPES_H
#define FLECS_EXTENSION_REGISTER_TYPES_H

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void initialize_flecs_extension(ModuleInitializationLevel p_level);
void uninitialize_flecs_extension(ModuleInitializationLevel p_level);

#endif
