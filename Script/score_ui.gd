extends CanvasLayer

@onready var label: Label = $"MarginContainer/ScoreLabel"

func _ready() -> void:

	_set_score_text(0)

	# Connect to an existing player
	var p := get_tree().get_first_node_in_group("player")
	if p:
		_connect_player(p)

	get_tree().connect("node_added", Callable(self, "_on_node_added"))

func _on_node_added(n: Node) -> void:
	if n.is_in_group("player"):
		_connect_player(n)

		if "score" in n:
			_set_score_text(int(n.score))

func _connect_player(p: Node) -> void:
	if not p.is_connected("score_changed", Callable(self, "_on_score_changed")):
		p.connect("score_changed", Callable(self, "_on_score_changed"), CONNECT_DEFERRED)

func _on_score_changed(new_score: int) -> void:
	_set_score_text(new_score)

func _set_score_text(s: int) -> void:
	if label:
		label.text = "Score: %d" % s
