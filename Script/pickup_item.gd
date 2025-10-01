extends Area2D

@export var float_when_held: bool = true
@export var held_z_boost: int = 1

var _pickable := true
var _original_z := 0

func _ready() -> void:
	add_to_group("pickup")

func is_item_pickable() -> bool:
	return _pickable

func on_pickup(holder: Node2D, hold_point: Marker2D) -> void:
	_pickable = false
	_original_z = z_index
	monitoring = false

	var p := get_parent()
	if p:
		p.remove_child(self)
	holder.add_child(self)

	position = hold_point.position
	z_index = max(holder.z_index + held_z_boost, 1)

	if float_when_held:
		var t := create_tween()
		t.tween_property(self, "position:y", position.y - 2.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func on_drop(drop_pos: Vector2) -> void:
	var root := get_tree().current_scene
	if get_parent():
		get_parent().remove_child(self)
	root.add_child(self)

	global_position = drop_pos
	z_index = _original_z
	monitoring = true
	_pickable = true
