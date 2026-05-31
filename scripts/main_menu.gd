extends Control

## Main Menu - Entry point for the game

@onready var new_game_button: Button = $CenterContainer/MainPanel/MarginContainer/VBoxContainer/MenuPanel/MenuMargin/MenuVBox/NewGameButton
@onready var quit_button: Button = $CenterContainer/MainPanel/MarginContainer/VBoxContainer/MenuPanel/MenuMargin/MenuVBox/QuitButton
@onready var menu_vbox: VBoxContainer = $CenterContainer/MainPanel/MarginContainer/VBoxContainer/MenuPanel/MenuMargin/MenuVBox
@onready var flavor_text: Label = $CenterContainer/MainPanel/MarginContainer/VBoxContainer/FlavorText

var slot_selector: OptionButton
var campaign_selector: OptionButton
var continue_button: Button
var campaign_button: Button
var settings_button: Button
var slot_info_label: Label


func _ready() -> void:
	print("[MainMenu] Ready")
	SettingsSystem.apply_font_scale(self)
	new_game_button.text = "> QUICK PLAY"
	quit_button.text = "> QUIT"
	_build_extra_menu_controls()
	_refresh_menu_state()
	CampaignSystem.campaign_progress_changed.connect(_on_campaign_progress_changed)
	SaveSystem.slot_saved.connect(_on_save_slot_changed)
	SaveSystem.slot_loaded.connect(_on_save_slot_changed)


func _build_extra_menu_controls() -> void:
	var slot_row := HBoxContainer.new()
	var slot_label := Label.new()
	slot_label.text = "SAVE SLOT"
	slot_row.add_child(slot_label)

	slot_selector = OptionButton.new()
	slot_selector.custom_minimum_size = Vector2(120, 0)
	for i in range(1, 4):
		slot_selector.add_item("Slot %d" % i, i)
	slot_selector.item_selected.connect(_on_slot_changed)
	slot_row.add_child(slot_selector)
	menu_vbox.add_child(slot_row)

	slot_info_label = Label.new()
	slot_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	slot_info_label.modulate = Color(0.75, 0.75, 0.75)
	menu_vbox.add_child(slot_info_label)

	campaign_selector = OptionButton.new()
	campaign_selector.custom_minimum_size = Vector2(0, 36)
	menu_vbox.add_child(campaign_selector)

	campaign_button = Button.new()
	campaign_button.text = "> CAMPAIGN MODE"
	campaign_button.custom_minimum_size = Vector2(0, 45)
	campaign_button.pressed.connect(_on_campaign_pressed)
	menu_vbox.add_child(campaign_button)

	continue_button = Button.new()
	continue_button.text = "> CONTINUE SELECTED SLOT"
	continue_button.custom_minimum_size = Vector2(0, 45)
	continue_button.pressed.connect(_on_continue_pressed)
	menu_vbox.add_child(continue_button)

	settings_button = Button.new()
	settings_button.text = "> SETTINGS"
	settings_button.custom_minimum_size = Vector2(0, 45)
	settings_button.pressed.connect(_on_settings_pressed)
	menu_vbox.add_child(settings_button)


func _on_new_game_pressed() -> void:
	var slot := _get_selected_slot()
	SaveSystem.set_active_slot(slot)
	CampaignSystem.clear_active_scenario()
	GameManager.play_mode = "quick"
	GameManager.campaign_scenario_id = ""
	GameManager.start_new_game()
	SaveSystem.save_to_slot(slot, true)
	get_tree().change_scene_to_file("res://scenes/character_creation.tscn")


func _on_campaign_pressed() -> void:
	if campaign_selector.get_item_count() == 0:
		return

	var slot := _get_selected_slot()
	var selected_index := campaign_selector.get_selected()
	if selected_index < 0:
		return
	var scenario_id := String(campaign_selector.get_item_metadata(selected_index))
	if scenario_id == "":
		return

	SaveSystem.set_active_slot(slot)
	if not CampaignSystem.start_campaign_scenario(scenario_id):
		return
	SaveSystem.save_to_slot(slot, true)
	get_tree().change_scene_to_file("res://scenes/opening_scene.tscn")


func _on_continue_pressed() -> void:
	var slot := _get_selected_slot()
	SaveSystem.load_from_slot(slot)


func _on_settings_pressed() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Settings"
	dialog.dialog_text = "Accessibility and tutorial settings"

	var body := VBoxContainer.new()
	body.custom_minimum_size = Vector2(420, 180)
	body.theme_override_constants.separation = 8

	var font_row := HBoxContainer.new()
	var font_label := Label.new()
	font_label.text = "Font Scale"
	font_row.add_child(font_label)
	var font_opt := OptionButton.new()
	font_opt.add_item("Normal", 0)
	font_opt.add_item("Large", 1)
	font_opt.add_item("Extra Large", 2)
	var current_scale := float(SettingsSystem.get_value("font_scale", 1.0))
	font_opt.select(0 if current_scale <= 1.0 else (1 if current_scale < 1.3 else 2))
	font_row.add_child(font_opt)
	body.add_child(font_row)

	var speed_row := HBoxContainer.new()
	var speed_label := Label.new()
	speed_label.text = "Text Speed"
	speed_row.add_child(speed_label)
	var speed_opt := OptionButton.new()
	speed_opt.add_item("Slow", 0)
	speed_opt.add_item("Normal", 1)
	speed_opt.add_item("Fast", 2)
	var current_speed := float(SettingsSystem.get_value("text_speed", 1.0))
	speed_opt.select(0 if current_speed < 1.0 else (1 if current_speed == 1.0 else 2))
	speed_row.add_child(speed_opt)
	body.add_child(speed_row)

	var color_row := HBoxContainer.new()
	var color_label := Label.new()
	color_label.text = "Color Mode"
	color_row.add_child(color_label)
	var color_opt := OptionButton.new()
	color_opt.add_item("Default", 0)
	color_opt.add_item("Deuteranopia Friendly", 1)
	color_opt.add_item("High Contrast", 2)
	var color_mode := String(SettingsSystem.get_value("colorblind_mode", "off"))
	if color_mode == "deuteranopia":
		color_opt.select(1)
	elif color_mode == "high_contrast":
		color_opt.select(2)
	else:
		color_opt.select(0)
	color_row.add_child(color_opt)
	body.add_child(color_row)

	var tutorial_toggle := CheckBox.new()
	tutorial_toggle.text = "Enable Tutorial Hints"
	tutorial_toggle.button_pressed = bool(SettingsSystem.get_value("tutorial_enabled", true))
	body.add_child(tutorial_toggle)

	dialog.add_child(body)
	add_child(dialog)

	dialog.confirmed.connect(func() -> void:
		match font_opt.selected:
			0:
				SettingsSystem.set_value("font_scale", 1.0)
			1:
				SettingsSystem.set_value("font_scale", 1.15)
			2:
				SettingsSystem.set_value("font_scale", 1.3)

		match speed_opt.selected:
			0:
				SettingsSystem.set_value("text_speed", 0.75)
			1:
				SettingsSystem.set_value("text_speed", 1.0)
			2:
				SettingsSystem.set_value("text_speed", 1.5)

		match color_opt.selected:
			0:
				SettingsSystem.set_value("colorblind_mode", "off")
			1:
				SettingsSystem.set_value("colorblind_mode", "deuteranopia")
			2:
				SettingsSystem.set_value("colorblind_mode", "high_contrast")

		SettingsSystem.set_value("tutorial_enabled", tutorial_toggle.button_pressed)
		SettingsSystem.apply_font_scale(self)
	)

	dialog.popup_centered()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _get_selected_slot() -> int:
	if slot_selector == null or slot_selector.get_selected_id() <= 0:
		return 1
	return slot_selector.get_selected_id()


func _refresh_menu_state() -> void:
	if slot_selector:
		slot_selector.select(clampi(SaveSystem.active_slot, 1, 3) - 1)
	_refresh_slot_info()
	_refresh_campaign_selector()


func _refresh_slot_info() -> void:
	if slot_info_label == null:
		return
	var meta := SaveSystem.get_slot_metadata(_get_selected_slot())
	if bool(meta.get("exists", false)):
		slot_info_label.text = "Slot info: %s" % String(meta.get("label", ""))
		continue_button.disabled = false
	else:
		slot_info_label.text = "Slot info: Empty"
		continue_button.disabled = true


func _refresh_campaign_selector() -> void:
	if campaign_selector == null:
		return
	campaign_selector.clear()
	var unlocked := CampaignSystem.get_unlocked_scenarios()
	for scenario in unlocked:
		var idx := int(scenario.get("index", 0))
		var title := String(scenario.get("title", "Scenario"))
		var id := String(scenario.get("id", ""))
		campaign_selector.add_item("%d. %s" % [idx, title])
		campaign_selector.set_item_metadata(campaign_selector.get_item_count() - 1, id)
	campaign_button.disabled = campaign_selector.get_item_count() == 0


func _on_slot_changed(_index: int) -> void:
	_refresh_slot_info()


func _on_campaign_progress_changed() -> void:
	_refresh_campaign_selector()


func _on_save_slot_changed(_slot: int) -> void:
	_refresh_slot_info()
