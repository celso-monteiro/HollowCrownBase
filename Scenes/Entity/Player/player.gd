extends CharacterBody3D

const STEP_SIZE := 1.6
const TURN_TIME := 0.2
const MOVE_TIME := 0.3
const CAST_HEIGHT := 1.0            # cast height (if you want, set to player’s chest)
const RAY_MARGIN := 0.10           # extra distance to keep from walls
const COLLISION_MASK := 0xFFFFFFFF  # adjust if you use layers

@onready var front_ray  : RayCast3D       = $FrontRay
@onready var back_ray   : RayCast3D       = $BackRay
@onready var left_ray   : RayCast3D       = $LeftRay
@onready var right_ray  : RayCast3D       = $RightRay
@onready var animation  : AnimationPlayer = $Animation
@onready var camera     : Camera3D        = $Camera3D


var is_busy := false                 # true while a step/turn tween is running
var direction := Vector3.FORWARD     # forward in local space (-basis.z after snap)
var _current_intent := ""            # "forward" | "back" | "left" | "right" | ""
var _played_stop_anim := false       # to play headbob once when chain stops

var _last_reveal_cell: Vector2i = Vector2i(-9999, -9999)

func _ready() -> void:
	#MapService.configure(64, 64, Vector2i(0, 0)) # <-- use your real grid size/origin
	MapService.configure(64, 64, Vector2i(-32, -32))
	# for a quick visual test
	MapService.reveal_at_world(global_transform.origin, true)
	_enable_rays()
	_snap_to_grid()
	_update_direction()

	
func _on_step_finished():
	MapService.reveal_at_world(global_transform.origin, true)
	
func _update_compass():
	var f := -global_transform.basis.z.normalized()
	var dirs = {
		"N": Vector3(0,0,-1),
		"E": Vector3(1,0, 0),
		"S": Vector3(0,0, 1),
		"W": Vector3(-1,0,0),
	}
	var best := "N"
	var best_dot := -INF
	for k in dirs.keys():
		var d = f.dot(dirs[k])
		if d > best_dot:
			best_dot = d
			best = k
	
	#var hud := get_tree().root.get_node_or_null("HUD") # adjust path!
	var hud := get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("set_compass"):
		hud.set_compass(best)
		
func _physics_process(_delta: float) -> void:
	# Determine movement intent based on held keys (priority order avoids diagonals)
	var intent := ""
	if Input.is_action_pressed("forward") or Input.is_action_pressed("ui_up"):
		intent = "forward"
	elif Input.is_action_pressed("back") or Input.is_action_pressed("ui_down"):
		intent = "back"
	elif Input.is_action_pressed("left") or Input.is_action_pressed("ui_left"):
		intent = "left"
	elif Input.is_action_pressed("right") or Input.is_action_pressed("ui_right"):
		intent = "right"
	# Start chain if not moving and a key is held
	if not is_busy and intent != "":
		if _can_move_intent(intent):
			_start_step_for_intent(intent)
			_current_intent = intent
			_played_stop_anim = false
		else:
			_current_intent = ""  # blocked; no chain
		return

	# When tween finishes, chaining is handled in the tween's finished callback.
	# If no key is held and we haven't played stop animation yet, do it once.
	if intent == "" and not _played_stop_anim and not is_busy:
		_do_stop_animation_once()
	# existing movement logic...
	_update_automap()

func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("save"):
		SaveService.save_game()
		
	if event.is_action_pressed("load"):
		SaveService.load_game()
		
	if event.is_action_pressed("pause"):
		get_tree().paused
		print(get_tree().paused )
				
	# Quit / other UI fix this
	if event.is_action_pressed("ui_cancel"):
		print("Esc pressed")
		get_tree().quit()
	# One-turn-per-press (kept simple)
	
	if event.is_action_pressed("left") or event.is_action_pressed("ui_left"):
		_turn(90)
	if event.is_action_pressed("right") or event.is_action_pressed("ui_right"):
		_turn(-90)
	
	if event.is_action_pressed("map"):
		MapService.toggle_full_map()
		MapService.reveal_at_world(global_transform.origin, true)  # at start and after each grid move
		
	# Use / interact (front ray)
	if event.is_action_pressed("use"):
		var ray := $FrontRay
		ray.force_raycast_update()
		if ray.is_colliding():
			var node := ray.get_collider() as Node
			# climb up until we find a "Door" group node
			while node and not node.is_in_group("Door"):
				node = node.get_parent()
			if node and node.is_in_group("Door") and node.has_method("open_door"):
				node.open_door()

# --- helpers ---------------------------------------------------------------

func _enable_rays() -> void:
	for r in [front_ray, back_ray, left_ray, right_ray]:
		if r:
			r.enabled = true
func _dir_vector_for_intent(intent: String) -> Vector3:
	# Forward/back use -Z/+Z; left/right use -X/+X in local space
	var f := -global_transform.basis.z.normalized()
	var r :=  global_transform.basis.x.normalized()
	match intent:
		"forward":
			return f
		"back":
			return -f
		"left":
			return -r
		"right":
			return r
		_:
			return Vector3.ZERO
			
func _can_move_intent(intent: String) -> bool:
	var local_dir := _dir_vector_for_intent(intent)
	if local_dir == Vector3.ZERO:
		return false

	# cast from chest forward by exactly one step (+ small margin)
	var from := global_transform.origin + Vector3(0, CAST_HEIGHT, 0)
	var to   := from + local_dir * (STEP_SIZE + RAY_MARGIN)

	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [self]
	q.collision_mask = COLLISION_MASK

	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit.is_empty()


func _start_step_for_intent(intent: String) -> void:
	var local_dir := _dir_vector_for_intent(intent)
	if local_dir == Vector3.ZERO:
		return
	is_busy = true
	var target := global_transform.origin + local_dir * STEP_SIZE
	var t := get_tree().create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "global_transform:origin", target, MOVE_TIME)
	t.finished.connect(func():
		is_busy = false
		_snap_to_grid()
		_update_direction()
		# Decide whether to chain the next step or stop
		var still_holding := Input.is_action_pressed(intent) or \
			((intent == "forward") and Input.is_action_pressed("ui_up")) or \
			((intent == "back")    and Input.is_action_pressed("ui_down")) or \
			((intent == "left")    and Input.is_action_pressed("ui_left")) or \
			((intent == "right")   and Input.is_action_pressed("ui_right"))

		if still_holding and _can_move_intent(intent):
			_start_step_for_intent(intent)  # chain next tile immediately
		else:
			_current_intent = ""
			_do_stop_animation_once()
	)
	
	
func _do_stop_animation_once() -> void:
	_played_stop_anim = true
	#if animation and animation.has_animation("headbob"):
		#animation.play("headbob")

func _turn(angle_deg: float) -> void:
	if is_busy:
		return
	is_busy = true
	var target_yaw := rotation_degrees.y + angle_deg
	var t := get_tree().create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "rotation_degrees:y", target_yaw, TURN_TIME)
	t.finished.connect(func():
		is_busy = false
		_snap_to_grid()
		_update_direction()
		_update_compass()
	)

func _update_direction() -> void:
	direction = -global_transform.basis.z.normalized()

func _snap_to_grid() -> void:
	var p := global_transform.origin
	p.x = round(p.x / STEP_SIZE) * STEP_SIZE
	p.z = round(p.z / STEP_SIZE) * STEP_SIZE
	global_transform.origin = p
	
func _update_automap() -> void:
	if not MapService:
		return
	var current_cell := MapService.world_to_cell(global_transform.origin)
	if current_cell != _last_reveal_cell:
		MapService.reveal_at_world(global_transform.origin, true)
		_last_reveal_cell = current_cell
