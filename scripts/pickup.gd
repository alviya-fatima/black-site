extends Interactable

var item_id: String = ""
var _visual: Node3D
var _glow: OmniLight3D
var _time: float = 0.0
var _taken: bool = false


func setup(id: String) -> void:
	item_id = id


func _ready() -> void:
	super._ready()
	if item_id.is_empty():
		queue_free()
		return
	if GameState.has_flag("taken_" + item_id):
		queue_free()
		return
	_time = randf() * 4.0
	_build_visual()


func _material(color: Color, metallic: float = 0.0, emissive: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.4 if metallic > 0.0 else 0.75
	mat.metallic = metallic
	if emissive:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.3
	return mat


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = pos
	inst.rotation = rot
	parent.add_child(inst)
	return inst


func _cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 14
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = pos
	inst.rotation = rot
	parent.add_child(inst)
	return inst


func _build_visual() -> void:
	_visual = Node3D.new()
	_visual.position.y = 0.18
	add_child(_visual)
	var item: Dictionary = StoryData.ITEMS.get(item_id, {})
	var tint := Color(str(item.get("color", "#c5bea2")))
	var metal := _material(Color("8b846d"), 0.8)
	var glow_mat := _material(tint, 0.0, true)
	match item_id:
		"staff_card":
			_box(_visual, Vector3(0.26, 0.018, 0.36), Vector3.ZERO, _material(Color("c8c2a9"), 0.0))
			_box(_visual, Vector3(0.24, 0.02, 0.05), Vector3(0, 0.003, -0.12), _material(Color("5e3027"), 0.0))
			_box(_visual, Vector3(0.1, 0.006, 0.1), Vector3(0.05, 0.013, 0.06), metal)
			_box(_visual, Vector3(0.07, 0.009, 0.012), Vector3(-0.07, 0.013, -0.03), _material(Color("292a24"), 0.0))
		"brass_key":
			var ring := TorusMesh.new()
			ring.inner_radius = 0.07
			ring.outer_radius = 0.13
			ring.rings = 16
			ring.ring_segments = 8
			var ring_inst := MeshInstance3D.new()
			ring_inst.mesh = ring
			ring_inst.material_override = glow_mat
			ring_inst.rotation.x = PI * 0.5
			ring_inst.position = Vector3(-0.1, 0.03, 0)
			_visual.add_child(ring_inst)
			_box(_visual, Vector3(0.3, 0.035, 0.045), Vector3(0.1, 0.03, 0), glow_mat)
			_box(_visual, Vector3(0.03, 0.12, 0.045), Vector3(0.2, 0.085, 0), glow_mat)
			_box(_visual, Vector3(0.03, 0.08, 0.045), Vector3(0.12, 0.075, 0), glow_mat)
		"override_key":
			_box(_visual, Vector3(0.26, 0.03, 0.2), Vector3.ZERO, _material(Color("242823"), 0.0))
			_box(_visual, Vector3(0.2, 0.012, 0.04), Vector3(0, 0.022, -0.06), _material(Color("b5ac8d"), 0.0, true))
			_box(_visual, Vector3(0.055, 0.035, 0.055), Vector3(0.11, 0.0, 0.15), metal)
		_:
			# Anchor fuses.
			var glass := _material(tint, 0.0, true)
			_cylinder(_visual, 0.09, 0.2, Vector3(0, 0.12, 0), glass)
			_cylinder(_visual, 0.105, 0.045, Vector3(0, 0.23, 0), metal)
			_cylinder(_visual, 0.105, 0.045, Vector3(0, 0.01, 0), metal)
			_box(_visual, Vector3(0.015, 0.1, 0.015), Vector3(0.085, 0.12, 0.02), _material(Color("d4d0b3"), 0.0))
	var label := Label3D.new()
	label.text = str(item.get("short", "ITEM"))
	label.font_size = 28
	label.pixel_size = 0.0025
	label.modulate = Color(0.85, 0.84, 0.76, 0.9)
	label.outline_size = 5
	label.outline_modulate = Color(0, 0, 0, 0.8)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 0.52, 0)
	add_child(label)
	_glow = OmniLight3D.new()
	_glow.light_color = tint
	_glow.light_energy = 0.25
	_glow.omni_range = 1.45
	_glow.position = Vector3(0, 0.25, 0)
	_glow.shadow_enabled = false
	add_child(_glow)


func _process(delta: float) -> void:
	_time += delta
	if _visual == null:
		return
	_visual.rotation.y += delta * 0.55
	_visual.position.y = 0.18 + sin(_time * 1.8) * 0.035


func get_prompt(_player: Node) -> String:
	if _taken:
		return ""
	var item: Dictionary = StoryData.ITEMS.get(item_id, {})
	return "Take " + str(item.get("name", "item"))


func interact(player: Node) -> void:
	if _taken:
		return
	_taken = true
	player.play_interaction_animation()
	player.game.collect_item(item_id)
	queue_free()


func set_highlight(value: bool) -> void:
	super.set_highlight(value)
	if _glow != null:
		_glow.light_energy = 0.5 if value else 0.25
