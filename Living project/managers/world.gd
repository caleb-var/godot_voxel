class_name World extends Manager

@onready var visualiser = $Visualiser

var object_meta : ObjectMeta = ObjectMeta.new()

var bvhTLAS		: BVHTLAS = BVHTLAS.new()

var TLAS		: Array[BVHNode] = []
var objects 	: Array[VoxelObject] = []
var object_count: int = 0
var next_index 	: int = 0
var instances 	: Array[Instance] = []
var packed_instances

func _init() -> void:
	return

func create_test() -> PackedByteArray:
	seed(11)

	var test_object = VoxelObject.new()
	var default_material = test_object.material_table.add_material(VoxelMaterial.new())
	
	var svo_root = SVO.new(0)
	svo_root.add_leaf_child(0,default_material)
	test_object.voxel_data = svo_root
	svo_root.update_aabb("force")
	add_object(test_object)
	for test in range(100000):
		var test_instance = Instance.new(objects[0],Vector3(randf()*100.0,randf()*100.0,randf()*100.0))
		add_instance(test_instance)
		
	for instance in instances:
		bvhTLAS.add_aabb(instance.aabb.position, instance.aabb.end)
	bvhTLAS.build()
	TLAS.append(BVHNode.new(instances))
	var return_array : PackedByteArray = full_serialize()
	#visualiser.visualize_TLAS(TLAS[0])
	
	return return_array




"""Returns the ID allocated"""
func add_object(object :VoxelObject) -> int:
	var index = 0
	if next_index !=0:
		object.object_id = next_index
		objects[next_index] = object
		index = next_index
		next_index = objects.find(null) if objects.has(null) else 0
	else:
		object.object_id = objects.size()
		objects.append(object)
		index = object.object_id
	object_count += 1
	return index
func add_instance(instance : Instance) -> int:
	instances.append(instance)
	return instances.size()-1
"""Returns the ID freed"""
func remove_object(index:int)->int:
	if not next_index:
		next_index = index
	objects[index] = null
	return index
func remove_instance(index:int) -> int:
	instances.remove_at(index)
	return index



"""
Serializes an entire SVO tree into a PackedByteArray.
Returns: { data: PackedByteArray, object_meta: ObjectMeta }
"""
func full_serialize() -> PackedByteArray:
	var packed = PackedByteArray()
	
	print("TLAS Nodes: ",TLAS.size())
	print("Instances: ",instances.size())
	print("Objects: ",objects.size())
	
	packed.append_array(serialize_objects())
	object_meta.TLAS_offset = (packed.size() / 4)
	packed.append_array(serialize_TLAS())
	object_meta.instances_offset = (packed.size() / 4)
	packed.append_array(serialize_instances())
	print(object_meta)
	
	packed = object_meta._serialize() + packed
	return packed
	
## Utility: dump a PackedByteArray that stores TinyBVH TLAS nodes
## Usage:
##     var nodes = tlas.to_gpu_bvh()
##     print_tlas_nodes(nodes)

const NODE_BYTES := 32           # 8 × u32

func print_tlas_nodes(raw: PackedByteArray) -> void:
	if raw.is_empty():
		push_error("print_tlas_nodes: buffer is empty")
		return

	var node_count := raw.size() / NODE_BYTES
	var db := StreamPeerBuffer.new()
	db.data_array = raw
	db.big_endian = false        # TinyBVH writes little-endian

	print("\nIdx |      Min (x y z)      |      Max (x y z)      | leftFirst | triCount | type")
	print("----+-----------------------+-----------------------+-----------+----------+------")

	for i in node_count:

		var base := i * NODE_BYTES
		db.seek(base)

		var min_x := db.get_float()          # u32→f32
		var min_y := db.get_float()
		var min_z := db.get_float()
		var left  := db.get_u32()

		var max_x := db.get_float()
		var max_y := db.get_float()
		var max_z := db.get_float()
		var tris  := db.get_u32()

		var node_type := "int" if tris == 0 else "leaf"

		print("%3d | %6.2f %6.2f %6.2f | %6.2f %6.2f %6.2f | %9d | %8d | %s"
			  % [i, min_x, min_y, min_z, max_x, max_y, max_z, left, tris, node_type])

	
func serialize_TLAS() -> PackedByteArray:
	#var packed_tlas = PackedByteArray()
	#packed_instances = PackedByteArray()
	#TLAS[0]._serialize_TLAS(packed_tlas,packed_instances)
	
	var bvh_packed = bvhTLAS.to_gpu_bvh()
	return bvh_packed
	
func serialize_objects() -> PackedByteArray:
	var packed_headers = PackedByteArray()
	var packed_nodes = PackedByteArray()
	var packed_voxels = PackedByteArray()
	var packed_materials = PackedByteArray()
	
	var object_data
	for object : VoxelObject in objects:
		"""as a Dict of: node_data, voxel_leaf and material_table"""
		"""We want to extract the object header so each object is at a certain index"""
		object_data = object._serialize(object_count)
		packed_headers.append_array(object_data["node_data"].slice(0,32))
		packed_nodes.append_array(object_data["node_data"].slice(32))
		packed_voxels.append_array(object_data["voxel_leaf"])
		packed_materials.append_array(object_data["material_table"])
	object_meta.voxel_leaf_offset = packed_nodes.size()/4
	object_meta.material_table_offset = packed_voxels.size()/4 + object_meta.voxel_leaf_offset
	return packed_headers + packed_nodes + packed_voxels + packed_materials
	
func serialize_instances() -> PackedByteArray:
	var _packed_instances = PackedByteArray()
	for instance in instances:
		_packed_instances.append_array(instance._serialize())
	return _packed_instances
