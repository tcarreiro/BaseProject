class_name FallState extends BaseState

@export var distance = 0.9
var raycast = RayCast3D.new()

func _ready() -> void:
	state_id = StateId.FALL
	animation_node_name = BlendTreeAnimationComponent.FALLING
	_ordering()
	raycast.collision_mask = 512 # TODO: get from database
	add_child(raycast)


func _ordering() -> void:
	moves_priority = {
		StateId.FALL : 0,
		StateId.DISABLE : 1, # should stop mid air if disabled?
		StateId.IDLE: 5,
		StateId.MOVE: 5,
	}


func _filtering(action_data: ActionData) -> void:
	super._filtering(action_data)
	raycast.global_position = entity.global_position
	raycast.target_position = Vector3.DOWN * distance
	raycast.force_raycast_update()
	if raycast.is_colliding():
		_play_animation(BlendTreeAnimationComponent.LANDING)
		action_data.actions[0] = StateId.IDLE
