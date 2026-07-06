# autoload/signal_manager.gd
extends Node

## ============================================================
## ХАРАКТЕРИСТИКИ (CharacterStats)
## ============================================================

signal health_changed(current: int, max: int)
signal max_health_changed(max: int)
signal energy_changed(current: int, max: int)
signal block_changed(current: int)

## ============================================================
## СТАТУСЫ И ПАССИВКИ
## ============================================================

signal status_added(target: Node, status_id: int, stacks: int, duration: int)
signal status_removed(target: Node, status_id: int)
signal status_ticked(target: Node, status_id: int, damage: int)
signal passive_added(target: Node, passive_id: int)
signal passive_removed(target: Node, passive_id: int)

## ============================================================
## СПЕЦИФИЧЕСКИЕ ДЛЯ ПЕРСОНАЖЕЙ
## ============================================================

signal atonement_changed(current: int, max: int)  # PenitentStats

## ============================================================
## ВРАГИ (EnemyInstance)
## ============================================================

signal enemy_health_changed(enemy: EnemyInstance, current: int, max: int)
signal enemy_status_changed(enemy: EnemyInstance)
signal enemy_died(enemy: EnemyInstance)
signal player_died(player: CharacterStats)

## ============================================================
## БОЙ (BattleManager)
## ============================================================

signal battle_started()
signal battle_victory()
signal battle_defeat()
signal player_turn_started()
signal enemy_turn_started()
signal turn_started()
signal turn_ended()

## ============================================================
## НАМЕРЕНИЯ ВРАГОВ
## ============================================================

signal enemy_intent_changed(enemy: Node, intent: IntentEntry)

## ============================================================
## КАРТЫ
## ============================================================

signal card_played(card_data: Resource)
signal card_drawn(card_data: Resource)
signal card_discarded(card_data: Resource)
signal hand_updated(hand: Array)

## ============================================================
## UI
## ============================================================

signal log_message(text: String)
signal deck_size_changed(size: int)
signal discard_size_changed(size: int)
signal hand_ui_created(hand_ui: HandUI)  # рука создана

signal target_selection_requested(card_ui: CardUI)
signal target_selected(target: Node)
signal target_selection_cancelled()

signal enemy_clicked(enemy: EnemyInstance)

signal get_hit(target: Node)

signal enemy_highlight_requested(enemy: EnemyInstance, enabled: bool)
# Выбор цели (HandUI)
signal selecting_target_changed(is_selecting: bool)

signal damage_dealt(target: Node, amount: int)
signal heal_received(target: Node, amount: int)

signal next_room()
signal show_paths(paths: Array)

signal choice_panel_selected(path_index: int)

signal player_took_damage(damage: int)

signal player_damage_dealt(damage: int)
signal player_heal_received(heal: int)

signal card_burned(card_data: CardData)

signal frozen_applied(target: Node)

signal player_death_animation_finished()

signal passive_changed(target: Node, passive_id: int)

signal player_status_changed(target : Node)

signal show_reward(reward_panel: Control)

signal getting_all_rewards()

signal add_card_to_deck(card: CardData)
signal add_gold(amount: int)
signal heal_player(amount: int)
signal damage_player(amount: int)
signal reward_selected()
signal add_artifact(artifact)
signal add_potion(potion)
signal energy_buff(amount: int)
signal deck_size_buff(amount: int)
signal remove_card(card: CardData)
signal upgrade_card(card: CardData)
signal add_property_to_card(card: CardData)

signal coins_changed(amount: int)
signal bones_changed(amount: int)
