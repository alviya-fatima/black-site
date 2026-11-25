extends OmniLight3D

@export var base_energy: float = 1.2
@export var flicker_strength: float = 0.22
@export var flicker_seed: float = 0.0
@export var flicker_speed: float = 1.0
@export var dropout_chance: float = 0.0025

var _time: float = 0.0
var _dropout: float = 0.0


func _ready() -> void:
	_time = flicker_seed
	if flicker_seed == 0.0:
		_time = randf() * 100.0


func _process(delta: float) -> void:
	_time += delta * flicker_speed
	var n := sin(_time * 7.13) * 0.45 + sin(_time * 17.7 + 1.3) * 0.22 + sin(_time * 31.1) * 0.08
	var wobble: float = 1.0 + n * flicker_strength * 0.33
	if _dropout > 0.0:
		_dropout -= delta
		wobble *= 0.14
	elif randf() < dropout_chance * delta * 60.0:
		_dropout = randf_range(0.04, 0.16)
	light_energy = base_energy * maxf(0.0, wobble)
