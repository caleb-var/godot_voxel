#define TINYBVH_IMPLEMENTATION
#include "tiny_bvh.h"

#include "bvh_tlas.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;
using tinybvh::bvhvec3;

void BVHTLAS::_bind_methods() {
    ClassDB::bind_method(D_METHOD("init", "max_entities"), &BVHTLAS::init);
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

void BVHTLAS::init(uint32_t max_entities) {
    if (max_entities) _allocate_buffers(max_entities);
    clear();
}

PackedByteArray BVHTLAS::to_gpu_bvh() {
    return PackedByteArray();
}

int BVHTLAS::get_node_count() const {
    return bvh.allocatedNodes;
}

/* ───────────────────  Per Entity or Bulk  ────────────────── */

int BVHTLAS::add_aabb(Vector3 min, Vector3 max) {
    int id;
    if (!freelist.empty()) { id = freelist.back(); freelist.pop_back(); }
    else { id = static_cast<int>(min_x.size()); _allocate_buffers(id + 1); }

    min_x[id] = min.x; min_y[id] = min.y; min_z[id] = min.z;
    max_x[id] = max.x; max_y[id] = max.y; max_z[id] = max.z;
    flags[id] = 0x03; // ALIVE | DIRTY
    _mark_dirty(id);
    return id;
}

void BVHTLAS::update_aabb(int id, Vector3 pmin, Vector3 pmax) {
    min_x[id] = pmin.x; min_y[id] = pmin.y; min_z[id] = pmin.z;
    max_x[id] = pmax.x; max_y[id] = pmax.y; max_z[id] = pmax.z;
    _mark_dirty(id);
}

void BVHTLAS::remove(int id) {
    flags[id] = 0x00; // dead
    freelist.push_back(id);
}

/* ───────────────────    bvh functions    ────────────────── */

void BVHTLAS::build() {
    bvh.user_ptr = this;
    bvh.Build( &get_aabb_callback,min_x.size());
}

void BVHTLAS::refit() {
    if(_should_rebuild()){build();return;}
    bvh.Refit();
}

void BVHTLAS::clear() {
    std::fill(flags.begin(), flags.end(), uint8_t(0));
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
        flags.resize(n);
}

inline void BVHTLAS::_mark_dirty(uint32_t id) { flags[id] |= 0x02; }

/* naive heuristic – refine later */
bool BVHTLAS::_should_rebuild() const {
        static uint32_t frame = 0; ++frame;
        if (frame % 30 != 0) return false;             // every 30th frame
        size_t dirty = 0, total = flags.size();
        for (auto f : flags) dirty += (f & 0x02) != 0;
        return dirty > total / 5;                      // >20 % dirty
}