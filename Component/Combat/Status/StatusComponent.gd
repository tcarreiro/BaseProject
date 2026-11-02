class_name StatusComponent extends EntityComponent3D

signal status_applied(status: StatusEffect, source: Entity3D)
signal status_removed(status: StatusEffect)

class ActiveStatus:
	var effect: StatusEffect
	var stacks: int = 0
	var remaining: float = 0.0
	var tick_timer: float = 0.0
	var source: Entity3D = null  # quem aplicou; null = natureza/ambiental
	
	func _init(_effect: StatusEffect, _stacks: int, _remaining: float, _source: Entity3D, _instant_tick: bool = true) -> void:
		self.effect = _effect
		self.stacks = _stacks
		self.remaining = _remaining
		self.source = _source
		self.tick_timer = 0.0 if _instant_tick else effect.tick_rate  # Immediate first tick

var _active_statuses: Dictionary[String, ActiveStatus] = {} # statusId -> ActiveStatus

func _process(delta: float) -> void:
	for id in _active_statuses.keys():
		var entry: ActiveStatus = _active_statuses[id]
		entry.remaining -= delta

		if entry.effect.tick_rate > 0.0:
			entry.tick_timer -= delta
			if entry.tick_timer <= 0:
				entry.tick_timer = entry.effect.tick_rate
				entry.effect._on_tick(entity, entry.source)

		if entry.remaining <= 0.0:
			remove_status(id)


func add_status(effect: StatusEffect, source: Entity3D, stacks: int = 1) -> void:
	if _should_block_crowd_control(effect) or _should_block_disabling(effect):
		return

	if has_status(effect.id):
		var entry = _active_statuses[effect.id]
		entry.stacks = min(entry.stacks + stacks, effect.max_stacks)
		entry.remaining = effect.duration
		entry.source = source
	else:
		_active_statuses[effect.id] = ActiveStatus.new(effect, stacks, effect.duration, source, effect.instant_tick)
		effect._on_apply(entity, source)

	status_applied.emit(effect, source)


func has_status(id: String) -> bool:
	return _active_statuses.has(id)


func has_any_disabling() -> bool:
	for entry: ActiveStatus in _active_statuses.values():
		if entry.effect.is_disabling:
			return true
	return false


func has_any_crowd_control() -> bool:
	for entry: ActiveStatus in _active_statuses.values():
		if entry.effect.is_crowd_control:
			return true
	return false


func clear_all() -> void:
	for id in _active_statuses.keys():
		remove_status(id)


func remove_status(id: String, source: Entity3D = null) -> void:
	if not has_status(id): return
	var entry: ActiveStatus = _active_statuses[id]
	entry.effect._on_remove(entity, source)
	_active_statuses.erase(id)
	status_removed.emit(entry.effect)


func _should_block_crowd_control(new_effect: StatusEffect) -> bool:
	if not new_effect.is_crowd_control: return false
	for entry: ActiveStatus in _active_statuses.values():
		if entry.effect.blocks_crowd_control:
			return true
	return false


func _should_block_disabling(new_effect: StatusEffect) -> bool:
	if not new_effect.is_disabling: return false
	for entry: ActiveStatus in _active_statuses.values():
		if entry.effect.blocks_disabling:
			return true
	return false


func _should_block_damage_of_type(damage_type: StringName) -> bool:
	for entry: ActiveStatus in _active_statuses.values():
		var block = entry.effect.blocks_damage_of_type
		if block.has(damage_type):
			return true
	return false
