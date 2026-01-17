extends Node

## Perk System - Character perks/traits selected at creation
## Similar to Fallout's perk system - special abilities that define playstyle

signal perk_selected(perk_id: String)
signal perk_removed(perk_id: String)
signal perk_triggered(perk_id: String, context: Dictionary)

# How many perks player can select at character creation
const STARTING_PERK_SLOTS := 2
const MAX_PERKS := 4  # Can unlock more through gameplay

# Currently selected perks
var active_perks: Array[String] = []
var perk_slots: int = STARTING_PERK_SLOTS

# Track perk triggers for cooldowns/limits
var perk_usage: Dictionary = {}  # perk_id -> {times_used: int, last_day: int}

# ═══════════════════════════════════════════════════════════════════════════════
# PERK DEFINITIONS
# ═══════════════════════════════════════════════════════════════════════════════

const PERKS := {
	# ─────────────────────────────────────────────────────────────────────────
	# SPEECHCRAFT PERKS
	# ─────────────────────────────────────────────────────────────────────────
	"silver_tongue": {
		"name": "Silver Tongue",
		"description": "Your words flow like honey. +2 to all Speechcraft checks.",
		"icon": "🗣️",
		"category": "speechcraft",
		"requires": {"speechcraft": 4},
		"effects": {
			"skill_bonus": {"speechcraft": 2}
		},
		"type": "passive"
	},
	"crowd_pleaser": {
		"name": "Crowd Pleaser",
		"description": "You thrive in front of audiences. Town events give +50% district support.",
		"icon": "👏",
		"category": "speechcraft",
		"requires": {"speechcraft": 5},
		"effects": {
			"event_bonus": {"town_event": 1.5}
		},
		"type": "passive"
	},
	"debate_champion": {
		"name": "Debate Champion",
		"description": "You've done this before. Start debates with Advantage on first check.",
		"icon": "🏆",
		"category": "speechcraft",
		"requires": {"speechcraft": 6},
		"effects": {
			"debate_first_advantage": true
		},
		"type": "triggered"
	},
	"honeyed_words": {
		"name": "Honeyed Words",
		"description": "Once per day, re-roll a failed Speechcraft check.",
		"icon": "🍯",
		"category": "speechcraft",
		"requires": {"speechcraft": 5},
		"effects": {
			"reroll_skill": "speechcraft",
			"uses_per_day": 1
		},
		"type": "activated"
	},

	# ─────────────────────────────────────────────────────────────────────────
	# KAPITAL PERKS
	# ─────────────────────────────────────────────────────────────────────────
	"deep_pockets": {
		"name": "Deep Pockets",
		"description": "Start with +3 Kapital. Money opens doors.",
		"icon": "💰",
		"category": "kapital",
		"requires": {},
		"effects": {
			"starting_skill_bonus": {"kapital": 3}
		},
		"type": "passive"
	},
	"donor_network": {
		"name": "Donor Network",
		"description": "Fundraiser events give double rewards. You know the right people.",
		"icon": "📞",
		"category": "kapital",
		"requires": {"kapital": 4},
		"effects": {
			"event_bonus": {"fundraiser": 2.0}
		},
		"type": "passive"
	},
	"money_talks": {
		"name": "Money Talks",
		"description": "Once per run, automatically succeed a failed check by 'making it rain.'",
		"icon": "💸",
		"category": "kapital",
		"requires": {"kapital": 6},
		"effects": {
			"auto_succeed": true,
			"uses_per_run": 1,
			"costs": {"kapital": -2}  # Costs 2 Kapital to use
		},
		"type": "activated"
	},
	"corporate_backing": {
		"name": "Corporate Backing",
		"description": "Start with a corporate endorsement. -1 Legitimacy, but +3 Influence.",
		"icon": "🏢",
		"category": "kapital",
		"requires": {"kapital": 5},
		"effects": {
			"starting_endorsement": "Corporate PAC",
			"starting_skill_mod": {"legitimacy": -1, "influence": 3}
		},
		"type": "passive",
		"tradeoff": true
	},

	# ─────────────────────────────────────────────────────────────────────────
	# INFLUENCE PERKS
	# ─────────────────────────────────────────────────────────────────────────
	"media_darling": {
		"name": "Media Darling",
		"description": "The press loves you. +15% positive news coverage.",
		"icon": "📺",
		"category": "influence",
		"requires": {"influence": 4},
		"effects": {
			"news_bias": 0.15
		},
		"type": "passive"
	},
	"social_media_savvy": {
		"name": "Social Media Savvy",
		"description": "Scandals spread slower. -25% scandal impact on district support.",
		"icon": "📱",
		"category": "influence",
		"requires": {"influence": 5},
		"effects": {
			"scandal_reduction": 0.25
		},
		"type": "passive"
	},
	"grassroots_hero": {
		"name": "Grassroots Hero",
		"description": "Canvassing is more effective. +3 trust per positive interaction.",
		"icon": "🌱",
		"category": "influence",
		"requires": {"influence": 4},
		"effects": {
			"canvassing_bonus": 3
		},
		"type": "passive"
	},
	"viral_moment": {
		"name": "Viral Moment",
		"description": "Once per run, a success becomes a critical success (goes viral).",
		"icon": "🔥",
		"category": "influence",
		"requires": {"influence": 6},
		"effects": {
			"force_crit": true,
			"uses_per_run": 1
		},
		"type": "activated"
	},

	# ─────────────────────────────────────────────────────────────────────────
	# LEGITIMACY PERKS
	# ─────────────────────────────────────────────────────────────────────────
	"establishment_insider": {
		"name": "Establishment Insider",
		"description": "You know how the system works. +2 to Legitimacy checks.",
		"icon": "🏛️",
		"category": "legitimacy",
		"requires": {"legitimacy": 4},
		"effects": {
			"skill_bonus": {"legitimacy": 2}
		},
		"type": "passive"
	},
	"spotless_record": {
		"name": "Spotless Record",
		"description": "Your past is clean. First scandal of the run is buried.",
		"icon": "✨",
		"category": "legitimacy",
		"requires": {"legitimacy": 5},
		"effects": {
			"scandal_immunity": 1
		},
		"type": "triggered"
	},
	"trusted_face": {
		"name": "Trusted Face",
		"description": "NPCs start with +10 trust toward you. You seem... reliable.",
		"icon": "😊",
		"category": "legitimacy",
		"requires": {"legitimacy": 4},
		"effects": {
			"starting_npc_trust": 10
		},
		"type": "passive"
	},
	"veteran_campaigner": {
		"name": "Veteran Campaigner",
		"description": "You've run before. Start Day 2 with +15 district support.",
		"icon": "🎖️",
		"category": "legitimacy",
		"requires": {"legitimacy": 5},
		"effects": {
			"starting_district_support": 15
		},
		"type": "passive"
	},

	# ─────────────────────────────────────────────────────────────────────────
	# LOGIC PERKS
	# ─────────────────────────────────────────────────────────────────────────
	"consistency_bonus": {
		"name": "Ideological Purity",
		"description": "Keeping promises gives +2 to all checks for the rest of the run.",
		"icon": "⚖️",
		"category": "logic",
		"requires": {"logic": 4},
		"effects": {
			"promise_kept_bonus": 2
		},
		"type": "triggered"
	},
	"fact_checker": {
		"name": "Fact Checker",
		"description": "Once per debate, expose opponent's contradiction for +5 support.",
		"icon": "🔍",
		"category": "logic",
		"requires": {"logic": 5},
		"effects": {
			"debate_expose": true,
			"uses_per_debate": 1
		},
		"type": "activated"
	},
	"mental_fortress": {
		"name": "Mental Fortress",
		"description": "You never contradict yourself. Immune to Logic-based attacks in debate.",
		"icon": "🧠",
		"category": "logic",
		"requires": {"logic": 6},
		"effects": {
			"logic_attack_immunity": true
		},
		"type": "passive"
	},
	"calculated_risk": {
		"name": "Calculated Risk",
		"description": "Know the odds. See hidden probability modifiers on checks.",
		"icon": "🎯",
		"category": "logic",
		"requires": {"logic": 5},
		"effects": {
			"show_hidden_modifiers": true
		},
		"type": "passive"
	},

	# ─────────────────────────────────────────────────────────────────────────
	# WILDCARD PERKS (No skill requirements, but tradeoffs)
	# ─────────────────────────────────────────────────────────────────────────
	"political_outsider": {
		"name": "Political Outsider",
		"description": "You're not one of them. -2 Legitimacy, but +3 Speechcraft with angry voters.",
		"icon": "🔥",
		"category": "wildcard",
		"requires": {},
		"effects": {
			"starting_skill_mod": {"legitimacy": -2},
			"mood_bonus": {"angry": 3}
		},
		"type": "passive",
		"tradeoff": true
	},
	"local_celebrity": {
		"name": "Local Celebrity",
		"description": "Everyone knows your face. +20% name recognition, -10% taken seriously.",
		"icon": "⭐",
		"category": "wildcard",
		"requires": {},
		"effects": {
			"name_recognition_bonus": 0.2,
			"legitimacy_penalty": -1
		},
		"type": "passive",
		"tradeoff": true
	},
	"dark_horse": {
		"name": "Dark Horse",
		"description": "Nobody expects you to win. Opponent underestimates you (-10% their effectiveness).",
		"icon": "🐴",
		"category": "wildcard",
		"requires": {},
		"effects": {
			"opponent_debuff": 0.1
		},
		"type": "passive"
	},
	"family_name": {
		"name": "Family Name",
		"description": "Political dynasty. +3 Legitimacy, but scandals hurt 50% more.",
		"icon": "👨‍👩‍👧",
		"category": "wildcard",
		"requires": {},
		"effects": {
			"starting_skill_mod": {"legitimacy": 3},
			"scandal_vulnerability": 1.5
		},
		"type": "passive",
		"tradeoff": true
	},
	"lucky_bastard": {
		"name": "Lucky Bastard",
		"description": "Born under a good sign. Critical success on 9 or 10 (normally just 10).",
		"icon": "🍀",
		"category": "wildcard",
		"requires": {},
		"effects": {
			"crit_range_bonus": 1
		},
		"type": "passive"
	},
	"thick_skin": {
		"name": "Thick Skin",
		"description": "Insults bounce off. Opponent attacks in debate are 30% less effective.",
		"icon": "🛡️",
		"category": "wildcard",
		"requires": {},
		"effects": {
			"debate_defense": 0.3
		},
		"type": "passive"
	},
	"wildcard_play": {
		"name": "Wildcard",
		"description": "Chaos is a ladder. Once per run, flip a failed check to critical success OR critical failure (50/50).",
		"icon": "🃏",
		"category": "wildcard",
		"requires": {},
		"effects": {
			"chaos_flip": true,
			"uses_per_run": 1
		},
		"type": "activated",
		"risky": true
	},
}

# Perks that cannot be taken together
const EXCLUSIVE_PERKS := [
	["establishment_insider", "political_outsider"],  # Can't be both
	["spotless_record", "family_name"],  # Dynasty = baggage
	["deep_pockets", "grassroots_hero"],  # Different campaign styles
]


func _ready() -> void:
	print("[PerkSystem] Initialized with %d available perks" % PERKS.size())


func reset() -> void:
	"""Reset perk system for new game"""
	active_perks.clear()
	perk_slots = STARTING_PERK_SLOTS
	perk_usage.clear()
	print("[PerkSystem] Reset")


func get_available_perks() -> Array[String]:
	"""Get list of perks the player can currently select"""
	var available: Array[String] = []

	for perk_id in PERKS:
		if can_select_perk(perk_id):
			available.append(perk_id)

	return available


func can_select_perk(perk_id: String) -> bool:
	"""Check if a perk can be selected"""
	if not PERKS.has(perk_id):
		return false

	# Already have it
	if active_perks.has(perk_id):
		return false

	# No slots left
	if active_perks.size() >= perk_slots:
		return false

	# Check skill requirements
	var perk: Dictionary = PERKS[perk_id]
	var requires: Dictionary = perk.get("requires", {})
	for skill_name in requires:
		if SkillSystem.get_skill(skill_name) < requires[skill_name]:
			return false

	# Check exclusivity
	for exclusive_group in EXCLUSIVE_PERKS:
		if perk_id in exclusive_group:
			for other_perk in exclusive_group:
				if other_perk != perk_id and active_perks.has(other_perk):
					return false

	return true


func select_perk(perk_id: String) -> bool:
	"""Select a perk during character creation"""
	if not can_select_perk(perk_id):
		return false

	active_perks.append(perk_id)
	perk_usage[perk_id] = {"times_used": 0, "last_day": 0}
	perk_selected.emit(perk_id)
	print("[PerkSystem] Selected perk: %s" % perk_id)

	# Apply immediate effects
	_apply_starting_effects(perk_id)

	return true


func remove_perk(perk_id: String) -> bool:
	"""Remove a perk (during character creation only)"""
	var idx := active_perks.find(perk_id)
	if idx == -1:
		return false

	active_perks.remove_at(idx)
	perk_usage.erase(perk_id)
	perk_removed.emit(perk_id)
	print("[PerkSystem] Removed perk: %s" % perk_id)

	# Note: Starting effects would need to be reversed here
	# For simplicity, only allow removal before game starts

	return true


func has_perk(perk_id: String) -> bool:
	"""Check if player has a specific perk"""
	return active_perks.has(perk_id)


func get_perk_data(perk_id: String) -> Dictionary:
	"""Get full perk definition"""
	return PERKS.get(perk_id, {})


func get_active_perks() -> Array[String]:
	"""Get list of active perk IDs"""
	return active_perks.duplicate()


func get_active_perks_data() -> Array[Dictionary]:
	"""Get full data for all active perks"""
	var result: Array[Dictionary] = []
	for perk_id in active_perks:
		var data := PERKS.get(perk_id, {}).duplicate()
		data["id"] = perk_id
		result.append(data)
	return result


func _apply_starting_effects(perk_id: String) -> void:
	"""Apply effects that happen immediately on perk selection"""
	var perk: Dictionary = PERKS.get(perk_id, {})
	var effects: Dictionary = perk.get("effects", {})

	# Starting skill bonuses
	if effects.has("starting_skill_bonus"):
		for skill_name in effects["starting_skill_bonus"]:
			var amount: int = effects["starting_skill_bonus"][skill_name]
			SkillSystem.add_modifier(skill_name, amount)

	# Starting skill modifications (can be negative)
	if effects.has("starting_skill_mod"):
		for skill_name in effects["starting_skill_mod"]:
			var amount: int = effects["starting_skill_mod"][skill_name]
			SkillSystem.add_modifier(skill_name, amount)


func apply_game_start_effects() -> void:
	"""Apply effects that happen when the game actually starts (after character creation)"""
	for perk_id in active_perks:
		var perk: Dictionary = PERKS.get(perk_id, {})
		var effects: Dictionary = perk.get("effects", {})

		# Starting endorsement
		if effects.has("starting_endorsement"):
			GameManager.add_endorsement(effects["starting_endorsement"])

		# Starting district support
		if effects.has("starting_district_support"):
			GameManager.add_district_support(effects["starting_district_support"], "perk:" + perk_id)


# ═══════════════════════════════════════════════════════════════════════════════
# PERK EFFECT QUERIES (called by other systems)
# ═══════════════════════════════════════════════════════════════════════════════

func get_skill_bonus(skill_name: String) -> int:
	"""Get total skill bonus from perks"""
	var bonus := 0
	for perk_id in active_perks:
		var effects: Dictionary = PERKS.get(perk_id, {}).get("effects", {})
		if effects.has("skill_bonus") and effects["skill_bonus"].has(skill_name):
			bonus += effects["skill_bonus"][skill_name]
	return bonus


func get_crit_range_bonus() -> int:
	"""Get critical success range bonus (normally 0, meaning only 10 crits)"""
	var bonus := 0
	for perk_id in active_perks:
		var effects: Dictionary = PERKS.get(perk_id, {}).get("effects", {})
		if effects.has("crit_range_bonus"):
			bonus += effects["crit_range_bonus"]
	return bonus


func get_scandal_reduction() -> float:
	"""Get scandal impact reduction (0.0 to 1.0)"""
	var reduction := 0.0
	for perk_id in active_perks:
		var effects: Dictionary = PERKS.get(perk_id, {}).get("effects", {})
		if effects.has("scandal_reduction"):
			reduction += effects["scandal_reduction"]
	return clampf(reduction, 0.0, 0.75)  # Cap at 75% reduction


func get_scandal_vulnerability() -> float:
	"""Get scandal vulnerability multiplier (1.0 = normal)"""
	var mult := 1.0
	for perk_id in active_perks:
		var effects: Dictionary = PERKS.get(perk_id, {}).get("effects", {})
		if effects.has("scandal_vulnerability"):
			mult = maxf(mult, effects["scandal_vulnerability"])
	return mult


func get_event_bonus(event_type: String) -> float:
	"""Get event reward multiplier for a specific event type"""
	var mult := 1.0
	for perk_id in active_perks:
		var effects: Dictionary = PERKS.get(perk_id, {}).get("effects", {})
		if effects.has("event_bonus") and effects["event_bonus"].has(event_type):
			mult *= effects["event_bonus"][event_type]
	return mult


func get_starting_npc_trust() -> int:
	"""Get bonus starting trust with NPCs"""
	var bonus := 0
	for perk_id in active_perks:
		var effects: Dictionary = PERKS.get(perk_id, {}).get("effects", {})
		if effects.has("starting_npc_trust"):
			bonus += effects["starting_npc_trust"]
	return bonus


func get_canvassing_bonus() -> int:
	"""Get bonus trust from canvassing interactions"""
	var bonus := 0
	for perk_id in active_perks:
		var effects: Dictionary = PERKS.get(perk_id, {}).get("effects", {})
		if effects.has("canvassing_bonus"):
			bonus += effects["canvassing_bonus"]
	return bonus


func get_debate_defense() -> float:
	"""Get debate attack reduction (0.0 to 1.0)"""
	var defense := 0.0
	for perk_id in active_perks:
		var effects: Dictionary = PERKS.get(perk_id, {}).get("effects", {})
		if effects.has("debate_defense"):
			defense += effects["debate_defense"]
	return clampf(defense, 0.0, 0.5)  # Cap at 50%


func get_opponent_debuff() -> float:
	"""Get opponent effectiveness reduction"""
	var debuff := 0.0
	for perk_id in active_perks:
		var effects: Dictionary = PERKS.get(perk_id, {}).get("effects", {})
		if effects.has("opponent_debuff"):
			debuff += effects["opponent_debuff"]
	return clampf(debuff, 0.0, 0.3)  # Cap at 30%


func has_debate_first_advantage() -> bool:
	"""Check if player has advantage on first debate check"""
	for perk_id in active_perks:
		var effects: Dictionary = PERKS.get(perk_id, {}).get("effects", {})
		if effects.get("debate_first_advantage", false):
			return true
	return false


func has_logic_immunity() -> bool:
	"""Check if player is immune to logic-based attacks"""
	for perk_id in active_perks:
		var effects: Dictionary = PERKS.get(perk_id, {}).get("effects", {})
		if effects.get("logic_attack_immunity", false):
			return true
	return false


func should_show_hidden_modifiers() -> bool:
	"""Check if player can see hidden dice roll modifiers"""
	for perk_id in active_perks:
		var effects: Dictionary = PERKS.get(perk_id, {}).get("effects", {})
		if effects.get("show_hidden_modifiers", false):
			return true
	return false


func get_scandal_immunity_remaining() -> int:
	"""Check how many scandal immunities remain"""
	for perk_id in active_perks:
		var effects: Dictionary = PERKS.get(perk_id, {}).get("effects", {})
		if effects.has("scandal_immunity"):
			var used: int = perk_usage.get(perk_id, {}).get("times_used", 0)
			return maxi(0, effects["scandal_immunity"] - used)
	return 0


func use_scandal_immunity() -> bool:
	"""Use one scandal immunity charge"""
	for perk_id in active_perks:
		var effects: Dictionary = PERKS.get(perk_id, {}).get("effects", {})
		if effects.has("scandal_immunity"):
			var used: int = perk_usage.get(perk_id, {}).get("times_used", 0)
			if used < effects["scandal_immunity"]:
				perk_usage[perk_id]["times_used"] = used + 1
				perk_triggered.emit(perk_id, {"action": "scandal_immunity"})
				print("[PerkSystem] Used scandal immunity from %s" % perk_id)
				return true
	return false


# ═══════════════════════════════════════════════════════════════════════════════
# ACTIVATED ABILITIES (player-triggered)
# ═══════════════════════════════════════════════════════════════════════════════

func can_use_reroll(skill_name: String) -> bool:
	"""Check if player can reroll a specific skill"""
	for perk_id in active_perks:
		var effects: Dictionary = PERKS.get(perk_id, {}).get("effects", {})
		if effects.get("reroll_skill", "") == skill_name:
			var usage: Dictionary = perk_usage.get(perk_id, {})
			var uses_today: int = 0
			if usage.get("last_day", 0) == GameManager.current_day:
				uses_today = usage.get("times_used", 0)
			if uses_today < effects.get("uses_per_day", 1):
				return true
	return false


func use_reroll(skill_name: String) -> bool:
	"""Use a reroll ability"""
	for perk_id in active_perks:
		var effects: Dictionary = PERKS.get(perk_id, {}).get("effects", {})
		if effects.get("reroll_skill", "") == skill_name:
			var usage: Dictionary = perk_usage.get(perk_id, {"times_used": 0, "last_day": 0})

			# Reset if new day
			if usage.get("last_day", 0) != GameManager.current_day:
				usage["times_used"] = 0
				usage["last_day"] = GameManager.current_day

			if usage["times_used"] < effects.get("uses_per_day", 1):
				usage["times_used"] += 1
				perk_usage[perk_id] = usage
				perk_triggered.emit(perk_id, {"action": "reroll", "skill": skill_name})
				print("[PerkSystem] Used reroll from %s for %s" % [perk_id, skill_name])
				return true
	return false


func can_use_money_talks() -> bool:
	"""Check if Money Talks can be used"""
	if not has_perk("money_talks"):
		return false
	var usage: Dictionary = perk_usage.get("money_talks", {})
	return usage.get("times_used", 0) < 1 and SkillSystem.get_skill("kapital") >= 2


func use_money_talks() -> bool:
	"""Use Money Talks to auto-succeed"""
	if not can_use_money_talks():
		return false

	perk_usage["money_talks"]["times_used"] = 1
	SkillSystem.add_modifier("kapital", -2)  # Cost
	perk_triggered.emit("money_talks", {"action": "auto_succeed"})
	print("[PerkSystem] Used Money Talks!")
	return true


func can_use_viral_moment() -> bool:
	"""Check if Viral Moment can be used"""
	if not has_perk("viral_moment"):
		return false
	var usage: Dictionary = perk_usage.get("viral_moment", {})
	return usage.get("times_used", 0) < 1


func use_viral_moment() -> bool:
	"""Use Viral Moment to force critical success"""
	if not can_use_viral_moment():
		return false

	perk_usage["viral_moment"]["times_used"] = 1
	perk_triggered.emit("viral_moment", {"action": "force_crit"})
	print("[PerkSystem] Used Viral Moment!")
	return true


func can_use_wildcard() -> bool:
	"""Check if Wildcard can be used"""
	if not has_perk("wildcard_play"):
		return false
	var usage: Dictionary = perk_usage.get("wildcard_play", {})
	return usage.get("times_used", 0) < 1


func use_wildcard() -> Dictionary:
	"""Use Wildcard - 50/50 crit success or crit failure"""
	if not can_use_wildcard():
		return {"used": false}

	perk_usage["wildcard_play"]["times_used"] = 1
	var is_success := randf() > 0.5
	var result := {"used": true, "crit_success": is_success, "crit_failure": not is_success}
	perk_triggered.emit("wildcard_play", result)
	print("[PerkSystem] Used Wildcard! Result: %s" % ("CRIT SUCCESS" if is_success else "CRIT FAILURE"))
	return result


# ═══════════════════════════════════════════════════════════════════════════════
# PERK CATEGORIES & UI HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

func get_perks_by_category(category: String) -> Array[String]:
	"""Get all perks in a category"""
	var result: Array[String] = []
	for perk_id in PERKS:
		if PERKS[perk_id].get("category", "") == category:
			result.append(perk_id)
	return result


func get_all_categories() -> Array[String]:
	var categories: Array[String] = ["speechcraft", "kapital", "influence", "legitimacy", "logic", "wildcard"]
	return categories


func get_perk_requirement_text(perk_id: String) -> String:
	"""Get human-readable requirement text"""
	var perk: Dictionary = PERKS.get(perk_id, {})
	var requires: Dictionary = perk.get("requires", {})

	if requires.is_empty():
		return "No requirements"

	var parts: Array[String] = []
	for skill_name in requires:
		parts.append("%s %d+" % [SkillSystem.get_skill_display_name(skill_name), requires[skill_name]])

	return ", ".join(parts)


func get_slots_remaining() -> int:
	"""Get number of perk slots still available"""
	return perk_slots - active_perks.size()


func add_perk_slot() -> void:
	"""Add an additional perk slot (from gameplay rewards)"""
	if perk_slots < MAX_PERKS:
		perk_slots += 1
		print("[PerkSystem] Added perk slot. Now have %d slots" % perk_slots)
