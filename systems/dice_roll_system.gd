extends Node

## Dice Roll System - Dramatic skill checks with modifiers, advantage/disadvantage, and criticals
## Inspired by Disco Elysium's tension and Baldur's Gate 3's visible dice

signal roll_started(check_data: Dictionary)
signal roll_completed(result: Dictionary)

# Skill voice flavor text
const SKILL_VOICES := {
	"speechcraft": {
		"pre": "You can talk your way out of this. You've done it before.",
		"success": "Your words land. They actually believe you.",
		"failure": "The words come out wrong. They're not buying it.",
		"crit_success": "You've never been more convincing. They're mesmerized.",
		"crit_failure": "You say something deeply offensive. This will haunt you."
	},
	"kapital": {
		"pre": "Money talks. Let it speak for you.",
		"success": "The transaction is complete. Everyone has their price.",
		"failure": "Your wallet isn't deep enough for this one.",
		"crit_success": "They're so impressed, they offer you more.",
		"crit_failure": "The paper trail is exposed. Scandal incoming."
	},
	"influence": {
		"pre": "You've built an audience. Time to use it.",
		"success": "Your reputation precedes you. They're already on your side.",
		"failure": "Your influence doesn't reach this far.",
		"crit_success": "You've become a symbol. They'll follow you anywhere.",
		"crit_failure": "Your fame backfires spectacularly."
	},
	"legitimacy": {
		"pre": "Do they believe you belong here? Let's find out.",
		"success": "Your credentials check out. They accept your authority.",
		"failure": "They see through you. You don't belong here.",
		"crit_success": "They're in awe of your qualifications.",
		"crit_failure": "Your entire background is called into question."
	},
	"logic": {
		"pre": "The facts are on your side. Probably.",
		"success": "Your argument is airtight. They can't refute it.",
		"failure": "Your logic has a hole. They found it.",
		"crit_success": "You expose their contradiction. They're speechless.",
		"crit_failure": "You contradict yourself on camera. Viral clip."
	}
}


func _ready() -> void:
	print("[DiceRollSystem] Initialized")


func perform_check(skill_name: String, difficulty: int, context: Dictionary = {}) -> Dictionary:
	"""
	Perform a skill check with full modifier calculation, advantage/disadvantage, and criticals.
	
	context can include:
	- npc_id: String (for trust-based modifiers)
	- check_tags: Array[String] (for promise/flag matching)
	- description: String (for UI display)
	"""
	
	# Get base skill value
	var skill_value := SkillSystem.get_skill(skill_name)
	
	# Calculate modifiers
	var modifiers := calculate_modifiers(skill_name, context)
	var total_modifier := 0
	for mod in modifiers:
		total_modifier += mod.amount
	
	# Check for advantage/disadvantage
	var has_advantage := check_advantage(skill_name, context)
	var has_disadvantage := check_disadvantage(skill_name, context)
	
	# If both, they cancel out
	if has_advantage and has_disadvantage:
		has_advantage = false
		has_disadvantage = false
	
	# Calculate probability before rolling
	var probability := calculate_probability(skill_value, difficulty, total_modifier, has_advantage, has_disadvantage)
	
	# Build pre-roll data for UI
	var check_data := {
		"skill_name": skill_name,
		"skill_display": SkillSystem.get_skill_display_name(skill_name),
		"skill_value": skill_value,
		"difficulty": difficulty,
		"modifiers": modifiers,
		"total_modifier": total_modifier,
		"has_advantage": has_advantage,
		"has_disadvantage": has_disadvantage,
		"probability": probability,
		"description": context.get("description", ""),
		"pre_voice": SKILL_VOICES.get(skill_name, {}).get("pre", "Make your move.")
	}
	
	roll_started.emit(check_data)
	
	# Perform the actual roll
	var roll_values: Array[int] = []
	var final_roll: int
	
	if has_advantage:
		# Roll 2d10, take higher
		roll_values.append(randi_range(1, 10))
		roll_values.append(randi_range(1, 10))
		final_roll = maxi(roll_values[0], roll_values[1])
	elif has_disadvantage:
		# Roll 2d10, take lower
		roll_values.append(randi_range(1, 10))
		roll_values.append(randi_range(1, 10))
		final_roll = mini(roll_values[0], roll_values[1])
	else:
		# Normal roll
		final_roll = randi_range(1, 10)
		roll_values.append(final_roll)
	
	# Calculate total
	var total := skill_value + total_modifier + final_roll
	var success := total >= difficulty
	
	# Check for criticals (based on final_roll, not total)
	var is_crit_success := final_roll == 10
	var is_crit_failure := final_roll == 1
	
	# Determine flavor text
	var voice_key := "success" if success else "failure"
	if is_crit_success:
		voice_key = "crit_success"
	elif is_crit_failure:
		voice_key = "crit_failure"
	
	var flavor_text: String = SKILL_VOICES.get(skill_name, {}).get(voice_key, "")
	
	# Build result
	var result := {
		"skill_name": skill_name,
		"skill_display": SkillSystem.get_skill_display_name(skill_name),
		"skill_value": skill_value,
		"difficulty": difficulty,
		"modifiers": modifiers,
		"total_modifier": total_modifier,
		"has_advantage": has_advantage,
		"has_disadvantage": has_disadvantage,
		"probability": probability,
		"roll_values": roll_values,
		"final_roll": final_roll,
		"total": total,
		"success": success,
		"is_crit_success": is_crit_success,
		"is_crit_failure": is_crit_failure,
		"margin": total - difficulty,
		"flavor_text": flavor_text
	}
	
	roll_completed.emit(result)
	
	return result


func calculate_modifiers(skill_name: String, context: Dictionary) -> Array[Dictionary]:
	"""Calculate all applicable modifiers for a skill check."""
	var modifiers: Array[Dictionary] = []
	
	var npc_id: String = context.get("npc_id", "")
	var check_tags: Array = context.get("check_tags", [])
	
	# 1. NPC Trust modifier
	if npc_id != "":
		var trust := GameManager.get_npc_trust(npc_id)
		if trust >= 30:
			modifiers.append({"source": "NPC trusts you", "amount": 2})
		elif trust >= 10:
			modifiers.append({"source": "NPC is warming up", "amount": 1})
		elif trust <= -30:
			modifiers.append({"source": "NPC distrusts you", "amount": -2})
		elif trust <= -10:
			modifiers.append({"source": "NPC is skeptical", "amount": -1})
	
	# 2. Active scandals penalty
	if GameManager.scandals.size() > 0:
		modifiers.append({"source": "Active scandal", "amount": -2})
	
	# 3. Endorsements bonus
	if GameManager.endorsements.size() >= 3:
		modifiers.append({"source": "Well endorsed", "amount": 2})
	elif GameManager.endorsements.size() >= 1:
		modifiers.append({"source": "Has endorsement", "amount": 1})
	
	# 4. Broken promises penalty
	if GameManager.promises_broken.size() > 0:
		var penalty := mini(GameManager.promises_broken.size(), 3)
		modifiers.append({"source": "Broken promises", "amount": -penalty})
	
	# 5. District support bonus
	if GameManager.district_support >= 30:
		modifiers.append({"source": "Popular in district", "amount": 2})
	elif GameManager.district_support >= 10:
		modifiers.append({"source": "Some district support", "amount": 1})
	elif GameManager.district_support <= -30:
		modifiers.append({"source": "Unpopular in district", "amount": -2})
	
	# 6. Related skill synergy (if another skill is very high, it helps)
	var synergy_skills := {
		"speechcraft": "influence",
		"kapital": "influence", 
		"influence": "legitimacy",
		"legitimacy": "logic",
		"logic": "speechcraft"
	}
	var synergy_skill: String = synergy_skills.get(skill_name, "")
	if synergy_skill != "":
		var synergy_value := SkillSystem.get_skill(synergy_skill)
		if synergy_value >= 8:
			modifiers.append({"source": "%s synergy" % SkillSystem.get_skill_display_name(synergy_skill), "amount": 1})
	
	# 7. Day-based tension (later days are harder under pressure)
	if GameManager.current_day >= 6:
		modifiers.append({"source": "Election pressure", "amount": -1})
	
	return modifiers


func check_advantage(skill_name: String, context: Dictionary) -> bool:
	"""Check if the player has advantage on this roll."""
	var npc_id: String = context.get("npc_id", "")
	
	# High NPC trust grants advantage
	if npc_id != "" and GameManager.get_npc_trust(npc_id) >= 50:
		return true
	
	# Media bias strongly in your favor
	if GameManager.media_bias >= 0.4:
		return true
	
	# Opponent has active scandal (context flag)
	if GameManager.get_run_flag("opponent_scandal"):
		return true
	
	# Very high district support
	if GameManager.district_support >= 50:
		return true
	
	return false


func check_disadvantage(skill_name: String, context: Dictionary) -> bool:
	"""Check if the player has disadvantage on this roll."""
	var npc_id: String = context.get("npc_id", "")
	
	# Very low NPC trust grants disadvantage
	if npc_id != "" and GameManager.get_npc_trust(npc_id) <= -50:
		return true
	
	# Media bias strongly against you
	if GameManager.media_bias <= -0.4:
		return true
	
	# Multiple active scandals
	if GameManager.scandals.size() >= 2:
		return true
	
	# Many broken promises
	if GameManager.promises_broken.size() >= 3:
		return true
	
	return false


func calculate_probability(skill: int, difficulty: int, modifier: int, has_adv: bool, has_dis: bool) -> float:
	"""Calculate the probability of success for a skill check."""
	# Need to roll: difficulty - skill - modifier or higher on d10
	var need_to_roll := difficulty - skill - modifier
	
	# Clamp to valid d10 range
	if need_to_roll <= 1:
		return 1.0  # Auto-success (even rolling 1 would succeed)
	if need_to_roll > 10:
		return 0.0  # Impossible
	
	# Base probability on d10
	var base_prob := (11.0 - need_to_roll) / 10.0
	
	if has_adv:
		# P(at least one die >= X) = 1 - P(both < X)^2
		var fail_prob := 1.0 - base_prob
		return 1.0 - (fail_prob * fail_prob)
	elif has_dis:
		# P(both dice >= X) = P(X)^2
		return base_prob * base_prob
	
	return base_prob


func get_difficulty_name(difficulty: int) -> String:
	"""Get a human-readable name for a difficulty value."""
	if difficulty <= 8:
		return "Trivial"
	elif difficulty <= 10:
		return "Easy"
	elif difficulty <= 12:
		return "Medium"
	elif difficulty <= 14:
		return "Hard"
	elif difficulty <= 16:
		return "Very Hard"
	else:
		return "Nearly Impossible"
