#pragma once

#ifndef GODOT_FLECS_MODULE_H
#define GODOT_FLECS_MODULE_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/global_constants.hpp>
#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/utility_functions.hpp>


#include "flecs.h"

namespace godot {

//--------------------------------------------------------------------
// Lightweight wrappers for handles that GDScript can keep as int64.
//--------------------------------------------------------------------
using EntityID = int64_t;   // flecs::id_t is uint64_t; Godot uses signed 64‑bit.
using QueryID  = int64_t;

//--------------------------------------------------------------------
// GDFlecs – singleton Node that owns a single flecs::world instance
//--------------------------------------------------------------------
class FlecsGD : public Node {
    GDCLASS(FlecsGD, Node);

public:
    static FlecsGD *get_singleton();

    //----------------------------------------------------------------
    // World lifecycle
    //----------------------------------------------------------------
    void init();                                    // Optional manual init
    void set_threads(int32_t thread_count);         // Call once before init
    void progress(double delta);

    //----------------------------------------------------------------
    // Entity creation / deletion (archetype inferred from Dictionary keys)
    //----------------------------------------------------------------
    EntityID spawn(const Dictionary &components);   // returns entity id
    void     despawn(EntityID id);

    //----------------------------------------------------------------
    // Queries – cached
    //----------------------------------------------------------------
    QueryID  make_query(const String &flecs_query); // returns opaque id
    void     each(QueryID id, const Callable &cb);  // cb(entity_id, comp1, ..)

    //----------------------------------------------------------------
    // Hot‑loading of native & script modules
    //----------------------------------------------------------------
    bool load_module(const String &path, const String &file);
    bool load_script(const String &path, const String &file);

    //----------------------------------------------------------------
    // Debug / profiling helpers
    //----------------------------------------------------------------
    TypedArray<Dictionary> get_system_stats() const; // {name, time_avg, time_max}
protected:
    static void _bind_methods();
private:
    flecs::world           world;
    std::unordered_map<QueryID, flecs::query_base> queries;
    int64_t FlecsGD::last_query_id = 0;

    // helpers
    EntityID _gd_entity_to_id(const Variant &v) const;
    Variant  _convert_column(flecs::entity_t comp, void *ptr);
};
} // namespace godot

#endif