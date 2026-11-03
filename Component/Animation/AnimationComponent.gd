class_name AnimationComponent extends EntityComponent3D

signal animation_event(event: StringName, args: Array)
signal death_animation_ended()
signal step_landed(member_name: StringName)

#region Event Types
const END_DEATH = &"DeathEnd"
#endregion


func setup(p_entity: Entity3D) -> void:
	super(p_entity)
	var state_machine := entity.get_component(StateMachine) as StateMachine
	if state_machine:
		state_machine.state_changed.connect(_on_state_changed)


func _on_state_changed(_previous: BaseState, current: BaseState) -> void:
	if current and current.animation_node_name != "":
		play_animation(current.animation_node_name, current.state_speed_multiplier)


## Backend deve sobrescrever estes:
func play_animation(_animation_name: StringName, _speed: float = 1.0) -> void:
	push_warning("play_animation method not implemented for %s"%entity.name)


func pause_animation() -> void:
	push_warning("pause_animation method not implemented for %s"%entity.name)


func resume_animation() -> void:
	push_warning("resume_animation method not implemented for %s"%entity.name)


func is_paused() -> bool:
	return false


## Mecanismo genérico, chamado por Method Tracks — funciona com
## qualquer AnimationPlayer por baixo, então pode viver aqui mesmo.
func emit_event(event: StringName, args: Array = []) -> void:
	match event:
		END_DEATH:
			death_animation_ended.emit()
		_:
			animation_event.emit(event, args)
