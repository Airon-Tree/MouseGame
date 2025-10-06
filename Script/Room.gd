extends Node2D
class_name Room

## Optional bitmask if you later group templates by connectivity
const U:=1; const D:=2; const L:=4; const R:=8

@onready var anchor: Node2D = $Anchor
@onready var door_up:    Node = $DoorUp
@onready var door_down:  Node = $DoorDown
@onready var door_left:  Node = $DoorLeft
@onready var door_right: Node = $DoorRight

var coords: Vector2i = Vector2i.ZERO
var door_mask: int = 0

func apply_door_mask(mask:int) -> void:
	door_mask = mask
	if is_instance_valid(door_up):    door_up.visible    = bool(mask & U)
	if is_instance_valid(door_down):  door_down.visible  = bool(mask & D)
	if is_instance_valid(door_left):  door_left.visible  = bool(mask & L)
	if is_instance_valid(door_right): door_right.visible = bool(mask & R)

func set_template(scene: PackedScene) -> void:
	if anchor and anchor.get_child_count() > 0:
		anchor.get_child(0).queue_free()
	if scene and anchor:
		anchor.add_child(scene.instantiate())
