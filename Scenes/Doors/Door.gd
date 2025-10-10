extends Node3D
# Put this node in group "doors" so the player can call door.toggle()

@export_enum("swing", "slide") var door_type: String = "swing"
@export var open_time: float = 0.35
@export var swing_angle_deg: float = 90.0      # used for swing
@export var slide_distance: float = 1.9        # used for slide (local X by default)
@export var starts_open: bool = false
@export var blocks_when_closed: bool = true    # when open, collision turns off

var hinge: Node3D = null
var anim: AnimationPlayer = null

var _is_open := false
var _closed_pos: Vector3
var _open_pos: Vector3
var _closed_rot_y: float
var _open_rot_y: float
var _colliders: Array[CollisionShape3D] = []

func _ready() -> void:
	# Ensure group
	if not is_in_group("doors"):
		add_to_group("doors")

	# Resolve nodes safely
	hinge = get_node_or_null("Hinge") as Node3D
	if hinge == null:
		hinge = self
	anim = get_node_or_null("AnimationPlayer") as AnimationPlayer

	# Cache collision shapes under hinge (recursive)
	_colliders.clear()
	for n in hinge.find_children("*", "CollisionShape3D", true, false):
		_colliders.append(n as CollisionShape3D)

	# Closed transforms
	_closed_pos = hinge.position
	_closed_rot_y = hinge.rotation_degrees.y

	# Open transforms (no ternaries)
	if door_type == "slide":
		var local_x := hinge.transform.basis.x.normalized()  # slide along local X
		_open_pos = _closed_pos + local_x * slide_distance
		_open_rot_y = _closed_rot_y
	else:
		_open_pos = _closed_pos
		_open_rot_y = _closed_rot_y + swing_angle_deg

	# Initial state
	if starts_open:
		_apply_open_state(true, true)
	else:
		_apply_open_state(false, true)

func toggle() -> void:
	if _is_open:
		close()
	else:
		open()

func open() -> void:
	if _is_open:
		return
	_is_open = true
	_play_motion(true)

func close() -> void:
	if not _is_open:
		return
	_is_open = false
	_play_motion(false)

func _play_motion(is_opening: bool) -> void:
	var t := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if door_type == "slide":
		var target_pos := _open_pos if is_opening else _closed_pos
		t.tween_property(hinge, "position", target_pos, open_time)
	else:
		var target_rot := Vector3(
			hinge.rotation_degrees.x,
			_open_rot_y if is_opening else _closed_rot_y,
			hinge.rotation_degrees.z
		)
		t.tween_property(hinge, "rotation_degrees", target_rot, open_time)

	t.finished.connect(func ():
		_apply_open_state(is_opening, false)
	)


func _apply_open_state(is_opening: bool, instant: bool) -> void:
	# Collision off when open (if blocks_when_closed)
	for c in _colliders:
		if is_instance_valid(c):
			c.disabled = is_opening and blocks_when_closed

	if instant:
		if door_type == "slide":
			hinge.position = _open_pos if open else _closed_pos
		else:
			var r := hinge.rotation_degrees
			r.y = _open_rot_y if open else _closed_rot_y
			hinge.rotation_degrees = r
