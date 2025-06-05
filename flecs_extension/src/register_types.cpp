#include "register_types.h"
#include "flecs_gd.h"
#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/engine.hpp>

using namespace godot;

void initialize_flecs_extension(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
    ClassDB::register_class<FlecsGD>();
    Engine::get_singleton()->register_singleton("FlecsGD",FlecsGD::get_singleton());    
}

void uninitialize_flecs_extension(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
    Engine::get_singleton()->unregister_singleton("FlecsGD");
}

extern "C" {
GDExtensionBool GDE_EXPORT flecs_extension_init(GDExtensionInterfaceGetProcAddress p_interface, const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_init) {
    godot::GDExtensionBinding::InitObject init_obj(p_interface, p_library, r_init);

    init_obj.register_initializer(initialize_flecs_extension);
    init_obj.register_terminator(uninitialize_flecs_extension);
    init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

    return init_obj.init();
}
}
