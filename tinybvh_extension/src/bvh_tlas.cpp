#define TINYBVH_IMPLEMENTATION
#include "tiny_bvh.h"

#include "bvh_tlas.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void BVHTLAS::_bind_methods() {
    ClassDB::bind_method(D_METHOD("clear"), &BVHTLAS::clear);
    ClassDB::bind_method(D_METHOD("add_aabb", "min", "max"), &BVHTLAS::add_aabb);
    ClassDB::bind_method(D_METHOD("build"), &BVHTLAS::build);
    ClassDB::bind_method(D_METHOD("refit"), &BVHTLAS::refit);
    ClassDB::bind_method(D_METHOD("get_node_count"), &BVHTLAS::get_node_count);
}

BVHTLAS::BVHTLAS() {
    // Optional: any init logic here
}

BVHTLAS::~BVHTLAS() {
    // Optional: any cleanup logic here
}
void BVHTLAS::clear() {
    mins.clear();
    maxs.clear();
    bvh = {};
}

void BVHTLAS::add_aabb(Vector3 min, Vector3 max) {
    mins.emplace_back(min.x, min.y, min.z);
    maxs.emplace_back(max.x, max.y, max.z);
}
void godot::BVHTLAS::get_aabb_callback(unsigned int index, tinybvh::bvhvec3 &out_min, tinybvh::bvhvec3 &out_max, void* user_ptr) {
    BVHTLAS* self = static_cast<BVHTLAS*>(user_ptr);
    out_min = self->mins[index];
    out_max = self->maxs[index];
}

void BVHTLAS::build() {
    bvh.user_ptr = this;
    bvh.Build( &get_aabb_callback,mins.size());
}

void BVHTLAS::refit() {
    bvh.Refit();
}

int BVHTLAS::get_node_count() const {
    return bvh.allocatedNodes;
}
