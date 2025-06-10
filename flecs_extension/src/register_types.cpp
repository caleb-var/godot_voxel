#include "register_types.h"
#include "flecs_gd.h"
#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

namespace godot{
    void initialize(ModuleInitializationLevel p_level) {
        if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
            return;
        }
        GDREGISTER_RUNTIME_CLASS(FlecsGD);
    }
    void uninitialize(ModuleInitializationLevel p_level) {}
    extern "C" {
    GDExtensionBool GDE_EXPORT flecs_extension_init(GDExtensionInterfaceGetProcAddress p_interface, const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_init) {
        godot::GDExtensionBinding::InitObject init_obj(p_interface, p_library, r_init);

        init_obj.register_initializer(initialize);
        init_obj.register_terminator(uninitialize);
        init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
        return init_obj.init();
    }}
}