# autoload/signal_manager.gd
extends Node

## Сигналы CharacterStats
signal health_changed(current: int, max: int)
signal max_health_changed(max: int)
signal energy_changed(current: int, max: int)
signal block_changed(current: int)
signal status_added(status_id: int, stacks: int, duration: int)
signal status_removed(status_id: int)
signal passive_added(passive_id: int)
signal passive_removed(passive_id: int)

## Сигналы PenitentStats
signal atonement_changed(current: int, max: int)

## Сигналы игровых событий
signal turn_started()
signal turn_ended()
signal card_played(card_data: Resource)
