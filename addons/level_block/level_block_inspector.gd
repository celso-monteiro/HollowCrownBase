@tool
extends EditorInspectorPlugin

const FACES: Array[String] = [
	"north_face","east_face","south_face","west_face","top_face","bottom_face"
]
const FACE_LABELS := {
	"north_face":"North Wall",
	"east_face":"East Wall",
	"south_face":"South Wall",
	"west_face":"West Wall",
	"top_face":"Ceiling",
	"bottom_face":"Floor"
}

var TextureSelectorScene := preload("res://addons/level_block/texture_selector_scene.tscn")

# -- foldout state for the current inspected object --
var _faces_header_added := false
var _faces_collapsed := false
var _faces_controls: Array[Control] = []

#func _can_handle(object: Object) -> bool:
	#return object is Node3D and object.has_method("refresh")

# level_block_inspector.gd
func _can_handle(object: Object) -> bool:
	# Accept MeshInstance3D or Node3D, as long as it looks like our block
	return object is Node3D \
		and object.has_method("refresh") \
		and "north_face" in object \
		and "texture_sheet" in object

# Reset per-object state
func _parse_begin(object: Object) -> void:
	_faces_header_added = false
	_faces_collapsed = false
	_faces_controls.clear()

func _parse_property(
	object: Object,
	type: int,
	property: String,
	hint: int,
	hint_text: String,
	usage: int,
	wide: bool
) -> bool:
	if property in FACES:
		# Insert the Faces header once, above the first face
		if not _faces_header_added:
			add_custom_control(_make_faces_header())
			_faces_header_added = true

		var selector: Control = TextureSelectorScene.instantiate()
		var label: String = FACE_LABELS.get(property, property)

		if "texture_sheet" in object and object.texture_sheet:
			selector.call_deferred("set_texture_sheet", object.texture_sheet, int(object.texture_size))
		selector.call_deferred("set_value", int(object.get(property)))
		selector.call_deferred("set_face_label", label)

		selector.connect("value_changed", _on_face_selected.bind(object, property))

		add_property_editor_for_multiple_properties(
			label,                     # left label in inspector
			[StringName(property)],    # properties this editor controls
			selector                   # our control
		)

		# Track control so the header can show/hide it
		_faces_controls.append(selector)
		selector.visible = not _faces_collapsed

		return true
	return false

func _on_face_selected(value: int, object: Object, face_name: String) -> void:
	if object and object.is_inside_tree():
		object.set(face_name, value)
		object.refresh()

# ---------- header builder ----------
func _make_faces_header() -> Control:
	var hb := HBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var btn := Button.new()
	btn.text = "Faces ▸" if _faces_collapsed else "Faces ▾"
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = "Show/Hide all face editors"
	hb.add_child(btn)

	btn.pressed.connect(func():
		_faces_collapsed = not _faces_collapsed
		btn.text = "Faces ▸" if _faces_collapsed else "Faces ▾"
		# Toggle visibility of all face editors we added
		for c in _faces_controls:
			if is_instance_valid(c):
				c.visible = not _faces_collapsed
	)

	return hb
