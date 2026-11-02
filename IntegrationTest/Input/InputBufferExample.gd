# projeto example
class_name InputBufferExample extends EntityComponent3D

@export var input_buffer_time: float = 0.12  # segundos
const max_pool_size: int = 3

var input_queue: Array[ActionData.Move] = []
var combo_counter: int = 0

var _state_machine: StateMachine
var _ability_component: AbilityComponent
var _processing: bool = false


func setup(p_entity: Entity3D) -> void:
	super(p_entity)
	_state_machine = entity.get_component(StateMachine) as StateMachine
	_ability_component = entity.get_component(AbilityComponent) as AbilityComponent

	if _state_machine:
		_state_machine.move_input.connect(queue_input)
		_state_machine.state_changed.connect(_on_state_changed)


func _process(_delta: float) -> void:
	process_queued_actions()


func _on_state_changed(_previous: BaseState, _current: BaseState) -> void:
	process_queued_actions()


func queue_move(slot: StringName, action: StringName) -> void:
	var move := ActionData.Move.new()
	move.slot = slot
	move.action_move = action
	move.time = Time.get_ticks_msec() / 1000.0
	queue_input(move)


func queue_input(move: ActionData.Move) -> void:
	var now = Time.get_ticks_msec() / 1000.0
	input_queue = input_queue.filter(func(_move: ActionData.Move):
		return now - float(_move.time) < input_buffer_time
	)
	move.priority = input_queue.size()
	input_queue.append(move)
	input_queue.sort_custom(func(a, b):
		return int(a.priority) > int(b.priority)
	)
	process_queued_actions()


func process_queued_actions() -> void:
	if _processing:
		return
	_processing = true

	if not input_queue.is_empty():
		var now = Time.get_ticks_msec() / 1000.0
		input_queue = input_queue.filter(func(move: ActionData.Move):
			return now - float(move.time) < input_buffer_time
		)

		var i := 0
		var processed := 0
		while i < input_queue.size() and processed < max_pool_size:
			var move: ActionData.Move = input_queue[i]
			if try_consume_move(move):
				input_queue.remove_at(i)
				processed += 1
			else:
				i += 1

	_processing = false


func try_consume_move(move: ActionData.Move) -> bool:
	if not _ability_component:
		return false
	if move.action_move == ActionData.Move.PRESSED:
		var ability := _ability_component.use(move.slot)
		if ability:
			_enter_casting_state(ability)
			return true
		return false
	else:
		_ability_component.release(move.slot)
		return true


func _enter_casting_state(ability: Ability) -> void:
	if not _state_machine: return
	var casting_state := _state_machine.find_state(CastingState) as CastingState
	if not casting_state: return
	casting_state.begin_cast(ability)
	_state_machine.transition_to(StateId.CAST)
