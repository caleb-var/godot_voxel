extends Node3D

@onready var camera = $Camera3D
@onready var renderer = $Renderer
@onready var world = $"../World"
@onready var debug = $"../Debug"
@onready var ui = $"../UI"

@export_category("Control settings")
@export var vertical_limit: float = 89.0  # Limit vertical rotation to avoid flipping
@export var move_speed: float = 200.0
@export var mouse_sensitivity: float = 0.2

var mouse_enabled: bool = true
var previous_mouse_position: Vector2 = Vector2.ZERO
var rotation_x: float = 0.0  # Rotation around the X-axis (vertical)
var rotation_y: float = 0.0  # Rotation around the Y-axis (horizontal)


func _ready() -> void:
	_register_debug_stat()
	# Lock the mouse at the start
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta: float) -> void:
	handle_movement(delta)
	
	if Input.is_action_just_pressed("ui_cancel"):
		mouse_enabled = not mouse_enabled
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if mouse_enabled else Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_enabled:
		# Update rotation based on mouse movement
		rotation_y -= event.relative.x * mouse_sensitivity
		rotation_x -= event.relative.y * mouse_sensitivity
		# Clamp vertical rotation to avoid flipping
		rotation_x = clamp(rotation_x, -vertical_limit, vertical_limit)
		# Apply the new rotation to the transform
		camera.rotation_degrees = Vector3(rotation_x,rotation_y,0.0)
		
func handle_movement(delta: float) -> void:
	# Directional movement
	var direction = Vector3.ZERO
	if Input.is_action_pressed("ui_up"):  # W
		direction.z -= 1
	if Input.is_action_pressed("ui_down"):  # S
		direction.z += 1
	if Input.is_action_pressed("ui_left"):  # A
		direction.x -= 1
	if Input.is_action_pressed("ui_right"):  # D
		direction.x += 1
	if Input.is_action_pressed("ui_accept"):  # Space
		direction.y += 1
	if Input.is_action_pressed("control_down"):  # Ctrl
		direction.y -= 1
	# Normalize and apply movement
	direction = direction.rotated(Vector3(0,1,0),deg_to_rad(rotation_y))
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		translate(direction * move_speed * delta)



################################### HELPER FUNCTIONS ##########################################
 
func _output_ready(image_texture : ImageTexture):
	ui._update_voxel_display(image_texture)
	
func _get_object_buffer_data() -> PackedByteArray:
	return world.create_test()
	
func _string_position() -> String:
	var temp_transform : Transform3D = get_my_transform()
	return "%v" % temp_transform.origin

func get_my_transform() -> Transform3D:
	if camera == null:return self.global_transform
	return camera.global_transform
func get_fps()->String:
	return "%f" % Engine.get_frames_per_second()

func _register_debug_stat() -> void:
	debug.add_stat("FPS",name,"",get_fps,5)
	debug.add_stat("Position",name,_string_position(),_string_position,10)
