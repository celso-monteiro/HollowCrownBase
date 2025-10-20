extends Node

signal map_updated(tex: Texture2D)
signal cell_revealed(cell: Vector2i, state: int) # 1=seen, 2=visited

# ---- Tunables (match torch/HUD tones) ----
const COLOR_BG      : Color = Color("#0d0b09")   # map backplate
const COLOR_FLOOR   : Color = Color("#E0A96D")   # visited floor (warm torch amber)
const COLOR_SEEN    : Color = Color("#C08C54")   # faint halo (dim amber)
const COLOR_PLAYER  : Color = Color("#FFF2C7")   # soft torch highlight for player
const COLOR_GRID    : Color = Color("#1a140c")   # optional subtle grid

@export var TILE_PX        := 128                     # each cell on FullMap
@export var STEP_SIZE      := 2.0                     # world step == 1 cell
@export var HALO_RADIUS    := 1                       # radius around player as "seen"
@export var SHOW_GRID      := false

# ---- Map data ----
var width  : int = 0
var height : int = 0
var origin_cell := Vector2i.ZERO   # world (0,0) cell => map coords origin
var states : PackedByteArray       # 0=unknown,1=seen,2=visited

# Rendering
var _img  : Image
var _tex  : ImageTexture
var _dirty := true
var _last_player_cell := Vector2i(-9999, -9999)

var grid_size: Vector2i:
	get:
		return Vector2i(width, height)
		
var last_player_cell: Vector2i: 
	get:
		return _last_player_cell

# ---- Player facing (simple version) ----
enum Facing { NORTH, EAST, SOUTH, WEST }

var player_facing: int = Facing.SOUTH


func _emit_updated() -> void:
	emit_signal("map_updated", get_texture())

func configure(map_width: int, map_height: int, map_origin_cell := Vector2i.ZERO) -> void:
	print("[MapService] configure call with:", map_width, "x", map_height, " origin:", map_origin_cell)
	width  = map_width
	height = map_height
	origin_cell = map_origin_cell

	_img = Image.create(width * TILE_PX, height * TILE_PX, false, Image.FORMAT_RGBA8)
	print("[MapService] img size:", _img.get_width(), "x", _img.get_height())
	_tex = ImageTexture.create_from_image(_img)
	_clear_background()
	_dirty = true
	_emit_updated()

func _clear_background() -> void:
	_img.fill(COLOR_BG)
	if SHOW_GRID:
		for x in range(width + 1):
			var px = x * TILE_PX
			for y in range(_img.get_height()):
				_img.set_pixel(px, y, COLOR_GRID)
		for y in range(height + 1):
			var py = y * TILE_PX
			for x in range(_img.get_width()):
				_img.set_pixel(x, py, COLOR_GRID)

func get_texture() -> Texture2D:
	if _dirty:
		_tex.update(_img)
		_dirty = false
	return _tex

# ---- Coordinate helpers ----
func world_to_cell(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		int(round(world_pos.x / STEP_SIZE)),
		int(round(-world_pos.z / STEP_SIZE))  # -Z forward → increase Y
	)

func cell_to_index(c: Vector2i) -> int:
	return c.x + c.y * width

func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height

# ---- Reveal logic ----
func reveal_at_world(world_pos: Vector3, also_visit := true) -> void:
	var c = world_to_cell(world_pos) - origin_cell
	if not in_bounds(c):
		return
	if also_visit:
		_mark_visited(c)
	# faint halo around player
	for dy in range(-HALO_RADIUS, HALO_RADIUS + 1):
		for dx in range(-HALO_RADIUS, HALO_RADIUS + 1):
			var n = c + Vector2i(dx, dy)
			if in_bounds(n):
				_mark_seen(n)
	_draw_player(c)
	_emit_updated()

func _mark_seen(c: Vector2i) -> void:
	var idx = cell_to_index(c)
	var cur := states[idx]
	if cur == 0:
		states[idx] = 1
		_fill_cell(c, COLOR_SEEN)
		_dirty = true
		emit_signal("cell_revealed", c, 1)

func _mark_visited(c: Vector2i) -> void:
	var idx = cell_to_index(c)
	if states[idx] != 2:
		states[idx] = 2
		_fill_cell(c, COLOR_FLOOR)
		_dirty = true
		emit_signal("cell_revealed", c, 2)

func _fill_cell(c: Vector2i, col: Color) -> void:
	var x0 = c.x * TILE_PX
	var y0 = c.y * TILE_PX
	for y in range(TILE_PX):
		for x in range(TILE_PX):
			_img.set_pixel(x0 + x, y0 + y, col)

func _draw_player(c: Vector2i) -> void:
	# redraw last visited so the previous player marker disappears
	if in_bounds(_last_player_cell) and states[cell_to_index(_last_player_cell)] == 2:
		_fill_cell(_last_player_cell, COLOR_FLOOR)
	# draw tiny cross in the center of the current tile
	var x0 = c.x * TILE_PX
	var y0 = c.y * TILE_PX
	var cx = x0 + TILE_PX / 2
	var cy = y0 + TILE_PX / 2
	for i in range(-4, 5):
		_img.set_pixel(cx + i, cy, COLOR_PLAYER)
		_img.set_pixel(cx, cy + i, COLOR_PLAYER)
	_last_player_cell = c
	_dirty = true

# ---- Optional: bulk mark known floor from your generator (so walls stay dark) ----
# Call this once after dungeon generation to prepaint only walkable cells as "unknown"
func preload_walkable(cells: PackedVector2Array) -> void:
	# Not painting here keeps unexplored dark; this exists if you need a mask later.
	pass
	
var _full_map: Control

func ensure_full_map() -> void:
	if _full_map and is_instance_valid(_full_map):
		return
	var scene := preload("res://Scenes/Maps/full_map.tscn")
	_full_map = scene.instantiate()
	get_tree().root.add_child(_full_map)
	_full_map.visible = false
	_full_map.process_mode = Node.PROCESS_MODE_ALWAYS
	
func toggle_full_map() -> void:
	# Make sure the FullMap scene exists
	ensure_full_map()

	# Get the instance we created or cached
	var fm = _full_map
	if fm == null:
		push_error("[MapService] toggle_full_map: _full_map is null!")
		return

	# Toggle visibility
	fm.visible = not fm.visible
	print("[MapService] FullMap visible:", fm.visible)

	# When showing, assign the latest texture
	if fm.visible:
		var tex := get_texture()
		print("[MapService] get_texture() returned:", tex)
		if tex == null:
			push_warning("[MapService] Texture is null, map will appear blank.")
		else:
			# make sure TextureRect exists
			if not fm.has_node("MapTexture"):
				push_warning("[MapService] FullMap has no node 'MapTexture'")
				return
			fm.map_texrect.texture = tex
			print("[MapService] Texture assigned to FullMap.")
	
func get_facing_vector() -> Vector2i:
	match player_facing:
		Facing.NORTH:
			return Vector2i(0, -1)
		Facing.SOUTH:
			return Vector2i(0, 1)
		Facing.EAST:
			return Vector2i(1, 0)
		Facing.WEST:
			return Vector2i(-1, 0)
		_:
			return Vector2i.ZERO
