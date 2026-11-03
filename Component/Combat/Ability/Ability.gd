class_name Ability extends Node3D

signal start_channeling()
signal cast_start()
signal cast_end()
signal ability_ready(ability: Ability)
signal animation_requested(node_name: StringName, time_scale: float)
signal ability_changed(ability: Ability)

## cooldown_id identifica QUAL timer mudou (ex: &"default", &"recast_window", &"buff_duration").
## is_global indica se esse timer bloqueia can_use() e deve refletir no ícone principal da HUD;
## timers com is_global = false são só informativos (barras extras, janelas de recast, etc).
signal cooldown_started(cooldown_id: StringName, duration: float, is_global: bool)
signal cooldown_updated(ability: Ability, cooldown_id: StringName, remaining: float, max_value: float, is_global: bool)
signal timer_expired(cooldown_id: StringName)

const DEFAULT_COOLDOWN_ID := &"default"
const CAST_SAFETY_TIMER_ID := &"cast_safety"

class TimerState:
	var remaining: float = 0.0
	var max_value: float = 0.0
	var is_global: bool = false


var definition: AbilityDefinition
var caster: Entity3D
var combat_component: CombatComponent
var movement_component: MovementComponent
var animation_component: AnimationComponent

var pressed: bool = false
var active: bool = false
var on_cooldown: bool = false
var current_animation_request: StringName = &""

var _timers: Dictionary[StringName, TimerState] = {}


func setup(p_definition: AbilityDefinition, p_caster: Entity3D) -> void:
	definition = p_definition
	caster = p_caster
	combat_component = caster.get_component(CombatComponent) as CombatComponent
	movement_component = caster.get_component(MovementComponent) as MovementComponent
	animation_component = caster.get_component(AnimationComponent) as AnimationComponent
	if animation_component:
		animation_component.animation_event.connect(_on_animation_event)
		_register_animation_lib_on_caster()
		_configure_caster_animation_nodes()
		#animation_component.add_lib(animation_library_name, definition.animation_library)


func _register_animation_lib_on_caster() -> void:
	pass


func _configure_caster_animation_nodes() -> void:
	pass


#region Contrato — cada Ability concreta sobrescreve
func can_use() -> bool:
	return false

func can_activate() -> bool:
	return caster != null and can_use()

func reset() -> void:
	pass

func handle_press() -> Ability:
	return null

func handle_release() -> void:
	pass

func _process(delta: float) -> void:
	_handle_timers(delta)

#endregion


#region Timers
## Inicia (ou reinicia) um timer nomeado.
## is_global = true: bloqueia can_use() enquanto ativo e conta pro ícone principal.
## is_global = false: só informativo — HUD/lógica própria decide o que fazer com ele.
func start_timer(id: StringName, duration: float, is_global: bool = false) -> void:
	var state := TimerState.new()
	state.remaining = duration
	state.max_value = duration
	state.is_global = is_global
	_timers[id] = state

	if is_global:
		on_cooldown = true

	cooldown_started.emit(id, duration, is_global)
	cooldown_updated.emit(self, id, state.remaining, state.max_value, is_global)


func stop_timer(id: StringName) -> void:
	if not _timers.has(id):
		return
	_timers.erase(id)
	if not _any_global_timer_active():
		on_cooldown = false


func get_timer_remaining(id: StringName) -> float:
	return _timers[id].remaining if _timers.has(id) else 0.0

func get_timer_max(id: StringName) -> float:
	return _timers[id].max_value if _timers.has(id) else 0.0

func is_timer_active(id: StringName) -> bool:
	return get_timer_remaining(id) > 0.0

func _start_cast_safety_timeout(duration: float) -> void:
	if duration > 0.0:
		start_timer(CAST_SAFETY_TIMER_ID, duration, false)

func _on_timer_expired(id: StringName) -> void:
	if id == CAST_SAFETY_TIMER_ID:
		push_warning("Ability '%s': CastEnd never received, forcing cast_end via safety timeout" % (definition.id if definition else &"?"))
		cancel_cast()


func cancel_cast() -> void:
	_on_animation_event(definition.cast_end_event, [])


## Chame isto de dentro do _process() de cada Ability concreta.
func _handle_timers(delta: float) -> void:
	for id in _timers.keys().duplicate():
		var state: TimerState = _timers[id]
		if state.remaining <= 0.0:
			continue
		state.remaining -= delta
		cooldown_updated.emit(self, id, maxf(state.remaining, 0.0), state.max_value, state.is_global)
		if state.remaining <= 0.0:
			state.remaining = 0.0
			if state.is_global:
				var still_active = _any_global_timer_active()
				on_cooldown = still_active
				if not on_cooldown:
					ability_ready.emit(self)
			timer_expired.emit(id)
			_on_timer_expired(id)
			_timers.erase(id)


## Ponto de extensão: reaja ao fim de um timer específico
## (ex: ShadowExchange alternando entre janela mínima e máxima de recast).
func _any_global_timer_active() -> bool:
	for state: TimerState in _timers.values():
		if state.is_global and state.remaining > 0.0:
			return true
	return false


## Atalho para o caso comum: um único cooldown global calculado a partir
## de ability haste. Abilities com timers múltiplos chamam start_timer()
## diretamente em vez desta função.
func _compute_cooldown() -> float:
	var ability_haste: float = combat_component.effective_ability_haste if combat_component else 0.0
	var duration = definition.base_cooldown * (100.0 / (100.0 + ability_haste))
	start_timer(DEFAULT_COOLDOWN_ID, duration, true)
	return duration
#endregion


#region Movement
func _disable_movement() -> void:
	caster.lock_action_provider()

func _enable_movement() -> void:
	caster.unlock_action_provider()

#endregion


#region Animation / eventos
func _request_animation(node_name: StringName, time_scale: float = 1.0) -> void:
	current_animation_request = node_name
	animation_requested.emit(node_name, time_scale)


func set_icon(icon: Texture2D) -> void:
	if definition:
		definition.icon = icon
	ability_changed.emit(self)


func _on_animation_event(event: StringName, _args: Array) -> void:
	print(event, "|", _args)
	if definition and event == definition.cast_end_event:
		stop_timer(CAST_SAFETY_TIMER_ID)
		_enable_movement()
		cast_end.emit()
	if definition and event == definition.cast_start_event:
		cast_start.emit()
#endregion


#region Helpers
func check_valid_target_pos(target_pos: Vector3) -> bool:
	return target_pos != Vector3.INF

func spawn_cast(cast_scene: PackedScene, target: Vector3) -> AbilityCast:
	var cast := cast_scene.instantiate() as AbilityCast
	_get_cast_container().add_child(cast)
	cast.setup(self, target)
	return cast

func _get_cast_container() -> Node:
	return caster.get_tree().current_scene
#endregion
