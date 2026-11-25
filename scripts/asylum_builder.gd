extends Node3D

const DoorScript := preload("res://scripts/door.gd")
const DocumentScript := preload("res://scripts/document.gd")
const PickupScript := preload("res://scripts/pickup.gd")
const PuzzleScript := preload("res://scripts/puzzle_station.gd")
const TriggerScript := preload("res://scripts/story_trigger.gd")
const StairsScript := preload("res://scripts/stairs_up.gd")

var game: Node
var kit: WorldKit
var zones: Array[Dictionary] = []
var _basement: Node3D


func build(game_ref: Node) -> void:
	game = game_ref
	seed(6106)
	kit = WorldKit.new()
	_build_exterior()
	_build_main_shell()
	_build_crawlspace()
	_build_basement()
	_build_room_contents()
	_register_zones()


func _build_exterior() -> void:
	var ground_mat := kit.text_material(kit.m_grass, Vector3(14, 14, 1))
	ground_mat.albedo_color = Color(0.26, 0.29, 0.23)
	kit.add_floor(self, Rect2(-42, -55, 25.8, 13.5), ground_mat, -0.08)
	kit.add_floor(self, Rect2(16.2, -55, 25.8, 13.5), ground_mat, -0.08)
	kit.add_floor(self, Rect2(-42, -41.5, 84, 24), ground_mat, -0.08)
	kit.add_floor(self, Rect2(-42, -17.5, 11.8, 5), ground_mat, -0.08)
	kit.add_floor(self, Rect2(-21.5, -17.5, 63.5, 5), ground_mat, -0.08)
	kit.add_floor(self, Rect2(-42, -12.5, 84, 52.5), ground_mat, -0.08)
	kit.add_floor(self, Rect2(-4, 28, 8, 5), kit.text_material(kit.m_concrete, Vector3(2, 1, 1)), -0.02)
	kit.add_debris(self, Vector3(-27, 0, 24), Vector2(4, 5), 22)
	kit.add_debris(self, Vector3(28, 0, 2), Vector2(3, 8), 18)
	kit.add_debris(self, Vector3(0, 0, 32), Vector2(7, 2), 14)
	for tree_pos in [
		Vector3(-31, 0, 22), Vector3(-33, 0, -12), Vector3(31, 0, -22),
		Vector3(29, 0, 13), Vector3(-16, 0, 34), Vector3(18, 0, 35),
	]:
		_dead_tree(tree_pos)


func _dead_tree(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	var bark := kit.m_wood
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.12
	trunk.bottom_radius = 0.28
	trunk.height = 3.6
	trunk.radial_segments = 8
	var t := MeshInstance3D.new()
	t.mesh = trunk
	t.material_override = bark
	t.position.y = 1.8
	t.rotation.z = randf_range(-0.08, 0.08)
	root.add_child(t)
	for i in range(5):
		var branch := BoxMesh.new()
		branch.size = Vector3(0.09, randf_range(0.8, 1.9), 0.09)
		var b := MeshInstance3D.new()
		b.mesh = branch
		b.material_override = bark
		b.position = Vector3(randf_range(-0.2, 0.2), randf_range(2.0, 3.4), randf_range(-0.2, 0.2))
		b.rotation = Vector3(randf_range(-0.7, 0.7), randf() * TAU, randf_range(-0.7, 0.7))
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(b)


func _build_main_shell() -> void:
	kit.add_floor(self, Rect2(-22, -30, 44, 50), kit.m_floor, 0.0)
	kit.add_floor(self, Rect2(-10, 20, 20, 8), kit.m_floor, 0.0)
	kit.add_floor(self, Rect2(-10, -38, 20, 8), kit.m_floor, 0.0)
	kit.add_floor_collision(self, Rect2(-22.4, -30.4, 44.8, 51.0), -0.1)
	kit.add_floor_collision(self, Rect2(-10.4, -38.4, 20.8, 29.0), -0.1)
	kit.add_floor_collision(self, Rect2(-10.4, 19.6, 20.8, 8.9), -0.1)

	# Exterior walls.
	kit.add_wall_with_gap(self, "z", -22, -30, 20, [-15, -5], 1.9)
	kit.add_wall_with_gap(self, "z", 22, -30, 20, [15], 1.9)
	kit.add_wall_with_gap(self, "x", -30, -22, 22, [0], 10.0)
	kit.add_wall_with_gap(self, "x", 28, -10, 10, [0], 2.2)
	kit.add_wall(self, Vector3(-10, 0, 24), 8, "z")
	kit.add_wall(self, Vector3(10, 0, 24), 8, "z")

	# South room walls and lobby shoulders.
	kit.add_wall(self, Vector3(-13.5, 0, 20), 17, "x")
	kit.add_wall(self, Vector3(13.5, 0, 20), 17, "x")

	# Corridor walls with one door into each room.
	kit.add_wall_with_gap(self, "z", -5, -30, 20, [-25, -15, -5, 5, 15], 1.9)
	kit.add_wall_with_gap(self, "z", 5, -30, 20, [-25, -15, -5, 5, 15], 1.9)

	# Room partitions.
	for z in [-20.0, -10.0, 0.0, 10.0]:
		kit.add_wall(self, Vector3(-13.5, 0, z), 17, "x")
		kit.add_wall(self, Vector3(13.5, 0, z), 17, "x")

	# North hall.
	kit.add_wall(self, Vector3(-16, 0, -30), 12, "x")
	kit.add_wall(self, Vector3(16, 0, -30), 12, "x")
	kit.add_wall(self, Vector3(-10, 0, -34), 8, "z")
	kit.add_wall(self, Vector3(10, 0, -34), 8, "z")
	kit.add_wall_with_gap(self, "x", -38, -10, 10, [-6, 4], 1.9)

	# Room signs over the corridor doors.
	var west_signs := {
		"15": "INTAKE 03", "5": "STORAGE", "-5": "DAY ROOM",
		"-15": "WEST WASHROOM", "-25": "WARD A",
	}
	var east_signs := {
		"15": "STAFF ONLY", "5": "SECURITY", "-5": "MEDICAL",
		"-15": "RECORDS", "-25": "WARD B",
	}
	for z_text in west_signs:
		kit.add_label_sign(self, str(west_signs[z_text]), Vector3(-4.55, 2.56, float(z_text)), 24, Color("aaa78f"), 0.0036)
	for z_text in east_signs:
		kit.add_label_sign(self, str(east_signs[z_text]), Vector3(4.55, 2.56, float(z_text)), 24, Color("aaa78f"), 0.0036)

func _build_doors() -> void:
	var common_width := 1.68
	_door({"id": "intake", "name": "intake door", "kind": "normal", "plate": "03", "width": common_width}, Vector3(-5, 0, 15), PI * 0.5)
	_door({"id": "storage", "name": "storage door", "kind": "normal", "plate": "STORAGE", "width": common_width}, Vector3(-5, 0, 5), PI * 0.5)
	_door({"id": "day_room", "name": "day room door", "kind": "normal", "plate": "DAY ROOM", "width": common_width}, Vector3(-5, 0, -5), PI * 0.5)
	_door({"id": "washroom", "name": "washroom door", "kind": "normal", "plate": "WASH", "width": common_width}, Vector3(-5, 0, -15), PI * 0.5)
	_door({"id": "ward_a", "name": "ward A door", "kind": "normal", "plate": "WARD A", "width": common_width}, Vector3(-5, 0, -25), PI * 0.5)
	_door({"id": "staff_room", "name": "staff room door", "kind": "normal", "required_item": "staff_card", "plate": "STAFF", "width": common_width}, Vector3(5, 0, 15), PI * 0.5)
	_door({"id": "security", "name": "security door", "kind": "keypad", "plate": "SECURITY", "width": common_width}, Vector3(5, 0, 5), PI * 0.5)
	_door({"id": "medical", "name": "medical door", "kind": "normal", "plate": "MEDICAL", "width": common_width}, Vector3(5, 0, -5), PI * 0.5)
	_door({"id": "records", "name": "records door", "kind": "normal", "plate": "RECORDS", "width": common_width}, Vector3(5, 0, -15), PI * 0.5)
	_door({"id": "ward_b", "name": "ward B door", "kind": "normal", "plate": "WARD B", "width": common_width}, Vector3(5, 0, -25), PI * 0.5)

	_door({"id": "front_exit", "name": "the front door", "kind": "ending", "ending_id": 1, "plate": "MAIN EXIT", "width": 2.0, "hinge_left": false}, Vector3(0, 0, 28), 0.0)
	_door({"id": "day_exit", "name": "the fire exit", "kind": "ending_item", "ending_id": 5, "required_item": "brass_key", "plate": "FIRE EXIT", "width": common_width, "hinge_left": false}, Vector3(-22, 0, -5), PI * 0.5)
	_door({"id": "staff_exit", "name": "the service route", "kind": "ending", "ending_id": 2, "plate": "SERVICE ROUTE", "width": common_width, "style": "metal"}, Vector3(22, 0, 15), PI * 0.5)
	_door({"id": "lift", "name": "the lift", "kind": "ending", "ending_id": 3, "plate": "LIFT", "width": 1.7, "style": "metal"}, Vector3(-6, 0, -38), 0.0)
	_door({"id": "basement_seal", "name": "the basement seal", "kind": "basement", "plate": "SUB-LEVEL C", "width": 1.7, "style": "metal"}, Vector3(4, 0, -38), 0.0)
	_door({"id": "hidden_mirror", "name": "the mirror", "kind": "mirror", "plate": "", "width": 1.78}, Vector3(-22, 0, -15), PI * 0.5)

	kit.add_label_sign(self, "MAIN EXIT", Vector3(0, 2.55, 27.55), 34, Color("b7b29b"), 0.004)
	kit.add_label_sign(self, "LIFT", Vector3(-6, 2.5, -37.55), 28, Color("b7b29b"), 0.0038)
	kit.add_label_sign(self, "SUB-LEVEL C", Vector3(4, 2.5, -37.55), 26, Color("b0837a"), 0.0036)

func _build_crawlspace() -> void:
	kit.add_floor(self, Rect2(-29.4, -16.9, 7.6, 3.8), kit.m_concrete, -0.005)
	kit.add_floor_collision(self, Rect2(-29.4, -16.9, 7.6, 3.8), -0.1)
	kit.add_wall(self, Vector3(-25.6, 0, -13.25), 7.4, "x", 2.35, 0.22)
	kit.add_wall(self, Vector3(-25.6, 0, -16.75), 7.4, "x", 2.35, 0.22)
	kit.add_wall(self, Vector3(-29.25, 0, -15), 3.7, "z", 2.35, 0.22)
	kit.add_static_box(self, Vector3(0.9, 0.65, 0.9), Vector3(-27.5, 0.325, -14.1), kit.m_wood)
	kit.add_static_box(self, Vector3(0.8, 0.52, 0.65), Vector3(-26.4, 0.26, -16.1), kit.m_wood)
	kit.add_static_box(self, Vector3(0.55, 0.48, 0.7), Vector3(-24.6, 0.24, -14.2), kit.m_rust)
	_document("crawl_note", Vector3(-26.4, 0.55, -16.1), 0.4)
	_pickup("override_key", Vector3(-27.5, 0.68, -14.1))
	_trigger({"text": "Crawl toward the pale light", "ending_id": 4}, Vector3(-28.7, 0.15, -15), -PI * 0.5)
	kit.add_wall_lamp(self, Vector3(-26.0, 1.82, -16.45), 0.0, true, 0.85)
	kit.add_flat_stain(self, Vector3(-25.2, 0, -15.1), 1.2, Color(0.05, 0.06, 0.05, 0.35))

func _build_basement() -> void:
	_basement = Node3D.new()
	_basement.name = "Basement"
	_basement.position.y = -4.0
	add_child(_basement)
	kit.add_floor(_basement, Rect2(-15.7, -67.8, 31.4, 26.0), kit.m_concrete, 0.0)
	kit.add_floor_collision(_basement, Rect2(-15.7, -67.8, 31.4, 26.0), -0.1)
	kit.add_flat_stain(_basement, Vector3(-10.4, 0, -52.4), 1.4, Color(0.035, 0.045, 0.04, 0.18))
	kit.add_flat_stain(_basement, Vector3(4.4, 0, -62.8), 1.2, Color(0.035, 0.045, 0.04, 0.16))
	# Outer walls.
	kit.add_wall(_basement, Vector3(-15.5, 0, -54.8), 26, "z", 2.7, 0.34)
	kit.add_wall(_basement, Vector3(15.5, 0, -54.8), 26, "z", 2.7, 0.34)
	kit.add_wall(_basement, Vector3(0, 0, -42.2), 31, "x", 2.7, 0.34)
	kit.add_wall_with_gap(_basement, "x", -67.5, -15.5, 15.5, [0], 2.1, 2.7, 0.34)
	# Supports and a wide arch into the return chamber.
	kit.add_wall(_basement, Vector3(-11.2, 0, -58), 8.6, "x", 2.7, 0.34)
	kit.add_wall(_basement, Vector3(11.2, 0, -58), 8.6, "x", 2.7, 0.34)
	for x in [-12.8, -4.8, 4.8, 12.8]:
		kit.add_static_box(_basement, Vector3(0.45, 2.7, 0.45), Vector3(x, 1.35, -50.3), kit.m_concrete)
	# Return chamber centerpiece.
	kit.add_static_box(_basement, Vector3(2.4, 0.24, 2.4), Vector3(0, 0.12, -62.8), kit.m_metal)
	var column := CylinderMesh.new()
	column.top_radius = 0.3
	column.bottom_radius = 0.5
	column.height = 2.4
	var col_inst := MeshInstance3D.new()
	col_inst.mesh = column
	col_inst.material_override = kit.m_rust
	col_inst.position = Vector3(0, 1.4, -62.8)
	_basement.add_child(col_inst)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.65
	ring.outer_radius = 0.86
	ring.rings = 24
	ring.ring_segments = 12
	var ring_inst := MeshInstance3D.new()
	ring_inst.mesh = ring
	ring_inst.material_override = kit.m_emissive_red
	ring_inst.position = Vector3(0, 2.34, -62.8)
	_basement.add_child(ring_inst)
	kit.add_static_box(_basement, Vector3(2.4, 0.15, 0.15), Vector3(0, 3.08, -62.8), kit.m_metal)
	kit.add_collision(_basement, Vector3(2.5, 2.7, 2.5), Vector3(0, 1.35, -62.8))
	kit.add_label_sign(_basement, "RETURN", Vector3(0, 2.95, -62.8), 30, Color("b66b5e"), 0.004)
	# Hero props.
	_boiler(Vector3(-12.0, 0, -46.7))
	kit.add_shelf(_basement, Vector3(12.0, 0, -52.5), PI * 0.5, 2.8)
	kit.add_shelf(_basement, Vector3(12.0, 0, -55.0), PI * 0.5, 2.8)
	kit.add_desk(_basement, Vector3(-9.4, 0, -55.4), 0.0, 1.7)
	kit.add_cabinet(_basement, Vector3(-15.0, 0, -59.8), PI * 0.5, 1.2)
	kit.add_gurney(_basement, Vector3(9.0, 0, -45.5), 0.5)
	for i in range(3):
		kit.add_static_box(_basement, Vector3(0.9, 0.8, 0.9), Vector3(-5.4 + i * 1.0, 0.4, -48.8), kit.m_wood)
	for p in [
		Vector3(-8.0, 1.8, -51.0), Vector3(7.8, 1.75, -64.2), Vector3(-2.2, 1.7, -59.0),
		Vector3(1.6, 1.8, -45.6), Vector3(9.0, 1.8, -47.0), Vector3(-1.8, 1.8, -50.8),
		Vector3(-14.3, 1.95, -52.1), Vector3(0.0, 1.8, -62.0),
	]:
		_hanging_bulb(_basement, p, Color("d2a06e") if p.z > -60.0 else Color("bd5648"), 0.85)
	kit.add_wall_lamp(_basement, Vector3(-15.16, 1.9, -54.6), PI * 0.5, false, 0.8)
	kit.add_wall_lamp(_basement, Vector3(-15.16, 2.1, -50.7), PI * 0.5, false, 0.95)
	kit.add_pipes(_basement, Vector3(-15.2, 2.3, -63.5), Vector3(-15.2, 1.1, -44.0), 0.07)
	kit.add_pipes(_basement, Vector3(15.2, 2.2, -66.0), Vector3(15.2, 1.4, -49.0), 0.06)
	kit.add_pipes(_basement, Vector3(-14.8, 2.2, -58.0), Vector3(14.8, 2.2, -58.0), 0.055)
	kit.add_debris(_basement, Vector3(-7.8, 0, -62.0), Vector2(3, 2.4), 18)
	kit.add_debris(_basement, Vector3(10.2, 0, -53.0), Vector2(2.6, 3.2), 14)
	for spec in [
		[Vector3(0, 2.4, -54.5), 2.0, 30.0, Color("b7a98a")],
		[Vector3(-9.0, 2.2, -47.5), 1.2, 17.0, Color("b49a78")],
		[Vector3(9.0, 2.2, -58.0), 1.2, 17.0, Color("b49a78")],
	]:
		var fill := OmniLight3D.new()
		fill.light_color = spec[3]
		fill.light_energy = spec[1]
		fill.omni_range = spec[2]
		fill.omni_attenuation = 0.65
		fill.position = spec[0]
		fill.shadow_enabled = false
		_basement.add_child(fill)
	_puzzle("dial", "Return Carrier", Vector3(-15.18, 0, -52.2), PI * 0.5, _basement)
	_document("boiler_note", Vector3(-9.4, 0.82, -55.4), 3.9, _basement)
	_door({"id": "service_tunnel", "name": "the service tunnel", "kind": "true_exit", "plate": "SERVICE TUNNEL", "width": 1.8, "style": "metal"}, Vector3(0, 0, -67.5), 0.0, _basement)
	var up = StairsScript.new()
	up.position = Vector3(3.3, 0, -43.0)
	_basement.add_child(up)
	kit.add_static_box(_basement, Vector3(3.2, 0.14, 1.0), Vector3(0, 0.07, -42.75), kit.m_wood)
	for i in range(3):
		kit.add_box(_basement, Vector3(3.0, 0.2, 0.55), Vector3(0, 0.2 + i * 0.2, -42.8 - i * 0.42), kit.m_wood)
	kit.add_label_sign(_basement, "RETURN CARRIER", Vector3(-3.8, 2.5, -59.5), 24, Color("8f8370"), 0.0034)

func _boiler(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	_basement.add_child(root)
	var tank := CylinderMesh.new()
	tank.top_radius = 1.15
	tank.bottom_radius = 1.3
	tank.height = 2.2
	var tank_inst := MeshInstance3D.new()
	tank_inst.mesh = tank
	tank_inst.material_override = kit.m_rust
	tank_inst.position.y = 1.1
	root.add_child(tank_inst)
	kit.add_box(root, Vector3(1.9, 0.35, 1.9), Vector3(0, 2.35, 0), kit.m_metal)
	kit.add_box(root, Vector3(0.35, 1.4, 0.35), Vector3(0.9, 0.7, 0), kit.m_metal)
	kit.add_collision(root, Vector3(2.5, 2.5, 2.5), Vector3(0, 1.25, 0))
	kit.add_pipes(_basement, pos + Vector3(0, 1.63, 0.6), pos + Vector3(0, 2.2, 5.0), 0.09)

func _hanging_bulb(parent: Node3D, pos: Vector3, color: Color, energy: float) -> void:
	var fixture := Node3D.new()
	fixture.position = pos
	parent.add_child(fixture)
	kit.add_box(fixture, Vector3(0.04, 0.65, 0.04), Vector3(0, 0.58, 0), kit.m_black)
	var bulb := SphereMesh.new()
	bulb.radius = 0.1
	bulb.height = 0.2
	bulb.radial_segments = 10
	var bulb_inst := MeshInstance3D.new()
	bulb_inst.mesh = bulb
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.2
	bulb_inst.material_override = mat
	bulb_inst.position = Vector3(0, 0.2, 0)
	fixture.add_child(bulb_inst)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 9.0
	light.position = Vector3(0, 0.15, 0)
	light.shadow_enabled = false
	light.set_script(load("res://scripts/flicker_light.gd"))
	fixture.add_child(light)
	light.set("base_energy", energy)
	light.set("flicker_strength", 0.24)
	light.set("flicker_seed", randf() * 800.0)


func _build_room_contents() -> void:
	_build_intake()
	_build_storage()
	_build_day_room()
	_build_washroom()
	_build_ward_a()
	_build_ward_b()
	_build_records()
	_build_medical()
	_build_security()
	_build_staff_room()
	_build_lobby()
	_build_north_hall()
	_build_corridor_dressing()
	_build_extra_scares()
	_build_doors()


func _build_intake() -> void:
	kit.add_bed(self, Vector3(-18.3, 0, 12.8))
	kit.add_bed(self, Vector3(-18.3, 0, 17.2))
	kit.add_bedside(self, Vector3(-16.1, 0, 15.0))
	kit.add_desk(self, Vector3(-8.4, 0, 18.5), 0.0, 1.45)
	kit.add_chair(self, Vector3(-7.0, 0, 16.8), PI)
	kit.add_ceiling_lamp(self, Vector3(-13.0, 0, 15.0), true, true, 1.55, 8.5)
	kit.add_wall_lamp(self, Vector3(-21.75, 1.95, 18.4), PI * 0.5, false, 0.65)
	kit.add_wall_decal(self, kit.scrawl_41_tex, Vector3(-21.84, 1.65, 11.8), Vector2(1.2, 1.2), PI * 0.5, Color(0.52, 0.5, 0.43, 0.7))
	kit.add_wall_decal(self, kit.scrawl_back_tex, Vector3(-14.0, 1.7, 10.16), Vector2(2.2, 0.7), 0.0, Color(0.45, 0.43, 0.38, 0.65))
	kit.add_flat_stain(self, Vector3(-12.5, 0, 16.1), 1.4, Color(0.06, 0.065, 0.055, 0.4))
	kit.add_paper_scatter(self, Vector3(-12.6, 0, 18.2), Vector2(1.2, 0.5), 5)
	_document("intake_06", Vector3(-8.4, 0.82, 18.4), 0.15)
	kit.add_ghost(self, Vector3(-19.0, 1.65, 14.9), 0.9)


func _build_storage() -> void:
	kit.add_shelf(self, Vector3(-21.0, 0, 2.6), PI * 0.5, 2.5)
	kit.add_shelf(self, Vector3(-21.0, 0, 7.4), PI * 0.5, 2.5)
	kit.add_desk(self, Vector3(-10.2, 0, 7.7), 0.0, 1.6)
	kit.add_chair(self, Vector3(-10.2, 0, 9.0), PI)
	kit.add_static_box(self, Vector3(1.05, 0.75, 0.9), Vector3(-15.5, 0.375, 2.1), kit.m_wood)
	kit.add_static_box(self, Vector3(0.8, 0.6, 0.9), Vector3(-14.1, 0.3, 2.4), kit.m_wood)
	kit.add_static_box(self, Vector3(1.1, 0.9, 1.1), Vector3(-7.4, 0.45, 1.6), kit.m_wood)
	kit.add_ceiling_lamp(self, Vector3(-13.0, 0, 5.0), true, false, 1.15, 7.5)
	kit.add_wall_lamp(self, Vector3(-21.76, 2.0, 5.0), PI * 0.5, true, 0.6)
	kit.add_paper_scatter(self, Vector3(-12.2, 0, 6.5), Vector2(2.4, 1.4), 12)
	kit.add_debris(self, Vector3(-17.0, 0, 6.0), Vector2(2.4, 2.0), 10)
	kit.add_flat_stain(self, Vector3(-9.5, 0, 3.3), 1.1)
	_document("maintenance_note", Vector3(-10.2, 0.82, 7.7), 0.12)
	_pickup("brass_key", Vector3(-20.7, 1.33, 2.6))
	kit.add_wall_decal(self, kit.scrawl_back_tex, Vector3(-21.84, 1.9, 9.3), Vector2(1.8, 0.58), PI * 0.5, Color(0.4, 0.38, 0.34, 0.55))


func _build_day_room() -> void:
	kit.add_desk(self, Vector3(-13.0, 0, -7.2), 0.0, 2.4)
	for chair_data in [
		[Vector3(-15.0, 0, -5.7), PI], [Vector3(-13.1, 0, -5.7), PI],
		[Vector3(-11.2, 0, -5.7), PI], [Vector3(-14.6, 0, -8.8), 0.0],
	]:
		kit.add_chair(self, chair_data[0], chair_data[1])
	kit.add_static_box(self, Vector3(2.3, 1.12, 0.62), Vector3(-9.2, 0.56, -9.3), kit.m_wood)
	kit.add_static_box(self, Vector3(1.8, 0.1, 0.55), Vector3(-9.2, 1.2, -9.3), kit.m_white)
	kit.add_box(self, Vector3(0.35, 0.65, 0.06), Vector3(-9.2, 0.86, -8.98), kit.m_black)
	_window(Vector3(-21.85, 1.9, -8.3), PI * 0.5)
	kit.add_ceiling_lamp(self, Vector3(-13.0, 0, -4.5), true, true, 1.05, 7.2)
	kit.add_flat_stain(self, Vector3(-11.5, 0, -3.5), 1.8, Color(0.055, 0.06, 0.05, 0.4))
	kit.add_paper_scatter(self, Vector3(-12.4, 0, -3.2), Vector2(2.5, 1.2), 9)
	kit.add_ghost(self, Vector3(-17.4, 1.7, -3.0), 1.0)
	kit.add_wall_decal(self, kit.scrawl_back_tex, Vector3(-5.14, 1.7, -8.6), Vector2(2.0, 0.65), -PI * 0.5, Color(0.46, 0.44, 0.38, 0.6))
	kit.add_label_sign(self, "DAY ROOM", Vector3(-13.0, 2.0, -9.72), 22, Color("938d79"), 0.0034)


func _build_washroom() -> void:
	for z in [-18.4, -11.6]:
		kit.add_sink(self, Vector3(-21.0, 0, z), PI * 0.5)
		kit.add_mirror_frame(self, Vector3(-21.86, 1.6, z), PI * 0.5, 1.0, 1.25)
	for z in [-18.7, -11.3]:
		kit.add_toilet(self, Vector3(-6.75, 0, z), -PI * 0.5)
	kit.add_static_box(self, Vector3(0.08, 1.6, 1.3), Vector3(-8.1, 0.8, -15.0), kit.m_tile)
	kit.add_static_box(self, Vector3(1.15, 0.7, 0.8), Vector3(-9.5, 0.35, -19.1), kit.m_white)
	kit.add_ceiling_lamp(self, Vector3(-13.5, 0, -12.4), true, false, 0.8, 6.3)
	kit.add_ceiling_lamp(self, Vector3(-13.5, 0, -17.8), true, false, 0.7, 6.0)
	kit.add_wall_lamp(self, Vector3(-21.76, 2.0, -15.0), PI * 0.5, true, 0.55)
	kit.add_flat_stain(self, Vector3(-18.3, 0, -14.7), 1.9, Color(0.04, 0.045, 0.04, 0.5))
	kit.add_flat_stain(self, Vector3(-10.0, 0, -17.8), 1.3, Color(0.05, 0.06, 0.05, 0.4))
	kit.add_ghost(self, Vector3(-20.1, 1.65, -13.0), 0.8)


func _build_ward_a() -> void:
	for z in [-21.7, -24.3, -26.9]:
		kit.add_bed(self, Vector3(-19.2, 0, z))
	kit.add_bed(self, Vector3(-11.0, 0, -21.9), PI * 0.5)
	kit.add_bedside(self, Vector3(-17.4, 0, -22.2))
	kit.add_bedside(self, Vector3(-17.4, 0, -26.4))
	kit.add_ceiling_lamp(self, Vector3(-13.5, 0, -24.8), true, true, 1.2, 8.0)
	kit.add_wall_lamp(self, Vector3(-21.75, 2.0, -28.1), PI * 0.5, true, 0.6)
	_window(Vector3(-21.85, 1.92, -27.2), PI * 0.5)
	kit.add_wall_decal(self, kit.scrawl_41_tex, Vector3(-12.8, 1.65, -29.83), Vector2(1.2, 1.2), 0.0, Color(0.5, 0.47, 0.4, 0.7))
	kit.add_wall_decal(self, kit.scrawl_subject_tex, Vector3(-11.6, 1.9, -29.82), Vector2(1.8, 0.6), 0.0, Color(0.44, 0.42, 0.37, 0.58))
	kit.add_flat_stain(self, Vector3(-12.8, 0, -25.4), 1.7)
	kit.add_paper_scatter(self, Vector3(-13.4, 0, -28.0), Vector2(1.8, 0.8), 8)
	kit.add_ghost(self, Vector3(-12.0, 1.7, -23.1), 1.0)
	_document("patient_13", Vector3(-17.4, 0.7, -22.2), 0.08)
	_pickup("fuse_power", Vector3(-17.4, 0.74, -26.4))


func _build_ward_b() -> void:
	for z in [-21.7, -24.3, -26.9]:
		kit.add_bed(self, Vector3(19.2, 0, z))
	kit.add_bed(self, Vector3(11.0, 0, -28.1), PI * 0.5)
	kit.add_bedside(self, Vector3(17.4, 0, -22.2))
	kit.add_bedside(self, Vector3(17.4, 0, -26.4))
	kit.add_ceiling_lamp(self, Vector3(13.5, 0, -24.8), true, false, 1.05, 7.5)
	kit.add_wall_lamp(self, Vector3(21.75, 2.0, -27.8), -PI * 0.5, true, 0.55)
	_window(Vector3(21.85, 1.92, -28.5), -PI * 0.5)
	kit.add_wall_decal(self, kit.scrawl_subject_tex, Vector3(12.0, 1.85, -29.82), Vector2(2.3, 0.75), 0.0, Color(0.55, 0.45, 0.4, 0.65))
	kit.add_wall_decal(self, kit.scrawl_41_tex, Vector3(9.6, 1.6, -29.83), Vector2(0.95, 0.95), 0.0, Color(0.45, 0.42, 0.36, 0.64))
	kit.add_flat_stain(self, Vector3(14.0, 0, -24.0), 2.0)
	kit.add_debris(self, Vector3(15.9, 0, -20.8), Vector2(2.0, 1.1), 10)
	kit.add_ghost(self, Vector3(12.8, 1.6, -23.0), 0.9)
	_pickup("fuse_lift", Vector3(17.4, 0.74, -26.4))


func _build_records() -> void:
	for z in [-18.5, -16.9, -13.1]:
		kit.add_cabinet(self, Vector3(20.45, 0, z), -PI * 0.5, 1.0)
	kit.add_desk(self, Vector3(12.0, 0, -12.4), 0.0, 1.9)
	kit.add_chair(self, Vector3(12.0, 0, -10.9), 0.0)
	kit.add_shelf(self, Vector3(8.3, 0, -19.4), 0.0, 2.6)
	kit.add_static_box(self, Vector3(0.9, 0.14, 0.6), Vector3(12.7, 0.86, -12.55), kit.m_black)
	kit.add_box(self, Vector3(0.65, 0.05, 0.5), Vector3(12.7, 0.98, -12.55), kit.m_paper)
	kit.add_ceiling_lamp(self, Vector3(13.5, 0, -15.0), true, false, 1.1, 7.6)
	kit.add_wall_lamp(self, Vector3(21.74, 2.0, -19.0), -PI * 0.5, true, 0.55)
	kit.add_paper_scatter(self, Vector3(12.4, 0, -15.5), Vector2(2.0, 1.5), 16)
	kit.add_wall_decal(self, kit.scrawl_back_tex, Vector3(5.14, 1.7, -18.1), Vector2(1.9, 0.6), PI * 0.5, Color(0.4, 0.4, 0.35, 0.5))
	_document("staff_memo", Vector3(12.0, 0.82, -12.35), -0.05)
	_pickup("fuse_records", Vector3(13.15, 0.8, -12.4))


func _build_medical() -> void:
	kit.add_bed(self, Vector3(19.0, 0, -2.9))
	kit.add_bed(self, Vector3(19.0, 0, -7.1))
	kit.add_cabinet(self, Vector3(20.45, 0, -7.0), -PI * 0.5, 1.1)
	kit.add_desk(self, Vector3(12.0, 0, -7.4), 0.0, 1.7)
	kit.add_chair(self, Vector3(12.0, 0, -5.9), 0.0)
	kit.add_sink(self, Vector3(8.4, 0, -9.2), 0.0)
	kit.add_static_box(self, Vector3(0.5, 1.5, 0.5), Vector3(15.0, 0.75, -1.2), kit.m_metal)
	kit.add_box(self, Vector3(0.05, 1.5, 0.05), Vector3(15.0, 0.75, -1.2), kit.m_black)
	kit.add_ceiling_lamp(self, Vector3(13.5, 0, -4.8), true, false, 1.25, 8.0)
	kit.add_wall_lamp(self, Vector3(21.74, 2.0, -2.2), -PI * 0.5, false, 0.5)
	kit.add_flat_stain(self, Vector3(14.0, 0, -8.0), 1.2)
	kit.add_paper_scatter(self, Vector3(12.4, 0, -8.8), Vector2(1.4, 0.6), 8)
	_document("medical_chart", Vector3(12.0, 0.82, -7.4), 0.04)
	_pickup("staff_card", Vector3(20.45, 1.96, -7.0))


func _build_security() -> void:
	kit.add_desk(self, Vector3(12.5, 0, 3.2), 0.0, 2.0)
	kit.add_chair(self, Vector3(12.5, 0, 4.7), PI)
	kit.add_cabinet(self, Vector3(8.0, 0, 1.0), 0.0, 1.0)
	kit.add_screen(self, Vector3(10.4, 1.75, 0.22), Vector2(1.3, 0.8), 0.0)
	kit.add_screen(self, Vector3(12.0, 1.75, 0.22), Vector2(1.1, 0.75), 0.0)
	kit.add_screen(self, Vector3(13.5, 1.75, 0.22), Vector2(0.95, 0.7), 0.0)
	kit.add_ceiling_lamp(self, Vector3(13.0, 0, 5.0), true, false, 1.15, 7.5)
	kit.add_wall_lamp(self, Vector3(21.74, 2.0, 2.5), -PI * 0.5, false, 0.55)
	kit.add_wall_lamp(self, Vector3(18.0, 2.2, 9.72), PI, false, 1.05)
	kit.add_flat_stain(self, Vector3(16.0, 0, 7.0), 1.3)
	_document("security_log", Vector3(12.5, 0.82, 3.2), 0.03)
	_puzzle("anchor", "Anchor Array Console", Vector3(18.0, 0, 8.0), 0.0)
	kit.add_label_sign(self, "ANCHOR ARRAY", Vector3(21.55, 2.55, 8.0), 22, Color("9d9a83"), 0.0032)


func _build_staff_room() -> void:
	kit.add_desk(self, Vector3(13.5, 0, 13.0), 0.0, 2.2)
	for chair_data in [
		[Vector3(12.2, 0, 11.4), 0.0], [Vector3(14.7, 0, 11.4), 0.0],
		[Vector3(12.2, 0, 14.7), PI], [Vector3(14.7, 0, 14.7), PI],
	]:
		kit.add_chair(self, chair_data[0], chair_data[1])
	for x in [8.4, 10.0, 11.6]:
		kit.add_static_box(self, Vector3(1.1, 1.9, 0.55), Vector3(x, 0.95, 10.5), kit.m_metal)
	kit.add_cabinet(self, Vector3(20.45, 0, 12.4), -PI * 0.5, 1.15)
	kit.add_static_box(self, Vector3(1.1, 1.8, 0.75), Vector3(8.4, 0.9, 19.2), kit.m_black)
	kit.add_box(self, Vector3(0.8, 1.2, 0.02), Vector3(8.4, 1.1, 18.8), kit.m_emissive_cold)
	kit.add_ceiling_lamp(self, Vector3(14.0, 0, 16.0), true, true, 1.25, 8.0)
	kit.add_flat_stain(self, Vector3(17.0, 0, 14.0), 1.1)
	kit.add_debris(self, Vector3(18.3, 0, 18.2), Vector2(1.9, 1.2), 8)
	_document("tally_scrap", Vector3(13.5, 0.82, 13.0), 0.04)
	kit.add_label_sign(self, "SERVICE ROUTE", Vector3(21.55, 2.55, 15.0), 22, Color("b7a88d"), 0.0032)


func _build_lobby() -> void:
	kit.add_reception_counter(self, Vector3(6.0, 0, 23.8), PI)
	kit.add_chair(self, Vector3(-6.5, 0, 23.0), PI * 0.5)
	kit.add_chair(self, Vector3(-6.5, 0, 25.2), PI * 0.5)
	kit.add_plant(self, Vector3(-8.6, 0, 21.4))
	kit.add_plant(self, Vector3(8.6, 0, 26.4))
	kit.add_static_box(self, Vector3(0.06, 1.2, 2.1), Vector3(9.82, 1.5, 23.8), kit.m_dark)
	kit.add_ceiling_lamp(self, Vector3(-3.8, 0, 23.5), true, true, 1.0, 7.2)
	kit.add_ceiling_lamp(self, Vector3(4.4, 0, 25.0), true, false, 0.9, 6.8)
	kit.add_wall_lamp(self, Vector3(0, 2.25, 27.7), PI, false, 0.6)
	kit.add_wall_decal(self, kit.scrawl_back_tex, Vector3(9.83, 1.6, 23.8), Vector2(1.8, 0.58), -PI * 0.5, Color(0.45, 0.42, 0.37, 0.55))
	kit.add_wall_decal(self, kit.scrawl_back_tex, Vector3(-10.14, 1.6, 24.2), Vector2(1.6, 0.52), PI * 0.5, Color(0.38, 0.36, 0.32, 0.5))
	var rug := MeshInstance3D.new()
	var rug_mesh := BoxMesh.new()
	rug_mesh.size = Vector3(4.8, 0.018, 5.4)
	rug.mesh = rug_mesh
	rug.material_override = kit.m_green_fabric
	rug.position = Vector3(-4.2, 0.012, 23.9)
	rug.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rug)
	kit.add_paper_scatter(self, Vector3(0, 0, 25.0), Vector2(4.0, 1.5), 10)
	kit.add_flat_stain(self, Vector3(0, 0, 25.8), 1.5)
	kit.add_label_sign(self, "BLACK SITE", Vector3(0, 2.15, 20.4), 36, Color("bcb7a0"), 0.0046)


func _build_north_hall() -> void:
	_bench(Vector3(-2.6, 0, -32.2), 0.0)
	kit.add_wheelchair(self, Vector3(2.4, 0, -32.0), -0.6)
	kit.add_wall_lamp(self, Vector3(-9.75, 2.1, -34.0), PI * 0.5, true, 0.65)
	kit.add_wall_lamp(self, Vector3(9.75, 2.1, -34.0), -PI * 0.5, true, 0.55)
	kit.add_box(self, Vector3(1.8, 0.02, 0.4), Vector3(-6, 0.02, -36.3), kit.m_emissive_warm)
	kit.add_box(self, Vector3(1.8, 0.02, 0.4), Vector3(4, 0.02, -36.3), kit.m_emissive_red)
	kit.add_wall_decal(self, kit.scrawl_subject_tex, Vector3(-9.84, 1.7, -36.0), Vector2(1.6, 0.55), PI * 0.5, Color(0.43, 0.4, 0.35, 0.55))
	kit.add_paper_scatter(self, Vector3(0, 0, -34.0), Vector2(3.6, 1.2), 9)
	kit.add_flat_stain(self, Vector3(0.0, 0, -31.0), 1.5)
	kit.add_ghost(self, Vector3(-7.2, 1.6, -35.5), 0.85)


func _bench(pos: Vector3, rot_y: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rot_y
	add_child(root)
	kit.add_box(root, Vector3(2.3, 0.12, 0.55), Vector3(0, 0.55, 0), kit.m_wood)
	kit.add_box(root, Vector3(2.3, 0.55, 0.08), Vector3(0, 0.9, 0.22), kit.m_wood)
	for x in [-0.9, 0.9]:
		kit.add_box(root, Vector3(0.08, 0.55, 0.08), Vector3(x, 0.28, -0.18), kit.m_metal)
		kit.add_box(root, Vector3(0.08, 0.55, 0.08), Vector3(x, 0.28, 0.18), kit.m_metal)
	kit.add_collision(root, Vector3(2.3, 0.7, 0.65), Vector3(0, 0.35, 0))


func _build_corridor_dressing() -> void:
	for z in [-27.0, -17.5, -8.5, 1.0, 10.0, 17.0]:
		kit.add_ceiling_lamp(self, Vector3(0, 0, z), true, false if z < -10 else true, 0.95, 7.0)
	kit.add_gurney(self, Vector3(-2.1, 0, 3.1), PI * 0.5)
	kit.add_static_box(self, Vector3(0.82, 0.7, 0.45), Vector3(3.9, 0.35, -8.0), kit.m_wood)
	kit.add_plant(self, Vector3(-3.8, 0, 19.0))
	kit.add_wall_decal(self, kit.scrawl_back_tex, Vector3(-4.84, 1.85, -11.0), Vector2(2.3, 0.72), PI * 0.5, Color(0.46, 0.43, 0.38, 0.62))
	kit.add_wall_decal(self, kit.scrawl_41_tex, Vector3(4.83, 1.55, -20.5), Vector2(0.95, 0.95), -PI * 0.5, Color(0.4, 0.37, 0.33, 0.55))
	kit.add_wall_decal(self, kit.scrawl_subject_tex, Vector3(-4.84, 1.7, -22.0), Vector2(1.7, 0.55), PI * 0.5, Color(0.38, 0.36, 0.32, 0.5))
	for center in [Vector3(0, 0, -19.0), Vector3(1.8, 0, 7.0), Vector3(0, 0, 11.5)]:
		kit.add_flat_stain(self, center, randf_range(0.8, 1.6))
	kit.add_paper_scatter(self, Vector3(0, 0, -4.5), Vector2(3.2, 2.0), 18)
	kit.add_paper_scatter(self, Vector3(0.6, 0, 12.5), Vector2(2.3, 1.6), 10)
	kit.add_debris(self, Vector3(-1.2, 0, -27.6), Vector2(2.4, 1.5), 13)
	kit.add_ghost(self, Vector3(-1.3, 1.6, -13.5), 1.05)
	kit.add_ghost(self, Vector3(1.4, 1.55, -28.5), 0.7)


func _build_extra_scares() -> void:
	kit.add_gurney(self, Vector3(8.7, 0, 21.3), 0.1)
	kit.add_body_bag(self, Vector3(8.7, 1.02, 21.3), 0.1)
	kit.add_wheelchair(self, Vector3(-7.0, 0, 21.0), 0.7)
	kit.add_restraint_chair(self, Vector3(-8.9, 0, 26.2), PI * 0.5)
	kit.add_hanging_sheet(self, Vector3(9.55, 0, 22.0), 1.2, 2.0, PI * 0.5)
	kit.add_specimen_jars(self, Vector3(6.0, 1.12, 23.8), 0.0, 3)
	kit.add_blood_trail(self, Vector3(0, 0, 27.2), Vector3(0, 0, 21.0), 8)
	kit.add_ceiling_stain(self, Vector3(3.0, 2.78, 24.2), 1.2)
	kit.add_ghost(self, Vector3(7.4, 1.65, 25.6), 1.15)

	kit.add_wheelchair(self, Vector3(-6.8, 0, 12.2), 0.3)
	kit.add_blood_trail(self, Vector3(-7.0, 0, 15.0), Vector3(-18.0, 0, 15.0), 7)
	kit.add_ceiling_stain(self, Vector3(-13.0, 2.78, 13.5), 0.9)

	kit.add_body_bag(self, Vector3(-8.2, 0.02, 3.1), 0.4)
	kit.add_restraint_chair(self, Vector3(-18.0, 0, 3.2), -PI * 0.5)
	kit.add_hanging_sheet(self, Vector3(-21.4, 0, 4.8), 1.0, 1.9, PI * 0.5)
	kit.add_blood_trail(self, Vector3(-8.0, 0, 7.5), Vector3(-18.0, 0, 3.5), 6)

	kit.add_wheelchair(self, Vector3(-18.2, 0, -7.9), -0.5)
	kit.add_iv_stand(self, Vector3(-15.2, 0, -6.2))
	kit.add_hanging_sheet(self, Vector3(-21.3, 0, -4.8), 1.0, 1.9, PI * 0.5)
	kit.add_blood_trail(self, Vector3(-11.0, 0, -3.5), Vector3(-19.0, 0, -8.0), 6)
	kit.add_ceiling_stain(self, Vector3(-13.0, 2.78, -8.2), 0.85)

	kit.add_hanging_sheet(self, Vector3(-9.4, 0, -18.4), 0.9, 1.85, 0.0)
	kit.add_hanging_sheet(self, Vector3(-9.4, 0, -11.6), 0.9, 1.85, 0.0)
	kit.add_restraint_chair(self, Vector3(-10.5, 0, -13.0), 0.6)
	kit.add_blood_trail(self, Vector3(-8.0, 0, -15.0), Vector3(-20.0, 0, -15.0), 7)
	kit.add_ceiling_stain(self, Vector3(-13.5, 2.78, -15.0), 1.0)

	kit.add_body_bag(self, Vector3(-19.2, 0.72, -24.3), 0.0)
	kit.add_restraints(self, Vector3(-19.2, 0.72, -21.7), 0.0)
	kit.add_restraints(self, Vector3(-19.2, 0.72, -26.9), 0.0)
	kit.add_iv_stand(self, Vector3(-16.2, 0, -24.6))
	kit.add_blood_trail(self, Vector3(-18.0, 0, -24.0), Vector3(-6.0, 0, -24.0), 7)
	kit.add_ceiling_stain(self, Vector3(-13.5, 2.78, -25.2), 1.0)

	kit.add_body_bag(self, Vector3(19.2, 0.72, -24.3), 0.0)
	kit.add_restraints(self, Vector3(19.2, 0.72, -21.7), 0.0)
	kit.add_restraints(self, Vector3(19.2, 0.72, -26.9), 0.0)
	kit.add_iv_stand(self, Vector3(16.2, 0, -24.6))
	kit.add_blood_trail(self, Vector3(18.0, 0, -24.0), Vector3(6.0, 0, -24.0), 7)
	kit.add_ceiling_stain(self, Vector3(13.5, 2.78, -25.2), 1.0)

	kit.add_gurney(self, Vector3(7.0, 0, -17.0), -0.15)
	kit.add_body_bag(self, Vector3(7.0, 1.02, -17.0), -0.15)
	kit.add_specimen_jars(self, Vector3(8.3, 2.12, -19.4), 0.0, 4)
	kit.add_restraint_chair(self, Vector3(18.7, 0, -10.7), -PI * 0.5)
	kit.add_blood_trail(self, Vector3(18.0, 0, -15.0), Vector3(6.0, 0, -15.0), 8)
	kit.add_ceiling_stain(self, Vector3(13.5, 2.78, -16.0), 1.0)
	kit.add_ghost(self, Vector3(18.7, 1.7, -16.8), 0.95)

	kit.add_gurney(self, Vector3(7.2, 0, -1.2), 0.2)
	kit.add_body_bag(self, Vector3(7.2, 1.02, -1.2), 0.2)
	kit.add_cabinet(self, Vector3(20.45, 0, -3.0), -PI * 0.5, 1.0)
	kit.add_specimen_jars(self, Vector3(20.45, 1.92, -3.0), -PI * 0.5, 4)
	kit.add_iv_stand(self, Vector3(17.8, 0, -4.7))
	kit.add_surgical_tray(self, Vector3(15.4, 0, -4.4), 0.2)
	kit.add_restraints(self, Vector3(19.0, 0.72, -2.9), 0.0)
	kit.add_restraints(self, Vector3(19.0, 0.72, -7.1), 0.0)
	kit.add_hanging_sheet(self, Vector3(7.4, 0, -8.6), 1.5, 2.1, PI * 0.5)
	kit.add_blood_trail(self, Vector3(18.0, 0, -7.0), Vector3(6.0, 0, -7.0), 6)
	kit.add_ceiling_stain(self, Vector3(13.5, 2.78, -4.8), 1.0)

	kit.add_wheelchair(self, Vector3(18.6, 0, 5.8), -0.7)
	kit.add_restraint_chair(self, Vector3(7.0, 0, 6.6), PI * 0.5)
	kit.add_blood_trail(self, Vector3(20.0, 0, 6.0), Vector3(6.0, 0, 2.0), 6)
	kit.add_ceiling_stain(self, Vector3(13.0, 2.78, 4.0), 0.9)
	kit.add_ghost(self, Vector3(19.8, 1.7, 7.6), 0.9)

	kit.add_gurney(self, Vector3(8.2, 0, 17.5), 0.0)
	kit.add_body_bag(self, Vector3(8.2, 1.02, 17.5), 0.0)
	kit.add_blood_trail(self, Vector3(18.0, 0, 12.0), Vector3(7.0, 0, 18.0), 7)
	kit.add_ceiling_stain(self, Vector3(14.0, 2.78, 15.0), 1.0)
	kit.add_hanging_sheet(self, Vector3(20.9, 0, 17.8), 1.0, 2.0, -PI * 0.5)

	kit.add_gurney(self, Vector3(6.0, 0, -31.2), 0.3)
	kit.add_body_bag(self, Vector3(6.0, 1.02, -31.2), 0.3)
	kit.add_blood_trail(self, Vector3(0, 0, -30.0), Vector3(0, 0, -37.0), 5)
	kit.add_ceiling_stain(self, Vector3(0, 2.78, -34.0), 1.1)
	kit.add_hanging_sheet(self, Vector3(-9.4, 0, -31.0), 1.1, 1.9, PI * 0.5)

	kit.add_gurney(self, Vector3(3.0, 0, -22.5), 0.1)
	kit.add_body_bag(self, Vector3(3.0, 1.02, -22.5), 0.1)
	kit.add_iv_stand(self, Vector3(-4.0, 0, -8.8))
	kit.add_wheelchair(self, Vector3(-3.6, 0, 17.8), -0.6)
	kit.add_blood_trail(self, Vector3(0, 0, 20.0), Vector3(0, 0, -29.0), 12)
	kit.add_ceiling_stain(self, Vector3(0, 2.78, -12.5), 1.0)
	kit.add_ceiling_stain(self, Vector3(0, 2.78, 7.5), 0.9)
	kit.add_hanging_sheet(self, Vector3(4.65, 0, -3.5), 1.0, 1.9, PI * 0.5)
	kit.add_ghost(self, Vector3(2.8, 1.6, 17.5), 0.85)

	kit.add_body_bag(_basement, Vector3(9.0, 1.02, -45.5), 0.5)
	kit.add_body_bag(_basement, Vector3(-6.8, 0.02, -61.0), -0.2)
	kit.add_restraint_chair(_basement, Vector3(-13.0, 0, -62.5), 0.4)
	kit.add_specimen_jars(_basement, Vector3(12.0, 1.22, -52.5), PI * 0.5, 3)
	kit.add_blood_trail(_basement, Vector3(-2.0, 0, -45.0), Vector3(0.0, 0, -62.0), 9)
	kit.add_ceiling_stain(_basement, Vector3(0, 2.72, -55.0), 1.4)
	kit.add_ghost(_basement, Vector3(2.4, 1.7, -61.0), 1.2)

	kit.add_blood_trail(self, Vector3(-25.2, 0, -15.1), Vector3(-28.8, 0, -15.0), 4)
	kit.add_ceiling_stain(self, Vector3(-26.0, 2.3, -15.0), 0.55)


func _window(pos: Vector3, rot_y: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rot_y
	add_child(root)
	kit.add_box(root, Vector3(1.25, 1.5, 0.06), Vector3(0, 0, 0), kit.m_dark)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color("182423")
	glass.emission_enabled = true
	glass.emission = Color("31494c")
	glass.emission_energy_multiplier = 0.4
	kit.add_box(root, Vector3(1.1, 1.35, 0.03), Vector3(0, 0, 0.04), glass)
	for x in [-0.34, 0.0, 0.34]:
		kit.add_box(root, Vector3(0.04, 1.35, 0.04), Vector3(x, 0, 0.075), kit.m_black)
	var light := OmniLight3D.new()
	light.light_color = Color("708f96")
	light.light_energy = 0.3
	light.omni_range = 4.2
	light.position = Vector3(0, 0.1, 0.65)
	light.shadow_enabled = false
	root.add_child(light)


func _document(id: String, pos: Vector3, rot_y: float = 0.0, parent: Node3D = null) -> void:
	var node = DocumentScript.new()
	node.setup(id)
	node.position = pos
	node.rotation.y = rot_y
	var host: Node3D = parent if parent != null else self
	host.add_child(node)


func _pickup(id: String, pos: Vector3, parent: Node3D = null) -> void:
	var node = PickupScript.new()
	node.setup(id)
	node.position = pos
	var host: Node3D = parent if parent != null else self
	host.add_child(node)


func _puzzle(kind: String, display: String, pos: Vector3, rot_y: float, parent: Node3D = null) -> void:
	var node = PuzzleScript.new()
	node.setup(kind, display)
	node.position = pos
	node.rotation.y = rot_y
	var host: Node3D = parent if parent != null else self
	host.add_child(node)


func _trigger(config: Dictionary, pos: Vector3, rot_y: float, parent: Node3D = null) -> void:
	var node = TriggerScript.new()
	node.setup(config)
	node.position = pos
	node.rotation.y = rot_y
	var host: Node3D = parent if parent != null else self
	host.add_child(node)


func _door(config: Dictionary, pos: Vector3, rot_y: float, parent: Node3D = null) -> void:
	var node = DoorScript.new()
	node.setup(config)
	node.position = pos
	node.rotation.y = rot_y
	var host: Node3D = parent if parent != null else self
	host.add_child(node)


func _register_zones() -> void:
	zones = [
		{"id": "crawlspace", "rect": Rect2(-29.4, -16.9, 7.6, 3.9), "floor": 0.0},
		{"id": "intake", "rect": Rect2(-22, 10, 17, 10), "floor": 0.0},
		{"id": "storage", "rect": Rect2(-22, 0, 17, 10), "floor": 0.0},
		{"id": "day_room", "rect": Rect2(-22, -10, 17, 10), "floor": 0.0},
		{"id": "washroom", "rect": Rect2(-22, -20, 17, 10), "floor": 0.0},
		{"id": "ward_a", "rect": Rect2(-22, -30, 17, 10), "floor": 0.0},
		{"id": "staff_room", "rect": Rect2(5, 10, 17, 10), "floor": 0.0},
		{"id": "security", "rect": Rect2(5, 0, 17, 10), "floor": 0.0},
		{"id": "medical", "rect": Rect2(5, -10, 17, 10), "floor": 0.0},
		{"id": "records", "rect": Rect2(5, -20, 17, 10), "floor": 0.0},
		{"id": "ward_b", "rect": Rect2(5, -30, 17, 10), "floor": 0.0},
		{"id": "corridor", "rect": Rect2(-5, -30, 10, 50), "floor": 0.0},
		{"id": "lobby", "rect": Rect2(-10, 20, 20, 8), "floor": 0.0},
		{"id": "north_hall", "rect": Rect2(-10, -38, 20, 8), "floor": 0.0},
		{"id": "basement_tunnel", "rect": Rect2(-9, -68, 18, 10), "floor": -4.0},
		{"id": "basement", "rect": Rect2(-16, -68, 32, 26), "floor": -4.0},
	]


func get_zone(position: Vector3) -> String:
	for zone in zones:
		if absf(position.y - float(zone.get("floor", 0.0))) > 2.0:
			continue
		var rect: Rect2 = zone.get("rect", Rect2())
		if rect.has_point(Vector2(position.x, position.z)):
			return str(zone.get("id", ""))
	return ""


func get_zone_name(position: Vector3) -> String:
	var id := get_zone(position)
	return str(StoryData.ZONE_NAMES.get(id, ""))
