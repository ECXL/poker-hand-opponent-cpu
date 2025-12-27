extends Node


@onready var card_manager = $CardManager
@onready var card_factory = $CardManager/MyCardFactory
@onready var hand = $CardManager/Hand
@onready var deck = $CardManager/Deck
@onready var board = $CardManager/Board
@onready var cpu_hand = $CardManager/CPUHand
@onready var hand_outcome_label = $HandOutcomeLabel
@onready var winner_outcome_label = $WinnerOutcomeLabel
@onready var player_money_label = $PlayerMoneyLabel
@onready var cpu_money_label = $CPUMoneyLabel
@onready var pot_money_label = $PotMoneyLabel
@onready var player_raise_slider = $PlayerRaiseSlider
@onready var player_raise_label = $PlayerRaiseLabel
@onready var check_money_label = $CheckMoneyLabel

var player_hand_evaluator: HandEvaluator = null
var cpu_hand_evaluator: HandEvaluator = null
var board_revealed: int = 0

var player_money: int = 1000
var cpu_money: int = 100
var pot_money: int = 0
var check_money: int = 0

func _ready():
	_reset_deck()
	update_money_labels()
	update_player_slider_max()
	player_raise_slider.value = 0
	update_player_label()

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
		
func _on_draw_cpu_hand_button_pressed() -> void:
	var current_draw_number = 2
	while current_draw_number > 0:
		var result = cpu_hand.move_cards(deck.get_top_cards(current_draw_number))
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
	
	evaluate_hand(combination_hand, player_hand_evaluator)
	
func _on_evaluate_cpu_hand_button_pressed() -> void:
	var combination_hand: Array[Card] = []
	combination_hand.append_array(cpu_hand._held_cards)
	combination_hand.append_array(board._held_cards)
	
	evaluate_hand(combination_hand, cpu_hand_evaluator)
		
func _on_evaluate_potential_hand_button_pressed() -> void:
	var combination_hand: Array[Card] = []
	combination_hand.append_array(cpu_hand._held_cards)
	var shown_cards: Array[Card] = board._held_cards.slice(0, board_revealed)
	combination_hand.append_array(shown_cards)
			
	evaluate_potential_hand(combination_hand, cpu_hand_evaluator)
	
func evaluate_hand(combination_hand: Array[Card], hand_evaluator: HandEvaluator) -> void:
	hand_evaluator = HandEvaluator.new()
	hand_evaluator._ready(combination_hand) # initialises HandEvaluator with the available cards
	hand_evaluator.identifyHand()
	
	var hand_type = hand_evaluator.getType()
	var main_hand = hand_evaluator.getMainHand()
	
	hand_outcome_label.text = "Hand Type: " + str(get_hand_type_name(hand_type))
	print("Main Hand: ")
	for card in main_hand:
		print(" ", card.card_info["value"], " of ", card.card_info["suit"])
		
func evaluate_potential_hand(combination_hand: Array[Card], hand_evaluator: HandEvaluator) -> void:
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
			
func _on_evaluate_winner_button_pressed() -> void:
	var player_combination_hand: Array[Card] = []
	player_combination_hand.append_array(hand._held_cards)
	player_combination_hand.append_array(board._held_cards)
			
	player_hand_evaluator = HandEvaluator.new()
	player_hand_evaluator._ready(player_combination_hand) # initialises HandEvaluator with the available cards
	player_hand_evaluator.identifyHand()
	
	var cpu_combination_hand: Array[Card] = []
	cpu_combination_hand.append_array(cpu_hand._held_cards)
	cpu_combination_hand.append_array(board._held_cards)
			
	cpu_hand_evaluator = HandEvaluator.new()
	cpu_hand_evaluator._ready(cpu_combination_hand) # initialises HandEvaluator with the available cards
	cpu_hand_evaluator.identifyHand()
	
	if player_hand_evaluator.__gt__(cpu_hand_evaluator):
		winner_outcome_label.text = "Player Wins!"
	else:
		winner_outcome_label.text = "CPU Wins!"

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
	cpu_hand.clear_cards()
	board_revealed = 0
	
func update_money_labels():
	player_money_label.text = str(player_money)
	cpu_money_label.text = str(cpu_money)
	pot_money_label.text = str(pot_money)

func update_player_slider_max():
	player_raise_slider.max_value = player_money
	player_raise_slider.value = 0
	update_player_label()

func _on_player_raise_slider_value_changed(value: float) -> void:
	update_player_label()
	
func update_player_label() -> void:
	player_raise_label.text = str(int(player_raise_slider.value))

func _on_raise_button_pressed() -> void:
	var raise_value = player_raise_slider.value
	player_money -= raise_value
	pot_money += raise_value
	check_money += raise_value
	update_player_slider_max()
	update_money_labels()
	update_check_money_label()
	
func update_check_money_label() -> void:
	check_money_label.text = "Buy in: " + str(check_money)


func _on_check_button_pressed() -> void:
	if player_money > check_money:
		player_money -= check_money
		pot_money += check_money
		update_player_slider_max()
		update_money_labels()
		update_check_money_label()
