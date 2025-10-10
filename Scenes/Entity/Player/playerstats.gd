extends Node

#Player variables
var health = 100
var gold = 0

var max_health = 100
var armor = 0
var max_armor = 100
var is_alive = true
var is_attacking = false

var ammo_wand = 12
var ammo_max_wand = 200
var current_weapon = "Wand"

var has_blue_key = false
var has_red_key = false
var has_yellow_key = false

func change_health(amount):
	if armor <= 0:
		health += amount
		health = clamp(health, 0, max_health)
	else:
		change_armor(amount)

func change_gold(amount):
	gold += amount

func change_armor(amount):
	armor += amount
	armor = clamp(armor,0,max_armor)

func get_health():
	return str(health) 

func get_armor():
	return str(armor)
	
func get_gold():
	return str(gold)

func change_wand_ammo(amount):
	ammo_wand += amount
	ammo_wand = clamp(ammo_wand,0,ammo_max_wand)

func get_ammo():
	return str(ammo_wand)
