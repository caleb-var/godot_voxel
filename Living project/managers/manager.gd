class_name Manager extends Node

func _register_debug_stat(stat_name : String,
		value : String,
		callable : Callable = Callable(),
		interval : int = int()) -> void:
	var debug = get_parent().debug
	debug.add_stat(stat_name,name,value,callable,interval)

func _register_on_tick():
	var tick_manager : Tick = get_parent().tick_manager
	tick_manager.tick.connect(_on_tick)

func _on_tick(delta_tile):
	pass

func _register_to_function():
	pass
