extends Node

## Seed Determinism Test
## Runs start_new_game() with the same seed multiple times
## and verifies all generated values are identical.
##
## Usage: Add this as a scene and run it, or call run_test() from debug overlay.
## Results are printed to console.

const TEST_SEED := 12345
const NUM_RUNS := 5


func _ready() -> void:
	# Wait one frame for all autoloads to initialize
	await get_tree().process_frame
	run_test()


func run_test() -> Dictionary:
	"""Run the deterministic seed test. Returns {passed: bool, details: String}"""
	print("\n[SeedTest] ═══════════════════════════════════════")
	print("[SeedTest] Starting deterministic seed test")
	print("[SeedTest] Seed: %d | Runs: %d" % [TEST_SEED, NUM_RUNS])
	print("[SeedTest] ═══════════════════════════════════════\n")

	var snapshots: Array[Dictionary] = []

	for run_idx in range(NUM_RUNS):
		var snapshot := _run_and_snapshot(TEST_SEED)
		snapshots.append(snapshot)
		print("[SeedTest] Run %d: district=%s, opponent=%s, crisis=%s" % [
			run_idx + 1, snapshot.district_name, snapshot.opponent_name, snapshot.main_crisis
		])

	# Compare all runs against the first
	var baseline: Dictionary = snapshots[0]
	var all_match := true
	var mismatches: Array[String] = []

	for run_idx in range(1, snapshots.size()):
		var current: Dictionary = snapshots[run_idx]
		for key in baseline.keys():
			if str(baseline[key]) != str(current[key]):
				all_match = false
				var msg := "Run %d: %s differs — expected '%s', got '%s'" % [
					run_idx + 1, key, str(baseline[key]), str(current[key])
				]
				mismatches.append(msg)
				print("[SeedTest] MISMATCH: %s" % msg)

	print("")
	if all_match:
		print("[SeedTest] ✓ PASSED — All %d runs produced identical results" % NUM_RUNS)
	else:
		print("[SeedTest] ✗ FAILED — %d mismatches found:" % mismatches.size())
		for m in mismatches:
			print("[SeedTest]   - %s" % m)

	print("[SeedTest] ═══════════════════════════════════════\n")

	var details := ""
	if all_match:
		details = "PASSED: All %d runs identical with seed %d" % [NUM_RUNS, TEST_SEED]
	else:
		details = "FAILED: %d mismatches\n" % mismatches.size()
		for m in mismatches:
			details += "  - %s\n" % m

	return {"passed": all_match, "details": details, "mismatches": mismatches}


func _run_and_snapshot(test_seed: int) -> Dictionary:
	"""Run start_new_game and capture all generated state"""
	GameManager.start_new_game(test_seed)

	var snapshot := {
		"district_name": GameManager.district_name,
		"district_theme": GameManager.district_theme,
		"main_crisis": GameManager.main_crisis,
		"opponent_name": GameManager.opponent_name,
		"opponent_archetype": GameManager.opponent_archetype,
		"media_bias": snapped(GameManager.media_bias, 0.001),
	}

	# Snapshot hidden params (key ones)
	var hp := GameManager.hidden_params
	var hidden_keys := [
		"season", "election_weather", "election_day_of_week",
		"economy", "national_mood", "local_event",
		"anti_incumbent_wave", "opponent_gaffe_prone",
		"endorsement_jackpot",
	]
	for key in hidden_keys:
		snapshot["hp_" + key] = hp.get(key, "MISSING")

	# Snapshot numeric hidden params (snapped to avoid float drift)
	var numeric_hidden := [
		"weather_turnout_modifier", "economy_modifier",
		"voter_turnout_base", "opponent_name_recognition",
		"opponent_ground_game", "net_hidden_modifier",
	]
	for key in numeric_hidden:
		snapshot["hp_" + key] = snapped(float(hp.get(key, 0.0)), 0.001)

	return snapshot
