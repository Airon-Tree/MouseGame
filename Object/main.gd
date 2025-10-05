extends Node2D
@export var player_scene: PackedScene
@export var initial_spawn_name: String = "spawn_start"  # name of a Marker2D in main.tscn

var score: int
var high_score= 0
var target_score: int
var prev_score: int
var timerunningout = false
var txtcolorchange = false

@onready var timer: Timer = $Timer
@onready var maintheme: AudioStreamPlayer2D = $MainTheme
@onready var timerend: AudioStreamPlayer2D = $TimerEnding


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.start()
	maintheme.play()
	target_score = _get_target_score()
	# If there isn't already a Player in the tree (fresh boot), spawn one.
	var existing := get_tree().get_first_node_in_group("player")
	if existing == null:
		if player_scene == null:
			push_error("[Main] player_scene is not set. Drag Player.tscn into Main's 'player_scene' export.")
			return
		var player := player_scene.instantiate()
		add_child(player)

		# Position at the spawn marker if present
		var spawn := find_child(initial_spawn_name, true, false)
		if spawn is Node2D:
			player.global_position = (spawn as Node2D).global_position
		else:
			push_warning("[Main] Spawn marker '%s' not found; placing Player at (0,0)." % initial_spawn_name)
			player.position = Vector2.ZERO

	# Make sure the player's Camera2D is active (if you added one under the Player)
		var cam := player.get_node_or_null("Camera2D")
		if cam and cam is Camera2D:
			(cam as Camera2D).current = true
	
	
func _get_target_score() -> int:
	var target := 0
	for pickup in get_tree().get_nodes_in_group("cheese"):
		if pickup.has_method("get_score_value"):
			target += pickup.get_score_value()
	return target - (target / 10)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var rounded = "%.2f" % $Timer.time_left
	$TimerLabel.text = str(rounded)
	$ScoreLabel.text = "Target Score: " + str(target_score)
	
	if timer.time_left <= 30.0 and not timerunningout:
		_switch_music()
		
	if timer.time_left <= 30.0 and not txtcolorchange:
		_change_label_color(Color.RED)
	if Input.is_key_pressed(KEY_Q):
		_restart_game()
		
		
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
	txtcolorchange = true
	$TimerLabel.add_theme_color_override("font_color", color)
	
	
func _show_lose_ui(final_score: int) -> void:
	var lose_ui := get_tree().get_first_node_in_group("lose_ui")
	if not lose_ui:
		lose_ui = get_tree().root.find_child("LoseUI", true, false)
	if lose_ui and lose_ui.has_method("show_lose"):
		lose_ui.call("show_lose", final_score)
	else:
		print("[Game] LoseUI not found or show_lose() missing.")

func _on_timer_timeout() -> void:
	if(score < target_score):
		print("Game Over")
		_show_lose_ui(score)
		
