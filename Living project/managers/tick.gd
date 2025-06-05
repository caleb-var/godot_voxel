class_name Tick extends Manager

signal tick(delta)

var target_tps: int = 30
var accumulated_time: float = 0.0
var tick_count: int = 0  # Keep track of total ticks

func _ready():
	_register_debug_stat.bindv(["Ticks per second (TPS)",str(target_tps)]).call_deferred()

func _physics_process(delta: float) -> void:
	accumulated_time += delta
	var interval = 1.0 / target_tps
	while accumulated_time >= interval:
		accumulated_time -= interval
		tick_count += 1
		emit_signal("tick", interval)
		
