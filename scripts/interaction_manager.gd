extends Node

signal prompt_changed(text: String)

var player: CharacterBody3D
var current: Node = null
var _last_prompt: String = ""
var _cooldown: float = 0.0
var _scan_timer: float = 0.0


func _ready() -> void:
	player = get_parent() as CharacterBody3D
	set_process(true)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_scan_timer -= delta
	if _scan_timer > 0.0:
		if _cooldown <= 0.0 and Input.is_action_just_pressed("interact") and current != null:
			_try_interact()
		return
	_scan_timer = 0.06

	if player == null:
		return
	var allowed: bool = bool(player.get("control_enabled"))
	if not allowed:
		_set_current(null)
		return

	var best: Node = null
	var best_dist: float = 9999.0
	for node in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		if node is Node3D:
			var n3 := node as Node3D
			var delta_v := n3.global_position - player.global_position
			var flat := Vector2(delta_v.x, delta_v.z).length()
			if absf(delta_v.y) > 2.2:
				continue
			if flat < best_dist:
				if node.has_method("get_prompt"):
					var prompt: String = node.get_prompt(player)
					if not prompt.is_empty():
						best = node
						best_dist = flat
	if best_dist > 2.35:
		best = null
	_set_current(best)

	if _cooldown <= 0.0 and Input.is_action_just_pressed("interact") and current != null:
		_try_interact()


func _set_current(node: Node) -> void:
	if current == node:
		_update_prompt()
		return
	if current != null and is_instance_valid(current) and current.has_method("set_highlight"):
		current.set_highlight(false)
	current = node
	if current != null and current.has_method("set_highlight"):
		current.set_highlight(true)
	_update_prompt()


func _update_prompt() -> void:
	var text := ""
	if current != null and is_instance_valid(current) and current.has_method("get_prompt"):
		text = str(current.get_prompt(player))
	if text != _last_prompt:
		_last_prompt = text
		prompt_changed.emit(text)


func _try_interact() -> void:
	if current == null or not is_instance_valid(current):
		return
	_cooldown = 0.25
	if current.has_method("interact"):
		AudioManager.play_sfx("interact", -16.0, 0.03)
		current.interact(player)
		_update_prompt()


func suppress_for(seconds: float) -> void:
	_cooldown = maxf(_cooldown, seconds)
