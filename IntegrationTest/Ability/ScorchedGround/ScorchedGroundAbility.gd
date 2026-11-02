class_name ScorchedGroundAbility extends ProjectAbilityExample

@export var area_cast_scene: PackedScene

@export var tick_interval: float = 0.5
@export var max_range: float = 15.0
@export var damage_base: float = 2.0
@export var magic_damage_mult: float = 0.35
@export var slow_perc_on_aim: float = 0.4
@export var minimum_aim_time: float = 0.5

@export var burn_duration: float = 3.0
@export var burn_tick_rate: float = 0.5
@export var burn_stacks: int = 1

@export var area_lifetime: float = 3.0

var aiming: bool = false
#var slowed: bool = false
var aiming_time: float = 0.0
var stat_modifier: CombatComponent.StatModifiers
var _current_area: PersistentAreaCast


func setup(p_definition: AbilityDefinition, p_caster: Entity3D) -> void:
	super.setup(p_definition, p_caster)
	stat_modifier = CombatComponent.StatModifiers.new()
	stat_modifier.movement_speed = -slow_perc_on_aim
	cast_start.connect(_cast_aoe)


func can_use() -> bool:
	return not active and not on_cooldown and movement_component and movement_component.on_floor()


func handle_press() -> Ability:
	if not can_activate():
		return null
	pressed = true
	active = true
	aiming = true
	aiming_time = 0.0

	#if combat_component:
		#combat_component.apply_modifier(stat_modifier)
		#slowed = true

	var target_pos := caster.get_target_position()
	if not check_valid_target_pos(target_pos):
		target_pos = caster.global_position

	_request_animation(BlendTreeAnimationComponent.STANDING_AIM)
	_current_area = spawn_cast(area_cast_scene, target_pos) as PersistentAreaCast
	_current_area.enter_aim_phase()
	return self


func handle_release() -> void:
	if not active:
		return

	pressed = false
	aiming = false
	active = false

	#if slowed and combat_component:
		#combat_component.remove_modifier(stat_modifier)
		#slowed = false

	if aiming_time < minimum_aim_time:
		if _current_area:
			_current_area.end()
			_current_area = null
			cancel_cast()
		return 

	_disable_movement()
	_start_cast_safety_timeout(definition.cast_end_timeout)
	_request_animation(BlendTreeAnimationComponent.STANDING_CAST, 2.0)
	if _current_area:
		_current_area.end_aim_phase()
	_compute_cooldown()


func _cast_aoe() -> void:
	if _current_area:
		_current_area.enter_cast_phase(area_lifetime, tick_interval)
		_current_area = null  # a área agora vive por conta própria


func _process(delta: float) -> void:
	super._process(delta)
	if aiming: 
		_update_aim(delta)


func _update_aim(delta: float) -> void:
	aiming_time += delta

	var target_pos := caster.get_target_position()
	if not check_valid_target_pos(target_pos): return

	var direction := caster.global_position.direction_to(target_pos)
	var distance := caster.global_position.distance_to(target_pos)
	var clamped_target := caster.global_position + direction * minf(distance, max_range)

	caster.look_at_target(clamped_target)

	if _current_area:
		clamped_target.y = target_pos.y + 0.01
		var ring_progress := 1.0
		if minimum_aim_time > 0.0:
			ring_progress = clampf(aiming_time / minimum_aim_time, 0.0, 1.0)
		_current_area.update_aim(clamped_target, ring_progress)
		
