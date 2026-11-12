class_name CombatComponent extends EntityComponent3D

const MINIMUM_ATTACK_SPEED: float = 0.1
const MINIMUM_MOVEMENT_SPEED_MULTIPLIER: float = 0.05
const MINIMUM_ABILITY_HASTE: float = -20

class StatModifiers extends Resource:
	var uuid := UUID.new_uuid()
	var max_hp: float = 0.0
	var armor: float = 0.0
	var magic_resist: float = 0.0
	var physical_damage: float = 0.0
	var magic_damage: float = 0.0
	var attack_range: float = 0.0
	var attack_speed: float = 0.0
	var movement_speed: float = 0.0
	var ability_haste: float = 0.0
	var heal_power: float = 0.0
	var shield_power: float = 0.0

signal died()
signal damage_denied(attack_data: AttackData)
signal damage_received(damage_data: DamageResultData)
signal heal_received(heal_result: HealResultData)
signal shielded(amount: int, shield_cut: bool, shield_amplified: bool)

@export var base_max_hp: float = 100.0
@export var base_armor: float = 0.0
@export var base_magic_resist: float = 0.0
@export var base_physical_damage: float = 10.0
@export var base_magic_damage: float = 0.0
@export var base_attack_range: float = 1.5
@export var base_attack_speed: float = 1.0
@export var base_movement_speed: float = 1.0
@export var base_ability_haste: float = 0.0
@export var base_heal_power: float = 0.0
@export var base_shield_power: float = 0.0

var _dead: bool = false   # junto de current_hp

var effective_max_hp: float:
	get: return maxf(base_max_hp + modifiers.max_hp, 1.0)
var effective_armor: float:
	get: return maxf(base_armor + modifiers.armor, -99.0)
var effective_magic_resist: float:
	get: return maxf(base_magic_resist + modifiers.magic_resist, -99.0)
var effective_physical_damage: float:
	get: return base_physical_damage + modifiers.physical_damage
var effective_magic_damage: float:
	get: return base_magic_damage + modifiers.magic_damage
var effective_attack_range: float:
	get: return base_attack_range + modifiers.attack_range
var effective_attack_speed: float:
	get: return maxf(base_attack_speed + modifiers.attack_speed, MINIMUM_ATTACK_SPEED)
var effective_movement_speed: float:
	get: return maxf(base_movement_speed + modifiers.movement_speed, MINIMUM_MOVEMENT_SPEED_MULTIPLIER)
var effective_ability_haste: float:
	get: return maxf(base_ability_haste + modifiers.ability_haste, MINIMUM_ABILITY_HASTE)
var effective_heal_power: float:
	get: return maxf(base_heal_power + modifiers.heal_power, 0.0)
var effective_shield_power: float:
	get: return maxf(base_shield_power + modifiers.shield_power, 0.0)

var current_hp: float
var shields: Dictionary[StringName, int] = {}
var shield_priority: Dictionary[StringName, Array] = {}

var modifiers: StatModifiers = StatModifiers.new()
var active_modifiers: Dictionary[UUID, StatModifiers] = {}

var status_component: StatusComponent


func setup(p_entity: Entity3D) -> void:
	super(p_entity)
	current_hp = effective_max_hp
	status_component = entity.get_component(StatusComponent) as StatusComponent

	var movement := entity.get_component(MovementComponent) as MovementComponent
	if movement:
		movement.hard_landing.connect(_on_hard_landing)


func receive_hit(attack_data: AttackData) -> void:
	take_damage(attack_data)
	if attack_data.knockback_strength > 0:
		entity.velocity += attack_data.knockback_direction * attack_data.knockback_strength
	if status_component:
		for effect in attack_data.status_effects:
			status_component.add_status(effect, attack_data.source)


func _on_hard_landing(impact_velocity: float) -> void:
	var attack_data := AttackData.new()
	attack_data.amount = roundi(abs(impact_velocity) / 2.0)
	attack_data.source = null
	receive_hit(attack_data)


func compute_shield_block(attack_data: AttackData) -> int:
	var residual_damage: int = attack_data.amount
	var damage_before_shield: int = residual_damage
	var priority: Array = shield_priority.get(attack_data.damage_type, [])
	for shield_type in priority:
		var shield_amount: int = shields.get(shield_type, 0)
		if shield_amount > 0:
			var damage_on_shield: int = roundi(residual_damage * (1.0 + attack_data.shield_damage_multiplier))
			if damage_on_shield <= shield_amount:
				shields[shield_type] -= damage_on_shield
				residual_damage = 0
			else:
				residual_damage -= roundi((damage_on_shield - shield_amount) / (1.0 + attack_data.shield_damage_multiplier))
				shields[shield_type] = 0
	var shield_block: int = damage_before_shield - residual_damage
	return shield_block


func compute_damage_mitigation(attack_data: AttackData, incoming_damage: int) -> int:
	var reduction_multiplier := 1.0
	match attack_data.damage_type:
		&"physical":
			reduction_multiplier = (100.0 / (100.0 + effective_armor))
		&"magical":
			reduction_multiplier = (100.0 / (100.0 + effective_magic_resist))
	var effective_damage: int = roundi(incoming_damage * reduction_multiplier)
	return incoming_damage - effective_damage


func take_damage(attack_data: AttackData) -> int:
	if status_component and status_component._should_block_damage_of_type(attack_data.damage_type):
		damage_denied.emit(attack_data)
		return 0

	var shield_block: int = compute_shield_block(attack_data)
	var residual_damage: int = attack_data.amount - shield_block
	if residual_damage <= 0:
		return 0

	var mitigated_damage = compute_damage_mitigation(attack_data, residual_damage)
	residual_damage -= mitigated_damage
	current_hp = max(current_hp - residual_damage, 0.0)

	var damage_data = DamageResultData.new(residual_damage, attack_data.damage_type, mitigated_damage, shield_block)
	damage_received.emit(damage_data)

	if current_hp <= 0.0 and not _dead:
		_dead = true
		died.emit()

	return residual_damage


func ressurrect() -> void:
	if _dead:
		_dead = false


func heal(heal_data: HealData) -> void:
	var before := current_hp
	var power := effective_heal_power  # 1.0 = neutro, <1.0 = cortada, >1.0 = amplificada
	var effective_healing: int = roundi(heal_data.amount * power)
	current_hp = min(current_hp + effective_healing, effective_max_hp)
	var applied_amount: int = roundi(current_hp - before)
	var overheal: int = effective_healing - applied_amount

	var result := HealResultData.new(
		applied_amount,
		heal_data.amount,
		overheal,
		power < 1.0,
		power > 1.0
	)
	heal_received.emit(result)


func apply_modifier(mod: StatModifiers) -> void:
	active_modifiers[mod.uuid] = mod
	modifiers = _compute_modifiers()


func remove_modifier(mod: StatModifiers) -> void:
	active_modifiers.erase(mod.uuid)
	modifiers = _compute_modifiers()


func _compute_modifiers() -> StatModifiers:
	var modifier := StatModifiers.new()
	for mod in active_modifiers.values():
		modifier.max_hp += mod.max_hp
		modifier.attack_range += mod.attack_range
		modifier.attack_speed += mod.attack_speed
		modifier.movement_speed += mod.movement_speed
		modifier.ability_haste += mod.ability_haste
		modifier.armor += mod.armor
		modifier.magic_resist += mod.magic_resist
		modifier.physical_damage += mod.physical_damage
		modifier.magic_damage += mod.magic_damage
		modifier.movement_speed += maxf(mod.movement_speed, 0.0)
		modifier.heal_power += mod.heal_power
		modifier.shield_power += mod.shield_power
	return modifier


func add_shield(shield_type: StringName, amount: int) -> void:
	var power := effective_shield_power
	var effective_shield: int = roundi(amount * power)
	shields[shield_type] = shields.get(shield_type, 0) + effective_shield
	shielded.emit(effective_shield, power < 1.0, power > 1.0)
