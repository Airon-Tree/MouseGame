extends Node2D

var score: int
var high_score= 0
var target_score: int
var prev_score: int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Timer.start()
	target_score = _get_target_score()
	
	
	
	
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


func _on_timer_timeout() -> void:
	if(score < target_score):
		print("Game Over")
