extends Node3D

@onready var front_ray = $Area3D/FrontRay
@onready var back_ray = $Area3D/BackRay
@onready var left_ray = $Area3D/LeftRay
@onready var right_ray = $Area3D/RightRay
@onready var blood_particles = preload("res://Scenes/Enemies/blood_particles.tscn")

var player
var target_position
var rng
var grid_size = 2	
var travel_time = 0.3 #speed
#var direction

var enemy_name

# enemy stats
@export var health = 150
@export var distance_to_shoot = 4
@export var attack_dmg = 4
var attack_dmg_random_dmg = 0
@export var pain_chance = 7

# enemy states (simple FSM)
var move = true
var searching = false
var shooting = false
var awake = false
var pain = false
var is_alive = true
var is_pain = false
var initial_health
var melee_attack = false

func _ready():
	player = get_tree().get_nodes_in_group("player")[0]
	rng = RandomNumberGenerator.new()
	initial_health = health
	TurnManager.connect("enemy_turn_started", _on_enemy_turn_started)
	$AnimationPlayer.play("idle")
	randomize()
	rng = RandomNumberGenerator.new()
	
	enemy_name = self.name

		
func _process(_delta):
	if health <= 0:
		is_alive = false
		
func _on_enemy_turn_started():
	# Check if there are enemies in the list (current room):
	if TurnManager.enemies.size() <= 0:
		return
	if is_alive and TurnManager.enemies[TurnManager.current_enemy_index] == self and TurnManager.turn == "ENEMY_TURN":
		print(TurnManager.turn , TurnManager.enemies[TurnManager.current_enemy_index])
		if player_collision():
			if !is_pain:
				# Melee attack if colission with player
				attack()
			else:
				skip_turn()
		else:
			if is_pain:
				skip_turn()
			else:
				chase_player_or_move_randomly()

func player_collision():
	# Check for collision with player in every possible direction
	return ((front_ray.is_colliding() and front_ray.get_collider().get_parent() == player) or (back_ray.is_colliding() and back_ray.get_collider().get_parent() == player) or (left_ray.is_colliding() and left_ray.get_collider().get_parent() == player) or (right_ray.is_colliding() and right_ray.get_collider().get_parent() == player))

func chase_player_or_move_randomly():
	var player_position = player.global_transform.origin
	var enemy_position = global_transform.origin
	
	# Calculate direction to the player
	var direction_to_player  = (player_position - enemy_position).normalized()
	
	# Determine the dominant direction
	var abs_direction = direction_to_player.abs()
	var dominant_direction = Vector3.ZERO
	
	if abs_direction.z >= abs_direction.x:
		if direction_to_player.z > 0:
			dominant_direction = Vector3.BACK
		else:
			dominant_direction = Vector3.FORWARD
	else:
		if direction_to_player.x > 0:
			dominant_direction = Vector3.RIGHT
		else:
			dominant_direction = Vector3.LEFT
	
	if !player_collision():
		if !is_direction_colliding(dominant_direction):
			# Check if the dominant direction is clear and chase the player
			if !is_direction_same_as_player(dominant_direction):
				move_one_grid(dominant_direction)
			else:
				move_randomly()
		else:
			move_randomly()

func move_randomly():
	#If unable to move towards the target, try random movement
	var random_direction = get_random_direction()
	if !player_collision():
		if !is_direction_colliding(random_direction) and !is_direction_same_as_player(random_direction): 
			move_one_grid(random_direction)
		else:
			skip_turn()

func get_random_direction():
	var random_directions = [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
	var random_direction = random_directions[rng.randi_range(0, random_directions.size() - 1)]
	return random_direction.normalized()

func is_direction_colliding(direction):
	var ray
	if direction == Vector3.LEFT:
		ray = left_ray
	elif direction == Vector3.RIGHT:
		ray = right_ray
	elif direction == Vector3.FORWARD:
		ray = front_ray
	elif direction == Vector3.BACK:
		ray = back_ray

	if ray != null:
		return ray.is_colliding()
	else:
		return true

func move_one_grid(direction):
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "transform", transform.translated_local(direction * grid_size), travel_time)
	$AnimationPlayer.play("walk")
	
func is_direction_same_as_player(direction):
	# the player and the enemy can't be in the same cell, so we calculate
	# the next enemy position to be sure
	var player_position = player.global_transform.origin
	var enemy_position = global_transform.origin
	var next_enemy_position = enemy_position + (direction.normalized() * grid_size)
	return next_enemy_position.distance_to(player_position) < grid_size

func skip_turn():
	#print("skiping turn")
	is_pain = false
	end_enemy_turn()

func take_damage(dmg_amount):
	if is_alive:
		health -= dmg_amount
		check_pain()
		if is_pain:
			SignalManager.emit_signal("display_info", enemy_name + " is in pain, can't attack!")
			$AnimationPlayer.play("pain")
			$Pain_snd.play()
		spawn_blood_particles()
				
		
		if health <= 0:
			die()
			return
			
	
func attack():
	if is_alive:
		SignalManager.emit_signal("display_info", enemy_name + " attacks...")
		$Attack_snd.play()
		$AnimationPlayer.play("attack")
		player.take_damage(randomize_damage())
		
func die():
	SignalManager.emit_signal("display_info",  enemy_name + " die!")
	$AnimationPlayer.play("die")
	$Area3D/CollisionShape3D.set_deferred("disabled", true)
	$Die_snd.play()
	#$Area3D/CollisionShape3D.disabled = true
	$Area3D/CollisionShape3D.set_deferred("disbled", true)
	$Area3D.collision_layer = 0
	$Area3D.collision_mask = 0
	
	# pop the enemy from the array
	TurnManager.unregister_enemy(self)
	SignalManager.count_enemies_killed.emit()

func explode():
	$Area3D/CollisionShape3D.set_deferred("disabled", true)
	$AnimationPlayer.play("gib")
	SignalManager.count_enemies_killed.emit()
	#$Gibs_snd.play()

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "pain":
		$AnimationPlayer.play("idle")
	if anim_name == "walk":
		$AnimationPlayer.play("idle")
		end_enemy_turn()
	if anim_name == "attack":
		$AnimationPlayer.play("idle")
		end_enemy_turn()
	if anim_name == "die":
		is_alive = false

func spawn_blood_particles():
	var blood_instance = blood_particles.instantiate()
	add_child(blood_instance)
	blood_instance.emitting = true
	blood_instance.global_position = global_position
	
func randomize_damage():
	# calculates random damage each time the enemy does a melee attack
	attack_dmg_random_dmg = rng.randi_range(1, 10) * attack_dmg
	#print("enemy attack: ", attack_dmg_random_dmg)
	return attack_dmg_random_dmg

func check_pain():
	var chance = rng.randi_range(1, pain_chance)
	#print("chance: ", chance)
	if chance >= pain_chance:
		is_pain = true
		#print("pain")
	else:
		is_pain = false

func end_enemy_turn():
	# End turn and move to the next enemy in the list
	TurnManager.turn = "PLAYER_TURN"
	TurnManager.emit_signal("player_turn_started")
	if TurnManager.enemies.size() > 0:
		TurnManager.current_enemy_index = (TurnManager.current_enemy_index + 1) % TurnManager.enemies.size()
