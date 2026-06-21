# scripts/ui/energy_display.gd
extends Label
class_name EnergyDisplay

func _ready():
	_setup_style()
	
	SignalManager.energy_changed.connect(_on_energy_changed)
	SignalManager.player_turn_started.connect(_on_player_turn_started)
	SignalManager.enemy_turn_started.connect(_on_enemy_turn_started)
	SignalManager.battle_victory.connect(_on_battle_ended)
	SignalManager.battle_defeat.connect(_on_battle_ended)
	
	var player = BattleManager.get_player()
	if player:
		_update_energy(player.get_energy(), player.get_max_energy())


func _setup_style():
	add_theme_font_override("font", DataManager.FONT_HEADERS)
	add_theme_font_size_override("font_size", 40)
	add_theme_color_override("font_color", DataManager.COLOR_FLESH_CAVES_ART_BG_DARK)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	custom_minimum_size = Vector2(100, 40)


func _update_energy(current: int, max_energy: int):
	text = "⚡ %d/%d" % [current, max_energy]


func _on_energy_changed(current: int, max_energy: int):
	_update_energy(current, max_energy)


func _on_player_turn_started():
	visible = true


func _on_enemy_turn_started():
	visible = false


func _on_battle_ended():
	visible = false
