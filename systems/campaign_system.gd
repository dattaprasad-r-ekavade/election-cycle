extends Node

## Campaign mode: "The Unlikely Mayor Tour".
## Ten scripted towns. Winning a town unlocks the next stop.

signal campaign_progress_changed()

const CAMPAIGN_FILE := "res://content/campaign_mode.json"
const PROGRESS_FILE := "user://campaign_progress.json"

var meta: Dictionary = {}
var scenarios: Array = []
var progress: Dictionary = {
	"completed": [],
	"won": [],
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
	meta = json.data.get("meta", {})
	scenarios.sort_custom(func(a, b): return int(a.get("index", 0)) < int(b.get("index", 0)))


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
	if not progress.has("won"):
		progress["won"] = []


func _save_progress() -> void:
	var file := FileAccess.open(PROGRESS_FILE, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(progress, "\t"))
	file.close()


func has_won(scenario_id: String) -> bool:
	return (progress.get("won", []) as Array).has(scenario_id)


func get_won_count() -> int:
	return (progress.get("won", []) as Array).size()


func is_unlocked(scenario: Dictionary) -> bool:
	var idx := int(scenario.get("index", 0))
	if idx <= 1:
		return true
	for s in scenarios:
		if int(s.get("index", 0)) == idx - 1:
			return has_won(String(s.get("id", "")))
	return false


func get_unlocked_scenarios() -> Array:
	var unlocked: Array = []
	for scenario in scenarios:
		if is_unlocked(scenario):
			unlocked.append(scenario)
	return unlocked


func get_scenario(scenario_id: String) -> Dictionary:
	for scenario in scenarios:
		if String(scenario.get("id", "")) == scenario_id:
			return scenario
	return {}


func get_active_scenario() -> Dictionary:
	return get_scenario(active_scenario_id)


func is_tour_complete() -> bool:
	for scenario in scenarios:
		if not has_won(String(scenario.get("id", ""))):
			return false
	return not scenarios.is_empty()


func start_campaign_scenario(scenario_id: String) -> bool:
	var scenario := get_scenario(scenario_id)
	if scenario.is_empty():
		return false
	if not is_unlocked(scenario):
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


func _on_game_ended(won: bool, _results: Dictionary) -> void:
	var scenario_id := active_scenario_id
	if scenario_id == "" and GameManager.play_mode == "campaign":
		scenario_id = GameManager.campaign_scenario_id
	if scenario_id == "":
		return

	var changed := false
	var completed: Array = progress.get("completed", [])
	if not completed.has(scenario_id):
		completed.append(scenario_id)
		progress["completed"] = completed
		changed = true

	if won:
		var won_list: Array = progress.get("won", [])
		if not won_list.has(scenario_id):
			won_list.append(scenario_id)
			progress["won"] = won_list
			changed = true

	if changed:
		_save_progress()
		campaign_progress_changed.emit()
