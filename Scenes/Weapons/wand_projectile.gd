extends Area3D

@onready var ray = $RayCast3D

# projectile variables
@export var projectile_speed = 10
@export var projectile_damage = 5

func _ready():
	$AnimationPlayer.play("idle")

func _process(delta):
	# projectile movement
	translate(Vector3.FORWARD * projectile_speed * delta)
	
	if ray.is_colliding():
		set_process(false)
		$AnimationPlayer.play("explode")
		$Explode_snd.play()
	
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "explode":
		queue_free()

func queu():
	queue_free()
	
func deal_damage():
	var enemies = get_overlapping_areas()
	for area in enemies:
		if area.get_parent().is_in_group("Enemy"):
			area.get_parent().take_damage(projectile_damage)


func _on_area_entered(area):
	if area.is_in_group("Player") or area.is_in_group("player_projectiles"):
		return
	set_process(false)
	$AnimationPlayer.play("explode")
	$Explode_snd.play()
	deal_damage()
