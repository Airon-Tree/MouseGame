extends Area2D

#@export_file("*.tscn") var target_scene: String     # res://scenes/level_0.tscn
#@export var target_spawn: String = "spawn_from_main" # name of a Marker2D in the target scene


## Direction relative to this room: up=(0,-1), down=(0,1), left=(-1,0), right=(1,0)
@export var direction: Vector2i = Vector2i(0, -1)

var _player_inside := false

func _ready() -> void:
	monitoring = true
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	if not is_connected("body_exited", Callable(self, "_on_body_exited")):
		connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(b: Node) -> void:
	if b.is_in_group("player"):
		_player_inside = true

func _on_body_exited(b: Node) -> void:
	if b.is_in_group("player"):
		_player_inside = false

func _physics_process(_delta: float) -> void:
	# Interact to switch rooms locally (no scene change)
	if _player_inside and Input.is_action_just_pressed("interact"):
		var player := get_tree().get_first_node_in_group("player")
		if player:
			# Works because RoomGenerator is now an Autoload singleton
			RoomGenerator.request_room_switch(self, player)
