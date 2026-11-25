extends Control

var _busy: bool = false
var _settings_root: Control
var _confirm_root: Control
var _ghost: TextureRect
var _logo: TextureRect
var _time: float = 0.0
var _flicker_timer: float = 9.0
var _continue_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().paused = false
	_build_background()
	_build_content()
	if not SceneTransition._busy:
		call_deferred("_fade_in")
	AudioManager.play_ambience("main_theme", -13.0, 2.8)


func _fade_in() -> void:
	await get_tree().process_frame
	if not SceneTransition._busy:
		SceneTransition.fade_in(0.9)


func _build_background() -> void:
	var base := ColorRect.new()
	base.color = Color("060806")
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)

	var wash := TextureRect.new()
	var wash_gradient := Gradient.new()
	wash_gradient.set_color(0, Color(0.055, 0.075, 0.055, 1.0))
	wash_gradient.set_color(1, Color(0.012, 0.016, 0.012, 1.0))
	var wash_tex := GradientTexture2D.new()
	wash_tex.gradient = wash_gradient
	wash_tex.fill = GradientTexture2D.FILL_LINEAR
	wash_tex.fill_from = Vector2(0.0, 0.0)
	wash_tex.fill_to = Vector2(1.0, 1.0)
	wash.texture = wash_tex
	wash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wash.stretch_mode = TextureRect.STRETCH_SCALE
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	var ghost_texture := load("res://assets/textures/ghost.png") as Texture2D
	if ghost_texture != null:
		_ghost = TextureRect.new()
		_ghost.texture = ghost_texture
		_ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_ghost.modulate = Color(0.75, 0.84, 0.75, 0.055)
		_ghost.anchor_left = 0.42
		_ghost.anchor_right = 1.0
		_ghost.anchor_top = 0.0
		_ghost.anchor_bottom = 0.9
		_ghost.offset_left = 100
		_ghost.offset_top = 10
		_ghost.offset_right = -20
		_ghost.offset_bottom = 0
		_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_ghost)

	var ember := TextureRect.new()
	var ember_gradient := Gradient.new()
	ember_gradient.set_color(0, Color(0.33, 0.055, 0.04, 0.28))
	ember_gradient.set_color(1, Color(0.33, 0.055, 0.04, 0.0))
	var ember_tex := GradientTexture2D.new()
	ember_tex.gradient = ember_gradient
	ember_tex.fill = GradientTexture2D.FILL_RADIAL
	ember_tex.fill_from = Vector2(0.0, 1.0)
	ember_tex.fill_to = Vector2(0.72, 0.55)
	ember.texture = ember_tex
	ember.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ember.stretch_mode = TextureRect.STRETCH_SCALE
	ember.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ember.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ember)

	var vignette := TextureRect.new()
	var vignette_gradient := Gradient.new()
	vignette_gradient.set_color(0, Color(0.0, 0.0, 0.0, 0.0))
	vignette_gradient.add_point(0.68, Color(0.0, 0.0, 0.0, 0.15))
	vignette_gradient.set_color(1, Color(0.0, 0.0, 0.0, 0.78))
	var vignette_tex := GradientTexture2D.new()
	vignette_tex.gradient = vignette_gradient
	vignette_tex.fill = GradientTexture2D.FILL_RADIAL
	vignette_tex.fill_from = Vector2(0.48, 0.46)
	vignette_tex.fill_to = Vector2(1.02, 0.52)
	vignette.texture = vignette_tex
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	UI.add_film_overlay(self)


func _build_content() -> void:
	var top_left := UI.mono("BLACK SITE  /  FACILITY 06", 11, UI.ink_faint)
	top_left.position = Vector2(92, 26)
	add_child(top_left)
	var top_right := UI.mono("NIGHT ADMISSION  /  03:17", 11, UI.ink_faint)
	top_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_right.anchor_left = 1.0
	top_right.anchor_right = 1.0
	top_right.offset_left = -432
	top_right.offset_right = -92
	top_right.offset_top = 26
	top_right.offset_bottom = 48
	add_child(top_right)

	var bottom_left := UI.mono("EST. 1987  /  SUB-LEVEL C  /  CARRIER 13.5", 10, Color(0.32, 0.35, 0.31, 0.8))
	bottom_left.anchor_top = 1.0
	bottom_left.anchor_bottom = 1.0
	bottom_left.offset_left = 92
	bottom_left.offset_right = 592
	bottom_left.offset_top = -40
	bottom_left.offset_bottom = -20
	add_child(bottom_left)
	var bottom_right := UI.mono("SIX ENDINGS  /  ONE RETURN", 10, Color(0.32, 0.35, 0.31, 0.8))
	bottom_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bottom_right.anchor_left = 1.0
	bottom_right.anchor_right = 1.0
	bottom_right.anchor_top = 1.0
	bottom_right.anchor_bottom = 1.0
	bottom_right.offset_left = -432
	bottom_right.offset_right = -92
	bottom_right.offset_top = -40
	bottom_right.offset_bottom = -20
	add_child(bottom_right)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 92)
	margin.add_theme_constant_override("margin_right", 92)
	margin.add_theme_constant_override("margin_top", 62)
	margin.add_theme_constant_override("margin_bottom", 54)
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 62)
	margin.add_child(row)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 7)
	row.add_child(left)

	_logo = UI.image_button_texture("res://assets/textures/title_logo.png", 600)
	_logo.custom_minimum_size = Vector2(600, 172)
	left.add_child(_logo)
	left.add_child(UI.spacer(2))
	left.add_child(UI.mono("SUBJECT 06  /  INTAKE 03  /  NIGHT ADMISSION", 11, UI.accent))
	var title := UI.heading("You have been here before.", 29, UI.ink)
	left.add_child(title)
	var body := UI.label(
		"Six ways out. One way back. The building keeps a record of every return, "
		+ "and it has been keeping it for a very long time.",
		14, UI.ink_dim, UI.font_serif, HORIZONTAL_ALIGNMENT_LEFT, true)
	body.custom_minimum_size = Vector2(540, 0)
	left.add_child(body)
	left.add_child(UI.spacer(18))

	var can_continue := SaveManager.has_save
	_continue_button = UI.button("CONTINUE", 392, 48, 16, HORIZONTAL_ALIGNMENT_CENTER)
	_continue_button.disabled = not can_continue
	_continue_button.pressed.connect(_on_continue)
	left.add_child(_continue_button)
	var begin := UI.button("BEGIN AGAIN", 392, 46, 15, HORIZONTAL_ALIGNMENT_CENTER, not can_continue)
	begin.pressed.connect(_on_begin_pressed)
	left.add_child(begin)
	var settings := UI.button("SETTINGS", 392, 44, 14, HORIZONTAL_ALIGNMENT_CENTER, false)
	settings.pressed.connect(_open_settings)
	left.add_child(settings)
	var quit := UI.button("QUIT TO DESKTOP", 392, 42, 13, HORIZONTAL_ALIGNMENT_CENTER, false)
	quit.pressed.connect(func() -> void: get_tree().quit())
	left.add_child(quit)

	var checkpoint_text := "NO SAVE RECORDED"
	if can_continue:
		checkpoint_text = "LAST CHECKPOINT  /  " + GameState.checkpoint_zone
	left.add_child(UI.spacer(4))
	left.add_child(UI.mono(checkpoint_text, 10, UI.ink_faint))

	row.add_child(_build_status_panel())

	if can_continue:
		_continue_button.grab_focus()
	else:
		begin.grab_focus()


func _build_status_panel() -> PanelContainer:
	var panel := UI.panel_panel(Color(0.018, 0.026, 0.019, 0.78), UI.border, 1, 28)
	panel.custom_minimum_size = Vector2(420, 0)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	box.add_child(UI.mono("THE BUILDING REMEMBERS", 10, UI.accent))
	box.add_child(UI.heading("Return Status", 25, UI.ink))
	box.add_child(UI.divider(UI.border, 1))
	var found := GameState.endings_found()
	var count_row := HBoxContainer.new()
	count_row.add_theme_constant_override("separation", 8)
	var big := UI.heading("%02d" % found, 58, UI.ink)
	count_row.add_child(big)
	var of_six := UI.heading("/ 06", 24, UI.ink_faint)
	of_six.size_flags_vertical = Control.SIZE_SHRINK_END
	of_six.custom_minimum_size = Vector2(0, 50)
	of_six.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_row.add_child(of_six)
	box.add_child(count_row)
	box.add_child(UI.mono("ENDINGS FOUND", 10, UI.ink_faint))
	box.add_child(UI.divider(UI.border, 1))
	box.add_child(UI.mono("RECORDED LOOPS", 10, UI.ink_faint))
	for i in range(1, 7):
		var data: Dictionary = StoryData.ENDINGS[i]
		var has_it := GameState.has_ending(i)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		var number := UI.mono("%02d" % i, 12, UI.accent if has_it else UI.ink_faint)
		number.custom_minimum_size = Vector2(28, 0)
		line.add_child(number)
		line.add_child(UI.label(str(data.get("title", "")) if has_it else "UNKNOWN LOOP", 13, UI.ink if has_it else UI.ink_faint))
		box.add_child(line)
	box.add_child(UI.divider(UI.border, 1))
	var tally_row := HBoxContainer.new()
	tally_row.add_child(UI.label("Return tally", 12, UI.ink_dim))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tally_row.add_child(gap)
	tally_row.add_child(UI.mono(str(GameState.return_tallies), 15, UI.ink))
	box.add_child(tally_row)
	box.add_child(UI.spacer(6))
	var quote := UI.label("You don't escape Black Site. You bounce back.", 15, Color("9b6b61"), UI.font_serif, HORIZONTAL_ALIGNMENT_LEFT, true)
	quote.custom_minimum_size = Vector2(340, 0)
	box.add_child(quote)
	return panel


func _on_continue() -> void:
	if _busy or not SaveManager.has_save:
		return
	GameState.run_active = true
	SaveManager.save_current()
	_go_to_game()


func _on_begin_pressed() -> void:
	if _busy:
		return
	if SaveManager.has_save:
		_open_confirm()
	else:
		_begin_new_game()


func _begin_new_game() -> void:
	if _busy:
		return
	_close_confirm()
	SaveManager.begin_new_run()
	_go_to_game()


func _go_to_game() -> void:
	if _busy:
		return
	_busy = true
	SceneTransition.change_scene("res://scenes/game.tscn", 0.9, 1.0)


func _open_confirm() -> void:
	if _confirm_root == null:
		_confirm_root = Control.new()
		_confirm_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_confirm_root.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(_confirm_root)
		var dim := ColorRect.new()
		dim.color = Color(0.004, 0.006, 0.004, 0.88)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_STOP
		_confirm_root.add_child(dim)
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_confirm_root.add_child(center)
		var panel := UI.panel_panel(Color(0.045, 0.052, 0.043, 0.99), UI.border, 1, 38)
		panel.custom_minimum_size = Vector2(560, 0)
		center.add_child(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 13)
		panel.add_child(box)
		box.add_child(UI.mono("INTAKE 03 / FRESH ADMISSION", 11, UI.accent))
		box.add_child(UI.heading("Begin again?", 30, UI.ink))
		box.add_child(UI.label("The current loop will be lost. The endings you have found will remain in the record.", 14, UI.ink_dim, UI.font_serif, HORIZONTAL_ALIGNMENT_LEFT, true))
		box.add_child(UI.divider(UI.border, 1))
		var buttons := HBoxContainer.new()
		buttons.add_theme_constant_override("separation", 10)
		buttons.alignment = BoxContainer.ALIGNMENT_END
		var cancel := UI.button("CANCEL", 150, 42, 14, HORIZONTAL_ALIGNMENT_CENTER, false)
		cancel.pressed.connect(_close_confirm)
		buttons.add_child(cancel)
		var confirm := UI.button("BEGIN AGAIN", 210, 42, 14, HORIZONTAL_ALIGNMENT_CENTER)
		confirm.pressed.connect(_begin_new_game)
		buttons.add_child(confirm)
		box.add_child(buttons)
		confirm.grab_focus()
	else:
		_confirm_root.visible = true
		_confirm_root.move_to_front()


func _close_confirm() -> void:
	if _confirm_root != null:
		_confirm_root.visible = false


func _open_settings() -> void:
	if _settings_root == null:
		_settings_root = Control.new()
		_settings_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_settings_root.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(_settings_root)
		var dim := ColorRect.new()
		dim.color = Color(0.004, 0.006, 0.004, 0.9)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_STOP
		_settings_root.add_child(dim)
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_settings_root.add_child(center)
		var settings_panel = load("res://scripts/settings_panel.gd").new()
		settings_panel.closed.connect(_close_settings)
		center.add_child(settings_panel)
	_settings_root.visible = true
	_settings_root.move_to_front()


func _close_settings() -> void:
	if _settings_root != null:
		_settings_root.visible = false


func _process(delta: float) -> void:
	_time += delta
	if _ghost != null:
		_ghost.modulate.a = 0.05 + sin(_time * 0.55) * 0.015
	_flicker_timer -= delta
	if _flicker_timer <= 0.0:
		_flicker_timer = randf_range(8.0, 16.0)
		_flicker_logo()


func _flicker_logo() -> void:
	if _logo == null:
		return
	AudioManager.play_sfx("light_buzz", -30.0, 0.2)
	var tween := create_tween()
	tween.tween_property(_logo, "modulate:a", 0.28, 0.05)
	tween.tween_property(_logo, "modulate:a", 0.9, 0.04)
	tween.tween_property(_logo, "modulate:a", 0.38, 0.07)
	tween.tween_property(_logo, "modulate:a", 1.0, 0.06)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _confirm_root != null and _confirm_root.visible:
			_close_confirm()
			get_viewport().set_input_as_handled()
		elif _settings_root != null and _settings_root.visible:
			_close_settings()
			get_viewport().set_input_as_handled()
