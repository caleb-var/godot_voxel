Current progress:

Porting TinyBVH plus modifying to work with Godot, callbacks and instances. Need to change TinyBVH library to support custom BLAS representation (uint32 index + count) for current ray tracing pipeline.

Porting Flecs + creating C++ singleton in the GDExtension C++ wrapper to track and maintain a packagebytearray for Godot compute shader with info header (tlas nodes -> instances -> objects (internal BVH) -> Parts -> blas data) and animation clip data for objects + blas


Todo: After creating bvh & flecs GDExtenstion that ports into current compute shader handler port in:

cpp multi-thread job system for large scale simulation,

gd script modloader for cpp flecs modules & gdscript lightweight systems

port current UI and debugging implementations
