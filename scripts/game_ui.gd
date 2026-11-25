extends CanvasLayer

signal restart_requested
signal menu_requested

var game: Node
var modal_open: bool = false
var pause_open: bool = false
var ending_open: bool = false
var settings_open: bool = false
var input_enabled: bool = true

var _hud: Control
var _location_label: Label
var _zone_label: Label
var _objective_label: Label
var _prompt_panel: PanelContainer
var _prompt_label: Label
var _toast_panel: PanelContainer
var _toast_label: Label
var _inv_panel: PanelContainer
var _inv_rows: VBoxContainer
var _prompt_text: String = ""

var _modal_root: Control
var _modal_center: CenterContainer
var _modal_kind: String = ""
var _on_modal_close: Callable = Callable()

var _pause_root: Control
var _settings_root: Control
var _ending_root: Control
var _toast_tween: Tween
var _last_objective: String = ""
var _ending_video_layer: CanvasLayer
var _ending_video_player: VideoStreamPlayer
var _ending_video_closed: bool = false

const ENDING_VIDEO_PATH := "res://assets/video/ending_climax.ogv"
const ENDING_VIDEO_START := 8.0
const ENDING_VIDEO_FALLBACK := 4.0

var _keypad_code: String = ""
var _keypad_entry: String = ""
var _keypad_display: Label
var _keypad_callback: Callable = Callable()
var _keypad_note: Label

var _anchor_progress: Array[String] = []
var _anchor_slots: Array[Label] = []
var _anchor_note: Label

var _dial_value: float = 12.0
var _dial_display: Label
var _dial_note: Label
var _dial_slider: HSlider


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	InventoryManager.inventory_changed.connect(update_inventory)
	_build_hud()
	update_inventory()


func _panel(fill: Color, border_color: Color = Color.TRANSPARENT, margin: int = 24) -> PanelContainer:
	return UI.panel_panel(fill, border_color, 1 if border_color != Color.TRANSPARENT else 0, margin)


func _shadow_label(node: Label) -> Label:
	node.add_theme_constant_override("outline_size", 5)
	node.add_theme_color_override("font_outline_color", Color(0.01, 0.012, 0.01, 0.9))
	return node


func _build_hud() -> void:
	_hud = Control.new()
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud)

	var top_left := VBoxContainer.new()
	top_left.position = Vector2(34, 24)
	top_left.custom_minimum_size = Vector2(480, 0)
	top_left.add_theme_constant_override("separation", 3)
	_hud.add_child(top_left)
	_location_label = _shadow_label(UI.heading("INTAKE 03", 25, UI.ink))
	_zone_label = _shadow_label(UI.mono("BLACK SITE  /  LOOP 42  /  03:17", 12, UI.ink_dim))
	top_left.add_child(_location_label)
	top_left.add_child(_zone_label)

	var objective_panel := PanelContainer.new()
	var ostyle := UI.stylebox(Color(0.025, 0.032, 0.025, 0.72), UI.accent_dim, 1, 13)
	ostyle.border_width_left = 3
	ostyle.border_color = UI.accent
	objective_panel.add_theme_stylebox_override("panel", ostyle)
	objective_panel.custom_minimum_size = Vector2(432, 0)
	objective_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var objective_margin := MarginContainer.new()
	objective_margin.add_theme_constant_override("margin_top", 5)
	var objective_box := VBoxContainer.new()
	objective_box.add_theme_constant_override("separation", 4)
	objective_box.add_child(UI.mono("CURRENT IMPRESSION", 10, UI.accent))
	_objective_label = UI.label("", 14, UI.ink_dim, UI.font_ui, HORIZONTAL_ALIGNMENT_LEFT, true)
	objective_box.add_child(_objective_label)
	objective_margin.add_child(objective_box)
	objective_panel.add_child(objective_margin)
	var obj_gap := Control.new()
	obj_gap.custom_minimum_size = Vector2(0, 10)
	top_left.add_child(obj_gap)
	top_left.add_child(objective_panel)

	var controls := UI.mono("WASD  MOVE\nSHIFT  RUN\nE  INTERACT\nTAB  CASE NOTES\nESC  PAUSE", 12, Color(0.48, 0.51, 0.46, 0.8))
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls.position = Vector2(1040, 26)
	controls.custom_minimum_size = Vector2(206, 0)
	_shadow_label(controls)
	_hud.add_child(controls)

	_inv_panel = PanelContainer.new()
	_inv_panel.anchor_left = 0.0
	_inv_panel.anchor_right = 0.0
	_inv_panel.anchor_top = 1.0
	_inv_panel.anchor_bottom = 1.0
	_inv_panel.offset_left = 34
	_inv_panel.offset_right = 500
	_inv_panel.offset_top = -154
	_inv_panel.offset_bottom = -34
	_inv_panel.add_theme_stylebox_override("panel", UI.stylebox(Color(0.025, 0.032, 0.025, 0.64), Color(0.22, 0.24, 0.21, 0.75), 1, 16))
	_inv_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_inv_panel)
	var inv_box := VBoxContainer.new()
	inv_box.add_theme_constant_override("separation", 9)
	_inv_panel.add_child(inv_box)
	inv_box.add_child(UI.mono("CARRIED", 10, UI.ink_faint))
	_inv_rows = VBoxContainer.new()
	_inv_rows.add_theme_constant_override("separation", 5)
	inv_box.add_child(_inv_rows)

	var prompt_center := CenterContainer.new()
	prompt_center.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	prompt_center.offset_top = -108
	prompt_center.offset_bottom = -56
	prompt_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(prompt_center)
	_prompt_panel = PanelContainer.new()
	_prompt_panel.add_theme_stylebox_override("panel", UI.stylebox(Color(0.025, 0.032, 0.025, 0.94), Color(0.4, 0.38, 0.31, 0.7), 1, 13))
	_prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_center.add_child(_prompt_panel)
	var prompt_row := HBoxContainer.new()
	prompt_row.add_theme_constant_override("separation", 10)
	_prompt_panel.add_child(prompt_row)
	var keycap := PanelContainer.new()
	keycap.add_theme_stylebox_override("panel", UI.stylebox(Color(0.1, 0.11, 0.09, 1), Color(0.48, 0.45, 0.36, 0.9), 1, 7))
	keycap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keycap.add_child(UI.mono("E", 15, UI.ink))
	prompt_row.add_child(keycap)
	_prompt_label = UI.label("", 15, UI.ink)
	prompt_row.add_child(_prompt_label)
	_prompt_panel.visible = false

	var toast_center := CenterContainer.new()
	toast_center.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	toast_center.offset_top = -184
	toast_center.offset_bottom = -124
	toast_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(toast_center)
	_toast_panel = PanelContainer.new()
	_toast_panel.add_theme_stylebox_override("panel", UI.stylebox(Color(0.11, 0.055, 0.045, 0.96), UI.accent_dim, 1, 14))
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_center.add_child(_toast_panel)
	_toast_label = UI.label("", 14, Color("ddd5bf"), UI.font_ui, HORIZONTAL_ALIGNMENT_CENTER, true)
	_toast_label.custom_minimum_size = Vector2(500, 0)
	_toast_panel.add_child(_toast_label)
	_toast_panel.visible = false

	_hud.visible = true


func set_hud_visible(value: bool) -> void:
	_hud.visible = value
	if not value:
		_prompt_panel.visible = false


func set_location(zone_name: String) -> void:
	_location_label.text = zone_name


func set_objective(text_value: String) -> void:
	if text_value == _last_objective:
		return
	_last_objective = text_value
	_objective_label.text = text_value


func set_prompt(text_value: String) -> void:
	_prompt_text = text_value
	_update_prompt_visibility()


func _update_prompt_visibility() -> void:
	var blocked := modal_open or pause_open or ending_open or settings_open
	var show := not blocked and not _prompt_text.is_empty()
	_prompt_panel.visible = show
	if show:
		_prompt_label.text = _prompt_text


func update_inventory() -> void:
	if _inv_rows == null:
		return
	for child in _inv_rows.get_children():
		_inv_rows.remove_child(child)
		child.queue_free()
	_inv_panel.visible = not InventoryManager.items.is_empty()
	if InventoryManager.items.is_empty():
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_inv_rows.add_child(row)
	var chips_in_row := 0
	for item_id in InventoryManager.items:
		if chips_in_row >= 3:
			row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			_inv_rows.add_child(row)
			chips_in_row = 0
		var data: Dictionary = StoryData.ITEMS.get(item_id, {})
		var chip := PanelContainer.new()
		var color := Color(str(data.get("color", "#8d9082")))
		var st := UI.stylebox(Color(0.035, 0.045, 0.038, 0.9), color.darkened(0.35), 1, 8)
		st.border_width_left = 3
		st.border_color = color
		chip.add_theme_stylebox_override("panel", st)
		chip.add_child(UI.mono(str(data.get("short", "ITEM")), 11, UI.ink))
		row.add_child(chip)
		chips_in_row += 1


func toast(text_value: String, duration: float = 3.4) -> void:
	if _toast_panel == null:
		return
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_label.text = text_value
	_toast_panel.visible = true
	_toast_panel.modulate.a = 0.0
	_toast_tween = create_tween()
	_toast_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.16)
	_toast_tween.tween_interval(duration)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func() -> void: _toast_panel.visible = false)


func show_intro() -> void:
	if modal_open or ending_open:
		return
	_open_modal_base()
	_modal_kind = "intro"
	_clear_modal_content()
	var panel := _panel(Color(0.045, 0.052, 0.043, 0.98), UI.border, 40)
	panel.custom_minimum_size = Vector2(720, 0)
	_modal_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var logo := UI.image_button_texture("res://assets/textures/title_logo.png", 560)
	logo.custom_minimum_size = Vector2(560, 160)
	box.add_child(logo)
	box.add_child(UI.mono("INTAKE 03  /  03:17  /  NIGHT ADMISSION", 12, UI.accent))
	box.add_child(UI.heading("You have been here before.", 26, UI.ink))
	var body := UI.label(
		"The clock is wrong. The door is unlocked. The building smells of bleach and wet paper. "
		+ "There is a bed with forty-one scratches cut into the frame. The last tally is fresh.\n\n"
		+ "Find a way out. Remember what the building tells you. It will lie politely.",
		15, UI.ink_dim, UI.font_serif, HORIZONTAL_ALIGNMENT_LEFT, true)
	body.custom_minimum_size = Vector2(620, 0)
	box.add_child(body)
	box.add_child(UI.divider(UI.border, 1))
	var controls := UI.mono("WASD move    SHIFT run    E interact    TAB case notes    ESC pause", 12, UI.ink_faint)
	box.add_child(controls)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	var begin := UI.button("GET UP", 190, 46, 16, HORIZONTAL_ALIGNMENT_CENTER)
	begin.pressed.connect(_close_intro)
	footer.add_child(begin)
	box.add_child(footer)
	begin.grab_focus()


func _close_intro() -> void:
	GameState.intro_seen = true
	SaveManager.save_current()
	close_modal()


func show_document(document_id: String) -> void:
	var data: Dictionary = StoryData.DOCS.get(document_id, {})
	if data.is_empty():
		return
	if modal_open or ending_open:
		return
	_open_modal_base()
	_modal_kind = "document"
	_clear_modal_content()
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(800, 0)
	var paper_style := UI.stylebox(UI.paper, Color("7c7662"), 1, 38)
	panel.add_theme_stylebox_override("panel", paper_style)
	_modal_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var top := HBoxContainer.new()
	top.add_child(UI.mono("BLACK SITE / CASE FILE", 11, Color("6d332b")))
	var top_gap := Control.new()
	top_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(top_gap)
	top.add_child(UI.mono("RECOVERED", 11, Color("6d332b")))
	box.add_child(top)
	box.add_child(UI.heading(str(data.get("title", "UNTITLED")), 31, UI.paper_ink))
	box.add_child(UI.mono(str(data.get("code", "")), 12, Color("5d5b4d")))
	box.add_child(UI.divider(Color("8e8874"), 1))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 304)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var body := UI.rich_label(str(data.get("body", "")), 17, UI.paper_ink, UI.font_serif)
	body.custom_minimum_size = Vector2(716, 0)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	box.add_child(UI.divider(Color("8e8874"), 1))
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	var hint := UI.label("Margin note: " + str(data.get("hint", "")), 12, Color("5d5b4d"), UI.font_serif)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(hint)
	var close := UI.button("CLOSE  [E]", 170, 40, 14, HORIZONTAL_ALIGNMENT_CENTER, false)
	close.pressed.connect(close_modal)
	footer.add_child(close)
	box.add_child(footer)
	close.grab_focus()
	AudioManager.play_sfx("page", -15.0, 0.02)
	AudioManager.play_sfx("signal_lost", -24.0 if document_id in ["patient_13", "intake_06", "boiler_note", "tally_scrap"] else -30.0, 0.0)
	_animate_document(panel, body)


func _animate_document(panel: Control, body: RichTextLabel) -> void:
	panel.scale = Vector2(0.9, 0.9)
	panel.modulate.a = 0.0
	panel.rotation = -0.018
	body.visible_ratio = 0.0
	await get_tree().process_frame
	if not is_instance_valid(panel) or not is_instance_valid(body):
		return
	panel.pivot_offset = panel.size * 0.5
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.set_parallel(true)
	t.tween_property(panel, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	t.tween_property(panel, "rotation", 0.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(panel, "modulate:a", 1.0, 0.2)
	var type_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	type_tween.tween_interval(0.16)
	type_tween.tween_property(body, "visible_ratio", 1.0, 0.85).set_trans(Tween.TRANS_LINEAR)
	var ghost := TextureRect.new()
	ghost.texture = load("res://assets/textures/ghost.png")
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ghost.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.modulate = Color(0.86, 0.94, 0.9, 0.0)
	_modal_root.add_child(ghost)
	var ghost_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	ghost_tween.tween_property(ghost, "modulate:a", 0.15, 0.16)
	ghost_tween.tween_property(ghost, "modulate:a", 0.0, 1.35)
	ghost_tween.tween_callback(ghost.queue_free)
	var flash := ColorRect.new()
	flash.color = Color(0.34, 0.02, 0.01, 1.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.modulate.a = 0.0
	_modal_root.add_child(flash)
	var flash_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	flash_tween.tween_property(flash, "modulate:a", 0.13, 0.05)
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.35)
	flash_tween.tween_callback(flash.queue_free)


func show_journal() -> void:
	if modal_open or ending_open or pause_open:
		return
	_open_modal_base()
	_modal_kind = "journal"
	_clear_modal_content()
	var panel := _panel(Color(0.035, 0.043, 0.035, 0.985), UI.border, 32)
	panel.custom_minimum_size = Vector2(980, 0)
	_modal_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var head := HBoxContainer.new()
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 1)
	title_box.add_child(UI.mono("SUBJECT 06 / INTAKE 03", 11, UI.accent))
	title_box.add_child(UI.heading("Case Notes", 33, UI.ink))
	head.add_child(title_box)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	head.add_child(UI.mono("DOCUMENTS %d / %d" % [GameState.documents.size(), StoryData.DOC_ORDER.size()], 12, UI.ink_dim))
	box.add_child(head)
	box.add_child(UI.divider(UI.border, 1))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 30)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(590, 0)
	left.add_theme_constant_override("separation", 7)
	left.add_child(UI.mono("RECOVERED FILES", 11, UI.ink_faint))
	var docs_scroll := ScrollContainer.new()
	docs_scroll.custom_minimum_size = Vector2(590, 410)
	docs_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(docs_scroll)
	var docs_box := VBoxContainer.new()
	docs_box.add_theme_constant_override("separation", 8)
	docs_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	docs_scroll.add_child(docs_box)
	var found := 0
	for id in StoryData.DOC_ORDER:
		if GameState.has_read_document(id):
			found += 1
			var data: Dictionary = StoryData.DOCS.get(id, {})
			var entry := VBoxContainer.new()
			entry.add_theme_constant_override("separation", 1)
			entry.add_child(UI.label(str(data.get("title", id)), 14, UI.ink))
			entry.add_child(UI.label(str(data.get("hint", "")), 12, UI.ink_dim, UI.font_serif, HORIZONTAL_ALIGNMENT_LEFT, true))
			docs_box.add_child(entry)
		else:
			docs_box.add_child(UI.label("UNRECOVERED FILE", 13, UI.ink_faint))
	if found == 0:
		docs_box.add_child(UI.label("No files yet. The building has not decided what to show you.", 14, UI.ink_dim, UI.font_serif, HORIZONTAL_ALIGNMENT_LEFT, true))
	columns.add_child(left)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(290, 0)
	right.add_theme_constant_override("separation", 8)
	right.add_child(UI.mono("CARRIED", 11, UI.ink_faint))
	if InventoryManager.items.is_empty():
		right.add_child(UI.label("Empty pockets.", 13, UI.ink_faint))
	for item_id in InventoryManager.items:
		var data: Dictionary = StoryData.ITEMS.get(item_id, {})
		var color := Color(str(data.get("color", "#8d9082")))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var swatch := ColorRect.new()
		swatch.color = color
		swatch.custom_minimum_size = Vector2(3, 20)
		row.add_child(swatch)
		row.add_child(UI.label(str(data.get("name", item_id)), 13, UI.ink))
		right.add_child(row)
	right.add_child(UI.spacer(12))
	right.add_child(UI.mono("LOGS", 11, UI.ink_faint))
	right.add_child(UI.label("Endings found: %d / 6" % GameState.endings_found(), 13, UI.ink_dim))
	right.add_child(UI.label("Return tallies: %d" % GameState.return_tallies, 13, UI.ink_dim))
	right.add_child(UI.spacer(12))
	right.add_child(UI.mono("THE BUILDING SAYS", 11, UI.ink_faint))
	var tale := UI.label("You do not escape Black Site. You bounce back.", 14, Color("9b6b61"), UI.font_serif, HORIZONTAL_ALIGNMENT_LEFT, true)
	right.add_child(tale)
	columns.add_child(right)
	box.add_child(UI.divider(UI.border, 1))
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	var close := UI.button("CLOSE  [TAB]", 190, 40, 14, HORIZONTAL_ALIGNMENT_CENTER, false)
	close.pressed.connect(close_modal)
	footer.add_child(close)
	box.add_child(footer)
	close.grab_focus()


func open_keypad(code: String, callback: Callable) -> void:
	if modal_open or ending_open:
		return
	_open_modal_base()
	_modal_kind = "keypad"
	_keypad_code = code
	_keypad_entry = ""
	_keypad_callback = callback
	_clear_modal_content()
	var panel := _panel(Color(0.035, 0.04, 0.034, 0.99), UI.border, 30)
	panel.custom_minimum_size = Vector2(430, 0)
	_modal_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(UI.mono("SECURITY / RESTRICTED", 11, UI.accent))
	box.add_child(UI.heading("Keypad", 30, UI.ink))
	box.add_child(UI.label("A three-digit code. The brass is worn smooth on 3, 1 and 4.", 13, UI.ink_dim, UI.font_serif, HORIZONTAL_ALIGNMENT_LEFT, true))
	_keypad_note = UI.mono("ENTER CODE", 11, UI.ink_faint)
	box.add_child(_keypad_note)
	_keypad_display = Label.new()
	_keypad_display.text = "_  _  _"
	_keypad_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_keypad_display.add_theme_font_override("font", UI.font_mono)
	_keypad_display.add_theme_font_size_override("font_size", 44)
	_keypad_display.add_theme_color_override("font_color", Color("b7d2b5"))
	_keypad_display.add_theme_stylebox_override("normal", UI.stylebox(Color(0.01, 0.02, 0.012, 1), Color(0.15, 0.24, 0.16, 1), 1, 10))
	_keypad_display.custom_minimum_size = Vector2(0, 78)
	box.add_child(_keypad_display)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	for n in range(1, 10):
		var b := UI.button(str(n), 118, 64, 20, HORIZONTAL_ALIGNMENT_CENTER, false)
		b.pressed.connect(_keypad_push.bind(str(n)))
		grid.add_child(b)
	var clr := UI.button("CLR", 118, 64, 15, HORIZONTAL_ALIGNMENT_CENTER, false)
	clr.pressed.connect(func() -> void: _keypad_set(""))
	grid.add_child(clr)
	var zero := UI.button("0", 118, 64, 20, HORIZONTAL_ALIGNMENT_CENTER, false)
	zero.pressed.connect(_keypad_push.bind("0"))
	grid.add_child(zero)
	var enter := UI.button("ENTER", 118, 64, 14, HORIZONTAL_ALIGNMENT_CENTER)
	enter.pressed.connect(_keypad_submit)
	grid.add_child(enter)
	var close := UI.button("BACK", 120, 36, 12, HORIZONTAL_ALIGNMENT_CENTER, false)
	close.pressed.connect(close_modal)
	var f := HBoxContainer.new()
	f.alignment = BoxContainer.ALIGNMENT_END
	f.add_child(close)
	box.add_child(f)
	enter.grab_focus()


func _keypad_set(value: String) -> void:
	_keypad_entry = value.substr(0, mini(3, value.length()))
	var shown := ""
	for i in range(3):
		shown += (str(_keypad_entry[i]) if i < _keypad_entry.length() else "_")
		shown += "  " if i < 2 else ""
	_keypad_display.text = shown


func _keypad_push(digit: String) -> void:
	if _keypad_entry.length() >= 3:
		return
	AudioManager.play_sfx("keypad_beep", -13.0, 0.01)
	_keypad_set(_keypad_entry + digit)


func _keypad_submit() -> void:
	if _keypad_entry == _keypad_code:
		AudioManager.play_sfx("keypad_ok", -8.0, 0.0)
		var callback := _keypad_callback
		close_modal()
		if callback.is_valid():
			callback.call()
	else:
		AudioManager.play_sfx("keypad_error", -9.0, 0.0)
		_keypad_note.text = "DENIED / CODE REJECTED"
		_keypad_note.add_theme_color_override("font_color", Color("c06458"))
		_keypad_set("")


func open_anchor_panel() -> void:
	if modal_open or ending_open:
		return
	_open_modal_base()
	_modal_kind = "anchor"
	_anchor_progress.clear()
	_clear_modal_content()
	var panel := _panel(Color(0.028, 0.038, 0.03, 0.99), UI.border, 34)
	panel.custom_minimum_size = Vector2(660, 0)
	_modal_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(UI.mono("ANCHOR ARRAY / SECURITY", 11, UI.accent))
	box.add_child(UI.heading("Boot Sequence", 32, UI.ink))
	box.add_child(UI.label("Three circuits are cold. Seat the fuses, then wake the anchors in the correct order.", 13, UI.ink_dim, UI.font_serif, HORIZONTAL_ALIGNMENT_LEFT, true))
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 10)
	box.add_child(slots)
	_anchor_slots.clear()
	for i in range(3):
		var slot := PanelContainer.new()
		slot.add_theme_stylebox_override("panel", UI.stylebox(Color(0.01, 0.02, 0.012, 1), Color(0.18, 0.26, 0.18, 1), 1, 14))
		slot.custom_minimum_size = Vector2(186, 70)
		var lab := UI.mono("SLOT %d\nCOLD" % (i + 1), 12, UI.ink_faint)
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(lab)
		_anchor_slots.append(lab)
		slots.add_child(slot)
	_anchor_note = UI.mono("AWAITING INPUT", 11, UI.ink_faint)
	box.add_child(_anchor_note)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	for spec in [["lights", "LIGHTS"], ["records", "RECORDS"], ["lift", "LIFT"], ["return", "RETURN"]]:
		var b := UI.button(str(spec[1]), 286, 58, 15, HORIZONTAL_ALIGNMENT_CENTER, spec[0] != "return")
		b.pressed.connect(_anchor_press.bind(str(spec[0])))
		grid.add_child(b)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	var close := UI.button("BACK", 130, 38, 13, HORIZONTAL_ALIGNMENT_CENTER, false)
	close.pressed.connect(close_modal)
	footer.add_child(close)
	box.add_child(footer)


func _anchor_press(key: String) -> void:
	if key == "return":
		AudioManager.play_sfx("keypad_error", -8.0, 0.0)
		_anchor_progress.clear()
		_reset_anchor_slots()
		_anchor_note.text = "RETURN ANCHOR DARK / SEQUENCE CLEARED"
		_anchor_note.add_theme_color_override("font_color", Color("c06458"))
		return
	var expected := "lights" if _anchor_progress.is_empty() else ("records" if _anchor_progress.size() == 1 else "lift")
	if key != expected:
		AudioManager.play_sfx("keypad_error", -9.0, 0.0)
		_anchor_progress.clear()
		_reset_anchor_slots()
		_anchor_note.text = "GROUND FAULT / ARRAY RESET"
		_anchor_note.add_theme_color_override("font_color", Color("c06458"))
		return
	AudioManager.play_sfx("keypad_beep", -12.0, 0.01)
	_anchor_progress.append(key)
	var idx := _anchor_progress.size() - 1
	_anchor_slots[idx].text = "SLOT %d\n%s" % [idx + 1, key.to_upper()]
	_anchor_slots[idx].add_theme_color_override("font_color", Color("9fc6a0"))
	_anchor_note.text = "CIRCUIT %d LIVE" % _anchor_progress.size()
	_anchor_note.add_theme_color_override("font_color", Color("8eb28d"))
	if _anchor_progress.size() == 3:
		AudioManager.play_sfx("unlock", -8.0, 0.0)
		game.solve_anchor()
		close_modal()


func _reset_anchor_slots() -> void:
	for i in range(_anchor_slots.size()):
		_anchor_slots[i].text = "SLOT %d\nCOLD" % (i + 1)
		_anchor_slots[i].add_theme_color_override("font_color", UI.ink_faint)


func open_dial_panel() -> void:
	if modal_open or ending_open:
		return
	_open_modal_base()
	_modal_kind = "dial"
	_dial_value = 12.0
	_clear_modal_content()
	var panel := _panel(Color(0.035, 0.032, 0.027, 0.99), UI.border, 34)
	panel.custom_minimum_size = Vector2(600, 0)
	_modal_center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(UI.mono("SUB-LEVEL C / RETURN CARRIER", 11, UI.accent))
	box.add_child(UI.heading("Tune the Carrier", 32, UI.ink))
	box.add_child(UI.label("The needle resists. Somewhere above, the building is still folding the corridor around you.", 13, UI.ink_dim, UI.font_serif, HORIZONTAL_ALIGNMENT_LEFT, true))
	_dial_display = Label.new()
	_dial_display.text = "12.0 kHz"
	_dial_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dial_display.add_theme_font_override("font", UI.font_mono)
	_dial_display.add_theme_font_size_override("font_size", 56)
	_dial_display.add_theme_color_override("font_color", Color("dbc99c"))
	_dial_display.add_theme_stylebox_override("normal", UI.stylebox(Color(0.02, 0.018, 0.014, 1), Color(0.25, 0.22, 0.16, 1), 1, 12))
	_dial_display.custom_minimum_size = Vector2(0, 92)
	box.add_child(_dial_display)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var minus := UI.button("- 0.1", 140, 48, 15, HORIZONTAL_ALIGNMENT_CENTER, false)
	minus.pressed.connect(_dial_adjust.bind(-0.1))
	row.add_child(minus)
	_dial_slider = HSlider.new()
	_dial_slider.min_value = 12.0
	_dial_slider.max_value = 15.0
	_dial_slider.step = 0.1
	_dial_slider.value = 12.0
	_dial_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dial_slider.custom_minimum_size = Vector2(190, 42)
	_dial_slider.value_changed.connect(_dial_changed)
	row.add_child(_dial_slider)
	var plus := UI.button("+ 0.1", 140, 48, 15, HORIZONTAL_ALIGNMENT_CENTER, false)
	plus.pressed.connect(_dial_adjust.bind(0.1))
	row.add_child(plus)
	box.add_child(row)
	_dial_note = UI.mono("CARRIER ACTIVE / 12.0", 11, UI.ink_faint)
	box.add_child(_dial_note)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	footer.alignment = BoxContainer.ALIGNMENT_END
	var close := UI.button("BACK", 130, 40, 13, HORIZONTAL_ALIGNMENT_CENTER, false)
	close.pressed.connect(close_modal)
	footer.add_child(close)
	var tune := UI.button("TUNE", 160, 40, 14, HORIZONTAL_ALIGNMENT_CENTER)
	tune.pressed.connect(_dial_tune)
	footer.add_child(tune)
	box.add_child(footer)
	tune.grab_focus()


func _dial_adjust(amount: float) -> void:
	_dial_slider.value = clampf(snappedf(_dial_slider.value + amount, 0.1), 12.0, 15.0)
	AudioManager.play_sfx("keypad_beep", -18.0, 0.0)


func _dial_changed(value: float) -> void:
	_dial_value = snappedf(value, 0.1)
	_dial_display.text = "%.1f kHz" % _dial_value
	_dial_note.text = "CARRIER ACTIVE / %.1f" % _dial_value
	_dial_note.add_theme_color_override("font_color", UI.ink_faint)


func _dial_tune() -> void:
	if is_equal_approx(_dial_value, 13.5):
		AudioManager.play_sfx("unlock", -8.0, 0.0)
		game.solve_dial()
		close_modal()
	else:
		AudioManager.play_sfx("keypad_error", -9.0, 0.0)
		_dial_note.text = "CARRIER REJECTED / THE CORRIDOR HOLDS"
		_dial_note.add_theme_color_override("font_color", Color("c06458"))


func _open_modal_base() -> void:
	if _modal_root == null:
		_modal_root = Control.new()
		_modal_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_modal_root.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(_modal_root)
		var dim := ColorRect.new()
		dim.color = Color(0.006, 0.008, 0.006, 0.82)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_STOP
		_modal_root.add_child(dim)
		_modal_center = CenterContainer.new()
		_modal_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_modal_center.mouse_filter = Control.MOUSE_FILTER_PASS
		_modal_root.add_child(_modal_center)
	modal_open = true
	_modal_root.visible = true
	_modal_root.move_to_front()
	_prompt_panel.visible = false
	_on_modal_close = Callable()
	if game != null and game.player != null:
		game.player.set_control(false)


func _clear_modal_content() -> void:
	if _modal_center == null:
		return
	for child in _modal_center.get_children():
		_modal_center.remove_child(child)
		child.queue_free()


func close_modal() -> void:
	if not modal_open:
		return
	var callback := _on_modal_close
	_on_modal_close = Callable()
	modal_open = false
	_modal_kind = ""
	_keypad_callback = Callable()
	if _modal_root != null:
		_modal_root.visible = false
		_clear_modal_content()
	if game != null and game.player != null and not pause_open and not ending_open:
		game.player.set_control(true)
		if game.has_method("suppress_interaction"):
			game.suppress_interaction(0.35)
	_update_prompt_visibility()
	if callback.is_valid():
		callback.call()


func open_pause() -> void:
	if modal_open or ending_open or pause_open or settings_open:
		return
	pause_open = true
	get_tree().paused = true
	if game != null and game.player != null:
		game.player.set_control(false)
	_build_pause_root()
	_pause_root.visible = true
	_pause_root.move_to_front()
	_update_prompt_visibility()


func _build_pause_root() -> void:
	if _pause_root != null:
		return
	_pause_root = Control.new()
	_pause_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_pause_root)
	var dim := ColorRect.new()
	dim.color = Color(0.005, 0.007, 0.005, 0.84)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	_pause_root.add_child(center)
	var panel := _panel(Color(0.04, 0.048, 0.038, 0.99), UI.border, 40)
	panel.custom_minimum_size = Vector2(500, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	panel.add_child(box)
	box.add_child(UI.mono("BLACK SITE / PAUSED", 11, UI.accent))
	box.add_child(UI.heading("Hold still.", 34, UI.ink))
	box.add_child(UI.label("The building will wait. It is very good at waiting.", 13, UI.ink_dim, UI.font_serif, HORIZONTAL_ALIGNMENT_LEFT, true))
	box.add_child(UI.divider(UI.border, 1))
	var resume := UI.button("RESUME", 380, 46, 16, HORIZONTAL_ALIGNMENT_CENTER)
	resume.pressed.connect(resume_game)
	box.add_child(resume)
	var settings := UI.button("SETTINGS", 380, 44, 15, HORIZONTAL_ALIGNMENT_CENTER, false)
	settings.pressed.connect(open_settings)
	box.add_child(settings)
	box.add_child(UI.spacer(4))
	var save_exit := UI.button("SAVE & MAIN MENU", 380, 44, 14, HORIZONTAL_ALIGNMENT_CENTER, false)
	save_exit.pressed.connect(_save_and_menu)
	box.add_child(save_exit)
	var quit := UI.button("QUIT TO DESKTOP", 380, 42, 13, HORIZONTAL_ALIGNMENT_CENTER, false)
	quit.pressed.connect(_quit_game)
	box.add_child(quit)
	box.add_child(UI.mono("PROGRESS SAVES WHEN YOU INTERACT", 10, UI.ink_faint))
	resume.grab_focus()


func resume_game() -> void:
	if not pause_open:
		return
	pause_open = false
	get_tree().paused = false
	if _pause_root != null:
		_pause_root.visible = false
	if _settings_root != null:
		_settings_root.visible = false
		settings_open = false
	if game != null and game.player != null:
		game.player.set_control(true)
		if game.has_method("suppress_interaction"):
			game.suppress_interaction(0.35)
	_update_prompt_visibility()


func open_settings() -> void:
	if _settings_root == null:
		_settings_root = Control.new()
		_settings_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_settings_root.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(_settings_root)
		var dim := ColorRect.new()
		dim.color = Color(0.005, 0.007, 0.005, 0.88)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_STOP
		_settings_root.add_child(dim)
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = Control.MOUSE_FILTER_PASS
		_settings_root.add_child(center)
		var settings_panel = load("res://scripts/settings_panel.gd").new()
		settings_panel.closed.connect(_close_settings)
		center.add_child(settings_panel)
	settings_open = true
	_pause_root.visible = false
	_settings_root.visible = true
	_settings_root.move_to_front()


func _close_settings() -> void:
	settings_open = false
	if _settings_root != null:
		_settings_root.visible = false
	if pause_open and _pause_root != null:
		_pause_root.visible = true
		_pause_root.move_to_front()


func _save_and_menu() -> void:
	get_tree().paused = false
	if game != null:
		game.save_progress()
	resume_game()
	SceneTransition.change_scene("res://scenes/main_menu.tscn", 0.7, 0.7)


func _quit_game() -> void:
	if game != null:
		game.save_progress()
	get_tree().quit()


func show_ending(ending_id: int) -> void:
	var data: Dictionary = StoryData.ENDINGS.get(ending_id, {})
	if data.is_empty():
		return
	ending_open = true
	modal_open = false
	pause_open = false
	settings_open = false
	if _modal_root != null:
		_modal_root.visible = false
	if _pause_root != null:
		_pause_root.visible = false
	if _settings_root != null:
		_settings_root.visible = false
	_hud.visible = false
	_prompt_panel.visible = false
	get_tree().paused = true
	if game != null and game.player != null:
		game.player.set_control(false)
	if _ending_root == null:
		_ending_root = Control.new()
		_ending_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_ending_root.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(_ending_root)
	else:
		for child in _ending_root.get_children():
			_ending_root.remove_child(child)
			child.queue_free()
	var bg := ColorRect.new()
	bg.color = Color(0.006, 0.008, 0.006, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ending_root.add_child(bg)
	var glow := TextureRect.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.16, 0.04, 0.03, 0.5))
	gradient.set_color(1, Color(0.0, 0.0, 0.0, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.16, 0.2)
	tex.fill_to = Vector2(1.0, 1.0)
	glow.texture = tex
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ending_root.add_child(glow)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 110)
	margin.add_theme_constant_override("margin_right", 110)
	margin.add_theme_constant_override("margin_top", 70)
	margin.add_theme_constant_override("margin_bottom", 60)
	_ending_root.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 62)
	margin.add_child(row)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(560, 0)
	left.add_theme_constant_override("separation", 13)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	left.add_child(UI.mono(str(data.get("number", "ENDING")), 12, UI.accent))
	var title := UI.heading(str(data.get("title", "UNKNOWN")), 56, UI.ink)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(title)
	left.add_child(UI.mono(str(data.get("tag", "")), 12, Color(str(data.get("accent", "#8d3b31")))))
	var line := ColorRect.new()
	line.color = Color(str(data.get("accent", "#8d3b31")))
	line.custom_minimum_size = Vector2(120, 2)
	left.add_child(line)
	var summary := UI.label(str(data.get("summary", "")), 18, UI.ink_dim, UI.font_serif, HORIZONTAL_ALIGNMENT_LEFT, true)
	summary.custom_minimum_size = Vector2(540, 0)
	left.add_child(summary)
	var body := UI.rich_label(str(data.get("body", "")), 16, UI.ink, UI.font_serif)
	body.custom_minimum_size = Vector2(540, 0)
	left.add_child(body)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(spacer)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	var wake := UI.button("WAKE IN INTAKE", 240, 46, 15, HORIZONTAL_ALIGNMENT_CENTER)
	wake.pressed.connect(func() -> void:
		get_tree().paused = false
		restart_requested.emit()
	)
	buttons.add_child(wake)
	var menu := UI.button("MAIN MENU", 180, 46, 13, HORIZONTAL_ALIGNMENT_CENTER, false)
	menu.pressed.connect(func() -> void:
		get_tree().paused = false
		menu_requested.emit()
	)
	buttons.add_child(menu)
	left.add_child(buttons)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(310, 0)
	right.add_theme_constant_override("separation", 9)
	var right_head := UI.mono("THE BUILDING REMEMBERS", 11, UI.ink_faint)
	right.add_child(right_head)
	var tally := UI.label("RETURN TALLY", 11, UI.ink_faint, UI.font_mono)
	right.add_child(tally)
	var tally_number := UI.heading("%02d" % GameState.return_tallies, 82, Color("79473f"))
	right.add_child(tally_number)
	right.add_child(UI.divider(UI.border, 1))
	right.add_child(UI.label("Endings found: %d / 6" % GameState.endings_found(), 13, UI.ink_dim))
	for eid in StoryData.ENDINGS.keys():
		var entry_data: Dictionary = StoryData.ENDINGS[eid]
		var found := GameState.has_ending(int(eid))
		var c := UI.ink_dim if found else UI.ink_faint
		var t := str(entry_data.get("title", "")) if found else "UNKNOWN LOOP"
		right.add_child(UI.mono(("0%d  " % int(eid)) + t, 11, c))
	row.add_child(right)
	wake.grab_focus()
	_ending_root.visible = true
	_ending_root.move_to_front()
	_animate_ending(left, right, title, line, glow)
	_schedule_ending_climax()


func _animate_ending(left: Control, right: Control, title: Control, line: ColorRect, glow: TextureRect) -> void:
	_ending_root.modulate.a = 0.0
	left.modulate.a = 0.0
	right.modulate.a = 0.0
	title.modulate.a = 0.0
	title.scale = Vector2(0.96, 0.96)
	line.scale = Vector2(0.0, 1.0)
	await get_tree().process_frame
	if not is_instance_valid(title) or not is_instance_valid(line):
		return
	title.pivot_offset = title.size * 0.5
	line.pivot_offset = Vector2(0, line.size.y * 0.5)
	var intro := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	intro.set_parallel(true)
	intro.tween_property(_ending_root, "modulate:a", 1.0, 0.32)
	intro.tween_property(title, "modulate:a", 1.0, 0.24).set_delay(0.08)
	intro.tween_property(title, "scale", Vector2.ONE, 0.58).set_delay(0.08).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	intro.tween_property(line, "scale", Vector2.ONE, 0.5).set_delay(0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	intro.tween_property(left, "modulate:a", 1.0, 0.5).set_delay(0.22)
	intro.tween_property(right, "modulate:a", 1.0, 0.5).set_delay(0.48)
	glow.modulate.a = 0.55
	var glow_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_loops()
	glow_tween.tween_property(glow, "modulate:a", 0.95, 1.1)
	glow_tween.tween_property(glow, "modulate:a", 0.4, 1.5)
	var ghost := TextureRect.new()
	ghost.texture = load("res://assets/textures/ghost.png")
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ghost.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.modulate = Color(0.82, 0.92, 0.88, 0.0)
	_ending_root.add_child(ghost)
	_ending_root.move_child(ghost, 2)
	var ghost_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	ghost_tween.tween_property(ghost, "modulate:a", 0.26, 0.42)
	ghost_tween.tween_property(ghost, "modulate:a", 0.0, 1.8)
	ghost_tween.tween_callback(ghost.queue_free)
	var flash := ColorRect.new()
	flash.color = Color(0.42, 0.025, 0.015, 1.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.modulate.a = 0.0
	_ending_root.add_child(flash)
	var flash_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_loops()
	flash_tween.tween_interval(0.7)
	flash_tween.tween_property(flash, "modulate:a", 0.18, 0.035)
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.16)
	flash_tween.tween_interval(1.4)
	flash_tween.tween_property(flash, "modulate:a", 0.1, 0.03)
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.85
	noise.fractal_octaves = 2
	noise.seed = randi()
	var noise_tex := NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.width = 256
	noise_tex.height = 144
	noise_tex.seamless = true
	var grain := TextureRect.new()
	grain.texture = noise_tex
	grain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grain.stretch_mode = TextureRect.STRETCH_TILE
	grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grain.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_ending_root.add_child(grain)
	var grain_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_loops()
	grain_tween.tween_property(grain, "modulate:a", 0.07, 0.14)
	grain_tween.tween_property(grain, "modulate:a", 0.025, 0.28)


func _schedule_ending_climax() -> void:
	var delay := ENDING_VIDEO_START
	var position := AudioManager.get_ambience_position()
	if position > 0.01:
		delay = maxf(0.15, ENDING_VIDEO_START - position)
	get_tree().create_timer(delay, true).timeout.connect(_play_ending_climax)


func _play_ending_climax() -> void:
	if _ending_video_layer != null or not ending_open:
		return
	var stream := load(ENDING_VIDEO_PATH) as VideoStream
	if stream == null:
		_finish_ending_climax()
		return
	_ending_video_closed = false
	_ending_video_layer = CanvasLayer.new()
	_ending_video_layer.layer = 80
	_ending_video_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ending_video_layer)
	var black := ColorRect.new()
	black.color = Color(0.0, 0.0, 0.0, 1.0)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_STOP
	black.focus_mode = Control.FOCUS_ALL
	_ending_video_layer.add_child(black)
	black.grab_focus()
	var frame := AspectRatioContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.ratio = 444.0 / 694.0
	frame.stretch_mode = AspectRatioContainer.STRETCH_FIT
	_ending_video_layer.add_child(frame)
	_ending_video_player = VideoStreamPlayer.new()
	_ending_video_player.stream = stream
	_ending_video_player.expand = true
	_ending_video_player.volume_db = 12.0
	_ending_video_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_ending_video_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ending_video_player.finished.connect(_on_ending_climax_finished)
	frame.add_child(_ending_video_player)
	_ending_video_player.play()
	get_tree().create_timer(ENDING_VIDEO_FALLBACK, true).timeout.connect(_on_ending_climax_timeout)


func _on_ending_climax_finished() -> void:
	_finish_ending_climax()


func _on_ending_climax_timeout() -> void:
	if not _ending_video_closed:
		_finish_ending_climax()


func _finish_ending_climax() -> void:
	if _ending_video_closed:
		return
	_ending_video_closed = true
	if is_instance_valid(_ending_video_player):
		_ending_video_player.stop()
	AudioManager.stop_ambience(0.15)
	get_tree().paused = false
	menu_requested.emit()


func can_accept_world_input() -> bool:
	return not (modal_open or pause_open or ending_open or settings_open)


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or ending_open:
		return
	if settings_open:
		if event.is_action_pressed("pause"):
			_close_settings()
			get_viewport().set_input_as_handled()
		return
	if modal_open:
		if _modal_kind == "keypad" and event is InputEventKey and event.pressed and not event.echo:
			var key := (event as InputEventKey).keycode
			if key >= KEY_0 and key <= KEY_9:
				_keypad_push(str(key - KEY_0))
				get_viewport().set_input_as_handled()
				return
			if key == KEY_BACKSPACE:
				_keypad_set(_keypad_entry.substr(0, maxi(0, _keypad_entry.length() - 1)))
				get_viewport().set_input_as_handled()
				return
			if key == KEY_ENTER or key == KEY_KP_ENTER:
				_keypad_submit()
				get_viewport().set_input_as_handled()
				return
		if _modal_kind == "intro":
			if event.is_action_pressed("pause") or event.is_action_pressed("interact"):
				_close_intro()
				get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("pause") or event.is_action_pressed("interact") or (_modal_kind == "journal" and event.is_action_pressed("journal")):
			close_modal()
			get_viewport().set_input_as_handled()
		return
	if pause_open:
		if event.is_action_pressed("pause"):
			resume_game()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("journal"):
		show_journal()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		open_pause()
		get_viewport().set_input_as_handled()
