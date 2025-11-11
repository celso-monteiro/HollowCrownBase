extends Node

const SAVE_PATH := "user://save_0.json"

func save_game() -> void:
	var player_data := _capture_player()
	var scene_path := get_tree().current_scene.scene_file_path

	var data := {
		"timestamp": Time.get_unix_time_from_system(),
		"scene": scene_path,
		"player": player_data
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[Save] Could not open file for write.")
		return

	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	print("[Save] Saved player position:", player_data["pos"])
	print("[Save] Scene:", scene_path)

# ------------------------------------------------------------------------------

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		push_warning("[Load] No save file found.")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("[Load] Could not open file for read.")
		return

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[Load] Invalid JSON format.")
		return

	# Unpause just in case
	get_tree().paused = false

	# Load the saved scene if different
	var target_scene := String(parsed.get("scene", ""))
	if target_scene != "" and _current_scene_path() != target_scene:
		var err := get_tree().change_scene_to_file(target_scene)
		if err != OK:
			push_error("[Load] Could not change to %s" % target_scene)
			return
		# Wait a frame to ensure the scene is ready before applying state
		await get_tree().process_frame

	# Apply the player's position and rotation
	_apply_player_state(parsed.get("player", {}))

	print("[Load] Loaded player position:", parsed.get("player", {}).get("pos"))

# ------------------------------------------------------------------------------

func _capture_player() -> Dictionary:
	var result := {}
	var players := get_tree().get_nodes_in_group("player")

	# Find the actual Player (CharacterBody3D or has Player.gd script)
	var p: Node = null
	for n in players:
		if n is CharacterBody3D or n.has_method("get_input_direction"):
			p = n
			break

	if p == null:
		push_warning("[Save] No valid player found; using default position.")
		result = {"pos": [0,0,0], "rotation_y": 0.0}
	else:
		var pos = p.global_position
		result = {
			"pos": [pos.x, pos.y, pos.z],
			"rotation_y": p.global_rotation.y
		}
	return result

# ------------------------------------------------------------------------------

func _apply_player_state(p_data: Dictionary) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		push_warning("[Load] No player found in scene.")
		return

	var p := players[0]

	if p_data.has("pos"):
		var a = p_data["pos"]
		if typeof(a) == TYPE_ARRAY and a.size() == 3:
			p.global_position = Vector3(a[0], a[1], a[2])

	if p_data.has("rotation_y"):
		var rot = p.global_rotation
		rot.y = float(p_data["rotation_y"])
		p.global_rotation = rot

# ------------------------------------------------------------------------------

func _current_scene_path() -> String:
	var cs: Node = get_tree().current_scene
	if cs and cs.has_method("get_scene_file_path"):
		return cs.scene_file_path
	return ""
