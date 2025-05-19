#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <vector>

// Ensure tinybvh functions are safely inlined if included in multiple places
#ifndef TINYBVH_H
#define TINYBVH_H
#include "tiny_bvh.h"
#endif

namespace godot {

class BVHTLAS : public RefCounted {
    GDCLASS(BVHTLAS, RefCounted)

private:
    tinybvh::BVH bvh;

    // Local AABBs used for BVH construction
    std::vector<tinybvh::bvhvec3> mins;
    std::vector<tinybvh::bvhvec3> maxs;

protected:
    static void _bind_methods();

public:
    BVHTLAS();
    ~BVHTLAS();

    void clear();
    void add_aabb(Vector3 min, Vector3 max);
    void build();
    void refit();
    int get_node_count() const;

    // Callback passed into tinybvh Build / Refit
    static void get_aabb_callback(unsigned int index, tinybvh::bvhvec3& out_min, tinybvh::bvhvec3& out_max, void* user_ptr);
};

} // namespace godot
