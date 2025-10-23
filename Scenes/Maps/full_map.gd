# full_map.gd
extends CanvasLayer

@onready var dim: ColorRect         = $Dim
@onready var map_texrect: TextureRect = $MapImage
@onready var hint: Label            = $Hint

func _ready():
	# CanvasLayer isn't a Control, so we size/anchor the CHILD Controls:
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_texrect.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)

	# Make sure this layer draws above everything
	layer = 100
	visible = false

	# Visual sanity: dim the background slightly, and show a banner text
	dim.color = Color(0, 0, 0, 0.4)
	hint.text = "MAP"
	hint.add_theme_font_size_override("font_size", 24)

	# TextureRect display settings
	map_texrect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	map_texrect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_texrect.modulate = Color(1,1,1,1)

	# Connect updates
	MapService.map_updated.connect(_on_map_updated)

func refresh_texture():
	var tex := MapService.get_texture()
	if tex:
		map_texrect.texture = tex
		# Debug print so we *know* something is assigned
		print("[FullMap] assigned tex:", tex, " size:", tex.get_width(), "x", tex.get_height())
	else:
		print("[FullMap] tex is null in refresh_texture")

func _on_map_updated(tex: Texture2D) -> void:
	# Only bother updating if visible (prevents needless churn)
	if visible:
		map_texrect.texture = tex
