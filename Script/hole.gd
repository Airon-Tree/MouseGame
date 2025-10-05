extends Area2D

@export var debug_print: bool = false
@export var item_group_name: String = "pickup"   # items are in this group
@export var required_score: int = 75

var _cooldown := false
var _player_in := false

func _ready() -> void:

	monitoring = true

	# Connect signals
	if not is_connected("area_entered", Callable(self, "_on_area_entered")):
		connect("area_entered", Callable(self, "_on_area_entered"))
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	if not is_connected("body_exited", Callable(self, "_on_body_exited")):
		connect("body_exited", Callable(self, "_on_body_exited"))

	# must have an enabled CollisionShape2D with a shape
	#var has_shape := false
	#for child in get_children():
		#if child is CollisionShape2D and not child.disabled and child.shape:
			#has_shape = true
			#break
	#if not has_shape:
		#push_warning("Hole has no enabled CollisionShape2D with a shape. It cannot overlap items.")

func _physics_process(_delta: float) -> void:

	if _cooldown:
		return
	for a in get_overlapping_areas():
		_try_consume(a)
	for b in get_overlapping_bodies():
		_try_consume(b)
	if _player_in and Input.is_action_just_pressed("win"):
		var player := get_tree().get_first_node_in_group("player")
		if player and "score" in player and int(player.score) >= required_score:
			_do_win(player)
		elif debug_print:
			var cur := int(player.score) if player and ("score" in player) else -1
			print("[Hole] Need ", required_score, " to win. Current: ", cur)

func _on_area_entered(a: Area2D) -> void:
	_try_consume(a)

func _on_body_entered(b: Node) -> void:
	_try_consume(b)
	if b and b.is_in_group("player"):
		_player_in = true

func _on_body_exited(b: Node) -> void:
	if b and b.is_in_group("player"):
		_player_in = false

func _try_consume(node: Node) -> void:
	if _cooldown or node == null:
		return
	# Only our pickup items
	if not node.is_in_group(item_group_name):
		return
	# Ignore while held / under player
	if node.has_method("is_currently_held") and node.call("is_currently_held"):
		return
	if _has_player_ancestor(node):
		return

	# Award points
	var points := 0
	if node.has_method("get_score_value"):
		points = int(node.call("get_score_value"))
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_score"):
		player.call("add_score", points)
		if debug_print: print("[Hole] +", points, " from ", node.name)

	# Remove the item
	_cooldown = true
	if "queue_free" in node:
		node.queue_free()
	await get_tree().process_frame
	_cooldown = false

func _do_win(player: Node) -> void:
	# Snap player to hole center (optional), then hide / disable
	if player is Node2D:
		player.global_position = global_position
	# hide and stop player
	if "visible" in player:
		player.visible = false
	player.set_process(false)
	player.set_physics_process(false)

	# Show win UI & play music
	var win_ui := get_tree().get_first_node_in_group("win_ui")
	if not win_ui:
		# fallback: try finding any CanvasLayer named WinUI
		win_ui = get_tree().root.find_child("WinUI", true, false)
	if win_ui and win_ui.has_method("show_win"):
		var final_score := int(player.score) if ("score" in player) else 0
		win_ui.call("show_win", final_score)
	elif debug_print:
		print("[Hole] WinUI not found or show_win() missing. Add WinUI.tscn and put it in group 'win_ui'.")

func _has_player_ancestor(n: Node) -> bool:
	var cur := n.get_parent()
	while cur:
		if cur.is_in_group("player"):
			return true
		cur = cur.get_parent()
	return false
