#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <cstdint>
#include <vector>
#include <atomic>

// Ensure tinybvh functions are safely inlined if included in multiple places
#ifndef TINYBVH_H
#define TINYBVH_H
#include "tiny_bvh.h"
#endif

namespace godot {

class BVHTLAS : public RefCounted {
    GDCLASS(BVHTLAS, RefCounted)

public:
    BVHTLAS();
    ~BVHTLAS();
    void init(uint32_t max_entities = 0); // pre-allocate

    int add_aabb(Vector3 p_min, Vector3 p_max);  // returns entity ID
    void add_aabb_bulk(const AABB *src, size_t count);
    void update_aabb(int id, Vector3 p_min, Vector3 p_max);
    void remove(int id);
    void clear();

    void build();                       // full rebuild
    void refit();                       // cheap incremental update
    PackedByteArray to_gpu_bvh();       // serialise to buffer
    int get_node_count() const;    // quick stats

    // Callback passed into tinybvh Build / Refit
    static void get_aabb_callback(unsigned int index,
        tinybvh::bvhvec3& out_min,
        tinybvh::bvhvec3& out_max,
        void* user_ptr);

protected:
    static void _bind_methods();

private:
    tinybvh::BVH bvh;

    std::vector<float> min_x, min_y, min_z;
    std::vector<float> max_x, max_y, max_z;
    std::vector<uint8_t> flags;         // bit0 = ALIVE, bit1 = DIRTY
    std::vector<int32_t> freelist;      // stack of free IDs

    void _allocate_buffers(uint32_t n);
    void _mark_dirty(uint32_t id);
    bool _should_rebuild() const;
};

} // namespace godot
