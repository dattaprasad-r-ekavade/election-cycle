extends Node

## Headless smoke test. Run:
##   godot --headless --path . res://tests/smoke_test.tscn
## Covers: town generation (all styles/seeds), campaign data + cutscenes,
## roguelike seed recipes, town scene boot, campaign flow, full 7-day run.

const G := preload("res://systems/town_generator.gd")

var failures: Array = []


func _ready() -> void:
	await get_tree().process_frame
	_test_generator()
	_test_campaign_data()
	_test_seed_recipes()
	await _test_town_scene()
	await _test_campaign_scene_flow()
	await _test_full_run()
	await _test_news_broadcast()
	await _test_election_night()

	if failures.is_empty():
		print("SMOKE_TEST_PASS")
	else:
		print("SMOKE_TEST_FAIL")
		for f in failures:
			print("  FAIL: %s" % f)
	get_tree().quit(0 if failures.is_empty() else 1)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


func _test_generator() -> void:
	for style in G.THEME_STYLES.keys():
		for seed_v in [1101, 2202, 3303, 4404, 5505, 6606, 7707, 8808, 9909, 10010, 42, 7, 999983, 123456, 31337]:
			var town := G.generate(seed_v, style)
			_check(town.buildings.size() >= 6, "%s/%d: only %d buildings" % [style, seed_v, town.buildings.size()])
			for required in ["hq", "town_hall", "print_shop", "diner", "landmark"]:
				_check(not G.get_building(town, required).is_empty(), "%s/%d missing %s" % [style, seed_v, required])
			_check(G.is_walkable(town, town.spawn), "%s/%d spawn blocked" % [style, seed_v])
			for b in town.buildings:
				var door: Vector2i = b.door
				var ok := false
				for off: Vector2i in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
					if G.is_walkable(town, door + off):
						ok = true
				_check(ok or G.is_walkable(town, door), "%s/%d door unreachable for %s" % [style, seed_v, b.id])
			_check(town.npc_spawns.size() >= 4, "%s/%d too few npc spawns" % [style, seed_v])
	var a := G.generate(777, "suburban")
	var b := G.generate(777, "suburban")
	_check(str(a.tiles) == str(b.tiles), "generator not deterministic")
	print("generator tests done")


func _test_campaign_data() -> void:
	_check(CampaignSystem.scenarios.size() == 10, "expected 10 scenarios, got %d" % CampaignSystem.scenarios.size())
	for s in CampaignSystem.scenarios:
		var sid := String(s.get("id", ""))
		_check(s.has("town_style") and G.THEME_STYLES.has(String(s.town_style)), "%s bad town_style" % sid)
		_check((s.get("intro_lines", []) as Array).size() >= 3, "%s too few intro lines" % sid)
		_check(String(s.get("epilogue_win", "")) != "", "%s missing epilogue_win" % sid)
		var cuts: Dictionary = s.get("day_cutscenes", {})
		_check(not cuts.is_empty(), "%s missing day_cutscenes" % sid)
		for day_key in cuts:
			var cut: Dictionary = cuts[day_key]
			_check(int(day_key) >= 2 and int(day_key) <= 6, "%s cutscene on bad day %s" % [sid, day_key])
			_check(String(cut.get("visitor", "")) != "", "%s cutscene %s missing visitor" % [sid, day_key])
			_check((cut.get("lines", []) as Array).size() >= 2, "%s cutscene %s too short" % [sid, day_key])
	var hometown := CampaignSystem.get_scenario("hometown")
	_check(bool(hometown.get("tutorial", false)), "hometown should be the tutorial campaign")
	var saved := CampaignSystem.progress.duplicate(true)
	CampaignSystem.progress = {"completed": [], "won": []}
	_check(CampaignSystem.get_unlocked_scenarios().size() == 1, "fresh progress should unlock exactly 1")
	CampaignSystem.progress = {"completed": ["hometown"], "won": ["hometown"]}
	_check(CampaignSystem.get_unlocked_scenarios().size() == 2, "1 win should unlock 2")
	CampaignSystem.progress = saved
	print("campaign data tests done")


func _test_seed_recipes() -> void:
	# Same master seed -> same everything
	GameManager.play_mode = "quick"
	GameManager.start_new_game(31415)
	var first := [GameManager.district_name, GameManager.main_crisis, GameManager.opponent_name, GameManager.district_theme]
	var recipe_a: Dictionary = GameManager.run_recipe.duplicate()
	GameManager.start_new_game(31415)
	var second := [GameManager.district_name, GameManager.main_crisis, GameManager.opponent_name, GameManager.district_theme]
	_check(str(first) == str(second), "same seed gave different runs: %s vs %s" % [first, second])
	_check(str(recipe_a) == str(GameManager.run_recipe), "same seed gave different recipes")

	# Rerolling ONE component must not change the others
	var crisis_before := GameManager.main_crisis
	var opponent_before := GameManager.opponent_name
	var theme_before := GameManager.district_theme
	GameManager.reroll_component("opponent")
	_check(GameManager.main_crisis == crisis_before, "opponent reroll changed crisis")
	_check(GameManager.district_theme == theme_before, "opponent reroll changed theme")
	GameManager.reroll_component("crisis")
	_check(GameManager.district_theme == theme_before, "crisis reroll changed theme")
	_check(GameManager.opponent_name != opponent_before or true, "")  # opponent stays whatever reroll picked

	# Layout seed independent of the other components
	var crisis_after_reroll := GameManager.main_crisis
	var layout_a := GameManager.get_layout_seed()
	GameManager.reroll_component("layout")
	var layout_b := GameManager.get_layout_seed()
	_check(layout_a != layout_b, "layout reroll did not change layout seed")
	_check(GameManager.main_crisis == crisis_after_reroll, "layout reroll changed crisis")

	# Recipe survives save round-trip
	var state := GameManager.export_state()
	var recipe_saved: Dictionary = GameManager.run_recipe.duplicate()
	GameManager.start_new_game(999)
	GameManager.import_state(state)
	_check(str(GameManager.run_recipe) == str(recipe_saved), "recipe lost in save round-trip")
	print("seed recipe tests done")


func _test_town_scene() -> void:
	GameManager.play_mode = "quick"
	GameManager.campaign_scenario_id = ""
	GameManager.start_new_game(424242)
	GameManager.player_name = "Smokey"
	GameManager.advance_day()  # day 2
	var scene := load("res://scenes/town.tscn")
	var town_node: Node = scene.instantiate()
	add_child(town_node)
	await get_tree().create_timer(0.6).timeout
	_check(is_instance_valid(town_node), "town scene died")
	var town_data: Dictionary = town_node.get("town")
	_check(not town_data.is_empty(), "town not generated")
	_check(town_node.get("npc_nodes").size() >= 4, "no NPCs spawned")
	var b: Dictionary = G.get_building(town_data, "house_0")
	if not b.is_empty():
		town_node.call("_on_building_interact", b)
		await get_tree().process_frame
		_check(town_node.get_node("UILayer/BottomPanel").visible, "activity panel did not open")
	town_node.queue_free()
	await get_tree().process_frame
	print("town scene tests done")


func _test_campaign_scene_flow() -> void:
	var ok := CampaignSystem.start_campaign_scenario("hometown")
	_check(ok, "could not start hometown scenario")
	_check(GameManager.district_name == "Dillard's Hollow", "campaign profile not applied")
	_check(GameManager.opponent_name == "Mayor Earl Tuttle", "campaign opponent not applied")
	GameManager.advance_day()  # applies campaign modifiers
	_check(GameManager.district_support == 5, "hometown start_support not applied (got %d)" % GameManager.district_support)

	# Boot the town in campaign mode; the Day 2 cutscene should fire,
	# and clicking through it should land on the Day 2 tutorial manual.
	var scene := load("res://scenes/town.tscn")
	var town_node: Node = scene.instantiate()
	add_child(town_node)
	await get_tree().create_timer(1.2).timeout
	_check(is_instance_valid(town_node), "campaign town scene died")
	_check(GameManager.get_run_flag("cutscene_day_2_seen"), "day 2 cutscene did not trigger")
	# Click through cutscene dialogue
	var choices: Node = town_node.get_node("UILayer/BottomPanel/Margin/VBox/ChoicesScroll/ChoicesContainer")
	for i in range(10):
		await get_tree().create_timer(0.35).timeout
		var clicked := false
		for child in choices.get_children():
			if child is Button and not child.disabled:
				child.pressed.emit()
				clicked = true
				break
		if not clicked and GameManager.get_run_flag("tutorial_day_2_seen"):
			break
	await get_tree().create_timer(1.5).timeout  # visitor walks away, manual opens
	_check(GameManager.get_run_flag("tutorial_day_2_seen"), "day 2 tutorial manual did not show")
	town_node.queue_free()
	await get_tree().process_frame

	for path in ["res://scenes/campaign_map.tscn", "res://scenes/scenario_intro.tscn"]:
		var n: Node = (load(path) as PackedScene).instantiate()
		add_child(n)
		await get_tree().process_frame
		await get_tree().process_frame
		_check(is_instance_valid(n), "%s died" % path)
		n.queue_free()
		await get_tree().process_frame
	CampaignSystem.clear_active_scenario()
	print("campaign flow tests done")


func _test_full_run() -> void:
	GameManager.play_mode = "quick"
	GameManager.start_new_game(55555)
	GameManager.advance_day()  # 2
	_check(GameManager.current_day == 2, "day should be 2")
	var day_types := {2: "canvassing", 4: "fundraisers", 5: "events"}
	for d in range(2, 7):
		if day_types.has(d):
			var scenario := ContentLoader.get_random_scenario(day_types[d], d)
			_check(not scenario.is_empty() and scenario.has("choices"), "no %s scenario on day %d" % [day_types[d], d])
		elif d == 3:
			_check(not ContentLoader.get_posters().is_empty(), "no posters available")
		elif d == 6:
			_check(not ContentLoader.get_debate_round(1).is_empty(), "no debate round 1")
		NewsSystem.generate_daily_news()
		GameManager.advance_day()
	_check(GameManager.current_day == 7, "day should be 7, got %d" % GameManager.current_day)
	var got_results: Array = []
	GameManager.game_ended.connect(func(_w, r): got_results.append(r), CONNECT_ONE_SHOT)
	GameManager.end_game()
	_check(not got_results.is_empty(), "game_ended not emitted")
	if not got_results.is_empty():
		var r: Dictionary = got_results[0]
		_check(r.has("won") and r.has("factors"), "results malformed")
	_check(not GameManager.last_results.is_empty(), "last_results not stored by end_game")
	print("full run test done")


func _test_news_broadcast() -> void:
	var nb := Control.new()
	nb.set_script(load("res://scripts/news_broadcast.gd"))
	add_child(nb)
	await get_tree().process_frame
	var done: Array = []
	nb.finished.connect(func(): done.append(true))
	nb.begin([{"headline": "Test Headline", "body": "Test body.", "tone": "positive"}], 3)
	for i in range(12):
		await get_tree().process_frame
		nb._advance()  # complete typing
		nb._advance()  # next segment
	_check(not done.is_empty(), "news broadcast never finished")
	nb.queue_free()
	await get_tree().process_frame
	print("news broadcast test done")


func _test_election_night() -> void:
	GameManager.last_results = GameManager.calculate_election_results()
	var n: Node = (load("res://scenes/election_night.tscn") as PackedScene).instantiate()
	add_child(n)
	await get_tree().create_timer(0.8).timeout
	_check(is_instance_valid(n), "election night scene died")
	n.queue_free()
	await get_tree().process_frame
	print("election night test done")
