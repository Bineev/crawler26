extends Node

var music_player : AudioStreamPlayer

# Заполняйте эти массивы в инспекторе Godot (mp3/wav)
@export var gameplay_playlist : Array[AudioStream] = [
	preload("res://audio/music/Crawler - No Hope.ogg"),
	preload("res://audio/music/Crawler - Death is near.ogg"),
	preload("res://audio/music/Crawler - Dark Cave.ogg"),
	preload("res://audio/music/Crawler - Explore.ogg"),
	preload("res://audio/music/Crawler - Cultist Lair.ogg"),
]
@export var menu_theme : AudioStream = preload("res://audio/music/Crawler - Main Menu.ogg")

var played_streams : Array[AudioStreamPlayer] = []
var remaining_tracks : Array[AudioStream] = []
var is_in_gameplay : bool = false

# Словарь для отслеживания времени последнего запуска конкретных аудиоресурсов
var sound_cooldowns: Dictionary = {}


# --- СЕКЦИЯ МУЗЫКИ (ЖЕЛЕЗОБЕТОННЫЙ ВАРИАНТ НА ТАЙМЕРЕ) ---

# Добавим внутренний таймер для контроля очереди треков
var music_timer : SceneTreeTimer

func play_menu_music():
	is_in_gameplay = false
	_stop_music_player()
	
	if not menu_theme:
		print("Внимание: Забыли назначить menu_theme в инспекторе!")
		return
		
	music_player = AudioStreamPlayer.new()
	music_player.stream = menu_theme
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.bus = "Music"
	music_player.volume_db = -15
	
	# Для меню можно оставить зацикливание через сигнал, тут оно обычно не дает сбоев
	music_player.connect("finished", music_player.play)
	
	add_child(music_player)
	music_player.play()


func start_gameplay_playlist(fade_duration: float = 1.0):
	is_in_gameplay = true
	
	if is_instance_valid(music_player) and music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, fade_duration)
		tween.finished.connect(func():
			_stop_music_player()
			_play_next_random_track()
		)
	else:
		_play_next_random_track()


func _play_next_random_track():
	if not is_in_gameplay: return
	
	if gameplay_playlist.is_empty():
		print("Внимание: Плейлист геймплея пуст!")
		return
		
	if remaining_tracks.is_empty():
		remaining_tracks = gameplay_playlist.duplicate()
		remaining_tracks.shuffle()
		
	var next_track = remaining_tracks.pop_front()
	
	_stop_music_player()
	
	music_player = AudioStreamPlayer.new()
	music_player.stream = next_track
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.bus = "Music"
	music_player.volume_db = -15
	
	add_child(music_player)
	music_player.play()
	
	# Узнаем точную длину трека в секундах
	var track_length = next_track.get_length()
	
	# Создаем безопасный таймер. Когда трек физически кончится, 
	# автоматически запустится следующий, даже если сигнал "finished" завис.
	music_timer = get_tree().create_timer(track_length, false) # false — не ставится на паузу
	music_timer.timeout.connect(func():
		if is_in_gameplay and is_instance_valid(music_player) and music_player.stream == next_track:
			_play_next_random_track()
	)


func _stop_music_player():
	# Если мы принудительно меняем трек, сбрасываем старый таймер, чтобы они не накладывались
	music_timer = null 
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.queue_free()



func play(source : Node, stream : AudioStream):
	if not stream:
		return

	# 1. ЗАЩИТА ОТ СТАКАНЬЯ ОДИНАКОВЫХ ЗВУКОВ (Звуковой кулдаун)
	var current_time = Time.get_ticks_msec()
	var stream_id = stream.get_instance_id()
	
	if sound_cooldowns.has(stream_id):
		if current_time - sound_cooldowns[stream_id] < DataManager.sound_delay:
			return # Игнорируем дубликат
			
	sound_cooldowns[stream_id] = current_time

	# 2. Контроль общей звуковой каши
	if played_streams.size() >= DataManager.max_sounds:
		var oldest = played_streams.pop_front()
		if is_instance_valid(oldest): 
			oldest.queue_free()
		
	var sound = AudioStreamPlayer.new()
	sound.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sound)
	played_streams.append(sound)
	
	sound.bus = "SFX"
	sound.stream = stream
	sound.volume_db = -20
	
	# 3. Рандомизация Pitch (убирает резонанс)
	sound.pitch_scale = randf_range(0.92, 1.08)
	
	sound.connect("finished", erase_finished_sound.bind(sound))
	sound.play()


func _ready():
	# Автоматически очищаем кэш кулдаунов раз в 30 секунд, чтобы память не засорялась
	var timer = Timer.new()
	timer.wait_time = 30.0
	timer.autostart = true
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	timer.timeout.connect(func(): sound_cooldowns.clear())
	add_child(timer)
	
	play_menu_music()



func erase_finished_sound(sound_to_erase : AudioStreamPlayer):
	played_streams.erase(sound_to_erase)
	if is_instance_valid(sound_to_erase):
		sound_to_erase.queue_free()


func play_local(sound_local : AudioStreamPlayer2D, stream : AudioStream):
	if is_instance_valid(sound_local):
		sound_local.volume_db = -2
		sound_local.stream = stream
		sound_local.play()


func play_ui(source : Node, stream : AudioStream):
	if not stream: return
	var sound_temp = AudioStreamPlayer.new()
	sound_temp.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sound_temp)
	sound_temp.bus = "SFX"
	sound_temp.stream = stream
	sound_temp.volume_db = -10
	sound_temp.connect("finished", sound_temp.queue_free)
	sound_temp.play()
