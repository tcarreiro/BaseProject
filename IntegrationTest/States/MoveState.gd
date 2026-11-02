class_name MoveState extends BaseState

func _ready() -> void:
	state_id = StateId.MOVE
	animation_node_name = BlendTreeAnimationComponent.STANDING_LOCOMOTION
	_ordering()


func _ordering() -> void:
	moves_priority = {
		StateId.DISABLE : 0,
		StateId.MOVE : 1,
		StateId.FALL : 2,
		StateId.IDLE : 5,
		StateId.JUMP : 10,
		StateId.AIM : 20,
		StateId.CAST : 25,
	}

func _filtering(action_data: ActionData) -> void:
	super._filtering(action_data)
	if not animation_component: return
	if action_data.actions.size() > 0 and action_data.actions[0] == StateId.MOVE:
		var locomotion_blend_position = 1
		if action_data.is_sneaking:
			locomotion_blend_position = 0.5
		animation_component.set_animation_blendspace1d_blend_position(animation_node_name, locomotion_blend_position)
	
