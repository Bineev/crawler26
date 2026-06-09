# scripts/deck/deck_data.gd
extends Resource
class_name DeckData

@export var master_cards: Array[CardData] = []


func create_battle_copy() -> BattleDeck:
	var battle_copy = BattleDeck.new()
	battle_copy.initialize(master_cards.duplicate())
	return battle_copy
