extends Node

## SKILL System - Player attribute management
## S - Speechcraft: How convincing you sound
## K - Kapital: Campaign money and financial leverage
## I - Influence: Passive reach and media momentum
## L - Legitimacy: Whether people believe you should be in power
## L - Logic: Consistency of positions, resistance to contradictions

signal skill_changed(skill_name: String, new_value: int)
signal points_changed(remaining: int)

const SKILL_NAMES := ["speechcraft", "kapital", "influence", "legitimacy", "logic"]
const SKILL_DISPLAY := {
	"speechcraft": "Speechcraft",
	"kapital": "Kapital",
	"influence": "Influence",
	"legitimacy": "Legitimacy",
	"logic": "Logic"
}
const SKILL_DESCRIPTIONS := {
	"speechcraft": "How convincing you sound in arguments and debates",
	"kapital": "Campaign money, donors, and financial leverage",
	"influence": "Passive reach, reputation, and media momentum",
	"legitimacy": "Whether people believe you should be in power",
	"logic": "Consistency of your positions and resistance to contradictions"
}

const MIN_SKILL := 1
const MAX_SKILL := 10
const STARTING_POINTS := 15
const DEFAULT_SKILL_VALUE := 3

# Current skill values
var skills: Dictionary = {
	"speechcraft": DEFAULT_SKILL_VALUE,
	"kapital": DEFAULT_SKILL_VALUE,
	"influence": DEFAULT_SKILL_VALUE,
	"legitimacy": DEFAULT_SKILL_VALUE,
	"logic": DEFAULT_SKILL_VALUE
}

# Temporary modifiers (from events, items, etc)
var modifiers: Dictionary = {
	"speechcraft": 0,
	"kapital": 0,
	"influence": 0,
	"legitimacy": 0,
	"logic": 0
}

# Points available for allocation
var allocation_points: int = STARTING_POINTS


func _ready() -> void:
	print("[SkillSystem] Initialized")
	reset_skills()


func reset_skills() -> void:
	"""Reset all skills to default values"""
	for skill in SKILL_NAMES:
		skills[skill] = DEFAULT_SKILL_VALUE
		modifiers[skill] = 0

	# Calculate starting points (subtract what's already allocated)
	var used_points := DEFAULT_SKILL_VALUE * SKILL_NAMES.size()
	allocation_points = STARTING_POINTS - used_points + (DEFAULT_SKILL_VALUE * SKILL_NAMES.size())
	# Simplify: start with 15 points, 3 in each = 0 remaining by default
	allocation_points = 0

	print("[SkillSystem] Skills reset")


func get_skill(skill_name: String) -> int:
	"""Get effective skill value (base + modifiers)"""
	if not skills.has(skill_name):
		push_error("Unknown skill: %s" % skill_name)
		return 0
	return clampi(skills[skill_name] + modifiers[skill_name], MIN_SKILL, MAX_SKILL)


func get_base_skill(skill_name: String) -> int:
	"""Get base skill value without modifiers"""
	return skills.get(skill_name, 0)


func set_skill(skill_name: String, value: int) -> void:
	"""Set a skill's base value directly"""
	if not skills.has(skill_name):
		push_error("Unknown skill: %s" % skill_name)
		return
	skills[skill_name] = clampi(value, MIN_SKILL, MAX_SKILL)
	skill_changed.emit(skill_name, get_skill(skill_name))


func allocate_point(skill_name: String) -> bool:
	"""Allocate one point to a skill during character creation"""
	if allocation_points <= 0:
		return false
	if not skills.has(skill_name):
		return false
	if skills[skill_name] >= MAX_SKILL:
		return false

	skills[skill_name] += 1
	allocation_points -= 1
	skill_changed.emit(skill_name, get_skill(skill_name))
	points_changed.emit(allocation_points)
	return true


func deallocate_point(skill_name: String) -> bool:
	"""Remove one point from a skill during character creation"""
	if not skills.has(skill_name):
		return false
	if skills[skill_name] <= MIN_SKILL:
		return false

	skills[skill_name] -= 1
	allocation_points += 1
	skill_changed.emit(skill_name, get_skill(skill_name))
	points_changed.emit(allocation_points)
	return true


func add_modifier(skill_name: String, amount: int) -> void:
	"""Add a temporary modifier to a skill"""
	if not modifiers.has(skill_name):
		push_error("Unknown skill: %s" % skill_name)
		return
	modifiers[skill_name] += amount
	skill_changed.emit(skill_name, get_skill(skill_name))
	print("[SkillSystem] Added modifier %+d to %s" % [amount, skill_name])


func remove_modifier(skill_name: String, amount: int) -> void:
	"""Remove a temporary modifier from a skill"""
	add_modifier(skill_name, -amount)


func clear_modifiers() -> void:
	"""Clear all temporary modifiers"""
	for skill in SKILL_NAMES:
		modifiers[skill] = 0
		skill_changed.emit(skill, get_skill(skill))


func check_skill(skill_name: String, threshold: int) -> bool:
	"""Check if a skill meets a threshold"""
	return get_skill(skill_name) >= threshold


func roll_skill_check(skill_name: String, difficulty: int) -> Dictionary:
	"""Perform a skill check with randomness
	Returns: {success: bool, margin: int, roll: int}"""
	var skill_value := get_skill(skill_name)
	var roll := randi_range(1, 10)
	var total := skill_value + roll
	var success := total >= difficulty

	return {
		"success": success,
		"margin": total - difficulty,
		"roll": roll,
		"skill_value": skill_value,
		"total": total,
		"difficulty": difficulty
	}


func get_all_skills() -> Dictionary:
	"""Get all effective skill values"""
	var result := {}
	for skill in SKILL_NAMES:
		result[skill] = get_skill(skill)
	return result


func get_skill_display_name(skill_name: String) -> String:
	"""Get the display name for a skill"""
	return SKILL_DISPLAY.get(skill_name, skill_name.capitalize())


func get_skill_description(skill_name: String) -> String:
	"""Get the description for a skill"""
	return SKILL_DESCRIPTIONS.get(skill_name, "")


func set_starting_allocation(extra_points: int) -> void:
	"""Set available allocation points for character creation"""
	allocation_points = extra_points
	points_changed.emit(allocation_points)


func get_points_remaining() -> int:
	"""Get remaining allocation points"""
	return allocation_points
