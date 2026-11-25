extends Node

var ink: Color
var ink_dim: Color
var ink_faint: Color
var bg: Color
var bg_soft: Color
var panel: Color
var border: Color
var accent: Color
var accent_dim: Color
var moss: Color
var paper: Color
var paper_ink: Color

var font_ui: SystemFont
var font_bold: SystemFont
var font_mono: SystemFont
var font_serif: SystemFont
var theme: Theme


func _ready() -> void:
	ink = Color("d8d5c6")
	ink_dim = Color("8d9082")
	ink_faint = Color("575d52")
	bg = Color("090b09")
	bg_soft = Color("0f130f")
	panel = Color("11140f")
	border = Color("3a4037")
	accent = Color("8e312b")
	accent_dim = Color("5f2723")
	moss = Color("6d7b6a")
	paper = Color("c7c4b1")
	paper_ink = Color("25271f")
	font_ui = _system_font(["Bahnschrift", "Segoe UI", "Arial"], 400)
	font_bold = _system_font(["Bahnschrift", "Segoe UI", "Arial"], 700)
	font_mono = _system_font(["Consolas", "Courier New", "Lucida Console"], 400)
	font_serif = _system_font(["Georgia", "Cambria", "Times New Roman"], 400)
	theme = Theme.new()
	theme.default_font = font_ui
	theme.default_font_size = 17


func _system_font(names: Array, weight: int) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(names)
	f.font_weight = weight
	f.allow_system_fallback = true
	return f


func label(text_value: String, size: int = 18, color: Color = Color.WHITE,
		font: Font = null, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		wrap: bool = false) -> Label:
	var node := Label.new()
	node.text = text_value
	node.add_theme_font_override("font", font if font != null else font_ui)
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.horizontal_alignment = alignment
	if wrap:
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node


func rich_label(text_value: String, size: int = 17, color: Color = Color.WHITE,
		font: Font = null) -> RichTextLabel:
	var node := RichTextLabel.new()
	node.bbcode_enabled = true
	node.text = text_value
	node.fit_content = true
	node.scroll_active = false
	node.add_theme_font_override("normal_font", font if font != null else font_ui)
	node.add_theme_font_size_override("normal_font_size", size)
	node.add_theme_color_override("default_color", color)
	node.add_theme_constant_override("line_separation", 6)
	return node


func stylebox(fill: Color, border_color: Color = Color.TRANSPARENT,
		width: int = 1, margin: int = 0, radius: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border_color
	style.set_border_width_all(width)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func button(text_value: String, width: float = 340.0, height: float = 48.0,
		font_size: int = 17, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		accent_bar: bool = true) -> Button:
	var node := Button.new()
	node.text = text_value
	node.custom_minimum_size = Vector2(width, height)
	node.focus_mode = Control.FOCUS_ALL
	node.alignment = alignment
	node.add_theme_font_override("font", font_ui)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", ink)
	node.add_theme_color_override("font_hover_color", Color("f0ecda"))
	node.add_theme_color_override("font_focus_color", Color("f0ecda"))
	node.add_theme_color_override("font_pressed_color", ink_dim)
	node.add_theme_color_override("font_disabled_color", ink_faint)
	var normal := stylebox(Color(0.035, 0.045, 0.038, 0.92), border, 1, 0)
	normal.border_width_left = 3 if accent_bar else 1
	normal.border_color = accent if accent_bar else border
	normal.content_margin_left = 22
	normal.content_margin_right = 18
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.075, 0.087, 0.073, 0.97)
	hover.border_color = ink_dim if not accent_bar else accent
	hover.border_width_left = 5 if accent_bar else 1
	var focus := hover.duplicate() as StyleBoxFlat
	focus.bg_color = Color(0.06, 0.07, 0.06, 0.96)
	focus.border_color = Color("a39d85")
	focus.border_width_left = 5
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.018, 0.024, 0.019, 1.0)
	node.add_theme_stylebox_override("normal", normal)
	node.add_theme_stylebox_override("hover", hover)
	node.add_theme_stylebox_override("focus", focus)
	node.add_theme_stylebox_override("pressed", pressed)
	node.add_theme_stylebox_override("disabled", normal)
	node.mouse_entered.connect(func() -> void: AudioManager.play_ui_hover())
	node.focus_entered.connect(func() -> void: AudioManager.play_ui_hover())
	node.pressed.connect(func() -> void: AudioManager.play_ui_click())
	return node


func small_button(text_value: String, width: float = 180.0) -> Button:
	return button(text_value, width, 36.0, 14, HORIZONTAL_ALIGNMENT_CENTER, false)


func panel_panel(fill: Color = Color.TRANSPARENT, border_color: Color = Color.TRANSPARENT,
		width: int = 1, margin: int = 26) -> PanelContainer:
	var node := PanelContainer.new()
	node.add_theme_stylebox_override("panel", stylebox(fill, border_color, width, margin))
	return node


func heading(text_value: String, size: int = 28, color: Color = Color.WHITE) -> Label:
	var node := label(text_value, size, color, font_bold)
	node.add_theme_constant_override("outline_size", 0)
	return node


func mono(text_value: String, size: int = 14, color: Color = Color.WHITE) -> Label:
	return label(text_value, size, color, font_mono)


func divider(color: Color = Color.WHITE, height: float = 1.0) -> ColorRect:
	var line := ColorRect.new()
	line.color = color
	line.custom_minimum_size = Vector2(0, height)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


func spacer(height: float) -> Control:
	var node := Control.new()
	node.custom_minimum_size = Vector2(0, height)
	return node


func overlay(fill: Color = Color(0.01, 0.012, 0.01, 0.84)) -> ColorRect:
	var node := ColorRect.new()
	node.color = fill
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return node


func full_rect(control: Control) -> Control:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return control


func add_film_overlay(host: Node) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 5
	layer.name = "FilmOverlay"
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader_path := "res://assets/shaders/film_grain.gdshader"
	if ResourceLoader.exists(shader_path):
		var material := ShaderMaterial.new()
		material.shader = load(shader_path)
		rect.material = material
	layer.add_child(rect)
	host.add_child(layer)
	return layer


func make_glitch_overlay(host: Node) -> ColorRect:
	var layer := CanvasLayer.new()
	layer.layer = 190
	layer.name = "GlitchOverlay"
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader_path := "res://assets/shaders/glitch.gdshader"
	if ResourceLoader.exists(shader_path):
		var material := ShaderMaterial.new()
		material.shader = load(shader_path)
		material.set_shader_parameter("intensity", 0.0)
		rect.material = material
	rect.visible = false
	layer.add_child(rect)
	host.add_child(layer)
	return rect


func set_glitch(rect: ColorRect, amount: float, distortion: float = 0.0, tint: float = 0.0) -> void:
	if rect == null or rect.material == null:
		return
	var mat := rect.material as ShaderMaterial
	mat.set_shader_parameter("intensity", amount)
	mat.set_shader_parameter("distortion", distortion)
	mat.set_shader_parameter("tint", tint)


func image_button_texture(path: String, max_width: float = 420.0) -> TextureRect:
	var texture := load(path) as Texture2D
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(max_width, max_width * 0.287)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect
