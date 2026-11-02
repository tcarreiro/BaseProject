class_name AbilityComponent extends EntityComponent3D

signal ability_learned(definition: AbilityDefinition)
signal ability_unlearned(definition: AbilityDefinition)
signal ability_equipped(ability: Ability, slot_id: StringName)
signal ability_unequipped(slot_id: StringName)
signal cooldown_updated(slot_id: StringName, cooldown_id: StringName, remaining: float, max_value: float, is_global: bool)
signal ability_changed(ability: Ability)

@export var allowed_slots: Array[StringName] = []  # vazio = qualquer slot é aceito
@export var active: bool = true:
	set(_active):
		active = _active

class AbilitySlot extends Resource:
	var ability_id: StringName
	var ability: Ability
	var cooldowns: Dictionary[StringName, Dictionary] = {} # cooldown_id -> {remaining, max, is_global}


var _known_abilities: Dictionary[StringName, AbilityDefinition] = {}
var _equipped_abilities: Dictionary[StringName, AbilitySlot] = {}
var _active_slot_id: StringName = &""


func _is_slot_allowed(slot_id: StringName) -> bool:
	return allowed_slots.is_empty() or slot_id in allowed_slots


func learn_ability(definition: AbilityDefinition) -> void:
	if _known_abilities.has(definition.id):
		return
	_known_abilities[definition.id] = definition
	ability_learned.emit(definition)


func unlearn_ability(ability_id: StringName) -> void:
	if not _known_abilities.has(ability_id):
		return
	var definition = _known_abilities[ability_id]
	_known_abilities.erase(ability_id)
	ability_unlearned.emit(definition)


func _get_all_equipped_ability_ids() -> Array:
	return _equipped_abilities.values().map(func(slot: AbilitySlot): return slot.ability_id)


func _slot_has_ability_equipped(slot_id: StringName) -> bool:
	return _equipped_abilities.has(slot_id) and _equipped_abilities[slot_id] != null


func equip_ability(ability_id: StringName, slot_id: StringName) -> void:
	if not _is_slot_allowed(slot_id):
		return
	if not _known_abilities.has(ability_id):
		return
	if _get_all_equipped_ability_ids().has(ability_id):
		return

	var definition: AbilityDefinition = _known_abilities[ability_id]
	if not definition.ability_scene:
		push_error("AbilityDefinition '%s' has no ability_scene" % ability_id)
		return

	var ability := definition.ability_scene.instantiate() as Ability
	add_child(ability)
	ability.setup(definition, entity)
	ability.cooldown_updated.connect(_on_update_cooldown)
	ability.ability_changed.connect(_on_ability_changed)
	ability.cast_end.connect(_on_ability_cast_end.bind(slot_id))

	var slot := AbilitySlot.new()
	slot.ability_id = ability_id
	slot.ability = ability
	_equipped_abilities[slot_id] = slot

	ability_equipped.emit(ability, slot_id)


func unequip_ability(slot_id: StringName) -> void:
	if not _is_slot_allowed(slot_id):
		return
	if not _slot_has_ability_equipped(slot_id):
		return

	var ability := get_ability_on_slot(slot_id)
	_equipped_abilities[slot_id] = null
	ability_unequipped.emit(slot_id)

	if ability:
		ability.call_deferred("queue_free")


func _on_ability_cast_end(slot_id: StringName) -> void:
	if _active_slot_id == slot_id:
		_active_slot_id = &""


func get_ability_on_slot(slot_id: StringName) -> Ability:
	if not _slot_has_ability_equipped(slot_id):
		return null
	return _equipped_abilities[slot_id].ability


func _on_ability_changed(ability: Ability) -> void:
	ability_changed.emit(ability)


func _on_update_cooldown(ability: Ability, cooldown_id: StringName, remaining: float, max_value: float, is_global: bool) -> void:
	for slot_id in _equipped_abilities.keys():
		var slot: AbilitySlot = _equipped_abilities[slot_id]
		if not slot or slot.ability != ability:
			continue
		slot.cooldowns[cooldown_id] = {"remaining": remaining, "max": max_value, "is_global": is_global}
		cooldown_updated.emit(slot_id, cooldown_id, remaining, max_value, is_global)


func use(slot_id: StringName) -> Ability:
	if not active:
		return null
	if _active_slot_id != &"":
		return null
	var ability := get_ability_on_slot(slot_id)
	if not ability:
		return null
	if not ability.can_activate():
		return null
	if ability.definition.blocks_other_casts:
		_active_slot_id = slot_id
	return ability.handle_press()


func release(slot_id: StringName) -> Ability:
	if not active: return null
	var ability := get_ability_on_slot(slot_id)
	if ability:
		ability.handle_release()
	return ability
