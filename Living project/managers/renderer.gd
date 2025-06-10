class_name Renderer extends Manager

@onready var player = $".."
@onready var world = $"../../World"

@export var compute_shader: RDShaderFile

var rd : RenderingDevice
var compute_pipeline : RID
var shader : RID

var object_buffer : RID
var camera_buffer: RID

var world_view_set : RID
var object_uniform_set : RID

var output_texture : RID

var object_uniform : RDUniform
var camera_uniform : RDUniform
var output_uniform : RDUniform


var voxel_data_dirty = false
var camera_data_dirty = true

var object_meta : ObjectMeta

var camera_transform : Transform3D
var window_size = Vector2(1920,1080)

func _start():
	# Initialize rendering pipeline
	_setup_rendering_pipeline()
	_create_uniforms()
	# Create GPU resources
	_create_output_texture()


""" Setup functions! """


func _create_uniforms():
	camera_uniform = RDUniform.new()
	camera_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	camera_uniform.binding = 0
	camera_uniform.add_id(camera_buffer)
	
	object_uniform = RDUniform.new()
	object_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	object_uniform.binding = 0
	object_uniform.add_id(object_buffer)
func _create_object_buffer(object_data = PackedByteArray([])):
	object_data = player._get_object_buffer_data()
	object_meta = ObjectMeta.new()._deserialize(object_data)
	object_buffer = rd.storage_buffer_create(object_data.size(), object_data)
func _create_camera_buffer():
	var camera_data = transform_to_bytes(player.get_my_transform())
	camera_buffer = rd.storage_buffer_create(camera_data.size(), camera_data)
func _setup_rendering_pipeline():
	rd = RenderingServer.create_local_rendering_device()
	var shader_spirv: RDShaderSPIRV = compute_shader.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	compute_pipeline = rd.compute_pipeline_create(shader)
	
	_create_object_buffer()
	_create_camera_buffer()
func _create_output_texture():
	var rdt = RDTextureFormat.new()
	rdt.width = window_size.x
	rdt.height = window_size.y
	rdt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	rdt.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	rdt.usage_bits = (RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT)
	output_texture = rd.texture_create(rdt, RDTextureView.new(), [])
	output_uniform = RDUniform.new()
	output_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_uniform.binding = 1
	output_uniform.add_id(output_texture)


""" Runtime functions! """

func _process(_delta):
	_update_camera_buffer()
	_update_TLAS_bufer(world.serialize_TLAS())
	
	_dispatch_compute_shader()
	_retrieve_output_texture()
func _dispatch_compute_shader():
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, compute_pipeline)
	
	world_view_set = rd.uniform_set_create([camera_uniform,output_uniform], shader, 0)
	object_uniform_set = rd.uniform_set_create([object_uniform],shader,1)
	
	rd.compute_list_bind_uniform_set(compute_list, world_view_set,0)
	rd.compute_list_bind_uniform_set(compute_list, object_uniform_set, 1)
	
	rd.compute_list_dispatch(compute_list, window_size.x/16, window_size.y/16, 1)
	rd.compute_list_end()
	rd.submit()
	rd.sync()
func _update_camera_buffer():
	var camera_data = transform_to_bytes(player.get_my_transform())
	rd.buffer_update(camera_buffer,0,camera_data.size(),camera_data)
	

func _update_object_buffer():
	push_warning("why we updating object buffer")
	var object_data = player.get_object_data()
	object_buffer = rd.storage_buffer_create(object_data.size(), object_data)
	rd.buffer_update(object_buffer,0,object_data.size(),object_data)

func _update_TLAS_bufer(data : PackedByteArray):
	rd.buffer_update(object_buffer,object_meta.TLAS_offset + object_meta.META_SIZE,data.size(),data)

func _update_instance_transform(index: int,data : PackedByteArray):
	rd.buffer_update(object_buffer,index,data.size(),data)
	
func _retrieve_output_texture():
	var output = rd.texture_get_data(output_texture, 0)
	output = Image.create_from_data(window_size.x, window_size.y, false, Image.FORMAT_RGBA8, output)
	player._output_ready(ImageTexture.create_from_image(output))


""" Helper Functions! """


func transform_to_bytes(t : Transform3D) -> PackedByteArray:
	var basis = t.basis
	var origin = t.origin
	var bytes : PackedByteArray = PackedFloat32Array([
		basis.x.x, basis.x.y, basis.x.z, 0.0,
		basis.y.x, basis.y.y, basis.y.z, 0.0,
		basis.z.x, basis.z.y, basis.z.z, window_size.x,
		origin.x, origin.y, origin.z, window_size.y
	]).to_byte_array()
	return bytes
