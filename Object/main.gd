extends Node2D
@export var player_scene: PackedScene
@export var initial_spawn_name: String = "spawn_start"  # name of a Marker2D in main.tscn

var score: int
var high_score = 0
var target_score: int
var prev_score: int
var timerunningout := false
var txtcolorchange := false

@onready var timer_label: Label = $"ScoreUI/TimerLabel"
@onready var target_score_label: Label = $"ScoreUI/TargetScoreLabel"

@onready var timer: Timer = $Timer
@onready var maintheme: AudioStreamPlayer2D = $MainTheme
@onready var timerend: AudioStreamPlayer2D = $TimerEnding

func _ready() -> void:
	timer.start()
	maintheme.play()

	# If there isn't already a Player in the tree (fresh boot), spawn one.
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		if player_scene == null:
			push_error("[Main] player_scene is not set. Drag Player.tscn into Main's 'player_scene' export.")
			return
		player = player_scene.instantiate()
		add_child(player)

		# Position at the spawn marker if present
		var spawn := find_child(initial_spawn_name, true, false)
		if spawn is Node2D:
			player.global_position = (spawn as Node2D).global_position
		else:
			push_warning("[Main] Spawn marker '%s' not found; placing Player at (0,0)." % initial_spawn_name)
			player.position = Vector2.ZERO

		# Ensure the player's Camera2D exists and is current
		var cam := player.get_node_or_null("Camera2D")
		if cam == null:
			cam = Camera2D.new()
			cam.name = "Camera2D"
			cam.position_smoothing_enabled = true
			cam.position_smoothing_speed = 10.0
			player.add_child(cam)
		var world_w := RoomGenerator.CELL_SIZE.x * RoomGenerator.GRID_SIZE.x
		var world_h := RoomGenerator.CELL_SIZE.y * RoomGenerator.GRID_SIZE.y
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = int(world_w)
		cam.limit_bottom = int(world_h)
		(cam as Camera2D).enabled = true
		(cam as Camera2D).make_current()

	# Hand the player reference to the ScoreUI so it can connect the signal reliably
	var score_ui := $ScoreUI
	if score_ui and score_ui.has_method("connect_player_from_main"):
		score_ui.call("connect_player_from_main", player)

	# --- IMPORTANT: build rooms first, then compute the target score ---
	RoomGenerator.boot()               # generate the 3×3 and place the player
	await get_tree().process_frame     # wait one frame so templates are in the tree
	_update_target_score_label()       # compute and show "Target Score"

func _process(_delta: float) -> void:
	var rounded = "%.2f" % $Timer.time_left
	timer_label.text = str(rounded)
	# target_score_label is updated once; no need to recompute here

	if timer.time_left <= 30.0 and not timerunningout:
		_switch_music()
	if timer.time_left <= 30.0 and not txtcolorchange:
		_change_label_color(Color.RED)
	if Input.is_key_pressed(KEY_Q):
		_restart_game()

# Sum all cheese values (group "cheese"), then reduce by 10%
func _get_target_score() -> int:
	var target := 0
	for pickup in get_tree().get_nodes_in_group("cheese"):
		if pickup.has_method("get_score_value"):
			target += pickup.get_score_value()
	return target - (target / 2)

# Update the UI label once rooms/templates exist
func _update_target_score_label() -> void:
	target_score = _get_target_score()
	if target_score_label:
		target_score_label.text = "Target Score: %d" % target_score


func _restart_game() -> void:
	get_tree().reload_current_scene()

func _switch_music():
	timerunningout = true
	if maintheme.playing:
		maintheme.stop()
	timerend.play()

func stop_bgm() -> void:
	if maintheme and maintheme.playing:
		maintheme.stop()
	if timerend and timerend.playing:
		timerend.stop()

func _change_label_color(color: Color) -> void:
	# Use the cached timer_label resolved from ScoreUI
	txtcolorchange = true
	if timer_label:
		timer_label.add_theme_color_override("font_color", color)

func _show_lose_ui(final_score: int) -> void:
	var lose_ui := get_tree().get_first_node_in_group("lose_ui")
	if not lose_ui:
		lose_ui = get_tree().root.find_child("LoseUI", true, false)
	if lose_ui and lose_ui.has_method("show_lose"):
		lose_ui.call("show_lose", final_score)
	else:
		print("[Game] LoseUI not found or show_lose() missing.")

func _on_timer_timeout() -> void:
	if score < target_score:
		print("Game Over")
		_show_lose_ui(score)
