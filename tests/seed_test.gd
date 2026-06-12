extends RefCounted

## Backward-compatible alias for tooling that referenced this path.
## Prefer `tests/run_seed_test.gd` (CLI) or `tests/seed_test_logic.gd` (runtime).

const LOGIC_SCRIPT := "res://tests/seed_test_logic.gd"


static func run() -> Dictionary:
	var test_script: Script = load(LOGIC_SCRIPT)
	var runner: Node = test_script.new()
	return runner.run()
