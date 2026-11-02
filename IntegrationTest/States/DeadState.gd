class_name DeadState extends BaseState

func _ready() -> void:
	state_id = StateId.DEAD
	animation_node_name = BlendTreeAnimationComponent.DEATH
	can_move = false
	_ordering()


func _ordering() -> void:
	moves_priority = {} # TBD: Revive?


func _filtering(action_data: ActionData) -> void:
	action_data.actions.clear()
	action_data.queued_moves.clear()


func state_enter() -> void:
	super.state_enter()
	entity.lock_action_provider()
	if animation_component: animation_component.death_animation_ended.connect(_on_animation_event)


func _on_animation_event()->void:
	entity._destroy(3.0)
