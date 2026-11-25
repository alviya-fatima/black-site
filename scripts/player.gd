extends CharacterBody3D

@export var walk_speed: float = 3.05
@export var run_speed: float = 5.15
@export var acceleration: float = 14.0
@export var friction: float = 18.0

var game: Node = null
var control_enabled: bool = true
var running: bool = false
var facing: float = 0.0

var _visual: Node3D
var _body_root: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _head: Node3D
var _anim_time: float = 0.0
var _phase: float = 0.0
var _step_timer: float = 0.0
var _interact_anim: float = 0.0
var _spawn: Transform3D

var skin_mat: StandardMaterial3D
var cloth_mat: StandardMaterial3D
var cloth_dark_mat: StandardMaterial3D
var pants_mat: StandardMaterial3D
var strap_mat: StandardMaterial3D
var hair_mat: StandardMaterial3D
var metal_mat: StandardMaterial3D
var boot_mat: StandardMaterial3D
var sole_mat: StandardMaterial3D
var shadow_mat: StandardMaterial3D


func _ready() -> void:
	floor_snap_length = 0.28
	up_direction = Vector3.UP
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	add_to_group("player")
	_build_visuals()
	_spawn = global_transform


func _make_mat(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	return mat


func _sphere(parent: Node3D, radius: float, pos: Vector3, mat: Material,
		scale_v: Vector3 = Vector3.ONE, segments: int = 14, rings: int = 8) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = rings
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = pos
	inst.scale = scale_v
	parent.add_child(inst)
	return inst


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material,
		rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = pos
	inst.rotation = rot
	parent.add_child(inst)
	return inst


func _build_visuals() -> void:
	skin_mat = _make_mat(Color("b9a28c"), 0.92)
	cloth_mat = _make_mat(Color("a8a695"), 0.97)
	cloth_dark_mat = _make_mat(Color("858474"), 0.98)
	pants_mat = _make_mat(Color("3d4038"), 0.96)
	strap_mat = _make_mat(Color("191b18"), 0.7)
	hair_mat = _make_mat(Color("0b0d0e"), 0.72)
	metal_mat = _make_mat(Color("a6a085"), 0.36, 0.8)
	boot_mat = _make_mat(Color("181a17"), 0.8)
	sole_mat = _make_mat(Color("090a09"), 0.96)
	shadow_mat = StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0.006, 0.008, 0.007, 0.45)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)

	# Faint institutional fill so the player reads in unlit corners.
	var presence := OmniLight3D.new()
	presence.position = Vector3(0, 1.2, 0.25)
	presence.light_color = Color("9aa89a")
	presence.light_energy = 0.45
	presence.omni_range = 4.0
	presence.omni_attenuation = 2.0
	presence.shadow_enabled = false
	_visual.add_child(presence)

	# Blob shadow.
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.42
	shadow_mesh.bottom_radius = 0.42
	shadow_mesh.height = 0.005
	shadow_mesh.radial_segments = 20
	var shadow_inst := MeshInstance3D.new()
	shadow_inst.mesh = shadow_mesh
	shadow_inst.material_override = shadow_mat
	shadow_inst.position.y = 0.02
	shadow_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual.add_child(shadow_inst)

	_body_root = Node3D.new()
	_body_root.name = "Body"
	_visual.add_child(_body_root)

	# Legs.
	_left_leg = Node3D.new()
	_left_leg.position = Vector3(0.155, 0.72, 0)
	_body_root.add_child(_left_leg)
	_right_leg = Node3D.new()
	_right_leg.position = Vector3(-0.155, 0.72, 0)
	_body_root.add_child(_right_leg)
	for leg in [_left_leg, _right_leg]:
		_box(leg, Vector3(0.2, 0.58, 0.23), Vector3(0, -0.28, 0), pants_mat)
		_box(leg, Vector3(0.215, 0.18, 0.26), Vector3(0, -0.6, 0), pants_mat)
		_box(leg, Vector3(0.24, 0.17, 0.36), Vector3(0, -0.7, 0.045), boot_mat)
		_box(leg, Vector3(0.25, 0.045, 0.38), Vector3(0, -0.785, 0.05), sole_mat)
		_box(leg, Vector3(0.13, 0.1, 0.012), Vector3(0, -0.28, 0.12), strap_mat)

	# Pants / lower torso.
	_box(_body_root, Vector3(0.48, 0.28, 0.33), Vector3(0, 0.83, 0), pants_mat)
	_box(_body_root, Vector3(0.51, 0.075, 0.35), Vector3(0, 0.765, 0), strap_mat)
	_box(_body_root, Vector3(0.072, 0.08, 0.37), Vector3(0, 0.77, 0), strap_mat)

	# Padded institutional shirt.
	_box(_body_root, Vector3(0.55, 0.62, 0.35), Vector3(0, 1.13, 0), cloth_mat)
	_box(_body_root, Vector3(0.58, 0.1, 0.37), Vector3(0, 1.43, 0), cloth_dark_mat)
	_box(_body_root, Vector3(0.2, 0.16, 0.32), Vector3(0.325, 1.36, 0), cloth_mat)
	_box(_body_root, Vector3(0.2, 0.16, 0.32), Vector3(-0.325, 1.36, 0), cloth_mat)
	_box(_body_root, Vector3(0.02, 0.38, 0.012), Vector3(0, 1.15, 0.181), cloth_dark_mat)
	for i in range(5):
		_box(_body_root, Vector3(0.036, 0.013, 0.014), Vector3(-0.05 + i * 0.025, 1.055, 0.187), strap_mat)

	# The three straps and buckles from the intake photograph.
	_box(_body_root, Vector3(0.585, 0.052, 0.375), Vector3(0, 1.34, 0), strap_mat)
	_box(_body_root, Vector3(0.585, 0.052, 0.375), Vector3(0, 1.12, 0), strap_mat)
	_box(_body_root, Vector3(0.074, 0.55, 0.39), Vector3(0, 1.22, 0), strap_mat)
	_box(_body_root, Vector3(0.59, 0.06, 0.37), Vector3(0, 0.875, 0), strap_mat)
	for y in [1.34, 1.12, 0.875]:
		_box(_body_root, Vector3(0.13, 0.115, 0.022), Vector3(0, y, 0.197), metal_mat)
		_box(_body_root, Vector3(0.062, 0.062, 0.026), Vector3(0, y, 0.21), strap_mat)

	# Neck and collar.
	var neck := CylinderMesh.new()
	neck.top_radius = 0.115
	neck.bottom_radius = 0.13
	neck.height = 0.16
	var neck_inst := MeshInstance3D.new()
	neck_inst.mesh = neck
	neck_inst.material_override = skin_mat
	neck_inst.position = Vector3(0, 1.52, 0)
	_body_root.add_child(neck_inst)
	var collar := CylinderMesh.new()
	collar.top_radius = 0.155
	collar.bottom_radius = 0.16
	collar.height = 0.08
	var collar_inst := MeshInstance3D.new()
	collar_inst.mesh = collar
	collar_inst.material_override = strap_mat
	collar_inst.position = Vector3(0, 1.585, 0)
	_body_root.add_child(collar_inst)
	for i in range(7):
		var a := TAU * i / 7.0
		_box(_body_root, Vector3(0.026, 0.026, 0.014),
			Vector3(cos(a) * 0.155, 1.585, sin(a) * 0.155), metal_mat)

	# Head and hair.
	_head = Node3D.new()
	_head.position = Vector3(0, 1.67, 0)
	_body_root.add_child(_head)
	_sphere(_head, 0.22, Vector3(0, 0.02, 0), skin_mat, Vector3(1.0, 1.08, 0.96), 20, 12)
	# Face shadow and eyes hidden under the fringe.
	_box(_head, Vector3(0.23, 0.12, 0.02), Vector3(0, 0.0, 0.202), _make_mat(Color("3d3831"), 1.0))
	_sphere(_head, 0.023, Vector3(-0.075, 0.012, 0.208), hair_mat, Vector3(1, 1.2, .5), 8, 6)
	_sphere(_head, 0.023, Vector3(0.075, 0.012, 0.208), hair_mat, Vector3(1, 1.2, .5), 8, 6)
	_sphere(_head, 0.03, Vector3(0, -0.06, 0.213), _make_mat(Color("8e7a68"), 0.94), Vector3(1, .8, .4), 8, 6)

	var rng := RandomNumberGenerator.new()
	rng.seed = 6106
	var hair_clumps := [
		[Vector3(0, 0.22, -0.02), Vector3(0.24, 0.16, 0.23)],
		[Vector3(-0.15, 0.18, 0.02), Vector3(0.17, 0.14, 0.18)],
		[Vector3(0.15, 0.18, 0.01), Vector3(0.17, 0.14, 0.18)],
		[Vector3(0, 0.16, 0.14), Vector3(0.2, 0.15, 0.16)],
		[Vector3(-0.14, 0.1, 0.16), Vector3(0.15, 0.16, 0.12)],
		[Vector3(0.14, 0.1, 0.16), Vector3(0.14, 0.17, 0.12)],
		[Vector3(0, 0.06, 0.2), Vector3(0.18, 0.12, 0.1)],
		[Vector3(-0.19, 0.04, 0.02), Vector3(0.1, 0.2, 0.16)],
		[Vector3(0.19, 0.04, 0.02), Vector3(0.1, 0.2, 0.16)],
		[Vector3(0, 0.02, -0.19), Vector3(0.24, 0.2, 0.12)],
		[Vector3(-0.14, 0.2, -0.13), Vector3(0.14, 0.15, 0.15)],
		[Vector3(0.14, 0.2, -0.13), Vector3(0.14, 0.15, 0.15)],
	]
	for clump in hair_clumps:
		_sphere(_head, 0.5, clump[0], hair_mat, clump[1] * 2.0, 9, 6)
	for i in range(7):
		var ang := rng.randf_range(0, TAU)
		var spike := CylinderMesh.new()
		spike.top_radius = 0.0
		spike.bottom_radius = rng.randf_range(0.035, 0.075)
		spike.height = rng.randf_range(0.2, 0.42)
		var inst := MeshInstance3D.new()
		inst.mesh = spike
		inst.material_override = hair_mat
		inst.position = Vector3(cos(ang) * 0.15, 0.26 + rng.randf_range(-0.03, 0.08), sin(ang) * 0.14)
		inst.rotation = Vector3(rng.randf_range(-0.7, 0.7), ang, rng.randf_range(-0.8, 0.8))
		_body_root.add_child(inst)

	# Arms.
	_left_arm = Node3D.new()
	_left_arm.position = Vector3(0.355, 1.36, 0)
	_body_root.add_child(_left_arm)
	_right_arm = Node3D.new()
	_right_arm.position = Vector3(-0.355, 1.36, 0)
	_body_root.add_child(_right_arm)
	for arm in [_left_arm, _right_arm]:
		_box(arm, Vector3(0.16, 0.5, 0.17), Vector3(0, -0.24, 0), cloth_mat)
		_box(arm, Vector3(0.17, 0.07, 0.18), Vector3(0, -0.47, 0), strap_mat)
		_box(arm, Vector3(0.145, 0.25, 0.155), Vector3(0, -0.57, 0.01), cloth_dark_mat)
		_sphere(arm, 0.077, Vector3(0, -0.72, 0.015), skin_mat, Vector3(0.9, 1.05, 0.85), 10, 6)

	# ID tag.
	_box(_body_root, Vector3(0.14, 0.19, 0.012), Vector3(0.225, 1.22, 0.19), _make_mat(Color("c4b98e"), 0.85))
	_box(_body_root, Vector3(0.09, 0.02, 0.014), Vector3(0.225, 1.27, 0.197), strap_mat)
	_box(_body_root, Vector3(0.08, 0.012, 0.014), Vector3(0.225, 1.22, 0.197), strap_mat)

	# Slight initial lean.
	_body_root.rotation.z = -0.025


func _physics_process(delta: float) -> void:
	if not control_enabled:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)
	else:
		var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var dir := Vector3(input_vec.x, 0, input_vec.y)
		running = Input.is_action_pressed("run") and dir.length_squared() > 0.05
		var speed := run_speed if running else walk_speed
		var target := dir.normalized() * speed
		if dir.length_squared() > 0.01:
			velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
			velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
			var target_facing := atan2(dir.x, dir.z)
			facing = lerp_angle(facing, target_facing, 11.0 * delta)
			_visual.rotation.y = facing
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)
			velocity.z = move_toward(velocity.z, 0.0, friction * delta)

	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity.y -= 18.0 * delta
	move_and_slide()
	_animate(delta)


func _animate(delta: float) -> void:
	_anim_time += delta
	_interact_anim = maxf(0.0, _interact_anim - delta)
	var planar := Vector2(velocity.x, velocity.z).length()
	var moving := planar > 0.18 and control_enabled and is_on_floor()
	if moving:
		_phase += delta * (11.5 if running else 7.4)
		var swing := sin(_phase) * (0.61 if running else 0.38)
		_left_leg.rotation.x = lerp(_left_leg.rotation.x, swing, 18.0 * delta)
		_right_leg.rotation.x = lerp(_right_leg.rotation.x, -swing, 18.0 * delta)
		_left_arm.rotation.x = lerp(_left_arm.rotation.x, -swing * 0.8, 12.0 * delta)
		_right_arm.rotation.x = lerp(_right_arm.rotation.x, swing * 0.8, 12.0 * delta)
		_body_root.position.y = absf(sin(_phase * 2.0)) * (0.025 if running else 0.013)
		_body_root.rotation.z = sin(_phase) * (0.025 if running else 0.012)
		_step_timer -= delta
		if _step_timer <= 0.0 and is_on_floor():
			AudioManager.play_step(running)
			_step_timer = 0.3 if running else 0.47
	else:
		_phase = lerp(_phase, 0.0, 5.0 * delta)
		_left_leg.rotation.x = lerp(_left_leg.rotation.x, 0.0, 7.0 * delta)
		_right_leg.rotation.x = lerp(_right_leg.rotation.x, 0.0, 7.0 * delta)
		_left_arm.rotation.x = lerp(_left_arm.rotation.x, sin(_anim_time * 1.2) * 0.025, 5.0 * delta)
		_right_arm.rotation.x = lerp(_right_arm.rotation.x, -sin(_anim_time * 1.2) * 0.025, 5.0 * delta)
		_body_root.position.y = lerp(_body_root.position.y, sin(_anim_time * 1.7) * 0.008, 4.0 * delta)
		_body_root.rotation.z = lerp(_body_root.rotation.z, -0.025, 4.0 * delta)
		_step_timer = 0.0
	if _interact_anim > 0.0:
		var lift := sin(clampf((0.52 - _interact_anim) / 0.18, 0.0, 1.0) * PI)
		_right_arm.rotation.x = lerp(_right_arm.rotation.x, -1.25 * lift, 18.0 * delta)
		_head.rotation.x = lerp(_head.rotation.x, 0.12 * lift, 10.0 * delta)
	else:
		_head.rotation.x = lerp(_head.rotation.x, 0.0, 5.0 * delta)
	_head.rotation.y = sin(_anim_time * 0.7) * 0.045 if not moving else 0.0


func play_interaction_animation() -> void:
	_interact_anim = 0.52


func teleport_to(position: Vector3, face_angle: float = 0.0) -> void:
	global_position = position
	velocity = Vector3.ZERO
	facing = face_angle
	_visual.rotation.y = face_angle
	_step_timer = 0.0


func set_control(value: bool) -> void:
	control_enabled = value
	if not value:
		running = false


func reset_spawn() -> void:
	global_transform = _spawn
	velocity = Vector3.ZERO
