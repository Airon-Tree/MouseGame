extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Timer.start()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var rounded = "%.2f" % $Timer.time_left
	$Label.text = str(rounded)


func _on_timer_timeout() -> void:
	print("Game Over")
