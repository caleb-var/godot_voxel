class_name MaterialTable

var lookup_table: Array = []  # Array of material IDs (index → material_id)
var material_data: PackedByteArray

const MAX_MATERIALS = 256
const MATERIAL_SIZE = 32

func _init():
	material_data.resize(MAX_MATERIALS)
	material_data.fill(0)

func add_material(voxel_material : VoxelMaterial) -> int:
	var material_ID = voxel_material.material_ID
	
	if lookup_table.has(material_ID):
		return lookup_table.find(material_ID)

	var index = lookup_table.size()
	voxel_material.material_ID = index
	# Find a free slot
	lookup_table.append(material_ID)
	material_data.encode_var(index*MATERIAL_SIZE,voxel_material.to_bytes())
	return index
func remove_material(material_id: int) -> void:
	var index : int = -1
	if lookup_table.has(material_id):
		index = lookup_table.find(material_id)
		lookup_table.pop_at(index)
		material_data = material_data.slice(0,index) + material_data.slice(index+1)
	material_data.resize(MAX_MATERIALS)

## Get the material index for a given material ID
func get_material(material_id: int) -> VoxelMaterial:
	var index = lookup_table.find(material_id)
	if index==-1:return VoxelMaterial.new()
	return material_data.decode_var(index*MATERIAL_SIZE) as VoxelMaterial

func has_material(material_id: int) -> bool:
	return lookup_table.has(material_id)
