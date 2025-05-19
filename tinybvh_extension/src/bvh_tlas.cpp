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

void BVHTLAS::clear() {
    mins.clear();
    maxs.clear();
    bvh = {};
}

void BVHTLAS::add_aabb(Vector3 min, Vector3 max) {
    mins.emplace_back(min.x, min.y, min.z);
    maxs.emplace_back(max.x, max.y, max.z);
}

void BVHTLAS::get_aabb_callback(unsigned int index, bvhvec3* out_min, bvhvec3* out_max, void* user_ptr) {
    auto* self = static_cast<BVHTLAS*>(user_ptr);
    *out_min = self->mins[index];
    *out_max = self->maxs[index];
}

void BVHTLAS::build() {
    tinybvh_build(&bvh, (unsigned int)mins.size(), get_aabb_callback, this);
}

void BVHTLAS::refit() {
    tinybvh_refit(&bvh, get_aabb_callback, this);
}

int BVHTLAS::get_node_count() const {
    return bvh.node_count;
}
