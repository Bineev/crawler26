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

signal status_added(status_id: int, stacks: int, duration: int)
signal status_removed(status_id: int)
signal passive_added(passive_id: int)
signal passive_removed(passive_id: int)

## ============================================================
## СПЕЦИФИЧЕСКИЕ ДЛЯ ПЕРСОНАЖЕЙ
## ============================================================

signal atonement_changed(current: int, max: int)  # PenitentStats

## ============================================================
## БОЙ (BattleManager)
## ============================================================

signal battle_started()
signal battle_victory()
signal battle_defeat()
signal player_turn_started()
signal enemy_turn_started()
signal turn_started()      # общий сигнал (может быть deprecated)
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
