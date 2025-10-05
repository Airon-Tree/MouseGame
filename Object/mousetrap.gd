extends Area2D

func _ready() -> void:
	# Connect once when ready
	connect("body_entered", Callable(self, "_on_body_entered"))
	


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var lose_ui := get_tree().get_first_node_in_group("lose_ui")
		if not lose_ui:
			lose_ui = get_tree().root.find_child("LoseUI", true, false)
		if lose_ui and lose_ui.has_method("show_lose"):
			lose_ui.call("show_lose", 0)
		print("ded")
		if body.has_method("die"):
			body.die()
		else:
			body.queue_free()
			


			
