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
* [ ] Decide & enforce:

  * Trust = NPC-only **or**
  * Introduce `district_support`
* [ ] Add promise IDs + contradiction tracking
* [ ] Add dev event log (promises, scandals, endorsements)
* [ ] Deterministic seed test (5 runs, same results)
* [ ] Debug overlay (stats, flags, promises, scandals)

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

**Focus:** Days 4–5

#### Tasks

* [ ] Fundraiser scenes tied to locations
* [ ] Donor flags + delayed consequences
* [ ] Town event system (interruptions)
* [ ] Event selection via seed + tags

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

---

## PHASE 3 — CONTENT + BALANCE (MAY–AUG)

### Goal

Depth, replayability, clarity.

#### Tasks (ongoing)

* [ ] Add more NPC variants
* [ ] Expand scenario pools
* [ ] Balance SKILL tradeoffs
* [ ] Improve news system tone
* [ ] Tutorial text & onboarding
* [ ] Accessibility (font size, speed)

🚫 Do NOT:

* Add new mechanics
* Add new SKILLs

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


