# resources/enemies/enemy_resource.gd
extends Resource
class_name EnemyResource

## ID врага (из енама MoleEnemy или другого биома)
@export var enemy_id: DataManager.MoleEnemy = DataManager.MoleEnemy.MOLE_MUTANT

## ID биома (из енама Biome)
@export var biome: DataManager.Biome = DataManager.Biome.MOLE_TUNNELS

## Базовое здоровье (будет умножено на скейлинг)
@export var base_max_health: int = 30

## Базовая сила (будет умножена на скейлинг)
@export var base_strength: int = 5

## Стартовые пассивки (копируются при инициализации врага)
@export var starting_passives: Array[PassiveResource] = []


func get_enemy_id() -> int:
	return enemy_id


func get_biome() -> int:
	return biome


func get_base_max_health() -> int:
	return base_max_health


func get_base_strength() -> int:
	return base_strength
