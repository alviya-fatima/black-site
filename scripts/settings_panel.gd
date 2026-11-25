extends PanelContainer

signal closed

var _value_labels: Dictionary = {}
var _fullscreen_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	custom_minimum_size = Vector2(560, 0)
	add_theme_stylebox_override("panel", UI.stylebox(Color(0.055, 0.065, 0.055, 0.99), UI.border, 1, 34))
	_build()
	SaveManager.settings_changed.connect(_on_setting_changed)


func _build() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 15)
	add_child(box)
	box.add_child(UI.mono("BLACK SITE / CONFIG", 12, UI.accent))
	box.add_child(UI.heading("Settings", 32, UI.ink))
	box.add_child(UI.label("Adjust the signal. Changes are saved immediately.", 14, UI.ink_dim))
	box.add_child(UI.divider(UI.border, 1))
	box.add_child(UI.spacer(4))
	for key in ["master", "music", "sfx"]:
		_add_volume_row(box, key)
	_add_fullscreen_row(box)
	box.add_child(UI.spacer(6))
	box.add_child(UI.divider(UI.border, 1))
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	footer.alignment = BoxContainer.ALIGNMENT_END
	var back := UI.button("BACK", 170, 42, 15, HORIZONTAL_ALIGNMENT_CENTER, false)
	back.pressed.connect(func() -> void: closed.emit())
	footer.add_child(back)
	box.add_child(footer)


func _add_volume_row(parent: VBoxContainer, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var label_text := key.to_upper()
	var name_label := UI.label(label_text, 15, UI.ink)
	name_label.custom_minimum_size = Vector2(150, 0)
	var value_label := UI.mono(_percent(key), 15, UI.ink_dim)
	value_label.custom_minimum_size = Vector2(64, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_value_labels[key] = value_label
	var minus := UI.button("-", 42, 36, 20, HORIZONTAL_ALIGNMENT_CENTER, false)
	var plus := UI.button("+", 42, 36, 20, HORIZONTAL_ALIGNMENT_CENTER, false)
	minus.pressed.connect(func() -> void: _adjust(key, -0.1))
	plus.pressed.connect(func() -> void: _adjust(key, 0.1))
	row.add_child(name_label)
	row.add_child(minus)
	row.add_child(value_label)
	row.add_child(plus)
	row.add_child(UI.label("", 1, UI.ink_dim))
	parent.add_child(row)
	var hint := UI.label("Master" if key == "master" else ("Ambience / score" if key == "music" else "Doors, steps and voices"), 12, UI.ink_faint)
	hint.position.x = 0
	parent.add_child(hint)


func _add_fullscreen_row(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var name_label := UI.label("DISPLAY", 15, UI.ink)
	name_label.custom_minimum_size = Vector2(150, 0)
	_fullscreen_button = UI.button("", 170, 36, 13, HORIZONTAL_ALIGNMENT_CENTER, false)
	_refresh_fullscreen()
	_fullscreen_button.pressed.connect(func() -> void:
		SaveManager.set_setting("fullscreen", not bool(SaveManager.settings.get("fullscreen", false)))
	)
	row.add_child(name_label)
	row.add_child(_fullscreen_button)
	parent.add_child(row)
	parent.add_child(UI.label("A wider view of a smaller room.", 12, UI.ink_faint))


func _adjust(key: String, amount: float) -> void:
	var current := float(SaveManager.settings.get(key, 0.8))
	SaveManager.set_setting(key, clampf(snappedf(current + amount, 0.01), 0.0, 1.0))
	AudioManager.play_ui_hover()


func _percent(key: String) -> String:
	return "%d%%" % int(round(float(SaveManager.settings.get(key, 0.0)) * 100.0))


func _refresh_fullscreen() -> void:
	if _fullscreen_button == null:
		return
	_fullscreen_button.text = "FULLSCREEN" if bool(SaveManager.settings.get("fullscreen", false)) else "WINDOWED"


func _on_setting_changed(key: String, _value: Variant) -> void:
	if key in ["master", "music", "sfx"]:
		var label: Label = _value_labels.get(key, null)
		if label != null:
			label.text = _percent(key)
	elif key == "fullscreen":
		_refresh_fullscreen()
