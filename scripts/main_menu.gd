extends Control

## Main Menu - Entry point for the game


func _ready() -> void:
	print("[MainMenu] Ready")


func _on_new_game_pressed() -> void:
	# Go to character creation / registration
	get_tree().change_scene_to_file("res://scenes/character_creation.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
