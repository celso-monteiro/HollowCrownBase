@tool
extends Node
# NOTE: Do NOT add `class_name` here—this script is an Autoload named "MapService".

# ---------------- Signals ----------------
signal map_updated(tex: Texture2D)
signal cell_revealed(cell: Vector2i, state: int) # 1=seen, 2=visited

# ---------------- Tunables / Colors (match your HUD torch tones as needed) ----------------
const COLOR_BG     : Color = Color("#0d0b09") # map backdrop (fog)
const COLOR_FLOOR  : Color = Color("#E0A96D") # visited floor
const COLOR_SEEN   : Color = Color("#C08C54") # faint halo (seen)
const COLOR_PLAYER : Color = Color("#FFF2C7") # small cross marker
const COLOR_GRID   : Color = Color("#1a140c") # optional subtle grid lines

@export var TILE_PX    : int   = 128  # pixels per map cell in the texture
@export var STEP_SIZE  : float = 2.0  # world step size equals 1 map cell
@export var HALO_RADIUS: int   = 1    # halo radius in cells
@export var SHOW_GRID  : bool  = false

# ---------------- Cell states ----------------
const CELL_UNKNOWN := 0
const CELL_SEEN    := 1
const CELL_FLOOR   := 2
const CELL_DOOR    := 3  # optional: if you tag doors later

# Color aliases for external code that wants colors
const COL_FOG   := COLOR_BG
const COL_SEEN  := COLOR_SEEN
const COL_FLOOR := COLOR_FLOOR
const COL_DOOR  := COLOR_FLOOR

# ---------------- Map data ----------------
var width  : int = 0
var height : int = 0
var origin_cell : Vector2i = Vector2i.ZERO       # world (0,0) mapped into texture indices
var states : PackedByteArray                     # width*height bytes: 0,1,2,...

# Expose combined size for convenience
var grid_size: Vector2i:
	get: return Vector2i(width, height)

# ---------------- Rendering backing store ----------------
var _img  : Image
var _tex  : ImageTexture
var _dirty: bool = true

# Player marker + facing
var _last_player_cell: Vector2i = Vector2i(-9999, -9999)

enum Facing { NORTH, EAST, SOUTH, WEST }
var player_facing: int = Facing.SOUTH

# ---------------- Full Map overlay (CanvasLayer) ----------------
var _full_map: CanvasLayer

# =================================================================
# Public API
# =================================================================


func configure(map_width: int, map_height: int, map_origin_cell: Vector2i = Vector2i.ZERO) -> void:
	# Initialize map dimensions and backing image/texture
	width       = map_width
	height      = map_height
	origin_cell = map_origin_cell

	# Build image and texture
	_img = Image.create(width * TILE_PX, height * TILE_PX, false, Image.FORMAT_RGBA8)
	_tex = ImageTexture.create_from_image(_img)

	_clear_background()
	_dirty = true
	_emit_updated()

func get_texture() -> Texture2D:
	# Safe getter: returns null if not configured yet
	if _tex == null:
		if _img == null:
			return null
		_tex = ImageTexture.create_from_image(_img)
		_dirty = false
		return _tex

	if _dirty:
		_tex.update(_img)
		_dirty = false
	return _tex

func world_to_cell(world_pos: Vector3) -> Vector2i:
	# X to the right; -Z forward maps to +Y on the texture
	return Vector2i(
		int(round(world_pos.x / STEP_SIZE)),
		int(round(world_pos.z / STEP_SIZE))
	)

func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height

func get_cell(c: Vector2i) -> int:
	# Expects c in world-grid coordinates; convert to map indices
	var mc := c - origin_cell
	if not in_bounds(mc):
		return CELL_UNKNOWN
	return int(states[cell_to_index(mc)])

func player_cell() -> Vector2i:
	return _last_player_cell

func get_facing_vector() -> Vector2i:
	match player_facing:
		Facing.NORTH: return Vector2i(0, -1)
		Facing.SOUTH: return Vector2i(0, 1)
		Facing.EAST:  return Vector2i(1, 0)
		Facing.WEST:  return Vector2i(-1, 0)
		_:            return Vector2i.ZERO

# Reveal current world pos; also_visit=true paints the center tile as visited
func reveal_at_world(world_pos: Vector3, also_visit: bool = true) -> void:
	if width <= 0 or height <= 0:
		return
	var c := world_to_cell(world_pos) - origin_cell
	if not in_bounds(c):
		return

	if also_visit:
		_mark_visited(c)

	# Faint halo
	for dy in range(-HALO_RADIUS, HALO_RADIUS + 1):
		for dx in range(-HALO_RADIUS, HALO_RADIUS + 1):
			var n := c + Vector2i(dx, dy)
			if in_bounds(n):
				_mark_seen(n)

	_draw_player(c)
	_emit_updated()

# Optional: bulk-known floor mask from generator (not needed yet)
func preload_walkable(_cells: PackedVector2Array) -> void:
	pass

# =================================================================
# FullMap scene management (CanvasLayer overlay)
# =================================================================

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
	if _full_map.visible:
		_full_map.call_deferred("refresh_texture")

# =================================================================
# Internals
# =================================================================

func _clear_background() -> void:
	if _img == null:
		return

	_img.fill(COLOR_BG)

	if SHOW_GRID:
		# Vertical grid lines
		for x in range(width + 1):
			var px := x * TILE_PX
			for y in range(_img.get_height()):
				_img.set_pixel(px, y, COLOR_GRID)
		# Horizontal grid lines
		for y in range(height + 1):
			var py := y * TILE_PX
			for x in range(_img.get_width()):
				_img.set_pixel(x, py, COLOR_GRID)

	# Allocate/reset states
	var size := width * height
	states = PackedByteArray()
	states.resize(size) # defaults to 0

	_dirty = true

func cell_to_index(c: Vector2i) -> int:
	return c.x + c.y * width

func _mark_seen(c: Vector2i) -> void:
	var idx := cell_to_index(c)
	if states[idx] == CELL_UNKNOWN:
		states[idx] = CELL_SEEN
		_fill_cell(c, COLOR_SEEN)
		_dirty = true
		emit_signal("cell_revealed", c, CELL_SEEN)

func _mark_visited(c: Vector2i) -> void:
	var idx := cell_to_index(c)
	if states[idx] != CELL_FLOOR:
		states[idx] = CELL_FLOOR
		_fill_cell(c, COLOR_FLOOR)
		_dirty = true
		emit_signal("cell_revealed", c, CELL_FLOOR)

func _fill_cell(c: Vector2i, col: Color) -> void:
	if _img == null:
		return
	var x0 := c.x * TILE_PX
	var y0 := c.y * TILE_PX
	for y in range(TILE_PX):
		for x in range(TILE_PX):
			_img.set_pixel(x0 + x, y0 + y, col)

func _draw_player(c: Vector2i) -> void:
	# Erase last player marker (if the cell is visited)
	if in_bounds(_last_player_cell) and states[cell_to_index(_last_player_cell)] == CELL_FLOOR:
		_fill_cell(_last_player_cell, COLOR_FLOOR)

	# Draw a tiny cross at center of current tile
	var x0 := c.x * TILE_PX
	var y0 := c.y * TILE_PX
	var cx := x0 + TILE_PX / 2
	var cy := y0 + TILE_PX / 2
	for i in range(-4, 5):
		_img.set_pixel(cx + i, cy, COLOR_PLAYER)
		_img.set_pixel(cx, cy + i, COLOR_PLAYER)

	_last_player_cell = c
	_dirty = true

func _emit_updated() -> void:
	var tex := get_texture()
	if tex:
		emit_signal("map_updated", tex)
