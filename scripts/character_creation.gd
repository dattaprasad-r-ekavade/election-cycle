extends Control

## Character Creation / Day 1 Registration
## Player allocates SKILL points, sees district info, and can set seed

const SEED_MIN := 0
const SEED_MAX := 2147483647  # Max 32-bit signed int

@onready var name_input: LineEdit = $MarginContainer/VBox/ContentHBox/LeftPanel/LeftMargin/LeftVBox/NameInput
@onready var slogan_input: LineEdit = $MarginContainer/VBox/ContentHBox/LeftPanel/LeftMargin/LeftVBox/SloganInput
@onready var district_name_label: Label = $MarginContainer/VBox/ContentHBox/LeftPanel/LeftMargin/LeftVBox/DistrictInfo/DistrictMargin/DistrictVBox/DistrictName
@onready var crisis_label: Label = $MarginContainer/VBox/ContentHBox/LeftPanel/LeftMargin/LeftVBox/DistrictInfo/DistrictMargin/DistrictVBox/Crisis
@onready var opponent_label: Label = $MarginContainer/VBox/ContentHBox/LeftPanel/LeftMargin/LeftVBox/DistrictInfo/DistrictMargin/DistrictVBox/Opponent
@onready var opponent_type_label: Label = $MarginContainer/VBox/ContentHBox/LeftPanel/LeftMargin/LeftVBox/DistrictInfo/DistrictMargin/DistrictVBox/OpponentType
@onready var points_label: Label = $MarginContainer/VBox/ContentHBox/RightPanel/RightMargin/RightVBox/PointsRemaining
@onready var skills_container: VBoxContainer = $MarginContainer/VBox/ContentHBox/RightPanel/RightMargin/RightVBox/SkillsContainer

# Seed UI elements (will be created dynamically if not in scene)
var seed_label: Label
var seed_input: LineEdit
var seed_randomize_btn: Button
var seed_container: HBoxContainer

var skill_rows: Dictionary = {}


func _ready() -> void:
	# Generate a new game with random seed
	GameManager.start_new_game()

	# Give player 5 extra points to allocate
	SkillSystem.set_starting_allocation(5)

	# Create seed UI
	_create_seed_ui()
	_update_seed_display()

	_update_district_info()
	_create_skill_rows()
	_update_points_display()

	# Connect to skill system
	SkillSystem.points_changed.connect(_on_points_changed)
	SkillSystem.skill_changed.connect(_on_skill_changed)

	# Set default name
	name_input.text = "Candidate"
	GameManager.player_name = "Candidate"


func _create_seed_ui() -> void:
	"""Create seed input UI dynamically"""
	# Find where to insert seed UI - after slogan input, before district info
	var left_vbox: VBoxContainer = $MarginContainer/VBox/ContentHBox/LeftPanel/LeftMargin/LeftVBox
	
	# Create container
	seed_container = HBoxContainer.new()
	seed_container.name = "SeedContainer"
	
	# Seed label
	seed_label = Label.new()
	seed_label.text = "► SEED: "
	seed_label.add_theme_font_size_override("font_size", 12)
	seed_container.add_child(seed_label)
	
	# Seed input
	seed_input = LineEdit.new()
	seed_input.name = "SeedInput"
	seed_input.custom_minimum_size = Vector2(150, 0)
	seed_input.placeholder_text = "Enter seed..."
	seed_input.text = str(GameManager.run_seed)
	seed_input.text_submitted.connect(_on_seed_submitted)
	seed_container.add_child(seed_input)
	
	# Randomize button
	seed_randomize_btn = Button.new()
	seed_randomize_btn.text = "🎲"
	seed_randomize_btn.tooltip_text = "Randomize seed"
	seed_randomize_btn.custom_minimum_size = Vector2(35, 0)
	seed_randomize_btn.pressed.connect(_on_randomize_seed)
	seed_container.add_child(seed_randomize_btn)
	
	# Range label
	var range_label := Label.new()
	range_label.text = "  (0 - 2147483647)"
	range_label.add_theme_font_size_override("font_size", 10)
	range_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	seed_container.add_child(range_label)
	
	# Insert after slogan input (index 1 typically, but let's be safe)
	var slogan_idx := slogan_input.get_index()
	left_vbox.add_child(seed_container)
	left_vbox.move_child(seed_container, slogan_idx + 1)


func _update_seed_display() -> void:
	"""Update seed input to show current seed"""
	if seed_input:
		seed_input.text = str(GameManager.run_seed)


func _on_seed_submitted(new_seed_text: String) -> void:
	"""Handle manual seed entry"""
	var new_seed := new_seed_text.to_int()
	
	# Validate range
	if new_seed < SEED_MIN:
		new_seed = SEED_MIN
	elif new_seed > SEED_MAX:
		new_seed = SEED_MAX
	
	# Regenerate with new seed
	_regenerate_with_seed(new_seed)


func _on_randomize_seed() -> void:
	"""Generate new random seed"""
	var new_seed := randi()
	if new_seed < 0:
		new_seed = -new_seed  # Ensure positive
	_regenerate_with_seed(new_seed)


func _regenerate_with_seed(new_seed: int) -> void:
	"""Regenerate the game with a new seed"""
	# Store current skill allocation (we want to keep player's choices)
	var saved_skills := SkillSystem.get_all_skills()
	var saved_points := SkillSystem.get_points_remaining()
	var saved_name := GameManager.player_name
	var saved_slogan := GameManager.campaign_slogan
	
	# Start new game with specified seed
	GameManager.start_new_game(new_seed)
	
	# Restore player choices
	for skill_name in saved_skills:
		SkillSystem.set_skill(skill_name, saved_skills[skill_name])
	SkillSystem.set_starting_allocation(saved_points)
	GameManager.player_name = saved_name
	GameManager.campaign_slogan = saved_slogan
	
	# Update UI
	_update_seed_display()
	_update_district_info()
	_update_skill_values()


func _update_district_info() -> void:
	district_name_label.text = "DISTRICT: %s" % GameManager.district_name
	crisis_label.text = "CRISIS: %s" % GameManager.main_crisis
	opponent_label.text = "RIVAL: %s" % GameManager.opponent_name
	opponent_type_label.text = "TYPE: %s" % GameManager.opponent_archetype


func _update_skill_values() -> void:
	"""Update all skill value displays"""
	for skill_name in skill_rows:
		var panel: PanelContainer = skill_rows[skill_name]
		var row: HBoxContainer = panel.get_child(0)
		var value_label: Label = row.get_node("value_label")
		value_label.text = str(SkillSystem.get_skill(skill_name))


func _create_skill_rows() -> void:
	# Clear existing
	for child in skills_container.get_children():
		child.queue_free()

	# Create a row for each skill
	for skill_name in SkillSystem.SKILL_NAMES:
		var row := _create_skill_row(skill_name)
		skills_container.add_child(row)
		skill_rows[skill_name] = row


func _create_skill_row(skill_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = skill_name + "_panel"

	var row := HBoxContainer.new()
	row.name = skill_name + "_row"

	# Skill name and description
	var name_container := VBoxContainer.new()
	name_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.name = "name_label"
	name_label.text = "► " + SkillSystem.get_skill_display_name(skill_name).to_upper()
	name_label.add_theme_font_size_override("font_size", 14)
	name_container.add_child(name_label)

	var desc_label := Label.new()
	desc_label.name = "desc_label"
	desc_label.text = SkillSystem.get_skill_description(skill_name)
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	name_container.add_child(desc_label)

	row.add_child(name_container)

	# Minus button
	var minus_btn := Button.new()
	minus_btn.name = "minus_btn"
	minus_btn.text = "◄"
	minus_btn.custom_minimum_size = Vector2(35, 35)
	minus_btn.pressed.connect(_on_minus_pressed.bind(skill_name))
	row.add_child(minus_btn)

	# Value label
	var value_label := Label.new()
	value_label.name = "value_label"
	value_label.text = str(SkillSystem.get_skill(skill_name))
	value_label.custom_minimum_size = Vector2(30, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", Color(0.2, 0.4, 0.7))
	row.add_child(value_label)

	# Plus button
	var plus_btn := Button.new()
	plus_btn.name = "plus_btn"
	plus_btn.text = "►"
	plus_btn.custom_minimum_size = Vector2(35, 35)
	plus_btn.pressed.connect(_on_plus_pressed.bind(skill_name))
	row.add_child(plus_btn)

	panel.add_child(row)
	return panel


func _on_minus_pressed(skill_name: String) -> void:
	SkillSystem.deallocate_point(skill_name)


func _on_plus_pressed(skill_name: String) -> void:
	SkillSystem.allocate_point(skill_name)


func _on_points_changed(remaining: int) -> void:
	_update_points_display()


func _on_skill_changed(skill_name: String, new_value: int) -> void:
	if skill_rows.has(skill_name):
		var panel: PanelContainer = skill_rows[skill_name]
		var row: HBoxContainer = panel.get_child(0)
		var value_label: Label = row.get_node("value_label")
		value_label.text = str(new_value)


func _update_points_display() -> void:
	var remaining := SkillSystem.get_points_remaining()
	points_label.text = "► REMAINING: %d" % remaining


func _on_name_changed(new_text: String) -> void:
	GameManager.player_name = new_text if new_text.length() > 0 else "Candidate"


func _on_slogan_changed(new_text: String) -> void:
	GameManager.campaign_slogan = new_text


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_start_pressed() -> void:
	if GameManager.player_name.length() == 0:
		GameManager.player_name = "Candidate"

	# Day 1 (Registration) is complete. Advance to Day 2 (Canvassing).
	GameManager.advance_day()

	# Transition to the game scene
	get_tree().change_scene_to_file("res://scenes/game.tscn")
