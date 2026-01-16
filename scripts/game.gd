extends Control

## Main Game Scene - Handles day activities and game loop
## "The Gang Runs For Office"
## Now loads content from scenario_maker.json via ContentLoader

@onready var day_label: Label = $TopBar/HBox/DayLabel
@onready var day_title: Label = $MainContent/ContentPanel/ContentMargin/ContentContainer/HeaderPanel/HeaderMargin/HeaderVBox/DayTitle
@onready var day_description: Label = $MainContent/ContentPanel/ContentMargin/ContentContainer/HeaderPanel/HeaderMargin/HeaderVBox/DayDescription
@onready var activity_text: RichTextLabel = $MainContent/ContentPanel/ContentMargin/ContentContainer/ActivityPanel/ActivityMargin/ActivityContent/ActivityText
@onready var choices_container: VBoxContainer = $MainContent/ContentPanel/ContentMargin/ContentContainer/ActivityPanel/ActivityMargin/ActivityContent/ChoicesContainer
@onready var status_label: Label = $BottomBar/HBox/StatusLabel
@onready var next_day_button: Button = $BottomBar/HBox/NextDayButton

# Skill display labels
@onready var speechcraft_label: Label = $TopBar/HBox/SkillsHBox/Speechcraft
@onready var kapital_label: Label = $TopBar/HBox/SkillsHBox/Kapital
@onready var influence_label: Label = $TopBar/HBox/SkillsHBox/Influence
@onready var legitimacy_label: Label = $TopBar/HBox/SkillsHBox/Legitimacy
@onready var logic_label: Label = $TopBar/HBox/SkillsHBox/Logic

# Day activity data
const DAY_ACTIVITIES := {
	2: {"title": "CANVASSING", "quote": "\"Say it to their face.\"", "description": "Time to meet the voters. They definitely want to hear from you."},
	3: {"title": "POSTERS", "quote": "\"How do you look from a distance?\"", "description": "Design your campaign materials. Make it memorable. Or don't."},
	4: {"title": "FUNDRAISER", "quote": "\"Who owns you?\"", "description": "Money doesn't grow on trees, but it does grow on moral flexibility."},
	5: {"title": "TOWN EVENT", "quote": "\"Perform in public.\"", "description": "A crowd has gathered. What could possibly go wrong?"},
	6: {"title": "THE DEBATE", "quote": "\"Everything comes due.\"", "description": "Face your opponent. All your contradictions are about to surface."},
	7: {"title": "ELECTION DAY", "quote": "\"The math doesn't care how you feel.\"", "description": "The votes are being counted. No take-backs."}
}

var current_choices: Array = []
var current_npc_id: String = ""
var debate_round: int = 1
var in_dialogue := false
var current_activity_type: String = ""
var current_activity_id: String = ""


func _ready() -> void:
	GameManager.day_changed.connect(_on_day_changed)
	GameManager.game_ended.connect(_on_game_ended)
	SkillSystem.skill_changed.connect(_on_skill_changed)
	DialogueSystem.dialogue_line.connect(_on_dialogue_line)
	DialogueSystem.choices_presented.connect(_on_choices_presented)
	DialogueSystem.dialogue_ended.connect(_on_dialogue_ended)

	_update_skill_display()
	_update_status_bar()
	_setup_day(GameManager.current_day)


func _on_day_changed(day: int) -> void:
	_setup_day(day)


func _setup_day(day: int) -> void:
	day_label.text = "► " + GameManager.get_day_name().to_upper()

	if day == 7:
		_show_results()
		return

	if DAY_ACTIVITIES.has(day):
		var activity: Dictionary = DAY_ACTIVITIES[day]
		day_title.text = "═══ %s ═══" % activity.title
		day_description.text = "%s\n%s" % [activity.quote, activity.description]
	else:
		day_title.text = "═══ DAY %d ═══" % day
		day_description.text = ""

	_clear_choices()
	_load_day_activity(day)

	next_day_button.text = "► END DAY" if day < 7 else "► SEE RESULTS"
	next_day_button.disabled = false


func _load_day_activity(day: int) -> void:
	match day:
		2: _start_canvassing()
		3: _start_poster_activity()
		4: _start_fundraiser()
		5: _start_town_event()
		6: _start_debate()
		_: activity_text.text = "Day %d activities..." % day


func _start_canvassing() -> void:
	"""Day 2 - Load canvassing scenario from ContentLoader"""
	var scenario := ContentLoader.get_random_scenario("canvassing", GameManager.current_day)

	if scenario.is_empty():
		activity_text.text = "[b]No one answers their doors today.[/b]\n\nMaybe try again tomorrow?"
		return

	current_activity_type = "canvassing"
	current_activity_id = scenario.get("id", "")
	current_npc_id = scenario.get("npc_id", "")
	activity_text.text = scenario.get("intro_text", "You knock on a door...")
	current_choices = scenario.get("choices", [])
	_show_choices(current_choices)


func _start_poster_activity() -> void:
	"""Day 3 - Load poster options from ContentLoader"""
	var posters := ContentLoader.get_posters()

	if posters.is_empty():
		activity_text.text = "[b]Your campaign manager shrugs.[/b]\n\n\"I got nothing. Just... draw something?\""
		return

	current_activity_type = "posters"
	current_activity_id = ""
	activity_text.text = "[b]Your campaign manager spreads out poster mockups.[/b]\n\n\"We need something that says 'vote for me' but also 'I might burn this whole thing down.' You know, relatable.\""

	current_choices = []
	for poster in posters:
		current_choices.append({
			"id": poster.get("id", ""),
			"text": poster.get("text", "Generic poster"),
			"effects": poster.get("effects", [])
		})

	_show_choices(current_choices)


func _start_fundraiser() -> void:
	"""Day 4 - Load fundraiser scenario from ContentLoader"""
	var scenario := ContentLoader.get_random_scenario("fundraisers", GameManager.current_day)

	if scenario.is_empty():
		activity_text.text = "[b]No one wants to give you money today.[/b]\n\nShocking, really."
		return

	current_activity_type = "fundraisers"
	current_activity_id = scenario.get("id", "")
	current_npc_id = scenario.get("npc_id", "")
	activity_text.text = scenario.get("intro_text", "Someone approaches with money...")
	current_choices = scenario.get("choices", [])
	_show_choices(current_choices)


func _start_town_event() -> void:
	"""Day 5 - Load town event from ContentLoader"""
	var scenario := ContentLoader.get_random_scenario("events", GameManager.current_day)

	if scenario.is_empty():
		activity_text.text = "[b]The town event was cancelled.[/b]\n\nSomething about a 'gas leak.' Sure."
		return

	current_activity_type = "events"
	current_activity_id = scenario.get("id", "")
	activity_text.text = scenario.get("intro_text", "You arrive at the event...")
	current_choices = scenario.get("choices", [])
	_show_choices(current_choices)


func _start_debate() -> void:
	"""Day 6 - Load debate round from ContentLoader"""
	var round_data := ContentLoader.get_debate_round(debate_round)

	if round_data.is_empty():
		activity_text.text = "[b]THE DEBATE STAGE[/b]\n\n%s stands across from you, smirking.\n\nThe moderator clears her throat: \"Let's begin.\"\n\nYour opponent speaks first: \"I'm normal. My opponent is not. Questions?\"" % GameManager.opponent_name
		current_activity_type = "debate_rounds"
		current_activity_id = ""
		current_choices = [
			{"text": "\"Define 'normal.'\" [Logic]", "skill_check": {"skill": "logic", "difficulty": 10}, "effects_on_success": [{"op": "stat_add", "stat": "logic", "amount": 2}, {"op": "stat_add", "stat": "influence", "amount": 2}], "effects_on_failure": [{"op": "stat_add", "stat": "influence", "amount": -1}]},
			{"text": "\"I HAVEN'T EVEN BEGUN TO PEAK!\" [Speechcraft]", "skill_check": {"skill": "speechcraft", "difficulty": 12}, "effects_on_success": [{"op": "stat_add", "stat": "speechcraft", "amount": 3}, {"op": "stat_add", "stat": "influence", "amount": 3}], "effects_on_failure": [{"op": "stat_add", "stat": "legitimacy", "amount": -2}, {"op": "scandal_add", "headline": "Candidate Screams About 'Peaking'"}]},
			{"text": "Challenge them to a contest of strength. [Legitimacy]", "skill_check": {"skill": "legitimacy", "difficulty": 11}, "effects_on_success": [{"op": "stat_add", "stat": "legitimacy", "amount": 2}, {"op": "stat_add", "stat": "influence", "amount": 2}], "effects_on_failure": [{"op": "scandal_add", "headline": "Debate Becomes Wrestling Match"}]},
			{"text": "Pull out a folder of 'evidence.' It's empty. [Influence]", "skill_check": {"skill": "influence", "difficulty": 13}, "effects_on_success": [{"op": "stat_add", "stat": "influence", "amount": 4}], "effects_on_failure": [{"op": "stat_add", "stat": "legitimacy", "amount": -3}, {"op": "scandal_add", "headline": "Candidate's Evidence Folder Empty"}]}
		]
	else:
		var intro := "[b]DEBATE - ROUND %d: %s[/b]\n\n" % [debate_round, round_data.get("topic", "Unknown")]
		intro += "Moderator: \"%s\"\n\n" % round_data.get("moderator_question", "...")
		intro += "%s responds: \"%s\"" % [GameManager.opponent_name, round_data.get("opponent_attack", "...")]
		activity_text.text = intro
		current_choices = round_data.get("choices", [])
		current_activity_type = "debate_rounds"
		current_activity_id = round_data.get("id", "")

	_show_choices(current_choices)


func _show_choices(choices: Array) -> void:
	_clear_choices()

	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = "► " + _replace_placeholders(choice.get("text", "..."))

		var can_select := true
		if choice.has("requires"):
			for skill_name in choice.requires:
				if not SkillSystem.check_skill(skill_name, choice.requires[skill_name]):
					can_select = false
					btn.text += " [LOCKED]"
					break

		btn.disabled = not can_select
		btn.pressed.connect(_on_choice_selected.bind(i))
		btn.custom_minimum_size = Vector2(0, 38)
		choices_container.add_child(btn)


func _replace_placeholders(text: String) -> String:
	text = text.replace("{player_name}", GameManager.player_name)
	text = text.replace("{opponent_name}", GameManager.opponent_name)
	text = text.replace("{district_name}", GameManager.district_name)
	text = text.replace("{crisis}", GameManager.main_crisis)
	return text


func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()


func _on_choice_selected(index: int) -> void:
	if index < 0 or index >= current_choices.size():
		return

	var choice: Dictionary = current_choices[index]
	var result_text := ""

	if choice.has("skill_check"):
		var check: Dictionary = choice.skill_check
		var result := SkillSystem.roll_skill_check(check.skill, check.difficulty)

		if result.success:
			result_text = "[color=green]► SUCCESS![/color] (Rolled %d + %d = %d vs %d)\n\n" % [result.roll, result.skill_value, result.total, result.difficulty]
			if choice.has("effects_on_success"):
				_apply_choice_effects(choice.effects_on_success)
		else:
			result_text = "[color=red]► FAILED![/color] (Rolled %d + %d = %d vs %d)\n\n" % [result.roll, result.skill_value, result.total, result.difficulty]
			if choice.has("effects_on_failure"):
				_apply_choice_effects(choice.effects_on_failure)
	else:
		result_text = "[color=yellow]►[/color] "
		if choice.has("effects"):
			_apply_choice_effects(choice.effects)

	_log_activity_event(choice)
	result_text += "You selected: " + _replace_placeholders(choice.get("text", "..."))

	activity_text.text = result_text
	_clear_choices()
	next_day_button.disabled = false


func _apply_choice_effects(effects: Array) -> void:
	GameManager.apply_effects(effects, {"npc_id": current_npc_id})
	_update_skill_display()


func _log_activity_event(choice: Dictionary) -> void:
	match current_activity_type:
		"posters":
			GameManager.log_event("poster_placed", {
				"poster_id": choice.get("id", ""),
				"text": choice.get("text", "")
			})
		"fundraisers":
			GameManager.log_event("donor_taken", {
				"scenario_id": current_activity_id,
				"choice_text": choice.get("text", "")
			})
		"events":
			GameManager.log_event("event_attended", {
				"scenario_id": current_activity_id,
				"choice_text": choice.get("text", "")
			})
		"canvassing":
			GameManager.log_event("canvassing_choice", {
				"scenario_id": current_activity_id,
				"choice_text": choice.get("text", "")
			})
		"debate_rounds":
			GameManager.log_event("debate_choice", {
				"round_id": current_activity_id,
				"choice_text": choice.get("text", "")
			})


func _show_results() -> void:
	var results := GameManager.calculate_election_results()

	day_title.text = "═══ ELECTION RESULTS ═══"
	day_description.text = "\"The math doesn't care how you feel.\""

	var text := ""
	if results.won:
		text = "[color=green][b]► VICTORY![/b][/color]\n\n"
		text += "Against all odds (and possibly good judgment), you won.\n\n"
	else:
		text = "[color=red][b]► DEFEAT[/b][/color]\n\n"
		text += "Democracy has spoken. It said 'no.'\n\n"

	text += "[b]═══ FINAL VOTE ═══[/b]\n"
	text += "► %s: %d votes (%.1f%%)\n" % [GameManager.player_name.to_upper(), results.player_votes, 50 + results.margin / 2]
	text += "► %s: %d votes (%.1f%%)\n\n" % [GameManager.opponent_name.to_upper(), results.opponent_votes, 50 - results.margin / 2]

	text += "[b]═══ FACTORS ═══[/b]\n"
	for factor in results.factors:
		var value: float = results.factors[factor]
		var color := "green" if value > 0 else ("red" if value < 0 else "white")
		text += "► %s: [color=%s]%+.1f[/color]\n" % [factor.capitalize().replace("_", " "), color, value]

	if GameManager.scandals.size() > 0:
		text += "\n[b]═══ SCANDALS ═══[/b]\n"
		for scandal in GameManager.scandals:
			text += "► [color=red]%s[/color]\n" % scandal.headline

	if GameManager.endorsements.size() > 0:
		text += "\n[b]═══ ENDORSEMENTS ═══[/b]\n"
		for endorser in GameManager.endorsements:
			text += "► [color=green]%s[/color]\n" % endorser

	if GameManager.promises_made.size() > 0:
		text += "\n[b]═══ PROMISES ═══[/b]\n"
		text += "► Made: %d | Broken: %d\n" % [GameManager.promises_made.size(), GameManager.promises_broken.size()]

	activity_text.text = text
	_clear_choices()

	next_day_button.text = "► PLAY AGAIN"
	next_day_button.pressed.disconnect(_on_next_day_pressed)
	next_day_button.pressed.connect(_on_play_again)


func _on_next_day_pressed() -> void:
	_show_news()


func _show_news() -> void:
	var headlines := NewsSystem.generate_daily_news()

	var news_text := "[b]═══ EVENING NEWS ═══[/b]\n\n"
	for headline in headlines:
		var color := "white"
		match headline.tone:
			"positive": color = "green"
			"negative": color = "red"

		news_text += "[color=%s]► %s[/color]\n" % [color, headline.headline]
		news_text += "  %s\n\n" % headline.body

	activity_text.text = news_text
	_clear_choices()

	next_day_button.text = "► CONTINUE"
	next_day_button.pressed.disconnect(_on_next_day_pressed)
	next_day_button.pressed.connect(_on_continue_from_news)


func _on_continue_from_news() -> void:
	next_day_button.pressed.disconnect(_on_continue_from_news)
	next_day_button.pressed.connect(_on_next_day_pressed)
	GameManager.advance_day()


func _on_play_again() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_skill_changed(_skill_name: String, _new_value: int) -> void:
	_update_skill_display()


func _update_skill_display() -> void:
	speechcraft_label.text = "SPE:%d" % SkillSystem.get_skill("speechcraft")
	kapital_label.text = "KAP:%d" % SkillSystem.get_skill("kapital")
	influence_label.text = "INF:%d" % SkillSystem.get_skill("influence")
	legitimacy_label.text = "LEG:%d" % SkillSystem.get_skill("legitimacy")
	logic_label.text = "LOG:%d" % SkillSystem.get_skill("logic")


func _update_status_bar() -> void:
	status_label.text = "DISTRICT: %s | CRISIS: %s | RIVAL: %s" % [
		GameManager.district_name.to_upper(),
		GameManager.main_crisis.to_upper(),
		GameManager.opponent_name.to_upper()
	]


func _on_dialogue_line(speaker: String, text: String) -> void:
	activity_text.text = "[b]%s:[/b] %s" % [speaker, text]


func _on_choices_presented(choices: Array) -> void:
	current_choices = choices
	_show_choices(choices)


func _on_dialogue_ended() -> void:
	in_dialogue = false
	next_day_button.disabled = false


func _on_game_ended(_won: bool, _results: Dictionary) -> void:
	_show_results()
