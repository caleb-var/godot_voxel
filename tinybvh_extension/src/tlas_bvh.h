#pragma once
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include "tiny_bvh.h"

class TLASBVH : public godot::RefCounted {
    GDCLASS(TLASBVH, godot::RefCounted);

private:
    tinybvh::BVH bvh;
    std::vector<float> aabb_data; // Flat AABB array (minx,miny,minz,maxx,maxy,maxz per object)
    int num_objects = 0;

protected:
    static void _bind_methods();

public:
    TLASBVH() = default;
    ~TLASBVH() override = default;

    void build(const godot::PackedFloat32Array &aabbs);  // Input: [minx,miny,minz,maxx,maxy,maxz, ...] for N objects
    void refit(const godot::PackedFloat32Array &aabbs);  // For updating bounds efficiently

    int get_node_count() const;
    int get_object_count() const;
};
