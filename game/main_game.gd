extends Node


@onready var card_manager = $CardManager
@onready var card_factory = $CardManager/MyCardFactory
@onready var hand = $CardManager/Hand
@onready var deck = $CardManager/Deck
@onready var board = $CardManager/Board
@onready var hand_outcome_label = $HandOutcomeLabel

var hand_evaluator: HandEvaluator = null
var board_revealed: int = 0


func _ready():
	_reset_deck()
	

func _reset_deck():
	var list = _get_randomized_card_list()
	deck.clear_cards()
	for card in list:
		card_factory.create_card(card, deck)


func _get_randomized_card_list() -> Array:
	var suits = ["club", "spade", "diamond", "heart"]
	var values = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
	
	var card_list = []
	for suit in suits:
		for value in values:
			card_list.append("%s_%s" % [suit, value])
	
	card_list.shuffle()
	
	return card_list


func _on_draw_1_button_pressed() -> void:
	hand.move_cards(deck.get_top_cards(1))


func _on_draw_hand_button_pressed() -> void:
	var current_draw_number = 2
	while current_draw_number > 0:
		var result = hand.move_cards(deck.get_top_cards(current_draw_number))
		if result:
			break
		current_draw_number -= 1


func _on_deal_board_button_pressed() -> void:
	var current_draw_number = 5
	while current_draw_number > 0:
		var result = board.move_cards(deck.get_top_cards(current_draw_number))
		if result:
			break
		current_draw_number -= 1

func _on_flop_button_pressed() -> void:
	var current_flip_number = 2
	while current_flip_number >= 0:
		board._held_cards[current_flip_number].show_front = true
		current_flip_number -=1
	board_revealed = 3

func _on_turn_button_pressed() -> void:
	board._held_cards[3].show_front = true
	board_revealed = 4

func _on_river_button_pressed() -> void:
	board._held_cards[4].show_front = true
	board_revealed = 5
	
func _on_reveal_all_button_pressed() -> void:
	var current_flip_number = 4
	while current_flip_number >= 0:
		board._held_cards[current_flip_number].show_front = true
		current_flip_number -=1
	board_revealed = 5

func _on_evaluate_hand_button_pressed() -> void:
	var combination_hand: Array[Card] = []
	combination_hand.append_array(hand._held_cards)
	combination_hand.append_array(board._held_cards)
	
	hand_evaluator = HandEvaluator.new()
	hand_evaluator._ready(combination_hand) # initialises HandEvaluator with the available cards
	hand_evaluator.identifyHand()
	
	var hand_type = hand_evaluator.getType()
	var main_hand = hand_evaluator.getMainHand()
	
	hand_outcome_label.text = "Hand Type: " + str(get_hand_type_name(hand_type))
	print("Main Hand: ")
	for card in main_hand:
		print(" ", card.card_info["value"], " of ", card.card_info["suit"])
		
func _on_evaluate_potential_hand_button_pressed() -> void:
	var combination_hand: Array[Card] = []
	combination_hand.append_array(hand._held_cards)
	var shown_cards: Array[Card] = board._held_cards.slice(0, board_revealed)
	combination_hand.append_array(shown_cards)
			
	hand_evaluator = HandEvaluator.new()
	hand_evaluator._ready(combination_hand) # initialises HandEvaluator with the available cards
	hand_evaluator.identifyHand()
	
	var hand_type = hand_evaluator.getType()
	hand_outcome_label.text = "Hand Type: " + str(get_hand_type_name(hand_type))
	
	hand_evaluator.identifyPotentialHands(hand._held_cards)
		
func get_hand_type_name(hand_type: HandEvaluator.HandType) -> String:
	match hand_type:
		HandEvaluator.HandType.HIGH_CARD:
			return "High Card"
		HandEvaluator.HandType.PAIR:
			return "Pair"
		HandEvaluator.HandType.TWO_PAIR:
			return "Two Pair"
		HandEvaluator.HandType.THREE_OF_A_KIND:
			return "Three of a Kind"
		HandEvaluator.HandType.STRAIGHT:
			return "Straight"
		HandEvaluator.HandType.FLUSH:
			return "Flush"
		HandEvaluator.HandType.FULL_HOUSE:
			return "Full House"
		HandEvaluator.HandType.FOUR_OF_A_KIND:
			return "Four of a Kind"
		HandEvaluator.HandType.STRAIGHT_FLUSH:
			return "Straight Flush"
		HandEvaluator.HandType.ROYAL_FLUSH:
			return "Royal Flush"
		_:
			return "Unknown"
	

func _on_reset_deck_button_pressed():
	_reset_deck()


func _on_undo_button_pressed():
	card_manager.undo()


func _on_shuffle_hand_button_pressed():
	hand.shuffle()

func _on_clear_all_button_pressed():
	_reset_deck()
	hand.clear_cards()
	board.clear_cards()
	board_revealed = 0
