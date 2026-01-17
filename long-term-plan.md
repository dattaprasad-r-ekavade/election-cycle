# MASTER TIMELINE (RECALIBRATED)

**Current date:** 16–17 Jan 2026
**Current state:** System-playable (text), no spatial layout
**Overall status:** ~3 weeks ahead, safely

---

## PHASE 0 — FOUNDATION FREEZE (NOW → 31 JAN)

### Goal

Lock systems so nothing breaks when space is added.

### Deliverable by Jan 31

> “I can run the same seed twice and get the same outcome.”

---

### 🔹 Week: Jan 17 – Jan 25

**Focus:** System hardening (NO new features)

#### Tasks

* [ ] Freeze effect schema (one internal format only)
* [ ] Loader normalization for legacy fields
* [x] Decide & enforce:

  * ~~Trust = NPC-only **or**~~
  * ~~Introduce `district_support`~~
  * **DONE:** Both systems implemented (dual-layer trust)
* [ ] Add promise IDs + contradiction tracking
* [ ] Add dev event log (promises, scandals, endorsements)
* [ ] Deterministic seed test (5 runs, same results)
* [ ] Debug overlay (stats, flags, promises, scandals, hidden params, perks)
* [x] Hidden parameters system (external election factors)
* [x] Perk system (Fallout-style character perks)

✅ **Exit criteria**

* No silent failures
* Bad content crashes loudly in dev
* You trust your GameState completely

---

### 🔹 Week: Jan 26 – Jan 31

**Focus:** Minimal UI shell (still text-first)

#### Tasks

* [ ] Godot scene structure:

  * MainMenu
  * GameShell
  * DialogueView
  * DaySummaryView
* [ ] Replace console output with basic UI panels
* [ ] Keyboard/mouse input hooked cleanly
* [ ] Day transition screen (end-of-day → news)

🚫 Do NOT:

* Add walking
* Add tiles
* Add NPC sprites

✅ **Exit criteria**

* Days 1–3 fully playable via UI
* Still ugly, but readable

---

## PHASE 1 — SPATIAL LAYER (FEB)

This is where the **Pokémon-style town** comes in.

---

## PHASE 1A — UGLY TOWN MAP (Feb 1 – Feb 15)

### Goal

Turn text choices into **physical locations**.

### Deliverable

> “I walk around a block and talk to people.”

---

### 🔹 Week: Feb 1 – Feb 7

**Focus:** Movement + map as router

#### Tasks

* [ ] One small town scene (single screen or 2–3 screens)
* [ ] TileMap or simple static background
* [ ] Player movement (8-direction or 4-direction)
* [ ] Camera follow
* [ ] Interaction key / click detection

🚫 Skip:

* Pathfinding
* Animations
* NPC schedules

---

### 🔹 Week: Feb 8 – Feb 15

**Focus:** NPCs as interaction anchors

#### Tasks

* [ ] NPC nodes placed in town
* [ ] Each NPC has:

  * ID
  * Tooltip/name
  * Interaction trigger
* [ ] Interaction opens **existing dialogue system**
* [ ] Locations mapped to scenario pools:

  * Houses → canvassing
  * Square → events
  * Hall → debate
* [ ] Day-based NPC availability

✅ **Exit criteria**

* Days 1–3 playable **with walking**
* Zero new dialogue written
* Map is dumb but functional

---

## PHASE 2 — FULL 7-DAY LOOP (MAR–APR)

### Goal

Feature complete game (still unpolished).

---

### 🔹 Weeks: Feb 16 – Mar 15

**Focus:** Days 4–5 + Save System

#### Tasks

* [ ] Fundraiser scenes tied to locations
* [ ] Donor flags + delayed consequences
* [ ] Town event system (interruptions)
* [ ] Event selection via seed + tags
* [ ] **Save/Load system:**
  * Save game state to file (JSON)
  * Load game from save file
  * Save slot UI (3 slots)
  * Auto-save at day transitions
  * Save includes: day, skills, flags, promises, scandals, seed

---

### 🔹 Weeks: Mar 16 – Apr 15

**Focus:** Days 6–7

#### Tasks

* [ ] Debate scene (non-spatial)
* [ ] Debate attacks pulled from event log
* [ ] Media aftermath screen
* [ ] Vote calculation logic
* [ ] Endgame explanation screen:

  * Why you won
  * Why you lost

✅ **Exit criteria**

> Full 7-day run, start → end, no placeholders in logic
> Save/load working reliably

---

## PHASE 3 — CONTENT + BALANCE (MAY–AUG)

### Goal

Depth, replayability, clarity.

---

### 🔹 May: Content Expansion + Campaign Mode Foundation

#### Tasks

* [ ] Add more NPC variants
* [ ] Expand scenario pools (target: 10+ per day type)
* [ ] Balance SKILL tradeoffs
* [ ] Improve news system tone
* [ ] **Campaign Mode system:**
  * Campaign vs Quick Play menu selection
  * Campaign progress tracking (unlocks, completion)
  * Fixed seed + scripted events for campaign scenarios
  * Campaign scenario loader (separate from procedural)

#### Campaign Mode Design

* [ ] Design 10 campaign scenarios (see `content/scripts/campaign_scenarios.md`)
* [ ] Each scenario has:
  * Unique district with backstory
  * Pre-defined opponent with personality/history
  * Specific crisis that ties into narrative
  * Scripted events that trigger based on choices
  * Unique ending variations
* [ ] **Launch target: 5 scenarios playable**
* [ ] Remaining 5 scenarios: Post-launch free update

---

### 🔹 June: Opening Scene ("The Parody Bait-and-Switch")

#### Tasks

* [ ] **Opening cinematic sequence:**
  * Fake Pokemon-style professor intro
  * Dramatic interruption by "Legal"
  * Format shift to actual game
  * See: `content/scripts/opening_scene.md`
* [ ] Opening scene skip option (for replays)
* [ ] First-time player detection

**Streamer hook:** The bait-and-switch should generate genuine surprise/laughter on first viewing.

---

### 🔹 July: Tutorial System

#### Tasks

* [ ] **In-game tutorial (non-intrusive):**
  * Day 1: Explain SKILL system during registration
  * Day 2: First skill check has extended explanation
  * Tooltip system for UI elements
  * "How did I win/lose?" post-game breakdown
* [ ] Tutorial can be disabled in settings
* [ ] Tutorial state saved (don't repeat)

---

### 🔹 August: Polish & Accessibility

#### Tasks

* [ ] Accessibility (font size, text speed, colorblind modes)
* [ ] Settings menu expansion
* [ ] Final balance pass
* [ ] Bug sweep

🚫 Do NOT:

* Add new mechanics
* Add new SKILLs

✅ **Exit criteria**

> Opening scene makes playtesters laugh
> New players understand the game without external help

---

## PHASE 4 — PRESENTATION + STEAM (SEP–OCT)

### Goal

Make it sellable, not bigger.

#### Tasks

* [ ] Art pass (consistent, minimal)
* [ ] Sound effects (light)
* [ ] Steam page copy
* [ ] Screenshots
* [ ] Trailer (30–45 sec)
* [ ] Demo cut (Days 1–3)

---

## PHASE 5 — LAUNCH BUFFER (NOV)

### Goal

Ship calmly.

#### Tasks

* [ ] QA
* [ ] Bug fixing
* [ ] Hotfix pipeline
* [ ] Streamer outreach
* [ ] Launch

---

## PHASE 6 — POST-LAUNCH CONTENT (DEC 2026 → Q1 2027)

### Goal

Keep players engaged, complete campaign mode.

---

### 🔹 December 2026: Hotfix + Community Response

#### Tasks

* [ ] Monitor reviews and feedback
* [ ] Critical bug fixes
* [ ] Balance adjustments based on player data
* [ ] Community building (Discord, Reddit)

---

### 🔹 January 2027: Campaign Completion Update (FREE)

#### Tasks

* [ ] **Campaign scenarios 6-10:**
  * Scenario 6: [TBD]
  * Scenario 7: [TBD]
  * Scenario 8: [TBD]
  * Scenario 9: [TBD]
  * Scenario 10: [TBD] (Final/hardest)
* [ ] Campaign completion rewards/achievements
* [ ] "Campaign Complete" ending screen

---

### 🔹 Q1 2027: Quality of Life + Extras

#### Tasks

* [ ] Additional procedural content based on feedback
* [ ] Requested accessibility features
* [ ] Potential: Endless/challenge mode
* [ ] Evaluate: Paid DLC viability

---


