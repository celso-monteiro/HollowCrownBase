extends Node

# **** WIP ****
# This will be updated in a future patch if there is enough interest

 #Stat List
#==========
#
# Stats are 6 fundamental parameters that define the capabilities and 
# opportunities of a character. All stats have a maximum of 10, and a minimum 
# of -10. Each stat has its own XP score. Stats increase upon reaching certain 
# XP thresholds, according to the same curve as leveling with player XP. 
# The player earns stat XP by performing natural game actions (killing enemies, 
# picking items, discovering secret areas, finishing levels, etc.)
# 1- Strength: affects attack damage. One point of Strength increases 
#			   10% the attack damage of each weapon.
# 2- Defense: affects resistance to damage. One point of Defense decreases 
#			  10% the damage received from enemies.
# 3- Vitality: affects maximum HP. One point of Vitality increases 10% the 
#              maximum HP.
# 4- Energy: affects maximum armor value. One point of Energy increases 10% 
#            maximum armor
# 5- Agility: Affects ability to avoid incoming attacks. One point of Agility 
#             increases 10% the chance to avoid an attack.
# 6- Luck: Affects drop rates of most items. One point of Luck increases credit 
#          drop rate by 10% (Medkit, armor, ammo)


var strength = 0
var defense = 0
var vitality = 0
var energy = 0
var agility = 0
var luck = 0 

func _ready():
	pass

func _process(delta):
	pass
