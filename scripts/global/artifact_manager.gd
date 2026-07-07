# autoload/artifact_manager.gd
extends Node

## Массив ID артефактов, которые открыты в мете
var unlocked_artifact_ids: Array[DataManager.ArtifactId] = []

## Словарь артефактов по грейду
var artifacts_by_grade: Dictionary = {}

## Мета-прогресс (0.0 - 1.0)
var meta_progress: float = 0.0

func _ready():
	_load_artifacts_data()
	_init_unlocked_artifacts()

func _load_artifacts_data() -> void:
	# Группируем артефакты по грейду
	for grade in DataManager.ArtifactGrade.values():
		artifacts_by_grade[grade] = DataManager.get_artifacts_by_grade(grade)

func _init_unlocked_artifacts() -> void:
	# TODO: загружать прогресс из сохранения
	# Пока все артефакты открыты
	for grade in artifacts_by_grade.values():
		for artifact_id in grade:
			if artifact_id not in unlocked_artifact_ids:
				unlocked_artifact_ids.append(artifact_id)

## Получить случайный артефакт по грейду
func get_random_artifact(grade: DataManager.ArtifactGrade) -> ArtifactResource:
	var pool = _get_available_artifacts_by_grade(grade)
	if pool.is_empty():
		return null
	return DataManager.get_artifact_resource(pool[randi() % pool.size()])

## Получить несколько случайных артефактов по грейду
func get_random_artifacts(grade: DataManager.ArtifactGrade, amount: int) -> Array[ArtifactResource]:
	var pool = _get_available_artifacts_by_grade(grade)
	var result: Array[ArtifactResource] = []
	
	if pool.is_empty():
		return result
	
	var shuffled = pool.duplicate()
	shuffled.shuffle()
	
	for i in range(min(amount, shuffled.size())):
		var resource = DataManager.get_artifact_resource(shuffled[i])
		if resource:
			result.append(resource)
	
	return result

## Получить доступные артефакты по грейду с учётом прогресса
func _get_available_artifacts_by_grade(grade: DataManager.ArtifactGrade) -> Array[DataManager.ArtifactId]:
	var all = artifacts_by_grade.get(grade, [])
	var available: Array[DataManager.ArtifactId] = []
	
	for artifact_id in all:
		if artifact_id in unlocked_artifact_ids:
			# TODO: добавить фильтрацию по прогрессу, если нужно
			available.append(artifact_id)
	
	return available

## Получить все доступные артефакты
func get_all_available_artifacts() -> Array[ArtifactResource]:
	var result: Array[ArtifactResource] = []
	for artifact_id in unlocked_artifact_ids:
		var resource = DataManager.get_artifact_resource(artifact_id)
		if resource:
			result.append(resource)
	return result

## Проверить, открыт ли артефакт
func is_artifact_unlocked(artifact_id: DataManager.ArtifactId) -> bool:
	return artifact_id in unlocked_artifact_ids

## Открыть артефакт (для мета-прогресса)
func unlock_artifact(artifact_id: DataManager.ArtifactId) -> void:
	if artifact_id not in unlocked_artifact_ids:
		unlocked_artifact_ids.append(artifact_id)
		# TODO: сохранить прогресс
