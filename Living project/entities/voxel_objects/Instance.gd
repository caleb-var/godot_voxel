class_name Instance extends RefCounted

const INSTANCE_SIZE = 144

var transform : Transform3D = Transform3D()
var object_ID : int = -1
var aabb : AABB = AABB()

func _to_string() -> String:
	return "Object id: %f transform: %s, aabb: %s"%[object_ID,str(transform),str(aabb)]

func _init(_object : VoxelObject, origin : Vector3, basis : Basis = Basis()):
	object_ID = _object.object_id
	transform.origin = origin
	transform.basis = basis
	aabb = AABB(_object.voxel_data.aabb)*transform.affine_inverse()
	#aabb.position = _object.voxel_data.aabb.position * transform.affine_inverse()
	#aabb.end = _object.voxel_data.aabb.end * transform.affine_inverse()
	

func _serialize() -> PackedByteArray:
	var _packed : PackedByteArray = PackedByteArray()
	var _offset = 0
	var inverse = transform.affine_inverse()
	_packed.append_array(transform_to_bytes(transform))
	_packed.append_array(transform_to_bytes(inverse))
	_offset = _packed.size()
	_packed.resize(INSTANCE_SIZE)
	_packed.encode_u32(_offset,object_ID)
	return _packed
	
func transform_to_bytes(t : Transform3D) -> PackedByteArray:
	var basis = t.basis
	var origin = t.origin
	var bytes : PackedByteArray = PackedFloat32Array([
		basis.x.x, basis.x.y, basis.x.z, 0.0,
		basis.y.x, basis.y.y, basis.y.z, 0.0,
		basis.z.x, basis.z.y, basis.z.z, 0.0,
		origin.x, origin.y, origin.z, 1.0
	]).to_byte_array()
	return bytes
