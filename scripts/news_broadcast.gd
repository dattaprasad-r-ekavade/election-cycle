extends Control

## WONK 5 ELECTION DESK — end-of-day news broadcast overlay.
## A seeded news anchor walks through the day's headlines segment by
## segment, gives a town pulse update, and closes with a funny kicker.

signal finished

const AVATAR_SCRIPT := preload("res://scripts/character_avatar.gd")

const ANCHOR_NAMES := [
	"Chip Babbleton", "Diane Soundbite", "Stone Phillips-Adjacent",
	"Brenda Broadcast", "Walt Wherever", "Patty Primetime",
	"Lou Gravitas", "Sandy Slownews",
]

const KICKERS := [
	"And finally tonight: a local duck was elected to an HOA board this afternoon. It has already been impeached.",
	"And finally: the town's oldest lawn gnome turned 60 today. Residents describe him as 'consistent' and 'more electable than most.'",
	"And finally: a squirrel briefly held the microphone at a town meeting. Witnesses say it stayed on message.",
	"And finally tonight: the fountain in the town square is up 3 points in polls nobody authorized.",
	"And finally: a man who promised to 'fix everything' was seen fixing one (1) fence. Experts are calling it 'a start.'",
	"And finally: the {crisis} remains unresolved, but a local cat sat on it, which residents agree 'helps somehow.'",
	"And finally tonight: early voting begins soon. Late voting, as always, begins immediately after it's too late.",
	"And finally: a yard sign war on Maple Street has entered week two. Casualties include one flamingo and everyone's patience.",
	"And finally: tonight's weather is brought to you by the word 'probably.'",
	"And finally: a raccoon broke into campaign headquarters and rearranged the filing system. Staff report it's better now.",
]

var segments: Array = []
var segment_index := -1
var anchor_name := "Chip Babbleton"
var line_label: RichTextLabel
var speaker_label: Label
var segment_tag: Label
var continue_btn: Button
var live_dot: ColorRect
var _reveal_tween: Tween


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	# Studio backdrop
	var bg := ColorRect.new()
	bg.color = Color("141c2c")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var backdrop := ColorRect.new()
	backdrop.color = Color("1c2a44")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.offset_bottom = -260.0
	add_child(backdrop)

	# Spinning "globe" decoration (very budget studio)
	var globe := ColorRect.new()
	globe.color = Color("2a4a7c")
	globe.size = Vector2(180, 180)
	globe.position = Vector2(990, 80)
	globe.rotation_degrees = 45
	add_child(globe)
	var gt := globe.create_tween().set_loops()
	gt.tween_property(globe, "rotation_degrees", 405.0, 12.0)

	# Channel bug + LIVE
	var bug := Label.new()
	bug.text = "WONK 5 — ELECTION DESK"
	bug.add_theme_font_size_override("font_size", 20)
	bug.add_theme_color_override("font_color", Color("f8d030"))
	bug.position = Vector2(28, 20)
	add_child(bug)

	live_dot = ColorRect.new()
	live_dot.color = Color("e03030")
	live_dot.size = Vector2(14, 14)
	live_dot.position = Vector2(30, 56)
	add_child(live_dot)
	var lt := live_dot.create_tween().set_loops()
	lt.tween_property(live_dot, "modulate:a", 0.2, 0.5)
	lt.tween_property(live_dot, "modulate:a", 1.0, 0.5)

	var live_lbl := Label.new()
	live_lbl.text = "LIVE"
	live_lbl.add_theme_font_size_override("font_size", 13)
	live_lbl.add_theme_color_override("font_color", Color("e05050"))
	live_lbl.position = Vector2(50, 53)
	add_child(live_lbl)

	# Anchor portrait behind a desk
	var anchor := Node2D.new()
	anchor.set_script(AVATAR_SCRIPT)
	anchor.position = Vector2(240, 280)
	anchor.scale = Vector2(4.5, 4.5)
	add_child(anchor)
	anchor.set_palette({
		"shirt": Color("303848"), "pants": Color("282838"),
		"hair": Color("888078"), "has_hat": false,
	})

	var desk := ColorRect.new()
	desk.color = Color("4a3828")
	desk.size = Vector2(360, 90)
	desk.position = Vector2(80, 360)
	add_child(desk)
	var desk_top := ColorRect.new()
	desk_top.color = Color("5c4632")
	desk_top.size = Vector2(376, 14)
	desk_top.position = Vector2(72, 352)
	add_child(desk_top)
	var desk_logo := Label.new()
	desk_logo.text = "WONK 5"
	desk_logo.add_theme_font_size_override("font_size", 22)
	desk_logo.add_theme_color_override("font_color", Color("f8d030"))
	desk_logo.position = Vector2(190, 388)
	add_child(desk_logo)

	# Lower-third: segment tag + speaker + text
	var lower := PanelContainer.new()
	lower.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	lower.offset_left = 24.0
	lower.offset_right = -24.0
	lower.offset_top = -244.0
	lower.offset_bottom = -16.0
	add_child(lower)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	lower.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	segment_tag = Label.new()
	segment_tag.add_theme_font_size_override("font_size", 13)
	segment_tag.add_theme_color_override("font_color", Color("e05050"))
	vbox.add_child(segment_tag)

	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 17)
	speaker_label.add_theme_color_override("font_color", Color("f8d030"))
	vbox.add_child(speaker_label)

	line_label = RichTextLabel.new()
	line_label.bbcode_enabled = true
	line_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	line_label.custom_minimum_size = Vector2(0, 96)
	vbox.add_child(line_label)

	continue_btn = Button.new()
	continue_btn.text = "▶  NEXT"
	continue_btn.custom_minimum_size = Vector2(0, 40)
	continue_btn.pressed.connect(_advance)
	vbox.add_child(continue_btn)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		_advance()
		get_viewport().set_input_as_handled()


func begin(headlines: Array, day: int, lead_in: String = "") -> void:
	anchor_name = ANCHOR_NAMES[GameManager.run_seed % ANCHOR_NAMES.size()]
	segments.clear()
	segment_index = -1

	# Intro
	segments.append({
		"tag": "OPENING",
		"text": "Good evening, I'm %s, and this is the Day %d Election Desk. We have updates from %s — none of them calming." % [anchor_name, day, GameManager.district_name],
	})

	if lead_in != "":
		segments.append({"tag": "TOP STORY", "text": lead_in})

	# Headlines
	for headline in headlines:
		var tone := String(headline.get("tone", "neutral"))
		var color := "white"
		if tone == "positive":
			color = "green"
		elif tone == "negative":
			color = "red"
		segments.append({
			"tag": "CAMPAIGN WATCH",
			"text": "[color=%s][b]%s[/b][/color]\n%s" % [color, headline.get("headline", ""), headline.get("body", "")],
		})

	# Town pulse: what actually moved today
	var support_today := 0
	for entry in GameManager.district_support_history:
		if int(entry.day) == day:
			support_today += int(entry.amount)
	var pulse := "District support sits at [b]%+d[/b]" % GameManager.district_support
	if support_today != 0:
		pulse += " — that's [color=%s]%+d today[/color]" % ["green" if support_today > 0 else "red", support_today]
	pulse += ". Insiders estimate combined backing at [b]%.0f[/b]." % GameManager.get_total_support()
	if GameManager.scandals.size() > 0:
		pulse += " Scandal count: [color=red]%d[/color]. The scandal desk has ordered more desks." % GameManager.scandals.size()
	segments.append({"tag": "TOWN PULSE", "text": pulse})

	# Funny kicker
	var kicker: String = KICKERS[randi() % KICKERS.size()]
	kicker = kicker.replace("{crisis}", GameManager.main_crisis)
	segments.append({"tag": "AND FINALLY...", "text": kicker})

	# Outro
	segments.append({
		"tag": "SIGN-OFF",
		"text": "That's the news. I'm %s. Tomorrow is Day %d — sleep well, candidate. Someone has to." % [anchor_name, day + 1],
	})

	visible = true
	_advance()


func _advance() -> void:
	# If text is still typing, complete it first.
	if line_label and line_label.visible_ratio < 1.0:
		if _reveal_tween and _reveal_tween.is_valid():
			_reveal_tween.kill()
		line_label.visible_ratio = 1.0
		return

	segment_index += 1
	if segment_index >= segments.size():
		visible = false
		finished.emit()
		return

	var seg: Dictionary = segments[segment_index]
	segment_tag.text = "■ %s" % seg.tag
	speaker_label.text = anchor_name.to_upper()
	line_label.text = String(seg.text)
	line_label.visible_ratio = 0.0
	if _reveal_tween and _reveal_tween.is_valid():
		_reveal_tween.kill()
	var dur := maxf(0.4, line_label.get_parsed_text().length() * 0.012 / float(SettingsSystem.get_value("text_speed", 1.0)))
	_reveal_tween = create_tween()
	_reveal_tween.tween_property(line_label, "visible_ratio", 1.0, dur)
	continue_btn.text = "▶  NEXT" if segment_index < segments.size() - 1 else "▶  END BROADCAST"
