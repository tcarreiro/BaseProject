class_name StateMachine extends EntityComponent3D

signal state_changed(previous: BaseState, current: BaseState)
signal move_input(move: ActionData.Move)

@export var initial_state: BaseState

var available_states: Dictionary[StringName, BaseState] = {}
var current_state: BaseState
var _previous_state: BaseState
var action_provider_component: ActionProviderComponent
var active = true


func setup(p_entity: Entity3D) -> void:
	super(p_entity)
	action_provider_component = entity.get_component(ActionProviderComponent) as ActionProviderComponent
	if not action_provider_component:
		push_error("StateMachine requires an ActionProviderComponent on Entity %s" % entity.name)
	_setup_states()
	_enter_initial_state()


func _setup_states() -> void:
	for child in get_children():
		if child is BaseState:
			available_states[child.state_id] = child
			child.setup(self, entity)


func _enter_initial_state() -> void:
	var first_state := initial_state
	if not first_state and not available_states.is_empty():
		first_state = available_states.values()[0]
	if first_state:
		transition_to(first_state.state_id)


func _process(delta: float) -> void:
	if not active: return
	if current_state:
		current_state.update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not active: return
	if current_state:
		current_state.handle_input(event)
	if action_provider_component:
		var move := action_provider_component.resolve_move_action(event)
		if move:
			move_input.emit(move)


func _physics_process(delta: float) -> void:
	if not active: return
	if not action_provider_component or not current_state:
		return
	var action_data := action_provider_component.resolve_movement_action()
	if action_data:
		current_state.physics_update(delta, action_data)


func transition_to(state_id: StringName) -> void:
	if not available_states.has(state_id):
		return
	var new_state := available_states[state_id]
	if new_state == current_state:
		return
	if current_state:
		current_state.state_exit()
	_previous_state = current_state
	current_state = new_state
	current_state.state_enter()
	state_changed.emit(_previous_state, current_state)


func get_previous_state() -> BaseState:
	return _previous_state


func find_state(state_class: Variant) -> BaseState:
	for child in get_children():
		if is_instance_of(child, state_class):
			return child
	return null
