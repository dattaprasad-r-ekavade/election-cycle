extends Node

## Dialogue System - Handles conversations with NPCs
## Loads dialogue from JSON, processes choices, applies effects

signal dialogue_started(npc_id: String)
signal dialogue_line(speaker: String, text: String)
signal choices_presented(choices: Array)
signal choice_made(choice_index: int)
signal dialogue_ended()

var current_dialogue: Dictionary = {}
var current_node_id: String = ""
var current_npc_id: String = ""
var dialogue_data: Dictionary = {}  # Loaded dialogue files
var flags: Dictionary = {}  # Global dialogue flags


func _ready() -> void:
	print("[DialogueSystem] Initialized")
	_load_all_dialogues()


func _load_all_dialogues() -> void:
	"""Load all dialogue JSON files from content folder"""
	var dir := DirAccess.open("res://content/dialogues")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var dialogue_id := file_name.get_basename()
				_load_dialogue_file("res://content/dialogues/" + file_name, dialogue_id)
			file_name = dir.get_next()
	else:
		print("[DialogueSystem] No dialogues folder found, will create sample")


func _load_dialogue_file(path: String, dialogue_id: String) -> void:
	"""Load a single dialogue JSON file"""
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		var json := JSON.new()
		var error := json.parse(file.get_as_text())
		if error == OK:
			var normalized := _normalize_dialogue(json.data)
			if _validate_dialogue(normalized, dialogue_id):
				dialogue_data[dialogue_id] = normalized
			else:
				push_error("Dialogue validation failed: %s" % path)
			print("[DialogueSystem] Loaded dialogue: %s" % dialogue_id)
		else:
			push_error("Failed to parse dialogue: %s" % path)


func start_dialogue(npc_id: String, dialogue_id: String = "") -> bool:
	"""Start a dialogue with an NPC"""
	if dialogue_id.is_empty():
		dialogue_id = npc_id

	if not dialogue_data.has(dialogue_id):
		print("[DialogueSystem] Dialogue not found: %s" % dialogue_id)
		return false

	current_npc_id = npc_id
	current_dialogue = dialogue_data[dialogue_id]
	current_node_id = current_dialogue.get("start", "start")

	dialogue_started.emit(npc_id)
	_process_current_node()
	return true


func start_dialogue_from_data(npc_id: String, data: Dictionary) -> void:
	"""Start a dialogue from directly provided data"""
	current_npc_id = npc_id
	current_dialogue = data
	current_node_id = data.get("start", "start")

	dialogue_started.emit(npc_id)
	_process_current_node()


func _process_current_node() -> void:
	"""Process the current dialogue node"""
	if not current_dialogue.has("nodes"):
		dialogue_ended.emit()
		return

	var nodes: Dictionary = current_dialogue.nodes
	if not nodes.has(current_node_id):
		dialogue_ended.emit()
		return

	var node: Dictionary = nodes[current_node_id]

	# Show dialogue line
	var speaker: String = node.get("speaker", current_dialogue.get("npc_name", "NPC"))
	var text: String = node.get("text", "")

	# Process text replacements
	text = _process_text(text)

	dialogue_line.emit(speaker, text)

	if node.has("effects"):
		_apply_effects(node.effects)

	# Check for choices
	if node.has("choices") and node.choices.size() > 0:
		var available_choices := _filter_choices(node.choices)
		choices_presented.emit(available_choices)
	elif node.has("next"):
		# Auto-advance after a delay or player input
		current_node_id = node.next
	else:
		# End of dialogue
		dialogue_ended.emit()


func _filter_choices(choices: Array) -> Array:
	"""Filter choices based on skill requirements and conditions"""
	var available := []
	for choice in choices:
		var choice_data: Dictionary = choice
		var can_show := true

		# Check skill requirements
		if choice_data.has("requires"):
			var req: Dictionary = choice_data.requires
			for skill_name in req:
				if not SkillSystem.check_skill(skill_name, req[skill_name]):
					can_show = false
					break

		# Check flag requirements
		if choice_data.has("requires_flag"):
			if not flags.get(choice_data.requires_flag, false):
				can_show = false

		if can_show:
			available.append(choice_data)

	return available


func _process_text(text: String) -> String:
	"""Process text replacements"""
	text = text.replace("{player_name}", GameManager.player_name)
	text = text.replace("{opponent_name}", GameManager.opponent_name)
	text = text.replace("{district_name}", GameManager.district_name)
	text = text.replace("{crisis}", GameManager.main_crisis)
	return text


func select_choice(choice_index: int, choices: Array) -> void:
	"""Handle player selecting a choice"""
	if choice_index < 0 or choice_index >= choices.size():
		return

	var choice: Dictionary = choices[choice_index]
	choice_made.emit(choice_index)

	# Apply effects
	if choice.has("effects"):
		_apply_effects(choice.effects)

	# Handle skill checks
	if choice.has("skill_check"):
		var check_data: Dictionary = choice.skill_check
		var skill_name: String = check_data.get("skill", "speechcraft")
		var difficulty: int = check_data.get("difficulty", 10)
		var result := SkillSystem.roll_skill_check(skill_name, difficulty)

		if result.success and choice.has("effects_on_success"):
			_apply_effects(choice.effects_on_success)

		if not result.success and choice.has("effects_on_failure"):
			_apply_effects(choice.effects_on_failure)

		if result.success and choice.has("success_next"):
			current_node_id = choice.success_next
		elif not result.success and choice.has("failure_next"):
			current_node_id = choice.failure_next
		elif choice.has("next"):
			current_node_id = choice.next
		else:
			dialogue_ended.emit()
			return
	elif choice.has("next"):
		current_node_id = choice.next
	else:
		dialogue_ended.emit()
		return

	_process_current_node()


func advance_dialogue() -> void:
	"""Advance to next node (for non-choice nodes)"""
	var nodes: Dictionary = current_dialogue.get("nodes", {})
	if not nodes.has(current_node_id):
		dialogue_ended.emit()
		return

	var node: Dictionary = nodes[current_node_id]
	if node.has("next"):
		current_node_id = node.next
		_process_current_node()
	else:
		dialogue_ended.emit()


func _apply_effects(effects: Array) -> void:
	"""Apply effects from a dialogue choice"""
	if effects is Array:
		GameManager.apply_effects(effects, {"npc_id": current_npc_id, "dialogue_flags": true})


func set_flag(flag_name: String, value: bool = true) -> void:
	"""Set a dialogue flag"""
	flags[flag_name] = value


func get_flag(flag_name: String) -> bool:
	"""Get a dialogue flag value"""
	return flags.get(flag_name, false)


func clear_flags() -> void:
	"""Clear all dialogue flags"""
	flags.clear()


func _normalize_dialogue(data: Dictionary) -> Dictionary:
	if not data.has("nodes"):
		return data
	for node_id in data.nodes.keys():
		var node: Dictionary = data.nodes[node_id]
		if node.has("effects") and node.effects is Dictionary:
			node.effects = _convert_effects_dict_to_ops(node.effects)
		if node.has("choices"):
			for i in range(node.choices.size()):
				node.choices[i] = _normalize_choice(node.choices[i])
	return data


func _normalize_choice(choice: Dictionary) -> Dictionary:
	if choice.has("effect"):
		choice.effects = _convert_effects_dict_to_ops(choice.effect)
		choice.erase("effect")

	if choice.has("effects") and choice.effects is Dictionary:
		choice.effects = _convert_effects_dict_to_ops(choice.effects)

	if choice.has("success_effect"):
		choice.effects_on_success = _convert_effects_dict_to_ops(choice.success_effect)
		choice.erase("success_effect")

	if choice.has("failure_effect"):
		choice.effects_on_failure = _convert_effects_dict_to_ops(choice.failure_effect)
		choice.erase("failure_effect")

	return choice


func _convert_effects_dict_to_ops(effects: Dictionary) -> Array:
	var ops: Array = []
	for key in effects.keys():
		match key:
			"trust":
				ops.append({"op": "trust_add", "amount": int(effects[key])})
			"endorsement":
				ops.append({"op": "endorsement_add", "name": str(effects[key])})
			"promise":
				ops.append({
					"op": "promise_add",
					"id": "promise_%s" % str(effects[key]).to_lower().replace(" ", "_"),
					"text": str(effects[key])
				})
			"set_flag":
				ops.append({"op": "set_flag", "flag": str(effects[key])})
			"clear_flag":
				ops.append({"op": "clear_flag", "flag": str(effects[key])})
			"scandal":
				ops.append({"op": "scandal_add", "headline": str(effects[key])})
			_:
				if SkillSystem.SKILL_NAMES.has(key):
					ops.append({"op": "stat_add", "stat": key, "amount": int(effects[key])})
				else:
					ops.append({"op": "unknown"})
	return ops


func _validate_dialogue(data: Dictionary, dialogue_id: String) -> bool:
	if not data.has("nodes"):
		push_error("[DialogueSystem] Missing nodes in %s" % dialogue_id)
		return false

	for node_id in data.nodes.keys():
		var node: Dictionary = data.nodes[node_id]
		if node.has("effects"):
			if not _validate_effect_ops(node.effects, dialogue_id, node_id):
				return false
		if node.has("choices"):
			for choice in node.choices:
				if not _validate_choice(choice, dialogue_id, node_id):
					return false
	return true


func _validate_choice(choice: Dictionary, dialogue_id: String, node_id: String) -> bool:
	if choice.has("requires"):
		for stat in choice.requires.keys():
			if not SkillSystem.SKILL_NAMES.has(stat):
				push_error("[DialogueSystem] Invalid requires stat %s in %s/%s" % [stat, dialogue_id, node_id])
				return false

	if choice.has("skill_check"):
		var check: Dictionary = choice.skill_check
		if not SkillSystem.SKILL_NAMES.has(check.get("skill", "")):
			push_error("[DialogueSystem] Invalid skill_check stat in %s/%s" % [dialogue_id, node_id])
			return false
		var difficulty_value: Variant = check.get("difficulty", 0)
		if not (difficulty_value is int or difficulty_value is float):
			push_error("[DialogueSystem] Invalid difficulty type in %s/%s" % [dialogue_id, node_id])
			return false

	for effects_key in ["effects", "effects_on_success", "effects_on_failure"]:
		if choice.has(effects_key):
			if not _validate_effect_ops(choice[effects_key], dialogue_id, node_id):
				return false

	return true


func _validate_effect_ops(effects: Array, dialogue_id: String, node_id: String) -> bool:
	if not (effects is Array):
		push_error("[DialogueSystem] Effects must be an array in %s/%s" % [dialogue_id, node_id])
		return false
	var allowed_ops := ["stat_add", "trust_add", "promise_add", "endorsement_add", "set_flag", "clear_flag", "scandal_add"]
	for effect in effects:
		var op: String = effect.get("op", "")
		if not allowed_ops.has(op):
			push_error("[DialogueSystem] Unknown effect op %s in %s/%s" % [op, dialogue_id, node_id])
			return false
		if op == "stat_add" and not SkillSystem.SKILL_NAMES.has(effect.get("stat", "")):
			push_error("[DialogueSystem] Invalid stat_add in %s/%s" % [dialogue_id, node_id])
			return false
	return true
