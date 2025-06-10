#define FLECS_IMPLEMENTATION
#define FLECS_CPP

#include <module.voxel.h>
#include <flecs.h>


namespace module_voxel{
    /* Module implementation */
    VoxelModule::VoxelModule(flecs::world &world){
            world.module<VoxelModule>();
            world.component<Position>();
            world.component<Velocity>();
            world.component<Color>();
            world.component<Instance>();
            world.system<Position, const Velocity>("Move")
                .each([](Position& p, const Velocity& v){
                    p.x += v.x;
                    p.y += v.y;
                    p.z += v.z;
                });}
}