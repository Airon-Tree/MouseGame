extends Node2D

var score: int
var high_score= 0
var target_score = 200
var prev_score: int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Timer.start()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var rounded = "%.2f" % $Timer.time_left
	$TimerLabel.text = str(rounded)
	$ScoreLabel.text = str(score)


func _on_timer_timeout() -> void:
	if(score < target_score):
		print("Game Over")
