# autoload/artifact_manager.gd
extends Node

var unlocked_artifact_ids: Array[DataManager.ArtifactId] = []

func _ready():
	_init_unlocked_artifacts()

func _init_unlocked_artifacts() -> void:
	# TODO: загружать прогресс из сохранения
	# Пока все артефакты открыты
	var all_artifacts = DataManager.get_all_artifact_ids()
	for artifact_id in all_artifacts:
		if artifact_id not in unlocked_artifact_ids:
			unlocked_artifact_ids.append(artifact_id)

func get_random_artifact(grade: DataManager.ArtifactGrade) -> ArtifactResource:
	var pool = _get_available_artifacts_by_grade(grade)
	if pool.is_empty():
		return null
	
	# 🆕 Фильтруем — убираем артефакты, которые уже есть у игрока
	var existing_ids: Array[DataManager.ArtifactId] = []
	for artifact in RunManager.artifacts:
		existing_ids.append(artifact.id)
	
	var filtered: Array[DataManager.ArtifactId] = []
	for artifact_id in pool:
		if artifact_id not in existing_ids:
			filtered.append(artifact_id)
	
	if filtered.is_empty():
		return null
	
	return DataManager.get_artifact_resource(filtered[randi() % filtered.size()])


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

func _get_available_artifacts_by_grade(grade: DataManager.ArtifactGrade) -> Array[DataManager.ArtifactId]:
	var all = DataManager.get_artifacts_by_grade(grade)
	var available: Array[DataManager.ArtifactId] = []
	
	for artifact_id in all:
		if artifact_id in unlocked_artifact_ids:
			available.append(artifact_id)
	
	return available
