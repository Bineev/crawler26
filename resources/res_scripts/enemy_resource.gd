# resources/enemies/enemy_resource.gd
extends Resource
class_name EnemyResource

## ID врага (из енама MoleEnemy)
@export var enemy_id: DataManager.MoleEnemy = DataManager.MoleEnemy.MOLE_MUTANT

## ID биома
@export var biome: DataManager.Biome = DataManager.Biome.MOLE_TUNNELS

## Размер врага (weak, normal, elite, boss)
@export var size: DataManager.EnemySize = DataManager.EnemySize.NORMAL

## Ключ локализации для имени
@export var name_key: String = ""

## Ключ локализации для описания
@export var description_key: String = ""

## Базовое здоровье
@export var base_max_health: int = 30

## Базовая сила
@export var base_strength: int = 5

## Стартовые пассивки
@export var starting_passives: Array[PassiveResource] = []


func get_enemy_id() -> int:
	return enemy_id

func get_biome() -> int:
	return biome

func get_size() -> DataManager.EnemySize:
	return size

func get_base_max_health() -> int:
	return base_max_health

func get_base_strength() -> int:
	return base_strength

func get_localized_name() -> String:
	if name_key.is_empty():
		return _get_default_name()
	return tr(name_key)

func get_localized_description() -> String:
	if description_key.is_empty():
		return _get_default_description()
	return tr(description_key)

func _get_default_name() -> String:
	match enemy_id:
		DataManager.MoleEnemy.MOLE_MUTANT:
			return "Mole Mutant"
		DataManager.MoleEnemy.STRONG_MOLE:
			return "Strong Mole"
		DataManager.MoleEnemy.RABID_RAT:
			return "Rabid Rat"
		DataManager.MoleEnemy.MOLE_FUNGUS:
			return "Mole Fungus"
		DataManager.MoleEnemy.MANY_HEADED_MOLE:
			return "Many-Headed Mole"
		DataManager.MoleEnemy.FUNGAL_MINER:
			return "Fungal Miner"
		DataManager.MoleEnemy.RODENT_MOUND:
			return "Rodent Mound"
		_:
			return "Unknown Enemy"

func _get_default_description() -> String:
	match enemy_id:
		DataManager.MoleEnemy.MOLE_MUTANT:
			return "A pathetic blind creature. It regenerates slowly."
		DataManager.MoleEnemy.STRONG_MOLE:
			return "A stout mole with powerful claws. It alternates between attack and defense."
		DataManager.MoleEnemy.RABID_RAT:
			return "A frenzied rat that spreads bleeding wounds."
		DataManager.MoleEnemy.MOLE_FUNGUS:
			return "A mushroom-infested horror. It grows stronger each turn."
		DataManager.MoleEnemy.MANY_HEADED_MOLE:
			return "A three-headed abomination. Its icy touch freezes the ground."
		DataManager.MoleEnemy.FUNGAL_MINER:
			return "A miner consumed by fungus. It digs and poisons."
		DataManager.MoleEnemy.RODENT_MOUND:
			return "A massive pile of writhing rodents. The swarm consumes all."
		_:
			return ""


func get_size_pixels() -> Vector2:
	return DataManager.get_enemy_size_pixels(size)
