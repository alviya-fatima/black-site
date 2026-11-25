extends Node

const SOUND_NAMES: Array[String] = [
	"amb_asylum", "amb_basement", "amb_outside",
	"step_1", "step_2", "step_3",
	"door_open", "door_close", "door_slam", "door_locked",
	"keypad_beep", "keypad_error", "keypad_ok",
	"ui_hover", "ui_click", "interact", "pickup", "unlock", "page",
	"light_buzz", "elevator", "glitch", "transition", "ending_tone",
	"heartbeat", "signal_lost", "intercom", "last_light", "loss_theme",
	"main_theme", "loss_music"
]

var sounds: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _ambience_player: AudioStreamPlayer
var _ambience_name: String = ""
var _ambience_volume: float = -9.0
var _ambience_looping: bool = false
var _ambience_generation: int = 0
var _cut: bool = false
var _headless: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_headless = DisplayServer.get_name() == "headless"
	_ensure_buses()
	_load_sounds()
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = "Music"
	_ambience_player.volume_db = -40.0
	add_child(_ambience_player)
	_ambience_player.finished.connect(_on_ambience_finished)
	for i in range(14):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	SaveManager.apply_audio_settings()


func _exit_tree() -> void:
	_cut = true
	_ambience_looping = false
	if _ambience_player != null:
		_ambience_player.stop()
		_ambience_player.stream = null
	for player in _sfx_players:
		player.stop()
		player.stream = null
	_sfx_players.clear()
	sounds.clear()


func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		var index := AudioServer.get_bus_index(bus_name)
		if index == -1:
			AudioServer.add_bus()
			index = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")
		if bus_name == "Music" and AudioServer.get_bus_effect_count(index) == 0:
			var reverb := AudioEffectReverb.new()
			reverb.room_size = 0.62
			reverb.damping = 0.65
			reverb.wet = 0.16
			reverb.dry = 1.0
			AudioServer.add_bus_effect(index, reverb)
		elif bus_name == "SFX" and AudioServer.get_bus_effect_count(index) == 0:
			var reverb2 := AudioEffectReverb.new()
			reverb2.room_size = 0.44
			reverb2.damping = 0.7
			reverb2.wet = 0.075
			reverb2.dry = 1.0
			AudioServer.add_bus_effect(index, reverb2)


func _load_sounds() -> void:
	for sound_name in SOUND_NAMES:
		var stream := _load_audio_stream(sound_name)
		if stream == null:
			push_warning("Missing sound: " + sound_name)
			continue
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
		sounds[sound_name] = stream


func _load_audio_stream(sound_name: String) -> AudioStream:
	for extension in [".mp3", ".ogg", ".wav"]:
		var path := "res://assets/audio/%s%s" % [sound_name, extension]
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null


func play_sfx(sound_name: String, volume_db: float = 0.0, pitch_variation: float = 0.04) -> void:
	if _cut or _headless:
		return
	var stream: AudioStream = sounds.get(sound_name, null)
	if stream == null:
		return
	var player := _available_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()


func _available_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	var fallback := _sfx_players[_sfx_cursor % _sfx_players.size()]
	_sfx_cursor += 1
	fallback.stop()
	return fallback


func play_step(running: bool = false) -> void:
	var names := ["step_1", "step_2", "step_3"]
	var sound: String = names[randi() % names.size()]
	play_sfx(sound, -13.0 if not running else -8.0, 0.09)


func play_ui_hover() -> void:
	play_sfx("ui_hover", -17.0, 0.02)


func play_ui_click() -> void:
	play_sfx("ui_click", -11.0, 0.02)


func play_ambience(sound_name: String, volume_db: float = -9.0, fade: float = 1.8) -> void:
	if _headless or not sounds.has(sound_name):
		return
	if _ambience_name == sound_name and _ambience_player.playing:
		if not is_equal_approx(_ambience_volume, volume_db):
			_ambience_volume = volume_db
			var volume_tween := create_tween()
			volume_tween.tween_property(_ambience_player, "volume_db", volume_db, 0.8)
		return
	_cut = false
	_ambience_generation += 1
	var generation := _ambience_generation
	_ambience_looping = false
	var target := sounds[sound_name] as AudioStream
	if _ambience_player.playing:
		var out_tween := create_tween()
		out_tween.tween_property(_ambience_player, "volume_db", -42.0, maxf(0.2, fade * 0.55))
		await out_tween.finished
		if generation != _ambience_generation:
			return
		_ambience_player.stop()
	_ambience_name = sound_name
	_ambience_volume = volume_db
	_ambience_player.stream = target
	_ambience_player.volume_db = -42.0
	_ambience_player.play()
	_ambience_looping = true
	var in_tween := create_tween()
	in_tween.tween_property(_ambience_player, "volume_db", _ambience_volume, fade)


func stop_ambience(fade: float = 1.0) -> void:
	_ambience_generation += 1
	_ambience_looping = false
	_ambience_name = ""
	if _ambience_player == null or not _ambience_player.playing:
		return
	var tween := create_tween()
	tween.tween_property(_ambience_player, "volume_db", -46.0, fade)
	await tween.finished
	_ambience_player.stop()


func _on_ambience_finished() -> void:
	if _ambience_looping and not _ambience_name.is_empty():
		_ambience_player.play()


func get_ambience_position() -> float:
	if _ambience_player == null or _ambience_player.stream == null:
		return 0.0
	if not _ambience_player.playing:
		return 0.0
	return _ambience_player.get_playback_position()


func fade_ambience_to(volume_db: float, duration: float = 1.0) -> void:
	if _ambience_player == null:
		return
	var tween := create_tween()
	tween.tween_property(_ambience_player, "volume_db", volume_db, duration)


func cut_audio() -> void:
	_cut = true
	_ambience_generation += 1
	_ambience_looping = false
	if _ambience_player:
		_ambience_player.stop()
	for p in _sfx_players:
		p.stop()


func restore_audio() -> void:
	_cut = false


func play_loss_theme(ending_id: int) -> void:
	var volume_db := -8.0
	match ending_id:
		1:
			volume_db = -9.0
		2:
			volume_db = -8.0
		3:
			volume_db = -9.0
		4:
			volume_db = -7.0
		5:
			volume_db = -8.0
		_:
			volume_db = -10.0
	_cut = false
	play_ambience("loss_music", volume_db, 0.8)


func play_ending_sting(ending_id: int) -> void:
	match ending_id:
		1:
			play_sfx("ending_tone", -9.0, 0.0)
		2:
			play_sfx("door_slam", -7.0, 0.02)
			play_sfx("signal_lost", -13.0, 0.0)
		3:
			play_sfx("elevator", -9.0, 0.0)
		4:
			play_sfx("heartbeat", -10.0, 0.0)
		5:
			play_sfx("intercom", -10.0, 0.0)
			play_sfx("signal_lost", -12.0, 0.0)
		_:
			play_sfx("last_light", -11.0, 0.0)
