extends Interactable

var door_id: String = ""
var display_name: String = "Door"
var kind: String = "normal"
var required_item: String = ""
var ending_id: int = 0
var width: float = 1.78
var height: float = 2.16
var hinge_left: bool = true
var plate_text: String = ""
var style: String = "wood"

var unlocked: bool = false
var is_open: bool = false

var _pivot: Node3D
var _body: StaticBody3D
var _open_angle: float
var _opening: bool = false
var _last_player: Node

var _wood: StandardMaterial3D
var _wood_dark: StandardMaterial3D
var _metal: StandardMaterial3D
var _black: StandardMaterial3D
var _glass: StandardMaterial3D
var _steel: StandardMaterial3D
var _lamp_red: StandardMaterial3D
var _lamp_green: StandardMaterial3D
var _lamp_white: StandardMaterial3D


func setup(config: Dictionary) -> void:
	door_id = str(config.get("id", "door"))
	display_name = str(config.get("name", "Door"))
	kind = str(config.get("kind", "normal"))
	required_item = str(config.get("required_item", ""))
	ending_id = int(config.get("ending_id", 0))
	width = float(config.get("width", 1.78))
	height = float(config.get("height", 2.16))
	hinge_left = bool(config.get("hinge_left", true))
	plate_text = str(config.get("plate", ""))
	style = str(config.get("style", "wood"))


func _ready() -> void:
	super._ready()
	_make_materials()
	if kind == "keypad" and GameState.has_flag("security_unlocked"):
		unlocked = true
	if GameState.has_flag("door_unlocked_" + door_id):
		unlocked = true
	if kind == "normal" and required_item.is_empty():
		unlocked = true
	_build_door()
	_open_angle = -PI * 0.53 if hinge_left else PI * 0.53


func _make_materials() -> void:
	_wood = StandardMaterial3D.new()
	_wood.albedo_texture = load("res://assets/textures/wood.png")
	_wood.roughness = 0.82
	_wood.uv1_scale = Vector3(0.8, 1.2, 1)
	_wood_dark = StandardMaterial3D.new()
	_wood_dark.albedo_color = Color("32271e")
	_wood_dark.roughness = 0.9
	_metal = StandardMaterial3D.new()
	_metal.albedo_color = Color("8a856f")
	_metal.roughness = 0.35
	_metal.metallic = 0.75
	_black = StandardMaterial3D.new()
	_black.albedo_color = Color("111310")
	_black.roughness = 0.7
	_glass = StandardMaterial3D.new()
	_glass.albedo_color = Color("263b3b")
	_glass.roughness = 0.08
	_glass.metallic = 0.55
	_glass.emission_enabled = true
	_glass.emission = Color("38514e")
	_glass.emission_energy_multiplier = 0.25
	_lamp_red = StandardMaterial3D.new()
	_lamp_red.albedo_color = Color("a0251e")
	_lamp_red.emission_enabled = true
	_lamp_red.emission = Color("c62d21")
	_lamp_red.emission_energy_multiplier = 2.0
	_lamp_green = StandardMaterial3D.new()
	_lamp_green.albedo_color = Color("5d9a68")
	_lamp_green.emission_enabled = true
	_lamp_green.emission = Color("77d88b")
	_lamp_green.emission_energy_multiplier = 1.6
	_steel = StandardMaterial3D.new()
	_steel.albedo_texture = load("res://assets/textures/metal.png")
	_steel.roughness = 0.48
	_steel.metallic = 0.62
	_lamp_white = StandardMaterial3D.new()
	_lamp_white.albedo_color = Color("d7c89d")
	_lamp_white.emission_enabled = true
	_lamp_white.emission = Color("ffe2ad")
	_lamp_white.emission_energy_multiplier = 1.8


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = pos
	parent.add_child(inst)
	return inst


func _build_door() -> void:
	# Decorative door frame.
	var frame_mat := _wood_dark
	_box(self, Vector3(0.08, height + 0.12, 0.34), Vector3(-width * 0.5 - 0.05, (height + 0.12) * 0.5, 0), frame_mat)
	_box(self, Vector3(0.08, height + 0.12, 0.34), Vector3(width * 0.5 + 0.05, (height + 0.12) * 0.5, 0), frame_mat)
	_box(self, Vector3(width + 0.18, 0.08, 0.34), Vector3(0, height + 0.1, 0), frame_mat)
	_box(self, Vector3(width + 0.04, 0.018, 0.52), Vector3(0, 0.025, 0), _metal)

	_pivot = Node3D.new()
	_pivot.position = Vector3(-width * 0.5 if hinge_left else width * 0.5, 0, 0)
	add_child(_pivot)

	_body = StaticBody3D.new()
	_pivot.add_child(_body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	var side := 1.0 if hinge_left else -1.0
	shape.size = Vector3(width, height, 0.11)
	collision.shape = shape
	collision.position = Vector3(side * width * 0.5, height * 0.5, 0)
	_body.add_child(collision)
	var panel_material := _wood
	var handle_material := _metal
	var inset_material := _wood_dark
	if kind == "mirror":
		panel_material = _glass
		handle_material = _metal
		inset_material = _metal
		height = 2.08
	elif kind == "security" or door_id.begins_with("security"):
		panel_material = _wood_dark
	if style == "metal":
		panel_material = _steel
		inset_material = _metal
		handle_material = _metal
	var panel := _box(_body, Vector3(width - 0.04, height, 0.11), Vector3(side * width * 0.5, height * 0.5, 0), panel_material)
	panel.name = "DoorPanel"
	if kind != "mirror":
		# Institutional inset panels.
		_box(_body, Vector3(width * 0.66, height * 0.38, 0.015), Vector3(side * width * 0.5, height * 0.64, 0.062), inset_material)
		_box(_body, Vector3(width * 0.66, height * 0.25, 0.015), Vector3(side * width * 0.5, height * 0.3, 0.062), inset_material)
		_box(_body, Vector3(width * 0.7, 0.028, 0.018), Vector3(side * width * 0.5, height * 0.45, 0.07), _black)
		# Small label plate.
		_box(_body, Vector3(0.38, 0.15, 0.014), Vector3(side * width * 0.5, height * 0.82, 0.062), _metal)
		if not plate_text.is_empty():
			var label := Label3D.new()
			label.text = plate_text
			label.font_size = 30
			label.pixel_size = 0.0022
			label.position = Vector3(side * width * 0.5, height * 0.82, 0.072)
			label.modulate = Color("252821")
			label.outline_size = 0
			_body.add_child(label)
	# Handle(s).
	var handle := Node3D.new()
	var handle_x := width - 0.15 if hinge_left else -width + 0.15
	handle.position = Vector3(handle_x, 0, 0)
	_body.add_child(handle)
	_box(handle, Vector3(0.055, 0.055, 0.05), Vector3(0, 1.02, 0.095), handle_material)
	_box(handle, Vector3(0.21, 0.045, 0.045), Vector3(-0.075 * side, 1.02, 0.11), handle_material)
	_box(handle, Vector3(0.055, 0.055, 0.05), Vector3(0, 1.02, -0.095), handle_material)
	# Lock indicator.
	var indicator := _lamp_green if unlocked else _lamp_red
	if kind == "normal" or kind == "mirror":
		indicator = _lamp_white
	_box(_body, Vector3(0.055, 0.055, 0.016), Vector3(side * width * 0.5, height * 0.93, 0.071), indicator)

	# Keypad beside security door.
	if kind == "keypad":
		var keypad := Node3D.new()
		keypad.position = Vector3(width * 0.5 + 0.34, 1.25, 0.15)
		add_child(keypad)
		_box(keypad, Vector3(0.28, 0.46, 0.08), Vector3.ZERO, _black)
		for yy in range(3):
			for xx in range(3):
				_box(keypad, Vector3(0.045, 0.045, 0.012), Vector3(-0.08 + xx * 0.08, 0.11 - yy * 0.08, 0.047), _metal)
		_box(keypad, Vector3(0.18, 0.055, 0.012), Vector3(0, 0.16, 0.047), _lamp_red)
	# Mirror gets a thick frame.
	if kind == "mirror":
		_box(self, Vector3(0.08, 2.2, 0.35), Vector3(-width * 0.5 - 0.06, 1.1, 0), _metal)
		_box(self, Vector3(0.08, 2.2, 0.35), Vector3(width * 0.5 + 0.06, 1.1, 0), _metal)
		_box(self, Vector3(width + 0.2, 0.08, 0.35), Vector3(0, 2.16, 0), _metal)


func get_prompt(_player: Node) -> String:
	var item_name := _item_name()
	var doc_known := GameState.has_read_document("maintenance_note")
	match kind:
		"keypad":
			if not unlocked:
				return "Enter keypad code - " + display_name
		"mirror":
			if not is_open:
				if doc_known:
					return "Open the hidden service panel"
				return "Examine the old mirror"
		"basement":
			if not GameState.has_flag("anchors_calibrated"):
				return "The seal is anchored"
			return "Descend into the basement"
		"true_exit":
			if not GameState.has_flag("loop_disabled"):
				return "Service tunnel - carrier active"
			if not InventoryManager.has_item("override_key"):
				return "Service tunnel - override required"
			return "Open the service tunnel"
		"ending_item":
			if not unlocked and not InventoryManager.has_item(required_item):
				return "Locked - " + item_name + " required"
			if not is_open:
				return "Open " + display_name
		"ending":
			if not is_open:
				return "Open " + display_name
	if is_open:
		return "Close " + display_name
	if not unlocked and required_item != "":
		return "Locked - " + item_name + " required"
	return "Open " + display_name


func _item_name() -> String:
	var data: Dictionary = StoryData.ITEMS.get(required_item, {})
	return str(data.get("name", "staff key"))


func interact(player: Node) -> void:
	_last_player = player
	player.play_interaction_animation()
	match kind:
		"keypad":
			if not unlocked:
				player.game.open_keypad(StoryData.SECURITY_CODE, Callable(self, "_on_keypad_success"))
				return
		"mirror":
			if not is_open:
				if not GameState.has_read_document("maintenance_note"):
					_locked_message(player, "The mirror is fixed to the wall. One corner looks loose. Search the storage room.")
					return
				unlocked = true
				GameState.set_flag("door_unlocked_" + door_id)
				GameState.set_flag("secret_passage_open")
				AudioManager.play_sfx("unlock", -9.0, 0.02)
				player.game.toast("The mirror swings inward. Cold air crawls out.")
				_set_open_state(true)
				player.game.save_progress()
				return
		"basement":
			if not GameState.has_flag("anchors_calibrated"):
				_locked_message(player, "The iron seal is still anchored. Somewhere above, a console controls it.")
				return
			AudioManager.play_sfx("door_open", -11.0, 0.02)
			player.game.enter_basement()
			return
		"ending":
			if not is_open:
				_play_ending_door(player, ending_id)
			return
		"ending_item":
			if not InventoryManager.has_item(required_item):
				_locked_message(player, "The lock is old, but solid. It needs a " + _item_name().to_lower() + ".")
				return
			unlocked = true
			GameState.set_flag("door_unlocked_" + door_id)
			AudioManager.play_sfx("unlock", -9.0, 0.02)
			player.game.toast("The brass key turns. Something heavy gives way.")
			_play_ending_door(player, ending_id, 0.5)
			return
		"true_exit":
			if not GameState.has_flag("loop_disabled"):
				_locked_message(player, "The service tunnel is sealed. The carrier is still folding the corridor.")
				return
			if not InventoryManager.has_item("override_key"):
				_locked_message(player, "A magnetic override slot blinks beside the door. It needs the service override.")
				return
			GameState.set_flag("override_used")
			AudioManager.play_sfx("unlock", -8.0, 0.02)
			player.game.toast("The override bites. Beyond the door: air.")
			_set_open_state(true)
			await get_tree().create_timer(0.8).timeout
			player.game.start_fake_victory()
			return
	if not unlocked:
		if required_item != "":
			if not InventoryManager.has_item(required_item):
				_locked_message(player, "Locked. It needs a " + _item_name().to_lower() + ".")
				return
			unlocked = true
			GameState.set_flag("door_unlocked_" + door_id)
			AudioManager.play_sfx("unlock", -9.0, 0.02)
			player.game.toast("The lock gives way.")
			player.game.save_progress()
		else:
			_locked_message(player, "The door will not move.")
			return
	_set_open_state(not is_open)
	player.game.save_progress()


func _on_keypad_success() -> void:
	unlocked = true
	GameState.set_flag("security_unlocked")
	GameState.set_flag("door_unlocked_" + door_id)
	AudioManager.play_sfx("unlock", -8.0, 0.02)
	SaveManager.save_current()
	_set_open_state(true)
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.game.toast("The lock releases. Security is open.")


func _play_ending_door(player: Node, id: int, delay: float = 0.72) -> void:
	if _opening or id <= 0:
		return
	_opening = true
	AudioManager.play_sfx("door_open", -9.0, 0.03)
	_set_open_state(true)
	await get_tree().create_timer(delay).timeout
	player.game.begin_ending(id)


func _locked_message(player: Node, message: String) -> void:
	AudioManager.play_sfx("door_locked", -12.0, 0.03)
	player.game.toast(message)


func _set_open_state(value: bool) -> void:
	is_open = value
	if is_open:
		AudioManager.play_sfx("door_open", -12.0, 0.03)
	else:
		AudioManager.play_sfx("door_close", -13.0, 0.03)
	var target := _open_angle if is_open else 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_pivot, "rotation:y", target, 0.72)

