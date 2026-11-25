extends Node3D

const BuilderScript := preload("res://scripts/asylum_builder.gd")
const GameUIScript := preload("res://scripts/game_ui.gd")
const PlayerScene := preload("res://scenes/player.tscn")

const CAMERA_OFFSET := Vector3(6.6, 18.6, 7.2)
const CAMERA_SIZE := 10.8
const BASEMENT_SPAWN := Vector3(0.0, -3.92, -50.2)
const BASEMENT_RETURN := Vector3(4.0, 0.08, -35.8)

var player: CharacterBody3D
var ui: CanvasLayer
var builder: Node3D
var camera: Camera3D
var world_environment: WorldEnvironment
var environment: Environment
var sun: DirectionalLight3D

var _zone_id: String = ""
var _zone_timer: float = 0.0
var _ending_active: bool = false
var _transition_busy: bool = false
var _recover_timer: float = 0.0

const ZONE_CHECKPOINTS := {
	"intake": Vector3(-12.5, 0.08, 15.5),
	"storage": Vector3(-13.0, 0.08, 5.0),
	"day_room": Vector3(-13.0, 0.08, -5.0),
	"washroom": Vector3(-13.0, 0.08, -15.0),
	"ward_a": Vector3(-12.8, 0.08, -24.8),
	"staff_room": Vector3(13.5, 0.08, 17.2),
	"security": Vector3(13.0, 0.08, 5.0),
	"medical": Vector3(13.0, 0.08, -5.0),
	"records": Vector3(13.0, 0.08, -15.0),
	"ward_b": Vector3(13.0, 0.08, -25.0),
	"corridor": Vector3(0.0, 0.08, 10.0),
	"lobby": Vector3(0.0, 0.08, 23.0),
	"north_hall": Vector3(0.0, 0.08, -33.0),
	"crawlspace": Vector3(-25.5, 0.08, -15.0),
	"basement": BASEMENT_SPAWN,
	"basement_tunnel": Vector3(0.0, -3.92, -59.5),
}


func _ready() -> void:
	if not GameState.run_active:
		GameState.run_active = true
	_build_environment()
	_build_world()
	_spawn_player()
	_build_camera()
	_build_ui()
	_connect_signals()
	_apply_zone_environment(player.global_position.y < -2.0)
	_audio_for_position()
	_update_zone(true, false)
	_update_objective()
	_snap_camera()
	call_deferred("_opening")
	if not SceneTransition._busy:
		call_deferred("_initial_fade_in")


func _opening() -> void:
	if not GameState.intro_seen:
		ui.show_intro()


func _initial_fade_in() -> void:
	await get_tree().process_frame
	if not SceneTransition._busy:
		SceneTransition.fade_in(0.9)


func _build_environment() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("040605")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("58675a")
	environment.ambient_light_energy = 0.42
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.05
	environment.tonemap_white = 6.0
	environment.fog_enabled = true
	environment.fog_light_color = Color("101a14")
	environment.fog_light_energy = 0.8
	environment.fog_density = 0.011
	environment.fog_sky_affect = 0.0
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.08
	environment.adjustment_saturation = 0.84
	environment.adjustment_brightness = 1.0

	world_environment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	world_environment.environment = environment
	add_child(world_environment)

	sun = DirectionalLight3D.new()
	sun.name = "Moonlight"
	sun.light_color = Color("93a8aa")
	sun.light_energy = 0.3
	sun.rotation_degrees = Vector3(-62.0, -35.0, 0.0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 42.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)


func _build_world() -> void:
	builder = BuilderScript.new()
	builder.name = "Asylum"
	add_child(builder)
	builder.build(self)


func _spawn_player() -> void:
	player = PlayerScene.instantiate()
	player.game = self
	add_child(player)
	player.teleport_to(GameState.checkpoint, 0.0)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = CAMERA_SIZE
	camera.near = 0.05
	camera.far = 140.0
	add_child(camera)
	camera.current = true
	camera.global_position = _camera_target() + CAMERA_OFFSET
	camera.look_at(_camera_target(), Vector3.UP)


func _build_ui() -> void:
	ui = GameUIScript.new()
	ui.name = "GameUI"
	ui.game = self
	ui.restart_requested.connect(_on_restart_requested)
	ui.menu_requested.connect(_on_menu_requested)
	add_child(ui)
	UI.add_film_overlay(self)


func _connect_signals() -> void:
	GameState.progress_changed.connect(_update_objective)
	InventoryManager.inventory_changed.connect(_update_objective)
	var manager := player.get_node_or_null("InteractionManager")
	if manager != null:
		manager.prompt_changed.connect(_on_prompt_changed)


func _process(delta: float) -> void:
	if player == null:
		return
	_update_camera(delta)
	_zone_timer -= delta
	if _zone_timer <= 0.0:
		_zone_timer = 0.18
		_update_zone()
	_recover_timer = maxf(0.0, _recover_timer - delta)
	if _recover_timer <= 0.0 and not _ending_active and not _transition_busy:
		if player.global_position.y < -9.0 or absf(player.global_position.x) > 46.0 or player.global_position.z > 40.0:
			_recover_player()


func _update_camera(delta: float) -> void:
	if camera == null or player == null:
		return
	var target := _camera_target()
	var desired := target + CAMERA_OFFSET
	camera.global_position = camera.global_position.lerp(desired, 1.0 - exp(-7.5 * delta))
	camera.look_at(target, Vector3.UP)


func _camera_target() -> Vector3:
	return player.global_position + Vector3(0, 0.85, 0)


func _snap_camera() -> void:
	if camera == null or player == null:
		return
	var target := _camera_target()
	camera.global_position = target + CAMERA_OFFSET
	camera.look_at(target, Vector3.UP)


func _update_zone(force: bool = false, save_checkpoint: bool = true) -> void:
	if builder == null or player == null:
		return
	var zone: String = builder.get_zone(player.global_position)
	if zone.is_empty():
		return
	if zone == _zone_id and not force:
		return
	_zone_id = zone
	var zone_name := str(StoryData.ZONE_NAMES.get(zone, ""))
	if not zone_name.is_empty():
		ui.set_location(zone_name)
	if save_checkpoint and ZONE_CHECKPOINTS.has(zone):
		var point: Vector3 = ZONE_CHECKPOINTS[zone]
		if zone == "corridor":
			point = Vector3(0.0, 0.08, clampf(player.global_position.z, -28.0, 18.0))
		GameState.set_checkpoint(point, zone_name)
		SaveManager.save_current()


func _apply_zone_environment(basement: bool) -> void:
	if basement:
		environment.fog_density = 0.008
		environment.fog_light_color = Color("10170f")
		environment.ambient_light_color = Color("748277")
		environment.ambient_light_energy = 0.9
		environment.tonemap_exposure = 1.2
		sun.light_energy = 0.0
	else:
		environment.fog_density = 0.011
		environment.fog_light_color = Color("101a14")
		environment.ambient_light_color = Color("58675a")
		environment.ambient_light_energy = 0.42
		environment.tonemap_exposure = 1.0
		sun.light_energy = 0.3


func _audio_for_position() -> void:
	if player == null:
		return
	AudioManager.play_ambience("main_theme", -9.0, 2.2)


func _on_prompt_changed(text: String) -> void:
	if _ending_active:
		ui.set_prompt("")
		return
	ui.set_prompt(text)


func read_document(document_id: String) -> void:
	if _ending_active:
		return
	GameState.read_document(document_id)
	SaveManager.save_current()
	ui.show_document(document_id)
	_update_objective()


func collect_item(item_id: String) -> void:
	if _ending_active:
		return
	if not InventoryManager.add_item(item_id):
		return
	GameState.set_flag("taken_" + item_id)
	AudioManager.play_sfx("pickup", -8.0, 0.03)
	SaveManager.save_current()
	match item_id:
		"staff_card":
			ui.toast("STAFF KEYCARD 07. The west break room lock remembers it.")
		"brass_key":
			ui.toast("A brass key, warm from someone else's pocket.")
		"override_key":
			ui.toast("SERVICE OVERRIDE. The service tunnel can be forced.")
		_:
			if InventoryManager.has_all_fuses():
				ui.toast("All three anchor fuses. Security is waiting.")
			else:
				ui.toast("Anchor fuse recovered. %d of 3." % InventoryManager.fuse_count())
	_update_objective()


func open_keypad(code: String, callback: Callable) -> void:
	if _ending_active:
		return
	ui.open_keypad(code, callback)


func open_anchor_panel() -> void:
	if _ending_active:
		return
	ui.open_anchor_panel()


func open_dial_panel() -> void:
	if _ending_active:
		return
	ui.open_dial_panel()


func solve_anchor() -> void:
	if GameState.has_flag("anchors_calibrated"):
		return
	for fuse_id in StoryData.FUSE_IDS:
		InventoryManager.remove_item(fuse_id)
	GameState.set_flag("anchors_calibrated")
	AudioManager.play_sfx("unlock", -6.0, 0.0)
	ui.toast("The anchor array goes quiet. Below, the seal releases.")
	SaveManager.save_current()
	_update_objective()


func solve_dial() -> void:
	if GameState.has_flag("loop_disabled"):
		return
	GameState.set_flag("loop_disabled")
	GameState.set_flag("carrier_tuned")
	AudioManager.play_sfx("unlock", -6.0, 0.0)
	AudioManager.play_sfx("glitch", -18.0, 0.0)
	ui.toast("The needle locks at 13.5. The corridor stops folding.")
	SaveManager.save_current()
	_update_objective()


func enter_basement() -> void:
	if _transition_busy or _ending_active:
		return
	_transition_busy = true
	player.set_control(false)
	ui.set_prompt("")
	await SceneTransition.fade_out(0.7)
	player.teleport_to(BASEMENT_SPAWN, PI)
	GameState.set_checkpoint(BASEMENT_SPAWN, "SUB-LEVEL C")
	SaveManager.save_current()
	_apply_zone_environment(true)
	_audio_for_position()
	_zone_id = ""
	_update_zone(true, false)
	_snap_camera()
	await get_tree().create_timer(0.15).timeout
	await SceneTransition.fade_in(0.9)
	player.set_control(true)
	ui.toast("Sub-Level C. The air tastes like rust.")
	suppress_interaction(0.35)
	_transition_busy = false


func exit_basement() -> void:
	if _transition_busy or _ending_active:
		return
	_transition_busy = true
	player.set_control(false)
	ui.set_prompt("")
	await SceneTransition.fade_out(0.55)
	player.teleport_to(BASEMENT_RETURN, 0.0)
	GameState.set_checkpoint(Vector3(0.0, 0.08, -33.0), "NORTH STAIRWELL")
	SaveManager.save_current()
	_apply_zone_environment(false)
	_audio_for_position()
	_zone_id = ""
	_update_zone(true, false)
	_snap_camera()
	await get_tree().create_timer(0.1).timeout
	await SceneTransition.fade_in(0.8)
	player.set_control(true)
	ui.toast("The stairwell is colder than you remember.")
	suppress_interaction(0.35)
	_transition_busy = false


func begin_ending(ending_id: int) -> void:
	if _ending_active:
		return
	if not StoryData.ENDINGS.has(ending_id):
		return
	if ending_id == 6:
		start_fake_victory()
		return
	_ending_active = true
	player.set_control(false)
	ui.set_prompt("")
	ui.input_enabled = false
	GameState.record_ending(ending_id)
	SaveManager.save_current()
	AudioManager.cut_audio()
	AudioManager.play_loss_theme(ending_id)
	AudioManager.play_ending_sting(ending_id)
	await SceneTransition.fade_out(0.9)
	ui.show_ending(ending_id)
	await get_tree().process_frame
	SceneTransition.fade_in(1.1)


func start_fake_victory() -> void:
	if _ending_active:
		return
	_ending_active = true
	player.set_control(false)
	ui.set_prompt("")
	ui.input_enabled = false
	GameState.set_flag("took_service_tunnel")
	SaveManager.save_current()
	AudioManager.play_sfx("glitch", -8.0, 0.0)
	await SceneTransition.fade_out(1.1, Color(0.94, 0.91, 0.82, 1.0))
	var result := get_tree().change_scene_to_file("res://scenes/outside.tscn")
	if result != OK:
		_ending_active = false
		push_error("Could not load outside scene.")


func save_progress() -> void:
	if _ending_active:
		return
	SaveManager.save_current()


func toast(text_value: String) -> void:
	if ui != null:
		ui.toast(text_value)


func suppress_interaction(seconds: float = 0.35) -> void:
	if player == null:
		return
	var manager := player.get_node_or_null("InteractionManager")
	if manager != null and manager.has_method("suppress_for"):
		manager.suppress_for(seconds)


func _update_objective() -> void:
	if ui == null or _ending_active:
		return
	var text := ""
	if not GameState.has_read_document("intake_06"):
		text = "Search Intake. The building remembers you."
	elif not InventoryManager.has_item("staff_card") and not GameState.has_flag("door_unlocked_staff_room"):
		text = "A staff keycard is logged to the medical cabinet."
	elif not GameState.has_read_document("maintenance_note"):
		text = "The west mirror hides a service panel. Search Storage."
	elif not InventoryManager.has_all_fuses() and not GameState.has_flag("anchors_calibrated"):
		text = "Collect three anchor fuses. Ward A. Ward B. Records."
	elif not GameState.has_flag("anchors_calibrated"):
		text = "Seat the fuses at the Security anchor console."
	elif not GameState.has_flag("loop_disabled"):
		text = "The basement seal is open. Tune the return carrier to 13.5."
	elif not InventoryManager.has_item("override_key"):
		text = "The service tunnel needs an override. Search behind the west mirror."
	else:
		text = "Open the service tunnel in Sub-Level C. Do not look at the sky."
	ui.set_objective(text)


func _recover_player() -> void:
	_recover_timer = 1.5
	player.teleport_to(GameState.checkpoint + Vector3(0, 0.12, 0), 0.0)
	_snap_camera()
	ui.toast("The corridor put you back.")


func _on_restart_requested() -> void:
	GameState.restart_loop()
	SaveManager.save_current()
	SceneTransition.change_scene("res://scenes/game.tscn", 0.65, 0.9)


func _on_menu_requested() -> void:
	if not _ending_active:
		SaveManager.save_current()
	SceneTransition.change_scene("res://scenes/main_menu.tscn", 0.8, 0.8)
