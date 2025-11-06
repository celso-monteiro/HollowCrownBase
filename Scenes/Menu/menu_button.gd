@tool
extends TextureButton

@onready var arrow = $Arrow
@onready var text_label = $Label

@export var text = "Text Button" 	# text to be displayed in the button
@export var arrow_margin_from_center = 100	# margin from the button

var center_x = 0

func _ready():
	$AnimationPlayer.play("idle")
	setup_text()
	hide_arrow()
	
	# this function is needed to grab the focus from the keyboard
	set_focus_mode(1) 

	
func _process(_delta):
	# To see the changes in the editor
	if Engine.is_editor_hint():
		setup_text()
		show_arrow()
	
func setup_text():
	# changes the text button
	text_label.text = text
	
func show_arrow():
	# position of the cursor in the Y axis
	arrow.global_position.y = global_position.y + (size.y / 2.0)
		
	# position of the cursor in X axis
	center_x = global_position.x + (size.x / 2)
	arrow.global_position.x = center_x - arrow_margin_from_center

	arrow.visible = true
	
func hide_arrow():
	arrow.visible = false

func _on_focus_entered():
	show_arrow()

func _on_focus_exited():
	hide_arrow()

func _on_mouse_entered():
	grab_focus()
