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
	print("[Save] Saved player position:", player_data["pos"])
	
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		push_warning("[Load] No save file found.")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("[Load] Could not open save file for read")
		return

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[Load] Invalid save file format")
		return

	# Restore player data
	var p_data = parsed.get("player", {})
	_apply_player_state(p_data)
	print("[Load] Loaded player position:", p_data.get("pos"))

func _apply_player_state(p_data: Dictionary) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		push_warning("[Load] No player found to restore.")
		return

	var p = players[0]

	if p_data.has("pos"):
		var a = p_data["pos"]
		if typeof(a) == TYPE_ARRAY and a.size() == 3:
			p.global_position = Vector3(a[0], a[1], a[2])

	if p_data.has("rot_y"):
		var rot = p.global_rotation
		rot.y = float(p_data["rot_y"])
		p.global_rotation = rot

func _capture_player() -> Dictionary:
	var result := {}

	# Try to locate player by group (recommended)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		result["pos"] = p.global_position
		result["rotation_y"] = p.global_rotation.y
	else:
		push_warning("[Save] No player found in scene.")
		result["pos"] = Vector3.ZERO
		result["rotation_y"] = 0.0

	return result
