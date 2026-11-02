class_name BaseState extends Node

@export var animation_node_name: String = ""
@export var can_move: bool = true
@export var state_speed_multiplier: float = 1.0

var state_id: StringName
var state_machine: StateMachine
var entity: Entity3D
var action_provider_component: ActionProviderComponent
var animation_component: AnimationComponent

## Estados que não devem gerar transição vindos deste (evita loop de reentrada
## quando a tag vencedora já representa o mesmo estado lógico atual).
var equivalent_states: Array[StringName] = []

## Prioridade de cada tag de ActionData.actions relevante para este estado.
## Sao as tags que podem interromper o estado
## Tags fora deste dicionário são ignoradas por _filtering().
var moves_priority: Dictionary = {}


func setup(p_state_machine: StateMachine, p_entity: Entity3D) -> void:
	state_machine = p_state_machine
	entity = p_entity
	action_provider_component = entity.get_component(ActionProviderComponent) as ActionProviderComponent
	animation_component = entity.get_component(AnimationComponent) as AnimationComponent


func state_enter() -> void:
	pass


func state_exit() -> void:
	pass


func update(_delta: float) -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass


func physics_update(delta: float, action_data: ActionData) -> void:
	_filtering(action_data)
	var next_state := check_state_priority(action_data)
	if next_state != &"" and not next_state in equivalent_states and next_state != state_id:
		state_machine.transition_to(next_state)
	_update_movement(delta, action_data)


func _play_animation(anim_name: StringName, speed: float = 1.0) -> void:
	var animation_controller = entity.get_component(AnimationComponent) as AnimationComponent
	if animation_controller:
		animation_controller.play_animation(anim_name, speed)


func find_state(state_class: Variant) -> BaseState:
	return state_machine.find_state(state_class) if state_machine else null


func _update_movement(delta: float, action_data: ActionData) -> void:
	entity.update_movement(delta, action_data, self)


func _filtering(action_data: ActionData) -> void:
	action_data.actions = action_data.actions.filter(
		func(action: StringName) -> bool: return moves_priority.has(action)
	)


func check_state_priority(action_data: ActionData) -> StringName:
	if action_data.actions.is_empty():
		return &""
	action_data.actions.sort_custom(_moves_priority_sort)
	return action_data.actions[0]


func _moves_priority_sort(a: StringName, b: StringName) -> bool:
	return moves_priority[a] > moves_priority[b]
