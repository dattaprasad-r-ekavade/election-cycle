# Election Cycle - Task Tracker

## PHASE 0: Foundation Freeze (Target: Jan 31)

**Goal:** Lock systems so nothing breaks when spatial layer is added.
**Deliverable:** "I can run the same seed twice and get the same outcome."

---

### Completed Tasks

- [x] **Hidden parameters system** - External election factors (weather, economy, mood, demographics, opponent stats, wildcards). Net modifier calculated and applied to election results.
- [x] **Perk system** - 24 perks across 6 categories (Speechcraft, Kapital, Influence, Legitimacy, Logic, Wildcard). Passive/triggered/activated types with exclusive combos.
- [x] **Dual-layer trust system** - NPC trust (per-character) + district_support (global). Weighted NPC influence. Content loader routes poster/event trust to district_support automatically.
- [x] **Effect schema normalization** - ContentLoader normalizes legacy `effect`/`success_effect`/`failure_effect` → `effects[]`/`effects_on_success[]`/`effects_on_failure[]`. Promise text auto-generates IDs. Scandal variants unified to `scandal_add`/`scandal_risk_add`.
- [x] **Strict schema validation on load** - ContentLoader validates: duplicate IDs, missing NPC references, invalid day numbers, unknown effect ops, invalid stats, invalid placeholders. Fails fast with helpful errors.
- [x] **Dev event log** - `GameManager.log_event()` tracks structured events: promise_made, promise_broken, scandal_triggered, scandal_risk_added, npc_trust_changed, district_support_changed, endorsement_gained, flag_set, poster_placed, donor_taken, event_attended, canvassing_choice, debate_choice.
- [x] **Tags for seed-based picking** - ContentLoader normalizes `issue_tags`, `world_tags`, `tone_tags` on all scenario items. `unique_per_run` and `cooldown_days` filtering implemented.
- [x] **Debate pulls from run history** - ContentLoader._append_debate_callouts() checks run flags and appends opponent callouts referencing player actions.

---

### Recently Completed

- [x] **Sync effect schema validation (DialogueSystem ↔ ContentLoader)** — DONE
  - Added `district_support_add` and `scandal_risk_add` to DialogueSystem's allowed ops.
  - Added `promise_add` ID/text validation and `scandal_risk_add` chance validation to match ContentLoader.
  - **File:** `systems/dialogue_system.gd`

- [x] **Promise contradiction tracking** — DONE
  - Added `CONTRADICTION_PAIRS` constant with pattern-based detection (build/cut_spending, lower_taxes/increase_funding, etc.).
  - `add_promise()` now calls `_check_promise_contradictions()` which logs detected contradictions.
  - Contradictions surface in debate (ContentLoader appends callouts) and penalize election results (-8 per contradiction).
  - New methods: `get_contradictions()`, `has_contradictions()`.
  - **Files:** `systems/game_manager.gd`, `systems/content_loader.gd`

- [x] **Debug overlay** — DONE
  - Autoload `DebugOverlay` — toggleable with F3, auto-refreshes every 0.5s (F4 to pause).
  - Shows: game state, district, skills (base+mod), perks, trust, promises+contradictions, scandals, endorsements, flags, hidden params, event log.
  - F5 triggers seed determinism test from overlay.
  - **File:** `systems/debug_overlay.gd` (registered as autoload in project.godot)

- [x] **Deterministic seed testing** — DONE
  - Test script runs `start_new_game(12345)` 5 times and compares all generated values.
  - Checks: district name/theme, crisis, opponent, media bias, and 15 hidden parameter values.
  - Accessible via F5 key or by running test scene directly.
  - **File:** `tests/seed_test.gd`

### Deferred

- [x] **Normalize old content in loader bridge** — Already implemented in ContentLoader.
- [x] **Canonical stat key enforcement** — Already implemented (validation rejects unknown stats at load time).

---

## PHASE 0B: Minimal UI Shell (Target: Jan 31)

- [x] MainMenu scene
- [x] Character creation scene (SKILL allocation + perk selection)
- [x] Game scene (Days 2-7 with choices, dice rolls, news, results)
- [x] Dice roll popup (dramatic reveal)
- [ ] Day transition polish (end-of-day → news flow cleanup)
- [ ] Scene structure audit before spatial layer

---

## PHASE 1: Spatial Layer (February)

_Not started. Blocked on Phase 0 completion._

- [ ] Town map (tilemap or static background)
- [ ] Player character sprite + movement
- [ ] Camera follow
- [ ] NPC nodes as interaction anchors
- [ ] Location → scenario routing
- [ ] Days 1-3 playable with walking

---

## PHASE 2: Full Loop + Save System (Mar-Apr)

- [ ] Save/load system (JSON state, 3 slots, auto-save)
- [ ] Debate scene improvements
- [ ] Vote calculation polish
- [ ] Endgame explanation screen

---

## PHASE 3: Content + Balance (May-Aug)

- [ ] Campaign Mode (10 hand-crafted scenarios)
- [ ] Opening scene (Pokemon parody bait-and-switch)
- [ ] Tutorial system
- [ ] Content expansion (10+ scenarios per day type)
- [ ] Accessibility features

---

## PHASE 4: Presentation + Steam (Sep-Oct)

- [ ] Art consistency pass
- [ ] Sound effects
- [ ] Steam page, trailer, demo, press kit

---

## PHASE 5: Launch (November 2026)

- [ ] QA + bug fixes
- [ ] Streamer outreach
- [ ] Ship it
