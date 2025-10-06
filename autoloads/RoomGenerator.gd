extends Node
# class_name RoomGenerator

# at top:
var rooms_root: Node2D = null          # parent for all generated rooms (easy to wipe)
var is_booted: bool = false            # guard to avoid double-boot


@export var default_template: PackedScene

@export var template_pool: Array[PackedScene] = []   # other room templates to pick from
@export var center_template: PackedScene             # template for the center (start) room
@export var reuse_templates: bool = true             # allow repeating same template


const ENTRY_OFFSET: float = 64.0  # how far to push the player inside the target room

## Grid config
const GRID_SIZE: Vector2i = Vector2i(3, 3)        # 3x3
const CELL_SIZE: Vector2 = Vector2(1280, 720)     # room spacing in pixels

## Door node names in Room.tscn
const DIRS: Dictionary = {                        # Dictionary[Vector2i, String]
	Vector2i(0, -1): "DoorUp",
	Vector2i(0,  1): "DoorDown",
	Vector2i(-1, 0): "DoorLeft",
	Vector2i( 1, 0): "DoorRight",
}

## All instantiated rooms by grid coord
var grid: Dictionary = {}                         # Dictionary[Vector2i -> Node2D]
var current_room: Node2D = null

func _ready() -> void:
	# do nothing here; Main will drive the boot sequence
	pass

func boot() -> void:
	# call this from Main after setting default_template
	_ensure_rooms_root()
	_clear_rooms()                # <<< important: wipe old generation

	# call this from Main after setting default_template
	# Build the 3x3 grid as soon as the game starts
	generate_rooms()
	# Wait one frame so the Player (spawned by Main) is present in the tree
	await get_tree().process_frame
	_place_player_at_start()
	
func _ensure_rooms_root() -> void:
	# Create or find the container that holds all rooms
	if rooms_root == null or not is_instance_valid(rooms_root):
		rooms_root = Node2D.new()
		rooms_root.name = "RoomsRoot"
		add_child(rooms_root)

func _clear_rooms() -> void:
	# Remove previously generated rooms so we don't stack them
	if rooms_root and is_instance_valid(rooms_root):
		for c in rooms_root.get_children():
			c.queue_free()
	grid.clear()


## Put the player at the starting room (center by default).
## If the player already exists (spawned by Main), we only move it.
func _place_player_at_start() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	# Choose the center room as the starting room
	var start_coord: Vector2i = Vector2i(1, 1)
	var room: Node2D = grid.get(start_coord, null) as Node2D
	if room == null:
		return
	print("[Gen] Start in Room_%d_%d" % [start_coord.x, start_coord.y]) # debug

	# Try to place near the bottom door's Entry marker if present; else use room center-ish
	var door_down: Node = room.get_node_or_null("DoorDown")
	var entry: Node2D = null
	if door_down:
		entry = door_down.get_node_or_null("Entry") as Node2D

	if entry:
		player.global_position = entry.global_position + Vector2(0, -ENTRY_OFFSET)
	else:
		player.global_position = room.global_position + Vector2(0, 100)

	current_room = room

## --- Create a 3x3 set of Room.tscn instances ---
func generate_rooms() -> void:
	var room_scene: PackedScene = preload("res://Scenes/Room.tscn")
	grid.clear()
	for y in range(GRID_SIZE.y):
		for x in range(GRID_SIZE.x):
			var room: Node2D = room_scene.instantiate() as Node2D
			# Helpful name for debugging in the Remote tree
			room.name = "Room_%d_%d" % [x, y]
			# Store grid coord on the room for robust lookup later
			room.set_meta("coord", Vector2i(x, y))

			rooms_root.add_child(room)      # keep rooms under the container

			room.position = Vector2(x, y) * CELL_SIZE
			var coord: Vector2i = Vector2i(x, y)
			grid[coord] = room
			_trim_doors(room, coord)
			# insert template if set
			# insert template if set
			var anchor := room.get_node_or_null("Anchor") as Node
			if anchor:
				# clear old children if you ever re-generate
				# while anchor.get_child_count() > 0: anchor.get_child(0).queue_free()

				var tpl: PackedScene = null
				if coord == Vector2i(1, 1) and center_template:
					# center room uses the start template
					tpl = center_template
				elif default_template:
					# keep backward-compat: if default_template set, use it for all rooms
					tpl = default_template
				elif template_pool.size() > 0:
					tpl = _pick_random_template_for(coord)

				if tpl:
					anchor.add_child(tpl.instantiate())


	# Cache center room (optional)
	current_room = grid.get(Vector2i(1, 1), null)

## --- Remove doors that go outside the grid; set door.direction on valid ones ---
func _trim_doors(room: Node2D, coord: Vector2i) -> void:
	for dir_key in DIRS.keys():
		var dir: Vector2i = dir_key
		var door_path: String = DIRS[dir]
		var door: Node = room.get_node_or_null(door_path)
		if door == null:
			continue

		var neighbor: Vector2i = coord + dir
		var out_of_bounds: bool = (
			neighbor.x < 0 or neighbor.y < 0 or
			neighbor.x >= GRID_SIZE.x or neighbor.y >= GRID_SIZE.y
		)

		if out_of_bounds:
			door.queue_free()
		else:
			door.set("direction", dir)

## --- Called by Door.gd when player presses interact on a door ---
func request_room_switch(door: Node, player: Node2D) -> void:
	var room_coord: Vector2i = _find_room_coord(door)
	print("[Gen] From", room_coord)  # debug
	if room_coord == Vector2i(-1, -1):
		push_warning("Room not found for this door.")
		return

	var door_dir: Vector2i = door.get("direction") as Vector2i
	var target_coord: Vector2i = room_coord + door_dir
	print("[Gen] To", target_coord)  # debug
	if not grid.has(target_coord):
		push_warning("No room exists in that direction.")
		return

	var target_room: Node2D = grid[target_coord] as Node2D
	var opp_dir: Vector2i = -door_dir
	var target_door_name: String = DIRS.get(opp_dir, "")
	var target_door: Node = target_room.get_node_or_null(target_door_name)

	# Prefer the Entry marker; fallback to door/global room pos
	var spawn: Node2D = null
	if target_door:
		spawn = (target_door.get_node_or_null("Entry") as Node2D)
	else:
		push_warning("[Gen] Opposite door not found in Room_%d_%d: %s"
			% [target_coord.x, target_coord.y, target_door_name])

	# Push the player inward so they don't sit inside the door collider
	var inward: Vector2 = Vector2(float(door_dir.x), float(door_dir.y)) * ENTRY_OFFSET

	if spawn:
		player.global_position = spawn.global_position + inward
	elif target_door:
		player.global_position = (target_door as Node2D).global_position + inward
	else:
		player.global_position = target_room.global_position + Vector2(0, 100)

	current_room = target_room

## --- Utility: find which grid room contains this door ---
func _find_room_coord(door: Node) -> Vector2i:
	# Primary: use the room instance that owns this door and read its coord metadata
	var room_node := door.get_owner()
	if room_node and room_node.has_meta("coord"):
		return room_node.get_meta("coord") as Vector2i

	# Fallback: traverse the grid and check ancestry (should rarely be needed)
	for k in grid.keys():
		var coord: Vector2i = k
		var room: Node = grid[coord]
		if room and room.is_ancestor_of(door):
			return coord
	return Vector2i(-1, -1)

# Pick a random template from the pool (optionally non-repeating).
# You can make this coord-dependent (see RNG section below) to get stable results.
var _pool_cache: Array[PackedScene] = []
func _pick_random_template_for(coord: Vector2i) -> PackedScene:
	if reuse_templates:
		return template_pool[randi() % template_pool.size()]
	# non-repeating across the whole 3x3
	if _pool_cache.is_empty():
		_pool_cache = template_pool.duplicate()
		_pool_cache.shuffle()
	return _pool_cache.pop_back()
