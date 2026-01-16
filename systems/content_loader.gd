extends Node

## Content Loader - Loads all game content from scenario_maker.json
## This allows easy modding and content creation

signal content_loaded()
signal content_error(message: String)

const CONTENT_PATH := "res://content/scenario_maker.json"
const VALID_PLACEHOLDERS := ["player_name", "opponent_name", "district_name", "crisis"]

var npcs: Dictionary = {}
var scenarios: Dictionary = {}  # keyed by day type: "canvassing", "posters", etc
var crises: Dictionary = {}
var opponents: Dictionary = {}
var news_templates: Dictionary = {}
var is_loaded := false
var run_history: Dictionary = {}  # day_type -> {used_ids: Array, last_seen: Dictionary}


func _ready() -> void:
	print("[ContentLoader] Initializing...")
	load_content()


func load_content() -> bool:
	"""Load all content from the JSON file"""
	if not FileAccess.file_exists(CONTENT_PATH):
		push_error("[ContentLoader] Content file not found: %s" % CONTENT_PATH)
		content_error.emit("Content file not found")
		return false

	var file := FileAccess.open(CONTENT_PATH, FileAccess.READ)
	if not file:
		push_error("[ContentLoader] Could not open content file")
		content_error.emit("Could not open content file")
		return false

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("[ContentLoader] JSON parse error: %s" % json.get_error_message())
		content_error.emit("JSON parse error: %s" % json.get_error_message())
		return false

	var data: Dictionary = json.data
	_normalize_content(data)

	if not _validate_content(data):
		content_error.emit("Content validation failed")
		return false

	# Load NPCs
	if data.has("npcs"):
		npcs = data.npcs
		print("[ContentLoader] Loaded %d NPCs" % npcs.size())

	# Load Scenarios
	if data.has("scenarios"):
		scenarios = data.scenarios
		print("[ContentLoader] Loaded scenarios for %d day types" % scenarios.size())

	# Load Crises
	if data.has("crises"):
		crises = data.crises
		print("[ContentLoader] Loaded %d crises" % crises.size())

	# Load Opponents
	if data.has("opponents"):
		opponents = data.opponents
		print("[ContentLoader] Loaded %d opponents" % opponents.size())

	# Load News Templates
	if data.has("news_templates"):
		news_templates = data.news_templates
		print("[ContentLoader] Loaded news templates")

	is_loaded = true
	content_loaded.emit()
	print("[ContentLoader] All content loaded successfully")
	return true


func reset_run_state() -> void:
	"""Reset per-run scenario history"""
	run_history.clear()


func get_random_scenario(day_type: String, day: int = 0) -> Dictionary:
	"""Get a random scenario for a specific day type"""
	if not scenarios.has(day_type):
		push_warning("[ContentLoader] No scenarios for day type: %s" % day_type)
		return {}

	var day_scenarios: Array = scenarios[day_type]
	if day_scenarios.is_empty():
		return {}

	var filtered := _filter_scenarios(day_type, day_scenarios, day)
	if filtered.is_empty():
		push_warning("[ContentLoader] No available scenarios after filtering for %s" % day_type)
		filtered = day_scenarios

	# Weight-based selection
	var total_weight := 0.0
	for scenario in filtered:
		total_weight += scenario.get("weight", 1.0)

	var roll := randf() * total_weight
	var current := 0.0

	for scenario in filtered:
		current += scenario.get("weight", 1.0)
		if roll <= current:
			_record_scenario_pick(day_type, scenario.get("id", ""), day)
			return _process_scenario(scenario)

	_record_scenario_pick(day_type, filtered[0].get("id", ""), day)
	return _process_scenario(filtered[0])


func _process_scenario(scenario: Dictionary) -> Dictionary:
	"""Process a scenario, replacing placeholders with actual values"""
	var processed := scenario.duplicate(true)

	# Replace placeholders in intro text
	if processed.has("intro_text"):
		processed.intro_text = _replace_placeholders(processed.intro_text)

	if processed.has("moderator_question"):
		processed.moderator_question = _replace_placeholders(processed.moderator_question)

	if processed.has("opponent_attack"):
		processed.opponent_attack = _replace_placeholders(processed.opponent_attack)

	# Replace placeholders in choices
	if processed.has("choices"):
		for i in range(processed.choices.size()):
			if processed.choices[i].has("text"):
				processed.choices[i].text = _replace_placeholders(processed.choices[i].text)

	return processed


func _filter_scenarios(day_type: String, scenarios_list: Array, day: int) -> Array:
	var filtered: Array = []
	var history: Dictionary = run_history.get(day_type, {"used_ids": [], "last_seen": {}})
	var used_ids: Array = history.used_ids
	var last_seen: Dictionary = history.last_seen

	for scenario in scenarios_list:
		if day > 0 and scenario.has("day") and int(scenario.day) != day:
			continue

		var scenario_id: String = scenario.get("id", "")
		if scenario.get("unique_per_run", false) and used_ids.has(scenario_id):
			continue

		if scenario.has("cooldown_days") and day > 0:
			var last_day := int(last_seen.get(scenario_id, -1000))
			var cooldown := int(scenario.get("cooldown_days", 0))
			if day - last_day <= cooldown:
				continue

		filtered.append(scenario)

	return filtered


func _record_scenario_pick(day_type: String, scenario_id: String, day: int) -> void:
	if scenario_id == "":
		return
	if not run_history.has(day_type):
		run_history[day_type] = {"used_ids": [], "last_seen": {}}

	var history: Dictionary = run_history[day_type]
	if not history.used_ids.has(scenario_id):
		history.used_ids.append(scenario_id)
	history.last_seen[scenario_id] = day


func _replace_placeholders(text: String) -> String:
	"""Replace placeholder text with actual game values"""
	text = text.replace("{player_name}", GameManager.player_name)
	text = text.replace("{opponent_name}", GameManager.opponent_name)
	text = text.replace("{district_name}", GameManager.district_name)
	text = text.replace("{crisis}", GameManager.main_crisis)
	return text


func get_npc(npc_id: String) -> Dictionary:
	"""Get NPC data by ID"""
	return npcs.get(npc_id, {})


func get_random_crisis() -> Dictionary:
	"""Get a random crisis"""
	if crises.is_empty():
		return {}
	var crisis_keys := crises.keys()
	var key: String = crisis_keys[randi() % crisis_keys.size()]
	return crises[key]


func get_random_opponent() -> Dictionary:
	"""Get a random opponent"""
	if opponents.is_empty():
		return {}
	var opponent_keys := opponents.keys()
	var key: String = opponent_keys[randi() % opponent_keys.size()]
	return opponents[key]


func get_posters() -> Array:
	"""Get all poster options"""
	if scenarios.has("posters"):
		var processed: Array = []
		for poster in scenarios.posters:
			var p: Dictionary = poster.duplicate(true) as Dictionary
			if p.has("text"):
				p.text = _replace_placeholders(p.text)
			processed.append(p)
		return processed
	return []


func get_random_fundraiser() -> Dictionary:
	"""Get a random fundraiser scenario"""
	return get_random_scenario("fundraisers", GameManager.current_day)


func get_random_event() -> Dictionary:
	"""Get a random town event"""
	return get_random_scenario("events", GameManager.current_day)


func get_debate_round(round_number: int) -> Dictionary:
	"""Get a specific debate round"""
	if not scenarios.has("debate_rounds"):
		return {}

	for round_data in scenarios.debate_rounds:
		if round_data.get("round_number", 0) == round_number:
			var processed := _process_scenario(round_data)
			if processed.has("opponent_attack"):
				processed.opponent_attack = _append_debate_callouts(processed.opponent_attack)
			return processed

	return {}


func get_news_headline(headline_type: String) -> String:
	"""Get a random news headline of a specific type"""
	if not news_templates.has(headline_type):
		return ""

	var templates: Array = news_templates[headline_type]
	if templates.is_empty():
		return ""

	var template: String = templates[randi() % templates.size()]
	return _replace_placeholders(template)


func _append_debate_callouts(base_text: String) -> String:
	var callouts: Array = []
	var flag_lines := {
		"ate_evidence": "They literally ate evidence on camera.",
		"fled_mcpoyles": "They ran from the McPoyles. On video.",
		"owns_boat": "They bought a 'party boat' with campaign money.",
		"frank_partner": "They partnered with a man who says 'lawn-dering.'",
		"dennis_enemy": "They insulted a local 'golden god.'"
	}

	for flag_name in flag_lines.keys():
		if GameManager.get_run_flag(flag_name):
			callouts.append(flag_lines[flag_name])

	if callouts.is_empty():
		return base_text

	var extra := " " + " ".join(callouts.slice(0, 2))
	return base_text + extra


func _normalize_content(data: Dictionary) -> void:
	if not data.has("scenarios"):
		return

	var scenario_groups := ["canvassing", "posters", "fundraisers", "events", "debate_rounds"]
	for group in scenario_groups:
		if not data.scenarios.has(group):
			continue

		for i in range(data.scenarios[group].size()):
			var item: Dictionary = data.scenarios[group][i]
			_normalize_scenario_item(item, group)


func _normalize_scenario_item(item: Dictionary, group: String) -> void:
	if item.has("choices"):
		for c in range(item.choices.size()):
			var choice: Dictionary = item.choices[c]
			choice = _normalize_choice_effects(choice, group)
			item.choices[c] = choice

	# Normalize poster-style effects directly on item
	if item.has("effect"):
		item.effects = _convert_effects_dict_to_ops(item.effect, group)
		item.erase("effect")

	if not item.has("issue_tags"):
		item.issue_tags = []
	if not item.has("world_tags"):
		item.world_tags = []
	if not item.has("tone_tags"):
		item.tone_tags = []

	if not item.has("unique_per_run"):
		item.unique_per_run = false
	if not item.has("cooldown_days"):
		item.cooldown_days = 0


func _normalize_choice_effects(choice: Dictionary, group: String) -> Dictionary:
	if choice.has("effect"):
		choice.effects = _convert_effects_dict_to_ops(choice.effect, group)
		choice.erase("effect")

	if choice.has("success_effect"):
		choice.effects_on_success = _convert_effects_dict_to_ops(choice.success_effect, group)
		choice.erase("success_effect")

	if choice.has("failure_effect"):
		choice.effects_on_failure = _convert_effects_dict_to_ops(choice.failure_effect, group)
		choice.erase("failure_effect")

	if choice.has("effects") and choice.effects is Dictionary:
		choice.effects = _convert_effects_dict_to_ops(choice.effects, group)

	return choice


func _convert_effects_dict_to_ops(effects: Dictionary, group: String) -> Array:
	var ops: Array = []

	for key in effects.keys():
		match key:
			"trust":
				if group == "posters" or group == "events":
					ops.append({"op": "district_support_add", "amount": int(effects[key])})
				else:
					ops.append({"op": "trust_add", "amount": int(effects[key])})
			"endorsement":
				ops.append({"op": "endorsement_add", "name": str(effects[key])})
			"promise":
				var promise_text := str(effects[key])
				ops.append({
					"op": "promise_add",
					"id": _generate_promise_id(promise_text),
					"text": promise_text
				})
			"set_flag":
				ops.append({"op": "set_flag", "flag": str(effects[key])})
			"clear_flag":
				ops.append({"op": "clear_flag", "flag": str(effects[key])})
			"scandal":
				ops.append({"op": "scandal_add", "headline": str(effects[key])})
			"scandal_chance":
				ops.append({
					"op": "scandal_risk_add",
					"id": "scandal_risk",
					"chance": float(effects[key]),
					"headline": "Questionable Campaign Practices"
				})
			"scandal_potential":
				ops.append({
					"op": "scandal_risk_add",
					"id": str(effects[key]),
					"chance": 0.4,
					"headline": "Campaign Irregularities Under Investigation"
				})
			_:
				if SkillSystem.SKILL_NAMES.has(key):
					ops.append({"op": "stat_add", "stat": key, "amount": int(effects[key])})
				else:
					ops.append({"op": "unknown"})

	return ops


func _generate_promise_id(text: String) -> String:
	var normalized := text.to_lower().strip_edges()
	normalized = normalized.replace(" ", "_")
	normalized = normalized.replace("{", "")
	normalized = normalized.replace("}", "")
	return "promise_%s" % normalized


func _validate_content(data: Dictionary) -> bool:
	if not data.has("scenarios"):
		push_error("[ContentLoader] Missing scenarios block")
		return false

	if not _validate_npcs(data.get("npcs", {})):
		return false

	var scenario_groups := ["canvassing", "posters", "fundraisers", "events", "debate_rounds"]
	for group in scenario_groups:
		if not data.scenarios.has(group):
			continue
		if not _validate_scenario_group(group, data.scenarios[group], data.get("npcs", {})):
			return false

	return true


func _validate_npcs(npc_data: Dictionary) -> bool:
	for npc_id in npc_data.keys():
		if npc_data[npc_id].get("id", "") != npc_id:
			push_error("[ContentLoader] NPC id mismatch: %s" % npc_id)
			return false
	return true


func _validate_scenario_group(group: String, items: Array, npc_data: Dictionary) -> bool:
	var ids: Dictionary = {}
	for item in items:
		var item_id: String = item.get("id", "")
		if item_id == "":
			push_error("[ContentLoader] Missing scenario id in %s" % group)
			return false
		if ids.has(item_id):
			push_error("[ContentLoader] Duplicate id %s in %s" % [item_id, group])
			return false
		ids[item_id] = true

		if item.has("npc_id") and item.npc_id != "" and not npc_data.has(item.npc_id):
			push_error("[ContentLoader] Missing npc_id reference %s in %s" % [item.npc_id, group])
			return false

		if item.has("day"):
			var day := int(item.day)
			if day < 1 or day > 7:
				push_error("[ContentLoader] Invalid day %d in %s" % [day, item_id])
				return false

		if not _validate_placeholders(item.get("intro_text", "")):
			return false
		if not _validate_placeholders(item.get("moderator_question", "")):
			return false
		if not _validate_placeholders(item.get("opponent_attack", "")):
			return false

		if item.has("choices"):
			for choice in item.choices:
				if not _validate_choice(choice, item_id):
					return false
	return true


func _validate_choice(choice: Dictionary, context_id: String) -> bool:
	if not _validate_placeholders(choice.get("text", "")):
		return false

	if choice.has("requires"):
		for stat in choice.requires.keys():
			if not SkillSystem.SKILL_NAMES.has(stat):
				push_error("[ContentLoader] Invalid requires stat %s in %s" % [stat, context_id])
				return false

	if choice.has("skill_check"):
		var check: Dictionary = choice.skill_check
		var skill_name: String = check.get("skill", "")
		if not SkillSystem.SKILL_NAMES.has(skill_name):
			push_error("[ContentLoader] Invalid skill_check stat %s in %s" % [skill_name, context_id])
			return false
		var difficulty_value: Variant = check.get("difficulty", 0)
		if not (difficulty_value is int or difficulty_value is float):
			push_error("[ContentLoader] Invalid difficulty type in %s" % context_id)
			return false

	for effects_key in ["effects", "effects_on_success", "effects_on_failure"]:
		if choice.has(effects_key):
			if not _validate_effect_ops(choice[effects_key], context_id):
				return false

	return true


func _validate_effect_ops(effects: Array, context_id: String) -> bool:
	if not (effects is Array):
		push_error("[ContentLoader] Effects must be an array in %s" % context_id)
		return false
	var allowed_ops := ["stat_add", "trust_add", "district_support_add", "promise_add", "endorsement_add", "set_flag", "clear_flag", "scandal_add", "scandal_risk_add"]
	for effect in effects:
		var op: String = effect.get("op", "")
		if not allowed_ops.has(op):
			push_error("[ContentLoader] Unknown effect op %s in %s" % [op, context_id])
			return false
		match op:
			"stat_add":
				if not SkillSystem.SKILL_NAMES.has(effect.get("stat", "")):
					push_error("[ContentLoader] Invalid stat_add stat in %s" % context_id)
					return false
			"promise_add":
				if effect.get("id", "") == "" or effect.get("text", "") == "":
					push_error("[ContentLoader] promise_add missing id/text in %s" % context_id)
					return false
			"scandal_risk_add":
				if not (effect.get("chance", 0.0) is float or effect.get("chance", 0.0) is int):
					push_error("[ContentLoader] scandal_risk_add chance invalid in %s" % context_id)
					return false
	return true


func _validate_placeholders(text: String) -> bool:
	if text == "":
		return true
	var regex := RegEx.new()
	regex.compile("\\{([a-z_]+)\\}")
	var matches := regex.search_all(text)
	for match in matches:
		var token := match.get_string(1)
		if not VALID_PLACEHOLDERS.has(token):
			push_error("[ContentLoader] Invalid placeholder {%s}" % token)
			return false
	return true
