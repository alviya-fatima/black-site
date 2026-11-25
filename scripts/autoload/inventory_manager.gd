extends Node

signal item_added(item_id: String)
signal item_removed(item_id: String)
signal inventory_changed

var items: Array[String] = []


func reset() -> void:
	items.clear()
	inventory_changed.emit()


func load_items(saved: Array) -> void:
	items.clear()
	for raw in saved:
		var id := str(raw)
		if StoryData.ITEMS.has(id) and not items.has(id):
			items.append(id)
	inventory_changed.emit()


func serialize() -> Array:
	return items.duplicate()


func has_item(item_id: String) -> bool:
	return items.has(item_id)


func add_item(item_id: String) -> bool:
	if not StoryData.ITEMS.has(item_id):
		push_warning("Unknown item: " + item_id)
		return false
	if items.has(item_id):
		return false
	items.append(item_id)
	item_added.emit(item_id)
	inventory_changed.emit()
	return true


func remove_item(item_id: String) -> bool:
	var index := items.find(item_id)
	if index == -1:
		return false
	items.remove_at(index)
	item_removed.emit(item_id)
	inventory_changed.emit()
	return true


func fuse_count() -> int:
	var count := 0
	for fuse in StoryData.FUSE_IDS:
		if has_item(fuse):
			count += 1
	return count


func has_all_fuses() -> bool:
	return fuse_count() >= 3


func get_display_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in items:
		var data: Dictionary = StoryData.ITEMS.get(item_id, {})
		if not data.is_empty():
			result.append({"id": item_id, "data": data})
	return result
