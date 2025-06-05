extends RefCounted
class_name BVHNode

const SHIFT = 32768
const SIZE = 32 		#in bytes
const SIZE_UINT = 4
const MAX_INSTANCES = 1


var bounding_box: AABB
var left_first : int = 0
var left: BVHNode
var right: BVHNode

var first_instance_index : int = -1
var instances: Array[Instance]  # references to voxel objects, or their bounding boxes

func _to_string() -> String:
	return "Leaf?[%d], pointers[%d,%d]" %[
			1 if instances.size()!=0 else 0,
			left_first,
			left_first+1]

func _init(_instances: Array[Instance] = []):
	compute_bounding_box(_instances)
	left = null
	right = null
	build_bvh(_instances)

func build_bvh(_instances) -> void:
	if _instances.size() == 0:
		return
	if _instances.size() <= MAX_INSTANCES:
		instances = _instances
		return
	# 1) Determine largest axis
	var size = bounding_box.size
	var axis_index = 0  # default to x
	if size.y > size.x and size.y >= size.z:
		axis_index = 1
	elif size.z > size.x and size.z > size.y:
		axis_index = 2
	
	# 2) Sort by center
	sort_by_center_axis(_instances, axis_index)
	
	# 3) Split
	var half = _instances.size() / 2
	var left_instances = _instances.slice(0, half)
	var right_instances = _instances.slice(half)
	left = BVHNode.new(left_instances)
	right = BVHNode.new(right_instances)

func compute_bounding_box(_instances = instances) -> void:
	bounding_box = _instances[0].aabb
	for instance : Instance in _instances.slice(1):
		bounding_box = bounding_box.expand(instance.aabb.position)
		bounding_box = bounding_box.expand(instance.aabb.end)

func sort_by_center_axis(_instances: Array, axis_index: int):
	match axis_index:
		0:
			_instances.sort_custom(_compare_x)
		1:
			_instances.sort_custom(_compare_y)
		2:
			_instances.sort_custom(_compare_z)

func _compare_x(a, b) -> bool:
	return get_center(a).x < get_center(b).x
func _compare_y(a, b) -> bool:
	return get_center(a).y < get_center(b).y
func _compare_z(a, b) -> bool:
	return get_center(a).z < get_center(b).z
func get_center(obj : Instance) -> Vector3:
	return obj.aabb.get_center()
	


func refit_bvh(bvh_nodes: Array, parent_of: Array, changed_leaves: Array) -> void:
	# changed_leaves is a list of node indices that had bounding box changes.
	# We'll recompute bounding boxes up the tree until we reach the root.

	var stack = changed_leaves.duplicate() # clone
	var visited = {} # to avoid re-processing the same node multiple times

	while stack.size() > 0:
		var node_index = stack.pop_back()
		if node_index in visited:
			continue
		visited[node_index] = true
		var node = bvh_nodes[node_index]

		# If NOT a leaf, we recalc from children:
		if node.left_child != -1 and node.right_child != -1:
			var left_node  = bvh_nodes[node.left_child]
			var right_node = bvh_nodes[node.right_child]
			# Recompute bounding box:
			node.bounds_min = left_node.bounds_min.min(right_node.bounds_min)
			node.bounds_max = left_node.bounds_max.max(right_node.bounds_max)
		
		# Once updated, we bubble up to the parent:
		var p_index = parent_of[node_index]
		if p_index != -1:
			stack.append(p_index)
func _serialize_TLAS(
		packed_TLAS		: PackedByteArray = PackedByteArray(),
		packed_instances: PackedByteArray = PackedByteArray(),
		debug_print 	: bool = false):

	var queue : Array = [self]
	var index = 0
	while !queue.is_empty():
		var current : BVHNode = queue.pop_front()
		
		if current.instances.size() == 0:
			current.left_first = index + 1
		else:
			current.left_first = packed_instances.size() / Instance.INSTANCE_SIZE
		
		if debug_print:
			print(current, " at index:", index)
		if current.left: 
			index +=1
			queue.append(current.left)
		if current.right: 
			index +=1
			queue.append(current.right)
		packed_TLAS.append_array(current._serialize())
		if instances.size() <= MAX_INSTANCES:
			for instance in current.instances:
				packed_instances.append_array(instance._serialize())
				
func _serialize() -> PackedByteArray:
	var packed : PackedByteArray = PackedByteArray()
	packed.resize(32)
	packed.encode_float(0, (bounding_box.position.x))
	packed.encode_float(4, (bounding_box.position.y))
	packed.encode_float(8, (bounding_box.position.z))
	packed.encode_u32(12,left_first)
	packed.encode_float(16, (bounding_box.end.x))
	packed.encode_float(20, (bounding_box.end.y))
	packed.encode_float(24, (bounding_box.end.z))
	packed.encode_u32(28,instances.size())
	#left first is based on:
	#	1. instance count. if instance count is 0, it is index of left node.
	#	2. otherwise it is first instance index.
	return packed
