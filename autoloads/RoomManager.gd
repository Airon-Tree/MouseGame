extends Node
## Carries the Player and any held Item across rooms, spawning at a named marker.

var _carried_item: Node2D = null
var _carried_item_was_held := false
var _player: Node2D = null
var _pending_spawn: String = ""

func request_transition(target_scene_path: String, target_spawn: String, player: Node) -> void:
	_player = player as Node2D
	_pending_spawn = target_spawn

	if _player == null:
		push_error("[RoomManager] Player reference is null.")
		return

	# --- detach held item so it survives the scene swap
	_carried_item = null
	_carried_item_was_held = false
	if "held_item" in _player and _player.held_item:
		var item := _player.held_item as Node2D
		_player.held_item = null
		_carried_item = item
		_carried_item_was_held = true
		var item_global := item.global_position
		if item.get_parent(): item.get_parent().remove_child(item)
		add_child(item) # park under autoload
		item.global_position = item_global
		if item is Area2D: (item as Area2D).monitoring = false

	# --- lift player out so they persist across the scene change
	var player_global := _player.global_position
	var prev_top_level := _player.is_set_as_top_level()
	_player.set_as_top_level(true)       # preserve global transform no matter the new parent
	if _player.get_parent(): _player.get_parent().remove_child(_player)
	add_child(_player)
	_player.global_position = player_global
	_player.visible = true
	_player.set_process(true)
	_player.set_physics_process(true)

	# --- change scene and wait until it's fully switched
	var tree := get_tree()
	await _await_scene_change(tree, target_scene_path)

	# --- reinsert player into the new room
	var room := tree.current_scene
	if room == null:
		push_error("[RoomManager] No current_scene after scene change.")
		return

	if _player.get_parent(): _player.get_parent().remove_child(_player)
	room.add_child(_player)

	# restore top-level flag now that it lives under the room again
	_player.set_as_top_level(prev_top_level)

	# move player to the spawn marker (if provided)
	var target_spawn_pos := _resolve_spawn_position(_pending_spawn)
	_player.global_position = target_spawn_pos

	# --- restore carried item
	if _carried_item:
		if _carried_item_was_held:
			var hold_point := _player.get_node_or_null("HoldPoint")
			if _carried_item.has_method("on_pickup") and hold_point:
				_carried_item.call("on_pickup", _player, hold_point)
			else:
				# fallback parenting
				if _carried_item.get_parent(): _carried_item.get_parent().remove_child(_carried_item)
				_player.add_child(_carried_item)
				if hold_point: _carried_item.position = hold_point.position
		else:
			if _carried_item.get_parent(): _carried_item.get_parent().remove_child(_carried_item)
			room.add_child(_carried_item)
			_carried_item.global_position = _player.global_position

		if _carried_item is Area2D:
			(_carried_item as Area2D).monitoring = true

	# cleanup
	_carried_item = null
	_carried_item_was_held = false
	_pending_spawn = ""

func _await_scene_change(tree: SceneTree, target_scene_path: String) -> void:
	tree.change_scene_to_file(target_scene_path)
	await tree.scene_changed
	await tree.process_frame   # ensures all nodes in new scene finish _ready()

func _resolve_spawn_position(spawn_name: String) -> Vector2:
	var room := get_tree().current_scene
	if room == null:
		return Vector2.ZERO
	if spawn_name == "" or spawn_name == null:
		return room.get_global_transform().origin

	var spawn := room.find_child(spawn_name, true, false)
	if spawn and spawn is Node2D:
		return (spawn as Node2D).global_position

	# fallback: origin of the room if the marker name was wrong
	push_warning("[RoomManager] Spawn marker '%s' not found. Using room origin." % spawn_name)
	return room.get_global_transform().origin
