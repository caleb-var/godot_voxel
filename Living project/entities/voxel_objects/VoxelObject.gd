class_name VoxelObject extends RefCounted

const MAX_MATERIALS = 256
const MATERIAL_SIZE = 32

var material_table: MaterialTable = MaterialTable.new()
var voxel_data: SVO

var object_id: int = -1

func _serialize(object_count)->Dictionary:
	var svo_packed = voxel_data._serialize(object_count,object_id)
	return {"node_data":svo_packed[0],"voxel_leaf":svo_packed[1],"material_table":material_table.material_data}
