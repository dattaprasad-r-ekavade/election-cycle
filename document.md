Product Description — Election Cycle
High-Concept
Election Cycle is a satirical 2D political RPG where you have 7 in-game days to win an election in a procedurally generated district.
You don’t win by being right.
You win by using the right SKILL.
Each run drops you into a new neighborhood with new people, new issues, a new opponent, and a new crisis. You walk the streets, talk to NPCs, make promises, contradict yourself, spend money, manipulate optics, and survive a public debate — all before election day.
At the end of the week, the votes are counted.
You win, you lose, or you lose in a way that makes sense.
Then the city resets.

Tone & Identity
Absurdist satire, not preachy politics
Inspired by Always Sunny–style humor
No “correct” ideology
Everyone (including the player) is flawed
Systems expose contradictions instead of judging them
The comedy comes from outcomes, not punchlines.

Core Gameplay Loop
Wake up in a procedurally generated district
Explore a compact city block
Talk to NPCs with distinct issues and personalities
Make dialogue choices tied to your SKILL stats
Trigger events, scandals, endorsements, and side tasks
Prepare for the public debate (Day 6)
Election results roll in (Day 7)
District resets with a new seed

 Core Systems
 SKILL System (Player Attributes)
A political RPG stat system inspired by SPECIAL, reimagined as SKILL:
S — Speechcraft
How convincing you sound in arguments and debates
K — Kapital 
Campaign money, donors, and financial leverage
I — Influence
Passive reach, reputation, and media momentum
L — Legitimacy
Whether people believe you should be in power
L — Logic
Consistency of your positions and resistance to contradictions
Each stat unlocks different dialogue options, not just higher success rates.
No build is “correct.”
Every build creates different problems.

 Dialogue System (Table-Based, System-Driven)
Dialogue is the game’s combat system.
Conversations are modular “scenes”
Each scene contains:
NPC context
Dialogue lines
Multiple choices
SKILL-tagged outcomes
Choices affect:
NPC trust
Global perception
Hidden flags (promises, contradictions, scandals)
Designed to be:
Highly replayable
AI-generated at scale
Safe to remix via seeds

 Seeded District Generation
Each run is defined by a seed composed of:
City theme
Main crisis
NPC distribution
Dominant issues
Opponent archetype
Media bias
The city layout, NPC traits, events, and dialogue pools are mixed and matched, not fully random — ensuring replayability without chaos.

Debate System (Boss Encounter)
On Day 6, you face your opponent in a public debate.
Multi-round structure
Each round tests a different SKILL stat
Crowd and media react dynamically
Performance depends on:
Past promises
Logic consistency
Influence momentum
Kapital spent before/after
The debate doesn’t decide everything — but it amplifies what you’ve already done.

 Endgame Resolution
Election results are calculated, not scripted.
Factors include:
District support
Voter enthusiasm
Broken promises
Scandals
Debate performance
Influence snowballing
Players should lose and say:
“Yeah… that tracks.”

 AI-Assisted Content Pipeline
AI is used as a content multiplier, not a designer.
AI generates:
Dialogue variants
NPC flavor text
Event descriptions
Satirical headlines
Opponent rhetoric
The game enforces:
Strict data formats
Tagged outcomes
Schema validation
Manual polish passes
This allows:
Fast content scaling
Consistent tone
Safe procedural remixing

 Key Features (Player-Facing)
Procedurally generated districts with handcrafted logic
Deep dialogue-driven gameplay
Political satire without real-world parties or candidates
Multiple playstyles and builds
High replayability with short runs
Streamer-friendly systems and outcomes
Single-player, offline
UI similar to pokemon for reference

 Tech Stack
Engine
Godot 4.x (Stable)
2D / 2.5D presentation
Windows-only build (initial release)
Programming
GDScript
Modular, system-first architecture
Strong separation of logic, UI, and content
Tools & Workflow
Godot Editor (runtime, scene composition)
VS Code (primary coding environment)
GitHub Copilot / AI tools for boilerplate and content tooling
JSON-based content files
Custom content validation tools (dev mode)
Platform
Steam (Windows)
Steam demo planned
Optional Steamworks features post-launch

Project Philosophy (Why This Will Ship)
Systems over spectacle
Data over hardcoded content
Satire through mechanics
AI-assisted, human-polished
Scoped for a solo developer

One-Line Elevator Pitch
Election Cycle is a satirical political RPG where winning isn’t about truth — it’s about which SKILL you’re willing to abuse before election day.



 7-Day Core Loop — Election Cycle
Each day introduces a different pressure vector, so the player can’t solve everything with one stat.
The goal is not realism — it’s exposing tradeoffs.

Day 1 — Registration
“Who are you pretending to be?”
Purpose
Establish identity
Lock starting constraints
Set expectations
Player Actions
Choose name, look, campaign flavor
Allocate starting SKILL points
Review:
Opponent profile
District theme
Main crisis
Media bias
Systems Impact
Sets:
Initial Legitimacy
Starting Kapital
Hidden expectations (high legitimacy = less forgiveness later)
Satire Angle
Registration forms already judge you
Opponent bio feels suspiciously curated
AI Content Use
Opponent backstory
District description
Media framing blurbs

Day 2 — Canvassing
“Say it to their face.”
Purpose
Establish grassroots support
Learn district issues
Build or burn trust early
Player Actions
Visit houses
Talk to NPCs
Make early promises
Gather issue intel
Primary SKILL Tested
Speechcraft
Legitimacy
Logic (early contradictions start here)
Failure Is OK
Being awkward now may help later (low expectations)
AI Content Use
NPC archetype dialogue
Issue hooks
Early skepticism lines

Day 3 — Posters
“How do you look from a distance?”
Purpose
Control Optics without saying Optics
Introduce passive Influence
Player Actions
Design campaign poster:
Slogan
Tone
Focus (policy / emotion / vague promise)
Place posters
Ask NPCs for reactions
Primary SKILL Tested
Influence
Logic (does slogan match promises?)
Legitimacy
System Twist
Posters boost Influence
Bad messaging creates delayed backlash
Satire Angle
NPCs interpret posters wildly differently
AI Content Use
Slogans
Reactions
Media commentary

Day 4 — Fundraiser
“Who owns you?”
Purpose
Introduce Kapital as power and poison
Create future debt
Player Actions
Call donors
Choose:
Clean funding
Questionable funding
Desperation funding
Decide how transparent to be
Primary SKILL Tested
Kapital
Legitimacy
Logic (strings attached)
Hidden Consequences
Donors demand favors later
Media may investigate
AI Content Use
Donor personalities
Conditions
Subtle threats

Day 5 — Town Event
“Perform in public.”
Purpose
Stress test your build
Force tradeoffs in real time
Player Actions
Attend event (festival, rally, protest, ceremony)
Choose where to spend attention
Handle interruptions
Primary SKILL Tested
Speechcraft
Influence
Legitimacy
Chaos Factor
Random events
NPCs confront you with past promises
Satire Angle
Doing nothing can be the safest choice
AI Content Use
Event flavor
Crowd reactions
Unexpected incidents

Day 6 — Debate
“Everything comes due.”
Purpose
Boss fight
Reveal contradictions
Lock narrative momentum
Structure
Multi-round:
Opening (Influence)
Policy (Speechcraft)
Attack/Defense (Logic)
Credibility (Legitimacy)
Media Aftermath (Kapital)
Key Rule
Debate does not create strength
It amplifies what already exists
AI Content Use
Opponent rhetoric
Moderator questions
Media spin

Day 7 — Results
“The math doesn’t care how you feel.”
Purpose
Payoff
Reflection
Motivation to replay
What Happens
Votes counted district-by-district
News reports explain why you won/lost
Epilogue based on:
Promises kept/broken
Scandals
Donor influence
Public trust
Replay Hook
“What if I leaned harder into Kapital?”
“What if I stayed logically consistent?”
“What if I embraced chaos?”

 NEWS SYSTEM (THE GLUE)
News runs every night between days.
What news does
Summarizes player actions
Reframes them (sometimes unfairly)
Foreshadows consequences
Nudges player planning
Types of News
Local headlines
Opinion columns
Anonymous leaks
Poll numbers
Rumors (true or false)
Important Rule
News is not objective.
It reflects media bias + your Influence + Kapital.
AI Content Sweet Spot
Headlines
Opinion blurbs
Satirical misinterpretations

WHY THIS LOOP IS EXCELLENT
Each day:
Tests different SKILL stats
Introduces new risk
No single stat solves everything
AI content fits naturally
Seed-based remixing is easy
Streamers get clear “episodes”
This loop is ship-ready design.

WEEK-BY-WEEK TIMELINE
Start: 12 Jan 2026
End: 30 Nov 2026
Weekly time: ~17–18 hrs
Experience assumption: Senior JS dev, new to Godot

 PHASE 0 — GODOT ORIENTATION (Weeks 1–2)
Goal: Translate your JS instincts into Godot concepts
This is NOT “learning programming” — it’s learning where things live

Week 1 (Jan 12–18) — Godot Mental Model (Fast Track)
Focus: Engine concepts only
Learn (quickly):
Scene = component tree (think React component)
Node = instance with lifecycle
Signals = events/callbacks
Control nodes = DOM + CSS layout
Build (hands-on):
Menu scene
Button → signal → function
Scene switching
Deliverable
Main menu → start game → back
You’re comfortable navigating the editor
⏱️ This should feel easy.

Week 2 (Jan 19–25) — GDScript ≈ JS Brain Mapping
Focus: Writing real code immediately
Do
Write:
GameManager (autoload singleton)
Day counter
Global state
Load JSON from disk
Print parsed data
Deliverable
Game boots → loads content → prints data
You trust GDScript syntax
 From here onward, treat Godot like any other runtime.

 PHASE 1 — CORE SYSTEMS (Weeks 3–8)
Goal: Systems > content
Output: Days 1–3 playable end-to-end

Week 3 — Project Architecture Lock
Focus: Prevent rewrites later
Set up
/systems
  skill_system.gd
  dialogue_system.gd
  seed_system.gd
/ui
/content
/tools

Build
Global GameState
Save/load stub
Debug overlay
Deliverable
Clean, scalable structure

Week 4 — SKILL System (Full)
Implement all 5 stats
Point allocation
Modifiers
Debug UI
Deliverable
Stats change, persist, affect logic

Week 5 — Dialogue Data + Loader
Define strict JSON schema
Dialogue scenes
Choices + effects
Deliverable
Dialogue renders from data

Week 6 — Dialogue Runner + Effects
Choice selection
SKILL checks
NPC trust
Flags
Deliverable
Dialogue does something

Week 7 — Seeded Scene Selector
Deterministic RNG
Tag filtering
Weighted picks
Deliverable
Same seed = same run

Week 8 — News System + Day Progression
End-of-day news
Day unlock logic
🎯 VERTICAL SLICE READY (Days 1–3)
You are ahead of schedule here compared to the beginner plan.

 PHASE 2 — FULL 7-DAY LOOP (Weeks 9–20)
Goal: Feature complete by July/August

Weeks 9–10 — Poster System (Day 3 deepening)
Poster choices
Influence modifiers
Delayed consequences

Weeks 11–12 — Fundraiser (Day 4)
Kapital gain
Donor flags
Media suspicion

Weeks 13–14 — Event System (Day 5)
Modular events
Interruptions
Crowd reactions

Weeks 15–17 — Debate System (Day 6)
Multi-round logic
Opponent AI
Media aftermath
 CORE GAME COMPLETE

Weeks 18–20 — Endgame (Day 7)
Vote calculation
Epilogues
Replay summary
At this point, the game is fully playable start to finish.

 PHASE 3 — CONTENT + POLISH (Weeks 21–36)
Goal: Depth, not scope

Weeks 21–26
AI-generated content
Balance passes
UI clarity
More NPCs/events

Weeks 27–30
Demo prep
Onboarding
Tutorial text

Weeks 31–34
Steam page
Screenshots
Trailer

Weeks 35–38
Bug fixing
Performance
QA

 PHASE 4 — LAUNCH BUFFER (Weeks 39–46)
Goal: Ship calmly

Weeks 39–42
Final polish
Marketing beats
Streamer outreach

Weeks 43–46 (Nov)
Release
Hotfixes
Post-launch support
 SHIP BY NOV END (WITH BUFFER)

 KEY DIFFERENCES FROM BEGINNER PLAN
Area
Beginner
You
Godot learning
4 weeks
2 weeks
Vertical slice
Week 12
Week 8
Feature complete
Sept
July/Aug
Buffer
Thin
Comfortable

Your experience buys you safety.

 New Biggest Risk (for senior devs)
Over-engineering
Abstracting too early
Building “perfect” systems
Rule for you:
If it works and is ugly, stop.



