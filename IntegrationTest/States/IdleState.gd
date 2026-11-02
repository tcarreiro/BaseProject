class_name IdleState extends BaseState

func _ready() -> void:
	state_id = StateId.IDLE
	animation_node_name = BlendTreeAnimationComponent.IDLE
	_ordering()


func _ordering() -> void:
	moves_priority = {
		StateId.DISABLE : 0,
		StateId.FALL : 5,
		StateId.JUMP : 10,
		StateId.AIM : 25,
		StateId.MOVE : 30,
	}

func _filtering(action_data: ActionData) -> void:
	super._filtering(action_data)
	_check_if_landing(action_data)

func _check_if_landing(action_data: ActionData) -> void:
	# ensure it doesn't enter FALL state while landing (otherwise it will bounce between IDLE and FALL)
	if action_data.actions.size() > 0 and action_data.actions[0] == StateId.FALL:
		if not animation_component or not animation_component.playback:
			return
		if animation_component.playback.get_current_node() == BlendTreeAnimationComponent.LANDING:
			action_data.actions.erase(StateId.FALL)
