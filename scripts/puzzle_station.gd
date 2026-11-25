extends Interactable

var kind: String = "anchor"
var display_name: String = "Console"
var _visual: Node3D
var _status_mats: Array[StandardMaterial3D] = []
var _refresh_timer: float = 0.0
var _lamp: OmniLight3D


func setup(station_kind: String, name_value: String = "") -> void:
	kind = station_kind
	display_name = name_value if not name_value.is_empty() else station_kind.capitalize()


func _ready() -> void:
	super._ready()
	_build()
	_refresh_status()


func _mat(color: Color, rough: float = 0.65, metal: float = 0.0, glow: bool = false, energy: float = 1.2) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	mat.metallic = metal
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = energy
	return mat


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = pos
	parent.add_child(inst)
	return inst


func _label(text_value: String, pos: Vector3, color: Color, size: int = 28) -> Label3D:
	var label := Label3D.new()
	label.text = text_value
	label.font_size = size
	label.pixel_size = 0.0025
	label.modulate = color
	label.outline_size = 5
	label.outline_modulate = Color(0, 0, 0, 0.8)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = pos
	_visual.add_child(label)
	return label


func _build() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var shell := _mat(Color("343a32"), 0.55, 0.5)
	var edge := _mat(Color("8d896f"), 0.32, 0.65, true, 0.16)
	var screen := _mat(Color("17362a"), 0.15, 0.0, true, 0.9)
	screen.emission = Color("2f7a52")
	screen.albedo_color = Color("1b4433")
	if kind == "anchor":
		_box(_visual, Vector3(1.2, 0.86, 0.22), Vector3(0, 1.3, 0), shell)
		_box(_visual, Vector3(1.24, 0.05, 0.25), Vector3(0, 1.75, 0), edge)
		_box(_visual, Vector3(0.74, 0.36, 0.02), Vector3(-0.16, 1.48, 0.13), screen)
		for i in range(3):
			var fuse_mat := _mat(Color("484f40"), 0.6, 0.2, true, 0.35)
			_status_mats.append(fuse_mat)
			_box(_visual, Vector3(0.12, 0.13, 0.045), Vector3(-0.45 + i * 0.15, 1.24, 0.14), fuse_mat)
			_box(_visual, Vector3(0.05, 0.05, 0.15), Vector3(0.31 + i * 0.12, 1.26, 0.09), _mat(Color("272b25"), 0.6))
			_box(_visual, Vector3(0.055, 0.03, 0.03), Vector3(0.31 + i * 0.12, 1.29, 0.18), _mat(Color("a04a3c"), 0.4, 0, true, 0.8))
		_label("ANCHOR ARRAY", Vector3(0, 1.84, 0.15), Color("aaa891"), 32)
		_lamp = OmniLight3D.new()
		_lamp.light_color = Color("82a785")
		_lamp.light_energy = 1.25
		_lamp.omni_range = 4.6
		_lamp.position = Vector3(0, 1.5, 0.7)
		_lamp.shadow_enabled = false
		add_child(_lamp)
	elif kind == "dial":
		var cabinet := _box(_visual, Vector3(1.28, 1.05, 0.34), Vector3(0, 1.17, 0), shell)
		_box(_visual, Vector3(1.32, 0.06, 0.38), Vector3(0, 1.72, 0), edge)
		_box(_visual, Vector3(0.76, 0.34, 0.03), Vector3(-0.17, 1.43, 0.19), screen)
		var torus := TorusMesh.new()
		torus.inner_radius = 0.18
		torus.outer_radius = 0.3
		torus.rings = 20
		torus.ring_segments = 10
		var ring_inst := MeshInstance3D.new()
		ring_inst.mesh = torus
		ring_inst.material_override = edge
		ring_inst.rotation.x = PI * 0.5
		ring_inst.position = Vector3(0.4, 1.2, 0.2)
		_visual.add_child(ring_inst)
		_box(_visual, Vector3(0.045, 0.28, 0.035), Vector3(0.4, 1.32, 0.23), _mat(Color("b8a77c"), 0.3, 0.7))
		_box(_visual, Vector3(0.13, 0.05, 0.035), Vector3(0.4, 1.2, 0.21), _mat(Color("a03b30"), 0.5, 0, true, 0.7))
		_label("RETURN CARRIER", Vector3(0, 1.84, 0.24), Color("aaa891"), 28)
		_lamp = OmniLight3D.new()
		_lamp.light_color = Color("b9a777")
		_lamp.light_energy = 1.25
		_lamp.omni_range = 4.6
		_lamp.position = Vector3(0, 1.35, 0.85)
		_lamp.shadow_enabled = false
		add_child(_lamp)
	else:
		_box(_visual, Vector3(0.7, 0.45, 0.16), Vector3(0, 1.4, 0), shell)
		_box(_visual, Vector3(0.32, 0.18, 0.02), Vector3(0, 1.46, 0.09), screen)
		_label(display_name.to_upper(), Vector3(0, 1.72, 0.12), Color("9a9a88"), 24)


func _refresh_status() -> void:
	if _status_mats.is_empty():
		return
	var collected := InventoryManager.fuse_count()
	var calibrated := GameState.has_flag("anchors_calibrated")
	for i in range(_status_mats.size()):
		var on := calibrated or i < collected
		var col := Color("6ea474") if on else Color("41362e")
		_status_mats[i].albedo_color = col
		_status_mats[i].emission = col
		_status_mats[i].emission_energy_multiplier = 1.0 if on else 0.12


func _process(delta: float) -> void:
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 0.5
		_refresh_status()


func get_prompt(_player: Node) -> String:
	match kind:
		"anchor":
			if GameState.has_flag("anchors_calibrated"):
				return "Anchor console — array cold"
			return "Use the anchor console"
		"dial":
			if GameState.has_flag("loop_disabled"):
				return "Return carrier — locked at 13.5"
			return "Adjust the return carrier"
	return "Examine " + display_name


func interact(player: Node) -> void:
	player.play_interaction_animation()
	match kind:
		"anchor":
			if GameState.has_flag("anchors_calibrated"):
				player.game.toast("The console is cold. Three dark slots watch you.")
				return
			if not InventoryManager.has_all_fuses():
				AudioManager.play_sfx("keypad_error", -12.0, 0.03)
				player.game.toast("The array needs three anchor fuses. You have %d of 3." % InventoryManager.fuse_count())
				return
			player.game.open_anchor_panel()
		"dial":
			if GameState.has_flag("loop_disabled"):
				player.game.toast("The needle holds at 13.5. The tunnel is breathing.")
				return
			player.game.open_dial_panel()
		_:
			player.game.toast("A dead console. The screen holds a fingerprint.")
			AudioManager.play_sfx("interact", -14.0, 0.03)


func set_highlight(value: bool) -> void:
	super.set_highlight(value)
	if _lamp != null:
		_lamp.light_energy = 1.9 if value else 1.25
