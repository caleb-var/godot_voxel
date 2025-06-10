#define FLECS_CPP
#define FLECS_IMPLEMENTATION
#define TINYBVH_IMPLEMENTATION
#include "flecs_gd.h"
#include <godot_cpp/classes/dir_access.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/random_number_generator.hpp>
#include <tiny_bvh.h>
#include <random>
std::mt19937 rng(std::random_device{}());
std::uniform_real_distribution<float> dist(-1.0f, 1.0f);

#include <module.voxel.h>

using namespace godot;
using namespace module_voxel;
using tinybvh::bvhvec3;


FlecsGD::FlecsGD(){
    TLAS = tinybvh::BVH();
    TLAS.user_ptr = this;
    world = flecs::world();
    world.import<VoxelModule>();
    flecs::entity base = world.prefab("base").set(Position{0,0,0}).set(Velocity{0,0,0});
    instance_index = base.id();
    TLAS.Build(get_aabb_callback,world.count(world.component<Position>()));
}
FlecsGD::~FlecsGD(){}

void FlecsGD::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_threads", "threads"), &FlecsGD::set_threads);
    ClassDB::bind_method(D_METHOD("progress", "delta"), &FlecsGD::progress);
    ClassDB::bind_method(D_METHOD("load_module", "lib_path", "module_symbol"),&FlecsGD::load_module);
    ClassDB::bind_method(D_METHOD("load_script", "fecs_path"),&FlecsGD::load_script);
    ClassDB::bind_method(D_METHOD("to_gpu_bvh"),&FlecsGD::to_gpu_bvh);
    ClassDB::bind_method(D_METHOD("bulk_create","count","prefab_name"),&FlecsGD::bulk_create);
}
void FlecsGD::get_aabb_callback(unsigned idx,
                        bvhvec3& out_min,
                        bvhvec3& out_max,
                        void* user) {
    auto* self = static_cast<FlecsGD*>(user);
    flecs::entity e{self->world,self->instance_index+idx};
    Position *p = e.get_mut<Position>();
    out_min = bvhvec3(p->x,p->y,p->z);
    out_max = bvhvec3(p->x +1.,p->y+1.,p->z+1.);
}

void FlecsGD::set_threads(int32_t n) {
    world.set_threads(n <= 0 ? 1 : n);
}

void FlecsGD::progress(double dt) {
    world.progress(static_cast<float>(dt));
    TLAS.Build(get_aabb_callback,world.count(world.component<Position>()));
}
void FlecsGD::bulk_create(int count, String prefab_name){
    for (int i = 0; i < count; i++) {
        flecs::entity e = world.entity().set(Position{0,0,0}).set(Velocity{dist(rng),dist(rng),dist(rng)});
    }
}

bool FlecsGD::load_module(const String &path, const String &module) {
    bool ok = ecs_import_from_library(world.c_ptr(),path.utf8().get_data(),"ModuleVoxel");

    if (!ok) UtilityFunctions::push_warning("load_module failed: "+module+ " at path: " + path);
    return ok;
}

bool FlecsGD::load_script(const String &path, const String &file) {
    bool ok = world.script_run_file(
        (path+file).utf8());
    if (!ok) UtilityFunctions::push_warning("load_script failed: "+file);
    return ok;
}
String FlecsGD::to_json(){
    return String(world.to_json());
}
PackedByteArray FlecsGD::to_gpu_bvh() {
    PackedByteArray output;
    const uint32_t node_count = TLAS.usedNodes; //skip 0 & 1?
    const size_t bytes = node_count * 32;

    output.resize(bytes);
    memcpy(output.ptrw(),&TLAS.bvhNode[0],bytes);
    return output;
}