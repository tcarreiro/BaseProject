class_name DamageOverTimeStatusEffect extends StatusEffect

@export var damage_per_tick: float = 5.0
@export var damage_type: StringName = DamageTypes.MAGICAL

func _on_tick(target: Entity3D, source: Entity3D) -> void:
	var combat_component := target.get_component(CombatComponent) as CombatComponent
	if not combat_component: return

	var attack_data := AttackData.new()
	attack_data.amount = roundi(damage_per_tick)
	attack_data.damage_type = damage_type
	attack_data.source = source
	if aggregate_hud_numbers:
		attack_data.uuid = uuid
	combat_component.receive_hit(attack_data)
