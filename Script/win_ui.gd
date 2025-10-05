extends CanvasLayer

@onready var win_label: Label = $CenterContainer/WinLabel
@onready var win_music: AudioStreamPlayer = $WinMusic

func show_win(final_score: int) -> void:
	visible = true
	if win_label:
		win_label.text = "You Win!\nScore: %d \nPress Q to Restart!" % final_score
	if win_music and win_music.stream:
		win_music.play()
		
		
