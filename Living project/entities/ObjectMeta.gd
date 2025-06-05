extends Resource
class_name ObjectMeta

# Scene buffer metadata
var TLAS_offset: int = 0
var objects_offset: int = 0
var voxel_leaf_offset : int = 0
var material_table_offset: int = 0
var instances_offset: int = 0

# --- Constants ---
const META_SIZE = 16  # Fixed size of the ObjectMeta structure (all uint32 values)
func _to_string():
	return """
				TLAS_offset:		%f
				object_offset:		%f
				voxel_leaf_offset:	%f
				material_offset:	%f
				instance_offset:	%f
	""" % [TLAS_offset,objects_offset,voxel_leaf_offset,material_table_offset,instances_offset]
"""
Encodes the ObjectMeta struct into a PackedByteArray (GPU-Friendly).
"""
func _serialize() -> PackedByteArray:
	var data = PackedByteArray()
	data.resize(META_SIZE)
	var offset = 0
	data.encode_u32(offset, TLAS_offset); offset += 4
	#data.encode_u32(offset, objects_offset); offset += 4
	data.encode_u32(offset, voxel_leaf_offset);offset += 4
	data.encode_u32(offset, material_table_offset);offset += 4
	data.encode_u32(offset, instances_offset)
	return data
func _deserialize(data: PackedByteArray) -> ObjectMeta:	
	var offset = 0
	TLAS_offset        = data.decode_u32(offset); offset += 4
	#objects_offset     = data.decode_u32(offset); offset += 4
	voxel_leaf_offset = data.decode_u32(offset); offset += 4
	material_table_offset = data.decode_u32(offset); offset += 4
	instances_offset   = data.decode_u32(offset)
	return self
