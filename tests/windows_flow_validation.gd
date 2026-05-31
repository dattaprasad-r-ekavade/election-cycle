extends SceneTree

const AUTOLOADS := [
	{"name": "GameManager", "path": "res://systems/game_manager.gd"},
	{"name": "SkillSystem", "path": "res://systems/skill_system.gd"},
	{"name": "PerkSystem", "path": "res://systems/perk_system.gd"},
	{"name": "SettingsSystem", "path": "res://systems/settings_system.gd"},
	{"name": "TutorialSystem", "path": "res://systems/tutorial_system.gd"},
	{"name": "CampaignSystem", "path": "res://systems/campaign_system.gd"},
	{"name": "SaveSystem", "path": "res://systems/save_system.gd"},
]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[FlowValidation] Starting Windows flow validation")
	await process_frame
	_ensure_autoloads()
	await process_frame
	await process_frame

	await _validate_campaign_to_opening_scene()
	await _validate_opening_skip_to_character_creation()
	await _validate_character_creation_to_town()

	if failures.is_empty():
		print("[FlowValidation] PASS: all scene flow checks succeeded")
		quit(0)
		return

	print("[FlowValidation] FAIL: %d checks failed" % failures.size())
	for failure in failures:
		print("[FlowValidation]   - %s" % failure)
	quit(1)


func _ensure_autoloads() -> void:
	for item in AUTOLOADS:
		var name := String(item["name"])
		if root.has_node(name):
			continue
		var script := load(String(item["path"]))
		if script == null:
			failures.append("Could not load autoload script: %s" % String(item["path"]))
			continue
		var node: Node = script.new()
		node.name = name
		root.add_child(node)


func _autoload(name: String) -> Node:
	if not root.has_node(name):
		return null
	return root.get_node(name)


func _first_unlocked_scenario_id() -> String:
	var campaign := _autoload("CampaignSystem")
	if campaign == null:
		return ""
	var unlocked: Array = campaign.call("get_unlocked_scenarios")
	if unlocked.is_empty():
		return ""
	return String(unlocked[0].get("id", ""))


func _change_and_wait(path: String) -> bool:
	var err := change_scene_to_file(path)
	if err != OK:
		failures.append("change_scene_to_file failed for %s: %s" % [path, err])
		return false
	await process_frame
	await process_frame
	return true


func _current_scene_path() -> String:
	if current_scene == null:
		return ""
	return String(current_scene.scene_file_path)


func _validate_campaign_to_opening_scene() -> void:
	var settings := _autoload("SettingsSystem")
	var campaign := _autoload("CampaignSystem")
	if settings == null or campaign == null:
		failures.append("Missing SettingsSystem or CampaignSystem autoload")
		return

	settings.call("set_value", "opening_seen", false)
	var scenario_id := _first_unlocked_scenario_id()
	if scenario_id == "":
		failures.append("No unlocked campaign scenario found")
		return

	if not bool(campaign.call("start_campaign_scenario", scenario_id)):
		failures.append("CampaignSystem.start_campaign_scenario failed")
		return

	if not await _change_and_wait("res://scenes/opening_scene.tscn"):
		return

	var scene_path := _current_scene_path()
	if not scene_path.ends_with("opening_scene.tscn"):
		failures.append("Expected opening scene, got %s" % scene_path)
		return

	var opening := current_scene
	var esc := InputEventKey.new()
	esc.pressed = true
	esc.keycode = KEY_ESCAPE
	opening._unhandled_input(esc)
	await process_frame

	var after_esc := _current_scene_path()
	if not after_esc.ends_with("opening_scene.tscn"):
		failures.append("Opening scene skipped on first viewing, expected no skip")
	else:
		print("[FlowValidation] PASS: opening scene shown for first campaign start")


func _validate_opening_skip_to_character_creation() -> void:
	var settings := _autoload("SettingsSystem")
	var campaign := _autoload("CampaignSystem")
	if settings == null or campaign == null:
		failures.append("Missing SettingsSystem or CampaignSystem autoload for skip test")
		return

	settings.call("set_value", "opening_seen", true)
	var scenario_id := _first_unlocked_scenario_id()
	if scenario_id == "":
		failures.append("No unlocked campaign scenario found for skip test")
		return

	if not bool(campaign.call("start_campaign_scenario", scenario_id)):
		failures.append("CampaignSystem.start_campaign_scenario failed for skip test")
		return

	if not await _change_and_wait("res://scenes/opening_scene.tscn"):
		return

	if current_scene == null or not _current_scene_path().ends_with("opening_scene.tscn"):
		failures.append("Skip test did not enter opening scene")
		return

	var opening := current_scene
	var esc := InputEventKey.new()
	esc.pressed = true
	esc.keycode = KEY_ESCAPE
	opening._unhandled_input(esc)
	await process_frame
	await process_frame

	var scene_path := _current_scene_path()
	if not scene_path.ends_with("character_creation.tscn"):
		failures.append("Esc skip did not reach character creation; got %s" % scene_path)
	else:
		print("[FlowValidation] PASS: opening scene skip reaches character creation")


func _validate_character_creation_to_town() -> void:
	if not _current_scene_path().ends_with("character_creation.tscn"):
		if not await _change_and_wait("res://scenes/character_creation.tscn"):
			return

	if current_scene == null:
		failures.append("Character creation scene missing")
		return

	var character_creation := current_scene
	if not character_creation.has_method("_on_start_pressed"):
		failures.append("Character creation scene missing _on_start_pressed")
		return

	character_creation._on_start_pressed()
	await process_frame
	await process_frame

	var scene_path := _current_scene_path()
	if not scene_path.ends_with("town.tscn"):
		failures.append("Start from character creation did not reach town; got %s" % scene_path)
	else:
		print("[FlowValidation] PASS: character creation advances to town")
