extends CanvasLayer

@onready var lose_label: Label = $CenterContainer/WinLabel

func show_lose(final_score: int) -> void:
	visible = true
	if lose_label:
		lose_label.text = "You Lose!\nScore: %d \nPress Q to Restart!" % final_score
	
