extends Node


func should_show_tip(tip_id: String) -> bool:
	if not bool(SettingsSystem.get_value("tutorial_enabled", true)):
		return false
	return not SettingsSystem.is_tip_seen(tip_id)


func mark_tip_seen(tip_id: String) -> void:
	SettingsSystem.set_tip_seen(tip_id)
