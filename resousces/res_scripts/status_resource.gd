# resources/statuses/status_resource.gd
extends Resource
class_name StatusResource

@export var id: DataManager.Status
@export var name_key: String = ""
@export var description_key: String = ""
@export var icon: Texture2D

## Тикание
@export var is_ticking: bool = false
@export var tick_interval: int = 1
@export var ignore_block: bool = false
@export var damage_owner: bool = false

## Стаки
@export var is_stacking: bool = false
@export var max_stacks: int = 0
@export var effect_per_stack: float = 0.0      # для Ice (-1% за стак)

## Порог
@export var threshold_stacks: int = 0
@export var threshold_effect: EffectEntry = null

## Постоянные модификаторы (для Weakness, Vulnerability, Shame, Strength)
@export var modifiers: Array[ModifierEntry] = []

## Что делает при тике (для Poison, Bleed, Burn, Regen)
@export var tick_effect: EffectEntry = null
