extends CanvasLayer

var overlay: ColorRect
var _busy: bool = false


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay = ColorRect.new()
	overlay.color = Color(0.008, 0.01, 0.008, 1.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _make_tween() -> Tween:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	return tween


func fade_in(duration: float = 1.1) -> void:
	overlay.visible = true
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := _make_tween()
	tween.tween_property(overlay, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE)
	await tween.finished
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false


func fade_out(duration: float = 0.8, target: Color = Color(0.008, 0.01, 0.008, 1.0)) -> void:
	overlay.visible = true
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.color = Color(target.r, target.g, target.b, overlay.color.a)
	var tween := _make_tween()
	tween.tween_property(overlay, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE)
	await tween.finished


func flash(color: Color = Color(0.82, 0.82, 0.74, 0.85), duration: float = 0.8) -> void:
	overlay.visible = true
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = color
	var tween := _make_tween()
	tween.tween_property(overlay, "color:a", 0.0, duration).set_trans(Tween.TRANS_EXPO)
	await tween.finished
	overlay.visible = false


func change_scene(path: String, out_duration: float = 0.8, in_duration: float = 0.8) -> void:
	if _busy:
		return
	_busy = true
	get_tree().paused = false
	await fade_out(out_duration)
	var result := get_tree().change_scene_to_file(path)
	if result != OK:
		push_error("Scene change failed: " + path)
		_busy = false
		return
	await get_tree().process_frame
	await get_tree().process_frame
	await fade_in(in_duration)
	_busy = false


func set_black(black: bool) -> void:
	overlay.visible = black
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP if black else Control.MOUSE_FILTER_IGNORE
	overlay.color.a = 1.0 if black else 0.0
