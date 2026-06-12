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
var play_mode: String = "quick"  # quick | campaign
var campaign_scenario_id: String = ""

# Player info
var player_name: String = "Candidate"
var campaign_slogan: String = ""

# Tracking systems
var promises_made: Array[Dictionary] = []
var promises_broken: Array[Dictionary] = []
var promise_contradictions: Array[Dictionary] = []  # Detected contradictions
var scandals: Array[Dictionary] = []
var scandal_risks: Array[Dictionary] = []
var endorsements: Array[String] = []
var run_flags: Dictionary = {}
var event_log: Array[Dictionary] = []

# Promise contradiction pairs: if both IDs exist, they contradict
# Each entry: [promise_id_pattern_a, promise_id_pattern_b, description]
const CONTRADICTION_PAIRS := [
	["build", "cut_spending", "Promised to build things AND cut spending"],
	["lower_taxes", "increase_funding", "Promised lower taxes AND more funding"],
	["tough_on_crime", "defund", "Promised tough on crime AND defunding"],
	["preserve", "develop", "Promised preservation AND development"],
	["transparency", "backroom", "Promised transparency AND made backroom deals"],
	["clean_campaign", "attack", "Promised clean campaign AND attacked opponent"],
	["protect_environment", "deregulate", "Promised environmental protection AND deregulation"],
	["support_workers",  "corporate", "Promised worker support AND corporate backing"],
]

# Trust Systems (dual-layer)
# NPC Trust: Individual relationships with key characters
var npc_trust: Dictionary = {}  # npc_id -> { "trust": int, "influence": int, "name": String }
# District Support: Overall popularity in the district (affected by public actions)
var district_support: int = 0
var district_support_history: Array[Dictionary] = []  # Track changes with sources

# District info (generated per run)
var district_name: String = ""
var district_theme: String = ""
var main_crisis: String = ""
var opponent_name: String = ""
var opponent_archetype: String = ""
var media_bias: float = 0.0  # -1 (hostile) to 1 (friendly)

# Hidden Parameters (not shown to player, only in debug)
# These are external factors that influence the election
var hidden_params: Dictionary = {}


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
	promise_contradictions.clear()
	scandals.clear()
	scandal_risks.clear()
	endorsements.clear()
	run_flags.clear()
	event_log.clear()

	# Reset trust systems
	npc_trust.clear()
	district_support = 0
	district_support_history.clear()
	hidden_params.clear()

	# Generate district and hidden parameters
	_generate_district()
	_generate_hidden_params()

	# Reset other systems
	SkillSystem.reset_skills()
	PerkSystem.reset()
	NewsSystem.clear_news()
	if ContentLoader:
		ContentLoader.reset_run_state()

	current_phase = GamePhase.PLAYING
	game_started.emit()

	print("[GameManager] New game started with seed: %d" % run_seed)
	# Note: Day 1 is character creation. advance_day() is called when player clicks Start.


func apply_campaign_profile(profile: Dictionary) -> void:
	"""Override generated district/opponent/crisis with scripted campaign profile."""
	if profile.has("district_name"):
		district_name = String(profile.get("district_name", district_name))
	if profile.has("district_theme"):
		district_theme = String(profile.get("district_theme", district_theme))
	if profile.has("main_crisis"):
		main_crisis = String(profile.get("main_crisis", main_crisis))
	if profile.has("opponent_name"):
		opponent_name = String(profile.get("opponent_name", opponent_name))
	if profile.has("opponent_archetype"):
		opponent_archetype = String(profile.get("opponent_archetype", opponent_archetype))

	for flag_name in profile.get("scripted_flags", []):
		set_run_flag(String(flag_name), true)


func _apply_campaign_start_modifiers() -> void:
	"""Apply scenario gag modifiers (skill mods, starting support) when the
	run actually begins (Day 1 -> Day 2)."""
	if play_mode != "campaign" or campaign_scenario_id == "":
		return
	var scenario: Dictionary = CampaignSystem.get_scenario(campaign_scenario_id)
	if scenario.is_empty():
		return
	var mods: Dictionary = scenario.get("modifiers", {})
	for stat in mods.get("skill_mods", {}):
		SkillSystem.add_modifier(String(stat), int(mods.skill_mods[stat]))
	var start_support := int(mods.get("start_support", 0))
	if start_support != 0:
		add_district_support(start_support, "local_conditions")



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


func _generate_hidden_params() -> void:
	"""Generate hidden parameters that affect the election.
	These are environmental/external factors not shown to the player."""

	# === WEATHER & TIMING ===
	var seasons := ["spring", "summer", "fall", "winter"]
	var election_weather := ["clear", "cloudy", "rainy", "stormy", "snowy", "heatwave"]
	var days_of_week := ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

	hidden_params["season"] = seasons[randi() % seasons.size()]
	hidden_params["election_weather"] = election_weather[randi() % election_weather.size()]
	hidden_params["election_day_of_week"] = days_of_week[randi() % days_of_week.size()]

	# Weather affects turnout (-15 to +10)
	var weather_turnout := {
		"clear": randf_range(5, 10),
		"cloudy": randf_range(0, 5),
		"rainy": randf_range(-10, -5),
		"stormy": randf_range(-15, -10),
		"snowy": randf_range(-12, -6),
		"heatwave": randf_range(-8, -3)
	}
	hidden_params["weather_turnout_modifier"] = weather_turnout.get(hidden_params["election_weather"], 0.0)

	# Weekend elections have different turnout
	var weekend_modifier := 5.0 if hidden_params["election_day_of_week"] in ["saturday", "sunday"] else 0.0
	hidden_params["weekend_modifier"] = weekend_modifier

	# === ECONOMIC CLIMATE ===
	var economic_states := ["recession", "stagnant", "stable", "growing", "booming"]
	hidden_params["economy"] = economic_states[randi() % economic_states.size()]

	# Economy affects incumbent sentiment
	var economy_incumbent := {
		"recession": randf_range(-15, -8),    # Voters want change
		"stagnant": randf_range(-8, -3),
		"stable": randf_range(-2, 5),
		"growing": randf_range(3, 10),
		"booming": randf_range(8, 15)         # Status quo is fine
	}
	hidden_params["economy_modifier"] = economy_incumbent.get(hidden_params["economy"], 0.0)

	# === NATIONAL POLITICAL MOOD ===
	var national_moods := ["anti_establishment", "polarized", "apathetic", "engaged", "angry", "hopeful"]
	hidden_params["national_mood"] = national_moods[randi() % national_moods.size()]

	# Mood affects different playstyles
	hidden_params["mood_legitimacy_bonus"] = 0.0
	hidden_params["mood_speechcraft_bonus"] = 0.0
	hidden_params["mood_kapital_penalty"] = 0.0

	match hidden_params["national_mood"]:
		"anti_establishment":
			hidden_params["mood_legitimacy_bonus"] = randf_range(-10, -5)  # Credentials hurt
			hidden_params["mood_speechcraft_bonus"] = randf_range(3, 8)    # Populism helps
		"polarized":
			hidden_params["mood_speechcraft_bonus"] = randf_range(-5, 5)   # Risky either way
		"apathetic":
			hidden_params["mood_kapital_penalty"] = randf_range(5, 10)     # Money buys attention
		"engaged":
			hidden_params["mood_legitimacy_bonus"] = randf_range(3, 8)     # Voters do research
		"angry":
			hidden_params["mood_speechcraft_bonus"] = randf_range(5, 12)   # Emotion wins
			hidden_params["mood_kapital_penalty"] = randf_range(-8, -3)    # Money looks bad
		"hopeful":
			hidden_params["mood_legitimacy_bonus"] = randf_range(2, 6)

	# === DISTRICT DEMOGRAPHICS ===
	hidden_params["voter_turnout_base"] = randf_range(35, 75)  # Base turnout percentage
	hidden_params["youth_population"] = randf_range(0.1, 0.35)  # 10-35% young voters
	hidden_params["elderly_population"] = randf_range(0.1, 0.35)
	hidden_params["college_educated"] = randf_range(0.2, 0.6)
	hidden_params["homeowner_rate"] = randf_range(0.3, 0.8)
	hidden_params["union_membership"] = randf_range(0.05, 0.35)

	# === LOCAL FACTORS ===
	var local_events := [
		{"event": "none", "modifier": 0},
		{"event": "sports_team_won", "modifier": randf_range(2, 5)},
		{"event": "sports_team_lost", "modifier": randf_range(-3, -1)},
		{"event": "factory_closing", "modifier": randf_range(-8, -3)},
		{"event": "new_business_opened", "modifier": randf_range(1, 4)},
		{"event": "local_hero_died", "modifier": randf_range(-5, 5)},  # Depends on politics
		{"event": "festival_week", "modifier": randf_range(3, 7)},
		{"event": "crime_spike", "modifier": randf_range(-6, -2)},
		{"event": "school_achievement", "modifier": randf_range(1, 3)},
		{"event": "infrastructure_failure", "modifier": randf_range(-7, -3)},
		{"event": "local_scandal_unrelated", "modifier": randf_range(-2, 2)},
	]
	var local_event: Dictionary = local_events[randi() % local_events.size()]
	hidden_params["local_event"] = local_event["event"]
	hidden_params["local_event_modifier"] = local_event["modifier"]

	# === OPPONENT HIDDEN STATS ===
	hidden_params["opponent_war_chest"] = randi_range(10000, 100000)  # Their campaign funds
	hidden_params["opponent_name_recognition"] = randf_range(0.2, 0.8)  # How well known
	hidden_params["opponent_skeletons"] = randi_range(0, 3)  # Scandals waiting to drop
	hidden_params["opponent_ground_game"] = randf_range(0.3, 0.9)  # Volunteer strength
	hidden_params["opponent_party_support"] = randf_range(0.2, 1.0)  # Backing from party

	# Opponent effectiveness based on archetype
	var archetype_bonuses := {
		"The Machine Politician": {"kapital": 10, "influence": 5, "legitimacy": -5},
		"The Failson": {"kapital": 15, "legitimacy": -10, "speechcraft": -5},
		"The True Believer": {"legitimacy": 10, "speechcraft": 5, "kapital": -10},
		"The Celebrity": {"influence": 15, "speechcraft": 5, "legitimacy": -8}
	}
	hidden_params["opponent_archetype_bonus"] = archetype_bonuses.get(opponent_archetype, {})

	# === MEDIA LANDSCAPE ===
	hidden_params["local_paper_exists"] = randf() > 0.3  # 70% chance of local paper
	hidden_params["local_paper_bias"] = randf_range(-0.5, 0.5) if hidden_params["local_paper_exists"] else 0.0
	hidden_params["social_media_engagement"] = randf_range(0.1, 0.6)  # How online is district
	hidden_params["tv_market_size"] = ["small", "medium", "large"][randi() % 3]
	hidden_params["national_media_attention"] = randf() < 0.15  # 15% chance race gets noticed

	# === HISTORICAL VOTING PATTERNS ===
	hidden_params["incumbent_advantage"] = randf_range(3, 12)  # Bonus for being in power
	hidden_params["anti_incumbent_wave"] = randf() < 0.25  # 25% chance of "throw bums out"
	hidden_params["last_election_margin"] = randf_range(-20, 20)  # How close was it last time
	hidden_params["voter_fatigue"] = randf_range(0, 0.15)  # Recent elections = tired voters

	# === WILD CARDS (rare events) ===
	hidden_params["october_surprise_chance"] = randf_range(0.05, 0.2)  # Late scandal/event
	hidden_params["endorsement_jackpot"] = randf() < 0.1  # 10% chance of surprise big endorsement
	hidden_params["opponent_gaffe_prone"] = randf() < 0.2  # 20% chance opponent screws up

	# === CALCULATE NET HIDDEN MODIFIER ===
	# This is the total swing from hidden factors
	var net_modifier := 0.0
	net_modifier += hidden_params["weather_turnout_modifier"]
	net_modifier += hidden_params["weekend_modifier"]
	net_modifier += hidden_params["economy_modifier"] * 0.3  # Scaled down
	net_modifier += hidden_params["local_event_modifier"]
	net_modifier += hidden_params["mood_legitimacy_bonus"] * 0.2
	net_modifier += hidden_params["mood_speechcraft_bonus"] * 0.2

	if hidden_params["anti_incumbent_wave"]:
		net_modifier += randf_range(-8, -3)  # Helps challengers

	hidden_params["net_hidden_modifier"] = net_modifier

	print("[GameManager] Hidden params generated. Net modifier: %.1f" % net_modifier)


func advance_day() -> void:
	"""Move to the next day"""
	if current_day >= MAX_DAYS:
		end_game()
		return

	# Apply perk game start effects when leaving character creation (Day 1 -> Day 2)
	if current_day == 1:
		PerkSystem.apply_game_start_effects()
		_apply_campaign_start_modifiers()

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

	# Check for contradictions with existing promises
	_check_promise_contradictions(promise)


func _check_promise_contradictions(new_promise: Dictionary) -> void:
	"""Check if a new promise contradicts any existing promises"""
	var new_id: String = new_promise.get("id", "").to_lower()
	if new_id == "":
		return

	for existing in promises_made:
		if existing == new_promise:
			continue
		var existing_id: String = existing.get("id", "").to_lower()
		if existing_id == "":
			continue

		for pair in CONTRADICTION_PAIRS:
			var pattern_a: String = pair[0]
			var pattern_b: String = pair[1]
			var description: String = pair[2]

			var match_found := false
			if new_id.contains(pattern_a) and existing_id.contains(pattern_b):
				match_found = true
			elif new_id.contains(pattern_b) and existing_id.contains(pattern_a):
				match_found = true

			if match_found:
				var contradiction := {
					"promise_a": existing.get("text", existing_id),
					"promise_b": new_promise.get("text", new_id),
					"promise_a_id": existing_id,
					"promise_b_id": new_id,
					"description": description,
					"day_detected": current_day
				}
				promise_contradictions.append(contradiction)
				log_event("contradiction_detected", contradiction)
				print("[GameManager] CONTRADICTION: %s" % description)


func get_contradictions() -> Array[Dictionary]:
	"""Get all detected promise contradictions (used by debate and endgame)"""
	return promise_contradictions


func has_contradictions() -> bool:
	"""Check if player has any contradictions"""
	return not promise_contradictions.is_empty()


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


func modify_npc_trust(npc_id: String, amount: int, npc_name: String = "", influence: int = 10) -> void:
	"""Modify trust with a specific NPC.
	influence: How much this NPC affects district support (0-100). Key figures = 50+, regular voters = 10"""
	if not npc_trust.has(npc_id):
		npc_trust[npc_id] = {
			"trust": 0,
			"influence": influence,
			"name": npc_name if npc_name != "" else npc_id
		}

	var npc_data: Dictionary = npc_trust[npc_id]
	var old_trust: int = npc_data.trust
	npc_data.trust = clampi(npc_data.trust + amount, -100, 100)

	# Update influence/name if provided
	if npc_name != "":
		npc_data.name = npc_name
	if influence > npc_data.influence:
		npc_data.influence = influence

	log_event("npc_trust_changed", {
		"npc_id": npc_id,
		"npc_name": npc_data.name,
		"amount": amount,
		"old_trust": old_trust,
		"new_trust": npc_data.trust,
		"influence": npc_data.influence,
		"day": current_day
	})


func get_npc_trust(npc_id: String) -> int:
	"""Get trust level with an NPC"""
	if npc_trust.has(npc_id):
		return npc_trust[npc_id].trust
	return 0


func get_npc_influence(npc_id: String) -> int:
	"""Get influence level of an NPC (how much they sway district opinion)"""
	if npc_trust.has(npc_id):
		return npc_trust[npc_id].influence
	return 10  # Default influence


func get_npc_data(npc_id: String) -> Dictionary:
	"""Get full NPC trust data"""
	return npc_trust.get(npc_id, {"trust": 0, "influence": 10, "name": npc_id})


func add_district_support(amount: int, source: String = "unknown") -> void:
	"""Modify global district support.
	source: What caused this change (for tracking/explainability)"""
	var old_support := district_support
	district_support = clampi(district_support + amount, -100, 100)

	# Track history for explainability
	district_support_history.append({
		"day": current_day,
		"amount": amount,
		"source": source,
		"old_value": old_support,
		"new_value": district_support
	})

	log_event("district_support_changed", {
		"amount": amount,
		"source": source,
		"old_value": old_support,
		"new_value": district_support,
		"day": current_day
	})


func get_district_support_breakdown() -> Dictionary:
	"""Get breakdown of what contributed to district support"""
	var breakdown := {}
	for entry in district_support_history:
		var source: String = entry.source
		if not breakdown.has(source):
			breakdown[source] = 0
		breakdown[source] += entry.amount
	return breakdown


func get_weighted_npc_support() -> float:
	"""Calculate NPC trust weighted by influence.
	High-influence NPCs (union leaders, media, etc.) count more."""
	if npc_trust.is_empty():
		return 0.0

	var weighted_sum := 0.0
	var influence_sum := 0.0

	for npc_id in npc_trust:
		var data: Dictionary = npc_trust[npc_id]
		var trust: float = float(data.trust)
		var influence: float = float(data.influence)
		weighted_sum += trust * influence
		influence_sum += influence

	if influence_sum == 0:
		return 0.0

	return weighted_sum / influence_sum


func get_total_support() -> float:
	"""Get combined support score (district + weighted NPC).
	This is what matters for the election."""
	var npc_contribution := get_weighted_npc_support() * 0.4  # NPCs = 40%
	var district_contribution := float(district_support) * 0.6  # District = 60%
	return npc_contribution + district_contribution


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
		"factors": {},
		"npc_breakdown": {},
		"district_breakdown": {},
		"hidden_factors": {}  # Only shown in debug
	}

	# Base support from skills
	var base_support := 0.0
	base_support += SkillSystem.get_skill("speechcraft") * 2.0
	base_support += SkillSystem.get_skill("influence") * 3.0
	base_support += SkillSystem.get_skill("legitimacy") * 2.5
	base_support += SkillSystem.get_skill("kapital") * 1.5
	results.factors["skill_support"] = base_support

	# NPC trust (weighted by influence)
	var weighted_npc := get_weighted_npc_support()
	results.factors["npc_trust"] = weighted_npc

	# Store individual NPC contributions for explainability
	for npc_id in npc_trust:
		var data: Dictionary = npc_trust[npc_id]
		results.npc_breakdown[data.name] = {
			"trust": data.trust,
			"influence": data.influence
		}

	# District support
	results.factors["district_support"] = float(district_support)
	results.district_breakdown = get_district_support_breakdown()

	# Promises impact
	var promise_factor := promises_made.size() * 5 - promises_broken.size() * 15
	results.factors["promises"] = promise_factor

	# Scandals hurt
	var scandal_factor := -scandals.size() * 20
	results.factors["scandals"] = scandal_factor

	# Endorsements help
	var endorsement_factor := endorsements.size() * 10
	results.factors["endorsements"] = endorsement_factor

	# Logic consistency bonus (staying consistent matters)
	var logic_bonus := SkillSystem.get_skill("logic") * 2.0

	# Contradictions penalize logic bonus
	var contradiction_penalty := promise_contradictions.size() * -8
	logic_bonus += contradiction_penalty
	results.factors["logic"] = logic_bonus
	if contradiction_penalty < 0:
		results.factors["contradictions"] = contradiction_penalty

	# Combined trust score (NPC + District weighted)
	var combined_trust := get_total_support()
	results.factors["combined_trust"] = combined_trust

	# === HIDDEN FACTORS (not shown to player) ===
	var hidden_modifier := 0.0

	# Weather & timing effects
	hidden_modifier += hidden_params.get("weather_turnout_modifier", 0.0)
	hidden_modifier += hidden_params.get("weekend_modifier", 0.0)
	results.hidden_factors["weather"] = hidden_params.get("election_weather", "unknown")
	results.hidden_factors["weather_effect"] = hidden_params.get("weather_turnout_modifier", 0.0)

	# Economic climate
	var economy_effect: float = hidden_params.get("economy_modifier", 0.0) * 0.4
	hidden_modifier += economy_effect
	results.hidden_factors["economy"] = hidden_params.get("economy", "unknown")
	results.hidden_factors["economy_effect"] = economy_effect

	# National mood affects skill effectiveness
	var mood: String = hidden_params.get("national_mood", "stable")
	var mood_effect := 0.0
	mood_effect += hidden_params.get("mood_legitimacy_bonus", 0.0) * (SkillSystem.get_skill("legitimacy") / 10.0)
	mood_effect += hidden_params.get("mood_speechcraft_bonus", 0.0) * (SkillSystem.get_skill("speechcraft") / 10.0)
	mood_effect += hidden_params.get("mood_kapital_penalty", 0.0) * (SkillSystem.get_skill("kapital") / 10.0)
	hidden_modifier += mood_effect * 0.3
	results.hidden_factors["national_mood"] = mood
	results.hidden_factors["mood_effect"] = mood_effect * 0.3

	# Local event impact
	hidden_modifier += hidden_params.get("local_event_modifier", 0.0)
	results.hidden_factors["local_event"] = hidden_params.get("local_event", "none")
	results.hidden_factors["local_event_effect"] = hidden_params.get("local_event_modifier", 0.0)

	# Anti-incumbent wave (we're the challenger)
	if hidden_params.get("anti_incumbent_wave", false):
		var wave_bonus := randf_range(5, 12)
		hidden_modifier += wave_bonus
		results.hidden_factors["anti_incumbent_wave"] = wave_bonus
	else:
		results.hidden_factors["anti_incumbent_wave"] = 0.0

	# Opponent strength (works against us)
	var opponent_strength := 0.0
	opponent_strength += hidden_params.get("opponent_name_recognition", 0.5) * 8
	opponent_strength += hidden_params.get("opponent_ground_game", 0.5) * 6
	opponent_strength += hidden_params.get("opponent_party_support", 0.5) * 5
	hidden_modifier -= opponent_strength * 0.3  # Opponent factors work against us
	results.hidden_factors["opponent_strength"] = opponent_strength * 0.3

	# October surprise chance (late game event)
	if randf() < hidden_params.get("october_surprise_chance", 0.1):
		var surprise := randf_range(-15, 15)  # Could help or hurt
		hidden_modifier += surprise
		results.hidden_factors["october_surprise"] = surprise
	else:
		results.hidden_factors["october_surprise"] = 0.0

	# Endorsement jackpot (rare big boost)
	if hidden_params.get("endorsement_jackpot", false) and endorsements.size() > 0:
		hidden_modifier += randf_range(5, 10)
		results.hidden_factors["endorsement_jackpot"] = true

	# Opponent gaffe (if they're prone and we're ahead, they might stumble)
	if hidden_params.get("opponent_gaffe_prone", false) and combined_trust > 20:
		var gaffe_bonus := randf_range(3, 8)
		hidden_modifier += gaffe_bonus
		results.hidden_factors["opponent_gaffe"] = gaffe_bonus

	results.hidden_factors["net_hidden_modifier"] = hidden_modifier

	# Calculate total
	var total_support: float = base_support
	total_support += combined_trust * 0.5  # Trust accounts for ~50% of swing
	total_support += float(promise_factor)
	total_support += float(scandal_factor)
	total_support += float(endorsement_factor)
	total_support += logic_bonus
	total_support += hidden_modifier  # Hidden factors now included

	# Add some randomness (media, remaining uncertainty)
	total_support += randf_range(-5, 5) + (media_bias * 15)

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


func get_hidden_params_debug() -> Dictionary:
	"""Get hidden parameters formatted for debug display.
	This should ONLY be shown in debug/dev mode, never to players."""
	return {
		"environment": {
			"season": hidden_params.get("season", "unknown"),
			"election_weather": hidden_params.get("election_weather", "unknown"),
			"election_day": hidden_params.get("election_day_of_week", "unknown"),
			"weather_modifier": hidden_params.get("weather_turnout_modifier", 0.0),
		},
		"economy": {
			"state": hidden_params.get("economy", "unknown"),
			"modifier": hidden_params.get("economy_modifier", 0.0),
		},
		"national_mood": {
			"mood": hidden_params.get("national_mood", "unknown"),
			"legitimacy_effect": hidden_params.get("mood_legitimacy_bonus", 0.0),
			"speechcraft_effect": hidden_params.get("mood_speechcraft_bonus", 0.0),
			"kapital_effect": hidden_params.get("mood_kapital_penalty", 0.0),
		},
		"demographics": {
			"base_turnout": hidden_params.get("voter_turnout_base", 50.0),
			"youth_pct": hidden_params.get("youth_population", 0.2),
			"elderly_pct": hidden_params.get("elderly_population", 0.2),
			"college_educated": hidden_params.get("college_educated", 0.4),
			"homeowners": hidden_params.get("homeowner_rate", 0.5),
			"union_members": hidden_params.get("union_membership", 0.15),
		},
		"local_factors": {
			"event": hidden_params.get("local_event", "none"),
			"event_modifier": hidden_params.get("local_event_modifier", 0.0),
		},
		"opponent": {
			"war_chest": hidden_params.get("opponent_war_chest", 50000),
			"name_recognition": hidden_params.get("opponent_name_recognition", 0.5),
			"skeletons": hidden_params.get("opponent_skeletons", 0),
			"ground_game": hidden_params.get("opponent_ground_game", 0.5),
			"party_support": hidden_params.get("opponent_party_support", 0.5),
			"archetype_bonus": hidden_params.get("opponent_archetype_bonus", {}),
			"gaffe_prone": hidden_params.get("opponent_gaffe_prone", false),
		},
		"media": {
			"local_paper_exists": hidden_params.get("local_paper_exists", false),
			"local_paper_bias": hidden_params.get("local_paper_bias", 0.0),
			"social_media_engagement": hidden_params.get("social_media_engagement", 0.3),
			"tv_market": hidden_params.get("tv_market_size", "small"),
			"national_attention": hidden_params.get("national_media_attention", false),
		},
		"historical": {
			"incumbent_advantage": hidden_params.get("incumbent_advantage", 5.0),
			"anti_incumbent_wave": hidden_params.get("anti_incumbent_wave", false),
			"last_margin": hidden_params.get("last_election_margin", 0.0),
			"voter_fatigue": hidden_params.get("voter_fatigue", 0.0),
		},
		"wildcards": {
			"october_surprise_chance": hidden_params.get("october_surprise_chance", 0.1),
			"endorsement_jackpot": hidden_params.get("endorsement_jackpot", false),
		},
		"net_modifier": hidden_params.get("net_hidden_modifier", 0.0),
	}


func apply_effects(effects: Array, context: Dictionary = {}) -> void:
	"""Apply standardized effect ops.
	Context can include: npc_id, npc_name, npc_influence, source, dialogue_flags"""
	var npc_id: String = context.get("npc_id", "")
	var npc_name: String = context.get("npc_name", "")
	var npc_influence: int = context.get("npc_influence", 10)
	var source: String = context.get("source", "choice")
	var apply_dialogue_flags: bool = context.get("dialogue_flags", false)

	for effect in effects:
		var op: String = effect.get("op", "")
		match op:
			"stat_add":
				SkillSystem.add_modifier(effect.get("stat", ""), int(effect.get("amount", 0)))
			"trust_add":
				if npc_id != "":
					# Allow effect to override NPC metadata
					var eff_name: String = effect.get("npc_name", npc_name)
					var eff_influence: int = effect.get("influence", npc_influence)
					modify_npc_trust(npc_id, int(effect.get("amount", 0)), eff_name, eff_influence)
			"district_support_add":
				# Allow effect to specify source, otherwise use context
				var eff_source: String = effect.get("source", source)
				add_district_support(int(effect.get("amount", 0)), eff_source)
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


func export_state() -> Dictionary:
	"""Serialize current game manager state for save slots."""
	return {
		"current_day": current_day,
		"current_phase": int(current_phase),
		"run_seed": run_seed,
		"play_mode": play_mode,
		"campaign_scenario_id": campaign_scenario_id,
		"player_name": player_name,
		"campaign_slogan": campaign_slogan,
		"promises_made": promises_made,
		"promises_broken": promises_broken,
		"promise_contradictions": promise_contradictions,
		"scandals": scandals,
		"scandal_risks": scandal_risks,
		"endorsements": endorsements,
		"run_flags": run_flags,
		"event_log": event_log,
		"npc_trust": npc_trust,
		"district_support": district_support,
		"district_support_history": district_support_history,
		"district_name": district_name,
		"district_theme": district_theme,
		"main_crisis": main_crisis,
		"opponent_name": opponent_name,
		"opponent_archetype": opponent_archetype,
		"media_bias": media_bias,
		"hidden_params": hidden_params,
	}


func import_state(data: Dictionary) -> void:
	"""Hydrate game manager from a saved dictionary."""
	current_day = int(data.get("current_day", 1))
	current_phase = int(data.get("current_phase", GamePhase.PLAYING)) as GamePhase
	run_seed = int(data.get("run_seed", 1))
	seed(run_seed)
	play_mode = String(data.get("play_mode", "quick"))
	campaign_scenario_id = String(data.get("campaign_scenario_id", ""))
	player_name = String(data.get("player_name", "Candidate"))
	campaign_slogan = String(data.get("campaign_slogan", ""))
	promises_made.assign(data.get("promises_made", []))
	promises_broken.assign(data.get("promises_broken", []))
	promise_contradictions.assign(data.get("promise_contradictions", []))
	scandals.assign(data.get("scandals", []))
	scandal_risks.assign(data.get("scandal_risks", []))
	endorsements.assign(data.get("endorsements", []))
	run_flags = data.get("run_flags", {})
	event_log.assign(data.get("event_log", []))
	npc_trust = data.get("npc_trust", {})
	district_support = int(data.get("district_support", 0))
	district_support_history.assign(data.get("district_support_history", []))
	district_name = String(data.get("district_name", ""))
	district_theme = String(data.get("district_theme", ""))
	main_crisis = String(data.get("main_crisis", ""))
	opponent_name = String(data.get("opponent_name", ""))
	opponent_archetype = String(data.get("opponent_archetype", ""))
	media_bias = float(data.get("media_bias", 0.0))
	hidden_params = data.get("hidden_params", {})
