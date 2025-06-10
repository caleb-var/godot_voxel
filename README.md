Current progress:

two GDExtensions for tinybvh & flecs. Only flecs will proceed - tinybvh will be a flecs module.

Current pipeline for flecs entitys with transform components powering tinybvh TLAS with objects, instances & materials is function.

-> Packed into a PackedByteArray for SSBO on compute shader using callbacks into the flecs component tables.

-> Support full camera buffer update + partial object buffer update using flecs to push updates through.

Next step is moving tinybvh TLAS contruction & refit logic to flecs multi-threaded system. Then write custom BLAS definition to support multiple types of voxel storage by default. Starting with SVO brick 4x4x4 with 64 bit occupancy mask & cached ray-aabb intersection at the 4x4x4 grid, for lighting fast BLAS traversal.

Port systems in flecs pipeline to power TLAS (partially done) -> Instances -> Objects (Animation) -> VoxelParts (little objects) -> BLAS index & count of uint32 (Animation).
