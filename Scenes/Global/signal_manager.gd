extends Node

#*****************************************************************************#

# A signal manager is a centralized script, set as an autoload, designed to 
# handle signals and coordinate actions between different objects. 
# Instead of connecting signals directly between multiple nodes, which can 
# become complex as your project grows, a signal manager can act as a hub. 

# *****************************************************************************#

signal display_dialog(text)
signal display_info
signal player_attacking
signal player_attacking_finished
signal player_died
signal change_weapon(weapon_name)

signal display_level_stats
signal count_enemies_killed
signal count_secrets_discovered
signal count_time_elapsed
signal count_items_picked

signal level_finished
signal room_entered
signal yellow_key_picked
