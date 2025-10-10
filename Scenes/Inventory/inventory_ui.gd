extends Control

# **** WIP ****
# if I see some interest in this template, I will update the inventory system

# Inventory system: the player has an inventory for objects collected. 
# If you use an item, normally you use a turn.

@onready var inventory: inv = preload("res://Scenes/Inventory/player_inventory.tres")
@onready var slots: Array = $SlotsContainer.get_children()

var is_open = false

func _ready():
	update_slots()
	close()
	
func open():
	visible = true
	is_open = true
	
func close():
	visible = false
	is_open = false
	
func _input(_event):
	if Input.is_action_just_pressed("inventory"):
		if is_open:
			close()
		else:
			open()

func update_slots():
	# ToDo
	for i in range(min(inventory.item.size(), slots.size())):
		slots[i].update_item(inventory.item[i])
