@tool
extends VBoxContainer

signal value_changed(value: int)

# lazy refs (inspector may call before _ready)
var face_label: Label
var preview_rect: TextureRect
var spin_box: SpinBox
var pick_btn: Button
var popup: AcceptDialog
var grid: GridContainer

var texture_sheet: Texture2D
var texture_size: int = 128
const CLEAR_TEX := preload("res://addons/level_block/clear.svg")

var _pending_value: int = -999999
var _nodes_ready := false

func _enter_tree() -> void:
	_resolve_nodes()

func _ready() -> void:
	_nodes_ready = true
	if pick_btn and not pick_btn.pressed.is_connected(_open_picker):
		pick_btn.pressed.connect(_open_picker)
	if spin_box and not spin_box.value_changed.is_connected(_on_spin_changed):
		spin_box.value_changed.connect(_on_spin_changed)

	if _pending_value != -999999 and spin_box:
		spin_box.value = _pending_value
		_pending_value = -999999
	_update_preview()

func _ensure_nodes() -> bool:
	if _nodes_ready and preview_rect and spin_box:
		return true
	_resolve_nodes()
	_nodes_ready = (preview_rect != null and spin_box != null)
	return _nodes_ready

func _resolve_nodes() -> void:
	face_label   = get_node_or_null("FaceLabel") as Label
	preview_rect = get_node_or_null("Row/TextureRect") as TextureRect
	spin_box     = get_node_or_null("Row/SpinBox") as SpinBox
	pick_btn     = get_node_or_null("Row/PickButton") as Button
	popup        = get_node_or_null("Popup") as AcceptDialog
	grid         = get_node_or_null("Popup/ScrollContainer/GridContainer") as GridContainer
	# simple fallbacks if layout changes slightly
	#if preview_rect == null: preview_rect = get_node_or_null("TextureRect") as TextureRect
	if preview_rect and preview_rect.custom_minimum_size == Vector2.ZERO:
		preview_rect.custom_minimum_size = Vector2(48, 48)
	if spin_box     == null: spin_box     = get_node_or_null("SpinBox") as SpinBox
	if pick_btn     == null: pick_btn     = get_node_or_null("PickButton") as Button
	if popup        == null: popup        = get_node_or_null("Popup") as AcceptDialog
	if grid         == null: grid         = get_node_or_null("GridContainer") as GridContainer

# ---------- public API (called by inspector) ----------
func set_face_label(label: String) -> void:
	if not _ensure_nodes(): return
	if face_label:
		face_label.text = label
	if pick_btn and pick_btn.text == "":
		pick_btn.text = "Pick"  # short; label already says which face

func set_texture_sheet(tex: Texture2D, size: int = 128) -> void:
	texture_sheet = tex
	texture_size = max(1, size)
	if _ensure_nodes():
		_update_preview()

func set_value(val: int) -> void:
	if not _ensure_nodes() or spin_box == null:
		_pending_value = val
		return
	spin_box.value = val
	_update_preview()

# ---------- UI handlers ----------
func _on_spin_changed(val: float) -> void:
	_update_preview()
	value_changed.emit(int(val))

func _open_picker() -> void:
	if texture_sheet == null or not popup:
		return
	_build_grid()
	popup.popup_centered()

# ---------- grid building (Button + TextureRect with AtlasTexture) ----------
func _build_grid() -> void:
	if grid == null or texture_sheet == null:
		return
	for c in grid.get_children(): c.queue_free()
	await get_tree().process_frame

	var cols: int = max(1, int(texture_sheet.get_width()  / texture_size))
	var rows: int = max(1, int(texture_sheet.get_height() / texture_size))
	grid.columns = clamp(cols, 1, 16)

	var index := 0
	for j in range(rows):
		for i in range(cols):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture_sheet
			atlas.region = Rect2(i * texture_size, j * texture_size, texture_size, texture_size)

			var btn := Button.new()
			btn.custom_minimum_size = Vector2(52, 52)
			btn.tooltip_text = "Tile " + str(index)

			var thumb := TextureRect.new()
			thumb.texture = atlas
			thumb.custom_minimum_size = Vector2(48, 48)
			thumb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			thumb.size_flags_vertical = Control.SIZE_EXPAND_FILL
			thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			thumb.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			btn.add_child(thumb)

			var picked := index
			btn.pressed.connect(func ():
				if spin_box: spin_box.value = picked
				_update_preview()
				value_changed.emit(picked)
				if popup: popup.hide()
			)

			grid.add_child(btn)
			index += 1

# ---------- preview ----------
func _update_preview() -> void:
	if not _ensure_nodes() or preview_rect == null:
		return
	if texture_sheet == null:
		preview_rect.texture = CLEAR_TEX
		return

	var idx := int(spin_box.value) if spin_box else -1
	if idx < 0:
		preview_rect.texture = CLEAR_TEX
		return

	var cols: int = max(1, int(texture_sheet.get_width() / texture_size))
	var x: int = (idx % cols) * texture_size
	var y: int = (idx / cols) * texture_size

	var atlas := AtlasTexture.new()
	atlas.atlas = texture_sheet
	atlas.region = Rect2(x, y, texture_size, texture_size)
	preview_rect.texture = atlas
