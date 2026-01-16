# ELECTION CYCLE
## Game Design Document v2.0
**Last Updated:** January 17, 2026  
**Target Release:** November 2026  
**Revenue Target:** $10,000 USD (Year 1)

---

# 🎯 EXECUTIVE SUMMARY

## The Pitch (30 seconds)
**Election Cycle** is a satirical political roguelite where you have **7 days to win an election** in a procedurally generated district. You don't win by being right—you win by using the right **SKILL**.

Think *Disco Elysium* meets *Papers, Please* meets *It's Always Sunny in Philadelphia*.

## Why This Will Sell
| Hook | Player Appeal |
|------|---------------|
| **Short runs (20-30 min)** | Perfect for busy adults, streamers |
| **Procedural replayability** | Every run is different |
| **Dark comedy without preaching** | Appeals across political spectrum |
| **SKILL system creates stories** | "I won by lying to everyone" is shareable |
| **Debate as boss fight** | Clear climax, viewer-friendly |

## Comparable Titles (Comp Analysis)
| Game | Similarity | Their Success |
|------|------------|---------------|
| **Disco Elysium** | Skill-based dialogue, satirical | 2M+ copies |
| **Papers, Please** | Moral choices, short sessions | 5M+ copies |
| **Not Tonight** | Political satire, paperwork | 500K+ copies |
| **Yes, Your Grace** | Decision-making, consequences | 300K+ copies |

**Our niche:** Political satire + roguelite runs. No direct competitor.

---

# 🎮 HIGH CONCEPT

## One-Line Pitch
> *"Election Cycle is a satirical political RPG where winning isn't about truth—it's about which SKILL you're willing to abuse before election day."*

## Core Fantasy
The player is a **cynical political operative** running for local office. They know the system is broken. They're going to exploit it anyway.

**The player should feel:**
- Clever when they manipulate
- Guilty when they compromise
- Amused when the system punishes them fairly
- Motivated to try a different approach

## Tone & Identity
| Element | Description |
|---------|-------------|
| **Humor style** | Absurdist, Always Sunny-esque |
| **Political stance** | None—everyone is flawed |
| **Comedy source** | Outcomes, not punchlines |
| **Violence** | None (scandals are the damage) |
| **Mature content** | Political corruption, lying, manipulation |

**ESRB Target:** Teen (Language, Simulated Gambling [Kapital mechanics], Mild Suggestive Themes)

---

# 📊 MARKET & REVENUE STRATEGY

## Target Audience

### Primary: "The Cynical Gamer" (Ages 25-40)
- Employed, limited gaming time
- Appreciates dark humor
- Watches political content (but exhausted by it)
- Plays: Disco Elysium, Hades, Slay the Spire, Papers Please
- Platforms: Steam (Windows), possibly Mac later

### Secondary: "The Streamer Audience"
- Viewers want **reactions** and **stories**
- Short runs = good stream pacing
- Skill checks create tension
- Debate = dramatic finale

## Revenue Model: $10,000 Year 1

### Pricing Strategy
| Price Point | Rationale |
|-------------|-----------|
| **$12.99 USD** | Sweet spot for indie roguelites |
| Launch discount: **$9.99 (23% off)** | Drives launch week buys |
| Sale floor: **$6.49 (50% off)** | Steam seasonal sales |

### Sales Math
| Scenario | Price | Units Needed | Steam Cut (30%) | Net to Dev |
|----------|-------|--------------|-----------------|------------|
| All full price | $12.99 | 1,100 | $4,290 | $10,000 |
| Mixed (avg $9) | $9.00 | 1,590 | $4,770 | $10,000 |
| All on sale | $6.49 | 2,200 | $4,290 | $10,000 |

**Realistic target: ~1,500-2,000 copies Year 1**

### Wishlist Strategy
| Milestone | Target Date | Goal |
|-----------|-------------|------|
| Steam page live | August 2026 | Start collecting |
| Demo release | September 2026 | Convert wishlists |
| Launch | November 2026 | 2,000+ wishlists |

**Industry average:** 10-20% of wishlists convert at launch.  
**Need:** 10,000-20,000 wishlists for safe $10k.  
**Achievable via:** Streamer coverage, Reddit, Twitter/X, demo virality.

---

# 🕹️ CORE GAMEPLAY LOOP

## Session Flow (20-30 minutes)
```
┌─────────────────────────────────────────────────────┐
│  DAY 1: Registration                                │
│  → Choose name, allocate SKILL points               │
│  → See district, opponent, crisis                   │
├─────────────────────────────────────────────────────┤
│  DAY 2-5: Campaign Activities                       │
│  → Each day has unique challenge                    │
│  → Choices affect stats, trust, scandals            │
│  → Evening news reflects your actions               │
├─────────────────────────────────────────────────────┤
│  DAY 6: The Debate (Boss Fight)                     │
│  → Multi-round confrontation                        │
│  → Past decisions resurface                         │
│  → Crowd/media react                                │
├─────────────────────────────────────────────────────┤
│  DAY 7: Election Results                            │
│  → Votes calculated from all factors                │
│  → Win/lose epilogue                                │
│  → "What if..." replay hooks                        │
└─────────────────────────────────────────────────────┘
```

## Why 7 Days?
- **Digestible:** Player can learn the loop in one run
- **Varied:** Each day tests different skills
- **Memorable:** Day structure creates narrative rhythm
- **Replayable:** Short enough to immediately try again

---

# ⚔️ THE SKILL SYSTEM

## Stats Overview
A political reimagining of SPECIAL (Fallout) as **SKILL**:

| Stat | Full Name | Governs | Playstyle |
|------|-----------|---------|-----------|
| **S** | Speechcraft | Debate performance, persuasion | The Orator |
| **K** | Kapital | Money, donors, ads, bribes | The Machine |
| **I** | Influence | Media coverage, reputation, reach | The Celebrity |
| **L** | Legitimacy | Trust, credentials, authority | The Statesman |
| **L** | Logic | Consistency, catching contradictions | The Honest One |

## Design Principles
1. **No stat is "correct"** — every build creates unique problems
2. **Stats unlock options, not just success rates** — high Kapital opens bribery dialogue
3. **Stats conflict** — high Legitimacy makes scandals hurt more
4. **Visible consequences** — players understand why they won/lost

## Stat Interactions (Examples)
| Situation | High Stat Advantage | Low Stat Disadvantage |
|-----------|--------------------|-----------------------|
| Caught in contradiction | High Logic: "I evolved my position" | Low Logic: Scandal |
| Donor wants favor | High Kapital: More options | Low Kapital: Desperate choices |
| Media investigates | High Influence: Spin it | Low Influence: Story runs |
| Opponent attacks credentials | High Legitimacy: Deflect | Low Legitimacy: Damage |

---

# 🎲 DICE ROLL SYSTEM (The Gamble)

> *"Politics is gambling with other people's futures."*

The dice roll is the **core tension mechanic** of Election Cycle. It must feel **dramatic**, **visible**, and **consequential**—like Disco Elysium's internal checks meet Baldur's Gate 3's cinematic dice.

## Design Philosophy

| Inspiration | What We Take | What We Adapt |
|-------------|--------------|---------------|
| **Disco Elysium** | Skill checks as internal tension, percentage shown, skills "speak" | Political skills, not psychological |
| **Baldur's Gate 3** | Visible dice, dramatic reveal, modifier breakdown | D10 (not D20), political modifiers |
| **Original** | Stakes feel PERSONAL (your career, not combat) | Reputation is HP |

## Core Mechanic: The Political Check

```
┌─────────────────────────────────────────────────┐
│          ⚔️ SPEECHCRAFT CHECK ⚔️                │
│                                                  │
│   "Convince the union rep you're pro-labor"     │
│                                                  │
│   BASE SKILL:     Speechcraft 6                 │
│   ─────────────────────────────────────         │
│   MODIFIERS:                                    │
│   ► Promised jobs yesterday      +2             │
│   ► Took corporate donor money   -3             │
│   ► Wearing union pin            +1             │
│   ─────────────────────────────────────         │
│   TOTAL MODIFIER:               +0              │
│   DIFFICULTY:                   12              │
│                                                  │
│   ┌─────────────────────────────────┐           │
│   │  SUCCESS CHANCE: 50%           │           │
│   │  ████████████░░░░░░░░░░░░      │           │
│   └─────────────────────────────────┘           │
│                                                  │
│   [ 🎲 ROLL THE DICE ]   [ ✖ BACK OUT ]        │
└─────────────────────────────────────────────────┘
```

### Formula
```
d10 + Skill Value + Modifiers ≥ Difficulty = SUCCESS
```

### Difficulty Tiers
| Difficulty | Name | % Success (Skill 5, no mods) |
|------------|------|------------------------------|
| 8 | Trivial | 80% |
| 10 | Easy | 60% |
| 12 | Medium | 40% |
| 14 | Hard | 20% |
| 16 | Very Hard | 10% (need modifiers) |
| 18+ | Nearly Impossible | Requires stacking bonuses |

## Modifiers: Your Actions Matter

Every choice builds or destroys your dice odds. This is **visible causality**.

### Positive Modifiers
| Source | Modifier | Example |
|--------|----------|---------|
| Kept a promise | +1 to +3 | "You promised housing reform—they remember" |
| Endorsement | +2 | "The union endorses you—workers trust you" |
| High related SKILL | +1 per 2 points above 5 | "Your Legitimacy lends weight" |
| Matching flags | +1 to +2 | "You've been consistent on this issue" |
| Spent Kapital | +1 to +3 | "Your campaign ad is playing everywhere" |

### Negative Modifiers
| Source | Modifier | Example |
|--------|----------|---------|
| Broke a promise | -2 to -4 | "You promised the opposite last week" |
| Active scandal | -2 | "The bribery story is still running" |
| Contradicted yourself | -1 to -3 | "Your Logic is failing you" |
| Opponent smear ad | -1 | "They ran an attack ad this morning" |
| Low trust with NPC | -1 to -3 | "They don't believe you anymore" |

## Advantage & Disadvantage (Disco + BG3 Hybrid)

Certain conditions grant **Advantage** (roll 2d10, take higher) or **Disadvantage** (roll 2d10, take lower).

### Advantage Triggers
| Condition | Flavor Text |
|-----------|-------------|
| NPC trusts you highly (+50) | *"They want to believe you."* |
| Promise directly matches check | *"You've already committed to this."* |
| Opponent just had a scandal | *"They're distracted by their own mess."* |
| Media bias in your favor | *"The press is on your side today."* |

### Disadvantage Triggers
| Condition | Flavor Text |
|-----------|-------------|
| NPC distrusts you (-50) | *"They've heard your lies before."* |
| Direct contradiction active | *"Your words are coming back to haunt you."* |
| Opponent endorsed by this group | *"They've already chosen a side."* |
| Active scandal about this topic | *"The headlines are still fresh."* |

### Probability Impact
| Roll Type | P(≥7 on d10) | Advantage | Disadvantage |
|-----------|--------------|-----------|--------------|
| Normal | 40% | 64% | 16% |
| Need ≥5 | 60% | 84% | 36% |
| Need ≥9 | 20% | 36% | 4% |

**Advantage nearly doubles success. Disadvantage nearly halves it.**

## Critical Outcomes

| Roll | Name | Effect |
|------|------|--------|
| **Natural 10** | **Critical Success** | Bonus effect + memorable headline |
| **Natural 1** | **Critical Failure** | Extra penalty + scandal risk |

### Critical Success Examples
- **Speechcraft crit:** Opponent is speechless. Gain +5 Influence.
- **Kapital crit:** Donor is so impressed they double their contribution.
- **Logic crit:** You expose opponent's contradiction. They lose trust.

### Critical Failure Examples
- **Speechcraft crit-fail:** You say something offensive. Viral clip.
- **Kapital crit-fail:** Donation paper trail leaked to press.
- **Logic crit-fail:** You contradict yourself live on camera.

## The Roll Experience (UX Flow)

### 1. Pre-Roll (Tension Building)
```
┌────────────────────────────────────────┐
│  💬 SPEECHCRAFT wants to speak...      │
│                                         │
│  "You can talk your way out of this.   │
│   You've done it before. But they're   │
│   watching closely this time."         │
│                                         │
│  Success: They'll trust you.           │
│  Failure: They'll remember this.       │
│                                         │
│  [ 50% CHANCE ]                        │
│                                         │
│  [ TRY IT ] [ BACK DOWN ]              │
└────────────────────────────────────────┘
```

### 2. The Roll (Dramatic Reveal)
```
┌────────────────────────────────────────┐
│                                         │
│            🎲 ROLLING...               │
│                                         │
│         ┌─────────────────┐            │
│         │                 │            │
│         │       7         │            │
│         │                 │            │
│         └─────────────────┘            │
│                                         │
│   7 + 6 (Speechcraft) + 0 (mods) = 13  │
│                                         │
│        vs DIFFICULTY 12                │
│                                         │
│   ═══════════════════════════════════  │
│         ✓ SUCCESS                      │
│   ═══════════════════════════════════  │
│                                         │
└────────────────────────────────────────┘
```

### 3. Post-Roll (Consequence)
```
┌────────────────────────────────────────┐
│                                         │
│  ✓ SPEECHCRAFT succeeded.              │
│                                         │
│  "Your words land. For once, they      │
│   actually believe you. Or at least,   │
│   they believe you believe it."        │
│                                         │
│  ► Trust +10 with Maria Chen           │
│  ► Flag set: union_speech_success      │
│                                         │
│  [ CONTINUE ]                          │
└────────────────────────────────────────┘
```

## Probability Analysis: Before vs After Enhancement

### Before (Current Hidden System)
- Roll happens behind simple "SUCCESS/FAILED" text
- Modifiers not visible to player
- No advantage/disadvantage
- Crits not implemented

| Aspect | Current State |
|--------|---------------|
| Player understanding | Low—feels random |
| Tension | Minimal—just click and see |
| Replayability driver | Weak—"I'll try again I guess" |
| Streamer appeal | Low—nothing to watch |
| Causality feeling | Weak—why did it fail? |

### After (Enhanced Visible System)
- Full modifier breakdown shown
- Percentage displayed before roll
- Advantage/disadvantage with 2d10
- Critical outcomes with headlines
- Skills "speak" like Disco Elysium

| Aspect | Enhanced State |
|--------|----------------|
| Player understanding | High—see exactly why |
| Tension | High—gambling feeling |
| Replayability driver | Strong—"I'll stack modifiers differently" |
| Streamer appeal | High—visible drama, reactions |
| Causality feeling | Strong—my choices mattered |

### Success Probability Impact

**Scenario: Skill 5, Difficulty 12**

| System | Base | With +3 mods | With Advantage | With Both |
|--------|------|--------------|----------------|-----------|
| **Before** | 40% | 40% (hidden) | N/A | N/A |
| **After** | 40% | 70% | 64% | 84% |

**Key insight:** Player SEES the 40% → 84% improvement from their choices. This creates the "I earned this" feeling.

## Why This Is Critical for $10k Target

| Feature | Revenue Impact |
|---------|----------------|
| Visible dice | Screenshot/GIF worthy → social sharing |
| Modifier breakdown | "Big brain" plays → Reddit posts |
| Advantage/disadvantage | Risk/reward choices → replayability |
| Critical outcomes | Memorable moments → word of mouth |
| Skill voices | Personality → reviews mention it |

**Baldur's Gate 3 taught the market that visible dice = engagement.**  
**Disco Elysium taught writers that skills can have personality.**  
**We combine both for political drama.**

---

# 📅 7-DAY STRUCTURE

## Day 1 — Registration
**Quote:** *"Who are you pretending to be?"*

| Element | Details |
|---------|---------|
| **Purpose** | Establish identity, set constraints |
| **Player Actions** | Name, slogan, allocate SKILL points |
| **Information Revealed** | Opponent profile, district theme, main crisis, media bias |
| **System Impact** | Sets starting Legitimacy expectations |
| **Satire Angle** | Registration forms already judge you |

## Day 2 — Canvassing
**Quote:** *"Say it to their face."*

| Element | Details |
|---------|---------|
| **Purpose** | Grassroots support, learn issues |
| **Player Actions** | Visit houses, talk to NPCs, make promises |
| **Skills Tested** | Speechcraft, Legitimacy, Logic |
| **Risk** | Early contradictions start here |
| **Satire Angle** | Being awkward now may help later (low expectations) |

## Day 3 — Posters
**Quote:** *"How do you look from a distance?"*

| Element | Details |
|---------|---------|
| **Purpose** | Control optics, build Influence |
| **Player Actions** | Choose poster design, slogan, placement |
| **Skills Tested** | Influence, Logic (does slogan match promises?) |
| **Risk** | Bad messaging creates delayed backlash |
| **Satire Angle** | NPCs interpret posters wildly differently |

## Day 4 — Fundraiser
**Quote:** *"Who owns you?"*

| Element | Details |
|---------|---------|
| **Purpose** | Kapital as power AND poison |
| **Player Actions** | Choose donors: Clean / Questionable / Desperation |
| **Skills Tested** | Kapital, Legitimacy, Logic |
| **Risk** | Donors demand favors, media may investigate |
| **Satire Angle** | Every dollar has strings attached |

## Day 5 — Town Event
**Quote:** *"Perform in public."*

| Element | Details |
|---------|---------|
| **Purpose** | Stress test your build |
| **Player Actions** | Attend event, handle interruptions, manage crowd |
| **Skills Tested** | Speechcraft, Influence, Legitimacy |
| **Risk** | NPCs confront you with past promises |
| **Satire Angle** | Doing nothing can be the safest choice |

## Day 6 — The Debate (Boss Fight)
**Quote:** *"Everything comes due."*

| Element | Details |
|---------|---------|
| **Purpose** | Climax—all contradictions surface |
| **Structure** | Multi-round: Opening (Influence) → Policy (Speechcraft) → Attack/Defense (Logic) → Credibility (Legitimacy) → Aftermath (Kapital) |
| **Key Rule** | Debate amplifies existing strength/weakness |
| **Risk** | Opponent references your run history |
| **Satire Angle** | Truth doesn't matter, perception does |

## Day 7 — Results
**Quote:** *"The math doesn't care how you feel."*

| Element | Details |
|---------|---------|
| **Purpose** | Payoff, reflection, replay motivation |
| **What Happens** | Votes counted, news explains outcome, epilogue based on choices |
| **Win Condition** | More than 50% support |
| **Replay Hooks** | "What if I leaned into Kapital?" / "What if I stayed consistent?" |

---

# 📰 NEWS SYSTEM (The Glue)

News runs every night between days. It's the **feedback mechanism** that makes consequences visible.

## What News Does
- Summarizes player actions (sometimes unfairly)
- Foreshadows consequences
- Reflects media bias + player Influence + Kapital
- Creates dramatic irony ("I know why they're saying that")

## News Types
| Type | Example |
|------|---------|
| **Local headline** | "New Candidate Promises Change" |
| **Opinion column** | "Can We Trust Their Promises?" |
| **Poll numbers** | "Race Tightens: 48% - 47%" |
| **Anonymous leak** | "Sources Say Candidate Met With Developers" |
| **Rumor (true/false)** | "Is Candidate Hiding Third Marriage?" |

**Important:** News is NOT objective. It's another system to manipulate.

---

# 🎨 VISUAL STYLE

## Art Direction
| Element | Approach |
|---------|----------|
| **Style** | Pixel art, Pokémon-inspired top-down |
| **Resolution** | 320x180 upscaled, chunky pixels |
| **Color palette** | Muted with accent colors per district |
| **Character design** | Simple, readable at small size |
| **Animation** | Minimal—walk cycles, idle, talk |

## UI Philosophy
| Principle | Implementation |
|-----------|----------------|
| **Clear hierarchy** | Stats always visible in top bar |
| **Readable text** | Large fonts, high contrast |
| **Feedback** | Every choice shows immediate result |
| **Pokemon inspiration** | Menu boxes, choice lists, simple transitions |

## Scope Control (Art)
| Include | Exclude |
|---------|---------|
| Town map (1-2 screens) | Complex interiors |
| ~10 NPC sprites | Animated cutscenes |
| 5-10 building exteriors | 3D effects |
| Simple UI elements | Particle systems |

---

# 🔧 TECHNICAL SPECIFICATION

## Engine & Platform
| Spec | Choice |
|------|--------|
| **Engine** | Godot 4.4 (stable) |
| **Language** | GDScript |
| **Primary platform** | Windows (Steam) |
| **Future platforms** | Mac, Linux (post-launch if viable) |
| **Resolution** | 1280x720 base, scales up |

## Architecture
```
/systems
  game_manager.gd      # Day loop, state, effects
  skill_system.gd      # SKILL stats and checks
  dialogue_system.gd   # Conversation engine
  news_system.gd       # Headline generation
  content_loader.gd    # JSON content pipeline

/scripts
  main_menu.gd
  character_creation.gd
  game.gd

/scenes
  main_menu.tscn
  character_creation.tscn
  game.tscn
  town.tscn (spatial layer)

/content
  scenario_maker.json   # All scenarios, NPCs, events
  dialogues/            # NPC conversation trees
```

## Content Pipeline
All content is **JSON-based** for:
- Easy AI-assisted content generation
- Modding potential (future)
- Rapid iteration without code changes

---

# 📈 DEVELOPMENT TIMELINE (Revised)

**Current Status:** January 17, 2026 — **68% complete**  
**Current State:** Full 7-day loop playable (text-based, no spatial layer)

## Phase Summary
| Phase | Timeline | Status | Goal |
|-------|----------|--------|------|
| **0: Foundation** | Jan 12-31 | ✅ 100% | Systems working |
| **1: Spatial Layer** | Feb 1-28 | 🔲 0% | Walking + town |
| **2: Content Depth** | Mar-May | 🔲 0% | More scenarios, balance |
| **3: Polish** | Jun-Aug | 🔲 0% | Art, audio, UX |
| **4: Launch Prep** | Sep-Oct | 🔲 0% | Demo, Steam page, trailer |
| **5: Release** | Nov | 🔲 0% | Ship + support |

## Phase 1: Spatial Layer (February)
**Goal:** Walk around town, talk to NPCs on map

| Week | Tasks |
|------|-------|
| Feb 1-7 | Player movement, simple town, camera |
| Feb 8-14 | NPCs on map, interaction triggers |
| Feb 15-21 | Locations → scenario routing |
| Feb 22-28 | Day-based NPC availability, polish |

**Exit Criteria:** Days 1-3 playable with walking.

## Phase 2: Content Depth (March-May)
**Goal:** Enough variety for replay value

| Month | Focus |
|-------|-------|
| March | More NPCs, canvassing scenarios |
| April | Events expansion, debate improvements |
| May | Balance pass, difficulty tuning |

**Exit Criteria:** 3+ distinct run archetypes feel different.

## Phase 3: Polish (June-August)
**Goal:** Looks and sounds good

| Month | Focus |
|-------|-------|
| June | Art pass—consistent pixel style |
| July | Audio—SFX, simple music loop |
| August | UX—tutorial text, accessibility |

**Exit Criteria:** Game is presentable in screenshots/video.

## Phase 4: Launch Prep (September-October)
**Goal:** Ready to sell

| Week | Tasks |
|------|-------|
| Sep 1-15 | Steam page, screenshots |
| Sep 16-30 | Demo (Days 1-3), upload |
| Oct 1-15 | Trailer (30-45 sec) |
| Oct 16-31 | Streamer outreach, press kit |

**Exit Criteria:** Steam page live, demo available, wishlists growing.

## Phase 5: Release (November)
**Goal:** Ship calmly

| Week | Tasks |
|------|-------|
| Nov 1-15 | Final QA, bug fixes |
| Nov 16-30 | **LAUNCH**, hotfixes, community response |

---

# 📣 MARKETING STRATEGY

## Pre-Launch (3 months before)
| Channel | Action |
|---------|--------|
| **Steam** | Page live, screenshots, GIFs, about section |
| **Twitter/X** | Weekly dev updates, GIFs, memes |
| **Reddit** | r/indiegaming, r/roguelikes, r/godot posts |
| **Discord** | Small community for playtesters |

## Launch Week
| Channel | Action |
|---------|--------|
| **Streamers** | Send 20-30 keys to small/mid streamers |
| **Press** | Email indie-friendly outlets (Rock Paper Shotgun, PC Gamer indie section) |
| **Reddit** | Launch announcement posts |
| **Steam** | Launch discount (23% off) |

## Post-Launch
| Timeline | Action |
|----------|--------|
| Week 1-2 | Respond to reviews, hotfix bugs |
| Month 2 | First content update (free) |
| Month 3+ | Participate in Steam sales |

## Streamer Appeal Features
- **Short runs** = good pacing for streams
- **Skill checks** = visible dice rolls, tension
- **Absurd outcomes** = reaction content
- **Debate finale** = dramatic climax
- **Seeds** = viewers can play same run

---

# ⚠️ RISK MITIGATION

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **Scope creep** | High | High | Strict feature freeze after April |
| **Over-engineering** | Medium | Medium | "If ugly but works, stop" |
| **Art quality concerns** | Medium | Medium | Minimal pixel art, consistency > detail |
| **Low wishlists** | Medium | High | Demo, streamer outreach, Reddit presence |
| **Political controversy** | Low | High | No real parties, equal mockery |
| **Burnout** | Medium | High | Weekend-only dev, use buffer time |

---

# ✅ SUCCESS CRITERIA

## Minimum Viable Product (MVP)
- [ ] Full 7-day loop playable
- [ ] Walking in town, talking to NPCs
- [ ] 10+ unique scenarios per day
- [ ] News system functional
- [ ] Election results with explanation
- [ ] Basic pixel art style
- [ ] Sound effects for key actions

## Launch Requirements
- [ ] Steam page with good screenshots
- [ ] Playable demo (Days 1-3)
- [ ] 30-45 second trailer
- [ ] Zero game-breaking bugs
- [ ] Tutorial/onboarding text
- [ ] Press kit ready

## Year 1 Goals
- [ ] 1,500+ copies sold
- [ ] $10,000 net revenue
- [ ] 70%+ positive reviews
- [ ] 1 content update released
- [ ] Active (small) community

---

# 🎬 APPENDIX: ELEVATOR PITCHES

## For Players (Steam description)
> **You have 7 days to win an election. Truth is optional.**
>
> ELECTION CYCLE is a satirical political roguelite where every run drops you into a new district with new voters, a new opponent, and a new crisis. Make promises. Break them. Survive the debate. Win the vote.
>
> Your SKILL determines your playstyle: talk your way out (Speechcraft), buy your way in (Kapital), control the narrative (Influence), or stay dangerously consistent (Logic).
>
> No ideology is correct. Everyone is corrupt. Including you.

## For Streamers
> "It's a political roguelite where you're basically playing a corrupt local politician. Every run is 20-30 minutes, you make promises you can't keep, donors want favors, and on Day 6 there's a debate where everything you've done comes back to haunt you. Great for reactions."

## For Press
> "Election Cycle offers a refreshingly cynical take on political satire. Rather than preaching, it exposes the contradictions inherent in campaigning through systems-driven gameplay. Think Disco Elysium's dialogue depth meets Papers, Please's moral weight, with Always Sunny's sense of humor. Available November 2026 on Steam."

---

**Document Version:** 2.0  
**Author:** [Your Name]  
**Target Revenue:** $10,000 USD (Year 1)  
**Confidence Level:** High 🚀
