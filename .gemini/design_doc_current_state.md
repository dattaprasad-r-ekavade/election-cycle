# Election Cycle - Current State Design Document
**Generated:** January 17, 2026  
**Source:** Codebase Analysis  
**Target Release:** October-November 2026

---

## 📋 Executive Summary

**Election Cycle** is a satirical 2D political RPG in Godot 4.4 where players have 7 in-game days to win a procedurally-generated local election. The core gameplay loop is dialogue-driven with choice-based mechanics tied to a "SKILL" stat system (political version of SPECIAL).

### Current Build Status: **Playable Vertical Slice (Text-Based)**
- Days 1-7 are playable end-to-end via UI
- No spatial/walking layer yet
- Content system fully functional with 83KB of scenario data
- All core systems implemented and connected

---

## 🎮 Core Systems - Implementation Status

### 1. SKILL System ✅ COMPLETE
**File:** `systems/skill_system.gd` (200 lines)

| Feature | Status | Notes |
|---------|--------|-------|
| All 5 stats (Speechcraft, Kapital, Influence, Legitimacy, Logic) | ✅ Done | Fully implemented |
| Point allocation (character creation) | ✅ Done | 5 extra points to allocate from base 3 each |
| Temporary modifiers | ✅ Done | Events can add/remove bonuses |
| Skill checks with dice rolling | ✅ Done | d10 + skill vs difficulty |
| Threshold checks (requires) | ✅ Done | Hard gates for choices |

### 2. Dialogue System ✅ COMPLETE  
**File:** `systems/dialogue_system.gd` (351 lines)

| Feature | Status | Notes |
|---------|--------|-------|
| JSON dialogue loading | ✅ Done | Loads from `content/dialogues/` |
| Node-based conversations | ✅ Done | Speaker, text, choices structure |
| Choice filtering (requires) | ✅ Done | Skill gates work |
| Skill checks on choices | ✅ Done | Success/failure branching |
| Effect application | ✅ Done | Pipes to GameManager |
| Text placeholders | ✅ Done | {player_name}, {opponent_name}, etc. |
| Flag system | ✅ Done | Per-dialogue flags |
| Validation | ✅ Done | Validates schema on load |

### 3. Content Loader ✅ COMPLETE
**File:** `systems/content_loader.gd` (531 lines)

| Feature | Status | Notes |
|---------|--------|-------|
| JSON schema loading | ✅ Done | Loads `scenario_maker.json` |
| NPC data | ✅ Done | Keyed dictionary |
| Scenario pools per day type | ✅ Done | canvassing, posters, fundraisers, events, debate_rounds |
| Crises & opponents | ✅ Done | Random selection per run |
| Weighted random selection | ✅ Done | Respects `weight` field |
| Tag-based filtering | ✅ Done | issue_tags, world_tags, tone_tags |
| Unique per run / cooldown | ✅ Done | Prevents repetition |
| Content normalization | ✅ Done | Converts legacy effect formats to ops |
| Content validation | ✅ Done | Strict checks for IDs, stats, placeholders |

### 4. Game Manager ✅ COMPLETE
**File:** `systems/game_manager.gd` (372 lines)

| Feature | Status | Notes |
|---------|--------|-------|
| Day progression (1-7) | ✅ Done | Signal-based |
| Phase management | ✅ Done | MENU, PLAYING, NEWS, DEBATE, RESULTS |
| Seed-based RNG | ✅ Done | Deterministic runs possible |
| District generation | ✅ Done | Theme, crisis, opponent |
| Promise tracking | ✅ Done | Made & broken with IDs |
| Scandal system | ✅ Done | Immediate + risk-based |
| Endorsement system | ✅ Done | Array of endorsers |
| NPC trust per-NPC | ✅ Done | Dictionary keyed by npc_id |
| District support (global) | ✅ Done | Separate from NPC trust |
| Run flags | ✅ Done | For debate callouts |
| Event logging | ✅ Done | Structured for news/endgame |
| Effect ops processor | ✅ Done | stat_add, trust_add, promise_add, etc. |
| Election results calculation | ✅ Done | Multi-factor weighted formula |

### 5. News System ✅ COMPLETE
**File:** `systems/news_system.gd` (297 lines)

| Feature | Status | Notes |
|---------|--------|-------|
| Daily news generation | ✅ Done | Based on current day |
| Day-specific headlines | ✅ Done | Registration, canvassing, posters, etc. |
| Skill-reactive content | ✅ Done | Headlines vary by stats |
| Media bias application | ✅ Done | Adjusts tone |
| Poll numbers | ✅ Done | Dynamic based on state |
| News history | ✅ Done | Tracked across run |
| Scandal-triggered news | ⚠️ Partial | Basic promise-breaking coverage |

---

## 🎬 Scenes & UI

### Main Menu ✅ COMPLETE
**File:** `scenes/main_menu.tscn`, `scripts/main_menu.gd`
- New game button → Character creation
- Basic structure in place

### Character Creation (Day 1) ✅ COMPLETE
**File:** `scenes/character_creation.tscn`, `scripts/character_creation.gd` (156 lines)
- Player name input
- Campaign slogan input
- District info display (name, crisis, opponent)
- SKILL point allocation with +/- buttons
- Points remaining display
- Back and Start buttons

### Game Scene (Days 2-7) ✅ COMPLETE
**File:** `scenes/game.tscn`, `scripts/game.gd` (403 lines)

| UI Element | Status |
|------------|--------|
| Top bar with day label | ✅ Done |
| Skills display (SPE/KAP/INF/LEG/LOG) | ✅ Done |
| Day title and description | ✅ Done |
| Activity text (RichTextLabel) | ✅ Done |
| Dynamic choice buttons | ✅ Done |
| Status bar (district/crisis/rival) | ✅ Done |
| Next day button | ✅ Done |
| End-of-day news screen | ✅ Done |
| Election results screen | ✅ Done |

### Visual Themes
**File:** `themes/pokemon_theme.tres` (3.1KB)
- Pokemon-inspired theme exists
- Basic styling applied

---

## 📁 Content Status

### Primary Content File
**File:** `content/scenario_maker.json` (83KB)

This is substantial! Contains:
- NPCs with archetypes
- Canvassing scenarios
- Poster options
- Fundraiser scenarios
- Town event scenarios  
- Debate rounds
- Crises
- Opponents

### Dialogue Files
**Directory:** `content/dialogues/`
- `donor_mysterious.json` (5.1KB)
- `voter_skeptic.json` (5.2KB)

---

## 📅 7-Day Loop Implementation

| Day | Title | Status | Implementation |
|-----|-------|--------|----------------|
| **Day 1** | Registration | ✅ Complete | Character creation scene |
| **Day 2** | Canvassing | ✅ Complete | Loads from scenario pool |
| **Day 3** | Posters | ✅ Complete | Multiple poster choices |
| **Day 4** | Fundraiser | ✅ Complete | Donor scenarios |
| **Day 5** | Town Event | ✅ Complete | Event scenarios |
| **Day 6** | Debate | ✅ Complete | Multi-round with fallback |
| **Day 7** | Results | ✅ Complete | Full results breakdown |

---

## ❌ Not Yet Implemented

### Spatial / Visual Layer
- [ ] Town map with walking
- [ ] Player character sprite
- [ ] NPC sprites in world
- [ ] Location-based interactions
- [ ] Camera follow
- [ ] Tilemaps

### Audio
- [ ] Music
- [ ] Sound effects
- [ ] UI feedback sounds

### Polish
- [ ] Art pass (consistent style)
- [ ] Animations
- [ ] Transitions between screens
- [ ] Tutorial/onboarding

### Distribution
- [ ] Steam integration
- [ ] Demo build
- [ ] Trailer
- [ ] Screenshots
- [ ] Steam page

---

## 🗂️ Architecture Quality

### Strengths
1. **Clean separation of concerns** - Systems, scripts, scenes properly organized
2. **Autoload singletons** - GameManager, SkillSystem, DialogueSystem, NewsSystem, ContentLoader
3. **Data-driven content** - Everything loads from JSON
4. **Signal-based communication** - Proper Godot patterns
5. **Validation on load** - Content fails fast if malformed
6. **Effect normalization** - Legacy content auto-converted

### Technical Debt
1. UI is functional but not polished
2. No save/load system yet
3. Debug overlay mentioned in tasks but not visible
4. Some console output still present

---

## 📊 Progress vs document.md

### Phase 0 — Godot Orientation (Weeks 1-2)
**Timeline:** Jan 12-25 | **Status:** ✅ COMPLETE + AHEAD

| Task | document.md | Current State |
|------|-------------|---------------|
| Scene understanding | Week 1 | ✅ Done |
| Signal system | Week 1 | ✅ Done |
| Menu scene | Week 1 | ✅ Done + game loop |
| GameManager autoload | Week 2 | ✅ Done |
| JSON loading | Week 2 | ✅ Done |

### Phase 1 — Core Systems (Weeks 3-8)
**Timeline:** Jan 26 - Mar 8 | **Status:** ✅ 100% COMPLETE

| Task | Target Week | Current State |
|------|-------------|---------------|
| Project architecture | Week 3 | ✅ Done |
| SKILL System | Week 4 | ✅ Done |
| Dialogue data schema | Week 5 | ✅ Done |
| Dialogue runner + effects | Week 6 | ✅ Done |
| Seeded scene selector | Week 7 | ✅ Done |
| News System + day progression | Week 8 | ✅ Done |

**Vertical Slice Target:** Week 8 (Mar 8)  
**Actual:** Completed by Week 1 (Jan 17) — **7 weeks ahead!**

### Phase 2 — Full 7-Day Loop (Weeks 9-20)
**Timeline:** Mar 9 - May 31 | **Status:** ✅ 100% COMPLETE

| Task | Target Week | Current State |
|------|-------------|---------------|
| Poster system (Day 3) | Weeks 9-10 | ✅ Done |
| Fundraiser (Day 4) | Weeks 11-12 | ✅ Done |
| Event system (Day 5) | Weeks 13-14 | ✅ Done |
| Debate system (Day 6) | Weeks 15-17 | ✅ Done |
| Endgame (Day 7) | Weeks 18-20 | ✅ Done |

**Full 7-Day Target:** Week 20 (May 31)  
**Actual:** Completed by Week 1 (Jan 17) — **19 weeks ahead!**

---

## 📈 Overall Progress Assessment

### By Feature Category

| Category | Weight | Progress | Weighted |
|----------|--------|----------|----------|
| Core Systems | 25% | 100% | 25% |
| 7-Day Game Loop | 20% | 100% | 20% |
| Content Pipeline | 15% | 95% | 14.25% |
| UI/UX (text-based) | 10% | 85% | 8.5% |
| Spatial Layer (walking) | 15% | 0% | 0% |
| Art/Audio | 10% | 5% | 0.5% |
| Polish & Distribution | 5% | 0% | 0% |

### **TOTAL PROGRESS: ~68%**

---

## 🗓️ Timeline Reality Check

**Today:** January 17, 2026  
**Target Release:** November 2026 (let's say Nov 15)  
**Time Remaining:** ~43 weeks (10 months)

### What's Left (from long-term-plan.md)

| Phase | Timeline | Weeks | Status |
|-------|----------|-------|--------|
| Phase 0 - Foundation | Jan 17-31 | 2 | Current - hardening |
| Phase 1A - Ugly Town Map | Feb 1-15 | 2 | Movement + NPC anchors |
| Phase 2 - Full Loop (spatial) | Feb 16 - Apr 15 | 8 | Already done in text |
| Phase 3 - Content + Balance | May - Aug | 16 | Depth, NPCs, polish |
| Phase 4 - Presentation + Steam | Sep - Oct | 8 | Art, sound, trailer |
| Phase 5 - Launch Buffer | Nov | 4 | QA, hotfixes, launch |

### Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Spatial layer takes longer | Medium | Medium | Can ship text-only if needed |
| Content depth insufficient | Low | High | 83KB already exists, AI can scale |
| Art consistency | Medium | Medium | Keep minimal, coherent style |
| Over-engineering | Medium | Low | "If it works ugly, stop" rule |
| Burnout | Medium | High | Already ahead, use buffer |

---

## ✅ Recommendations for Next Steps

### Immediate (Jan 17-31)
1. **Verify deterministic seeding** - Same seed = same run
2. **Add debug overlay** - See stats, flags, promises live
3. **Lock effect schema** - No more format changes
4. **Basic UI scene cleanup** - Prep for spatial layer

### February
1. **Spatial layer** - Walking in simple town
2. **NPCs as map anchors** - Talk triggers existing dialogue
3. **Location-to-scenario mapping** - Houses = canvassing, etc.

### March-April
1. **Visual polish pass** - Consistent look
2. **More content variety** - Expand scenario pools
3. **Sound effects** - UI feedback, key moments

---

## 🎯 Conclusion

You are **significantly ahead of schedule**. The document.md timeline assumed you'd be finishing the vertical slice by Week 8, but you've completed the **full 7-day loop** in Week 1.

The main remaining work is:
1. **Spatial layer** (~15% of total effort)
2. **Art/audio** (~10%)  
3. **Polish & distribution** (~7%)

With 43 weeks remaining and only ~32% left to build, you have substantial buffer. The biggest risk now is **over-polishing** or **scope creep**.

**Ship target confidence: HIGH** 🚀
