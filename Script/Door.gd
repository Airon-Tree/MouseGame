extends Area2D

@export_file("*.tscn") var target_scene: String     # res://scenes/level_0.tscn
@export var target_spawn: String = "spawn_from_main" # name of a Marker2D in the target scene

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
	if _player_inside and Input.is_action_just_pressed("interact"):
		var player := get_tree().get_first_node_in_group("player")
		if player and target_scene != "":
			RoomManager.request_transition(target_scene, target_spawn, player)
