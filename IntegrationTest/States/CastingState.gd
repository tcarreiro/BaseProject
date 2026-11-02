class_name CastingState extends BaseState

var ability: Ability
var movement_component: MovementComponent

func _ready() -> void:
	state_id = StateId.CAST
	state_speed_multiplier = 0.3
	_ordering()


func setup(p_state_machine: StateMachine, p_entity: Entity3D) -> void:
	super.setup(p_state_machine, p_entity)
	movement_component = entity.get_component(MovementComponent) as MovementComponent


func _ordering() -> void:
	moves_priority = {
		StateId.DISABLE: 0,
	}


## Chamado pelo AbilityInputBuffer antes de transicionar pro estado CAST.
func begin_cast(p_ability: Ability) -> void:
	ability = p_ability


func state_enter() -> void:
	if not ability: return
	if ability.current_animation_request != &"":
		_on_animation_requested(ability.current_animation_request)
	if not ability.animation_requested.is_connected(_on_animation_requested):
		ability.animation_requested.connect(_on_animation_requested)
	if not ability.cast_end.is_connected(_on_cast_end):
		ability.cast_end.connect(_on_cast_end)


func state_exit() -> void:
	if ability:
		if ability.animation_requested.is_connected(_on_animation_requested):
			ability.animation_requested.disconnect(_on_animation_requested)
		if ability.cast_end.is_connected(_on_cast_end):
			ability.cast_end.disconnect(_on_cast_end)
	ability = null


func physics_update(delta: float, action_data: ActionData) -> void:
	super.physics_update(delta, action_data)
	_update_animation_params()


func _on_animation_requested(node_name: StringName, time_scale:float = 1.0) -> void:
	if animation_component:
		animation_component.play_animation(node_name, time_scale)


func _on_cast_end() -> void:
	state_machine.transition_to(StateId.IDLE)


func _update_animation_params() -> void:
	if not action_provider_component: return
	var direction := action_provider_component.resolve_movement_direction()
	var local_dir := entity.get_global_transform_basis().inverse() * direction
	var move_blend := Vector2(local_dir.x, -local_dir.z)
	if animation_component:
		animation_component.set_animation_blendspace2d_blend_position(BlendTreeAnimationComponent.STANDING_AIM, move_blend)
		animation_component.set_animation_blendspace2d_blend_position(BlendTreeAnimationComponent.STANDING_CAST_MOVING, move_blend)
