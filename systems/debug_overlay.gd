extends CanvasLayer

## Debug Overlay - Toggleable dev panel (F3)
## Shows all game state for inspection during development

var panel: PanelContainer
var content_label: RichTextLabel
var is_visible := false
var auto_refresh := true
var refresh_timer := 0.0
const REFRESH_INTERVAL := 0.5  # Update every 0.5 seconds


func _ready() -> void:
	layer = 100  # Always on top
	_build_ui()
	print("[DebugOverlay] Initialized (F3 to toggle)")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			_toggle()
		elif event.keycode == KEY_F4 and is_visible:
			auto_refresh = not auto_refresh
			print("[DebugOverlay] Auto-refresh: %s" % ("ON" if auto_refresh else "OFF"))
		elif event.keycode == KEY_F5:
			_run_seed_test()


func _process(delta: float) -> void:
	if not is_visible or not auto_refresh:
		return
	refresh_timer += delta
	if refresh_timer >= REFRESH_INTERVAL:
		refresh_timer = 0.0
		_update_content()


func _toggle() -> void:
	is_visible = not is_visible
	panel.visible = is_visible
	if is_visible:
		_update_content()


func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.visible = false

	# Style the panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.92)
	style.border_color = Color(0.3, 0.8, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)

	# Position: right side of screen
	panel.anchor_left = 0.55
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 5
	panel.offset_right = -5
	panel.offset_top = 5
	panel.offset_bottom = -5

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	content_label = RichTextLabel.new()
	content_label.bbcode_enabled = true
	content_label.fit_content = true
	content_label.custom_minimum_size = Vector2(400, 0)
	content_label.add_theme_font_size_override("normal_font_size", 12)
	content_label.add_theme_font_size_override("bold_font_size", 13)
	scroll.add_child(content_label)

	add_child(panel)


func _update_content() -> void:
	var text := ""

	text += "[b][color=lime]═══ DEBUG OVERLAY (F3 close, F4 pause) ═══[/color][/b]\n\n"

	# Game State
	text += "[b][color=cyan]GAME STATE[/color][/b]\n"
	text += "  Day: %d / %d (%s)\n" % [GameManager.current_day, GameManager.MAX_DAYS, GameManager.get_day_name()]
	text += "  Phase: %s\n" % GameManager.GamePhase.keys()[GameManager.current_phase]
	text += "  Seed: [color=yellow]%d[/color]\n" % GameManager.run_seed
	text += "  Player: %s\n" % GameManager.player_name
	text += "  Slogan: %s\n" % GameManager.campaign_slogan
	text += "\n"

	# District
	text += "[b][color=cyan]DISTRICT[/color][/b]\n"
	text += "  Name: %s\n" % GameManager.district_name
	text += "  Theme: %s\n" % GameManager.district_theme
	text += "  Crisis: %s\n" % GameManager.main_crisis
	text += "  Opponent: %s (%s)\n" % [GameManager.opponent_name, GameManager.opponent_archetype]
	text += "  Media Bias: %+.2f\n" % GameManager.media_bias
	text += "\n"

	# Skills
	text += "[b][color=cyan]SKILLS (base + mod = effective)[/color][/b]\n"
	for skill_name in SkillSystem.SKILL_NAMES:
		var base: int = SkillSystem.get_base_skill(skill_name)
		var mod: int = SkillSystem.modifiers.get(skill_name, 0)
		var effective: int = SkillSystem.get_skill(skill_name)
		var mod_text := ""
		if mod != 0:
			mod_text = " [color=yellow]%+d[/color]" % mod
		text += "  %s: %d%s = [b]%d[/b]\n" % [SkillSystem.get_skill_display_name(skill_name), base, mod_text, effective]
	text += "  Allocation pts: %d\n" % SkillSystem.allocation_points
	text += "\n"

	# Perks
	text += "[b][color=cyan]PERKS (%d/%d slots)[/color][/b]\n" % [PerkSystem.active_perks.size(), PerkSystem.perk_slots]
	if PerkSystem.active_perks.is_empty():
		text += "  (none)\n"
	else:
		for perk_id in PerkSystem.active_perks:
			var perk: Dictionary = PerkSystem.get_perk_data(perk_id)
			var usage: Dictionary = PerkSystem.perk_usage.get(perk_id, {})
			var usage_text := ""
			if usage.get("times_used", 0) > 0:
				usage_text = " [used:%d]" % usage.times_used
			text += "  %s %s%s\n" % [perk.get("icon", "?"), perk.get("name", perk_id), usage_text]
	text += "\n"

	# Trust
	text += "[b][color=cyan]TRUST[/color][/b]\n"
	text += "  District Support: [b]%d[/b]\n" % GameManager.district_support
	text += "  Weighted NPC: [b]%.1f[/b]\n" % GameManager.get_weighted_npc_support()
	text += "  Total Support: [b]%.1f[/b]\n" % GameManager.get_total_support()
	if not GameManager.npc_trust.is_empty():
		text += "  NPCs:\n"
		for npc_id in GameManager.npc_trust:
			var data: Dictionary = GameManager.npc_trust[npc_id]
			var trust_color := "green" if data.trust > 0 else ("red" if data.trust < 0 else "white")
			text += "    %s: [color=%s]%+d[/color] (inf:%d)\n" % [data.name, trust_color, data.trust, data.influence]
	text += "\n"

	# Promises
	text += "[b][color=cyan]PROMISES (%d made, %d broken)[/color][/b]\n" % [GameManager.promises_made.size(), GameManager.promises_broken.size()]
	for promise in GameManager.promises_made:
		var broken := GameManager.promises_broken.has(promise)
		var status_text := "[color=red]BROKEN[/color]" if broken else "[color=green]active[/color]"
		text += "  [%s] %s (%s)\n" % [promise.get("id", "?"), promise.get("text", "?"), status_text]
	if not GameManager.promise_contradictions.is_empty():
		text += "  [color=orange]Contradictions:[/color]\n"
		for c in GameManager.promise_contradictions:
			text += "    ! %s\n" % c.get("description", "?")
	text += "\n"

	# Scandals
	text += "[b][color=cyan]SCANDALS (%d)[/color][/b]\n" % GameManager.scandals.size()
	for scandal in GameManager.scandals:
		text += "  [color=red]Day %d: %s[/color]\n" % [scandal.get("day", 0), scandal.get("headline", "?")]
	if not GameManager.scandal_risks.is_empty():
		text += "  Risks:\n"
		for risk in GameManager.scandal_risks:
			text += "    %.0f%%: %s\n" % [risk.get("chance", 0.0) * 100, risk.get("headline", "?")]
	text += "\n"

	# Endorsements
	text += "[b][color=cyan]ENDORSEMENTS (%d)[/color][/b]\n" % GameManager.endorsements.size()
	for e in GameManager.endorsements:
		text += "  [color=green]%s[/color]\n" % e
	text += "\n"

	# Run Flags
	text += "[b][color=cyan]FLAGS (%d)[/color][/b]\n" % GameManager.run_flags.size()
	for flag_name in GameManager.run_flags:
		text += "  %s = %s\n" % [flag_name, GameManager.run_flags[flag_name]]
	text += "\n"

	# Hidden Params Summary
	text += "[b][color=cyan]HIDDEN PARAMS[/color][/b]\n"
	var hp := GameManager.hidden_params
	text += "  Weather: %s (%+.1f)\n" % [hp.get("election_weather", "?"), hp.get("weather_turnout_modifier", 0.0)]
	text += "  Economy: %s (%+.1f)\n" % [hp.get("economy", "?"), hp.get("economy_modifier", 0.0)]
	text += "  Mood: %s\n" % hp.get("national_mood", "?")
	text += "  Local Event: %s (%+.1f)\n" % [hp.get("local_event", "none"), hp.get("local_event_modifier", 0.0)]
	text += "  Anti-incumbent: %s\n" % hp.get("anti_incumbent_wave", false)
	text += "  Opp. Name Recog: %.0f%%\n" % (hp.get("opponent_name_recognition", 0.0) * 100)
	text += "  Opp. Ground Game: %.0f%%\n" % (hp.get("opponent_ground_game", 0.0) * 100)
	text += "  Opp. Gaffe-prone: %s\n" % hp.get("opponent_gaffe_prone", false)
	text += "  [b]Net Modifier: %+.1f[/b]\n" % hp.get("net_hidden_modifier", 0.0)
	text += "\n"

	# Event Log (last 10)
	text += "[b][color=cyan]EVENT LOG (last 10)[/color][/b]\n"
	var log_entries: Array = GameManager.event_log
	var start_idx := maxi(0, log_entries.size() - 10)
	for i in range(start_idx, log_entries.size()):
		var entry: Dictionary = log_entries[i]
		text += "  D%d: %s\n" % [entry.get("day", 0), entry.get("type", "?")]
	if log_entries.is_empty():
		text += "  (empty)\n"

	content_label.text = text


func _run_seed_test() -> void:
	"""Run deterministic seed test from debug overlay (F5)"""
	print("[DebugOverlay] Running seed determinism test...")
	var test_script: Script = load("res://tests/seed_test_logic.gd")
	var runner: Node = test_script.new()
	var result: Dictionary = runner.run()
	var status := "PASSED" if bool(result.get("passed", false)) else "FAILED"
	print("[DebugOverlay] Seed test %s. %s" % [status, String(result.get("details", "")).strip_edges()])
