extends CanvasLayer

@onready var title_label = $Control/Title

var title

func _ready():
	title = get_tree().get_current_scene().level_name
	title_label.set("theme_override_font_sizes/font_size", 70)
	title_label.text = str(title)
