extends Node

const NODE_BYTES := 32        # TinyBVH node size
const F32 : PackedFloat32Array = []

func _ready():
	# ------------------------------------------------------------------
	# 1. Build a tiny TLAS
	# ------------------------------------------------------------------
	var tlas := BVHTLAS.new()
	
	tlas.add_aabb(Vector3(-1, -1, -1), Vector3( 1,  1,  1))    # id 0
	tlas.add_aabb(Vector3( 3,  0,  0), Vector3( 4,  1,  1))    # id 1
	tlas.add_aabb(Vector3( 0,  3,  0), Vector3( 1,  4,  1))    # id 2
	tlas.add_aabb(Vector3(-4, -1,  0), Vector3(-3,  1,  2))    # id 3
	
	tlas.build()
	print("Built TLAS with ", tlas.get_node_count(), " nodes")

	# ------------------------------------------------------------------
	# 2. Fetch the GPU-ready buffer (no extra copies)
	# ------------------------------------------------------------------
	var raw : PackedByteArray = tlas.to_gpu_bvh()

	# ------------------------------------------------------------------
	# 3. Decode and pretty-print each node
	# ------------------------------------------------------------------
	var node_count := raw.size() / NODE_BYTES
	var r := StreamPeerBuffer.new()
	r.data_array = raw             # attach buffer for typed reads
	r.big_endian = false           # TinyBVH writes little-endian

	print("\nIdx |      Min (x y z)      |      Max (x y z)      | leftFirst | triCount")
	print("----+---------------------------+---------------------------+-----------+---------")
	for i in node_count:
		var base := i * NODE_BYTES
		r.seek(base)
		var min_x := r.get_float()        # 0-3
		var min_y := r.get_float()        # 4-7
		var min_z := r.get_float()        # 8-11
		var left  := r.get_u32()          # 12-15
		var max_x := r.get_float()        # 16-19
		var max_y := r.get_float()        # 20-23
		var max_z := r.get_float()        # 24-27
		var tris  := r.get_u32()          # 28-31

		print("%3d | %6.2f %6.2f %6.2f | %6.2f %6.2f %6.2f | %9d | %8d"
			  % [i, min_x, min_y, min_z, max_x, max_y, max_z, left, tris])
