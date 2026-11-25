extends Node

signal saved
signal settings_changed(key: String, value: Variant)

const SAVE_PATH := "user://blacksite_save.json"
const SETTINGS_PATH := "user://blacksite_settings.cfg"
const SAVE_VERSION := 1

var has_save: bool = false
var last_loaded: Dictionary = {}
var settings: Dictionary = {
	"master": 0.82,
	"music": 0.62,
	"sfx": 0.82,
	"fullscreen": false,
}


func _ready() -> void:
	_load_settings()
	_apply_display_settings()
	_load_save()


func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		has_save = false
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not read BLACK SITE save.")
		has_save = false
		return
	var raw := file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw)
	if not parsed is Dictionary:
		push_warning("BLACK SITE save was corrupt; starting without save.")
		has_save = false
		return
	last_loaded = parsed as Dictionary
	if int(last_loaded.get("version", 0)) != SAVE_VERSION:
		push_warning("BLACK SITE save version mismatch.")
	GameState.load_from_dict(last_loaded)
	has_save = true


func save_current() -> void:
	if not GameState.run_active:
		return
	var data := GameState.to_save_dict()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write BLACK SITE save.")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	last_loaded = data
	has_save = true
	saved.emit()


func begin_new_run() -> void:
	GameState.reset_run(true)
	InventoryManager.reset()
	save_current()


func delete_save() -> void:
	GameState.clear_run()
	InventoryManager.reset()
	has_save = false
	last_loaded = {}
	if FileAccess.file_exists(SAVE_PATH):
		var absolute := ProjectSettings.globalize_path(SAVE_PATH)
		DirAccess.remove_absolute(absolute)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	settings["master"] = clampf(float(config.get_value("audio", "master", settings["master"])), 0.0, 1.0)
	settings["music"] = clampf(float(config.get_value("audio", "music", settings["music"])), 0.0, 1.0)
	settings["sfx"] = clampf(float(config.get_value("audio", "sfx", settings["sfx"])), 0.0, 1.0)
	settings["fullscreen"] = bool(config.get_value("video", "fullscreen", settings["fullscreen"]))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", settings["master"])
	config.set_value("audio", "music", settings["music"])
	config.set_value("audio", "sfx", settings["sfx"])
	config.set_value("video", "fullscreen", settings["fullscreen"])
	config.save(SETTINGS_PATH)


func set_setting(key: String, value: Variant) -> void:
	if not settings.has(key):
		return
	if key in ["master", "music", "sfx"]:
		value = clampf(float(value), 0.0, 1.0)
	elif key == "fullscreen":
		value = bool(value)
	settings[key] = value
	save_settings()
	if key in ["master", "music", "sfx"]:
		_apply_bus_volume(key)
	elif key == "fullscreen":
		_apply_display_settings()
	settings_changed.emit(key, value)


func apply_audio_settings() -> void:
	_apply_bus_volume("master")
	_apply_bus_volume("music")
	_apply_bus_volume("sfx")


func _apply_bus_volume(key: String) -> void:
	var bus_names := {"master": "Master", "music": "Music", "sfx": "SFX"}
	var bus_name: String = bus_names.get(key, "")
	if bus_name.is_empty():
		return
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	var linear := float(settings.get(key, 1.0))
	AudioServer.set_bus_mute(index, linear <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))


func _apply_display_settings() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if bool(settings.get("fullscreen", false)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
