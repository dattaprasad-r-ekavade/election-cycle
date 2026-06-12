# Election Cycle

A satirical political RPG built with **Godot 4.5+**. You have seven in-game days to win a local election using skills, choices, and questionable ethics.

## Requirements

- Godot **4.5** or newer (tested with 4.6.3)
- Linux, macOS, or Windows

## Quick setup

```bash
./setup.sh
```

This script downloads Godot (if needed), imports SVG/tile assets into the local `.godot` cache, and runs the headless validation tests.

## Run the game

```bash
godot --path .
```

The main scene is `scenes/main_menu.tscn`.

## Headless checks

```bash
# Startup smoke test
godot --headless --path . --quit-after 3

# Scene flow validation (menu → opening → character creation → town)
godot --headless -s res://tests/windows_flow_validation.gd

# Deterministic seed test
godot --headless -s res://tests/run_seed_test.gd
```

## Project layout

| Path | Purpose |
|------|---------|
| `scenes/` | Godot scenes (menu, town, campaign map, etc.) |
| `scripts/` | Scene controllers |
| `systems/` | Autoload singletons (game state, skills, saves, content) |
| `content/` | JSON scenarios, campaign data, dialogue |
| `tests/` | Headless validation scripts |
| `assets/sprites/` | SVG art assets |

## Notes

- The `.godot/` import cache is gitignored. Run `godot --import` (or `./setup.sh`) after cloning.
- Saves live in Godot's `user://` directory (platform-specific app data folder).
- Press **F3** in-game to toggle the debug overlay; **F5** runs the seed determinism test.
