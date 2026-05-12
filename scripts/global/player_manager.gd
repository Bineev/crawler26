extends Node


@export var gold : int = 100
@export var current_gold : int


func initialize():
	SignalManager.on_spend_gold.connect(spend_gold)
	current_gold = gold


func check_gold(gold_amount : int):
	if current_gold - gold_amount < 0:
		return false
	return true


func spend_gold(gold_amount : int):
	current_gold -= gold_amount


func add_gold(gold_amount : int):
	current_gold += gold_amount
