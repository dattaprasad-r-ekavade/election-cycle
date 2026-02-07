extends Node

## News System - Generates and displays news between days
## Reflects player actions, media bias, and foreshadows consequences

signal news_generated(headlines: Array)
signal news_displayed(headline: Dictionary)

var news_history: Array[Dictionary] = []
var todays_news: Array[Dictionary] = []


func _ready() -> void:
	print("[NewsSystem] Initialized")


func clear_news() -> void:
	"""Clear all news history"""
	news_history.clear()
	todays_news.clear()


func generate_daily_news() -> Array[Dictionary]:
	"""Generate news for the current day"""
	todays_news.clear()

	var day := GameManager.current_day
	var headlines: Array[Dictionary] = []

	# Day-specific news hooks
	match day:
		1:
			headlines.append(_generate_registration_news())
		2:
			headlines.append(_generate_canvassing_news())
		3:
			headlines.append(_generate_poster_news())
		4:
			headlines.append(_generate_fundraiser_news())
		5:
			headlines.append(_generate_event_news())
		6:
			headlines.append(_generate_debate_news())
		7:
			headlines.append(_generate_election_news())

	# Add contextual news based on player state
	if GameManager.scandals.size() > 0:
		headlines.append(_generate_scandal_followup())

	if GameManager.promises_broken.size() > 0:
		headlines.append(_generate_broken_promise_news())

	# Add poll numbers
	headlines.append(_generate_poll_news())

	# Apply media bias
	for headline in headlines:
		headline.bias_adjusted = _apply_media_bias(headline)

	todays_news = headlines
	news_history.append_array(headlines)
	news_generated.emit(headlines)

	return headlines


func _generate_registration_news() -> Dictionary:
	return {
		"type": "local",
		"headline": "New Candidate Enters Race for %s" % GameManager.district_name,
		"body": "%s has officially registered to run against incumbent favorite %s. The race for %s just got interesting." % [
			GameManager.player_name,
			GameManager.opponent_name,
			GameManager.district_name
		],
		"tone": "neutral",
		"day": GameManager.current_day
	}


func _generate_canvassing_news() -> Dictionary:
	var trust_avg := 0
	for npc_data in GameManager.npc_trust.values():
		trust_avg += npc_data.trust
	trust_avg = trust_avg / max(GameManager.npc_trust.size(), 1)

	var tone := "neutral"
	var headline := ""
	if trust_avg > 20:
		headline = "%s Receives Warm Welcome While Canvassing" % GameManager.player_name
		tone = "positive"
	elif trust_avg < -20:
		headline = "Residents Skeptical of %s's Door-to-Door Campaign" % GameManager.player_name
		tone = "negative"
	else:
		headline = "%s Hits the Streets in %s" % [GameManager.player_name, GameManager.district_name]

	return {
		"type": "local",
		"headline": headline,
		"body": "The candidate was seen going door-to-door in the district today.",
		"tone": tone,
		"day": GameManager.current_day
	}


func _generate_poster_news() -> Dictionary:
	var influence := SkillSystem.get_skill("influence")
	var headline := ""
	var tone := "neutral"

	if influence >= 7:
		headline = "%s's Campaign Posters Dominate the District" % GameManager.player_name
		tone = "positive"
	elif influence <= 3:
		headline = "Critics Mock %s's Campaign Imagery" % GameManager.player_name
		tone = "negative"
	else:
		headline = "Campaign Posters Go Up Across %s" % GameManager.district_name

	return {
		"type": "local",
		"headline": headline,
		"body": "Visual campaigning is in full swing as election day approaches.",
		"tone": tone,
		"day": GameManager.current_day
	}


func _generate_fundraiser_news() -> Dictionary:
	var kapital := SkillSystem.get_skill("kapital")
	var headline := ""
	var tone := "neutral"

	if kapital >= 7:
		headline = "%s Rakes in Campaign Donations" % GameManager.player_name
		tone = "positive"
	elif kapital <= 3:
		headline = "Questions Raised About %s's Campaign Funding" % GameManager.player_name
		tone = "negative"
	else:
		headline = "Campaign Fundraising Continues in %s Race" % GameManager.district_name

	return {
		"type": "local",
		"headline": headline,
		"body": "Money continues to flow into both campaigns.",
		"tone": tone,
		"day": GameManager.current_day
	}


func _generate_event_news() -> Dictionary:
	var legitimacy := SkillSystem.get_skill("legitimacy")
	var headline := ""
	var tone := "neutral"

	if legitimacy >= 7:
		headline = "%s Shines at Town Event" % GameManager.player_name
		tone = "positive"
	elif legitimacy <= 3:
		headline = "Awkward Moments for %s at Public Event" % GameManager.player_name
		tone = "negative"
	else:
		headline = "Candidates Attend Community Event"

	return {
		"type": "local",
		"headline": headline,
		"body": "Both candidates made appearances at today's town event.",
		"tone": tone,
		"day": GameManager.current_day
	}


func _generate_debate_news() -> Dictionary:
	var speechcraft := SkillSystem.get_skill("speechcraft")
	var logic := SkillSystem.get_skill("logic")
	var headline := ""
	var tone := "neutral"

	if speechcraft >= 7 and logic >= 5:
		headline = "%s Dominates Debate Performance" % GameManager.player_name
		tone = "positive"
	elif speechcraft <= 3 or logic <= 3:
		headline = "%s Stumbles in Debate Against %s" % [GameManager.player_name, GameManager.opponent_name]
		tone = "negative"
	else:
		headline = "Heated Debate Between Candidates"

	return {
		"type": "local",
		"headline": headline,
		"body": "The final debate before election day produced fireworks.",
		"tone": tone,
		"day": GameManager.current_day
	}


func _generate_election_news() -> Dictionary:
	return {
		"type": "breaking",
		"headline": "ELECTION DAY: Polls Open in %s" % GameManager.district_name,
		"body": "Voters head to the polls to decide between %s and %s." % [
			GameManager.player_name,
			GameManager.opponent_name
		],
		"tone": "neutral",
		"day": GameManager.current_day
	}


func _generate_scandal_followup() -> Dictionary:
	var latest_scandal: Dictionary = GameManager.scandals[-1]
	return {
		"type": "investigation",
		"headline": "DEVELOPING: " + latest_scandal.get("headline", "Campaign Controversy"),
		"body": "Questions continue to swirl around recent revelations.",
		"tone": "negative",
		"day": GameManager.current_day
	}


func _generate_broken_promise_news() -> Dictionary:
	return {
		"type": "opinion",
		"headline": "OPINION: Can We Trust %s's Promises?" % GameManager.player_name,
		"body": "Some voters are beginning to question the candidate's commitment to campaign pledges.",
		"tone": "negative",
		"day": GameManager.current_day
	}


func _generate_poll_news() -> Dictionary:
	# Calculate approximate poll numbers
	var support := 45.0
	support += SkillSystem.get_skill("influence") * 1.5
	support += SkillSystem.get_skill("legitimacy") * 1.0
	support -= GameManager.scandals.size() * 3
	support += GameManager.endorsements.size() * 2
	support += randf_range(-5, 5)  # Polling margin of error

	support = clampf(support, 20, 80)

	var headline := ""
	var tone := "neutral"

	if support > 52:
		headline = "POLL: %s Leads by %.0f Points" % [GameManager.player_name, support - 50]
		tone = "positive"
	elif support < 48:
		headline = "POLL: %s Trails by %.0f Points" % [GameManager.player_name, 50 - support]
		tone = "negative"
	else:
		headline = "POLL: Race Too Close to Call"

	return {
		"type": "poll",
		"headline": headline,
		"body": "Latest polling shows %s at %.0f%% and %s at %.0f%%." % [
			GameManager.player_name, support,
			GameManager.opponent_name, 100 - support
		],
		"tone": tone,
		"day": GameManager.current_day,
		"poll_number": support
	}


func _apply_media_bias(headline: Dictionary) -> Dictionary:
	"""Adjust headline based on media bias"""
	var bias := GameManager.media_bias
	var modified := headline.duplicate()

	# Bias affects how news is framed
	if bias > 0.3 and headline.tone == "negative":
		# Friendly media softens negative news
		modified.headline = modified.headline.replace("Questions Raised", "Minor Concerns")
		modified.headline = modified.headline.replace("Stumbles", "Faces Challenges")
	elif bias < -0.3 and headline.tone == "positive":
		# Hostile media undermines positive news
		modified.headline = modified.headline.replace("Dominates", "Claims Victory in")
		modified.headline = modified.headline.replace("Shines", "Appears at")

	return modified


func get_todays_news() -> Array[Dictionary]:
	"""Get news generated for today"""
	return todays_news


func get_all_news() -> Array[Dictionary]:
	"""Get complete news history"""
	return news_history
