extends Node

# References to child nodes (assigned in _ready)
@onready var debug : Debug = $Debug
@onready var tick_manager = $Tick
@onready var ui : UI = $UI
@onready var player : Node3D = $Player
@onready var world : World = $World
func _ready() -> void:
	# Initial debug print
	print("[Main] Initialization complete, TickManager and UI ready.")
	player.renderer._start()
	
