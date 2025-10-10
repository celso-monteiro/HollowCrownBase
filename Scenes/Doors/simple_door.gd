extends Node3D

var is_player_in_door = false
var is_open = false
var player

func _ready():
	player = get_tree().get_nodes_in_group("player")[0]

func _on_area_3d_area_entered(_area):
	pass

func _on_area_3d_area_exited(_area):
	pass

func _process(_delta):
	pass
			
func open_door():
	$AnimationPlayer.play("open")
	$DoorSnd.play()
	is_open = false
