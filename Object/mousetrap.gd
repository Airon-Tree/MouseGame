extends Area2D

func _ready() -> void:
	# Connect once when ready
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("mouse"):
		print("ded")
		if body.has_method("die"):
			body.die()
		else:
			body.queue_free()
