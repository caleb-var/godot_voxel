extends Node3D

@export var bounding_box_material: StandardMaterial3D
@export var level = 8
var depth_color = []

func visualize_TLAS(tlas : BVHNode, depth = 0) -> void:
	if depth > depth_color.size()-1: depth_color.append(Color(randf(),randf(),randf(),1.0))
	draw_aabb(tlas.bounding_box,1.0 if ((!tlas.left && !tlas.right) || depth==level)else 0.3,depth)
	if tlas.left:
		visualize_TLAS(tlas.left,depth+1)
	if tlas.right:
		visualize_TLAS(tlas.right,depth+1)

func draw_aabb(aabb:AABB, _transparency : float = 0.0, depth =0) -> void:
	# Create a box mesh that matches the AABB size
	var box_mesh := BoxMesh.new()
	# AABB 'size' is max - min
	box_mesh.size = aabb.size

	var mesh_instance := MeshInstance3D.new()
	var colour : Color = depth_color[depth]
	colour.a = _transparency
	var newmaterial = StandardMaterial3D.new()
	newmaterial.albedo_color = colour
	newmaterial.transparency = 1
	mesh_instance.material_override = newmaterial 
	mesh_instance.mesh = box_mesh
	mesh_instance.transform.origin = aabb.get_center()

	add_child(mesh_instance)
