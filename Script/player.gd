extends CharacterBody2D

@export var move_speed: float = 170.0
@export var interact_area_path: NodePath = ^"InteractArea"
@export var hold_point_path: NodePath = ^"HoldPoint"

@onready var interact_area: Area2D = _fetch_interact_area()
@onready var hold_point: Marker2D = _fetch_hold_point()

var held_item: Node2D = null

func _physics_process(_delta: float) -> void:
	# Movement
	var dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if dir.length() > 1.0:
		dir = dir.normalized()
	velocity = dir * move_speed
	move_and_slide()

	# Toggle pick/drop on F
	if Input.is_action_just_pressed("pickup"):
		if held_item:
			_drop_item()
		else:
			var target := _get_closest_item_in_range()
			if target:
				_pickup_item(target)

func _fetch_interact_area() -> Area2D:
	var node: Area2D = null
	if interact_area_path != NodePath():
		node = get_node_or_null(interact_area_path) as Area2D
	if node == null:
		node = $InteractArea if has_node("InteractArea") else null
	if node == null:
		push_error('Player: InteractArea not found. Add an Area2D named "InteractArea" as a child.')
	return node

func _fetch_hold_point() -> Marker2D:
	var node: Marker2D = null
	if hold_point_path != NodePath():
		node = get_node_or_null(hold_point_path) as Marker2D
	if node == null:
		node = $HoldPoint if has_node("HoldPoint") else null
	# create one for testing
	if node == null:
		node = Marker2D.new()
		node.name = "HoldPoint"
		add_child(node)
		node.position = Vector2(0, -32)
		print('Player: HoldPoint was missing, created one at (0, -32).')
	return node

func _get_closest_item_in_range() -> Node2D:
	if interact_area == null:
		return null
	var best: Node2D = null
	var best_d2 := INF

	for a in interact_area.get_overlapping_areas():
		if a is Node2D and _is_item_pickable(a):
			var d2 := global_position.distance_squared_to(a.global_position)
			if d2 < best_d2:
				best = a
				best_d2 = d2

	for b in interact_area.get_overlapping_bodies():
		if b is Node2D and _is_item_pickable(b):
			var d2 := global_position.distance_squared_to(b.global_position)
			if d2 < best_d2:
				best = b
				best_d2 = d2

	return best

func _is_item_pickable(n: Node) -> bool:
	if n.has_method("is_item_pickable"):
		return n.call("is_item_pickable")
	return n.is_in_group("pickup")

func _pickup_item(item: Node2D) -> void:
	if item.has_method("on_pickup"):
		item.call("on_pickup", self, hold_point)
	else:
		_generic_disable_collisions(item)
		if item.get_parent():
			item.get_parent().remove_child(item)
		add_child(item)
		item.position = hold_point.position
		item.z_index = max(z_index + 1, 1)
	held_item = item

func _drop_item() -> void:
	if held_item == null:
		return
	var item := held_item
	held_item = null

	if item.has_method("on_drop"):
		item.call("on_drop", hold_point.global_position + Vector2(0, 12))
		return

	var root := get_tree().current_scene
	remove_child(item)
	root.add_child(item)
	item.global_position = hold_point.global_position + Vector2(0, 12)
	_generic_enable_collisions(item)

func _generic_disable_collisions(node: Node) -> void:
	if node is Area2D:
		node.monitoring = false
	elif node is RigidBody2D:
		node.freeze = true
		node.sleeping = true
		node.linear_velocity = Vector2.ZERO
		node.angular_velocity = 0.0
	elif node.has_node("CollisionShape2D"):
		var cs := node.get_node("CollisionShape2D") as CollisionShape2D
		if cs:
			cs.disabled = true

func _generic_enable_collisions(node: Node) -> void:
	if node is Area2D:
		node.monitoring = true
	elif node is RigidBody2D:
		node.freeze = false
		node.sleeping = false
	elif node.has_node("CollisionShape2D"):
		var cs := node.get_node("CollisionShape2D") as CollisionShape2D
		if cs:
			cs.disabled = false
