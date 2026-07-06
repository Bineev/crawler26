# autoload/run_manager.gd
extends Node

var player_deck_data: DeckData = null
var current_character: DataManager.CharacterClass = DataManager.CharacterClass.PENITENT
var poison_damage_per_stack: int = DataManager.POISON_BASE_DAMAGE_PER_STACK
var bleed_damage_per_stack: int = DataManager.BLEED_BASE_DAMAGE_PER_STACK
var burn_damage_per_stack: int = DataManager.BURN_BASE_DAMAGE_PER_STACK
var regen_heal_per_stack: int = DataManager.REGEN_HEAL_PER_STACK

var coins: int = DataManager.STARTING_COINS
var bones: int = DataManager.STARTING_BONES


func _ready():
	initialize_run()


func initialize_run():
	player_deck_data = DeckData.new()
	player_deck_data.master_cards = DataManager.get_starting_deck().duplicate()
	DeckManager._load_cards_data()
	DeckManager._init_unlocked_cards()
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


func modify_poison_damage(modifier: int):
	poison_damage_per_stack += modifier


func modify_bleed_damage(modifier: int):
	bleed_damage_per_stack += modifier


func modify_burn_damage(modifier: int):
	burn_damage_per_stack += modifier


func reset_status_values():
	poison_damage_per_stack = DataManager.POISON_BASE_DAMAGE_PER_STACK
	bleed_damage_per_stack = DataManager.BLEED_BASE_DAMAGE_PER_STACK
	burn_damage_per_stack = DataManager.BURN_BASE_DAMAGE_PER_STACK
	regen_heal_per_stack = DataManager.REGEN_HEAL_PER_STACK


func add_coins(amount: int) -> void:
	coins += amount
	SignalManager.coins_changed.emit(coins)

func add_bones(amount: int) -> void:
	bones += amount
	SignalManager.bones_changed.emit(bones)

func get_coins() -> int:
	return coins

func get_bones() -> int:
	return bones

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		SignalManager.coins_changed.emit(coins)
		return true
	return false

func spend_bones(amount: int) -> bool:
	if bones >= amount:
		bones -= amount
		SignalManager.bones_changed.emit(bones)
		return true
	return false
