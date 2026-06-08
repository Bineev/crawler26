# scripts/ui/enemy_ui.gd
extends Control
class_name EnemyUI

## ============================================================
## НОДЫ
## ============================================================

@onready var enemy_sprite: TextureRect = $VBoxContainer/SpriteContainer/EnemySprite
@onready var intents_container: HBoxContainer = $VBoxContainer/IntentsContainer
@onready var health_bar: ProgressBar = $VBoxContainer/HealthBar
@onready var health_label: Label = $VBoxContainer/HealthBar/HealthLabel
@onready var status_container: HBoxContainer = $VBoxContainer/BottomPanel/StatusContainer
@onready var passive_container: HBoxContainer = $VBoxContainer/BottomPanel/PassiveContainer

var enemy_instance: EnemyInstance = null


## ============================================================
## ПУБЛИЧНЫЕ МЕТОДЫ
## ============================================================

func setup(enemy: EnemyInstance):
	enemy_instance = enemy
	update_display()
	
	# Подписываемся на сигналы через SignalManager
	SignalManager.enemy_health_changed.connect(_on_enemy_health_changed)
	SignalManager.enemy_status_changed.connect(_on_enemy_status_changed)


func update_display():
	if not enemy_instance:
		return
	
	# Спрайт
	if enemy_sprite:
		enemy_sprite.texture = enemy_instance.get_sprite()
	
	# Здоровье
	var current_health = enemy_instance.get_health()
	var max_health = enemy_instance.get_max_health()
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	if health_label:
		health_label.text = "%d/%d" % [current_health, max_health]
	
	# Намерения
	update_intents()
	
	# Статусы и пассивки
	update_statuses()
	update_passives()


func update_intents():
	if not intents_container:
		return
	
	for child in intents_container.get_children():
		child.queue_free()
	
	if not enemy_instance or not enemy_instance.current_intent:
		return
	
	for effect in enemy_instance.current_intent.effects:
		var intent_panel = _create_intent_panel(effect)
		if intent_panel:
			intents_container.add_child(intent_panel)


func _create_intent_panel(effect: EffectEntry) -> HBoxContainer:
	var panel = HBoxContainer.new()
	panel.add_constant_override("separation", 5)
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var value_label = Label.new()
	value_label.add_theme_font_size_override("font_size", 16)
	
	match effect.category:
		DataManager.EffectCategory.DAMAGE:
			icon.texture = DataManager.get_intent_icon(DataManager.IntentType.ATTACK)
			value_label.text = str(effect.base_value)
		DataManager.EffectCategory.BLOCK:
			icon.texture = DataManager.get_intent_icon(DataManager.IntentType.DEFEND)
			value_label.text = str(effect.base_value)
		DataManager.EffectCategory.HEAL:
			icon.texture = DataManager.get_intent_icon(DataManager.IntentType.HEAL)
			value_label.text = str(effect.base_value)
		DataManager.EffectCategory.APPLY_STATUS:
			icon.texture = DataManager.get_intent_icon(DataManager.IntentType.DEBUFF)
			if effect.status:
				value_label.text = "%d %s" % [effect.value, effect.status.get_localized_name()]
		DataManager.EffectCategory.APPLY_PASSIVE:
			icon.texture = DataManager.get_intent_icon(DataManager.IntentType.BUFF)
			if effect.passive:
				value_label.text = effect.passive.get_localized_name()
		_:
			icon.texture = DataManager.get_intent_icon(DataManager.IntentType.UNKNOWN)
			value_label.text = "?"
	
	panel.add_child(icon)
	panel.add_child(value_label)
	
	return panel


func update_statuses():
	if not status_container:
		return
	
	for child in status_container.get_children():
		child.queue_free()
	
	if not enemy_instance:
		return
	
	for status_data in enemy_instance.get_active_statuses_for_ui():
		var tooltip = "%s: %d" % [status_data["name"], status_data["stacks"]]
		if status_data.get("duration", 0) > 0:
			tooltip += " (осталось: %d)" % status_data["duration"]
		var icon = _create_icon(status_data["icon"], 32, tooltip)
		status_container.add_child(icon)


func update_passives():
	if not passive_container:
		return
	
	for child in passive_container.get_children():
		child.queue_free()
	
	if not enemy_instance:
		return
	
	for passive_data in enemy_instance.get_active_passives_for_ui():
		var tooltip = "%s\n%s" % [passive_data["name"], passive_data["description"]]
		var icon = _create_icon(passive_data["icon"], 32, tooltip)
		passive_container.add_child(icon)


func _create_icon(texture: Texture2D, size: int, tooltip: String) -> TextureRect:
	var icon = TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(size, size)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.tooltip_text = tooltip
	return icon


## ============================================================
## СИГНАЛЫ
## ============================================================

func _on_enemy_health_changed(enemy: EnemyInstance, new_health: int, max_health: int):
	if enemy != enemy_instance:
		return
	if health_bar:
		health_bar.value = new_health
	if health_label:
		health_label.text = "%d/%d" % [new_health, max_health]


func _on_enemy_status_changed(enemy: EnemyInstance):
	if enemy != enemy_instance:
		return
	update_statuses()


func _exit_tree():
	# Отписываемся от сигналов
	SignalManager.enemy_health_changed.disconnect(_on_enemy_health_changed)
	SignalManager.enemy_status_changed.disconnect(_on_enemy_status_changed)
