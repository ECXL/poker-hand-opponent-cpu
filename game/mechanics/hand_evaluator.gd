class_name HandEvaluator

var cards: Array[Card]
var type: HandType
var mainHand: Array[Card]

var potentialHand: HandType
var potentialValue: int

var MAX_CARD_POOL = 7

enum HandType {
	HIGH_CARD = 0,
	PAIR = 1,
	TWO_PAIR = 2,
	THREE_OF_A_KIND = 3,
	STRAIGHT = 4,
	FLUSH = 5,
	FULL_HOUSE = 6,
	FOUR_OF_A_KIND = 7,
	STRAIGHT_FLUSH = 8,
	ROYAL_FLUSH = 9,
}

# Called when the node enters the scene tree for the first time.
func _ready(passed_cards: Array[Card]) -> void:
	cards = []
	cards.assign(passed_cards)
	type = HandType.HIGH_CARD # Represents the type of the best hand
	mainHand = [] # Represents the best 5 card hand

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func identifyHand() -> void:
	"""
	Main logic flow for hand evaluation.
	Checks pair-related hands first, then flush/straight-related hands.
	"""
	checkForPairHands()
	checkForFlushStraightHands()
	
	# Default fallback if no stronger hand found
	if type == HandType.HIGH_CARD:
		cards.sort_custom(func(a, b): return a.card_info["value"] > b.card_info["value"])
		mainHand = cards.slice(0, 5)
		
func checkForPairHands() -> void:
	"""
    Checks for pairs, two pair, trips, full house, and quads.
	"""
	cards.reverse()
	var rank_counts = {}
	for card in cards:
		var value = card.card_info["value"]
		rank_counts[value] = rank_counts.get(value, 0) + 1
		
	var sorted_dict = {}
	var count_values = rank_counts.keys()
	count_values.sort_custom(func(a, b): return rank_counts[a] > rank_counts[b])

	for key in count_values:
		sorted_dict[key] = rank_counts[key]
		
	mainHand.clear()
	
	#Checks for a four of a kind 
	if rank_counts[count_values[0]] == 4:
		checkFourOfAKind(rank_counts)
		return
	#Checks for a full house
	if rank_counts[count_values[0]] >= 3 and (rank_counts[count_values[1]] >= 2 or rank_counts[count_values[1]] == 3):
		checkFullHouse(rank_counts)
		return
	#Checks for a three of a kind
	if rank_counts[count_values[0]] == 3:
		checkThreeOfAKind(rank_counts)
		return
	#Checks for a two pair
	if rank_counts[count_values[0]] == 2 and rank_counts[count_values[1]] == 2:
		checkTwoPair(rank_counts)
		return
	#Checks for a pair 
	if rank_counts[count_values[0]] == 2:
		checkPair(rank_counts)
		return
	
func checkForFlushStraightHands() -> void:
	"""
    Checks for flush, straight, straight flush, and royal flush.
	"""
	var flushCards = getFlushCards()
	if flushCards:
		if checkRoyalFlush(flushCards):
			return
		if checkStraightFlush(flushCards):
			return
			
		if type < HandType.FLUSH:
			mainHand = flushCards.slice(0, 5)
			type = HandType.FLUSH
		return
		
	checkStraight()
	
func checkRoyalFlush(flushCards: Array[Card]):
	"""
    Checks if flush cards form a royal flush.
	"""
	var flush_ranks = []
	for card in flushCards.slice(0,5):
		flush_ranks.append(card.card_info["value"])
	if flush_ranks == ['A', 'K', 'Q', 'J', '10']:
		mainHand = flushCards
		type = HandType.ROYAL_FLUSH
		return true
	return false
	
func checkStraightFlush(flushCards: Array[Card]):
	"""
    Checks if flush cards form a straight flush.
	"""
	var flushStraight = getHighestStraight(flushCards, true)
	if flushStraight:
		type = HandType.STRAIGHT_FLUSH
		mainHand = flushStraight
		return true
	return false
	
func checkStraight():
	"""
    Checks if a straight is present, including low-Ace straight.
	"""
	var straightCards = getHighestStraight(cards, false) # this is here in case the straight is Ace, King, Queen, Jack, 10
	if not straightCards:
		straightCards = getHighestStraight(cards, true) # this is here in case the straight is Ace, 2, 3, 4, 5
	if straightCards:
		type = HandType.STRAIGHT
		mainHand = straightCards

func getHighestStraight(card_array: Array[Card], aceLow: bool):
	"""
    Returns the highest straight (if any) from a set of cards.
    Handles duplicates and optionally ace-low straights.
	"""
	var unique_cards = []
	var highestRank = 0
	var highestStraight = null
	
	# Get unique ranks only
	var seen_ranks = {}
	for card in card_array:
		if card.card_info["value"] not in seen_ranks:
			unique_cards.append(card)
			seen_ranks[card.card_info["value"]] = true
	
	# Sort cards by value (descending for ace-high, special handling for ace-low)
	if aceLow:
		# For ace-low: sort with aces as 1
		unique_cards.sort_custom(func(a, b): return get_card_value(a, true) > get_card_value(b, true))
	else:
		# For ace-high: sort normally
		unique_cards.sort_custom(func(a, b): return get_card_value(a, false) > get_card_value(b, false))
	
	# Check for straights
	for i in range(len(unique_cards) - 4):
		var straight: Array[Card] = []
		straight.assign(unique_cards.slice(i, i+5))
		var top_val = get_card_value(straight[0], aceLow)
		var bottom_val = get_card_value(straight[4], aceLow)
		
		if top_val - bottom_val == 4:
			if top_val > highestRank:
				highestStraight = straight
				highestRank = top_val
	
	return highestStraight
	
func getFlushCards() -> Array[Card]:
	"""
    Returns 5+ cards of the same suit if flush is possible.
	"""
	var suit_dict = {'spade': [], 'heart': [], 'diamond': [], 'club': []}
	for card in cards:
		suit_dict[card.card_info["suit"]].append(card)
	for suit_cards in suit_dict.values():
		if len(suit_cards) >= 5:
			suit_cards.sort_custom(func(a, b): return get_card_value(a, false) > get_card_value(b, false))  # Descending sort
			var result: Array[Card] = []
			result.assign(suit_cards)
			return result
	return []
	
func checkFourOfAKind(rank_counts):
	"""Builds main hand with four of a kind and top kicker."""
	var four_of_a_kind_rank = []
	for rank in rank_counts:
		if rank_counts[rank] == 4:
			four_of_a_kind_rank.append(rank)
	var four_of_a_kind_cards = []
	for card in cards:
		if card.card_info["value"] == four_of_a_kind_rank[0]:
			four_of_a_kind_cards.append(card)	
	mainHand.append_array(four_of_a_kind_cards)
	type = HandType.FOUR_OF_A_KIND
	var kicker_cards = []
	for card in cards:
		if card.card_info["value"] != four_of_a_kind_rank[0]:
			kicker_cards.append(card)
	
	kicker_cards.sort_custom(func(a, b): return a.card_info["value"] > b.card_info["value"])
	mainHand.append_array(kicker_cards.slice(0, 1))

func checkFullHouse(rank_counts):
	"""Builds main hand for full house: three of a kind + pair."""
	var rank_order = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
	
	var three_of_a_kind_ranks = []
	for rank in rank_counts:
		if rank_counts[rank] >= 3:
			three_of_a_kind_ranks.append(rank)
	
	three_of_a_kind_ranks.sort_custom(func(a, b): return rank_order.find(a) > rank_order.find(b))
	
	var three_of_a_kind_rank = three_of_a_kind_ranks[0]
	var pair_ranks = []
	for rank in rank_counts:
		if rank_counts[rank] >= 2 and rank != three_of_a_kind_rank:
			pair_ranks.append(rank)
	
	pair_ranks.sort_custom(func(a, b): return rank_order.find(a) > rank_order.find(b))
	var pair_rank = pair_ranks[0]
	mainHand.append_array(cards.filter(func(card): return card.card_info["value"] == three_of_a_kind_rank).slice(0, 3))
	mainHand.append_array(cards.filter(func(card): return card.card_info["value"] == pair_rank).slice(0, 2))
	type = HandType.FULL_HOUSE

func checkThreeOfAKind(rank_counts):
	"""Builds three-of-a-kind hand with two kickers."""
	var three_of_a_kind_rank = []
	for rank in rank_counts:
		if rank_counts[rank] == 3:
			three_of_a_kind_rank.append(rank)
	
	var three_of_a_kind_cards = []
	for card in cards:
		if card.card_info["value"] == three_of_a_kind_rank[0]:
			three_of_a_kind_cards.append(card)
	
	mainHand.append_array(three_of_a_kind_cards)
	type = HandType.THREE_OF_A_KIND
	
	var potential_kickers = cards.filter(func(card): return card.card_info["value"] != three_of_a_kind_rank[0])
	potential_kickers.sort_custom(func(a, b): return get_card_value(a) > get_card_value(b))
	mainHand.append_array(potential_kickers.slice(0, 2))

func checkTwoPair(rank_counts):
	"""Builds two pair hand with top kicker."""
	var rank_order = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
	
	var two_pair_ranks = []
	for rank in rank_counts:
		if rank_counts[rank] == 2:
			two_pair_ranks.append(rank)
	two_pair_ranks.sort_custom(func(a, b): return rank_order.find(a) > rank_order.find(b))
	
	mainHand.append_array(cards.filter(func(card): return card.card_info["value"] == two_pair_ranks[0]))
	mainHand.append_array(cards.filter(func(card): return card.card_info["value"] == two_pair_ranks[1]))
	type = HandType.TWO_PAIR
	var potential_kickers = []
	for card in cards:
		if card.card_info["value"] not in two_pair_ranks:
			potential_kickers.append(card)
			
	potential_kickers.sort_custom(func(a, b): return get_card_value(a) > get_card_value(b))
	
	if potential_kickers:
		mainHand.append(potential_kickers[0])
		
func checkPair(rank_counts):
	"""Builds one pair hand with three kickers."""
	var pair_rank = []
	for rank in rank_counts:
		if rank_counts[rank] == 2:
			pair_rank.append(rank)
			
	var single_pair_cards = []
	for card in cards:
		if card.card_info["value"] == pair_rank[0]:
			single_pair_cards.append(card)
	
	mainHand.append_array(single_pair_cards)
	type = HandType.PAIR
	var potential_kickers = cards.filter(func(card): return card.card_info["value"] != pair_rank[0])
	potential_kickers.sort_custom(func(a, b): return get_card_value(a) > get_card_value(b))
	mainHand.append_array(potential_kickers.slice(0, 3))
	
func identifyPotentialHands(hand_cards: Array[Card]) -> void:
	"""
	Identifies potential hands that can be made and advantage due to cards in hand to weigh whether to stay in or not
	"""
	# var board = cards.filter(func(x): return x not in hand_cards)
	
	var stay_in_potential: int = 0
	if type == HandType.HIGH_CARD:
		stay_in_potential += checkHighCardPotential(hand_cards)
				
	if type == HandType.PAIR:
		stay_in_potential += checkPairPotential(hand_cards)
				
	if type == HandType.TWO_PAIR or type == HandType.FULL_HOUSE:
		stay_in_potential += checkTwoPairAndFullHousePotential(hand_cards)
		
	if type == HandType.THREE_OF_A_KIND or type == HandType.FOUR_OF_A_KIND:
		stay_in_potential += checkOfAKindPotential(hand_cards)
		
	if type < HandType.STRAIGHT:
		stay_in_potential += checkPotentialStraights(hand_cards)
	
	if type < HandType.FLUSH:
		stay_in_potential += checkPotentialFlushes(hand_cards)

	if type < HandType.STRAIGHT_FLUSH:
		stay_in_potential += checkPotentialStraightFlushes(hand_cards)
		
	if type == HandType.STRAIGHT or type == HandType.FLUSH or type == HandType.STRAIGHT_FLUSH or type == HandType.ROYAL_FLUSH:
		stay_in_potential += checkFlushStraightsPotential(hand_cards)
			
func checkHighCardPotential(hand_cards: Array[Card]) -> int:
	"""
	Identifies whether the High Card is in hand or not and adds weight
	based on the difference between the in hand and actual highest.
	"""
	var stay_in_potential = -15 # TODO: use this difference and its ilk in calculation of how likely opponent is to stay or fold
	var check_difference: int
	for card in hand_cards:
		check_difference = get_card_value(card) - get_card_value(mainHand[0])
		if check_difference > stay_in_potential:
			stay_in_potential = check_difference
		if check_difference == 0:
			stay_in_potential = get_card_value(mainHand[0]) - 6 # if high card is in hand, stay in chance is based on value
			print("High Card is in hand")
			break
	
	return stay_in_potential
	
func checkPairPotential(hand_cards: Array[Card]) -> int:
	"""
	Identifies whether the Pair in play is communal, in hand, or entirely in pocket. Also identifies whether a larger pair seems likely.
	"""
	var stay_in_potential = 0 # TODO: use this difference and its ilk in calculation of how likely opponent is to stay or fold
	var check_difference: int
	var in_hand = false
	var in_pocket = false
	
	var pair_value = get_card_value(mainHand[0])
	for card in hand_cards: 
		check_difference = get_card_value(card) - pair_value # to determine whether the pair is in hand or there is a potential higher pair.
		if check_difference == 0:
			if in_hand:
				in_pocket = true # if in_hand is already true then that means both values for pair are in pocket.
			else:
				in_hand = true # if check_difference is equal to zero then the pairing value must be in your hand.
	
	var highest_kicker = mainHand[2] # Highest kicker is the third as its the highest card that isn't the pair
	var higher_potential: int = get_card_value(highest_kicker) - pair_value # Checks if kicker is higher and thus could mean a higher pair is in play
	
	if higher_potential > 0:
		if hand_cards.has(highest_kicker): # if it is possible to make a new Two Pair with a higher value than the OG pair
			stay_in_potential += get_card_value(highest_kicker) / (MAX_CARD_POOL - cards.size() + 1) # chance to stay in lowers based on how many cards are left to reveal
			print("Potential higher pair in hand")
		elif higher_potential < 0:
			stay_in_potential -= get_card_value(highest_kicker) - pair_value # opponent could have potential higher pair, lower chance to stay
			print("Higher pair could be in opponent's hand")
	else:
		stay_in_potential += pair_value # highest pair achieved
	
	if in_hand:
		stay_in_potential += 10 # give boost if not entirely communal
		print("Pair value in hand")
		if in_pocket:
			stay_in_potential += 10 # gives additional boost if entirely in pocket
			print("Pair in pocket")
	
	return stay_in_potential
	
func checkTwoPairAndFullHousePotential(hand_cards: Array[Card]) -> int:
	"""
	Checks advantage of both Two Pair and Full House.
	"""
	
	var stay_in_potential = 0 # TODO: use this difference and its ilk in calculation of how likely opponent is to stay or fold
	var check_difference: int
	var in_hand = false
	var in_pocket = false
	var both_in_hand = false
	
	if (
	arrays_have_same_items(hand_cards, mainHand.slice(0, 2)) or  									# checks if first pair is in hand
	(type == HandType.TWO_PAIR and arrays_have_same_items(hand_cards, mainHand.slice(2, 4))) or  	# second pair (two pair)
	(type == HandType.FULL_HOUSE and arrays_have_same_items(hand_cards, mainHand.slice(3, 5)))		# pair in full house
	):
		in_pocket = true
		print("One of pairs entirely in pocket")
		
	if !in_pocket:
		var checkHand = []
		if type == HandType.TWO_PAIR:
			checkHand = mainHand.slice(0, 4)
		else:
			checkHand = mainHand
		for card in hand_cards:
			if checkHand.has(card):
				if !in_hand:
					in_hand = true
					print("One two pair/ full house value in hand")
				else:
					both_in_hand = true
					print("Both of the different two pair/ full house values in hand")
					
	if both_in_hand:
		stay_in_potential = 20 # TODO: play around with these numbers
	elif in_pocket:
		stay_in_potential = 18
	elif in_hand:
		stay_in_potential = 15
	else: # if all cards are communal then check kickers
		var highest_value = 0
		var card_value: int
		for card in hand_cards:
			card_value = get_card_value(card, true)
			if card_value > highest_value:
				highest_value = card_value
		stay_in_potential = highest_value
		print("Two pair is entirely communal")
		
	return stay_in_potential
	
func checkOfAKindPotential(hand_cards: Array[Card]) -> int:
	"""
	Checks advantage of both Two Pair and Full House.
	"""
	
	var stay_in_potential = 0 # TODO: use this difference and its ilk in calculation of how likely opponent is to stay or fold
	var in_hand = false
	var in_pocket = false
	
	for card in hand_cards: 
		if (card.card_info["value"] == mainHand[0].card_info["value"]):
			if !in_hand:
				in_hand = true
			else:
				in_pocket = true # if in_hand is already true then that means 2 of the values for the "x of a kind" are in pocket.
			
	if in_hand:
		stay_in_potential += 15 # give boost if not communal
		print("x of a kind is partly in hand")
		if in_pocket:
			stay_in_potential += 15 # gives additional boost if entirely in pocket
		print("Pair within x of a kind in hand")
	
	return stay_in_potential
	
func checkPotentialStraights(hand_cards: Array[Card]) -> int:
	"""
	Identifies whether there is the possibility of a Straight being created from current cards vs unrevealed cards
	"""

	var stay_in_potential = 0
	var card_values = []
	var straight_potential = false
	
	for card in cards:
		card_values.append(get_card_value(card, false))
		if card.card_info["value"] == 'A': # ace needs to be added as both high and low
			card_values.append(get_card_value(card, true))

	var potential_straight_values = 0
	for card_value in card_values:
		potential_straight_values = 0
		for n in range(card_value, card_value+5):
			if n in card_values:
				potential_straight_values+=1
		if potential_straight_values >= (5 - (MAX_CARD_POOL - cards.size())):
			straight_potential = true
			break
	
	if straight_potential:
		stay_in_potential = 5*(potential_straight_values) # TODO: adjust these numbers
		print("Potential straight to be made")
	
	return stay_in_potential
	
func checkPotentialFlushes(hand_cards: Array[Card]) -> int:
	"""
	Identifies whether there is the possibility of a Flush being created from current cards vs unrevealed cards
	"""
	
	var stay_in_potential = 0
	var card_suits = []
	var flush_potential = false
	
	for card in cards:
		card_suits.append(card.card_info["suit"])
		
	var potential_flush_values = 0
	var spade_count = card_suits.count("spade")
	var club_count = card_suits.count("club")
	var heart_count = card_suits.count("heart")
	var diamond_count = card_suits.count("diamond")
	var highest_suit_count = [spade_count, club_count, heart_count, diamond_count].max()
	
	if highest_suit_count >= (5 - (MAX_CARD_POOL - cards.size())):
		stay_in_potential = 5 * highest_suit_count # TODO: adjust these numbers
		print("Potential flush to be made")
		
	return stay_in_potential
	
func checkPotentialStraightFlushes(hand_cards: Array[Card]) -> int:
	"""
	Identifies whether there is the possibility of a Straight Flush being created from current cards vs unrevealed cards
	"""
	
	var stay_in_potential = 0
	var card_tuples = []
	var tuple = []
	var straight_flush_potential = false
	
	for card in cards:
		tuple = []
		tuple.append(get_card_value(card, false))
		tuple.append(card.card_info["suit"])
		card_tuples.append(tuple)
		if card.card_info["value"] == 'A':
			tuple = []
			tuple.append(get_card_value(card, true)) # need to check for both an ace high and low
			tuple.append(card.card_info["suit"])
			card_tuples.append(tuple)
	
	var potential_straight_flush = 0
	var potential_straight_flush_values = []
	var straight_flush_tuple = []
	for card_tuple in card_tuples:
		potential_straight_flush = 0 # reset for the check loop
		potential_straight_flush_values = [] # reset for the check loop
		for n in range(card_tuple[0], card_tuple[0]+5):
			straight_flush_tuple = []
			straight_flush_tuple.append(n)
			straight_flush_tuple.append(card_tuple[1])
			potential_straight_flush_values.append(straight_flush_tuple)
			
		for potential_straight_flush_value in potential_straight_flush_values:
			if potential_straight_flush_value in card_tuples:
				potential_straight_flush+=1
			
		if potential_straight_flush >= (5 - (MAX_CARD_POOL - cards.size())):
			straight_flush_potential = true
	
	if straight_flush_potential:
		stay_in_potential = 6 * potential_straight_flush # TODO: adjust these numbers
		print("Potential straight flush to be made")
	
	return stay_in_potential
	
func checkFlushStraightsPotential(hand_cards: Array[Card]) -> int:
	"""
	Evaluates the strength of the current Straight, Flush, or Straight Flush based on how many of its card members are in hand
	"""
	
	var stay_in_potential = 0
	var in_hand = false
	var both_in_hand = true
	
	for card in hand_cards:
		mainHand.has(card)
		if in_hand:
			both_in_hand = true
		else:
			in_hand = true
		
	if in_hand:
		print("Card in hand is in current straight/flush/straight flush")
		stay_in_potential += 5
		if both_in_hand:
			print("Both cards in hand is in current straight/flush/straight flush")
			stay_in_potential += 10
	
	return stay_in_potential
	
func arrays_have_same_items(arr1, arr2):
	"""Checks if arrays have the same items no matter the order"""
	if arr1.size() != arr2.size():
		return false
	for item in arr1:
		if item not in arr2:
			return false
	return true
	
func get_card_value(card: Card, aceLow: bool = false) -> int:
	"""Returns the numerical value of the card, keeping Ace being high or low into account"""
	var rank = card.card_info["value"]
	var rank_values = {
		"2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, 
		"9": 9, "10": 10, "J": 11, "Q": 12, "K": 13, "A": 14
	}
	
	if aceLow and rank == "A":
		return 1
	
	return rank_values.get(rank, 0)

func getType() -> HandType:
	"""Returns the evaluated hand type (enum)."""
	return type
	
func getMainHand() -> Array[Card]:
	"""Returns the five cards that make up the best hand."""
	return mainHand
	
func __eq__(hand_evaluator: Object) -> bool:
	"""Equality comparison based on hand type and card values."""
	if hand_evaluator.getType() != type:
		return false
	var otherHand = hand_evaluator.getMainHand()
	for i in range(5):
		if get_card_value(mainHand[i], false) != get_card_value(otherHand[i], false):
			return false
	return true

func __gt__(hand_evaluator: Object) -> bool:
	"""Greater-than comparison between two poker hands."""
	var otherHandValue = hand_evaluator.getType()
	if type > otherHandValue: 
		return true 
	if type < otherHandValue:
		return false
		
	var otherHand = hand_evaluator.getMainHand()
	for i in range(5):
		if get_card_value(mainHand[i], false) > get_card_value(otherHand[i], false):
			return true
	return false
