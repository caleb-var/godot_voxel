extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_tick(delta):
	transform.basis = transform.basis.rotated(Vector3.RIGHT,0.1*delta)

	pass # Replace with function body.
