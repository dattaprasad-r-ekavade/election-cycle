extends Control

## Dice Roll Popup - Dramatic skill check UI
## Shows modifiers, probability, animated roll, and result

signal roll_accepted(result: Dictionary)
signal roll_declined()

@onready var panel: PanelContainer = $CenterContainer/Panel
@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBox/TitleLabel
@onready var description_label: Label = $CenterContainer/Panel/MarginContainer/VBox/DescriptionLabel
@onready var skill_info: Label = $CenterContainer/Panel/MarginContainer/VBox/SkillInfo
@onready var modifiers_container: VBoxContainer = $CenterContainer/Panel/MarginContainer/VBox/ModifiersContainer
@onready var probability_bar: ProgressBar = $CenterContainer/Panel/MarginContainer/VBox/ProbabilityContainer/ProbabilityBar
@onready var probability_label: Label = $CenterContainer/Panel/MarginContainer/VBox/ProbabilityContainer/ProbabilityLabel
@onready var advantage_label: Label = $CenterContainer/Panel/MarginContainer/VBox/AdvantageLabel
@onready var voice_label: RichTextLabel = $CenterContainer/Panel/MarginContainer/VBox/VoiceLabel
@onready var roll_button: Button = $CenterContainer/Panel/MarginContainer/VBox/ButtonsContainer/RollButton
@onready var back_button: Button = $CenterContainer/Panel/MarginContainer/VBox/ButtonsContainer/BackButton
@onready var result_container: VBoxContainer = $CenterContainer/Panel/MarginContainer/VBox/ResultContainer
@onready var dice_label: Label = $CenterContainer/Panel/MarginContainer/VBox/ResultContainer/DiceLabel
@onready var breakdown_label: Label = $CenterContainer/Panel/MarginContainer/VBox/ResultContainer/BreakdownLabel
@onready var result_label: Label = $CenterContainer/Panel/MarginContainer/VBox/ResultContainer/ResultLabel
@onready var result_voice_label: RichTextLabel = $CenterContainer/Panel/MarginContainer/VBox/ResultContainer/ResultVoiceLabel
@onready var continue_button: Button = $CenterContainer/Panel/MarginContainer/VBox/ResultContainer/ContinueButton

var current_check_data: Dictionary = {}
var current_result: Dictionary = {}
var is_rolling := false


func _ready() -> void:
	visible = false
	result_container.visible = false
	roll_button.pressed.connect(_on_roll_pressed)
	back_button.pressed.connect(_on_back_pressed)
	continue_button.pressed.connect(_on_continue_pressed)


func show_check(skill_name: String, difficulty: int, description: String, context: Dictionary = {}) -> void:
	"""Show the dice roll popup for a skill check."""
	# Calculate everything without rolling yet
	var skill_value := SkillSystem.get_skill(skill_name)
	var modifiers := DiceRollSystem.calculate_modifiers(skill_name, context)
	var total_modifier := 0
	for mod in modifiers:
		total_modifier += mod.amount
	
	var has_advantage := DiceRollSystem.check_advantage(skill_name, context)
	var has_disadvantage := DiceRollSystem.check_disadvantage(skill_name, context)
	
	if has_advantage and has_disadvantage:
		has_advantage = false
		has_disadvantage = false
	
	var probability := DiceRollSystem.calculate_probability(skill_value, difficulty, total_modifier, has_advantage, has_disadvantage)
	
	current_check_data = {
		"skill_name": skill_name,
		"skill_display": SkillSystem.get_skill_display_name(skill_name),
		"skill_value": skill_value,
		"difficulty": difficulty,
		"modifiers": modifiers,
		"total_modifier": total_modifier,
		"has_advantage": has_advantage,
		"has_disadvantage": has_disadvantage,
		"probability": probability,
		"description": description,
		"context": context,
		"pre_voice": DiceRollSystem.SKILL_VOICES.get(skill_name, {}).get("pre", "Make your move.")
	}
	
	_populate_ui()
	result_container.visible = false
	roll_button.visible = true
	back_button.visible = true
	visible = true


func _populate_ui() -> void:
	"""Populate the UI with check data."""
	# Title
	title_label.text = "⚔️ %s CHECK ⚔️" % current_check_data.skill_display.to_upper()
	
	# Description
	description_label.text = current_check_data.description
	
	# Skill info
	skill_info.text = "Base %s: %d | Difficulty: %d (%s)" % [
		current_check_data.skill_display,
		current_check_data.skill_value,
		current_check_data.difficulty,
		DiceRollSystem.get_difficulty_name(current_check_data.difficulty)
	]
	
	# Modifiers
	for child in modifiers_container.get_children():
		child.queue_free()
	
	var mods: Array = current_check_data.modifiers
	if mods.is_empty():
		var no_mods := Label.new()
		no_mods.text = "► No modifiers"
		no_mods.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		modifiers_container.add_child(no_mods)
	else:
		for mod in mods:
			var mod_label := Label.new()
			var color := Color(0.3, 0.8, 0.3) if mod.amount > 0 else Color(0.8, 0.3, 0.3)
			mod_label.text = "► %s: %+d" % [mod.source, mod.amount]
			mod_label.add_theme_color_override("font_color", color)
			modifiers_container.add_child(mod_label)
	
	# Probability
	var prob_percent := current_check_data.probability * 100
	probability_bar.value = prob_percent
	probability_label.text = "%.0f%% CHANCE" % prob_percent
	
	# Color the probability bar
	var bar_style := probability_bar.get_theme_stylebox("fill")
	if bar_style is StyleBoxFlat:
		if prob_percent >= 70:
			bar_style.bg_color = Color(0.2, 0.7, 0.2)
		elif prob_percent >= 40:
			bar_style.bg_color = Color(0.7, 0.7, 0.2)
		else:
			bar_style.bg_color = Color(0.7, 0.2, 0.2)
	
	# Advantage/Disadvantage
	if current_check_data.has_advantage:
		advantage_label.text = "✦ ADVANTAGE (Roll 2d10, take higher)"
		advantage_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
		advantage_label.visible = true
	elif current_check_data.has_disadvantage:
		advantage_label.text = "✧ DISADVANTAGE (Roll 2d10, take lower)"
		advantage_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
		advantage_label.visible = true
	else:
		advantage_label.visible = false
	
	# Voice text
	voice_label.text = "[i]%s[/i]" % current_check_data.pre_voice


func _on_roll_pressed() -> void:
	"""Perform the actual roll."""
	if is_rolling:
		return
	
	is_rolling = true
	roll_button.disabled = true
	back_button.disabled = true
	
	# Animate the roll
	await _animate_roll()
	
	# Perform the actual check
	current_result = DiceRollSystem.perform_check(
		current_check_data.skill_name,
		current_check_data.difficulty,
		current_check_data.context
	)
	
	# Show result
	_show_result()
	is_rolling = false


func _animate_roll() -> void:
	"""Animate dice rolling."""
	result_container.visible = true
	roll_button.visible = false
	back_button.visible = false
	
	# Quick number cycling animation
	var has_two_dice: bool = current_check_data.has_advantage or current_check_data.has_disadvantage
	
	for i in range(15):
		if has_two_dice:
			dice_label.text = "🎲 %d  🎲 %d" % [randi_range(1, 10), randi_range(1, 10)]
		else:
			dice_label.text = "🎲 %d" % randi_range(1, 10)
		await get_tree().create_timer(0.05 + (i * 0.01)).timeout
	
	# Slow down at the end
	for i in range(5):
		if has_two_dice:
			dice_label.text = "🎲 %d  🎲 %d" % [randi_range(1, 10), randi_range(1, 10)]
		else:
			dice_label.text = "🎲 %d" % randi_range(1, 10)
		await get_tree().create_timer(0.1 + (i * 0.05)).timeout


func _show_result() -> void:
	"""Display the roll result."""
	var has_two_dice: bool = current_result.roll_values.size() > 1
	
	# Show final dice values
	if has_two_dice:
		var d1: int = current_result.roll_values[0]
		var d2: int = current_result.roll_values[1]
		var used := current_result.final_roll
		if d1 == used:
			dice_label.text = "🎲 [%d]  🎲 %d" % [d1, d2]
		else:
			dice_label.text = "🎲 %d  🎲 [%d]" % [d1, d2]
	else:
		dice_label.text = "🎲 %d" % current_result.final_roll
	
	# Show breakdown
	var mod_text := ""
	if current_result.total_modifier != 0:
		mod_text = " %+d (modifiers)" % current_result.total_modifier
	
	breakdown_label.text = "%d (roll) + %d (%s)%s = %d vs %d" % [
		current_result.final_roll,
		current_result.skill_value,
		current_result.skill_display,
		mod_text,
		current_result.total,
		current_result.difficulty
	]
	
	# Show result
	if current_result.is_crit_success:
		result_label.text = "★ CRITICAL SUCCESS ★"
		result_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	elif current_result.is_crit_failure:
		result_label.text = "✖ CRITICAL FAILURE ✖"
		result_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	elif current_result.success:
		result_label.text = "✓ SUCCESS"
		result_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	else:
		result_label.text = "✗ FAILURE"
		result_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	
	# Voice text
	result_voice_label.text = "[i]\"%s\"[/i]" % current_result.flavor_text
	
	continue_button.visible = true


func _on_back_pressed() -> void:
	"""Player chose not to roll."""
	visible = false
	roll_declined.emit()


func _on_continue_pressed() -> void:
	"""Player acknowledges result."""
	visible = false
	roll_accepted.emit(current_result)
