#define TINYBVH_IMPLEMENTATION
#include "tiny_bvh.h"

#include "bvh_tlas.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;
using tinybvh::bvhvec3;

void BVHTLAS::_bind_methods() {
    //per/bulk entity
    ClassDB::bind_method(D_METHOD("add_aabb", "min", "max"), &BVHTLAS::add_aabb);
    ClassDB::bind_method(D_METHOD("update_aabb", "id", "min", "max"), &BVHTLAS::update_aabb);
    ClassDB::bind_method(D_METHOD("remove", "id"), &BVHTLAS::remove);
    //bvh functions
    ClassDB::bind_method(D_METHOD("build"), &BVHTLAS::build);
    ClassDB::bind_method(D_METHOD("refit"), &BVHTLAS::refit);
    ClassDB::bind_method(D_METHOD("clear"), &BVHTLAS::clear);
    //support calls
    ClassDB::bind_method(D_METHOD("get_node_count"), &BVHTLAS::get_node_count);
    ClassDB::bind_method(D_METHOD("to_gpu_bvh"), &BVHTLAS::to_gpu_bvh);
}

BVHTLAS::BVHTLAS() {
    // Optional: any init logic here
}

BVHTLAS::~BVHTLAS() {
    // Optional: any cleanup logic here
}
/* ───────────────────  public: management  ────────────────── */

PackedByteArray BVHTLAS::to_gpu_bvh() {
    PackedByteArray output;
    const uint32_t node_count = bvh.usedNodes; //skip 0 & 1?
    const size_t bytes = node_count * 32;

    output.resize(bytes);
    memcpy(output.ptrw(),&bvh.bvhNode[0],bytes);
    return output;
}

int BVHTLAS::get_node_count() const {
    return bvh.NodeCount();
}

/* ───────────────────  Per Entity or Bulk  ────────────────── */

int BVHTLAS::add_aabb(Vector3 pmin, Vector3 pmax) {
    int id;

    if (!freelist.empty()) {
        /* ─ Re-use a vacant slot ─ */
        id = freelist.back();
        freelist.pop_back();
        min_x[id] = pmin.x;  min_y[id] = pmin.y;  min_z[id] = pmin.z;
        max_x[id] = pmax.x;  max_y[id] = pmax.y;  max_z[id] = pmax.z;
    } else {
        /* ─ Append new slot ─ */
        id = static_cast<int>(min_x.size());
        min_x.push_back(pmin.x);  min_y.push_back(pmin.y);  min_z.push_back(pmin.z);
        max_x.push_back(pmax.x);  max_y.push_back(pmax.y);  max_z.push_back(pmax.z);
    }
    return id;
}

void BVHTLAS::update_aabb(int id, Vector3 pmin, Vector3 pmax) {
    min_x[id] = pmin.x; min_y[id] = pmin.y; min_z[id] = pmin.z;
    max_x[id] = pmax.x; max_y[id] = pmax.y; max_z[id] = pmax.z;
}

void BVHTLAS::remove(int id) {
    freelist.push_back(id);
}

/* ───────────────────    bvh functions    ────────────────── */

void BVHTLAS::build() {
    bvh.user_ptr = this;
    bvh.Build(get_aabb_callback,min_x.size());
}

void BVHTLAS::refit() {
    bvh.Refit();
}

void BVHTLAS::clear() {
    freelist.clear();
    bvh = {};
}

void godot::BVHTLAS::get_aabb_callback(unsigned idx,
                           bvhvec3& out_min,
                           bvhvec3& out_max,
                           void* user) {
        auto* self = static_cast<BVHTLAS*>(user);
        out_min = bvhvec3(self->min_x[idx],
                          self->min_y[idx],
                          self->min_z[idx]);
        out_max = bvhvec3(self->max_x[idx],
                          self->max_y[idx],
                          self->max_z[idx]);
}
/* ───────────────  private helpers  ───────────────────── */

void BVHTLAS::_allocate_buffers(uint32_t n) {
        min_x.resize(n); min_y.resize(n); min_z.resize(n);
        max_x.resize(n); max_y.resize(n); max_z.resize(n);
}
