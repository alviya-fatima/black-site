extends Sprite3D

@export var bob_height: float = 0.08
@export var bob_speed: float = 0.55
@export var fade_amount: float = 0.04

var _origin: Vector3
var _time: float = 0.0
var _base_alpha: float = 0.0


func _ready() -> void:
	_origin = position
	_time = randf() * 20.0
	_base_alpha = modulate.a
	if get_tree().get_nodes_in_group("ghosts").size() < 3:
		add_to_group("ghosts")


func _process(delta: float) -> void:
	_time += delta
	position = _origin + Vector3(sin(_time * 0.17) * 0.05, sin(_time * bob_speed) * bob_height, cos(_time * 0.13) * 0.04)
	modulate.a = _base_alpha * (0.7 + 0.3 * sin(_time * 0.4)) * (1.0 - fade_amount)
