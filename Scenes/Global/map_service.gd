# map_service.gd (relevant parts)
var _full_map: CanvasLayer

func ensure_full_map() -> void:
	if _full_map and is_instance_valid(_full_map):
		return
	var scene := preload("res://Scenes/Maps/full_map.tscn")
	_full_map = scene.instantiate() as CanvasLayer
	_full_map.layer = 100
	_full_map.visible = false
	_full_map.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_full_map)

func toggle_full_map() -> void:
	ensure_full_map()
	_full_map.visible = not _full_map.visible
	print("[MapService] FullMap visible:", _full_map.visible)
	if _full_map.visible:
		_full_map.call_deferred("refresh_texture")
