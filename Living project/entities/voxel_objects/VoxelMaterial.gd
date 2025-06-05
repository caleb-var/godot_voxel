class_name VoxelMaterial

var material_ID: int = 0
var albedo: Color = Color(1, 1, 1, 1)  # Stored as vec4 in GLSL
var roughness: float = 1.0
var metallic: float = 0.0
const MATERIAL_SIZE = 32

func to_bytes() -> PackedByteArray:
	var buffer = PackedByteArray()
	buffer.resize(MATERIAL_SIZE)

	buffer.encode_u32(0, material_ID)  # Material ID (4 bytes)
	buffer.encode_float(4, albedo.r)   # Albedo (vec4)
	buffer.encode_float(8, albedo.g)
	buffer.encode_float(12, albedo.b)
	buffer.encode_float(16, albedo.a)
	buffer.encode_float(20, roughness) # Roughness (float)
	buffer.encode_float(24, metallic)  # Metallic (float)
	buffer.encode_float(28, 0.0)       # Padding (for 32-byte alignment)

	return buffer
