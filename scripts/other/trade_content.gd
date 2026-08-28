extends VBoxContainer
class_name TradeContent

var shop_items: Array[Dictionary] = []
var is_processing: bool = false
const ARTIFACT_ICON_SCENE = preload("res://scenes/artifact_icon.tscn")

@onready var cards_container: HBoxContainer = $CardsContainer
@onready var artifacts_container: HBoxContainer = $ArtifactsContainer
@onready var potions_container: HBoxContainer = $PotionsContainer


func setup(items: Array[Dictionary]) -> void:
	shop_items = items
	
	for item in items:
		match item["type"]:
			"card":
				_add_card_item(item)
			"artifact":
				_add_artifact_item(item)
			"key":  # 🆕
				_add_key_item(item)
			"potion":
				_add_potion_item(item)
	
	_update_buttons()
	SignalManager.coins_changed.connect(_on_coins_changed)
	await get_tree().create_timer(0.2).timeout
	cards_container.custom_minimum_size = cards_container.size
	artifacts_container.custom_minimum_size = artifacts_container.size
	potions_container.custom_minimum_size = potions_container.size


func _add_card_item(item: Dictionary) -> void:
	var container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 10)
	
	var card_ui = load("res://scenes/card.tscn").instantiate() as CardUI
	card_ui.card_data = item["data"]
	var card_container = Container.new()
	card_container.add_child(card_ui)
	container.add_child(card_container)
	cards_container.add_child(container)
	
	card_ui.display()
	card_ui.card_control.scale = Vector2(0.7, 0.7)
	card_ui.set_reward_state()
	card_container.custom_minimum_size = card_ui.get_actual_size() * 1.2

	var coin_icon = DataManager.get_currency_icon(DataManager.CurrencyType.COIN)
	var price = _get_price(item)
	var buy_button = DataManager.create_button(str(price), DataManager.ButtonType.PRIMARY, coin_icon)
	buy_button.add_theme_constant_override("icon_max_width", 32)
	buy_button.pressed.connect(_on_buy_pressed.bind(item, container))
	buy_button.set_meta("price", price)
	container.add_child(buy_button)
	buy_button.focus_mode = Control.FOCUS_NONE


func _add_artifact_item(item: Dictionary) -> void:
	var container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 5)
	
	var artifact_icon = load("res://scenes/artifact_icon.tscn").instantiate() as ArtifactIcon
	container.add_child(artifact_icon)
	artifacts_container.add_child(container)
	
	artifact_icon.setup(item["data"], true)
	
	var coin_icon = DataManager.get_currency_icon(DataManager.CurrencyType.COIN)
	var price = _get_price(item)
	var buy_button = DataManager.create_button(str(price), DataManager.ButtonType.PRIMARY, coin_icon)
	buy_button.pressed.connect(_on_buy_pressed.bind(item, container))
	buy_button.set_meta("price", price)
	container.add_child(buy_button)
	buy_button.focus_mode = Control.FOCUS_NONE


func _add_key_item(item: Dictionary) -> void:
	var container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 5)
	container.custom_minimum_size = Vector2(128, 128)
	
	# 🆕 Иконка ключа
	var key_icon = TextureRect.new()
	key_icon.texture = preload("res://img/icons/currency/keys1.png")  # TODO: добавить иконку ключа
	key_icon.custom_minimum_size = Vector2(96, 96)
	key_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	key_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	container.add_child(key_icon)
	
	artifacts_container.add_child(container)
	
	var coin_icon = DataManager.get_currency_icon(DataManager.CurrencyType.COIN)
	var price = _get_price(item)
	var buy_button = DataManager.create_button(str(price), DataManager.ButtonType.PRIMARY, coin_icon)
	buy_button.pressed.connect(_on_buy_pressed.bind(item, container))
	buy_button.set_meta("price", price)
	container.add_child(buy_button)
	buy_button.focus_mode = Control.FOCUS_NONE


func _add_potion_item(item: Dictionary) -> void:
	var container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 10)
	
	var potion_icon = load("res://scenes/potion_icon.tscn").instantiate() as PotionIcon
	container.add_child(potion_icon)
	potions_container.add_child(container)
	
	potion_icon.setup(item["data"])
	potion_icon.set_interactable(false)
	
	var coin_icon = DataManager.get_currency_icon(DataManager.CurrencyType.COIN)
	var price = _get_price(item)
	var buy_button = DataManager.create_button(str(price), DataManager.ButtonType.PRIMARY, coin_icon)
	buy_button.pressed.connect(_on_buy_pressed.bind(item, container))
	buy_button.set_meta("price", price)
	container.add_child(buy_button)
	buy_button.focus_mode = Control.FOCUS_NONE


func _get_price(item: Dictionary) -> int:
	# 🆕 Для ключей своя цена
	if item["type"] == "key":
		return RunManager.default_item_cost * 2  # цена как NORMAL
	
	var data = item["data"]
	var grade = DataManager.CostGrade.NORMAL
	
	if data.has_method("get_cost_grade"):
		grade = data.get_cost_grade()
	
	var base_price = int(grade) * RunManager.default_item_cost
	var variance = randf_range(0.7, 1.3)
	var final_price = floor(base_price * variance)
	
	return max(1, final_price)


func _update_buttons() -> void:
	var coins = RunManager.get_coins()
	
	for container in [cards_container, artifacts_container, potions_container]:
		for vbox in container.get_children():
			var button = vbox.get_child(-1)
			if button is Button:
				var price = button.get_meta("price", 0)
				button.disabled = coins < price


func _on_coins_changed(amount: int) -> void:
	_update_buttons()


func _on_buy_pressed(item: Dictionary, container: Control) -> void:
	if is_processing:
		return
	is_processing = true
	
	var price = _get_price(item)
	
	if RunManager.get_coins() < price:
		SignalManager.log_message.emit(tr("shop_not_enough_gold"))
		is_processing = false
		return
	
	RunManager.spend_coins(price)
	
	match item["type"]:
		"card":
			RunManager.add_card(item["data"])
			#SignalManager.log_message.emit(tr("shop_bought_card") % item["data"].get_localized_name())
		"artifact":
			RunManager.add_artifact(item["data"])
			#SignalManager.log_message.emit(tr("shop_bought_artifact") % item["data"].get_localized_name())
		"key":  # 🆕
			RunManager.add_keys(1)
			#SignalManager.log_message.emit(tr("shop_bought_key"))
		"potion":
			RunManager.add_potion(item["data"])
			#SignalManager.log_message.emit(tr("shop_bought_potion") % item["data"].get_localized_name())
	
	container.queue_free()
	is_processing = false
