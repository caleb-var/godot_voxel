#[compute]
#version 450

const float INF = 1e20;
const int max_steps = 10;
const float threshold = 0.05;
const int MAX_QUEUE = 200;
void swap(inout uint a, inout uint b) {
    uint temp = a;
    a = b;
    b = temp;
}
struct bvhvec3 {
    float x, y, z;
};
struct Material {
    uint material_ID;    // 4 bytes
    float roughness;     // 4 bytes
    float metallic;      // 4 bytes
    float _pad0;         // 4 bytes
    vec4 albedo;         // 16 bytes
};
struct Box {
    vec3 min;
    vec3 max;
};
struct Hit { 
    uint object_ID;
    uint materialID;       // Material ID of the hit voxel
    bool hit;              // True if a voxel was hit
    float t;
    ivec3 voxelCoords;     // Coordinates of the hit voxel
    vec3 normal;           // Surface normal of the hit face
    vec3 debug;
};
struct Ray {
    vec3 origin;
    vec3 direction;
    vec3 inv_direction;
    vec3 energy;
    float distance;
};
struct ObjectMeta {
    uint tlas_offset;    // Offset into data[] where objects begin
    
    uint voxel_leaf_offset;
    uint material_table_offset;

    uint instances_offset;  // Offset where instances begin
};
struct VoxelLeaf {
    // 4 bytes total: 
    //  - bits [0..7]   => material ID
    //  - bits [8..31]  => normal.x, normal.y, normal.z (packed)
    uint packed;
};
struct Instance {
    mat4 object_transform;
    mat4 inv_object_transform;
    uint object_offset;
    uint _meta0; //for padding
    uint _meta1;
    uint _meta2;
};
struct SVO { //32 bytes
    uint meta;                  // 4 bytes
    uint node_offset;           // 4 bytes
    uint voxel_offset;          // 4 bytes
    uint occupancy_mask_lower;  // 4 bytes
    uint occupancy_mask_upper;  // 4 bytes
    Box box;                    // 12 bytes
};
struct TLASNode {
    vec3 aabbMin; 
    uint left_first; // 16 bytes
    vec3 aabbMax; 
    uint instance_count;	// 16 bytes, total: 32 bytes
};

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
layout(set = 0, binding = 0) buffer CameraBuffer {
                            // Camera Transform Layout (Packed into a mat4)
                            // --------------------------------------------
                            // mat4 camera_transform:
                            // --------------------------------------------
                            // | basis.x.x | basis.x.y | basis.x.z | fov_y         | // Row 0: Basis X and FOV
                            // | basis.y.x | basis.y.y | basis.y.z | voxel_size    | // Row 1: Basis Y and Voxel Size
                            // | basis.z.x | basis.z.y | basis.z.z | resolution.x  | // Row 2: Basis Z and Window Width
                            // | origin.x  | origin.y  | origin.z  | resolution.y  | // Row 3: Origin and Window Height
                            // --------------------------------------------
                            // Access in shader:
                            //   - mat3 basis = mat3(camera_transform);        // Extract 3x3 Basis matrix
                            //   - vec3 origin = camera_transform[3].xyz;     // Extract Origin
                            //   - float fov_y = camera_transform[0].w;       // Extract FOV (field of view)
                            //   - float voxel_size = camera_transform[1].w;  // Extract Voxel Size
                            //   - vec2 resolution = vec2(camera_transform[2].w, camera_transform[3].w);  // Extract Window Size (resolution)
                            // Will probably make this the dynamic animation / particle buffer. Maybe object transform buffer too.
    mat4 camera_transform;
    //Hit VoxelHit[];     //TO DO: hit voxel cached buffer to store voxels between frames, caching in locality to frequently accessed to rarely accessed, so the rare ones can be popped and replaced.
};
layout(set = 0, binding = 1, rgba8) writeonly uniform image2D OutputTexture;  // Output texture
layout(set = 1, binding = 0) buffer ObjectBuffer{
    /*
        object_data = [TLAS][VoxelObject][Instances]
        VoxelObject = [Object Headers uint][Nodes][VoxelLeaf][Materials]
    */
    ObjectMeta Meta;
    uint object_data[];
};

vec4 get_vec4_from_object_data(uint index) {
    return vec4(
        uintBitsToFloat(object_data[index + 0]),
        uintBitsToFloat(object_data[index + 1]),
        uintBitsToFloat(object_data[index + 2]),
        uintBitsToFloat(object_data[index + 3])
    );
}
mat4 get_mat4_from_object_data(uint index) {
    return mat4(
        get_vec4_from_object_data(index),
        get_vec4_from_object_data(index + 4),
        get_vec4_from_object_data(index + 8),
        get_vec4_from_object_data(index + 12)
    );
}
int position_to_index(vec3 offset){
	return int(offset.x) + int(offset.y) * 4 + int(offset.z) * 16;
}
bool get_bit(uint value, uint index){
    return ((value >> index) & 1) != 0;
}

bool is_occupied(uint lower, uint upper, uint index) {
    if (index >= 64) return false; // Out of range check

    uint mask = 1u << (index & 31u); // Compute bit mask for index (mod 32)
    
    return (index < 32) ? (lower & mask) != 0u : (upper & mask) != 0u;
}

TLASNode get_tlasnode(uint node_index) {
    TLASNode node;
    uint base_index = Meta.tlas_offset/4 + (node_index*8);
    node.aabbMin = vec3(
        uintBitsToFloat(object_data[base_index]),
        uintBitsToFloat(object_data[base_index + 1]),
        uintBitsToFloat(object_data[base_index + 2]));

    node.left_first = object_data[base_index + 3];

    node.aabbMax = vec3(
        uintBitsToFloat(object_data[base_index + 4]),
        uintBitsToFloat(object_data[base_index + 5]),
        uintBitsToFloat(object_data[base_index + 6]));

    node.instance_count = object_data[base_index + 7];
    return node;
}

Instance get_instance(uint instance_index) {
    Instance instance;
    uint base_index = Meta.instances_offset/4 + (instance_index*36);
    instance.object_transform = get_mat4_from_object_data(base_index);
    instance.inv_object_transform = get_mat4_from_object_data(base_index + 16);
    instance.object_offset = object_data[base_index + 32];
    return instance;
}

vec3 camera_origin = camera_transform[3].xyz;
mat3 camera_basis = mat3(camera_transform);
vec2 resolution = vec2(camera_transform[2].w, camera_transform[3].w);


Ray create_ray(vec3 origin, vec3 direction){
    Ray ray;
    ray.origin = origin;
    ray.direction = direction;
    ray.inv_direction = 1/direction;
    ray.energy = vec3(1.0);
    return ray;
}
Ray create_primary_ray(vec2 screenPos){
    vec3 origin = camera_origin;
    vec3 world_direction = normalize(camera_basis * vec3(screenPos,-1.0));
    return create_ray(origin, world_direction);
}
Ray transform_ray(Ray ray, mat4 inv_transform) {
    Ray local_ray;
    local_ray.origin = (inv_transform * vec4(ray.origin, 1.0)).xyz;
    local_ray.direction = normalize((inv_transform * vec4(ray.direction, 0.0)).xyz);
    local_ray.inv_direction = 1.0 / local_ray.direction;
    local_ray.energy = ray.energy;
    return local_ray;
}


vec3 compute_miss(Ray ray) {
    vec3 unit_direction = normalize(ray.direction);
    float gradient_factor = 0.5 * (unit_direction.y + 1.0);
    return mix(vec3(1.0, 1.0, 1.0), vec3(0.5, 0.7, 1.0), gradient_factor);
}

float intersect_aabb(Ray ray, vec3 aabbMin, vec3 aabbMax) {
    float t_min = -1e30f; // Allow intersections from any direction
    float t_max = 1e30f;  // Large value representing infinity

    float t1 = (aabbMin.x - ray.origin.x) * ray.inv_direction.x;
    float t2 = (aabbMax.x - ray.origin.x) * ray.inv_direction.x;
    t_min = max(t_min, min(t1, t2));
    t_max = min(t_max, max(t1, t2));

    t1 = (aabbMin.y - ray.origin.y) * ray.inv_direction.y;
    t2 = (aabbMax.y - ray.origin.y) * ray.inv_direction.y;
    t_min = max(t_min, min(t1, t2));
    t_max = min(t_max, max(t1, t2));

    t1 = (aabbMin.z - ray.origin.z) * ray.inv_direction.z;
    t2 = (aabbMax.z - ray.origin.z) * ray.inv_direction.z;
    t_min = max(t_min, min(t1, t2));
    t_max = min(t_max, max(t1, t2));

    return (t_min <= t_max && t_max > 0.0) ? t_min : 1e30f;
}

Hit traverse_tlas(Ray ray, out float t_entry, out float t_exit) {
    Hit hit;
    hit.hit = false;
    hit.debug = vec3(0.0);

    TLASNode queue[MAX_QUEUE]; // Stack-based traversal
    TLASNode node = get_tlasnode(0);
    int queue_pointer = intersect_aabb(ray, node.aabbMin,node.aabbMax) != 1e30f ? 0 : -1;
    
    if (queue_pointer >= 0) queue[0] = node; // Start from the root

    while (queue_pointer >= 0) {
        
        node = queue[queue_pointer--]; // Pop from stack
        if (node.instance_count != 0) { // Leaf node
            hit.debug = vec3(1.0);
            hit.hit = true;
            continue;
        }

        hit.debug.x += 0.05;

        TLASNode left = get_tlasnode(node.left_first);
        TLASNode right = get_tlasnode(node.left_first + 1);

        float distance_left = intersect_aabb(ray, left.aabbMin, left.aabbMax);
        float distance_right = intersect_aabb(ray, right.aabbMin, right.aabbMax);

        if (distance_left > distance_right) {
            float temp_dist = distance_left; 
            distance_left = distance_right; 
            distance_right = temp_dist;

            TLASNode temp_node = left; 
            left = right; 
            right = temp_node;
        }

        // Push children onto the stack
        if (distance_left != 1e30f) queue[++queue_pointer] = left;
        if (distance_right != 1e30f) queue[++queue_pointer] = right;
    }

    return hit;
}






void main() {
    ivec2 pixel_coords = ivec2(gl_GlobalInvocationID.xy);
    vec2 screenPos = (pixel_coords * 2. - resolution) / resolution.y;
    screenPos.y = -screenPos.y; // Flip Y-axis for NDC
    vec4 color = vec4(0.0, 0.0, 0.0, 1.0);
    float t_entry, t_exit;

    Ray ray = create_primary_ray(screenPos);

    Hit hit = traverse_tlas(ray,t_entry,t_exit);
    //Hit hit = get_first_hit_instance(ray,t_entry, t_exit);
    
    if (hit.debug != vec3(0.0)){
        color = vec4(hit.debug,1.0);
    }else{
        color = vec4(compute_miss(ray), 1.0);
    }
    imageStore(OutputTexture, pixel_coords, color);
}

