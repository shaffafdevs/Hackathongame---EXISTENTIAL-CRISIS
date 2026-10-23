extends Node

enum Mode { DELETE, FREEZE, GRAVITY }
var current_mode: Mode = Mode.DELETE

var time_elapsed: float = 0.0
var timer_running: bool = true
var fragments_collected: int = 0

func _process(delta: float) -> void:
	if timer_running:
		time_elapsed += delta

	if Input.is_action_just_pressed("mode_delete"):
		current_mode = Mode.DELETE
	elif Input.is_action_just_pressed("mode_freeze"):
		current_mode = Mode.FREEZE
	elif Input.is_action_just_pressed("mode_gravity"):
		current_mode = Mode.GRAVITY
	elif Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

func get_formatted_time() -> String:
	var mins = int(time_elapsed) / 60
	var secs = int(time_elapsed) % 60
	var ms = int((time_elapsed - int(time_elapsed)) * 100)
	return "%02d:%02d.%02d" % [mins, secs, ms]
