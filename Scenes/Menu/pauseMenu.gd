extends CanvasLayer

func _ready():
	$Control/VBoxContainer/ContinueBtn.grab_focus()
	$Control/VBoxContainer/ContinueBtn.arrow.global_position.x = 110
	
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state


func _input(event):
	if event.is_action_pressed("pause"):
		#$Control/VBoxContainer/ContinueBtn.grab_focus()
		var new_pause_state = not get_tree().paused
		get_tree().paused = new_pause_state
		visible = new_pause_state

func _on_continue_btn_pressed():
	$BtnSnd.play()
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state

func _on_quit_btn_pressed():
	# Exit game
	$BtnSnd.play()
	get_tree().quit()

func _on_new_game_btn_pressed():
	print("New Game")

func _on_load_btn_pressed():
	print("Load Game")

func _on_config_btn_pressed():
	print("Config Game")
