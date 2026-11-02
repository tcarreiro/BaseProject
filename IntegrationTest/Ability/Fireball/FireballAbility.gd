# projeto
class_name FireballAbility extends ProjectAbilityExample

@export var projectile_cast_scene: PackedScene
@export var hit_base_damage: float = 10
@export var hit_magic_damage_mult: float = 0.2


func can_use() -> bool:
	return not on_cooldown and ((movement_component and movement_component.on_floor()) or not movement_component)


func handle_press() -> Ability:
	if not can_activate():
		return null
	var target_pos = caster.get_target_position() # TODO: safe guard?
	if not check_valid_target_pos(target_pos):
		return null

	pressed = true
	_disable_movement()
	_start_cast_safety_timeout(definition.cast_end_timeout)
	_request_animation(BlendTreeAnimationComponent.STANDING_CAST, 3.0)
	
	start_channeling.emit()

	spawn_cast(projectile_cast_scene, target_pos)
	caster.look_at_target(target_pos)
	_compute_cooldown()
	return self


func handle_release() -> void:
	pressed = false
