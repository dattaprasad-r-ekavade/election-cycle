extends SceneTree

## Headless entry point for the seed determinism test.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var test_script: Script = load("res://tests/seed_test_logic.gd")
	var runner: Node = test_script.new()
	var result: Dictionary = runner.run()
	runner.free()
	quit(0 if bool(result.get("passed", false)) else 1)
