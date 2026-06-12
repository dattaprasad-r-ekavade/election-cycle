extends Control

## Election Night — Pokemon-victory-screen style results.
## Candidate face-off, animated vote bar race, big banner, epilogue.

const AVATAR_SCRIPT := preload("res://scripts/character_avatar.gd")

var results: Dictionary = {}
var player_bar: ColorRect
var opponent_bar: ColorRect
var player_pct_label: Label
var opponent_pct_label: Label
var banner_label: Label
var detail_text: RichTextLabel
var buttons_box: VBoxContainer

const BAR_MAX_W := 420.0


func _ready() -> void:
	SettingsSystem.apply_font_scale(self)
	results = GameManager.last_results
	if results.is_empty():
		results = GameManager.calculate_election_results()
	_build_ui()
	_run_sequence()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("10182a")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var header := Label.new()
	header.text = "★  ELECTION NIGHT — %s  ★" % GameManager.district_name.to_upper()
	header.add_theme_font_size_override("font_size", 26)
	header.add_theme_color_override("font_color", Color("f8d030"))
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.offset_top = 24.0
	add_child(header)

	# Candidates
	var player_avatar := Node2D.new()
	player_avatar.set_script(AVATAR_SCRIPT)
	player_avatar.position = Vector2(310, 150)
	player_avatar.scale = Vector2(5.0, 5.0)
	add_child(player_avatar)

	var opponent_avatar := Node2D.new()
	opponent_avatar.set_script(AVATAR_SCRIPT)
	opponent_avatar.position = Vector2(860, 150)
	opponent_avatar.scale = Vector2(5.0, 5.0)
	add_child(opponent_avatar)
	opponent_avatar.set_palette({
		"shirt": Color("303848"), "pants": Color("282838"),
		"hair": Color("484038"), "has_hat": false,
	})

	var vs := Label.new()
	vs.text = "VS"
	vs.add_theme_font_size_override("font_size", 44)
	vs.add_theme_color_override("font_color", Color("e05050"))
	vs.position = Vector2(610, 200)
	add_child(vs)

	var p_name := Label.new()
	p_name.text = GameManager.player_name.to_upper()
	p_name.add_theme_font_size_override("font_size", 18)
	p_name.position = Vector2(240, 320)
	p_name.size = Vector2(280, 24)
	p_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(p_name)

	var o_name := Label.new()
	o_name.text = GameManager.opponent_name.to_upper()
	o_name.add_theme_font_size_override("font_size", 18)
	o_name.position = Vector2(790, 320)
	o_name.size = Vector2(280, 24)
	o_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(o_name)

	# Vote bars
	var p_back := ColorRect.new()
	p_back.color = Color(1, 1, 1, 0.08)
	p_back.position = Vector2(170, 356)
	p_back.size = Vector2(BAR_MAX_W, 30)
	add_child(p_back)
	player_bar = ColorRect.new()
	player_bar.color = Color("4878d0")
	player_bar.position = p_back.position
	player_bar.size = Vector2(0, 30)
	add_child(player_bar)
	player_pct_label = Label.new()
	player_pct_label.position = Vector2(170, 392)
	player_pct_label.add_theme_font_size_override("font_size", 15)
	add_child(player_pct_label)

	var o_back := ColorRect.new()
	o_back.color = Color(1, 1, 1, 0.08)
	o_back.position = Vector2(690, 356)
	o_back.size = Vector2(BAR_MAX_W, 30)
	add_child(o_back)
	opponent_bar = ColorRect.new()
	opponent_bar.color = Color("d05050")
	opponent_bar.position = o_back.position
	opponent_bar.size = Vector2(0, 30)
	add_child(opponent_bar)
	opponent_pct_label = Label.new()
	opponent_pct_label.position = Vector2(690, 392)
	opponent_pct_label.add_theme_font_size_override("font_size", 15)
	add_child(opponent_pct_label)

	# Banner (hidden until the count finishes)
	banner_label = Label.new()
	banner_label.add_theme_font_size_override("font_size", 52)
	banner_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.offset_top = 430.0
	banner_label.modulate.a = 0.0
	add_child(banner_label)

	# Details + buttons
	detail_text = RichTextLabel.new()
	detail_text.bbcode_enabled = true
	detail_text.position = Vector2(170, 506)
	detail_text.size = Vector2(620, 190)
	detail_text.modulate.a = 0.0
	add_child(detail_text)

	buttons_box = VBoxContainer.new()
	buttons_box.position = Vector2(850, 510)
	buttons_box.size = Vector2(260, 180)
	buttons_box.add_theme_constant_override("separation", 10)
	buttons_box.modulate.a = 0.0
	add_child(buttons_box)


func _run_sequence() -> void:
	await get_tree().create_timer(0.5).timeout

	var p_pct: float = 50.0 + float(results.margin) / 2.0
	var o_pct: float = 100.0 - p_pct

	# Vote bar race
	var tw := create_tween().set_parallel(true)
	tw.tween_method(_set_player_bar, 0.0, p_pct, 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_opponent_bar, 0.0, o_pct, 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished
	await get_tree().create_timer(0.4).timeout

	# Banner
	var won: bool = results.won
	banner_label.text = "★ ★ ★  VICTORY!  ★ ★ ★" if won else "—  DEFEAT  —"
	banner_label.add_theme_color_override("font_color", Color("f8d030") if won else Color("9098a8"))
	banner_label.scale = Vector2(2.2, 2.2)
	banner_label.pivot_offset = Vector2(size.x / 2.0, 30)
	var bt := create_tween().set_parallel(true)
	bt.tween_property(banner_label, "modulate:a", 1.0, 0.35)
	bt.tween_property(banner_label, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await bt.finished

	if won:
		_spawn_confetti()

	_fill_details()
	var dt := create_tween().set_parallel(true)
	dt.tween_property(detail_text, "modulate:a", 1.0, 0.4)
	dt.tween_property(buttons_box, "modulate:a", 1.0, 0.4)
	_build_buttons()


func _set_player_bar(pct: float) -> void:
	player_bar.size.x = BAR_MAX_W * pct / 100.0
	player_pct_label.text = "%.1f%%  (%d votes)" % [pct, int(pct * 1000)]


func _set_opponent_bar(pct: float) -> void:
	opponent_bar.size.x = BAR_MAX_W * pct / 100.0
	opponent_pct_label.text = "%.1f%%  (%d votes)" % [pct, int(pct * 1000)]


func _spawn_confetti() -> void:
	var colors := [Color("f8d030"), Color("e85048"), Color("4878d0"), Color("48a868"), Color("f06890")]
	for i in range(50):
		var c := ColorRect.new()
		c.color = colors[i % colors.size()]
		c.size = Vector2(8, 12)
		c.position = Vector2(randf_range(0, size.x), randf_range(-300, -20))
		c.rotation = randf_range(0, TAU)
		add_child(c)
		var fall := create_tween().set_parallel(true)
		fall.tween_property(c, "position:y", size.y + 40.0, randf_range(2.0, 4.5))
		fall.tween_property(c, "rotation", c.rotation + randf_range(-6, 6), 4.0)
		fall.chain().tween_callback(c.queue_free)


func _fill_details() -> void:
	var text := ""
	if results.won:
		text += "Against all odds (and several focus groups), you won.\n\n"
	else:
		text += "Democracy has spoken. It said 'no.' Then it muted you.\n\n"

	var factor_rows: Array = []
	for factor_name in results.factors.keys():
		factor_rows.append({"name": String(factor_name), "value": float(results.factors[factor_name])})
	factor_rows.sort_custom(func(a, b): return absf(a.value) > absf(b.value))
	text += "[b]WHAT DECIDED IT[/b]\n"
	for i in range(mini(4, factor_rows.size())):
		var item: Dictionary = factor_rows[i]
		var color := "green" if item.value >= 0 else "red"
		text += "• %s: [color=%s]%+.1f[/color]\n" % [item.name.capitalize().replace("_", " "), color, item.value]

	if GameManager.scandals.size() > 0:
		text += "\n[b]SCANDALS:[/b] [color=red]%d[/color] (they remember)\n" % GameManager.scandals.size()

	if GameManager.play_mode == "campaign":
		var scen: Dictionary = CampaignSystem.get_scenario(GameManager.campaign_scenario_id)
		var epilogue := String(scen.get("epilogue_win" if results.won else "epilogue_lose", ""))
		if epilogue != "":
			text += "\n[i]%s[/i]\n" % epilogue
		if results.won and int(scen.get("index", 0)) < 10:
			text += "\n[color=yellow]★ A new town is open on the Tour Map![/color]"
		if CampaignSystem.is_tour_complete():
			text += "\n\n[color=gold][b]HALL OF FAME[/b] — Ten towns. Ten gavels. One extremely tired mayor. Mom is thrilled.[/color]"

	detail_text.text = text


func _build_buttons() -> void:
	if GameManager.play_mode == "campaign":
		var tour_btn := Button.new()
		tour_btn.text = "▶  BACK TO THE TOUR MAP"
		tour_btn.custom_minimum_size = Vector2(0, 46)
		tour_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/campaign_map.tscn"))
		buttons_box.add_child(tour_btn)
	else:
		var again_btn := Button.new()
		again_btn.text = "▶  RUN AGAIN"
		again_btn.custom_minimum_size = Vector2(0, 46)
		again_btn.pressed.connect(func():
			CampaignSystem.clear_active_scenario()
			GameManager.start_new_game()
			get_tree().change_scene_to_file("res://scenes/character_creation.tscn")
		)
		buttons_box.add_child(again_btn)

	var menu_btn := Button.new()
	menu_btn.text = "▶  MAIN MENU"
	menu_btn.custom_minimum_size = Vector2(0, 46)
	menu_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	buttons_box.add_child(menu_btn)
