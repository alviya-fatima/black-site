extends Node

signal flag_changed(key: String, value: bool)
signal document_read(document_id: String)
signal ending_recorded(ending_id: int)
signal progress_changed

var flags: Dictionary = {}
var documents: Dictionary = {}
var endings: Dictionary = {}
var checkpoint: Vector3 = StoryData.START_POSITION
var checkpoint_zone: String = "INTAKE 03"
var last_ending: int = 0
var return_tallies: int = 0
var run_active: bool = false
var intro_seen: bool = false
var pending_final_ending: bool = false
var pending_ending_after_load: int = 0


func _ready() -> void:
	_setup_input()
	process_mode = Node.PROCESS_MODE_ALWAYS


func _setup_input() -> void:
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("run", [KEY_SHIFT])
	_add_key_action("interact", [KEY_E])
	_add_key_action("pause", [KEY_ESCAPE])
	_add_key_action("journal", [KEY_TAB])


func _add_key_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		event.keycode = keycode
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)


func reset_run(preserve_endings: bool = true) -> void:
	var kept_endings := endings.duplicate(true) if preserve_endings else {}
	flags.clear()
	documents.clear()
	endings = kept_endings
	checkpoint = StoryData.START_POSITION
	checkpoint_zone = "INTAKE 03"
	last_ending = 0
	return_tallies = 0
	run_active = true
	intro_seen = false
	pending_final_ending = false
	pending_ending_after_load = 0
	InventoryManager.reset()
	progress_changed.emit()


func clear_run() -> void:
	flags.clear()
	documents.clear()
	checkpoint = StoryData.START_POSITION
	checkpoint_zone = "INTAKE 03"
	last_ending = 0
	return_tallies = 0
	run_active = false
	intro_seen = false
	pending_final_ending = false
	pending_ending_after_load = 0


func restart_loop() -> void:
	var kept_documents := documents.duplicate(true)
	var kept_endings := endings.duplicate(true)
	var kept_tallies := return_tallies
	flags.clear()
	documents = kept_documents
	endings = kept_endings
	checkpoint = StoryData.START_POSITION
	checkpoint_zone = "INTAKE 03"
	last_ending = 0
	return_tallies = kept_tallies
	run_active = true
	intro_seen = true
	pending_final_ending = false
	pending_ending_after_load = 0
	InventoryManager.reset()
	progress_changed.emit()


func set_flag(key: String, value: bool = true) -> void:
	if bool(flags.get(key, false)) == value:
		return
	flags[key] = value
	flag_changed.emit(key, value)
	progress_changed.emit()


func has_flag(key: String) -> bool:
	return bool(flags.get(key, false))


func read_document(document_id: String) -> void:
	if not StoryData.DOCS.has(document_id):
		return
	if not documents.has(document_id):
		documents[document_id] = true
		document_read.emit(document_id)
		progress_changed.emit()


func has_read_document(document_id: String) -> bool:
	return bool(documents.get(document_id, false))


func record_ending(ending_id: int) -> void:
	endings[str(ending_id)] = true
	last_ending = ending_id
	return_tallies += 1
	ending_recorded.emit(ending_id)
	progress_changed.emit()


func has_ending(ending_id: int) -> bool:
	return bool(endings.get(str(ending_id), false))


func endings_found() -> int:
	var count := 0
	for key in StoryData.ENDINGS.keys():
		if has_ending(int(key)):
			count += 1
	return count


func set_checkpoint(position: Vector3, zone_name: String) -> void:
	checkpoint = position
	checkpoint_zone = zone_name


func to_save_dict() -> Dictionary:
	return {
		"version": 1,
		"flags": flags.duplicate(true),
		"documents": documents.duplicate(true),
		"endings": endings.duplicate(true),
		"inventory": InventoryManager.serialize(),
		"checkpoint": [checkpoint.x, checkpoint.y, checkpoint.z],
		"zone": checkpoint_zone,
		"last_ending": last_ending,
		"return_tallies": return_tallies,
		"run_active": run_active,
		"intro_seen": intro_seen,
	}


func load_from_dict(data: Dictionary) -> void:
	flags = data.get("flags", {}).duplicate(true)
	documents = data.get("documents", {}).duplicate(true)
	var saved_endings: Dictionary = data.get("endings", {}).duplicate(true)
	endings.clear()
	for k in saved_endings.keys():
		endings[str(k)] = bool(saved_endings[k])
	var cp = data.get("checkpoint", null)
	if cp is Array and cp.size() >= 3:
		checkpoint = Vector3(float(cp[0]), float(cp[1]), float(cp[2]))
	else:
		checkpoint = StoryData.START_POSITION
	checkpoint_zone = str(data.get("zone", "INTAKE 03"))
	last_ending = int(data.get("last_ending", 0))
	return_tallies = int(data.get("return_tallies", 0))
	run_active = bool(data.get("run_active", true))
	intro_seen = bool(data.get("intro_seen", false))
	InventoryManager.load_items(data.get("inventory", []))
	progress_changed.emit()
