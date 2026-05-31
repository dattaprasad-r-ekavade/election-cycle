extends Node

signal settings_changed()

const SETTINGS_PATH := "user://settings.json"

var data: Dictionary = {
	"font_scale": 1.0,
	"text_speed": 1.0,
	"colorblind_mode": "off",
	"tutorial_enabled": true,
	"opening_seen": false,
	"seen_tips": {},
}


func _ready() -> void:
	_load_settings()


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		_save_settings()
		return

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		return

	var loaded: Dictionary = json.data
	for key in data.keys():
		if loaded.has(key):
			data[key] = loaded[key]


func _save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func set_value(key: String, value: Variant) -> void:
	data[key] = value
	_save_settings()
	settings_changed.emit()


func get_value(key: String, default_value: Variant = null) -> Variant:
	return data.get(key, default_value)


func apply_font_scale(root: Node) -> void:
	if root == null:
		return
	if root is Control:
		(root as Control).scale = Vector2.ONE * float(data.get("font_scale", 1.0))


func get_seen_tips() -> Dictionary:
	return data.get("seen_tips", {})


func set_tip_seen(tip_id: String) -> void:
	var seen: Dictionary = get_seen_tips()
	seen[tip_id] = true
	data["seen_tips"] = seen
	_save_settings()


func is_tip_seen(tip_id: String) -> bool:
	var seen: Dictionary = get_seen_tips()
	return bool(seen.get(tip_id, false))
