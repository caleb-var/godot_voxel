class_name UI extends Manager

@onready var VoxelDisplay = $VoxelDisplay
@export var window_size = Vector2(1920,1080)

# Called when the node enters the scene tree for the first time.
func _ready():
	VoxelDisplay.visible = true
	_register_on_tick.call_deferred()
	_set_window_size.bind(window_size).call_deferred()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
#Called on tick from our tick manager. provides tick_delta, time since last tick.
func _on_tick(tick_delta) -> void:
	pass
	
func _set_window_size(resolution):
	window_size = resolution
	DisplayServer.window_set_size(window_size)
	VoxelDisplay.texture.size = window_size
	print("Window size: ",window_size)
	
func _update_voxel_display(image : ImageTexture) -> void:
	VoxelDisplay.texture = image
