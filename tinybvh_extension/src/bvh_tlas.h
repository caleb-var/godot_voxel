#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <vector>
#include "tiny_bvh.h"

namespace godot {

class BVHTLAS : public RefCounted {
    GDCLASS(BVHTLAS, RefCounted)

private:
    std::vector<bvhvec3> mins;
    std::vector<bvhvec3> maxs;
    tinybvh_BVH bvh;

    static void get_aabb_callback(unsigned int index, bvhvec3* out_min, bvhvec3* out_max, void* user_ptr);

protected:
    static void _bind_methods();

public:
    void clear();
    void add_aabb(Vector3 min, Vector3 max);
    void build();
    void refit();
    int get_node_count() const;
};

} // namespace godot
