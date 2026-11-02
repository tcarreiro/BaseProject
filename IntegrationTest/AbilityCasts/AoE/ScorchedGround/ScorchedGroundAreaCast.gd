class_name ScorchedGroundAreaCast extends PersistentAreaCast

var _ticking: bool = false
@onready var aim_mesh: MeshInstance3D = %AimMesh


func setup(p_ability: Ability, target: Vector3) -> void:
	super.setup(p_ability, target)
	tick_rate = INF  # desativado até enter_cast_phase()


#region Placeholder — utils do projeto
func is_opponent(_caster: Node, target: Node, allow_neutral := false) -> bool:
	var caster_team = get_team(_caster)
	var target_team = get_team(target)
	if allow_neutral and target_team == &"neutral":
		return true
	match caster_team:
		&"player": return target_team == &"enemy"
		&"enemy": return target_team == &"player"
		&"npc": return false
	return false

func get_team(node: Node) -> StringName:
	if node.is_in_group("player"): return &"player"
	if node.is_in_group("enemy"): return &"enemy"
	if node.is_in_group("npc"): return &"npc"
	if node.is_in_group("neutral"): return &"neutral"
	return &""
#endregion


## Chamado pela Ability enquanto o jogador segura a mira.
func enter_aim_phase() -> void:
	_ticking = false
	_play_animation("Aim")


## Chamado pela Ability enquanto em estado de mira
func update_aim(clamped_target: Vector3, ring_progress:float) -> void:
	global_position = clamped_target
	if aim_mesh:
		aim_mesh.get_active_material(0).set_shader_parameter("Ring_Progress", ring_progress)


## Chamado pela Ability quando a o evento "castStart" é disparado — inicia lifetime/tick a partir daqui.
func enter_cast_phase(p_lifetime: float, p_tick_rate: float) -> void:
	lifetime = p_lifetime
	tick_rate = p_tick_rate
	_lifetime_remaining = p_lifetime
	_tick_timer = p_tick_rate
	_ticking = true
	_play_animation("Cast")


## Chamado pela Ability quando a mira é confirmada — inicia lifetime/tick a partir daqui.
func end_aim_phase() -> void:
	_play_animation("Disabled")


func _process(delta: float) -> void:
	if not _ticking:
		return
	super._process(delta)


func _on_tick() -> void:
	var scorched := ability as ScorchedGroundAbility
	if not scorched: return

	var caster_combat := caster.get_component(CombatComponent) as CombatComponent
	if not caster_combat: return
	var magic_power := caster_combat.effective_magic_damage if caster_combat else 0.0

	for target in entities_inside:
		if not is_opponent(caster, target):
			continue
		_apply_burn(target, scorched, magic_power)


func _apply_burn(target: Entity3D, scorched: ScorchedGroundAbility, magic_power: float) -> void:
	var status_component := target.get_component(StatusComponent) as StatusComponent
	if not status_component: return

	var burn := DamageOverTimeStatusEffect.new()
	burn.id = "burn"
	burn.damage_per_tick = scorched.damage_base + scorched.magic_damage_mult * magic_power
	burn.damage_type = DamageTypes.MAGICAL
	burn.duration = scorched.burn_duration
	burn.tick_rate = scorched.burn_tick_rate
	burn.max_stacks = scorched.burn_stacks

	status_component.add_status(burn, caster)
