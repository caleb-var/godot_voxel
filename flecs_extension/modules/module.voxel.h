#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <flecs.h>

namespace module_voxel
{
    struct Position{float x, y, z;};
    struct Tranform{godot::Transform3D transform;};
    struct Velocity{float x, y, z;};
    struct Color{float r, g, b;};
    struct Instance{int id;};
    struct VoxelModule{VoxelModule(flecs::world &world);};
}