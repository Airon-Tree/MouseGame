extends CanvasLayer

@onready var label: Label = $"MarginContainer/ScoreLabel"

func _ready() -> void:
	_set_score_text(0)

	# Try to connect immediately if a player already exists
	var p := get_tree().get_first_node_in_group("player")
	if p:
		_connect_player(p)

	# Fallback: listen for nodes being added (in case player appears later)
	if not get_tree().is_connected("node_added", Callable(self, "_on_node_added")):
		get_tree().connect("node_added", Callable(self, "_on_node_added"))

# Public entry called from Main so we never miss the connection timing.
func connect_player_from_main(p: Node) -> void:
	_connect_player(p)
	if "score" in p:
		_set_score_text(int(p.score))

func _on_node_added(n: Node) -> void:
	# Warning: node_added fires before that node's _ready, so group might not be set yet.
	# We still try to connect, and Main.connect_player_from_main() is our reliable path.
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
