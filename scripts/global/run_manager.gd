# autoload/run_manager.gd
extends Node

var player_deck_data: DeckData = null


func _ready():
	initialize_run()


func initialize_run():
	player_deck_data = DeckData.new()
	player_deck_data.master_cards = DataManager.get_starting_deck().duplicate()
	print("RunManager initialized with deck size: ", player_deck_data.master_cards.size())


func get_player_deck() -> DeckData:
	if not player_deck_data:
		initialize_run()
	return player_deck_data


func add_card(card: CardData):
	if player_deck_data:
		player_deck_data.master_cards.append(card)


func remove_card(card: CardData):
	if player_deck_data:
		player_deck_data.master_cards.erase(card)


func reset_deck():
	player_deck_data = null
	initialize_run()
