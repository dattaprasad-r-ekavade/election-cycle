extends Node2D

## The walkable district: full Days 2-7 overworld loop.
## Day 2 canvassing, 3 posters, 4 fundraiser, 5 town event,
## 6 debate at Town Hall, 7 election rally at the Town Square.

const CELL := 48
const G := preload("res://systems/town_generator.gd")
const NPC_SCRIPT := preload("res://scripts/town_npc.gd")

@onready var map_art: Node2D = $MapArt
@onready var player: Node2D = $Player
@onready var npcs_root: Node2D = $NPCs
@onready var labels_root: Node2D = $MapLabels
@onready var day_label: Label = $UILayer/TopBar/Margin/HBox/DayLabel
@onready var skills_label: Label = $UILayer/TopBar/Margin/HBox/SkillsLabel
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

var town: Dictionary = {}
var dice_popup: Control

var current_choices: Array = []
var current_activity_type: String = ""
var current_activity_id: String = ""
var current_npc_id: String = ""
var day_complete := false
var showing_news := false
var encounters_done_today := 0
var fountain_coin_used_day := -1
var debate_round := 1
var pending_choice: Dictionary = {}
var election_results: Dictionary = {}
var results_shown := false

var npc_nodes: Array = []
var venue_markers: Array = []

# Day plan: which buildings host the day's main activity.
const DAY_PLAN := {
	2: {"type": "canvassing", "venues": ["house_0", "house_1", "house_2", "house_3"], "name": "Canvassing",
		"objective": "Knock on doors in the Neighborhood. Tall grass may contain wild voters."},
	3: {"type": "posters", "venues": ["print_shop", "hq"], "name": "Posters",
		"objective": "Visit the Print Shop (or HQ) and pick a poster strategy."},
	4: {"type": "fundraisers", "venues": ["diner", "landmark"], "name": "Fundraiser",
		"objective": "Money time. Hit the Diner and shake hands with wallets."},
	5: {"type": "events", "venues": ["square"], "name": "Town Event",
		"objective": "A crowd gathers at the Town Square stage. Go perform."},
	6: {"type": "debate_rounds", "venues": ["town_hall"], "name": "The Debate",
		"objective": "Town Hall. Your opponent is already doing vocal warmups."},
	7: {"type": "results", "venues": ["square"], "name": "Election Day",
		"objective": "Go to the Town Square stage. Democracy has finished chewing."},
}

const CLOSED_LINES := {
	"hq": "Your HQ. The intern is asleep on a pile of yard signs.",
	"town_hall": "Town Hall. Closed. A sign says 'Back in 5 minutes' — dated three years ago.",
	"print_shop": "The Print Shop. The smell of toner and broken dreams.",
	"diner": "The Diner. Today's special: whatever yesterday's special was.",
	"landmark": "Locals insist this place is 'historic.' Nobody can say why.",
	"house": "You consider knocking. The curtains move. You pretend to check your phone.",
}

const STYLE_QUIPS := {
	"suburban": [
		"My lawn. My rules. My measured, simmering rage.",
		"The HOA says my flamingo is 'a zoning incident.'",
		"I vote for whoever promises quieter leaf blowers.",
	],
	"hometown": [
		"I knew you when you were THIS tall. You peaked then, honestly.",
		"Your mom told everyone you're running. EVERYONE.",
		"We don't lock doors here. We do lock opinions.",
	],
	"university": [
		"I'm minoring in Protest Studies. The final is a riot. Literally.",
		"The frat's poll has you at 420%. They refuse to elaborate.",
		"My professor says voting is a social construct. He votes twice.",
	],
	"industrial": [
		"The vending machines unionized. The snacks demand dental.",
		"That smoke? That's the GOOD smoke. The bad smoke is purple.",
		"My grandfather worked that factory. My father worked it. I email.",
	],
	"coastal": [
		"The fish plant's hiring. The fish are not happy about it.",
		"Tide comes in, tide goes out. Politicians, same thing.",
		"You're not from here. Your shoes are too dry.",
	],
	"tourist": [
		"I came for a weekend, eleven years ago.",
		"The gift shops are at war. Shoppe #47 drew first blood.",
		"Please don't feed the influencers. They never leave.",
	],
	"downtown": [
		"I've been double-parked since 2019. It's a lifestyle now.",
		"Rent went up. My ceiling, somehow, went down.",
		"A politician? Here? Bold. The last one got booed by pigeons.",
	],
	"rural": [
		"The barn's older than the town. It votes too. Don't ask how.",
		"You city folk knock so... vertically.",
		"My tractor has more horsepower than your whole campaign.",
	],
	"tech": [
		"My fridge ordered milk and also filed my taxes. Wrong.",
		"The parking app crashed and now I legally live in my car.",
		"A door-to-door politician? How delightfully analog.",
	],
	"dream": [
		"You again? You're always here. You've always BEEN here.",
		"The fountain whispers poll numbers. They're never good.",
		"I'm not real, but my concerns about zoning are.",
	],
	"crime": [
		"I saw nothing. I see nothing. Buy a watch?",
		"Three factions run this town. Four if you count the raccoons.",
		"Politics? Around here we call that 'territory negotiation.'",
	],
	"national": [
		"Are you the candidate everyone's filming, or the other one?",
		"I've been interviewed six times today. I don't even live here.",
		"A celebrity endorsed my sandwich earlier. Strange week.",
	],
	"capital": [
		"I'm a lobbyist for lobbyists. We lobby for more lobbies.",
		"The monument? It commemorates the committee that proposed it.",
		"Shutdown's coming. We're betting on Thursday.",
	],
}

const NPC_NAMES := ["Gary", "Doris", "Chet", "Marlene", "Bus Stop Kevin", "Aunt Patty", "Big Steve", "Linda 2", "The Mayor's Cousin", "Craig"]

const PALETTES := [
	{"shirt": Color("4878d0"), "pants": Color("604830"), "hat": Color("f8d030"), "has_hat": false, "hair": Color("303030")},
	{"shirt": Color("48a868"), "pants": Color("3858a0"), "has_hat": false, "hair": Color("a06820")},
	{"shirt": Color("f8d030"), "pants": Color("484848"), "hat": Color("48a868"), "has_hat": true, "hair": Color("583818")},
	{"shirt": Color("c858d8"), "pants": Color("303848"), "has_hat": false, "hair": Color("e8e8e8")},
	{"shirt": Color("e8a030"), "pants": Color("385838"), "hat": Color("4878d0"), "has_hat": true, "hair": Color("281808")},
	{"shirt": Color("d05858"), "pants": Color("283858"), "has_hat": false, "hair": Color("905828")},
]


func _ready() -> void:
	SettingsSystem.apply_font_scale(self)

	if GameManager.current_day <= 1:
		get_tree().change_scene_to_file("res://scenes/character_creation.tscn")
		return
	if GameManager.current_day > 7:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return

	GameManager.game_ended.connect(_on_game_ended)
	SkillSystem.skill_changed.connect(func(_n, _v): _update_skills_hud())

	_generate_town()
	_spawn_npcs()
	_setup_player()
	_setup_ui()
	_setup_day()
	_run_day_intro.call_deferred()


func _on_game_ended(_won: bool, results: Dictionary) -> void:
	election_results = results


# ------------------------------------------------------------------ campaign cutscenes

const CUTSCENE_PALETTES := {
	"mom":      {"shirt": Color("e87898"), "pants": Color("705060"), "hair": Color("c8c0b8"), "has_hat": false},
	"official": {"shirt": Color("c8b890"), "pants": Color("504840"), "hair": Color("887858"), "has_hat": false},
	"student":  {"shirt": Color("58b878"), "pants": Color("3858a0"), "hair": Color("c84858"), "has_hat": false},
	"worker":   {"shirt": Color("e8a030"), "pants": Color("485058"), "hat": Color("f8d030"), "has_hat": true, "hair": Color("583818")},
	"vlogger":  {"shirt": Color("f06890"), "pants": Color("303848"), "hat": Color("40b8c8"), "has_hat": true, "hair": Color("f8e858")},
	"exec":     {"shirt": Color("303848"), "pants": Color("282838"), "hair": Color("181818"), "has_hat": false},
	"shadow":   {"shirt": Color("404858"), "pants": Color("303040"), "hair": Color("282830"), "skin": Color("b8a8c8"), "has_hat": false},
	"clone":    {"shirt": Color("e84840"), "pants": Color("3858a0"), "hat": Color("e84840"), "has_hat": true, "hair": Color("5a3a20")},
	"reporter": {"shirt": Color("4878d0"), "pants": Color("484848"), "hair": Color("a06820"), "has_hat": false},
	"aide":     {"shirt": Color("888098"), "pants": Color("404048"), "hair": Color("605850"), "has_hat": false},
}

var cutscene_active := false


# The hometown scenario doubles as the training campaign: after each day's
# cutscene, the CAMPAIGN MANUAL explains the mechanic that day introduces.
const TUTORIAL_TIPS := {
	2: "[b]Welcome to your campaign![/b] (Mom says hi.)\n\n• Move with [b]WASD / arrow keys[/b]. Press [b]Enter[/b] to talk to people and enter buildings.\n• The bouncing [color=yellow]![/color] marks today's objective. Today: knock on doors in the Neighborhood.\n• [b]Tall grass[/b] hides wild VOTERS. Walk through it for surprise encounters — each one you win builds support.\n• Your [b]SKILL[/b] stats are in the top bar. Choices marked with a skill roll a [b]d10 + that skill[/b] against a difficulty. A 10 is a critical success. A 1 is a story you'll tell in therapy.\n• Zoom with the [b]mouse wheel[/b] or [b]+/-[/b].",
	3: "[b]Poster day.[/b]\n\n• Today you pick a campaign poster at the Print Shop (or HQ). Posters permanently shift [b]district support[/b] — the big number that wins elections.\n• Check the status line at the bottom of this panel: DISTRICT, CRISIS, RIVAL, and your current SUPPORT.\n• Side tip: toss a coin in the fountain once a day. It is, technically, a bribe. It technically works.",
	4: "[b]Fundraiser day.[/b]\n\n• Money talks, and today it wants to talk to YOU at the Diner.\n• Donor choices often add [b]scandal RISK[/b] — a percentage chance that a nasty headline drops later. The money is real; so is the risk.\n• High [b]Kapital[/b] unlocks richer options. Low Kapital unlocks desperate ones. Both are content.",
	5: "[b]Town event day.[/b]\n\n• A crowd waits at the Town Square stage. Public choices here can create [b]promises[/b].\n• Promises are tracked. Contradict one later (build a thing AND cut spending?) and it WILL come up at the debate — and cost you votes.\n• Talking to townsfolk builds [b]NPC trust[/b], which counts separately from district support. Important people sway more voters.",
	6: "[b]DEBATE DAY.[/b] The boss fight.\n\n• Three rounds at Town Hall. Your opponent has been taking notes on your entire run — expect your own choices quoted back at you.\n• Some replies are [b][LOCKED][/b] — they need higher stats. Your build decides your weapons.\n• Critical failures here go viral. No pressure.",
	7: "[b]Election day.[/b]\n\n• The count weighs everything: skills, district support, NPC trust, promises kept and broken, scandals, endorsements — plus hidden conditions like weather and the economy (the [b]FATE[/b] dice from the remix screen).\n• Go to the stage when you're ready. Win or lose, you'll see exactly why.\n\nThat's the whole game. Mom believes in you.",
}


func _is_tutorial_run() -> bool:
	if GameManager.play_mode != "campaign":
		return false
	return bool(CampaignSystem.get_scenario(GameManager.campaign_scenario_id).get("tutorial", false))


func _run_day_intro() -> void:
	await _maybe_play_day_cutscene()
	_maybe_show_tutorial()


func _maybe_show_tutorial() -> void:
	if not _is_tutorial_run():
		return
	var day := GameManager.current_day
	if not TUTORIAL_TIPS.has(day):
		return
	var flag := "tutorial_day_%d_seen" % day
	if GameManager.get_run_flag(flag):
		return
	GameManager.set_run_flag(flag, true)
	_show_flavor("CAMPAIGN MANUAL — DAY %d" % day, TUTORIAL_TIPS[day])


func _maybe_play_day_cutscene() -> void:
	"""Pokemon-style scripted visit: a character walks up and talks to you."""
	if GameManager.play_mode != "campaign":
		return
	var scen: Dictionary = CampaignSystem.get_scenario(GameManager.campaign_scenario_id)
	var cuts: Dictionary = scen.get("day_cutscenes", {})
	var key := str(GameManager.current_day)
	if not cuts.has(key):
		return
	var flag := "cutscene_day_%d_seen" % GameManager.current_day
	if GameManager.get_run_flag(flag):
		return
	GameManager.set_run_flag(flag, true)
	await _play_cutscene(cuts[key])


func _play_cutscene(cut: Dictionary) -> void:
	cutscene_active = true
	player.input_locked = true
	await get_tree().create_timer(0.45).timeout

	# Spawn the visitor a few cells away and walk them over.
	var visitor := Node2D.new()
	visitor.set_script(NPC_SCRIPT)
	npcs_root.add_child(visitor)
	var spawn := _find_cutscene_spawn()
	var visitor_name := String(cut.get("visitor", "???"))
	visitor.setup({
		"name": visitor_name,
		"lines": [],
		"cell": spawn,
		"walker": false,
		"palette": CUTSCENE_PALETTES.get(String(cut.get("palette", "official")), {}),
		"walkable_check": _cell_walkable_for_cutscene,
		"occupied_check": _cell_occupied,
	})
	npc_nodes.append(visitor)

	var dest := _adjacent_free_cell(player.grid_cell)
	if dest != Vector2i(-1, -1):
		await visitor.walk_to(dest)
	visitor.face_towards(player.grid_cell)
	player.facing = Vector2i(signi(visitor.grid_cell.x - player.grid_cell.x), signi(visitor.grid_cell.y - player.grid_cell.y))
	if player.facing.x != 0 and player.facing.y != 0:
		player.facing = Vector2i(player.facing.x, 0)
	player.avatar.facing = player.facing
	player.avatar.queue_redraw()

	# Dialogue, one line per click.
	_open_panel(visitor_name)
	close_panel_button.visible = false
	next_day_button.visible = false
	for line in cut.get("lines", []):
		var speaker := String(line.get("speaker", visitor_name))
		activity_text.text = "[b]%s:[/b] %s" % [speaker, _replace_placeholders(String(line.get("text", "...")))]
		await _wait_for_cutscene_continue()

	# Wrap up: close panel, visitor wanders off.
	_clear_choices()
	bottom_panel.visible = false
	next_day_button.visible = true
	close_panel_button.visible = true
	await visitor.walk_to(spawn)
	npc_nodes.erase(visitor)
	visitor.queue_free()
	player.input_locked = false
	cutscene_active = false


func _wait_for_cutscene_continue() -> void:
	_clear_choices()
	var btn := Button.new()
	btn.text = "▶  ..."
	btn.custom_minimum_size = Vector2(0, 38)
	choices_container.add_child(btn)
	await btn.pressed


func _cell_walkable_for_cutscene(cell: Vector2i) -> bool:
	# Cutscene visitors may cross roads (dramatic entrances trump traffic law).
	if not G.is_walkable(town, cell):
		return false
	if player and player.grid_cell == cell:
		return false
	return true


func _find_cutscene_spawn() -> Vector2i:
	# A walkable cell 4-7 cells away from the player, preferring below/side.
	var pc: Vector2i = player.grid_cell
	for radius in [5, 6, 4, 7, 3]:
		for dir in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
			var c: Vector2i = pc + dir * radius
			if c.x > 0 and c.y > 0 and c.x < int(town.width) - 1 and c.y < int(town.height) - 1:
				if _cell_walkable_for_cutscene(c) and not _cell_occupied(c, null):
					return c
	return _adjacent_free_cell(pc)


func _adjacent_free_cell(cell: Vector2i) -> Vector2i:
	for dir in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
		var c: Vector2i = cell + dir
		if _cell_walkable_for_cutscene(c) and not _cell_occupied(c, null):
			return c
	return Vector2i(-1, -1)


# ------------------------------------------------------------------ setup

func _generate_town() -> void:
	var style := ""
	if GameManager.play_mode == "campaign":
		var scen: Dictionary = CampaignSystem.get_scenario(GameManager.campaign_scenario_id)
		style = String(scen.get("town_style", ""))
	if style == "":
		style = G.style_for_theme(GameManager.district_theme)

	town = G.generate(GameManager.get_layout_seed(), style)
	map_art.setup(town)

	# Building name labels
	for b in town.buildings:
		var rect: Rect2i = b.rect
		var center_x := (rect.position.x + rect.size.x * 0.5) * CELL
		labels_root.add_child(_make_world_label(String(b.name), Vector2(center_x, rect.position.y * CELL - 26), 13, Color(1, 0.98, 0.9)))

	var sq: Rect2i = town.square_rect
	var sq_x := (sq.position.x + sq.size.x * 0.5) * CELL
	labels_root.add_child(_make_world_label("Town Square", Vector2(sq_x, sq.position.y * CELL - 26), 13, Color(1, 0.98, 0.9)))


func _make_world_label(text: String, center_pos: Vector2, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(220, 22)
	lbl.position = center_pos - Vector2(110, 0)
	return lbl


func _spawn_npcs() -> void:
	var style := String(town.style)
	var quips: Array = (STYLE_QUIPS.get(style, STYLE_QUIPS["suburban"]) as Array).duplicate()
	quips.append("Aren't you %s? My %s hates you. I'm undecided." % [GameManager.player_name, ["dog", "barber", "houseplant", "group chat"][randi() % 4]])
	quips.append("Still no plan for %s, huh? Classic." % GameManager.main_crisis)
	quips.append("%s came by earlier. Firm handshake. Dead eyes." % GameManager.opponent_name)

	var spawns: Array = town.npc_spawns
	var count := mini(spawns.size(), 6)
	for i in range(count):
		var npc := Node2D.new()
		npc.set_script(NPC_SCRIPT)
		npcs_root.add_child(npc)
		var npc_lines := [quips[i % quips.size()], quips[(i + 3) % quips.size()]]
		npc.setup({
			"name": NPC_NAMES[(GameManager.run_seed + i) % NPC_NAMES.size()],
			"lines": npc_lines,
			"cell": spawns[i],
			"palette": PALETTES[(GameManager.run_seed + i) % PALETTES.size()],
			"walkable_check": _cell_walkable_for_npc,
			"occupied_check": _cell_occupied,
		})
		npc_nodes.append(npc)

	# Ducks near water, if any
	var duck_cell := _find_cell_near_water()
	if duck_cell != Vector2i(-1, -1):
		for d in range(2):
			var duck := Node2D.new()
			duck.set_script(NPC_SCRIPT)
			npcs_root.add_child(duck)
			duck.setup({
				"name": "Duck",
				"lines": ["Quack.", "Quack quack. (It sounds skeptical of your platform.)", "...quack? (It wants to see your tax returns.)"],
				"cell": duck_cell + Vector2i(d, 0),
				"radius": 3,
				"palette": {"is_duck": true},
				"walkable_check": _cell_walkable_for_npc,
				"occupied_check": _cell_occupied,
			})
			npc_nodes.append(duck)


func _find_cell_near_water() -> Vector2i:
	for y in range(int(town.height)):
		for x in range(int(town.width)):
			if int(town.tiles[y][x]) == G.T_WATER:
				for off: Vector2i in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:
					var c: Vector2i = Vector2i(x, y) + off
					if G.is_walkable(town, c):
						return c
	return Vector2i(-1, -1)


func _setup_player() -> void:
	player.configure(
		town.spawn,
		Vector2i(0, 0),
		Vector2i(int(town.width) - 1, int(town.height) - 1),
		_cell_walkable_for_player
	)
	player.interact_requested.connect(_on_player_interact)
	player.stepped.connect(_on_player_stepped)


func _setup_ui() -> void:
	next_day_button.pressed.connect(_on_next_day_pressed)
	close_panel_button.pressed.connect(_on_close_panel)
	bottom_panel.visible = false
	proximity_hint.visible = false

	var popup_scene := load("res://scenes/dice_roll_popup.tscn")
	dice_popup = popup_scene.instantiate()
	dice_popup.roll_accepted.connect(_on_dice_roll_accepted)
	dice_popup.roll_declined.connect(_on_dice_roll_declined)
	add_child(dice_popup)

	_update_skills_hud()
	_update_status()


func _setup_day() -> void:
	day_complete = false
	showing_news = false
	results_shown = false
	encounters_done_today = 0
	debate_round = 1
	current_choices.clear()
	pending_choice = {}
	_clear_choices()
	bottom_panel.visible = false
	next_day_button.text = "END DAY"
	next_day_button.disabled = true
	_update_header()
	_place_venue_markers()
	if player:
		player.input_locked = false


func _update_header() -> void:
	var day := GameManager.current_day
	var plan: Dictionary = DAY_PLAN.get(day, {})
	day_label.text = "DAY %d/7 — %s" % [day, plan.get("name", "Campaign")]
	objective_label.text = plan.get("objective", "Explore the district.")


func _update_skills_hud() -> void:
	skills_label.text = "SPE %d  KAP %d  INF %d  LEG %d  LOG %d" % [
		SkillSystem.get_skill("speechcraft"),
		SkillSystem.get_skill("kapital"),
		SkillSystem.get_skill("influence"),
		SkillSystem.get_skill("legitimacy"),
		SkillSystem.get_skill("logic"),
	]


func _update_status() -> void:
	status_label.text = "DISTRICT: %s | CRISIS: %s | RIVAL: %s | SUPPORT: %+d" % [
		GameManager.district_name, GameManager.main_crisis,
		GameManager.opponent_name, GameManager.district_support
	]


func _place_venue_markers() -> void:
	for m in venue_markers:
		if is_instance_valid(m):
			m.queue_free()
	venue_markers.clear()

	var plan: Dictionary = DAY_PLAN.get(GameManager.current_day, {})
	for venue_id in plan.get("venues", []):
		var pos := Vector2.ZERO
		if venue_id == "square":
			var st: Vector2i = town.stage_cell
			pos = Vector2((st.x + 1.0) * CELL, st.y * CELL - 26)
		else:
			var b := G.get_building(town, venue_id)
			if b.is_empty():
				continue
			var rect: Rect2i = b.rect
			pos = Vector2((rect.position.x + rect.size.x * 0.5) * CELL, rect.position.y * CELL - 26)
		var marker := _make_world_label("!", pos - Vector2(0, 26), 26, Color("f8d030"))
		labels_root.add_child(marker)
		venue_markers.append(marker)
		var base_y := marker.position.y
		var tw := marker.create_tween().set_loops()
		tw.tween_property(marker, "position:y", base_y - 8, 0.45).set_trans(Tween.TRANS_SINE)
		tw.tween_property(marker, "position:y", base_y, 0.45).set_trans(Tween.TRANS_SINE)


# ------------------------------------------------------------------ walkability

func _cell_walkable_for_player(cell: Vector2i) -> bool:
	if not G.is_walkable(town, cell):
		return false
	for npc in npc_nodes:
		if is_instance_valid(npc) and npc.grid_cell == cell:
			return false
	return true


func _cell_walkable_for_npc(cell: Vector2i) -> bool:
	if not G.is_walkable(town, cell):
		return false
	if player and player.grid_cell == cell:
		return false
	var t := int(town.tiles[cell.y][cell.x])
	if t == G.T_ROAD:
		return false  # townsfolk respect traffic, unlike candidates
	return true


func _cell_occupied(cell: Vector2i, asking: Node2D) -> bool:
	for npc in npc_nodes:
		if is_instance_valid(npc) and npc != asking and npc.grid_cell == cell:
			return true
	return false


# ------------------------------------------------------------------ proximity hint

func _process(_delta: float) -> void:
	if bottom_panel.visible:
		return
	var hint := _hint_for_cell(player.grid_cell + player.facing)
	if hint == "":
		hint = _hint_for_cell(player.grid_cell)
	if hint == "":
		proximity_hint.visible = false
	else:
		hint_label.text = hint
		proximity_hint.visible = true


func _hint_for_cell(cell: Vector2i) -> String:
	for npc in npc_nodes:
		if is_instance_valid(npc) and npc.grid_cell == cell:
			return "Talk to %s" % npc.npc_name
	var b := _building_at(cell)
	if not b.is_empty():
		if _is_todays_venue(b.id):
			return "%s  —  today's stop!" % b.name
		return b.name
	if _square_zone_at(cell) and _is_todays_venue("square"):
		return "The stage  —  today's stop!"
	for p in town.props:
		if p.cell == cell:
			return _prop_hint(String(p.kind))
	return ""


func _prop_hint(kind: String) -> String:
	match kind:
		"fountain": return "Fountain"
		"stage": return "Stage"
		"bench": return "Bench"
		"trash_can": return "Trash can"
		"mailbox": return "Mailbox"
		"statue": return "Statue"
		"barrel": return "Suspicious barrel"
		"server_box": return "Humming box"
		"duck_sign": return "Sign"
		"lamppost": return "Lamppost"
	return "???"


# ------------------------------------------------------------------ interactions

func _building_at(cell: Vector2i) -> Dictionary:
	for b in town.buildings:
		if (b.rect as Rect2i).has_point(cell) or b.door == cell:
			return b
	return {}


func _square_zone_at(cell: Vector2i) -> bool:
	var st: Vector2i = town.stage_cell
	return cell == st or cell == st + Vector2i(1, 0) or cell == st + Vector2i(0, 1) or cell == st + Vector2i(1, 1)


func _on_player_interact(target_cell: Vector2i) -> void:
	if showing_news or bottom_panel.visible:
		return

	# NPCs first
	for npc in npc_nodes:
		if is_instance_valid(npc) and npc.grid_cell == target_cell:
			npc.face_towards(player.grid_cell)
			_show_npc_line(npc)
			return

	# Buildings
	var b := _building_at(target_cell)
	if not b.is_empty():
		_on_building_interact(b)
		return

	# Stage / square
	if _square_zone_at(target_cell):
		if _is_todays_venue("square"):
			if GameManager.current_day == 7:
				_start_results_rally()
			else:
				_start_activity("square", "The Stage")
		else:
			_show_flavor("The Stage", "An empty stage. You do a little wave to no one. Pathetic. Inspiring, but pathetic.")
		return

	# Props
	for p in town.props:
		if p.cell == target_cell:
			_on_prop_interact(p)
			return


func _is_todays_venue(venue_id: String) -> bool:
	var plan: Dictionary = DAY_PLAN.get(GameManager.current_day, {})
	return plan.get("venues", []).has(venue_id)


func _on_building_interact(b: Dictionary) -> void:
	var bid := String(b.id)
	if _is_todays_venue(bid):
		if GameManager.current_day == 6:
			_start_debate()
		else:
			_start_activity(bid, String(b.name))
		return

	# Closed / flavor
	var key := "house" if bid.begins_with("house") else bid
	var line: String = CLOSED_LINES.get(key, "It's closed. Even the door looks unimpressed.")
	if day_complete:
		line += "\n\n[i]Today's work is done. Press END DAY when ready.[/i]"
	_show_flavor(String(b.name), line)


func _on_prop_interact(p: Dictionary) -> void:
	var kind := String(p.kind)
	match kind:
		"fountain":
			if fountain_coin_used_day != GameManager.current_day:
				fountain_coin_used_day = GameManager.current_day
				GameManager.add_district_support(1, "fountain_wish")
				_update_status()
				_show_flavor("Fountain", "You toss a coin and wish for electoral victory.\n\nThe fountain accepts your bribe. [color=green]+1 district support.[/color]\n\nDemocracy remains, technically, for sale.")
			else:
				_show_flavor("Fountain", "The fountain has had enough of your money today. Even fountains have ethics rules.")
		"trash_can":
			_show_flavor("Trash Can", _trash_line())
		"mailbox":
			_show_flavor("Mailbox", "It's full of campaign flyers. Mostly yours. All folded into tiny hats.")
		"statue":
			_show_flavor("Statue", "A statue of the town founder, who reportedly also promised to fix %s.\n\nIn 1887." % GameManager.main_crisis)
		"barrel":
			_show_flavor("Suspicious Barrel", "You knock on the barrel. The barrel knocks back.\n\nYou decide this is a problem for the NEXT mayor.")
		"server_box":
			_show_flavor("Humming Box", "A sticker reads: 'CIVIC CLOUD v0.3 — DO NOT TURN OFF, ELECTIONS LIVE HERE.'\n\nYou slowly back away.")
		"duck_sign":
			_show_flavor("Sign", "'DUCKS HAVE RIGHT OF WAY.'\n\nBelow, in smaller print: 'They know what they did.'")
		"bench":
			_show_flavor("Bench", "You sit for a moment. A pigeon judges your posture. You get back up. Campaigns don't rest.")
		"stage":
			_show_flavor("Stage", "The stage awaits a performance. Not today, though.")
		"lamppost":
			_show_flavor("Lamppost", "Seventeen staples and one very old flyer: '%s FOR MAYOR — INTEGRITY!'\n\nIt's your opponent's. From their last three attempts." % GameManager.opponent_name.to_upper())
		_:
			_show_flavor("???", "It's... a thing. You nod at it politically.")


func _trash_line() -> String:
	var lines := [
		"Inside: one of your own flyers. Folded into an angry swan.",
		"Inside: a '%s 4 EVER' foam finger. Concerning." % GameManager.opponent_name,
		"You find $5! You put it back. There could be cameras. There are ALWAYS cameras.",
		"A raccoon stares up at you. It has seen your polling numbers. It pities you.",
	]
	return lines[randi() % lines.size()]


func _show_npc_line(npc: Node2D) -> void:
	_open_panel(npc.npc_name)
	activity_text.text = "[b]%s:[/b] \"%s\"" % [npc.npc_name, npc.next_line()]
	_clear_choices()


func _show_flavor(title: String, text: String) -> void:
	_open_panel(title)
	activity_text.text = text
	_clear_choices()


# ------------------------------------------------------------------ tall grass encounters (Day 2)

func _on_player_stepped(cell: Vector2i) -> void:
	if GameManager.current_day != 2 or bottom_panel.visible or showing_news:
		return
	if int(town.tiles[cell.y][cell.x]) != G.T_TUFT:
		return
	if randf() < 0.3:
		var scenario := ContentLoader.get_random_scenario("canvassing", GameManager.current_day)
		if scenario.is_empty():
			return
		_open_panel("Tall Grass")
		current_activity_type = "canvassing"
		current_activity_id = scenario.get("id", "")
		current_npc_id = scenario.get("npc_id", "")
		activity_text.text = "[b]A wild VOTER appeared![/b]\n\n%s" % _replace_placeholders(scenario.get("intro_text", "They look at you expectantly."))
		current_choices = (scenario.get("choices", []) as Array).duplicate()
		_show_choices(current_choices)


# ------------------------------------------------------------------ main activities

func _start_activity(venue_id: String, venue_name: String) -> void:
	var day := GameManager.current_day
	var plan: Dictionary = DAY_PLAN.get(day, {})
	var act_type := String(plan.get("type", ""))

	if day_complete and act_type != "canvassing":
		_show_flavor(venue_name, "[b]Done for today.[/b]\n\nPress END DAY when ready.")
		return
	if act_type == "canvassing" and encounters_done_today >= 3:
		_show_flavor(venue_name, "You've harassed enough households for one day. Even your clipboard is embarrassed.\n\nPress END DAY when ready.")
		return

	match act_type:
		"canvassing":
			var scenario := ContentLoader.get_random_scenario("canvassing", day)
			if scenario.is_empty():
				_show_flavor(venue_name, "No one answers. You hear a TV get suspiciously quieter.")
				return
			_open_panel(venue_name)
			current_activity_type = "canvassing"
			current_activity_id = scenario.get("id", "")
			current_npc_id = scenario.get("npc_id", "")
			activity_text.text = _replace_placeholders(scenario.get("intro_text", "You knock on a door..."))
			current_choices = (scenario.get("choices", []) as Array).duplicate()
			_show_choices(current_choices)
		"posters":
			var posters := ContentLoader.get_posters()
			if posters.is_empty():
				_show_flavor(venue_name, "The print machines are down. The intern blames 'toner ghosts.'")
				return
			_open_panel(venue_name)
			current_activity_type = "posters"
			current_activity_id = ""
			current_npc_id = ""
			activity_text.text = "[b]The clerk spreads out poster mockups.[/b]\n\n\"We need something that says 'vote for me' but also 'I am normal.' Tall order.\""
			current_choices = []
			for poster in posters:
				current_choices.append({
					"id": poster.get("id", ""),
					"text": poster.get("text", "Poster"),
					"effects": poster.get("effects", []),
				})
			_show_choices(current_choices)
		"fundraisers":
			var scenario := ContentLoader.get_random_scenario("fundraisers", day)
			if scenario.is_empty():
				_show_flavor(venue_name, "Nobody wants to give you money today. Shocking, really.")
				return
			_open_panel(venue_name)
			current_activity_type = "fundraisers"
			current_activity_id = scenario.get("id", "")
			current_npc_id = scenario.get("npc_id", "")
			activity_text.text = _replace_placeholders(scenario.get("intro_text", "Someone approaches, wallet visibly throbbing..."))
			current_choices = (scenario.get("choices", []) as Array).duplicate()
			_show_choices(current_choices)
		"events":
			var scenario := ContentLoader.get_random_scenario("events", day)
			if scenario.is_empty():
				_show_flavor(venue_name, "The event was cancelled. Something about a 'gas leak.' Sure.")
				return
			_open_panel(venue_name)
			current_activity_type = "events"
			current_activity_id = scenario.get("id", "")
			current_npc_id = scenario.get("npc_id", "")
			activity_text.text = _replace_placeholders(scenario.get("intro_text", "You step up to the stage..."))
			current_choices = (scenario.get("choices", []) as Array).duplicate()
			_show_choices(current_choices)


# ------------------------------------------------------------------ debate (Day 6)

func _start_debate() -> void:
	if day_complete:
		_show_flavor("Town Hall", "[b]The debate is over.[/b]\n\nThe janitor is sweeping up discarded talking points.\n\nPress END DAY when ready.")
		return
	_open_panel("Town Hall — The Debate")
	_load_debate_round()


func _load_debate_round() -> void:
	var round_data := ContentLoader.get_debate_round(debate_round)
	current_activity_type = "debate_rounds"
	current_npc_id = ""

	if round_data.is_empty():
		# Fallback round
		activity_text.text = "[b]DEBATE — ROUND %d[/b]\n\n%s smirks: \"I'm normal. My opponent is not. Questions?\"" % [debate_round, GameManager.opponent_name]
		current_activity_id = ""
		current_choices = [
			{"text": "\"Define 'normal.'\" [Logic]", "skill_check": {"skill": "logic", "difficulty": 10},
				"effects_on_success": [{"op": "stat_add", "stat": "logic", "amount": 2}, {"op": "stat_add", "stat": "influence", "amount": 2}],
				"effects_on_failure": [{"op": "stat_add", "stat": "influence", "amount": -1}]},
			{"text": "\"I HAVEN'T EVEN BEGUN TO PEAK!\" [Speechcraft]", "skill_check": {"skill": "speechcraft", "difficulty": 12},
				"effects_on_success": [{"op": "stat_add", "stat": "speechcraft", "amount": 3}, {"op": "stat_add", "stat": "influence", "amount": 3}],
				"effects_on_failure": [{"op": "stat_add", "stat": "legitimacy", "amount": -2}, {"op": "scandal_add", "headline": "Candidate Screams About 'Peaking'"}]},
		]
	else:
		var intro := "[b]DEBATE — ROUND %d of 3: %s[/b]\n\n" % [debate_round, round_data.get("topic", "Everything")]
		intro += "Moderator: \"%s\"\n\n" % round_data.get("moderator_question", "...")
		intro += "%s: \"%s\"" % [GameManager.opponent_name, round_data.get("opponent_attack", "...")]
		activity_text.text = _replace_placeholders(intro)
		current_activity_id = round_data.get("id", "")
		current_choices = (round_data.get("choices", []) as Array).duplicate()

	_show_choices(current_choices)


func _advance_debate() -> void:
	debate_round += 1
	if debate_round > 3:
		_finish_day_activity()
		activity_text.text += "\n\n[b]The debate ends.[/b] The audience applauds, boos, and one person yells 'FREEBIRD.'\n\nPress END DAY to see the damage."
		return
	var btn := Button.new()
	btn.text = "▶ NEXT ROUND (%d of 3)" % debate_round
	btn.custom_minimum_size = Vector2(0, 40)
	btn.pressed.connect(_load_debate_round)
	choices_container.add_child(btn)


# ------------------------------------------------------------------ election day (Day 7)

func _start_results_rally() -> void:
	if results_shown:
		return
	results_shown = true
	player.input_locked = true
	GameManager.end_game()  # emits game_ended; CampaignSystem records progress
	# Hand off to the Pokemon-style election night screen.
	get_tree().change_scene_to_file("res://scenes/election_night.tscn")


# ------------------------------------------------------------------ choices & dice

func _show_choices(choices: Array) -> void:
	_clear_choices()
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = "▶ " + _replace_placeholders(choice.get("text", "..."))
		var can_select := true
		if choice.has("requires"):
			for skill_name in choice.requires:
				if not SkillSystem.check_skill(skill_name, choice.requires[skill_name]):
					can_select = false
					btn.text += "  [LOCKED]"
					break
		btn.disabled = not can_select
		btn.custom_minimum_size = Vector2(0, 40)
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
			"description": _replace_placeholders(choice.get("text", "Make a check")),
		}
		dice_popup.show_check(check.skill, check.difficulty, context.description, context)
		return

	_apply_choice_directly(choice)


func _on_dice_roll_accepted(result: Dictionary) -> void:
	var choice := pending_choice
	var result_text := ""
	if result.is_crit_success:
		result_text = "[color=gold]★ CRITICAL SUCCESS! ★[/color]\n"
	elif result.is_crit_failure:
		result_text = "[color=red]✖ CRITICAL FAILURE ✖[/color]\n"
	elif result.success:
		result_text = "[color=green]✓ SUCCESS[/color]\n"
	else:
		result_text = "[color=red]✗ FAILURE[/color]\n"

	result_text += "[i]\"%s\"[/i]\n\n" % result.flavor_text
	result_text += "Rolled %d + %d (%s)" % [result.final_roll, result.skill_value, result.skill_display]
	if result.total_modifier != 0:
		result_text += " %+d (modifiers)" % result.total_modifier
	result_text += " = %d vs %d\n" % [result.total, result.difficulty]

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
				"headline": "Campaign Gaffe Goes Viral",
			})

	_log_activity_event(choice)
	activity_text.text = result_text
	pending_choice = {}
	_resolve_activity_step()


func _on_dice_roll_declined() -> void:
	pending_choice = {}
	_show_choices(current_choices)


func _apply_choice_directly(choice: Dictionary) -> void:
	if choice.has("effects"):
		_apply_choice_effects(choice.effects)
	_log_activity_event(choice)
	activity_text.text = "[color=yellow]▶[/color] " + _replace_placeholders(choice.get("text", "..."))
	_resolve_activity_step()


func _resolve_activity_step() -> void:
	_clear_choices()
	_update_status()
	_update_skills_hud()
	if current_activity_type == "debate_rounds":
		_advance_debate()
		return
	if current_activity_type == "canvassing":
		encounters_done_today += 1
		_finish_day_activity()
		if encounters_done_today < 3:
			activity_text.text += "\n\n[i]You can knock on more doors today (%d/3), or press END DAY.[/i]" % encounters_done_today
		return
	_finish_day_activity()
	activity_text.text += "\n\n[i]Press END DAY when ready.[/i]"


func _finish_day_activity() -> void:
	day_complete = true
	next_day_button.disabled = false
	next_day_button.text = "END DAY"
	close_panel_button.visible = true


func _apply_choice_effects(effects: Array) -> void:
	GameManager.apply_effects(effects, {
		"npc_id": current_npc_id,
		"source": current_activity_type,
	})


func _log_activity_event(choice: Dictionary) -> void:
	match current_activity_type:
		"posters":
			GameManager.log_event("poster_placed", {"poster_id": choice.get("id", ""), "text": choice.get("text", "")})
		"fundraisers":
			GameManager.log_event("donor_taken", {"scenario_id": current_activity_id, "choice_text": choice.get("text", "")})
		"events":
			GameManager.log_event("event_attended", {"scenario_id": current_activity_id, "choice_text": choice.get("text", "")})
		"canvassing":
			GameManager.log_event("canvassing_choice", {"scenario_id": current_activity_id, "choice_text": choice.get("text", "")})
		"debate_rounds":
			GameManager.log_event("debate_choice", {"round_id": current_activity_id, "choice_text": choice.get("text", "")})


# ------------------------------------------------------------------ day end / news

func _on_next_day_pressed() -> void:
	if showing_news:
		_continue_from_news()
		return
	if GameManager.current_day == 7:
		activity_text.text = "There are no more days to end. There is only the [b]Town Square[/b], and the count."
		return
	if not day_complete:
		activity_text.text = "Complete today's objective before ending the day. The yellow [color=yellow]![/color] marks the spot."
		return
	_show_news()


var news_broadcast: Control


func _show_news() -> void:
	showing_news = true
	bottom_panel.visible = false
	player.input_locked = true

	if news_broadcast == null:
		news_broadcast = Control.new()
		news_broadcast.set_script(load("res://scripts/news_broadcast.gd"))
		$UILayer.add_child(news_broadcast)
		news_broadcast.finished.connect(_continue_from_news)

	var lead_in := ""
	if GameManager.current_day == 6:
		var scandals_today := 0
		for event in GameManager.event_log:
			if int(event.day) == 6 and event.type == "scandal_triggered":
				scandals_today += 1
		if scandals_today > 0:
			lead_in = "Our top story: pundits are replaying tonight's debate gaffes in slow motion. With a laugh track. We'll show it eleven more times after the break."
		else:
			lead_in = "Our top story: pundits agree the challenger 'held the stage' and 'did not visibly sweat.' In this market, that's a landslide of praise."

	news_broadcast.begin(NewsSystem.generate_daily_news(), GameManager.current_day, lead_in)


func _continue_from_news() -> void:
	showing_news = false
	GameManager.advance_day()
	bottom_panel.visible = false
	player.input_locked = false
	current_activity_type = ""
	current_activity_id = ""
	current_npc_id = ""
	_setup_day()
	if GameManager.current_day == 7:
		if _is_tutorial_run() and not GameManager.get_run_flag("tutorial_day_7_seen"):
			GameManager.set_run_flag("tutorial_day_7_seen", true)
			_show_flavor("CAMPAIGN MANUAL — DAY 7", TUTORIAL_TIPS[7])
		else:
			_show_flavor("Election Day", "[b]It's Election Day.[/b]\n\nThe polls are open. Your stomach is closed.\n\nHead to the Town Square stage when you're ready to face the count.")
		day_complete = true
	else:
		_run_day_intro.call_deferred()


# ------------------------------------------------------------------ panel helpers

func _open_panel(title: String) -> void:
	proximity_hint.visible = false
	panel_location_label.text = title
	close_panel_button.visible = true
	next_day_button.visible = true
	bottom_panel.modulate.a = 0.0
	bottom_panel.visible = true
	player.input_locked = true
	var tw := create_tween()
	tw.tween_property(bottom_panel, "modulate:a", 1.0, 0.15)


func _on_close_panel() -> void:
	if showing_news:
		return
	var tw := create_tween()
	tw.tween_property(bottom_panel, "modulate:a", 0.0, 0.12)
	await tw.finished
	bottom_panel.visible = false
	player.input_locked = false
	_clear_choices()
	if current_activity_type != "debate_rounds":
		current_activity_type = ""
		current_activity_id = ""
		current_npc_id = ""


func _replace_placeholders(text: String) -> String:
	text = text.replace("{player_name}", GameManager.player_name)
	text = text.replace("{opponent_name}", GameManager.opponent_name)
	text = text.replace("{district_name}", GameManager.district_name)
	text = text.replace("{crisis}", GameManager.main_crisis)
	return text
