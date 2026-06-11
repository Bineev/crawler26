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
