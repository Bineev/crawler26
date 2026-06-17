# scripts/ui/battle_log_ui.gd
extends PanelContainer
class_name BattleLogUI

var margin_container: MarginContainer = null
var scroll_container: ScrollContainer = null
var log_container: VBoxContainer = null

var max_log_entries: int = 50


func _ready():
	margin_container = $MarginContainer
	if margin_container:
		var vbox = margin_container.get_node("VBoxContainer")
		if vbox:
			scroll_container = vbox.get_node("ScrollContainer")
			if scroll_container:
				log_container = scroll_container.get_node("LogContainer")
	
	SignalManager.log_message.connect(_add_log_entry)
	_setup_style()
	_setup_title()


func _setup_style():
	if scroll_container:
		scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO


func _setup_title():
	if not margin_container:
		return
	var vbox = margin_container.get_node("VBoxContainer")
	if not vbox:
		return
	var title_label = vbox.get_node("Label")
	if title_label:
		title_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
		title_label.add_theme_font_size_override("font_size", 32)


func set_biome_style(biome: DataManager.Biome):
	var bg_color = DataManager.COLOR_PENITENT_CARD_BG
	bg_color.a = 0.95
	
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	add_theme_stylebox_override("panel", style)


func _add_log_entry(text: String):
	if text.is_empty():
		return
	
	if not log_container:
		return
	
	var entry = Label.new()
	entry.text = text
	entry.add_theme_color_override("font_color", _get_color_by_text(text))
	entry.autowrap_mode = TextServer.AUTOWRAP_WORD
	entry.add_theme_font_override("font", DataManager.FONT_MAIN)
	entry.add_theme_font_size_override("font_size", 14)
	
	log_container.add_child(entry)
	entry.custom_minimum_size.x = size.x - 30
	
	while log_container.get_child_count() > max_log_entries:
		var oldest = log_container.get_child(0)
		log_container.remove_child(oldest)
		oldest.queue_free()
	
	# Проблема может быть здесь — await на process_frame
	if scroll_container:
		# Убрать await, использовать call_deferred
		scroll_to_bottom()


func _get_color_by_text(text: String) -> Color:
	var lower = text.to_lower()
	
	if "урон" in lower or "damage" in lower or "получил" in lower:
		return DataManager.COLOR_FLESH_CAVES_ART_BG_DARK
	elif "блок" in lower or "block" in lower:
		return DataManager.COLOR_WARRIOR_ART_BG_DARK
	elif "лечит" in lower or "heal" in lower:
		return DataManager.COLOR_ROGUE_ART_BG_LIGHT
	elif "смерть" in lower or "death" in lower or "повержен" in lower:
		return DataManager.COLOR_FLESH_CAVES_ART_BG_DARK
	elif "наложен" in lower or "status" in lower:
		return DataManager.COLOR_MYSTIC_ART_BG_DARK
	else:
		return DataManager.COLOR_BONE_LABYRINTH_ART_BG_DARK


func clear_log():
	if log_container:
		for child in log_container.get_children():
			child.queue_free()


func scroll_to_bottom():
	# Ждем, пока контейнер пересчитает размеры элементов
	await scroll_container.sort_children
	# Скроллим на максимально возможную величину
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
