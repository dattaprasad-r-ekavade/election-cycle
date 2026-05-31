extends Node

signal campaign_progress_changed()

const CAMPAIGN_FILE := "res://content/campaign_mode.json"
const PROGRESS_FILE := "user://campaign_progress.json"

var scenarios: Array = []
var progress: Dictionary = {
	"completed": [],
}

var active_scenario_id: String = ""


func _ready() -> void:
	_load_scenarios()
	_load_progress()
	GameManager.game_ended.connect(_on_game_ended)


func _load_scenarios() -> void:
	scenarios.clear()
	if not FileAccess.file_exists(CAMPAIGN_FILE):
		return
	var file := FileAccess.open(CAMPAIGN_FILE, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		return
	scenarios = json.data.get("scenarios", [])


func _load_progress() -> void:
	if not FileAccess.file_exists(PROGRESS_FILE):
		_save_progress()
		return
	var file := FileAccess.open(PROGRESS_FILE, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		return
	progress = json.data
	if not progress.has("completed"):
		progress["completed"] = []


func _save_progress() -> void:
	var file := FileAccess.open(PROGRESS_FILE, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(progress, "\t"))
	file.close()


func get_completed_count() -> int:
	return int((progress.get("completed", []) as Array).size())


func get_unlocked_scenarios() -> Array:
	var completed_count := get_completed_count()
	var unlocked: Array = []
	for scenario in scenarios:
		var idx := int(scenario.get("index", 0))
		if idx <= 3:
			unlocked.append(scenario)
		elif idx <= 6 and completed_count >= 2:
			unlocked.append(scenario)
		elif idx <= 9 and completed_count >= 5:
			unlocked.append(scenario)
		elif idx == 10 and completed_count >= 9:
			unlocked.append(scenario)
	return unlocked


func get_scenario(scenario_id: String) -> Dictionary:
	for scenario in scenarios:
		if String(scenario.get("id", "")) == scenario_id:
			return scenario
	return {}


func start_campaign_scenario(scenario_id: String) -> bool:
	var scenario := get_scenario(scenario_id)
	if scenario.is_empty():
		return false

	active_scenario_id = scenario_id
	GameManager.play_mode = "campaign"
	GameManager.campaign_scenario_id = scenario_id
	GameManager.start_new_game(int(scenario.get("seed", 1)))
	GameManager.apply_campaign_profile(scenario)
	return true


func clear_active_scenario() -> void:
	active_scenario_id = ""
	GameManager.play_mode = "quick"
	GameManager.campaign_scenario_id = ""


func _on_game_ended(_won: bool, _results: Dictionary) -> void:
	if active_scenario_id == "":
		return
	var completed: Array = progress.get("completed", [])
	if not completed.has(active_scenario_id):
		completed.append(active_scenario_id)
		progress["completed"] = completed
		_save_progress()
		campaign_progress_changed.emit()
