extends Control

@onready var background: ColorRect = $Background
@onready var professor_sprite: TextureRect = $CenterArea/ProfessorSprite
@onready var legal_sprite: TextureRect = $CenterArea/LegalSprite
@onready var creature_sprite: TextureRect = $CenterArea/CreatureSprite
@onready var speaker_label: Label = $DialoguePanel/Margin/VBox/Speaker
@onready var line_label: RichTextLabel = $DialoguePanel/Margin/VBox/Line
@onready var hint_label: Label = $DialoguePanel/Margin/VBox/Hint

var lines: Array = []
var line_index := -1
var reveal_tween: Tween
var reveal_ratio := 0.0
var can_skip := false


func _ready() -> void:
	SettingsSystem.apply_font_scale(self)
	_build_lines()
	_start_cutscene()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if line_label.visible_ratio < 1.0:
			line_label.visible_ratio = 1.0
			_update_hint()
		else:
			_show_next_line()
	elif can_skip and ((event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE) or event.is_action_pressed("ui_cancel")):
		_finish_cutscene()


func _start_cutscene() -> void:
	professor_sprite.visible = true
	legal_sprite.visible = false
	creature_sprite.visible = true

	if bool(SettingsSystem.get_value("opening_seen", false)):
		can_skip = true
		hint_label.text = "Press Enter to continue. Esc to skip."
	else:
		can_skip = false
		hint_label.text = "Press Enter to continue."

	_show_next_line()


func _build_lines() -> void:
	lines = [
		{"speaker": "Professor Elmwood", "text": "Hello there. Welcome to the world of..."},
		{"speaker": "Professor Elmwood", "text": "...politics."},
		{"speaker": "Professor Elmwood", "text": "This world is inhabited by creatures called politicians."},
		{"speaker": "Professor Elmwood", "text": "Some people keep them in their pockets. Tiny, obedient, and bought."},
		{"speaker": "Professor Elmwood", "text": "Others send them into arenas to battle for dominance and campaign contributions."},
		{"speaker": "Professor Elmwood", "text": "As for me, I study politicians as a profession."},
		{"speaker": "Professor Elmwood", "text": "Now then... tell me about yourself. Are you a bo-"},
		{"speaker": "LEGAL", "text": "Stop. Stop stop stop. We are not doing this.", "legal": true},
		{"speaker": "Professor Elmwood", "text": "I was simply introducing the pla-"},
		{"speaker": "LEGAL", "text": "The actual game. Right now.", "legal": true},
		{"speaker": "LEGAL", "text": "Welcome to Election Cycle. Seven days. One election. Your choices matter.", "legal": true},
		{"speaker": "LEGAL", "text": "No creature collecting. Just campaign strategy and consequences.", "legal": true},
		{"speaker": "LEGAL", "text": "So... what is your name, candidate?", "legal": true},
	]


func _show_next_line() -> void:
	line_index += 1
	if line_index >= lines.size():
		_finish_cutscene()
		return

	var line: Dictionary = lines[line_index]
	speaker_label.text = String(line.get("speaker", "Narrator"))
	line_label.text = String(line.get("text", ""))
	line_label.visible_ratio = 0.0

	if bool(line.get("legal", false)):
		background.color = Color(0.22, 0.16, 0.16, 1.0)
		legal_sprite.visible = true
		professor_sprite.visible = false
		creature_sprite.visible = false
	else:
		background.color = Color(0.17, 0.26, 0.35, 1.0)
		legal_sprite.visible = false
		professor_sprite.visible = true
		creature_sprite.visible = true

	_animate_line_reveal()


func _animate_line_reveal() -> void:
	if reveal_tween and reveal_tween.is_valid():
		reveal_tween.kill()
	var speed := float(SettingsSystem.get_value("text_speed", 1.0))
	var duration := 0.9 / maxf(speed, 0.1)
	reveal_tween = create_tween()
	reveal_tween.tween_property(line_label, "visible_ratio", 1.0, duration)
	reveal_tween.finished.connect(_update_hint)


func _update_hint() -> void:
	if can_skip:
		hint_label.text = "Press Enter to continue. Esc to skip."
	else:
		hint_label.text = "Press Enter to continue."


func _finish_cutscene() -> void:
	SettingsSystem.set_value("opening_seen", true)
	get_tree().change_scene_to_file("res://scenes/character_creation.tscn")
