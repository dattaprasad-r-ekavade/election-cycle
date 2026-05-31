extends Node2D

@onready var player: Node2D = $Player
@onready var anchors_root: Node2D = $NPCAnchors
@onready var day_label: Label = $UILayer/TopBar/Margin/HBox/DayLabel
@onready var objective_label: Label = $UILayer/TopBar/Margin/HBox/ObjectiveLabel
@onready var status_label: Label = $UILayer/BottomPanel/Margin/VBox/StatusLabel
@onready var activity_text: RichTextLabel = $UILayer/BottomPanel/Margin/VBox/ActivityText
@onready var choices_container: VBoxContainer = $UILayer/BottomPanel/Margin/VBox/ChoicesScroll/ChoicesContainer
@onready var next_day_button: Button = $UILayer/BottomPanel/Margin/VBox/Buttons/NextDayButton
@onready var bottom_panel: PanelContainer = $UILayer/BottomPanel
@onready var proximity_hint: Control = $UILayer/ProximityHint
@onready var hint_label: Label = $UILayer/ProximityHint/HintMargin/HintBox/HintLabel
@onready var panel_location_label: Label = $UILayer/BottomPanel/Margin/VBox/PanelHeader/PanelLocationLabel
@onready var close_panel_button: Button = $UILayer/BottomPanel/Margin/VBox/PanelHeader/ClosePanelButton

var dice_popup: Control

var current_choices: Array = []
var current_activity_type: String = ""
var current_activity_id: String = ""
var current_npc_id: String = ""
var day_complete := false
var showing_news := false

var pending_choice: Dictionary = {}

const CELL_SIZE := 64

const LOCATION_DATA := {
	"CampaignHQ": {"id": "hq", "name": "Campaign HQ", "cell": Vector2i(9, 7), "hint": "Plan your next move."},
	"Neighborhood": {"id": "neighborhood", "name": "Neighborhood", "cell": Vector2i(3, 4), "hint": "Doors, voters, awkward small talk."},
	"PrintShop": {"id": "print_shop", "name": "Print Shop", "cell": Vector2i(14, 4), "hint": "Where slogans become posters."},
	"TownSquare": {"id": "town_square", "name": "Town Square", "cell": Vector2i(9, 3), "hint": "Public eyes are everywhere."},
}

# Location -> day -> routed scenario type.
const LOCATION_ROUTE := {
	"hq": {3: "posters"},
	"neighborhood": {2: "canvassing"},
	"print_shop": {3: "posters"},
	"town_square": {2: "canvassing"},
}

var anchors_by_cell: Dictionary = {}


func _ready() -> void:
	SettingsSystem.apply_font_scale(self)
	if GameManager.current_day > 3:
		get_tree().change_scene_to_file("res://scenes/game.tscn")
		return

	_setup_anchors()
	player.interact_requested.connect(_on_player_interact)

	next_day_button.pressed.connect(_on_next_day_pressed)
	close_panel_button.pressed.connect(_on_close_panel)
	bottom_panel.visible = false
	proximity_hint.visible = false

	var popup_scene := load("res://scenes/dice_roll_popup.tscn")
	dice_popup = popup_scene.instantiate()
	dice_popup.roll_accepted.connect(_on_dice_roll_accepted)
	dice_popup.roll_declined.connect(_on_dice_roll_declined)
	add_child(dice_popup)

	_update_header()
	_update_status()
	_clear_choices()
	next_day_button.disabled = true


func _setup_anchors() -> void:
	anchors_by_cell.clear()
	for child in anchors_root.get_children():
		if not LOCATION_DATA.has(child.name):
			continue

		var def: Dictionary = LOCATION_DATA[child.name]
		var cell: Vector2i = def.cell
		child.position = Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)
		anchors_by_cell[cell] = def

		if child.has_node("Label"):
			var label: Label = child.get_node("Label")
			label.text = def.name


func _process(_delta: float) -> void:
	if not bottom_panel.visible:
		_check_proximity()


func _check_proximity() -> void:
	var nearby := _get_nearby_location_def()
	if nearby.is_empty():
		proximity_hint.visible = false
		return
	hint_label.text = "%s  |  %s" % [nearby.name, nearby.hint]
	proximity_hint.visible = true


func _get_nearby_location_def() -> Dictionary:
	var pc: Vector2i = player.grid_cell
	var checks := [
		pc + player.facing, pc,
		pc + Vector2i.UP, pc + Vector2i.DOWN,
		pc + Vector2i.LEFT, pc + Vector2i.RIGHT,
	]
	for c in checks:
		if anchors_by_cell.has(c):
			return anchors_by_cell[c]
	return {}


func _show_activity_panel(location_name: String) -> void:
	proximity_hint.visible = false
	panel_location_label.text = location_name
	close_panel_button.visible = true
	bottom_panel.modulate.a = 0.0
	bottom_panel.visible = true
	var tw := create_tween()
	tw.tween_property(bottom_panel, "modulate:a", 1.0, 0.15)


func _on_close_panel() -> void:
	if showing_news or day_complete:
		return
	var tw := create_tween()
	tw.tween_property(bottom_panel, "modulate:a", 0.0, 0.12)
	await tw.finished
	bottom_panel.visible = false
	_clear_choices()
	current_choices.clear()
	current_activity_type = ""
	current_activity_id = ""
	current_npc_id = ""


func _update_header() -> void:
	day_label.text = "DAY %d - %s" % [GameManager.current_day, _day_name(GameManager.current_day)]
	objective_label.text = _objective_for_day(GameManager.current_day)


func _update_status() -> void:
	status_label.text = "DISTRICT: %s | CRISIS: %s | RIVAL: %s" % [
		GameManager.district_name,
		GameManager.main_crisis,
		GameManager.opponent_name
	]


func _show_intro_text() -> void:
	var text := "[b]Walk the district and interact with locations.[/b]\n\n" + _objective_for_day(GameManager.current_day)
	if GameManager.current_day == 2 and TutorialSystem.should_show_tip("day2_walk_tip"):
		text += "\n\n[color=yellow]Tutorial:[/color] Move with WASD/arrow keys and press Enter near a labeled location to interact."
		TutorialSystem.mark_tip_seen("day2_walk_tip")
	activity_text.text = text


func _day_name(day: int) -> String:
	match day:
		1:
			return "Registration"
		2:
			return "Canvassing"
		3:
			return "Posters"
		_:
			return "Campaign"


func _objective_for_day(day: int) -> String:
	if day == 2:
		return "Objective: Visit Neighborhood or Town Square and complete one canvassing encounter."
	if day == 3:
		return "Objective: Visit Campaign HQ or Print Shop and choose a poster strategy."
	return "Objective: Explore the district."


func _on_player_interact(target_cell: Vector2i) -> void:
	if showing_news:
		return

	if day_complete:
		# Panel is already open; just refresh the message.
		activity_text.text = "[b]Activity complete.[/b]\n\nPress End Day when ready."
		return

	var location_def := _resolve_interaction_location(target_cell)
	if location_def.is_empty():
		# Nothing nearby — don't open the panel, proximity hint already guides.
		return

	var location_id: String = location_def.id
	var route := _route_for_location(location_id, GameManager.current_day)
	if route == "":
		_show_activity_panel(location_def.name)
		activity_text.text = "[b]%s[/b]\n%s\n\nNothing here for today's objective." % [location_def.name, location_def.hint]
		return

	_start_location_activity(location_def, route)


func _resolve_interaction_location(target_cell: Vector2i) -> Dictionary:
	if anchors_by_cell.has(target_cell):
		return anchors_by_cell[target_cell]

	var current_cell: Variant = player.get("grid_cell")
	if current_cell is Vector2i:
		var player_cell := current_cell as Vector2i
		if anchors_by_cell.has(player_cell):
			return anchors_by_cell[player_cell]

		var nearby := [
			player_cell + Vector2i.UP,
			player_cell + Vector2i.DOWN,
			player_cell + Vector2i.LEFT,
			player_cell + Vector2i.RIGHT,
		]
		for cell in nearby:
			if anchors_by_cell.has(cell):
				return anchors_by_cell[cell]

	return {}


func _route_for_location(location_id: String, day: int) -> String:
	if not LOCATION_ROUTE.has(location_id):
		return ""
	var by_day: Dictionary = LOCATION_ROUTE[location_id]
	return by_day.get(day, "")


func _start_location_activity(location_def: Dictionary, route: String) -> void:
	_show_activity_panel(location_def.name)
	current_choices.clear()
	current_npc_id = ""
	current_activity_id = ""

	if route == "canvassing":
		var scenario := ContentLoader.get_random_scenario("canvassing", GameManager.current_day)
		if scenario.is_empty():
			activity_text.text = "[b]%s[/b]\n\nNo one opens the door today." % location_def.name
			return
		current_activity_type = "canvassing"
		current_activity_id = scenario.get("id", "")
		current_npc_id = scenario.get("npc_id", "")
		activity_text.text = "[b]%s[/b]\n%s" % [location_def.name, scenario.get("intro_text", "You knock on a door...")]
		current_choices = scenario.get("choices", [])
		_show_choices(current_choices)
		return

	if route == "posters":
		var posters := ContentLoader.get_posters()
		if posters.is_empty():
			activity_text.text = "[b]%s[/b]\n\nThe print machines are down. No posters today." % location_def.name
			return
		current_activity_type = "posters"
		activity_text.text = "[b]%s[/b]\nPick a campaign poster direction." % location_def.name
		for poster in posters:
			current_choices.append({
				"id": poster.get("id", ""),
				"text": poster.get("text", "Poster"),
				"effects": poster.get("effects", [])
			})
		_show_choices(current_choices)


func _show_choices(choices: Array) -> void:
	_clear_choices()
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = "> " + _replace_placeholders(choice.get("text", "..."))
		btn.custom_minimum_size = Vector2(0, 38)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_choice_selected.bind(i))
		choices_container.add_child(btn)


func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()


func _on_choice_selected(index: int) -> void:
	if index < 0 or index >= current_choices.size():
		return

	for child in choices_container.get_children():
		if child is Button:
			child.disabled = true

	var choice: Dictionary = current_choices[index]
	if choice.has("skill_check"):
		pending_choice = choice
		var check: Dictionary = choice.skill_check
		var context := {
			"npc_id": current_npc_id,
			"activity_type": current_activity_type,
			"description": _replace_placeholders(choice.get("text", "Make a check"))
		}
		dice_popup.show_check(check.skill, check.difficulty, context.description, context)
		return

	_apply_choice_directly(choice)


func _on_dice_roll_accepted(result: Dictionary) -> void:
	var choice := pending_choice
	var result_text := ""
	if result.is_crit_success:
		result_text = "[color=gold]CRITICAL SUCCESS![/color]\n"
	elif result.is_crit_failure:
		result_text = "[color=red]CRITICAL FAILURE[/color]\n"
	elif result.success:
		result_text = "[color=green]SUCCESS[/color]\n"
	else:
		result_text = "[color=red]FAILURE[/color]\n"

	result_text += "[i]\"%s\"[/i]\n\n" % result.flavor_text
	result_text += "Rolled %d + %d (%s)" % [result.final_roll, result.skill_value, result.skill_display]
	if result.total_modifier != 0:
		result_text += " %+d (modifiers)" % result.total_modifier
	result_text += " = %d vs %d\n\n" % [result.total, result.difficulty]

	if result.success:
		if choice.has("effects_on_success"):
			_apply_choice_effects(choice.effects_on_success)
		if result.is_crit_success:
			GameManager.add_district_support(5, "critical_success")
	else:
		if choice.has("effects_on_failure"):
			_apply_choice_effects(choice.effects_on_failure)
		if result.is_crit_failure:
			GameManager.add_scandal_risk({
				"id": "crit_fail_%d" % GameManager.current_day,
				"chance": 0.5,
				"headline": "Campaign Gaffe Goes Viral"
			})

	_log_activity_event(choice)
	activity_text.text = result_text
	pending_choice = {}
	_finalize_day_activity()


func _on_dice_roll_declined() -> void:
	pending_choice = {}
	for child in choices_container.get_children():
		if child is Button:
			child.disabled = false


func _apply_choice_directly(choice: Dictionary) -> void:
	if choice.has("effects"):
		_apply_choice_effects(choice.effects)
	_log_activity_event(choice)
	activity_text.text = "You selected: %s" % _replace_placeholders(choice.get("text", "..."))
	_finalize_day_activity()


func _apply_choice_effects(effects: Array) -> void:
	var context := {
		"npc_id": current_npc_id,
		"source": current_activity_type,
	}
	GameManager.apply_effects(effects, context)


func _log_activity_event(choice: Dictionary) -> void:
	if current_activity_type == "posters":
		GameManager.log_event("poster_placed", {
			"poster_id": choice.get("id", ""),
			"text": choice.get("text", "")
		})
	elif current_activity_type == "canvassing":
		GameManager.log_event("canvassing_choice", {
			"scenario_id": current_activity_id,
			"choice_text": choice.get("text", "")
		})


func _finalize_day_activity() -> void:
	_clear_choices()
	day_complete = true
	close_panel_button.visible = false
	next_day_button.disabled = false
	next_day_button.text = "END DAY"


func _on_next_day_pressed() -> void:
	if showing_news:
		_continue_from_news()
		return

	if not day_complete:
		activity_text.text = "Complete today's objective before ending the day."
		return

	_show_news()


func _show_news() -> void:
	showing_news = true
	var headlines := NewsSystem.generate_daily_news()
	var text := "[b]=== EVENING NEWS ===[/b]\n\n"
	for headline in headlines:
		var color := "white"
		match headline.tone:
			"positive":
				color = "green"
			"negative":
				color = "red"
		text += "[color=%s]%s[/color]\n" % [color, headline.headline]
		text += "  %s\n\n" % headline.body

	activity_text.text = text
	next_day_button.text = "CONTINUE"


func _continue_from_news() -> void:
	showing_news = false
	GameManager.advance_day()
	if GameManager.current_day > 3:
		get_tree().change_scene_to_file("res://scenes/game.tscn")
		return

	day_complete = false
	current_choices.clear()
	current_activity_type = ""
	current_activity_id = ""
	current_npc_id = ""
	pending_choice = {}
	_update_header()
	_show_intro_text()
	_clear_choices()
	bottom_panel.visible = false
	next_day_button.text = "END DAY"
	next_day_button.disabled = true


func _replace_placeholders(text: String) -> String:
	text = text.replace("{player_name}", GameManager.player_name)
	text = text.replace("{opponent_name}", GameManager.opponent_name)
	text = text.replace("{district_name}", GameManager.district_name)
	text = text.replace("{crisis}", GameManager.main_crisis)
	return text
