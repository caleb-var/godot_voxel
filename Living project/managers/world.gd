class_name World extends Manager

@onready var debug = $"../Debug"

var object_meta : ObjectMeta = ObjectMeta.new()
var flecs := FlecsGD.new()
var bvhTLAS		: BVHTLAS = BVHTLAS.new()

var TLAS		: Array[BVHNode] = []
var objects 	: Array[VoxelObject] = []
var object_count: int = 0
var next_index 	: int = 0
var instances 	: Array[Instance] = []
var packed_instances

func _init() -> void:
	pass
func create_test() -> PackedByteArray:
	seed(11)

	var test_object = VoxelObject.new()
	var default_material = test_object.material_table.add_material(VoxelMaterial.new())
	
	var svo_root = SVO.new(0)
	svo_root.add_leaf_child(0,default_material)
	test_object.voxel_data = svo_root
	svo_root.update_aabb("force")
	add_object(test_object)
	for test in range(100):
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
	
	print("Instances: ",instances.size())
	print("Objects: ",objects.size())
	
	packed.append_array(serialize_objects())
	object_meta.TLAS_offset = (packed.size())
	packed.append_array(serialize_TLAS())
	object_meta.instances_offset = (packed.size())
	packed.append_array(serialize_instances())
	print(object_meta)
	
	packed = object_meta._serialize() + packed
	return packed

	
func serialize_TLAS() -> PackedByteArray:	
	var bvh_packed = flecs.to_gpu_bvh()
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


func _on_tick(delta):
	flecs.progress(delta)
	$"../Player/Renderer".voxel_data_dirty = true
