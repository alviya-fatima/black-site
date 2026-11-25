extends Node3D

const GameUIScript := preload("res://scripts/game_ui.gd")

var ui: CanvasLayer
var camera: Camera3D
var environment: Environment
var sun: DirectionalLight3D
var kit: WorldKit
var _cinema: CanvasLayer
var _line_label: Label
var _time: float = 0.0
var _shake: float = 0.0
var _finished: bool = false


func _ready() -> void:
	_build_environment()
	_build_world()
	_build_camera()
	_build_cinema()
	_build_ui()
	AudioManager.play_ambience("main_theme", -9.0, 2.4)
	call_deferred("_run_sequence")
	if not SceneTransition._busy:
		call_deferred("_fade_in")


func _fade_in() -> void:
	await get_tree().process_frame
	if not SceneTransition._busy:
		SceneTransition.fade_in(1.6)


func _build_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("6f8d98")
	sky_material.sky_horizon_color = Color("ecd5b1")
	sky_material.sky_curve = 0.14
	sky_material.sky_energy_multiplier = 1.05
	sky_material.ground_bottom_color = Color("35402f")
	sky_material.ground_horizon_color = Color("c4b28d")
	sky_material.ground_curve = 0.05
	sky_material.sun_angle_max = 20.0
	sky_material.sun_curve = 0.06
	var sky := Sky.new()
	sky.sky_material = sky_material

	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d9d4bd")
	environment.ambient_light_energy = 0.75
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.08
	environment.tonemap_white = 5.5
	environment.fog_enabled = true
	environment.fog_light_color = Color("e2d6bd")
	environment.fog_light_energy = 0.9
	environment.fog_density = 0.006
	environment.fog_sky_affect = 0.35
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.04
	environment.adjustment_saturation = 0.92
	environment.adjustment_brightness = 1.03

	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	sun = DirectionalLight3D.new()
	sun.light_color = Color("ffdca8")
	sun.light_energy = 1.55
	sun.rotation_degrees = Vector3(-31.0, -44.0, 0.0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 85.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(sun)


func _build_world() -> void:
	kit = WorldKit.new()
	var grass := kit.text_material(kit.m_grass, Vector3(28, 28, 1))
	grass.albedo_color = Color(0.82, 0.88, 0.66)
	kit.add_floor(self, Rect2(-90, -95, 190, 150), grass, -0.04)
	var dirt := kit.text_material(kit.m_concrete, Vector3(2.2, 16, 1))
	dirt.albedo_color = Color(0.52, 0.43, 0.31)
	kit.add_floor(self, Rect2(-1.7, -80, 3.4, 105), dirt, 0.008)
	var gravel := kit.text_material(kit.m_concrete, Vector3(5, 2, 1))
	gravel.albedo_color = Color(0.44, 0.4, 0.33)
	kit.add_floor(self, Rect2(-7.0, 10.0, 14.0, 7.0), gravel, 0.012)
	for z in range(6, -60, -7):
		_fence_post(Vector3(-3.1, 0, float(z)))
		_fence_post(Vector3(3.1, 0, float(z)))
	for z in [1.5, -19.0, -40.0]:
		kit.add_box(self, Vector3(0.08, 0.09, 7.0), Vector3(-3.1, 0.64, z), kit.m_wood)
		kit.add_box(self, Vector3(0.08, 0.09, 7.0), Vector3(3.1, 0.64, z), kit.m_wood)
	for tree_data in [
		[Vector3(-11, 0, -4), 1.2], [Vector3(10.5, 0, -14), 1.0],
		[Vector3(-15, 0, -28), 1.35], [Vector3(14, 0, -34), 1.15],
		[Vector3(-21, 0, -52), 1.5], [Vector3(20, 0, -58), 1.3],
		[Vector3(-8, 0, -66), 1.1], [Vector3(7, 0, -76), 1.45],
	]:
		_dead_tree(tree_data[0], tree_data[1])
	for pine_data in [
		[Vector3(-31, 0, -38), 1.5], [Vector3(29, 0, -44), 1.7],
		[Vector3(-38, 0, -62), 1.9], [Vector3(37, 0, -68), 1.6],
	]:
		_pine(pine_data[0], pine_data[1])


func _fence_post(pos: Vector3) -> void:
	kit.add_box(self, Vector3(0.14, 0.9, 0.14), pos + Vector3(0, 0.45, 0), kit.m_wood, Vector3(0, 0.08, 0.04))
	kit.add_box(self, Vector3(0.19, 0.03, 0.19), pos + Vector3(0, 0.92, 0), kit.m_metal)


func _dead_tree(pos: Vector3, height_scale: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.scale = Vector3.ONE * height_scale
	add_child(root)
	var bark := kit.m_wood
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.09
	trunk.bottom_radius = 0.24
	trunk.height = 3.4
	trunk.radial_segments = 8
	var trunk_inst := MeshInstance3D.new()
	trunk_inst.mesh = trunk
	trunk_inst.material_override = bark
	trunk_inst.position.y = 1.7
	root.add_child(trunk_inst)
	for i in range(4):
		var branch := BoxMesh.new()
		branch.size = Vector3(0.07, randf_range(0.8, 1.6), 0.07)
		var branch_inst := MeshInstance3D.new()
		branch_inst.mesh = branch
		branch_inst.material_override = bark
		branch_inst.position = Vector3(randf_range(-0.2, 0.2), randf_range(1.9, 3.2), randf_range(-0.2, 0.2))
		branch_inst.rotation = Vector3(randf_range(-0.7, 0.7), randf() * TAU, randf_range(-0.7, 0.7))
		root.add_child(branch_inst)


func _pine(pos: Vector3, size_scale: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.scale = Vector3.ONE * size_scale
	add_child(root)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.08
	trunk.bottom_radius = 0.18
	trunk.height = 2.4
	var trunk_inst := MeshInstance3D.new()
	trunk_inst.mesh = trunk
	trunk_inst.material_override = kit.m_wood
	trunk_inst.position.y = 1.2
	root.add_child(trunk_inst)
	var needles := StandardMaterial3D.new()
	needles.albedo_color = Color("33432f")
	needles.roughness = 0.98
	for i in range(3):
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 1.3 - i * 0.28
		cone.height = 1.8
		cone.radial_segments = 9
		var cone_inst := MeshInstance3D.new()
		cone_inst.mesh = cone
		cone_inst.material_override = needles
		cone_inst.position.y = 2.2 + i * 0.9
		root.add_child(cone_inst)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.fov = 58.0
	camera.near = 0.05
	camera.far = 220.0
	add_child(camera)
	camera.position = Vector3(0.0, 1.72, 16.0)
	camera.look_at(Vector3(0.0, 1.45, -18.0), Vector3.UP)
	camera.current = true


func _build_cinema() -> void:
	_cinema = CanvasLayer.new()
	_cinema.layer = 30
	_cinema.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_cinema)
	var top_bar := ColorRect.new()
	top_bar.color = Color(0.004, 0.005, 0.004, 1.0)
	top_bar.anchor_right = 1.0
	top_bar.offset_bottom = 64
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cinema.add_child(top_bar)
	var bottom_bar := ColorRect.new()
	bottom_bar.color = Color(0.004, 0.005, 0.004, 1.0)
	bottom_bar.anchor_right = 1.0
	bottom_bar.anchor_top = 1.0
	bottom_bar.anchor_bottom = 1.0
	bottom_bar.offset_top = -92
	bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cinema.add_child(bottom_bar)
	var top_label := UI.mono("BLACK SITE  /  SERVICE YARD", 11, Color(0.63, 0.62, 0.54, 0.85))
	top_label.position = Vector2(74, 24)
	_cinema.add_child(top_label)
	var top_right := UI.mono("06:12  /  EXTERIOR", 11, Color(0.63, 0.62, 0.54, 0.85))
	top_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_right.anchor_left = 1.0
	top_right.anchor_right = 1.0
	top_right.offset_left = -310
	top_right.offset_right = -74
	top_right.offset_top = 24
	top_right.offset_bottom = 46
	_cinema.add_child(top_right)
	_line_label = UI.label("", 25, Color("efe6cf"), UI.font_serif, HORIZONTAL_ALIGNMENT_LEFT, true)
	_line_label.add_theme_constant_override("outline_size", 6)
	_line_label.add_theme_color_override("font_outline_color", Color(0.02, 0.025, 0.02, 0.85))
	_line_label.anchor_top = 1.0
	_line_label.anchor_bottom = 1.0
	_line_label.offset_left = 74
	_line_label.offset_right = 900
	_line_label.offset_top = -74
	_line_label.offset_bottom = -24
	_line_label.modulate.a = 0.0
	_cinema.add_child(_line_label)
	UI.add_film_overlay(self)


func _build_ui() -> void:
	ui = GameUIScript.new()
	ui.game = null
	ui.input_enabled = false
	ui.restart_requested.connect(_wake_in_intake)
	ui.menu_requested.connect(_back_to_menu)
	add_child(ui)
	ui.set_hud_visible(false)


func _run_sequence() -> void:
	await get_tree().create_timer(1.0).timeout
	_show_line("The door lets you go.")
	await get_tree().create_timer(2.1).timeout
	_show_line("The sun is warm. The grass is real.")
	await get_tree().create_timer(2.4).timeout
	_show_line("You lift your foot to step through.")
	await get_tree().create_timer(1.8).timeout
	AudioManager.play_sfx("glitch", -5.0, 0.0)
	_shake = 1.0
	_show_line("Then the world blinks.")
	await get_tree().create_timer(0.28).timeout
	AudioManager.cut_audio()
	await get_tree().create_timer(1.0).timeout
	_finish_victory()


func _show_line(text_value: String) -> void:
	_line_label.text = text_value
	_line_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_line_label, "modulate:a", 1.0, 0.45)


func _finish_victory() -> void:
	if _finished:
		return
	_finished = true
	GameState.record_ending(6)
	SaveManager.save_current()
	AudioManager.play_loss_theme(6)
	AudioManager.play_ending_sting(6)
	_cinema.visible = false
	ui.input_enabled = true
	ui.show_ending(6)


func _wake_in_intake() -> void:
	GameState.restart_loop()
	SaveManager.save_current()
	SceneTransition.change_scene("res://scenes/game.tscn", 0.8, 1.0)


func _back_to_menu() -> void:
	SceneTransition.change_scene("res://scenes/main_menu.tscn", 0.8, 0.8)


func _process(delta: float) -> void:
	_time += delta
	if camera != null and not _finished:
		_shake = maxf(0.0, _shake - delta * 1.4)
		var shake_x := randf_range(-0.035, 0.035) * _shake
		var shake_y := randf_range(-0.03, 0.03) * _shake
		camera.position.x = sin(_time * 0.32) * 0.045 + shake_x
		camera.position.y = 1.72 + sin(_time * 0.8) * 0.018 + shake_y
