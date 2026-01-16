extends Node

## GameManager - Central game state controller
## Handles day progression, game flow, and global state

signal day_changed(day: int)
signal game_started()
signal game_ended(won: bool, results: Dictionary)
signal phase_changed(phase: String)

enum GamePhase { MENU, PLAYING, NEWS, DEBATE, RESULTS }

const MAX_DAYS := 7
const DAY_NAMES := [
	"",  # Index 0 unused
	"Day 1 - Registration",
	"Day 2 - Canvassing",
	"Day 3 - Posters",
	"Day 4 - Fundraiser",
	"Day 5 - Town Event",
	"Day 6 - Debate",
	"Day 7 - Results"
]

# Current game state
var current_day: int = 0
var current_phase: GamePhase = GamePhase.MENU
var run_seed: int = 0

# Player info
var player_name: String = "Candidate"
var campaign_slogan: String = ""

# Tracking systems
var promises_made: Array[Dictionary] = []
var promises_broken: Array[Dictionary] = []
var scandals: Array[Dictionary] = []
var scandal_risks: Array[Dictionary] = []
var endorsements: Array[String] = []
var npc_trust: Dictionary = {}  # npc_id -> trust value (-100 to 100)
var district_support: int = 0
var run_flags: Dictionary = {}
var event_log: Array[Dictionary] = []

# District info (generated per run)
var district_name: String = ""
var district_theme: String = ""
var main_crisis: String = ""
var opponent_name: String = ""
var opponent_archetype: String = ""
var media_bias: float = 0.0  # -1 (hostile) to 1 (friendly)


func _ready() -> void:
	print("[GameManager] Initialized")


func start_new_game(seed_value: int = 0) -> void:
	"""Start a new game run with optional seed"""
	if seed_value == 0:
		seed_value = randi()

	run_seed = seed_value
	seed(run_seed)

	# Reset state - Day 1 is character creation
	current_day = 1
	promises_made.clear()
	promises_broken.clear()
	scandals.clear()
	scandal_risks.clear()
	endorsements.clear()
	npc_trust.clear()
	district_support = 0
	run_flags.clear()
	event_log.clear()

	# Generate district
	_generate_district()

	# Reset other systems
	SkillSystem.reset_skills()
	NewsSystem.clear_news()
	if ContentLoader:
		ContentLoader.reset_run_state()

	current_phase = GamePhase.PLAYING
	game_started.emit()

	print("[GameManager] New game started with seed: %d" % run_seed)
	# Note: Day 1 is character creation. advance_day() is called when player clicks Start.



func _generate_district() -> void:
	"""Generate district details based on seed, using ContentLoader if available"""
	var themes := ["Industrial", "Suburban", "Downtown", "Rural", "Coastal", "University"]

	# Try to get crisis from ContentLoader
	if ContentLoader and ContentLoader.is_loaded and not ContentLoader.crises.is_empty():
		var crisis_data := ContentLoader.get_random_crisis()
		main_crisis = crisis_data.get("name", "Generic Crisis")
	else:
		var crises := ["The Rat Problem", "Gentrification", "The Bridge Problem", "The Pill Problem", "Bar Zoning Crisis"]
		main_crisis = crises[randi() % crises.size()]

	# Try to get opponent from ContentLoader
	if ContentLoader and ContentLoader.is_loaded and not ContentLoader.opponents.is_empty():
		var opponent_data := ContentLoader.get_random_opponent()
		opponent_name = "%s %s" % [opponent_data.get("name_first", "John"), opponent_data.get("name_last", "Doe")]
		opponent_archetype = opponent_data.get("archetype", "The Politician")
	else:
		var archetypes := ["The Machine Politician", "The Failson", "The True Believer", "The Celebrity"]
		opponent_archetype = archetypes[randi() % archetypes.size()]
		var first_names := ["Harvey", "Trent", "Sandra", "Chad"]
		var last_names := ["Wellman", "Worthington", "Flippman", "Thunderson"]
		opponent_name = "%s %s" % [first_names[randi() % first_names.size()], last_names[randi() % last_names.size()]]

	district_theme = themes[randi() % themes.size()]

	# Generate district name
	var district_prefixes := ["North", "South", "East", "West", "New", "Old", "Greater"]
	var district_suffixes := ["Heights", "Valley", "Borough", "District", "Ward", "Commons"]
	district_name = "%s %s %s" % [district_prefixes[randi() % district_prefixes.size()], district_theme, district_suffixes[randi() % district_suffixes.size()]]

	media_bias = randf_range(-0.5, 0.5)

	print("[GameManager] District: %s, Crisis: %s, Opponent: %s (%s)" % [district_name, main_crisis, opponent_name, opponent_archetype])


func advance_day() -> void:
	"""Move to the next day"""
	if current_day >= MAX_DAYS:
		end_game()
		return

	current_day += 1
	day_changed.emit(current_day)
	print("[GameManager] Advanced to %s" % get_day_name())

	# Day 7 triggers results
	if current_day == MAX_DAYS:
		current_phase = GamePhase.RESULTS
		phase_changed.emit("results")


func get_day_name() -> String:
	"""Get the display name for current day"""
	if current_day >= 1 and current_day <= MAX_DAYS:
		return DAY_NAMES[current_day]
	return "Unknown Day"


func show_news() -> void:
	"""Transition to news phase between days"""
	current_phase = GamePhase.NEWS
	phase_changed.emit("news")


func end_news() -> void:
	"""Return from news to playing"""
	current_phase = GamePhase.PLAYING
	phase_changed.emit("playing")


func add_promise(promise: Dictionary) -> void:
	"""Track a promise made to an NPC or publicly"""
	if not promise.has("id"):
		promise.id = "promise_%d_%d" % [current_day, promises_made.size()]
	promises_made.append(promise)
	print("[GameManager] Promise made: %s" % promise.get("text", "Unknown"))
	log_event("promise_made", promise)


func break_promise(promise_index: int) -> void:
	"""Mark a promise as broken"""
	if promise_index < promises_made.size():
		var promise = promises_made[promise_index]
		promises_broken.append(promise)
		print("[GameManager] Promise broken: %s" % promise.get("text", "Unknown"))
		log_event("promise_broken", promise)


func add_scandal(scandal: Dictionary) -> void:
	"""Add a scandal to the player's record"""
	scandals.append(scandal)
	print("[GameManager] Scandal added: %s" % scandal.get("headline", "Unknown"))
	log_event("scandal_triggered", scandal)


func add_scandal_risk(scandal_risk: Dictionary) -> void:
	"""Track a scandal risk and resolve it immediately by chance"""
	scandal_risks.append(scandal_risk)
	log_event("scandal_risk_added", scandal_risk)

	var chance: float = float(scandal_risk.get("chance", 0.0))
	if chance > 0.0 and randf() < chance:
		var headline: String = scandal_risk.get("headline", "Campaign Scandal Breaks")
		add_scandal({"headline": headline, "day": current_day, "id": scandal_risk.get("id", "")})


func add_endorsement(endorser: String) -> void:
	"""Add an endorsement"""
	endorsements.append(endorser)
	print("[GameManager] Endorsement received: %s" % endorser)
	log_event("endorsement_gained", {"endorser": endorser, "day": current_day})


func modify_npc_trust(npc_id: String, amount: int) -> void:
	"""Modify trust with a specific NPC"""
	if not npc_trust.has(npc_id):
		npc_trust[npc_id] = 0
	npc_trust[npc_id] = clampi(npc_trust[npc_id] + amount, -100, 100)
	log_event("npc_trust_changed", {"npc_id": npc_id, "amount": amount, "day": current_day})


func get_npc_trust(npc_id: String) -> int:
	"""Get trust level with an NPC"""
	return npc_trust.get(npc_id, 0)


func add_district_support(amount: int) -> void:
	"""Modify global district support"""
	district_support = clampi(district_support + amount, -100, 100)
	log_event("district_support_changed", {"amount": amount, "day": current_day})


func set_run_flag(flag_name: String, value: bool = true) -> void:
	"""Set a global run flag"""
	run_flags[flag_name] = value
	log_event("flag_set", {"flag": flag_name, "value": value, "day": current_day})


func get_run_flag(flag_name: String) -> bool:
	"""Get a global run flag value"""
	return run_flags.get(flag_name, false)


func log_event(event_type: String, payload: Dictionary) -> void:
	"""Log structured events for news/endgame explainability"""
	var entry := {
		"type": event_type,
		"day": current_day,
		"payload": payload
	}
	event_log.append(entry)


func calculate_election_results() -> Dictionary:
	"""Calculate final election results based on all factors"""
	var results := {
		"won": false,
		"player_votes": 0,
		"opponent_votes": 0,
		"margin": 0.0,
		"factors": {}
	}

	# Base support from skills
	var base_support := 0.0
	base_support += SkillSystem.get_skill("speechcraft") * 2.0
	base_support += SkillSystem.get_skill("influence") * 3.0
	base_support += SkillSystem.get_skill("legitimacy") * 2.5
	base_support += SkillSystem.get_skill("kapital") * 1.5
	results.factors["skill_support"] = base_support

	# NPC trust average
	var trust_sum: int = 0
	for trust in npc_trust.values():
		trust_sum += int(trust)
	var avg_trust: float = float(trust_sum) / max(npc_trust.size(), 1)
	results.factors["npc_trust"] = avg_trust

	# District support
	results.factors["district_support"] = float(district_support)

	# Promises impact
	var promise_factor := promises_made.size() * 5 - promises_broken.size() * 15
	results.factors["promises"] = promise_factor

	# Scandals hurt
	var scandal_factor := -scandals.size() * 20
	results.factors["scandals"] = scandal_factor

	# Endorsements help
	var endorsement_factor := endorsements.size() * 10
	results.factors["endorsements"] = endorsement_factor

	# Logic consistency
	var logic_bonus := SkillSystem.get_skill("logic") * 2.0
	results.factors["logic"] = logic_bonus

	# Calculate total
	var total_support: float = base_support + avg_trust + float(promise_factor) + float(scandal_factor) + float(endorsement_factor) + logic_bonus
	total_support += float(district_support) * 0.5

	# Add some randomness (media, turnout, etc)
	total_support += randf_range(-10, 10) + (media_bias * 15)

	# Convert to vote percentages (opponent has base 45%)
	var player_percent := clampf(45 + total_support / 10.0, 10, 90)
	var opponent_percent := 100 - player_percent

	results.player_votes = int(player_percent * 1000)
	results.opponent_votes = int(opponent_percent * 1000)
	results.margin = player_percent - opponent_percent
	results.won = player_percent > 50

	return results


func end_game() -> void:
	"""End the current game run"""
	var results := calculate_election_results()
	current_phase = GamePhase.MENU
	game_ended.emit(results.won, results)
	print("[GameManager] Game ended - Won: %s" % results.won)


func apply_effects(effects: Array, context: Dictionary = {}) -> void:
	"""Apply standardized effect ops"""
	var npc_id: String = context.get("npc_id", "")
	var apply_dialogue_flags: bool = context.get("dialogue_flags", false)

	for effect in effects:
		var op: String = effect.get("op", "")
		match op:
			"stat_add":
				SkillSystem.add_modifier(effect.get("stat", ""), int(effect.get("amount", 0)))
			"trust_add":
				if npc_id != "":
					modify_npc_trust(npc_id, int(effect.get("amount", 0)))
			"district_support_add":
				add_district_support(int(effect.get("amount", 0)))
			"promise_add":
				add_promise({
					"id": effect.get("id", ""),
					"text": effect.get("text", ""),
					"npc_id": npc_id,
					"day": current_day
				})
			"endorsement_add":
				add_endorsement(effect.get("name", ""))
			"set_flag":
				set_run_flag(effect.get("flag", ""), true)
				if apply_dialogue_flags:
					DialogueSystem.set_flag(effect.get("flag", ""), true)
			"clear_flag":
				set_run_flag(effect.get("flag", ""), false)
				if apply_dialogue_flags:
					DialogueSystem.set_flag(effect.get("flag", ""), false)
			"scandal_add":
				add_scandal({
					"headline": effect.get("headline", ""),
					"day": current_day,
					"id": effect.get("id", "")
				})
			"scandal_risk_add":
				add_scandal_risk({
					"id": effect.get("id", ""),
					"chance": float(effect.get("chance", 0.0)),
					"headline": effect.get("headline", "Campaign Scandal Breaks"),
					"day": current_day
				})
			_:
				push_warning("[GameManager] Unknown effect op: %s" % op)


func return_to_menu() -> void:
	"""Return to main menu"""
	current_phase = GamePhase.MENU
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
