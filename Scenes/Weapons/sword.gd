extends Node3D

@onready var anim = $CanvasLayer/Control/AnimationPlayer
@onready var ray = $GunRays/RayCast3D

var can_shoot = true
var changed = false
var rng
var is_picked = false

@export var sword_damage = 50

func _ready():
	SignalManager.connect("player_attacking", _on_player_attack)
	SignalManager.connect("player_died", _on_player_died)
	randomize()
	rng = RandomNumberGenerator.new()
	anim.play("idle")

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		if ray.is_colliding():
			if ray.get_collider().get_parent().is_in_group("Enemy"):
				ray.get_collider().get_parent().take_damage(sword_damage)
		anim.play("idle")
		Playerstats.is_attacking = false
		SignalManager.emit_signal("player_attacking_finished")
		

func _on_player_attack():
	can_shoot = true
	
	if can_shoot:
		$CanvasLayer/Control/AnimationPlayer.play("shoot")
		can_shoot = false

func _on_player_died():
	can_shoot = false
	$CanvasLayer/Control/AnimationPlayer.play("off")
