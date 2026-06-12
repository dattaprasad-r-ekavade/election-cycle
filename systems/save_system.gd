extends Node

signal slot_saved(slot: int)
signal slot_loaded(slot: int)

const SAVE_DIR := "user://saves"

var active_slot: int = 1


func _ready() -> void:
	_ensure_save_dir()
	GameManager.day_changed.connect(_on_day_changed)


func _on_day_changed(_day: int) -> void:
	save_to_slot(active_slot, true)


func _ensure_save_dir() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func set_active_slot(slot: int) -> void:
	active_slot = clampi(slot, 1, 3)


func get_slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, clampi(slot, 1, 3)]


func save_to_slot(slot: int, is_autosave: bool = false) -> bool:
	slot = clampi(slot, 1, 3)
	active_slot = slot
	_ensure_save_dir()

	var payload := {
		"version": 1,
		"saved_at": Time.get_datetime_string_from_system(),
		"is_autosave": is_autosave,
		"slot": slot,
		"game_manager": GameManager.export_state(),
		"skill_system": SkillSystem.export_state(),
		"perk_system": PerkSystem.export_state(),
		"content_loader": ContentLoader.export_state(),
		"dialogue_system": DialogueSystem.export_state(),
	}

	var file := FileAccess.open(get_slot_path(slot), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	slot_saved.emit(slot)
	return true


func load_from_slot(slot: int) -> bool:
	slot = clampi(slot, 1, 3)
	var path := get_slot_path(slot)
	if not FileAccess.file_exists(path):
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		return false

	var data: Dictionary = json.data
	GameManager.import_state(data.get("game_manager", {}))
	SkillSystem.import_state(data.get("skill_system", {}))
	PerkSystem.import_state(data.get("perk_system", {}))
	if data.has("content_loader"):
		ContentLoader.import_state(data.get("content_loader", {}))
	if data.has("dialogue_system"):
		DialogueSystem.import_state(data.get("dialogue_system", {}))

	active_slot = slot
	slot_loaded.emit(slot)

	# Route to scene based on loaded day. Days 2-7 all live in the town now.
	if GameManager.current_day <= 1:
		get_tree().change_scene_to_file("res://scenes/character_creation.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/town.tscn")
	return true


func get_slot_metadata(slot: int) -> Dictionary:
	var path := get_slot_path(slot)
	if not FileAccess.file_exists(path):
		return {"exists": false, "label": "Empty"}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"exists": false, "label": "Unreadable"}

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {"exists": false, "label": "Corrupt"}

	var data: Dictionary = json.data
	var gm: Dictionary = data.get("game_manager", {})
	return {
		"exists": true,
		"day": int(gm.get("current_day", 1)),
		"player_name": String(gm.get("player_name", "Candidate")),
		"district": String(gm.get("district_name", "Unknown")),
		"saved_at": String(data.get("saved_at", "unknown")),
		"label": "Day %d - %s (%s)" % [int(gm.get("current_day", 1)), String(gm.get("player_name", "Candidate")), String(data.get("saved_at", ""))]
	}


func get_all_slot_metadata() -> Array:
	var out: Array = []
	for i in range(1, 4):
		out.append(get_slot_metadata(i))
	return out
