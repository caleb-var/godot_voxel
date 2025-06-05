class_name SVO

enum NodeType { BRANCH, LEAF }


const NODE_SIZE = 32   # Fixed size for branch nodes
const LEAF_SIZE = 4    # Fixed size for leaf nodes
const INSTANCE_SIZE = 144    # Fixed size for leaf nodes
const TLAS_SIZE = 48
 
var node_offset = 0
var leaf_offset = 0

var occupancy_mask: Bitboard
var node_type: int = NodeType.LEAF
var aabb: AABB
var material_id: int
var children: Array = []
var parent_node: SVO
var is_bounding_box_dirty: bool = false
var normal : Vector3 = Vector3(0,1,0)

func _init(in_node_type: int = NodeType.LEAF, in_occupancy: Bitboard = Bitboard.new(), in_aabb: AABB = AABB()):
	node_type = in_node_type
	occupancy_mask = in_occupancy
	aabb = in_aabb
	if children.size() < 64:
		children.resize(64)
func copy(copy_from: SVO = null):
	if copy_from != null:
		if copy_from.node_type==NodeType.LEAF:
			material_id = copy_from.material_id
			return
		node_type = copy_from.node_type
		occupancy_mask = Bitboard.new()
		occupancy_mask.copy_bits(copy_from.occupancy_mask)  # Copy bitmask
		aabb = AABB(copy_from.aabb.position, copy_from.aabb.size)  # Copy AABB
		is_bounding_box_dirty = copy_from.is_bounding_box_dirty

		# Copy children recursively
		children.resize(64)
			
		var child_index = occupancy_mask.first_valid_bit()
		while child_index !=-1:
			var child_node = copy_from.children[child_index]
			var new_child = SVO.new()
			new_child.copy(child_node)
			set_child_node(new_child, child_index)
			child_index = occupancy_mask.first_valid_bit(child_index + 1)
	else:
		node_type = NodeType.LEAF
		occupancy_mask = Bitboard.new()
		aabb = AABB()
		children.resize(64)

"""
Occupancy management
Since Godot 4.3 only has signed int 64 we just a 64bit bitboard and control it using the below functions.
"""

func set_occupancy_bit(child_index: int):
	if is_child_index_valid(child_index):
		occupancy_mask.set_bit(child_index)
func is_occupancy_bit_set(child_index: int) -> bool:
	return occupancy_mask.is_bit_set(child_index)


"""
Child management 
"""

func add_leaf_child(child_index: int, material_ID: int):
	if not is_child_index_valid(child_index):
		return

	var new_leaf = SVO.new()
	new_leaf.node_type = NodeType.LEAF
	new_leaf.material_id = material_ID
	children[child_index] = new_leaf
	
	if not is_occupancy_bit_set(child_index):
		set_occupancy_bit(child_index)


	is_bounding_box_dirty = true
func set_child_node(child_node: SVO, child_index: int):
	if not is_child_index_valid(child_index):
		return
	set_occupancy_bit(child_index)
	children[child_index] = child_node
	is_bounding_box_dirty = true
func remove_children(child_indices: Array):
	var removed_something = false
	var affected_neighbors = []  # Track neighbors to update

	# First, collect affected neighbors before deleting anything
	for idx in child_indices:
		if idx >= 0 and idx < 64 and children[idx] != null:
			# Find all valid neighbors of this voxel
			var neighbors = [
				idx - 1, idx + 1,
				idx - 4, idx + 4,
				idx - 16, idx + 16
			]

			# Only keep neighbors that are NOT being deleted
			for neighbor in neighbors:
				if is_child_index_valid(neighbor) and !child_indices.has(neighbor):
					affected_neighbors.append(neighbor)

	# Now, remove the requested voxels
	for idx in child_indices:
		if idx >= 0 and idx < 64:
			if children[idx] != null:
				children[idx] = null
				occupancy_mask.clear_bit(idx)
				removed_something = true

	# Update normals **only for remaining voxels** that had neighbors removed
	if removed_something:
		for neighbor_idx in affected_neighbors:
			pass
			#set_voxel_normal(neighbor_idx)
		
		is_bounding_box_dirty = true
func get_child_node(child_index: int):
	if is_occupancy_bit_set(child_index):
		return children[child_index]
	return null


"""
Shapes functions. 
"""

"""
AABB functions. 
"""

func create_branch_aabb() -> void:
	# AABB pos and size is [0-4]
	if occupancy_mask.first_valid_bit() == -1:
		print("died")
		return
	var min_pos = Vector3(INF, INF, INF)
	var max_pos = Vector3(-INF, -INF, -INF)
	var child_index = occupancy_mask.first_valid_bit()
	while child_index !=-1:
		var child_local_pos = index_to_position(child_index)
		var child_node = children[child_index]
		if child_node.node_type != NodeType.LEAF:
			if child_node.is_bounding_box_dirty:
				child_node.update_aabb("force")
			min_pos = min_pos.min(child_local_pos + (child_node.aabb.position /4.))
			max_pos = max_pos.max(child_local_pos + (child_node.aabb.end/4.))
		else:
			min_pos = min_pos.min(child_local_pos)
			max_pos = max_pos.max(child_local_pos + Vector3(1, 1, 1))
		child_index = occupancy_mask.first_valid_bit(child_index + 1)
	aabb = AABB(min_pos,max_pos-min_pos)
func update_aabb(mode: String = "auto") -> void:
	match mode:
		"force":
			if node_type == NodeType.LEAF:
				push_warning("called on a leaf node?")
				return
			create_branch_aabb()
			is_bounding_box_dirty = false
			mark_parent_dirty(false)
		"auto":
			if is_bounding_box_dirty:
				if node_type == NodeType.LEAF:
					push_warning("called on a leaf node?")
					return
				create_branch_aabb()
				is_bounding_box_dirty = false
				mark_parent_dirty()
		"mark_dirty":
			is_bounding_box_dirty = true
			mark_parent_dirty()
func mark_parent_dirty(force: bool = false) -> void:
	if parent_node:
		if force:
			parent_node.update_aabb("force")
			return
		parent_node.update_aabb("mark_dirty")

"""
Helper functions! Positional, debug and string/
"""
func is_child_index_valid(child_index: int) -> bool:
	if child_index < 0 or child_index >= 64:
		push_warning("Child index out of bounds: %d" % child_index)
		return false
	return true
func position_to_index(offset: Vector3) -> int:
	return int(offset.x) + int(offset.y) * 4 + int(offset.z) * 16
func index_to_position(idx: int) -> Vector3:
	var x = idx % 4
	var y = (idx / 4) % 4
	var z = idx / 16
	return Vector3(x, y, z)
func get_binary_string(m : Bitboard = occupancy_mask) -> String:
	var binary_str = ""

	for i in range(64):
		if m.is_bit_set(i):
			binary_str += str(1)
		else:
			binary_str += str(0)
	return binary_str
func print_node_info():
	print("Node Type:", node_type)
	print("Occupancy Mask:", occupancy_mask)
	print("Occupancy Mask Binary:", get_binary_string())
	print("AABB:", aabb)
	print("Material ID:", material_id)
	print("Is Bounding Box Dirty:", is_bounding_box_dirty)
	print("Number of Children:", children.size())
func _to_string() -> String:
	return "NodeType:%s | Occupancy:%s | AABB:%s" % [
		str(NodeType.keys()[node_type]),
		get_binary_string(),
		str(aabb)
	]

"""
Serializes an entire SVO tree into a PackedByteArray.
Returns: { data: PackedByteArray, object_meta: ObjectMeta }
"""
func _serialize(object_count,object_id) -> Array:
	update_aabb("force")
	var node_data = PackedByteArray()
	var leaf_data = PackedByteArray()
	_serialize_node(self, node_data, leaf_data, object_count * 8 + object_id * 8)
	return [node_data,leaf_data]

func _pack_branch(node: SVO, node_data: PackedByteArray, object_offset : int = 0):
	#print("node aabb debug: ", node.aabb.size)
	var temp_data = PackedByteArray()
	var index = 0;
	temp_data.resize(12)
	# [0-3]  4 bytes  - flags, bit 0 = [0=branch,1=leaf]
	temp_data.encode_u32(index,node.node_type)
	# [4-7]  4 bytes  - child node offset global
	if object_offset == 0:
		temp_data.encode_u32(index + 4, node_data.size())
	else:
		temp_data.encode_u32(index + 4, object_offset)
	# [8-11]  4 bytes  - child leaf offset global
	temp_data.encode_u32(index + 8, leaf_offset)
	# [12-19]  8 bytes  - 64 bit occupancy
	temp_data.append_array(node.occupancy_mask.data)
	# [20-31]  12 bytes - AABB (16-bit min/size)
	temp_data.resize(temp_data.size()+12)
	temp_data.encode_u16(index + 20, int((node.aabb.position.x/4.0)*32767) & 0xFFFF)
	temp_data.encode_u16(index + 22, int((node.aabb.position.y/4.0)*32767) & 0xFFFF)
	temp_data.encode_u16(index + 24, int((node.aabb.position.z/4.0)*32767) & 0xFFFF)
	temp_data.encode_u16(index + 26, int((node.aabb.end.x/4.0)*32767) & 0xFFFF)
	temp_data.encode_u16(index + 28, int((node.aabb.end.y/4.0)*32767) & 0xFFFF)
	temp_data.encode_u16(index + 30, int((node.aabb.end.z/4.0)*32767) & 0xFFFF)
	node_data.append_array(temp_data)

func _pack_leaf(node: SVO, leaf_data : PackedByteArray):
	leaf_data.push_back(node.material_id & 0xF)
	leaf_data.append_array(encode_normal(Vector3(0,1,0)))

func _serialize_node(node: SVO, 
		node_data: PackedByteArray, 
		leaf_data: PackedByteArray,
		object_offset : int = 0) -> void:
	if node.node_type == SVO.NodeType.LEAF:
		_pack_leaf(node,leaf_data)
	else:
		_pack_branch(node,node_data,object_offset)

	# Recursively serialize children
	var child_index = node.occupancy_mask.first_valid_bit()
	while child_index != -1:
		_serialize_node(node.children[child_index], node_data, leaf_data)
		child_index = node.occupancy_mask.first_valid_bit(child_index + 1)

# Given a normalized Vector3, encode each component into 8 bits.
func encode_normal(_normal: Vector3) -> PackedByteArray:
	var n = _normal.normalized()  # ensure the vector is unit length
	# Map each component from [-1,1] to [0,255]
	var bx = int(clamp(round((n.x * 0.5 + 0.5) * 255.0), 0, 255))
	var by = int(clamp(round((n.y * 0.5 + 0.5) * 255.0), 0, 255))
	var bz = int(clamp(round((n.z * 0.5 + 0.5) * 255.0), 0, 255))
	
	var bytes = PackedByteArray()
	bytes.append(bx)
	bytes.append(by)
	bytes.append(bz)
	return bytes
