class_name WorldKit
extends RefCounted

var floor_tex: Texture2D
var concrete_tex: Texture2D
var plaster_tex: Texture2D
var tile_tex: Texture2D
var wood_tex: Texture2D
var metal_tex: Texture2D
var grass_tex: Texture2D
var ghost_tex: Texture2D
var scrawl_back_tex: Texture2D
var scrawl_subject_tex: Texture2D
var scrawl_41_tex: Texture2D

var m_floor: StandardMaterial3D
var m_concrete: StandardMaterial3D
var m_plaster: StandardMaterial3D
var m_tile: StandardMaterial3D
var m_wood: StandardMaterial3D
var m_metal: StandardMaterial3D
var m_black: StandardMaterial3D
var m_dark: StandardMaterial3D
var m_white: StandardMaterial3D
var m_ivory: StandardMaterial3D
var m_mattress: StandardMaterial3D
var m_green_fabric: StandardMaterial3D
var m_rust: StandardMaterial3D
var m_paper: StandardMaterial3D
var m_glass: StandardMaterial3D
var m_emissive_warm: StandardMaterial3D
var m_emissive_cold: StandardMaterial3D
var m_emissive_red: StandardMaterial3D
var m_emissive_green: StandardMaterial3D
var m_shadow: StandardMaterial3D
var m_grass: StandardMaterial3D
var sign_font: SystemFont


func _init() -> void:
	floor_tex = _load_tex("floor_checker.png")
	concrete_tex = _load_tex("concrete.png")
	plaster_tex = _load_tex("wall_plaster.png")
	tile_tex = _load_tex("wall_tile.png")
	wood_tex = _load_tex("wood.png")
	metal_tex = _load_tex("metal.png")
	grass_tex = _load_tex("grass.png")
	ghost_tex = _load_tex("ghost.png")
	scrawl_back_tex = _load_tex("scrawl_back.png")
	scrawl_subject_tex = _load_tex("scrawl_subject.png")
	scrawl_41_tex = _load_tex("scrawl_41.png")

	m_floor = _textured(floor_tex, 0.86)
	m_concrete = _textured(concrete_tex, 0.94)
	m_plaster = _textured(plaster_tex, 0.96)
	m_tile = _textured(tile_tex, 0.66)
	m_wood = _textured(wood_tex, 0.82)
	m_metal = _textured(metal_tex, 0.55, 0.62)
	m_black = _flat(Color("111410"), 0.9)
	m_dark = _flat(Color("1d211c"), 0.9)
	m_white = _flat(Color("c4c2b2"), 0.86)
	m_ivory = _flat(Color("b0ad9b"), 0.88)
	m_mattress = _flat(Color("9b9987"), 0.96)
	m_green_fabric = _flat(Color("495b4d"), 0.96)
	m_rust = _flat(Color("633b2d"), 0.88)
	m_paper = _flat(Color("c4c1ac"), 0.88)
	m_glass = _flat(Color("192a2b"), 0.12, 0.42)
	m_glass.emission_enabled = true
	m_glass.emission = Color("223c3d")
	m_glass.emission_energy_multiplier = 0.2
	m_emissive_warm = _emissive(Color("ffd89b"), 2.4)
	m_emissive_cold = _emissive(Color("d9eee2"), 2.7)
	m_emissive_red = _emissive(Color("e24336"), 2.1)
	m_emissive_green = _emissive(Color("80d694"), 1.8)
	m_shadow = _flat(Color(0.01, 0.012, 0.01, 0.44), 1.0)
	m_shadow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m_shadow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m_grass = _textured(grass_tex, 0.98)
	sign_font = SystemFont.new()
	sign_font.font_names = PackedStringArray(["Consolas", "Courier New"])
	sign_font.font_weight = 700


func _load_tex(file: String) -> Texture2D:
	var path := "res://assets/textures/" + file
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("Missing texture: " + path)
	return null


func _textured(texture: Texture2D, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	if texture:
		mat.albedo_texture = texture
	mat.roughness = roughness
	mat.metallic = metallic
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return mat


func _flat(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	return mat


func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.roughness = 0.45
	return mat


func text_material(base: StandardMaterial3D, uv_scale: Vector3) -> StandardMaterial3D:
	var mat := base.duplicate() as StandardMaterial3D
	mat.uv1_scale = uv_scale
	return mat


func add_box(parent: Node3D, size: Vector3, pos: Vector3, material: Material,
		rot: Vector3 = Vector3.ZERO, name: String = "") -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	instance.rotation = rot
	if not name.is_empty():
		instance.name = name
	parent.add_child(instance)
	return instance


func add_collision(parent: Node3D, size: Vector3, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation = rot
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	body.add_child(shape_node)
	parent.add_child(body)
	return body


func add_static_box(parent: Node3D, size: Vector3, pos: Vector3, material: Material,
		rot: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body := add_collision(parent, size, pos, rot)
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	body.add_child(instance)
	return body


func add_wall(parent: Node3D, center: Vector3, length: float, axis: String = "x",
		height: float = 2.8, thickness: float = 0.28) -> StaticBody3D:
	var root := StaticBody3D.new()
	root.position = center
	root.rotation.y = PI * 0.5 if axis == "z" else 0.0
	parent.add_child(root)
	var lower := minf(1.18, height * 0.45)
	var upper := height - lower
	var tile_mat := text_material(m_tile, Vector3(maxf(1.0, length / 1.5), 1.0, 1.0))
	var plaster_mat := text_material(m_plaster, Vector3(maxf(1.0, length / 2.2), maxf(1.0, upper / 2.0), 1.0))
	add_box(root, Vector3(length, lower, thickness), Vector3(0, lower * 0.5, 0), tile_mat)
	add_box(root, Vector3(length, upper, thickness), Vector3(0, lower + upper * 0.5, 0), plaster_mat)
	add_box(root, Vector3(length, 0.06, thickness + 0.02), Vector3(0, 0.03, 0), m_dark)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(length, height, thickness)
	collision.shape = shape
	collision.position = Vector3(0, height * 0.5, 0)
	root.add_child(collision)
	return root


func add_wall_with_gap(parent: Node3D, axis: String, fixed_coord: float, start_coord: float,
		end_coord: float, gap_centers: Array, gap_width: float = 1.9,
		height: float = 2.8, thickness: float = 0.28) -> void:
	var gaps := gap_centers.duplicate()
	gaps.sort()
	var cursor := start_coord
	for gap in gaps:
		var gap_center := float(gap)
		var gap_start := gap_center - gap_width * 0.5
		var gap_end := gap_center + gap_width * 0.5
		if gap_start > cursor + 0.01:
			_add_wall_span(parent, axis, fixed_coord, cursor, gap_start, height, thickness)
		_add_lintel(parent, axis, fixed_coord, gap_start, gap_end, height, thickness, 2.18)
		cursor = gap_end
	if cursor < end_coord - 0.01:
		_add_wall_span(parent, axis, fixed_coord, cursor, end_coord, height, thickness)


func _add_wall_span(parent: Node3D, axis: String, fixed_coord: float, a: float, b: float,
		height: float, thickness: float) -> void:
	var length := b - a
	var midpoint := (a + b) * 0.5
	if axis == "x":
		add_wall(parent, Vector3(midpoint, 0, fixed_coord), length, "x", height, thickness)
	else:
		add_wall(parent, Vector3(fixed_coord, 0, midpoint), length, "z", height, thickness)


func _add_lintel(parent: Node3D, axis: String, fixed_coord: float, a: float, b: float,
		height: float, thickness: float, clearance: float) -> void:
	var length := b - a
	var midpoint := (a + b) * 0.5
	var lintel_height := height - clearance
	var pos := Vector3(midpoint, clearance + lintel_height * 0.5, fixed_coord) if axis == "x" else Vector3(fixed_coord, clearance + lintel_height * 0.5, midpoint)
	var size := Vector3(length, lintel_height, thickness) if axis == "x" else Vector3(thickness, lintel_height, length)
	var plaster_mat := text_material(m_plaster, Vector3(maxf(1, length / 2), 1, 1))
	add_static_box(parent, size, pos, plaster_mat)


func add_floor(parent: Node3D, rect: Rect2, material: StandardMaterial3D = null,
		y: float = 0.0) -> MeshInstance3D:
	var mesh := PlaneMesh.new()
	mesh.size = rect.size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var mat := text_material(material if material != null else m_floor,
		Vector3(maxf(1.0, rect.size.x / 4.9), maxf(1.0, rect.size.y / 4.9), 1))
	instance.material_override = mat
	instance.position = Vector3(rect.position.x + rect.size.x * 0.5, y, rect.position.y + rect.size.y * 0.5)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance


func add_floor_collision(parent: Node3D, rect: Rect2, y: float = -0.1) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = Vector3(rect.position.x + rect.size.x * 0.5, y, rect.position.y + rect.size.y * 0.5)
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(rect.size.x, 0.2, rect.size.y)
	shape_node.shape = shape
	body.add_child(shape_node)
	parent.add_child(body)
	return body


func add_doorway_header(parent: Node3D, center: Vector3, width: float, axis: String, material: Material = null) -> void:
	var size := Vector3(width, 0.56, 0.28) if axis == "x" else Vector3(0.28, 0.56, width)
	add_static_box(parent, size, center + Vector3(0, 2.48, 0), material if material != null else m_plaster)


func add_ceiling_lamp(parent: Node3D, pos: Vector3, flicker: bool = true,
		warm: bool = true, energy: float = 1.25, light_range: float = 8.0,
		shadow: bool = false) -> OmniLight3D:
	var fixture := Node3D.new()
	fixture.position = pos
	parent.add_child(fixture)
	var metal := m_metal
	add_box(fixture, Vector3(0.95, 0.05, 0.34), Vector3(0, 2.62, 0), metal)
	add_box(fixture, Vector3(0.85, 0.035, 0.26), Vector3(0, 2.585, 0), m_emissive_warm if warm else m_emissive_cold)
	add_box(fixture, Vector3(0.025, 0.34, 0.025), Vector3(-0.33, 2.79, 0), metal)
	add_box(fixture, Vector3(0.025, 0.34, 0.025), Vector3(0.33, 2.79, 0), metal)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 2.25, 0)
	light.light_color = Color("ffd8a4") if warm else Color("cfe5dc")
	light.light_energy = energy
	light.omni_range = light_range
	light.omni_attenuation = 1.4
	light.shadow_enabled = shadow
	if flicker:
		light.set_script(load("res://scripts/flicker_light.gd"))
		fixture.add_child(light)
		light.set("base_energy", energy)
		light.set("flicker_strength", randf_range(0.12, 0.32))
		light.set("flicker_seed", randf() * 1000.0)
	else:
		fixture.add_child(light)
	return light


func add_wall_lamp(parent: Node3D, pos: Vector3, face_rotation: float = 0.0,
		flicker: bool = true, energy: float = 1.0) -> void:
	var fixture := Node3D.new()
	fixture.position = pos
	fixture.rotation.y = face_rotation
	parent.add_child(fixture)
	add_box(fixture, Vector3(0.11, 0.38, 0.22), Vector3(0, 0, 0), m_metal)
	add_box(fixture, Vector3(0.18, 0.24, 0.025), Vector3(0, 0.02, 0.13), m_emissive_warm)
	var light := OmniLight3D.new()
	light.position = Vector3(0, -0.02, 0.35)
	light.light_color = Color("ffd3a0")
	light.light_energy = energy
	light.omni_range = 5.3
	light.shadow_enabled = false
	if flicker:
		light.set_script(load("res://scripts/flicker_light.gd"))
		fixture.add_child(light)
		light.set("base_energy", energy)
		light.set("flicker_strength", randf_range(0.14, 0.4))
		light.set("flicker_seed", randf() * 1000.0)
	else:
		fixture.add_child(light)


func add_label_sign(parent: Node3D, text_value: String, pos: Vector3, size: int = 46,
		color: Color = Color("b9b6a1"), pixel_size: float = 0.0042) -> Label3D:
	var node := Label3D.new()
	node.text = text_value
	node.font = sign_font
	node.font_size = size
	node.pixel_size = pixel_size
	node.modulate = color
	node.outline_size = 8
	node.outline_modulate = Color(0.02, 0.025, 0.02, 0.9)
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.no_depth_test = false
	node.position = pos
	node.render_priority = 2
	parent.add_child(node)
	return node


func add_wall_decal(parent: Node3D, texture: Texture2D, pos: Vector3, size: Vector2,
		rot_y: float = 0.0, color: Color = Color.WHITE) -> MeshInstance3D:
	if texture == null:
		return null
	var quad := QuadMesh.new()
	quad.size = size
	var inst := MeshInstance3D.new()
	inst.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	inst.material_override = mat
	inst.position = pos
	inst.rotation.y = rot_y
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(inst)
	return inst


func add_flat_stain(parent: Node3D, pos: Vector3, radius: float = 1.0, color: Color = Color(0.06, 0.07, 0.06, 0.35)) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.05
	mesh.height = 0.006
	mesh.radial_segments = 20
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	inst.material_override = mat
	inst.position = pos + Vector3(0, 0.018, 0)
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(inst)
	return inst


func add_paper_scatter(parent: Node3D, center: Vector3, extents: Vector2, count: int) -> void:
	for i in range(count):
		var size := Vector2(randf_range(0.16, 0.3), randf_range(0.2, 0.38))
		var mesh := PlaneMesh.new()
		mesh.size = size
		var inst := MeshInstance3D.new()
		inst.mesh = mesh
		inst.material_override = m_paper
		inst.position = center + Vector3(randf_range(-extents.x, extents.x), 0.035, randf_range(-extents.y, extents.y))
		inst.rotation.y = randf() * TAU
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(inst)


func add_blob_shadow(parent: Node3D, radius: float = 0.55) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 0.9
	mesh.height = 0.004
	mesh.radial_segments = 24
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = m_shadow
	inst.position.y = 0.018
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(inst)
	return inst


func prop_root(parent: Node3D, pos: Vector3, rotation_y: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rotation_y
	parent.add_child(root)
	return root


func add_bed(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> void:
	var root := prop_root(parent, pos, rot_y)
	add_box(root, Vector3(1.05, 0.12, 2.1), Vector3(0, 0.47, 0), m_wood)
	add_box(root, Vector3(0.96, 0.2, 2.0), Vector3(0, 0.6, 0), m_mattress)
	add_box(root, Vector3(0.95, 0.06, 0.75), Vector3(0, 0.73, -0.58), m_green_fabric)
	add_box(root, Vector3(0.73, 0.12, 0.36), Vector3(0, 0.78, -0.75), m_white)
	for x in [-0.44, 0.44]:
		for z in [-0.88, 0.88]:
			add_box(root, Vector3(0.055, 0.5, 0.055), Vector3(x, 0.25, z), m_metal)
	add_collision(root, Vector3(1.08, 0.65, 2.14), Vector3(0, 0.33, 0))


func add_bedside(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> void:
	var root := prop_root(parent, pos, rot_y)
	add_box(root, Vector3(0.54, 0.06, 0.44), Vector3(0, 0.55, 0), m_wood)
	for x in [-0.22, 0.22]:
		for z in [-0.16, 0.16]:
			add_box(root, Vector3(0.04, 0.55, 0.04), Vector3(x, 0.275, z), m_metal)
	add_box(root, Vector3(0.18, 0.16, 0.12), Vector3(0.08, 0.67, 0.02), m_white)
	add_collision(root, Vector3(0.54, 0.55, 0.44), Vector3(0, 0.28, 0))


func add_desk(parent: Node3D, pos: Vector3, rot_y: float = 0.0, width: float = 1.7) -> Node3D:
	var root := prop_root(parent, pos, rot_y)
	add_box(root, Vector3(width, 0.08, 0.78), Vector3(0, 0.77, 0), m_wood)
	add_box(root, Vector3(width - 0.22, 0.52, 0.64), Vector3(0, 0.46, 0.04), m_dark)
	for x in [-width * 0.43, width * 0.43]:
		add_box(root, Vector3(0.07, 0.73, 0.07), Vector3(x, 0.37, -0.29), m_metal)
		add_box(root, Vector3(0.07, 0.73, 0.07), Vector3(x, 0.37, 0.29), m_metal)
	add_collision(root, Vector3(width, 0.8, 0.8), Vector3(0, 0.4, 0))
	return root


func add_chair(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> void:
	var root := prop_root(parent, pos, rot_y)
	add_box(root, Vector3(0.48, 0.08, 0.46), Vector3(0, 0.5, 0), m_wood)
	add_box(root, Vector3(0.48, 0.58, 0.07), Vector3(0, 0.8, 0.2), m_wood)
	for x in [-0.18, 0.18]:
		for z in [-0.18, 0.18]:
			add_box(root, Vector3(0.045, 0.47, 0.045), Vector3(x, 0.24, z), m_metal)


func add_cabinet(parent: Node3D, pos: Vector3, rot_y: float = 0.0, width: float = 1.0) -> void:
	var root := prop_root(parent, pos, rot_y)
	add_box(root, Vector3(width, 1.9, 0.5), Vector3(0, 0.95, 0), m_metal)
	add_box(root, Vector3(width - 0.1, 0.04, 0.53), Vector3(0, 1.02, 0), m_dark)
	add_box(root, Vector3(width - 0.1, 0.035, 0.52), Vector3(0, 1.48, 0), m_dark)
	add_box(root, Vector3(0.05, 0.12, 0.04), Vector3(-0.08, 1.22, 0.27), m_metal)
	add_box(root, Vector3(0.05, 0.12, 0.04), Vector3(0.08, 1.22, 0.27), m_metal)
	add_collision(root, Vector3(width, 1.9, 0.5), Vector3(0, 0.95, 0))


func add_shelf(parent: Node3D, pos: Vector3, rot_y: float = 0.0, width: float = 2.2) -> void:
	var root := prop_root(parent, pos, rot_y)
	for x in [-width * 0.46, width * 0.46]:
		add_box(root, Vector3(0.07, 2.15, 0.46), Vector3(x, 1.075, 0), m_metal)
	for h in [0.08, 0.64, 1.2, 1.76, 2.09]:
		add_box(root, Vector3(width, 0.045, 0.46), Vector3(0, h, 0), m_metal)
	for i in range(6):
		var sx := randf_range(-width * 0.35, width * 0.35)
		var h: float = [0.27, 0.83, 1.39][i % 3]
		add_box(root, Vector3(randf_range(0.2, 0.48), randf_range(0.14, 0.34), 0.33), Vector3(sx, h, 0), m_wood if i % 2 == 0 else m_paper)
	add_collision(root, Vector3(width, 2.15, 0.48), Vector3(0, 1.075, 0))


func add_toilet(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> void:
	var root := prop_root(parent, pos, rot_y)
	var bowl := CylinderMesh.new()
	bowl.top_radius = 0.25
	bowl.bottom_radius = 0.2
	bowl.height = 0.3
	var inst := MeshInstance3D.new()
	inst.mesh = bowl
	inst.material_override = m_white
	inst.position = Vector3(0, 0.31, -0.05)
	root.add_child(inst)
	add_box(root, Vector3(0.5, 0.55, 0.24), Vector3(0, 0.44, 0.27), m_white)
	add_box(root, Vector3(0.55, 0.28, 0.48), Vector3(0, 0.14, -0.03), m_white)
	add_collision(root, Vector3(0.55, 0.65, 0.72), Vector3(0, 0.32, 0))


func add_sink(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> void:
	var root := prop_root(parent, pos, rot_y)
	add_box(root, Vector3(0.62, 0.14, 0.45), Vector3(0, 0.8, 0), m_white)
	add_box(root, Vector3(0.5, 0.24, 0.34), Vector3(0, 0.67, 0), m_ivory)
	add_box(root, Vector3(0.045, 0.25, 0.045), Vector3(0, 1.03, -0.15), m_metal)
	add_box(root, Vector3(0.06, 0.06, 0.18), Vector3(0, 1.14, -0.08), m_metal)
	add_box(root, Vector3(0.08, 0.7, 0.08), Vector3(0.24, 0.35, 0.05), m_metal)


func add_mirror_frame(parent: Node3D, pos: Vector3, rot_y: float = 0.0, width: float = 1.3, height: float = 1.8) -> void:
	var root := prop_root(parent, pos, rot_y)
	add_box(root, Vector3(width, height, 0.08), Vector3(0, height * 0.5, 0), m_metal)
	add_box(root, Vector3(width - 0.12, height - 0.12, 0.09), Vector3(0, height * 0.5, 0.01), m_glass)
	add_collision(root, Vector3(width, height, 0.12), Vector3(0, height * 0.5, 0))


func add_reception_counter(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> void:
	var root := prop_root(parent, pos, rot_y)
	add_box(root, Vector3(4.7, 1.03, 0.78), Vector3(0, 0.515, 0), m_wood)
	add_box(root, Vector3(4.85, 0.08, 0.94), Vector3(0, 1.06, 0), m_dark)
	add_box(root, Vector3(4.4, 0.38, 0.03), Vector3(0, 0.64, 0.405), m_metal)
	add_box(root, Vector3(0.85, 0.05, 0.5), Vector3(-1.15, 1.13, 0.02), m_metal)
	add_box(root, Vector3(0.55, 0.03, 0.36), Vector3(-1.15, 1.17, 0.02), m_paper)
	add_collision(root, Vector3(4.7, 1.1, 0.8), Vector3(0, 0.55, 0))


func add_gurney(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> void:
	var root := prop_root(parent, pos, rot_y)
	add_box(root, Vector3(0.82, 0.1, 1.85), Vector3(0, 0.82, 0), m_metal)
	add_box(root, Vector3(0.7, 0.15, 1.65), Vector3(0, 0.94, 0), m_mattress)
	for x in [-0.34, 0.34]:
		for z in [-0.72, 0.72]:
			add_box(root, Vector3(0.04, 0.78, 0.04), Vector3(x, 0.41, z), m_metal)
			var wheel := CylinderMesh.new()
			wheel.top_radius = 0.08
			wheel.bottom_radius = 0.08
			wheel.height = 0.06
			var wheel_inst := MeshInstance3D.new()
			wheel_inst.mesh = wheel
			wheel_inst.material_override = m_black
			wheel_inst.rotation.z = PI * 0.5
			wheel_inst.position = Vector3(x, 0.08, z)
			root.add_child(wheel_inst)
	add_collision(root, Vector3(0.85, 0.9, 1.9), Vector3(0, 0.45, 0))


func add_wheelchair(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> void:
	var root := prop_root(parent, pos, rot_y)
	var seat := MeshInstance3D.new()
	var seat_mesh := BoxMesh.new()
	seat_mesh.size = Vector3(0.55, 0.07, 0.54)
	seat.mesh = seat_mesh
	seat.material_override = m_dark
	seat.position = Vector3(0, 0.56, 0)
	root.add_child(seat)
	add_box(root, Vector3(0.55, 0.58, 0.07), Vector3(0, 0.86, 0.26), m_dark)
	for side in [-1.0, 1.0]:
		var wheel := CylinderMesh.new()
		wheel.top_radius = 0.34
		wheel.bottom_radius = 0.34
		wheel.height = 0.045
		var inst := MeshInstance3D.new()
		inst.mesh = wheel
		inst.material_override = m_dark
		inst.rotation.z = PI * 0.5
		inst.position = Vector3(side * 0.36, 0.36, 0.05)
		root.add_child(inst)
		add_box(root, Vector3(0.025, 0.2, 0.025), Vector3(side * 0.36, 0.72, -0.25), m_metal)
	add_collision(root, Vector3(0.85, 0.9, 0.8), Vector3(0, 0.45, 0))


func add_screen(parent: Node3D, pos: Vector3, size: Vector2, rot_y: float = 0.0) -> void:
	var root := prop_root(parent, pos, rot_y)
	add_box(root, Vector3(size.x + 0.12, size.y + 0.12, 0.24), Vector3(0, 0, 0), m_dark)
	add_box(root, Vector3(size.x, size.y, 0.015), Vector3(0, 0, 0.13), m_emissive_green)
	add_box(root, Vector3(0.28, 0.06, 0.18), Vector3(0, -size.y * 0.5 - 0.1, 0), m_metal)


func add_pipes(parent: Node3D, start: Vector3, end: Vector3, radius: float = 0.06) -> void:
	var delta := end - start
	var length := delta.length()
	if length <= 0.01:
		return
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = m_metal
	inst.position = start + delta * 0.5
	inst.look_at_from_position(start + delta * 0.5, start, Vector3.FORWARD)
	inst.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	parent.add_child(inst)


func add_debris(parent: Node3D, center: Vector3, extents: Vector2, count: int) -> void:
	for i in range(count):
		var size := Vector3(randf_range(0.06, 0.28), randf_range(0.02, 0.08), randf_range(0.05, 0.35))
		add_box(parent, size,
			center + Vector3(randf_range(-extents.x, extents.x), 0.04, randf_range(-extents.y, extents.y)),
			[ m_wood, m_plaster, m_paper ][i % 3], Vector3(0, randf() * TAU, 0))


func add_plant(parent: Node3D, pos: Vector3) -> void:
	var root := prop_root(parent, pos, 0)
	var pot := CylinderMesh.new()
	pot.top_radius = 0.28
	pot.bottom_radius = 0.2
	pot.height = 0.38
	var pot_inst := MeshInstance3D.new()
	pot_inst.mesh = pot
	pot_inst.material_override = m_rust
	pot_inst.position.y = 0.19
	root.add_child(pot_inst)
	for i in range(5):
		add_box(root, Vector3(0.035, randf_range(0.4, 0.9), 0.025),
			Vector3(randf_range(-0.12, 0.12), 0.55, randf_range(-0.12, 0.12)),
			m_green_fabric, Vector3(randf_range(-0.4, 0.4), randf() * TAU, randf_range(-0.3, 0.3)))


func add_ghost(parent: Node3D, pos: Vector3, scale_mul: float = 1.0) -> void:
	if ghost_tex == null:
		return
	var sprite := Sprite3D.new()
	sprite.texture = ghost_tex
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = 0.0046 * scale_mul
	sprite.position = pos
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.modulate = Color(0.83, 0.94, 0.91, 0.27)
	sprite.set_script(load("res://scripts/ghost_figure.gd"))
	parent.add_child(sprite)


func add_body_bag(parent: Node3D, pos: Vector3, rot_y: float = 0.0, collision: bool = false) -> Node3D:
	var root := prop_root(parent, pos, rot_y)
	add_box(root, Vector3(0.7, 0.22, 1.78), Vector3(0, 0.11, 0), m_black)
	add_box(root, Vector3(0.28, 0.15, 0.34), Vector3(0, 0.19, -0.72), m_black)
	add_box(root, Vector3(0.035, 0.018, 1.44), Vector3(0, 0.235, 0.06), m_metal)
	for z in [-0.55, 0.0, 0.55]:
		add_box(root, Vector3(0.76, 0.035, 0.055), Vector3(0, 0.22, z), m_rust)
	add_box(root, Vector3(0.12, 0.012, 0.18), Vector3(0.24, 0.24, 0.7), m_paper)
	if collision:
		add_collision(root, Vector3(0.75, 0.3, 1.85), Vector3(0, 0.15, 0))
	return root


func add_restraints(parent: Node3D, pos: Vector3, rot_y: float = 0.0, width: float = 0.95) -> void:
	var root := prop_root(parent, pos, rot_y)
	for z in [-0.55, 0.34]:
		add_box(root, Vector3(width, 0.035, 0.11), Vector3(0, 0.015, z), m_rust)
		add_box(root, Vector3(0.08, 0.05, 0.13), Vector3(width * 0.5, 0.03, z), m_metal)
		add_box(root, Vector3(0.08, 0.05, 0.13), Vector3(-width * 0.5, 0.03, z), m_metal)


func add_iv_stand(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> void:
	var root := prop_root(parent, pos, rot_y)
	var base := CylinderMesh.new()
	base.top_radius = 0.24
	base.bottom_radius = 0.3
	base.height = 0.05
	var base_inst := MeshInstance3D.new()
	base_inst.mesh = base
	base_inst.material_override = m_metal
	base_inst.position.y = 0.025
	root.add_child(base_inst)
	add_box(root, Vector3(0.035, 1.9, 0.035), Vector3(0, 0.95, 0), m_metal)
	add_box(root, Vector3(0.44, 0.035, 0.035), Vector3(0, 1.86, 0), m_metal)
	var bag_mat := StandardMaterial3D.new()
	bag_mat.albedo_color = Color(0.38, 0.52, 0.4, 0.55)
	bag_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bag_mat.roughness = 0.35
	add_box(root, Vector3(0.17, 0.28, 0.08), Vector3(0.14, 1.68, 0), bag_mat)
	add_box(root, Vector3(0.012, 0.95, 0.012), Vector3(0.14, 1.08, 0), m_glass)


func add_specimen_jars(parent: Node3D, pos: Vector3, rot_y: float = 0.0, count: int = 4) -> void:
	var root := prop_root(parent, pos, rot_y)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.55, 0.68, 0.61, 0.32)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.2
	for i in range(count):
		var x := (float(i) - float(count - 1) * 0.5) * 0.2
		var jar := CylinderMesh.new()
		jar.top_radius = 0.065
		jar.bottom_radius = 0.075
		jar.height = 0.19
		var jar_inst := MeshInstance3D.new()
		jar_inst.mesh = jar
		jar_inst.material_override = glass
		jar_inst.position = Vector3(x, 0.095, 0)
		root.add_child(jar_inst)
		var fill := CylinderMesh.new()
		fill.top_radius = 0.05
		fill.bottom_radius = 0.055
		fill.height = 0.11
		var fill_inst := MeshInstance3D.new()
		fill_inst.mesh = fill
		fill_inst.material_override = m_emissive_red if i % 3 == 0 else m_emissive_green
		fill_inst.position = Vector3(x, 0.07, 0)
		root.add_child(fill_inst)
		var lid := CylinderMesh.new()
		lid.top_radius = 0.07
		lid.bottom_radius = 0.07
		lid.height = 0.025
		var lid_inst := MeshInstance3D.new()
		lid_inst.mesh = lid
		lid_inst.material_override = m_metal
		lid_inst.position = Vector3(x, 0.205, 0)
		root.add_child(lid_inst)


func add_hanging_sheet(parent: Node3D, pos: Vector3, width: float = 1.1, height: float = 1.9, rot_y: float = 0.0) -> void:
	var root := prop_root(parent, pos, rot_y)
	var plane := PlaneMesh.new()
	plane.size = Vector2(width, height)
	var inst := MeshInstance3D.new()
	inst.mesh = plane
	inst.rotation.x = PI * 0.5
	inst.position.y = height * 0.5
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.62, 0.64, 0.58, 0.38)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.9
	inst.material_override = mat
	root.add_child(inst)
	add_box(root, Vector3(width + 0.2, 0.035, 0.035), Vector3(0, height, 0), m_metal)
	for x in [-width * 0.35, width * 0.35]:
		add_box(root, Vector3(0.018, height, 0.018), Vector3(x, height * 0.5, 0), m_metal)


func add_blood_trail(parent: Node3D, start: Vector3, end: Vector3, count: int = 7) -> void:
	for i in range(count):
		var t := float(i) / maxf(1.0, float(count - 1))
		var p := start.lerp(end, t) + Vector3(randf_range(-0.18, 0.18), 0, randf_range(-0.18, 0.18))
		add_flat_stain(parent, p, randf_range(0.18, 0.42), Color(0.16, 0.025, 0.02, 0.52))


func add_ceiling_stain(parent: Node3D, pos: Vector3, radius: float = 0.8) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.08
	mesh.height = 0.006
	mesh.radial_segments = 18
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.025, 0.03, 0.025, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	inst.material_override = mat
	inst.position = pos
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(inst)


func add_surgical_tray(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> void:
	var root := prop_root(parent, pos, rot_y)
	add_box(root, Vector3(0.72, 0.04, 0.46), Vector3(0, 0.9, 0), m_metal)
	for x in [-0.28, 0.28]:
		for z in [-0.16, 0.16]:
			add_box(root, Vector3(0.025, 0.88, 0.025), Vector3(x, 0.45, z), m_metal)
	add_box(root, Vector3(0.3, 0.018, 0.035), Vector3(-0.12, 0.93, 0.06), m_white)
	add_box(root, Vector3(0.24, 0.012, 0.03), Vector3(0.16, 0.93, -0.07), m_metal)
	add_box(root, Vector3(0.18, 0.014, 0.12), Vector3(0.18, 0.935, 0.11), m_rust)


func add_restraint_chair(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> void:
	var root := prop_root(parent, pos, rot_y)
	add_box(root, Vector3(0.5, 0.09, 0.48), Vector3(0, 0.52, 0), m_wood)
	add_box(root, Vector3(0.5, 0.62, 0.08), Vector3(0, 0.85, 0.21), m_wood)
	for x in [-0.2, 0.2]:
		for z in [-0.18, 0.18]:
			add_box(root, Vector3(0.045, 0.5, 0.045), Vector3(x, 0.25, z), m_metal)
	for z in [-0.1, 0.13]:
		add_box(root, Vector3(0.58, 0.035, 0.09), Vector3(0, 0.57, z), m_rust)
	add_box(root, Vector3(0.55, 0.035, 0.08), Vector3(0, 0.82, 0.24), m_rust)
	add_collision(root, Vector3(0.58, 0.95, 0.55), Vector3(0, 0.47, 0))
