class_name AttackData extends Resource

@export var uuid := UUID.new_uuid()
@export var amount: int = 0
@export var damage_type: StringName = DamageTypes.PHYSICAL
@export var knockback_direction: Vector3 = Vector3.ZERO
@export var knockback_strength: float = 0.0
@export var shield_damage_multiplier: float = 0.0
@export var status_effects: Array[StatusEffect] = []
var source: Entity3D = null
