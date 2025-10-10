extends Node3D

@onready var anim = $CanvasLayer/Control/AnimationPlayer
@onready var spawn_location = $Marker3D
@onready var projectile = preload("res://Scenes/Weapons/wand_projectile.tscn")

var can_shoot = true
var changed = false
var rng
var is_picked = false

func _ready():
	SignalManager.connect("player_attacking", _on_player_attack)
	SignalManager.connect("player_died", _on_player_died)
	randomize()
	rng = RandomNumberGenerator.new()
	anim.play("idle")

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim.play("idle")
		Playerstats.is_attacking = false
		SignalManager.emit_signal("player_attacking_finished")

func _on_player_attack():
	if Playerstats.ammo_wand <= 0:
		Playerstats.is_attacking = false
		can_shoot = false
	else:
		can_shoot = true
	
	if can_shoot:
		$CanvasLayer/Control/AnimationPlayer.play("shoot")
		Playerstats.change_wand_ammo(-3)
		can_shoot = false

func launch_projectile():
	$Shoot_snd.play()
	var new_projectile = projectile.instantiate()
	get_node("/root/TestLevel").add_child(new_projectile) # change for root name !
	new_projectile.global_transform = spawn_location.global_transform

func _on_player_died():
	can_shoot = false
	$CanvasLayer/Control/AnimationPlayer.play("off")
