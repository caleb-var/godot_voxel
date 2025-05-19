#include "register_types.h"
#include "bvh_tlas.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

void initialize_tinybvh_extension() {
    ClassDB::register_class<BVHTLAS>();
}

void uninitialize_tinybvh_extension() {
    // Nothing yet
}

extern "C" {
GDExtensionBool GDE_EXPORT tinybvh_extension_init(const GDExtensionInterface *p_interface, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_init) {
    GDExtensionBinding::InitObject init_obj(p_interface, p_library, r_init);

    init_obj.register_initializer(initialize_tinybvh_extension);
    init_obj.register_terminator(uninitialize_tinybvh_extension);
    init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

    return init_obj.init();
}
}
