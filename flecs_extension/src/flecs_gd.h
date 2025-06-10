#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/string.hpp>
#include <tiny_bvh.h>

#include "flecs.h"


namespace godot {

class FlecsGD : public RefCounted {
    GDCLASS(FlecsGD, RefCounted);

protected:
    flecs::world world;
    tinybvh::BVH TLAS;
    int instance_index;
    static void _bind_methods();
public:
    FlecsGD();
    ~FlecsGD();

    static void get_aabb_callback(unsigned idx,tinybvh::bvhvec3& out_min,tinybvh::bvhvec3& out_max,void* user);
    
    flecs::world *get_world();
    void set_threads(int32_t thread_count);
    void progress(double delta);

    bool load_module(const String &path, const String &file);
    bool load_script(const String &path, const String &file);

    PackedByteArray FlecsGD::to_gpu_bvh();

    String to_json();
};
}