# SaveService.gd
extends Node

const SAVE_PATH := "user://save_0.json"

func save_game() -> void:
	var player_data = _capture_player()
	var scene = get_tree().current_scene.scene_file_path

	var data := {
		"timestamp": Time.get_unix_time_from_system(),
		"scene": scene,
		"player": player_data
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[Save] Could not open file for writing")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("[Save] Saved player position:", player_data["position"])

func _capture_player() -> Dictionary:
	var result := {}

	# Try to locate player by group (recommended)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		result["position"] = p.global_position
		result["rotation_y"] = p.global_rotation.y
	else:
		push_warning("[Save] No player found in scene.")
		result["position"] = Vector3.ZERO
		result["rotation_y"] = 0.0

	return result
