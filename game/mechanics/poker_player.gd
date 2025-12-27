class_name PokerPlayer
extends HandEvaluator

var money: int
var buy_in: int
var pot: int
var street: String
	
func checkStayInPotential(hand_cards: Array[Card]):
	var current_hand_value = hand_type_to_score()
	var potential_value = identifyPotentialHands(hand_cards)
	if street == "preflop":
		potential_value += 50
	
	var hand_strength = calculate_hand_strength(current_hand_value, float(potential_value))
	var pot_odds = calculate_pot_odds()
	var risk_level = calculate_risk_level()
	
	print("Hand Strength: ", hand_strength)
	print("Pot Odds: ", pot_odds)
	print("Risk Level: ", risk_level, "%")
	
	return decide_action(hand_strength, pot_odds, risk_level)

func hand_type_to_score() -> float:
	# Base scores for each hand type
	var base_score: float
	var hand_type = getType()
	var high_card_rank = getCardValue(mainHand[0])
	
	match hand_type:
		HandType.HIGH_CARD:
			base_score = 0.0
		HandType.PAIR:
			base_score = 20.0
		HandType.TWO_PAIR:
			base_score = 35.0
		HandType.THREE_OF_A_KIND:
			base_score = 50.0
		HandType.STRAIGHT:
			base_score = 60.0
		HandType.FLUSH:
			base_score = 70.0
		HandType.FULL_HOUSE:
			base_score = 80.0
		HandType.FOUR_OF_A_KIND:
			base_score = 90.0
		HandType.STRAIGHT_FLUSH, HandType.ROYAL_FLUSH:
			base_score = 98.0 
	
	# Add bonus based on high card (spreads values within each tier)
	var bonus_range: float
	match hand_type:
		HandType.HIGH_CARD:
			bonus_range = 18.0  # 0-18
		HandType.PAIR:
			bonus_range = 13.0  # 20-33
		HandType.TWO_PAIR:
			bonus_range = 13.0  # 35-48
		HandType.THREE_OF_A_KIND:
			bonus_range = 8.0   # 50-58
		HandType.STRAIGHT:
			bonus_range = 8.0   # 60-68
		HandType.FLUSH:
			bonus_range = 8.0   # 70-78
		HandType.FULL_HOUSE:
			bonus_range = 8.0   # 80-88
		HandType.FOUR_OF_A_KIND:
			bonus_range = 6.0   # 90-96
		HandType.STRAIGHT_FLUSH, HandType.ROYAL_FLUSH:
			bonus_range = 2.0   # 98-100
	
	# Normalize high card (2-14 where 14=Ace) to 0-1 range
	var normalized_high_card = (high_card_rank - 2) / 12.0
	
	return base_score + (bonus_range * normalized_high_card)
	
func calculate_hand_strength(current_hand_value: float, potential_value: float) -> float:
	# Weight current vs potential based on game stage
	var current_weight: float
	var potential_weight: float
	
	match street:
		"preflop":
			current_weight = 0.1
			potential_weight = 0.9
		"flop":
			current_weight = 0.5
			potential_weight = 0.5
		"turn":
			current_weight = 0.7
			potential_weight = 0.3
		"river":
			current_weight = 1.0
			potential_weight = 0.0
	
	return (current_hand_value * current_weight) + (potential_value * potential_weight)

func calculate_pot_odds() -> float:
	# Returns ratio of investment to potential return
	if buy_in != 0 and pot != 0:
		return buy_in / (pot + buy_in)
	else:
		return 0
	
func calculate_risk_level() -> float:
	# What % of your stack is at risk?
	return (buy_in / money) * 100

func decide_action(hand_strength: float, pot_odds: float, risk_level: float) -> String:
	# FOLD conditions
	if hand_strength < 30 and risk_level > 20:
		return "FOLD"
	
	if hand_strength < 20:
		return "FOLD"
	
	# Strong hand scenarios
	if hand_strength > 75:
		if risk_level < 30:
			return "RAISE"
		else:
			return "CHECK/CALL"
	
	# Medium hand with good pot odds
	if hand_strength > 50:
		if pot_odds < 0.3:  # Getting good odds
			return "CALL"
		elif risk_level < 15:
			return "RAISE"
		else:
			return "CHECK/CALL"
	
	# Weak-medium hand
	if hand_strength > 15:
		if pot_odds < 0.2 and risk_level < 10:
			return "CALL"
		else:
			return "CHECK/FOLD"
	
	# Default: weak hand
	return "FOLD"

func setMoney(money_value: int):
	money = money_value

func getMoney() -> int:
	return money
	
func setBuyIn(money_value: int):
	buy_in = money_value

func getBuyIn() -> int:
	return buy_in
	
func setPot(money_value: int):
	pot = money_value

func getPot() -> int:
	return pot

func setStreet(street_string: String):
	street = street_string

func getStreet() -> String:
	return street
	
func setMoneyParams(money_value: int, buy_in_value: int, pot_value: int):
	setMoney(money_value)
	setBuyIn(buy_in_value)
	setPot(pot_value)
