class_name PlayerActionProvider extends ActionProviderComponent

var is_using_controller: bool = false
var input_strength: Vector2 = Vector2.ZERO
var analog_deadzone: float = 0.1
var sneaking_threshold: float = 0.6

# checa se PlayerActionProvider tem isto:
func resolve_movement_direction() -> Vector3:
	if action_data.movement_direction.length() < 0.1:
		return Vector3.ZERO
	var camera = entity.get_viewport().get_camera_3d()
	if not camera:
		return Vector3(action_data.movement_direction.x, 0, action_data.movement_direction.y).normalized()
	var forward = -camera.global_transform.basis.z
	forward.y = 0
	var right = camera.global_transform.basis.x
	right.y = 0
	return (forward.normalized() * action_data.movement_direction.y + right.normalized() * action_data.movement_direction.x).normalized()


func resolve_movement_action() -> ActionData:
	action_data = ActionData.new()
	entity = entity as OrchestratorEntityExample
	if _disabled: return action_data
	if entity.movement_component and entity.movement_component.disable_movement:
		action_data.actions.append(StateId.IDLE)
		return action_data
	
	_compute_movement_direction()
	if not entity.movement_component:
		return null
	action_data.is_on_floor = entity.movement_component.on_floor()
	var has_disabling = entity.status_component and entity.status_component.has_any_disabling()
	#var allow_input = GameManager.allow_player_input
	if has_disabling:# or not allow_input:
		action_data.movement_direction = Vector2.ZERO
		action_data.actions.append(StateId.DISABLE)
	_determine_move_state()
	if not action_data.is_on_floor:
		action_data.actions.append(StateId.FALL)
	else:
		if action_data.movement_direction.length() > 0.1:
			action_data.actions.append(StateId.MOVE)
		else:
			action_data.actions.append(StateId.IDLE)
	
	return action_data


func _compute_movement_direction() -> void:
	var raw_input = Input.get_vector("input_left", "input_right", "input_down", "input_up")
	
	is_using_controller = Input.get_connected_joypads().size() > 0
	if is_using_controller and raw_input != Vector2.ZERO:
		input_strength = Vector2(
			Input.get_axis("input_left", "input_right"),
			Input.get_axis("input_down", "input_up")
		)
	else:
		input_strength = raw_input
	
	if raw_input.length() < analog_deadzone:
		action_data.movement_direction = Vector2.ZERO
	else:
		var scaled_magnitude = (raw_input.length() - analog_deadzone) / (1.0 - analog_deadzone)
		action_data.movement_direction = raw_input.normalized() * scaled_magnitude


func _determine_move_state() -> void:
	if is_using_controller and action_data.movement_direction != Vector2.ZERO:
		var stick_pressure = max(abs(input_strength.x), abs(input_strength.y))
		action_data.is_sneaking = stick_pressure < sneaking_threshold
		return
	action_data.is_sneaking = Input.is_action_pressed(&"sneak") and action_data.movement_direction.length() > 0.0


func resolve_move_action(event: InputEvent)->ActionData.Move:
	var _action_data = ActionData.new()
	var move = ActionData.Move.new();
	if _disabled: return null
	move.time = Time.get_ticks_msec() / 1000.0
	check_press_event(event, &"jump", move)
	check_press_event(event, &"primary_click", move)
	check_press_event(event, &"secondary_click", move)
	check_press_event(event, &"special", move)
	check_press_event(event, &"dash", move)
	check_release_event(event, &"jump", move)
	check_release_event(event, &"primary_click", move)
	check_release_event(event, &"secondary_click", move)
	check_release_event(event, &"special", move)
	check_release_event(event, &"dash", move)
	if move.slot != "":
		return move
	return null

func check_press_event(event: InputEvent, key_name: StringName, move: ActionData.Move) -> void:
	if not InputMap.has_action(key_name):
		return
	if event.is_action_pressed(key_name):
		move.slot = key_name
		move.action_move = ActionData.Move.PRESSED


func check_release_event(event: InputEvent, key_name: StringName, move: ActionData.Move) -> void:
	if not InputMap.has_action(key_name):
		return
	if event.is_action_released(key_name):
		move.slot = key_name
		move.action_move = ActionData.Move.RELEASED
