extends Control

@export var cell_px := 6
@export var show_player := true
@onready var map_texrect: TextureRect = $MapImage

var img := Image.create(1,1,false,Image.FORMAT_RGBA8)
var tex := ImageTexture.create_from_image(img)

func _ready() -> void:
	visible = false
	print("[FullMap] ready; MapService W×H:", MapService.width, "x", MapService.height)
	MapService.map_updated.connect(_redraw)
	
func open_map() -> void:
	visible = true
	_redraw()

func close_map() -> void:
	visible = false

func _unhandled_input(e: InputEvent) -> void:
	if not visible: return
	if e.is_action_pressed("map"): #or e.is_action_pressed("ui_cancel"):
		close_map()


func _redraw(_tex: Texture2D = null) -> void:
	if MapService.width <= 0 or MapService.height <= 0:
		print("[FullMap] redraw skipped: map not configured yet.")
		return
	# ...continue only when sizes are valid...
	var gs: Vector2i = MapService.grid_size
	var px := cell_px
	img = Image.create(gs.x * px, gs.y * px, false, Image.FORMAT_RGBA8)

	for y in gs.y:
		for x in gs.x:
			var c := Vector2i(x,y)
			var t = MapService.get_cell(c)
			var col: Color			
			match t:
				MapService.CELL_FLOOR:
					col = MapService.COL_FLOOR
				MapService.CELL_SEEN:
					col = MapService.COL_SEEN
				MapService.CELL_DOOR:
					col = MapService.COL_DOOR
				_:
					col = MapService.COL_FOG
			for yy in px:
				for xx in px:
					img.set_pixel(x*px+xx, y*px+yy, col)
	if show_player:
		var p = MapService.last_player_cell * px + Vector2i(px/2, px/2)
		var dir := MapService.get_facing_vector()
		var tip = p + dir * (px / 2)
		_draw_disc(p, 2, Color(1,0.9,0.2,1))
		_draw_line(p, tip, Color(1,0.3,0.1,1))
	tex.update(img)
	map_texrect.texture = tex

func _draw_disc(center: Vector2i, r: int, col: Color) -> void:
	var gs: Vector2i = MapService.grid_size
	for y in gs.y:
		for x in gs.x:
			if x*x + y*y <= r*r:
				var pt := center + Vector2i(x,y)
				if pt.x >= 0 and pt.y >= 0 and pt.x < img.get_width() and pt.y < img.get_height():
					img.set_pixelv(pt, col)

func _draw_line(a: Vector2i, b: Vector2i, col: Color) -> void:
	var d := b - a
	var steps = max(abs(d.x), abs(d.y))
	if steps == 0: return
	for i in steps+1:
		var t := float(i)/float(steps)
		var p := Vector2i(round(a.x + d.x*t), round(a.y + d.y*t))
		if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
			img.set_pixelv(p, col)
