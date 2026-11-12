# projeto — cena própria, com VFX de explosão etc.
class_name FireballProjectile extends ProjectileCast

#region Placeholder.. utils from project
func find_living_entity(node: Node3D) -> OrchestratorEntityExample:
	var current: Node = node
	while current:
		if current is OrchestratorEntityExample:
			return current
		if current is Node3D:
			current = current.get_parent()
		else:
			return null
	return null


func is_opponent(_caster: Node, target: Node, allow_neutral := false) -> bool:
	var caster_team = get_team(_caster)
	var target_team = get_team(target)
	if allow_neutral and target_team == &"neutral":
		return true
	match caster_team:
		&"player":
			return target_team == &"enemy"
		&"enemy":
			return target_team == &"player"
		&"npc":
			return false
	return false


func get_team(node: Node) -> StringName:
	if node.is_in_group("player"):
		return &"player"
	if node.is_in_group("enemy"):
		return &"enemy"
	if node.is_in_group("npc"):
		return &"npc"
	if node.is_in_group("neutral"):
		return &"neutral"
	return &""

#endregion

func setup(p_ability: Ability, target: Vector3) -> void:
	super.setup(p_ability, target)
	_play_animation("Channeling")


func _on_hit(body: Node3D) -> void:
	var target := find_living_entity(body)
	if not target or not is_opponent(caster, target):
		return
	_collided = true
	_apply_damage(target)
	_play_animation("ExplosionFireball")
	cast_hit.emit(target)


func _cast_projectile() -> void:
	super._cast_projectile()
	_play_animation("Cast")


func end() -> void:
	super.end()
	finished.emit()
	queue_free()


func _apply_damage(target: Entity3D) -> void:
	var fireball = ability as FireballAbility
	var caster_combat := caster.get_component(CombatComponent) as CombatComponent
	var target_combat := target.get_component(CombatComponent) as CombatComponent
	if not target_combat: return

	var magic_power := caster_combat.effective_magic_damage if caster_combat else 0.0
	var attack := AttackData.new()
	attack.amount = roundi(fireball.hit_base_damage + magic_power * fireball.hit_magic_damage_mult)
	attack.damage_type = DamageTypes.MAGICAL
	attack.source = caster
	target_combat.receive_hit(attack)
