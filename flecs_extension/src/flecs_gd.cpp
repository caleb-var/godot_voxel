#include "flecs_gd.h"
#include <godot_cpp/classes/dir_access.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/project_settings.hpp>
#include <unordered_map>


using namespace godot;
using godot::UtilityFunctions;

static FlecsGD *singleton = nullptr;
FlecsGD *FlecsGD::get_singleton() { return singleton; }
FlecsGD::~FlecsGD() { }

void FlecsGD::_bind_methods() {
    ClassDB::bind_method(D_METHOD("init"), &FlecsGD::init);
    ClassDB::bind_method(D_METHOD("set_threads", "threads"), &FlecsGD::set_threads);
    ClassDB::bind_method(D_METHOD("get_system_stats"), &FlecsGD::get_system_stats);
    
    ClassDB::bind_method(D_METHOD("progress", "delta"), &FlecsGD::progress);
    ClassDB::bind_method(D_METHOD("spawn", "components"), &FlecsGD::spawn);
    ClassDB::bind_method(D_METHOD("despawn", "id"), &FlecsGD::despawn);

    ClassDB::bind_method(D_METHOD("make_query", "ecsql"), &FlecsGD::make_query);
    ClassDB::bind_method(D_METHOD("each", "query_id", "callable"), &FlecsGD::each);

    ClassDB::bind_method(D_METHOD("load_module", "lib_path", "module_symbol"),&FlecsGD::load_module);
    ClassDB::bind_method(D_METHOD("load_script", "fecs_path"),&FlecsGD::load_script);
}
FlecsGD::FlecsGD() {
    // Optional: any init logic here
}
FlecsGD::~FlecsGD() {
    // Optional: any cleanup logic here
}

void FlecsGD::set_threads(int32_t n) {
    world.set_threads(n <= 0 ? 1 : n);
}

void FlecsGD::progress(double dt) {
    world.progress(static_cast<float>(dt));
}
int64_t FlecsGD::spawn(const Dictionary &d) {
    flecs::entity e = world.entity();
    for (int i = 0; i < d.size(); ++i) {
        String key = d.keys()[i];
        Variant val = d[key];

        flecs::id_t cid = world.lookup(key.utf8().get_data());
        if (!cid) { e.add(world.entity(key.utf8().get_data())); continue; }

        switch (val.get_type()) {
            case Variant::INT:   e.set(cid, (int64_t)val); break;
            case Variant::FLOAT: e.set(cid, (double)val);  break;
            case Variant::BOOL:  e.set(cid, (bool)val);    break;
            default:
                UtilityFunctions::push_warning("spawn(): unsupported variant for "+key);
        }
    }
    return static_cast<int64_t>(e);
}

void FlecsGD::despawn(int64_t id) {
    world.entity(static_cast<flecs::id_t>(id)).destruct();
}

// ───────────────────────────────────────────────
//  Hot-loading helpers
// ───────────────────────────────────────────────
bool FlecsGD::load_module(const String &path, const String &file) {
    bool ok = ecs_import_from_library(
        world.c_ptr(),
        path.utf8(),
        file.utf8());
    if (!ok) UtilityFunctions::push_warning("load_module failed: "+file);
    return ok;
}

bool FlecsGD::load_script(const String &path, const String &file) {
    bool ok = world.script_run_file(
        (path+file).utf8());
    if (!ok) UtilityFunctions::push_warning("load_script failed: "+file);
    return ok;
}