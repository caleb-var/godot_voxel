extends Node

var bvh : BVHTLAS = BVHTLAS.new()

func _init():
	bvh.add_aabb(Vector3(0,0,0),Vector3(1,1,1))
	bvh.add_aabb(Vector3(10,10,10),Vector3(11,11,11))

	bvh.build()
	print("Built BVH with node count:", bvh.get_node_count())
