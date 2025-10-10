extends Node

# This script is a singleton.

# This approach handles turns by cycling through the player and each enemy in 
# sequence. The TurnManager keeps track of whose turn it is, emits the 
# appropriate signals, and ensures each enemy gets their turn before cycling 
# back to the player.

var turn # PLAYER or ENEMY

# This array shows the enemies in the scene. Later, I have to change this to 
# add only the enemies in the current room. Otherwise some enemies far away 
# from the player would want to attack/move/etc.
var enemies = [] 
var current_enemy_index = 0

signal player_turn_started
signal enemy_turn_started


func _ready():
	turn = "PLAYER_TURN"

func get_turn():
	# for debug purposes
	return turn

func register_enemy(enemy):
	# add all enemies to the array to cycle trough
	enemies.append(enemy)
	
func unregister_enemy(enemy):
	# erase enemies from the array. For example, when killed
	enemies.erase(enemy)
	if enemies.size() > 0:
		current_enemy_index = current_enemy_index % enemies.size()
	else:
		current_enemy_index = 0
