extends Area2D


@export_range(0.1, 1.0, 0.01) var speed_multiplier: float = 0.75
@export var score_value: int = 25
# small=10 (0.90), cheese=25 (0.75), big=50 (0.55)


@export var float_when_held: bool = true
@export var held_z_offset_below_player: int = 1

var _pickable := true
var _held := false
var _original_z := 0
var _original_z_as_relative := true

func _ready() -> void:
	add_to_group("pickup")

func is_item_pickable() -> bool: return _pickable
func is_currently_held() -> bool: return _held
func get_carry_speed_multiplier() -> float: return speed_multiplier
func get_score_value() -> int: return score_value

# holder: Player; hold_point: Marker2D on the player
func on_pickup(holder: Node2D, hold_point: Marker2D) -> void:
	if self.is_ancestor_of(holder):
		push_warning("Item is an ancestor of Player. Fix Main.tscn: make Player and items siblings.")
		return

	_pickable = false
	_held = true   # mark as held

	_original_z = z_index
	_original_z_as_relative = z_as_relative

	# Follow the player
	var p := get_parent()
	if p: p.remove_child(self)
	holder.add_child(self)
	position = hold_point.position

	# Draw behind player's sprite
	var player_sprite := holder.get_node_or_null("Sprite2D") as Sprite2D
	if player_sprite:
		player_sprite.z_as_relative = false
		player_sprite.z_index = max(player_sprite.z_index, 100)
		z_as_relative = false
		z_index = player_sprite.z_index - held_z_offset_below_player

	# No Area2D to monitor anything while held
	monitoring = false

	if float_when_held:
		var t := create_tween()
		t.tween_property(self, "position:y", position.y - 2.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func on_drop(drop_pos: Vector2) -> void:
	# Return to world
	var root := get_tree().current_scene
	if get_parent(): get_parent().remove_child(self)
	root.add_child(self)

	global_position = drop_pos

	# Restore draw order
	z_as_relative = _original_z_as_relative
	z_index = _original_z

	# Now it is a free item again
	monitoring = true
	_pickable = true
	_held = false   #mark as NOT held
