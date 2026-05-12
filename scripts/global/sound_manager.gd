extends Node

var sound : AudioStreamPlayer
var music : AudioStreamPlayer
var main_theme1
var main_theme2
var menu_theme : Resource
var main_theme = [main_theme1, main_theme2]
var peaceful_music : Array[Resource]
var martial_music : Array[Resource]

var peaceful_music_index : int
var martial_music_index : int
var played_streams : Array[AudioStreamPlayer]
var is_martial_phase : bool
#const UI_HOVER : AudioStream = preload("res://sound/ui.wav")
#const ARROW = preload("res://sound/arrow.wav")
#const HIT_1 = preload("res://sound/hit1.wav")
#const MAGIC = preload("res://sound/magic.wav")
#const RANGE = preload("res://sound/range.wav")
#const SWORD = preload("res://sound/sword.wav")


func play(source : Node, stream : AudioStream):
	#if sound and sound.playing:
		#sound.stop()
	print(played_streams.size())
	if played_streams.size() > DataManager.max_sounds:
		return
	sound = AudioStreamPlayer.new()
	sound.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sound)
	played_streams.append(sound)
	sound.bus = "SFX"
	sound.stream = stream
	sound.volume_db = -25
	sound.connect("finished", erase_finished_sound.bind(sound))
	#sound.volume_db = -15
	sound.play()


func erase_finished_sound(new_sound : AudioStreamPlayer):
	played_streams.erase(new_sound)
	if sound and is_instance_valid(new_sound):
		sound.queue_free()


func play_local(sound_local : AudioStreamPlayer2D, stream : AudioStream):
	if is_instance_valid(sound_local):
		sound_local.volume_db = -2
		sound_local.stream = stream
		sound_local.play()


func play_ui(source : Node, stream : AudioStream):
	var sound_temp = AudioStreamPlayer.new()
	sound_temp.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sound_temp)
	sound_temp.bus = "SFX"
	sound_temp.stream = stream
	sound_temp.volume_db = -15
	sound_temp.connect("finished", sound_temp.queue_free)
	#sound.volume_db = -15
	sound_temp.stream = stream
	sound_temp.play()


func play_peaceful_music(current_delay : int = 0):
	#if sound and sound.playing:
		#sound.stop()
	if music:
		music.stop()
		music.queue_free()
	music = AudioStreamPlayer.new()
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music)
	music.bus = "Music"
	if peaceful_music_index == peaceful_music.size():
		peaceful_music_index = 0
	music.stream = main_theme[peaceful_music_index]
	peaceful_music_index += 1
	#music.volume_db = -5
	music.play()
	#sound.volume_db = -15
	#get_tree().create_timer(current_delay).timeout.connect(music.play)


func play_martial_music(current_delay : int = 0):
	#if sound and sound.playing:
		#sound.stop()
	if music:
		music.stop()
		music.queue_free()
	music = AudioStreamPlayer.new()
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music)
	music.bus = "Music"
	if martial_music_index == martial_music.size():
		martial_music_index = 0
	music.stream = main_theme[martial_music_index]
	martial_music_index += 1
	#music.volume_db = -5
	music.play()
	#sound.volume_db = -15
	#get_tree().create_timer(current_delay).timeout.connect(music.play)


func fade_out(duration: float):
	# Создаем tween
	var tween = create_tween()
	# Плавное изменение volume_db от текущего до -80 (почти бесшумно)
	tween.tween_property(music, "volume_db", -80.0, duration)
	# После завершения затухания останавливаем звук
	tween.finished.connect(on_fade_finished)


func on_fade_finished():
	if is_martial_phase:
		play_martial_music()
	else:
		play_peaceful_music()


func play_menu_music():
	#if sound and sound.playing:
		#sound.stop()
	if music:
		music.stop()
		music.queue_free()
	music = AudioStreamPlayer.new()
	music.stream = menu_theme
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music)
	music.bus = "Music"
	#music.volume_db = -5
	music.play()
	#sound.volume_db = -15
	#get_tree().create_timer(current_delay).timeout.connect(music.play)
