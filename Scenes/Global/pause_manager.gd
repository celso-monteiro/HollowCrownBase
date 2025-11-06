# res://Globals/PauseManager.gd  (set as Autoload)
extends Node
signal pause_changed(paused: bool)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func toggle() -> void:
	get_tree().paused = not get_tree().paused
	emit_signal("pause_changed", get_tree().paused)

func pause() -> void:
	if not get_tree().paused:
		get_tree().paused = true
		emit_signal("pause_changed", true)

func resume() -> void:
	if get_tree().paused:
		get_tree().paused = false
		emit_signal("pause_changed", false)

func _unhandled_input(event: InputEvent) -> void:
	# "pause" mapped to P (or whatever)
	if event.is_action_pressed("pause"):
		toggle()
