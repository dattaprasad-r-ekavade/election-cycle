extends Control

## Campaign scenario intro cutscene: title card + scripted dialogue,
## then on to character creation.

var lines: Array = []
var line_index := -1
var scenario: Dictionary = {}

var title_label: Label
var subtitle_label: Label
var speaker_label: Label
var line_label: RichTextLabel
var hint_label: Label
var showing_title := true


func _ready() -> void:
	SettingsSystem.apply_font_scale(self)
	scenario = CampaignSystem.get_active_scenario()
	if scenario.is_empty():
		get_tree().change_scene_to_file("res://scenes/character_creation.tscn")
		return
	lines = scenario.get("intro_lines", [])
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("141824")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.position = Vector2(640, 220)
	center.add_theme_constant_override("separation", 10)
	add_child(center)

	subtitle_label = Label.new()
	subtitle_label.text = "STOP %d — %s" % [int(scenario.get("index", 0)), String(scenario.get("subtitle", ""))]
	subtitle_label.add_theme_font_size_override("font_size", 16)
	subtitle_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(subtitle_label)

	title_label = Label.new()
	title_label.text = String(scenario.get("title", ""))
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.add_theme_color_override("font_color", Color("f8d030"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title_label)

	var district_label := Label.new()
	district_label.text = String(scenario.get("district_name", ""))
	district_label.add_theme_font_size_override("font_size", 18)
	district_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	district_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(district_label)

	center.custom_minimum_size = Vector2(600, 0)
	center.position = Vector2(340, 200)

	# Dialogue panel (hidden during title card)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 80
	panel.offset_right = -80
	panel.offset_top = -190
	panel.offset_bottom = -30
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 17)
	speaker_label.add_theme_color_override("font_color", Color("f8d030"))
	vbox.add_child(speaker_label)

	line_label = RichTextLabel.new()
	line_label.bbcode_enabled = true
	line_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	line_label.custom_minimum_size = Vector2(0, 70)
	vbox.add_child(line_label)

	hint_label = Label.new()
	hint_label.text = "Press Enter to continue.  Esc to skip."
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.68))
	vbox.add_child(hint_label)

	speaker_label.text = ""
	line_label.text = "[i]Press Enter...[/i]"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if showing_title:
			showing_title = false
			_show_next_line()
		elif line_label.visible_ratio < 1.0:
			line_label.visible_ratio = 1.0
		else:
			_show_next_line()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_finish()


func _show_next_line() -> void:
	line_index += 1
	if line_index >= lines.size():
		_finish()
		return
	var line: Dictionary = lines[line_index]
	speaker_label.text = String(line.get("speaker", ""))
	line_label.text = String(line.get("text", ""))
	line_label.visible_ratio = 0.0
	var tw := create_tween()
	var dur := maxf(0.4, line_label.text.length() * 0.015 / float(SettingsSystem.get_value("text_speed", 1.0)))
	tw.tween_property(line_label, "visible_ratio", 1.0, dur)


func _finish() -> void:
	get_tree().change_scene_to_file("res://scenes/character_creation.tscn")
