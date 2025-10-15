extends CanvasLayer

#@onready var full_map := preload("res://Scenes/Maps/full_map.tscn").instantiate()

@onready var armor = $Control/StatusBar/ArmorLabel
@onready var health = $Control/StatusBar/HealthLabel
@onready var ammo = $Control/StatusBar/AmmoLabel
@onready var info_label = $Control/InfoLabel
@onready var time_label = $Control/TimeElapsed
@onready var gold = $Control/GoldLabel
@onready var compass: Label = $"Control/TopBar/CompassLabel"  # adjust exact path


var time_elapsed = 0.0
var minutes
var seconds
var time_string

func set_compass(cardinal: String) -> void:
	compass.text = cardinal

func _ready():
	info_label.text = ""
	SignalManager.connect("display_info", _on_display_info)
	SignalManager.connect("change_weapon", _on_change_weapon)
	SignalManager.connect("yellow_key_picked", _on_yellow_key_picked)

func _process(delta):
	armor.text = Playerstats.get_armor()
	health.text = Playerstats.get_health()
	gold.text = Playerstats.get_gold()
	
	# Time
	time_elapsed += delta
	minutes = time_elapsed / 60
	seconds = fmod(time_elapsed, 60)
	time_string = "%02d:%02d" % [minutes, seconds]
	time_label.text = time_string
	
	#display ammo
	ammo.text = Playerstats.get_ammo()
	
func _on_display_info(info_text):
	info_label.text = info_text
	$Timer.start()

func _on_change_weapon(new_weapon):
	if new_weapon == "Wand":
		#ammo.text = Playerstats.get_ammo()
		$Control/StatusBar/WandIcon.visible = true
		$Control/StatusBar/SwordIcon.visible = false
		$Control/StatusBar/AmmoIcon.visible = true
		$Control/StatusBar/AmmoLabel.visible = true
	else:
		#ammo.text = ""
		$Control/StatusBar/WandIcon.visible = false
		$Control/StatusBar/SwordIcon.visible = true
		$Control/StatusBar/AmmoIcon.visible = false
		$Control/StatusBar/AmmoLabel.visible = false

func _on_timer_timeout():
	info_label.text = ""

func _on_yellow_key_picked():
	$Control/StatusBar/YellowSlot.visible = true
