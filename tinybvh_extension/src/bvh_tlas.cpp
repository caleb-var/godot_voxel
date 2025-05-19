#include "bvh_tlas.h"

BvhTlas::BvhTlas() {}

BvhTlas::~BvhTlas() {}

void BvhTlas::build(Array aabb_array) {
    int count = aabb_array.size();
    aabbs.resize(count);

    for (int i = 0; i < count; ++i) {
        Dictionary dict = aabb_array[i];
        Vector3 min = dict["min"];
        Vector3 max = dict["max"];
        for (int j = 0; j < 3; ++j) {
            aabbs[i].min[j] = min[j];
            aabbs[i].max[j] = max[j];
        }
    }

    // nodes count = 2*N - 1
    nodes.resize(aabbs.size() * 2 - 1);

    tinybvh::build(
        aabbs.data(), sizeof(SimpleAabb), aabbs.size(),
        nodes.data(), sizeof(tinybvh::BVHNode),
        [](const void* aabb, int axis) -> float {
            const SimpleAabb* a = reinterpret_cast<const SimpleAabb*>(aabb);
            return 0.5f * (a->min[axis] + a->max[axis]);
        },
        [](const void* aabb, int axis) -> float {
            const SimpleAabb* a = reinterpret_cast<const SimpleAabb*>(aabb);
            return a->min[axis];
        },
        [](const void* aabb, int axis) -> float {
            const SimpleAabb* a = reinterpret_cast<const SimpleAabb*>(aabb);
            return a->max[axis];
        }
    );
}

void BvhTlas::refit(Array aabb_array) {
    // Update AABBs only, then refit
    int count = aabb_array.size();
    if (count != int(aabbs.size()))
        build(aabb_array); // Fallback to rebuild

    for (int i = 0; i < count; ++i) {
        Dictionary dict = aabb_array[i];
        Vector3 min = dict["min"];
        Vector3 max = dict["max"];
        for (int j = 0; j < 3; ++j) {
            aabbs[i].min[j] = min[j];
            aabbs[i].max[j] = max[j];
        }
    }
    tinybvh::refit(
        aabbs.data(), sizeof(SimpleAabb), aabbs.size(),
        nodes.data(), sizeof(tinybvh::BVHNode),
        [](const void* aabb, int axis) -> float {
            const SimpleAabb* a = reinterpret_cast<const SimpleAabb*>(aabb);
            return 0.5f * (a->min[axis] + a->max[axis]);
        },
        [](const void* aabb, int axis) -> float {
            const SimpleAabb* a = reinterpret_cast<const SimpleAabb*>(aabb);
            return a->min[axis];
        },
        [](const void* aabb, int axis) -> float {
            const SimpleAabb* a = reinterpret_cast<const SimpleAabb*>(aabb);
            return a->max[axis];
        }
    );
}

PackedFloat32Array BvhTlas::get_nodes() const {
    PackedFloat32Array out;
    out.resize(nodes.size() * 8); // Each node: 2x float3 (min, max), 2x int (left, right/prim)
    int i = 0;
    for (const auto &n : nodes) {
        out.set(i++, n.bmin[0]);
        out.set(i++, n.bmin[1]);
        out.set(i++, n.bmin[2]);
        out.set(i++, n.bmax[0]);
        out.set(i++, n.bmax[1]);
        out.set(i++, n.bmax[2]);
        out.set(i++, float(n.left));   // These are ints, can reinterpret as float if needed
        out.set(i++, float(n.right));  // (or store as separate buffer if desired)
    }
    return out;
}

void BvhTlas::_bind_methods() {
    ClassDB::bind_method(D_METHOD("build", "aabb_array"), &BvhTlas::build);
    ClassDB::bind_method(D_METHOD("refit", "aabb_array"), &BvhTlas::refit);
    ClassDB::bind_method(D_METHOD("get_nodes"), &BvhTlas::get_nodes);
}
