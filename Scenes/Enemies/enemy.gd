extends Node3D

@onready var front_ray = $Area3D/FrontRay
@onready var back_ray = $Area3D/BackRay
@onready var left_ray = $Area3D/LeftRay
@onready var right_ray = $Area3D/RightRay
@onready var animation = $AnimationPlayer

@export var travel_time = 0.3 #speed

var tween
var player
var rng
var direction
var dir
var grid_size = 2
var target_position


func _ready():
	player = get_tree().get_nodes_in_group("player")[0]
	target_position = player.global_position
	rng = RandomNumberGenerator.new()
	
	#TurnManager.connect("player_turn_started", on_player_turn_started)
	TurnManager.connect("enemy_turn_started", on_enemy_turn_started)

func _physics_process(delta):
	if tween is Tween:
		if tween.is_running():
			return	
		
func get_random_direction():
	# choose a random direction
	var random_direction = rng.randi_range(0,3)
	match random_direction:
		0: direction = Vector3.BACK # south
		1: direction = Vector3.FORWARD # north
		2: direction = Vector3.RIGHT # west
		3: direction = Vector3.LEFT # east
	return direction

func move_one_grid(direction):
	# Create a new tween
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Tween the transform to the target position
	tween.tween_property(self, "transform", transform.translated_local(direction * 2), travel_time)

func on_player_turn_started():
	#TurnManager.turn == "PLAYER_TURN"
	pass

func on_enemy_turn_started():
	print("enemy_turn")
	if TurnManager.turn == "ENEMY_TURN":
		
		if front_ray.is_colliding():
			print("front: ",front_ray.get_collider().name )
		if back_ray.is_colliding():
			print("back: ", back_ray.get_collider().name)
		if left_ray.is_colliding():
			print("left: ", left_ray.get_collider().name)
		if right_ray.is_colliding():
			print("right: ", right_ray.get_collider().name)
		
		if (front_ray.is_colliding() and front_ray.get_collider().name == "PlayerArea") or \
			(back_ray.is_colliding() and back_ray.get_collider().name == "PlayerArea") or \
			(left_ray.is_colliding() and left_ray.get_collider().name == "PlayerArea") or \
			(right_ray.is_colliding() and right_ray.get_collider().name == "PlayerArea"):
			#TurnManager.set_turn("PLAYER_TURN")
			TurnManager.emit_signal("player_turn_started")
		else:

			target_position = player.global_position
			direction = (target_position - global_position).normalized()
							
			# if there is no collision with player, chase the player
			# Determine the dominant direction so the enemy can move on a grid basis
			var abs_direction = direction.abs()

			if abs_direction.z >= abs_direction.x:
				if direction.z > 0:
					direction = Vector3.BACK
				else:
					direction = Vector3.FORWARD
			else:
				if direction.x > 0:
					direction = Vector3.RIGHT
				else:
					direction = Vector3.LEFT
			
			# move and avoid obstacles
			if direction == Vector3.FORWARD:
				if !front_ray.is_colliding():
					move_one_grid(direction)
					#TurnManager.set_turn("PLAYER_TURN")
					TurnManager.emit_signal("player_turn_started")
				else:
					# move in random direction
					var random_direction = get_random_direction()
					while true:
						if random_direction == Vector3.FORWARD and !front_ray.is_colliding():
							break
						if random_direction == Vector3.BACK and !back_ray.is_colliding():
							break
						elif random_direction == Vector3.LEFT and !left_ray.is_colliding():
							break
						elif random_direction == Vector3.RIGHT and !right_ray.is_colliding():
							break
						random_direction = get_random_direction()
					move_one_grid(random_direction)
					#TurnManager.set_turn("PLAYER_TURN")
					TurnManager.emit_signal("player_turn_started")
				
			elif direction == Vector3.BACK:
				if !back_ray.is_colliding():
					move_one_grid(direction)
					#TurnManager.set_turn("PLAYER_TURN")
					TurnManager.emit_signal("player_turn_started")
				else:
					# move in random direction
					var random_direction = get_random_direction()
					while true:
						if random_direction == Vector3.FORWARD and !front_ray.is_colliding():
							break
						if random_direction == Vector3.BACK and !back_ray.is_colliding():
							break
						elif random_direction == Vector3.LEFT and !left_ray.is_colliding():
							break
						elif random_direction == Vector3.RIGHT and !right_ray.is_colliding():
							break
						random_direction = get_random_direction()
					move_one_grid(random_direction)
					#TurnManager.set_turn("PLAYER_TURN")
					TurnManager.emit_signal("player_turn_started")
					
			elif direction == Vector3.LEFT:
				if !left_ray.is_colliding():
					move_one_grid(direction)
					#TurnManager.set_turn("PLAYER_TURN")
					TurnManager.emit_signal("player_turn_started")
				else:
					# move in random direction
					var random_direction = get_random_direction()
					while true:
						if random_direction == Vector3.FORWARD and !front_ray.is_colliding():
							break
						if random_direction == Vector3.BACK and !back_ray.is_colliding():
							break
						elif random_direction == Vector3.LEFT and !left_ray.is_colliding():
							break
						elif random_direction == Vector3.RIGHT and !right_ray.is_colliding():
							break
						random_direction = get_random_direction()
					move_one_grid(random_direction)
					#TurnManager.set_turn("PLAYER_TURN")
					TurnManager.emit_signal("player_turn_started")
			elif direction == Vector3.RIGHT:
				if !right_ray.is_colliding():
					move_one_grid(direction)
					#TurnManager.set_turn("PLAYER_TURN")
					TurnManager.emit_signal("player_turn_started")
				else:
					# move in random direction
					var random_direction = get_random_direction()
					while true:
						if random_direction == Vector3.FORWARD and !front_ray.is_colliding():
							break
						if random_direction == Vector3.BACK and !back_ray.is_colliding():
							break
						elif random_direction == Vector3.LEFT and !left_ray.is_colliding():
							break
						elif random_direction == Vector3.RIGHT and !right_ray.is_colliding():
							break
						random_direction = get_random_direction()
					move_one_grid(random_direction)
					#TurnManager.set_turn("PLAYER_TURN")
					TurnManager.emit_signal("player_turn_started")
