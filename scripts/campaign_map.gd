extends Control

## The Unlikely Mayor Tour — scenario select map.
## Ten stops on a winding road to the Capital. Win a town, unlock the next.

var selected_id := ""
var stop_buttons: Dictionary = {}  # id -> Button
var info_title: Label
var info_subtitle: Label
var info_body: RichTextLabel
var start_button: Button
var progress_label: Label
var map_area: Control

const STOP_POSITIONS := [
	Vector2(0.08, 0.84), Vector2(0.24, 0.74), Vector2(0.14, 0.56),
	Vector2(0.32, 0.46), Vector2(0.18, 0.28), Vector2(0.38, 0.18),
	Vector2(0.55, 0.30), Vector2(0.66, 0.52), Vector2(0.80, 0.36),
	Vector2(0.88, 0.14),
]


func _ready() -> void:
	SettingsSystem.apply_font_scale(self)
	_build_ui()
	_refresh_stops()
	CampaignSystem.campaign_progress_changed.connect(_refresh_stops)
	# Select first not-yet-won unlocked scenario
	var pick := ""
	for s in CampaignSystem.scenarios:
		var sid := String(s.get("id", ""))
		if CampaignSystem.is_unlocked(s):
			pick = sid
			if not CampaignSystem.has_won(sid):
				break
	if pick != "":
		_select_scenario(pick)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("1a2030")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var header := Label.new()
	header.text = "★ THE UNLIKELY MAYOR TOUR ★"
	header.add_theme_font_size_override("font_size", 26)
	header.add_theme_color_override("font_color", Color("f8d030"))
	header.position = Vector2(32, 18)
	add_child(header)

	progress_label = Label.new()
	progress_label.add_theme_font_size_override("font_size", 14)
	progress_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	progress_label.position = Vector2(34, 52)
	add_child(progress_label)

	# Map area (left)
	map_area = Control.new()
	map_area.position = Vector2(20, 84)
	map_area.size = Vector2(740, 600)
	map_area.draw.connect(_draw_map_path)
	add_child(map_area)

	# Info panel (right)
	var panel := PanelContainer.new()
	panel.position = Vector2(790, 84)
	panel.size = Vector2(460, 540)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	info_subtitle = Label.new()
	info_subtitle.add_theme_font_size_override("font_size", 13)
	info_subtitle.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	vbox.add_child(info_subtitle)

	info_title = Label.new()
	info_title.add_theme_font_size_override("font_size", 22)
	info_title.add_theme_color_override("font_color", Color("f8d030"))
	info_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info_title)

	info_body = RichTextLabel.new()
	info_body.bbcode_enabled = true
	info_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_body.custom_minimum_size = Vector2(0, 320)
	vbox.add_child(info_body)

	start_button = Button.new()
	start_button.text = "▶ START THIS ELECTION"
	start_button.custom_minimum_size = Vector2(0, 48)
	start_button.pressed.connect(_on_start_pressed)
	vbox.add_child(start_button)

	var back_button := Button.new()
	back_button.text = "◀ BACK TO MENU"
	back_button.custom_minimum_size = Vector2(0, 40)
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	vbox.add_child(back_button)

	# Stop buttons
	for i in range(CampaignSystem.scenarios.size()):
		var scenario: Dictionary = CampaignSystem.scenarios[i]
		var sid := String(scenario.get("id", ""))
		var pos: Vector2 = STOP_POSITIONS[i % STOP_POSITIONS.size()]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(58, 58)
		btn.position = Vector2(pos.x * map_area.size.x, pos.y * map_area.size.y)
		btn.pressed.connect(_select_scenario.bind(sid))
		map_area.add_child(btn)
		stop_buttons[sid] = btn

		var lbl := Label.new()
		lbl.text = String(scenario.get("title", ""))
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
		lbl.position = btn.position + Vector2(-12, 60)
		map_area.add_child(lbl)


func _draw_map_path() -> void:
	var pts: Array = []
	for i in range(CampaignSystem.scenarios.size()):
		var pos: Vector2 = STOP_POSITIONS[i % STOP_POSITIONS.size()]
		pts.append(Vector2(pos.x * map_area.size.x + 29, pos.y * map_area.size.y + 29))
	for i in range(pts.size() - 1):
		var won: bool = CampaignSystem.has_won(String(CampaignSystem.scenarios[i].get("id", "")))
		var col := Color("f8d030") if won else Color(0.4, 0.45, 0.55)
		map_area.draw_line(pts[i], pts[i + 1], col, 4.0)
		# dashes
		var mid: Vector2 = (pts[i] + pts[i + 1]) / 2.0
		map_area.draw_circle(mid, 3.0, Color(0.1, 0.12, 0.18))


func _refresh_stops() -> void:
	var won_count := CampaignSystem.get_won_count()
	progress_label.text = "Gavels collected: %d / %d   %s" % [
		won_count, CampaignSystem.scenarios.size(),
		"— THE TOUR IS COMPLETE. MOM IS THRILLED." if CampaignSystem.is_tour_complete() else ""
	]
	for s in CampaignSystem.scenarios:
		var sid := String(s.get("id", ""))
		if not stop_buttons.has(sid):
			continue
		var btn: Button = stop_buttons[sid]
		var idx := int(s.get("index", 0))
		if CampaignSystem.has_won(sid):
			btn.text = "★\n%d" % idx
			btn.modulate = Color("78e07a")
			btn.disabled = false
		elif CampaignSystem.is_unlocked(s):
			btn.text = "%d" % idx
			btn.modulate = Color("f8d030")
			btn.disabled = false
		else:
			btn.text = "🔒"
			btn.modulate = Color(0.5, 0.5, 0.55)
			btn.disabled = true
	map_area.queue_redraw()


func _select_scenario(sid: String) -> void:
	selected_id = sid
	var s := CampaignSystem.get_scenario(sid)
	if s.is_empty():
		return
	info_subtitle.text = "STOP %d — %s" % [int(s.get("index", 0)), String(s.get("subtitle", ""))]
	info_title.text = String(s.get("title", ""))

	var body := ""
	body += "[b]District:[/b] %s\n" % s.get("district_name", "?")
	body += "[b]Crisis:[/b] %s\n\n" % s.get("main_crisis", "?")
	body += "[b]Opponent:[/b] %s\n" % s.get("opponent_name", "?")
	body += "[i]%s[/i]\n\n" % s.get("opponent_tagline", "")

	var mods: Dictionary = s.get("modifiers", {})
	var mod_bits: Array = []
	for stat in mods.get("skill_mods", {}):
		mod_bits.append("%s %+d" % [String(stat).capitalize(), int(mods.skill_mods[stat])])
	if int(mods.get("start_support", 0)) != 0:
		mod_bits.append("Starting support %+d" % int(mods.get("start_support", 0)))
	if not mod_bits.is_empty():
		body += "[b]Local conditions:[/b] %s\n\n" % ", ".join(mod_bits)

	if CampaignSystem.has_won(sid):
		body += "[color=green]✔ You won this town. Replay any time.[/color]"
	else:
		body += "[color=yellow]Win here to unlock the next stop.[/color]"
	info_body.text = body
	start_button.disabled = false


func _on_start_pressed() -> void:
	if selected_id == "":
		return
	if not CampaignSystem.start_campaign_scenario(selected_id):
		return
	SaveSystem.save_to_slot(SaveSystem.active_slot, true)
	get_tree().change_scene_to_file("res://scenes/scenario_intro.tscn")
