extends Control

@export var cell_px := 6              # map cell size when rendering the full map
@export var show_player := true       # toggle player arrow on map
@onready var map_texrect: TextureRect = $MapImage

var img := Image.create(1,1,false,Image.FORMAT_RGBA8)
var tex := ImageTexture.create_from_image(img)

func _ready() -> void:
	visible = false
	map_texrect.texture = tex
	MapService.map_changed.connect(_redraw)
	_redraw()

func open_map() -> void:
	visible = true
	_redraw()
	# optional: pause game input while map open
	# get_tree().paused = true
	# process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func close_map() -> void:
	visible = false
	# get_tree().paused = false

#func _unhandled_input(e: InputEvent) -> void:
	#if not visible: return
	#if e.is_action_pressed("map") or e.is_action_pressed("ui_cancel"):
		#close_map()
		
func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("map"):
		print("M key pressed")
		visible = not visible
		if visible:
			map_texrect.texture = MapService.get_texture()
		get_viewport().set_input_as_handled()

	elif visible and e.is_action_pressed("ui_cancel"):
		close_map()


func _redraw() -> void:
	var gs = MapService.grid_size
	var px := cell_px
	img = Image.create(gs.x * px, gs.y * px, false, Image.FORMAT_RGBA8)
	img.lock()

	for y in gs.y:
		for x in gs.x:
			var c := Vector2i(x,y)
			var t = MapService.get_cell(c)
			var col = t
			match t:
				MapService.CELL_FLOOR: MapService.COL_FLOOR
				MapService.CELL_SEEN:  MapService.COL_SEEN
				MapService.CELL_DOOR:  MapService.COL_DOOR  # keep door glyph if you tag them
				_: MapService.COL_FOG
			for yy in px:
				for xx in px:
					img.set_pixel(x*px+xx, y*px+yy, col)

	# player arrow (optional)
	if show_player:
		var p = MapService.player_cell * px + Vector2i(px/2, px/2)
		var tip = p + MapService.player_facing * (px/2)
		_draw_disc(p, 2, Color(1,0.9,0.2,1))
		_draw_line(p, tip, Color(1,0.3,0.1,1))

	img.unlock()
	tex.update(img)
	map_texrect.texture = tex

func _draw_disc(center: Vector2i, r: int, col: Color) -> void:
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
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
