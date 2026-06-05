# scripts/passives/denial_logic.gd
class_name DenialLogic

## Вызывается при попытке наложения статуса
## @return bool - true если статус заблокирован
static func try_block_status(passive: PassiveResource, target, status: StatusResource) -> bool:
	if not passive.is_active():
		return false
	
	# Тратим заряд
	if passive.consume_charge():
		# Блокируем наложение статуса
		SignalManager.log_message.emit("DENIAL заблокировал статус!")
		return true
	
	return false
