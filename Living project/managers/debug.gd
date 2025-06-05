class_name Debug extends Manager

var _messages := []                # Stores log entries
var _mutex := Mutex.new()          # Thread safety

@onready var _stats : VBoxContainer = $TabContainer/stats
var _timed_stats : Dictionary = {}
var _pushed_stats : Dictionary = {}

func _on_tick(delta):
	process_stats()
	
func _ready():
	_register_on_tick.call_deferred()

func add_debug_message(module_name: String, message: String,level: String = "INFO") -> void:
	_mutex.lock()
	_messages.append({
		"timestamp": Time.get_ticks_msec(),
		"module": module_name,
		"level": level,
		"message": message
	})
	_mutex.unlock()

func fetch_messages() -> Array:
	_mutex.lock()
	var msgs = _messages.duplicate()   # Copy
	_messages.clear()                  # Clear main list
	_mutex.unlock()
	return msgs

func process_stats():
	for stat in _timed_stats:
		stat = _timed_stats[stat]
		stat.tick_counter += 1
		if stat["tick_counter"] >= stat["interval"]:
			stat["tick_counter"] = 0
			stat["value"] = stat["callable"].call()
			var holder = _stats.get_node(stat["stat_name"])
			holder.get_child(1).text = stat["value"]

func update_stat(stat_name : String, value : String) -> bool:
	var holder = _stats.find_child(stat_name)
	holder.get_child(1).text = value
	return true

func add_stat(stat_name : String,
		caller : String,
		value : String,
		callable : Callable,
		interval : int = 0) -> bool:
	if _timed_stats.has(stat_name)  || _pushed_stats.has(stat_name): return false
	if callable.is_null():
		_pushed_stats[stat_name] = {"stat_name" = stat_name,
				"caller" = caller,
				"value" = value}
	else:
		_timed_stats[stat_name] = {"stat_name" = stat_name,
				"caller" = caller,
				"value" = value,
				"interval" = interval,
				"tick_counter" = 0,
				"callable" = callable}
	var column : HBoxContainer = HBoxContainer.new()
	column.name = stat_name
	_stats.add_child(column)
	var _name_label = Label.new()
	_name_label.text=stat_name
	column.add_child(_name_label)
	var _stat_label = Label.new()
	_stat_label.text = value
	_stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stat_label.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	column.add_child(_stat_label)
	return true


func on_stats_toggle(toggled_on):
	_stats.visible = not _stats.visible
