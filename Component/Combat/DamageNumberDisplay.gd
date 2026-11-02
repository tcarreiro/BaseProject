# framework
class_name DamageNumbersDisplay extends EntityComponent3D

var combat_component: CombatComponent

func setup(p_entity: Entity3D) -> void:
	super(p_entity)
	combat_component = entity.get_component(CombatComponent) as CombatComponent
	if combat_component:
		combat_component.damage_received.connect(_on_damage_received)
		combat_component.heal_received.connect(_on_heal_received)
		combat_component.shielded.connect(_on_shielded)

func _on_damage_received(_damage_result: DamageResultData) -> void:
	pass

func _on_heal_received(_heal_result: HealResultData) -> void:
	pass

func _on_shielded(_amount: int, _cut: bool, _amplified: bool) -> void:
	pass
