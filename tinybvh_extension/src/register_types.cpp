#include <godot_cpp/godot.hpp>
#include "bvh_tlas.h"

using namespace godot;

extern "C" {

// Initialization.
GDExtensionBool GDE_EXPORT my_bvh_extension_init(const GDExtensionInterface *p_interface, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
    godot::GDExtensionBinding::InitObject init_obj(p_interface, p_library, r_initialization);
    init_obj.register_initializer([]() {
        ClassDB::register_class<BvhTlas>();
    });
    init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
    return init_obj.init();
}
}
