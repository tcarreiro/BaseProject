class_name MovementComponent extends EntityComponent3D

signal hard_landing(impact_velocity: float)
signal step_landed(member_name: StringName)

const MAX_STEP_HEIGHT = 0.3
const HARD_LANDING_THRESHOLD = 8.0

@export var move_speed: float = 5.0
@export var valid_collider_classes: Array[StringName] = [
	"StaticBody3D", "CSGShape3D"
]

var animation_component: AnimationComponent
var action_provider_component: ActionProviderComponent

var disable_movement: bool = false
var snapped_to_stairs_last_frame: bool = false
var moving: bool = false
var last_frame_was_on_floor: float = -INF
var last_frame_was_on_air: float = -INF
var vertical_velocity_before_impact: float = 0.0
var last_vertical_impact_velocity = 0.0

func setup(p_entity: Entity3D) -> void:
	super(p_entity)
	
	animation_component = entity.get_component(AnimationComponent) as AnimationComponent
	action_provider_component = entity.get_component(ActionProviderComponent) as ActionProviderComponent
	
	if animation_component:
		animation_component.step_landed.connect(_on_step_landed)


func _on_step_landed(member_name: StringName) -> void:
	step_landed.emit(member_name)


func on_floor() -> bool:
	return entity.is_on_floor() or snapped_to_stairs_last_frame


func get_movement_speed(action_data: ActionData = null) -> float:
	var final_move_speed = move_speed
	if action_data and action_data.is_sneaking:
		final_move_speed *= 0.3
	return final_move_speed


func lock_movement() -> void:
	disable_movement = true


func unlock_movement() -> void:
	disable_movement = false


func update_movement(delta: float, action_data: ActionData, state: BaseState) -> void:
	var direction = action_provider_component.resolve_movement_direction()
	var vertical_speed = entity.velocity.y

	var movement_allowed = not disable_movement and (not state or state.can_move)
	var speed_multiplier = state.state_speed_multiplier if state else 1.0

	entity.velocity = direction * get_movement_speed(action_data) * speed_multiplier
	if not movement_allowed:
		entity.velocity = Vector3.ZERO
	entity.velocity.y = vertical_speed

	if entity.velocity.length() > 0.1:
		entity.look_at_target(entity.global_position + direction, delta * 10)

	if not _snap_up_to_stairs_check(delta):
		entity.move_and_slide()
		_snap_down_to_stairs_check()

	if not on_floor():
		entity.velocity += entity.get_gravity() * delta
		vertical_velocity_before_impact = entity.velocity.y
		last_frame_was_on_air = Engine.get_physics_frames()
	else:
		if vertical_velocity_before_impact != 0.0:
			if abs(vertical_velocity_before_impact) > HARD_LANDING_THRESHOLD:
				hard_landing.emit(vertical_velocity_before_impact)
			vertical_velocity_before_impact = 0.0
		last_frame_was_on_floor = Engine.get_physics_frames()


#region STAIRS HANDLER
func _snap_down_to_stairs_check() -> void:
	var ray_below = entity.ray_below()
	if not ray_below:
		snapped_to_stairs_last_frame = true
		return
	var did_snap = false
	var floor_below: bool = ray_below.is_colliding() and not _is_surface_too_steep(ray_below.get_collision_normal())
	var was_on_floor_last_frame = Engine.get_physics_frames() - last_frame_was_on_floor == 1
	if not entity.is_on_floor() and entity.velocity.y <= 0 and (was_on_floor_last_frame or snapped_to_stairs_last_frame) and floor_below:
		var body_test_result = PhysicsTestMotionResult3D.new()
		if _run_body_test_motion(entity.global_transform, Vector3(0, -MAX_STEP_HEIGHT, 0), body_test_result):
			entity.position.y += body_test_result.get_travel().y
			entity.apply_floor_snap()
			did_snap = true
	snapped_to_stairs_last_frame = did_snap


func _snap_up_to_stairs_check(delta: float) -> bool:
	var ray_ahead = entity.ray_ahead()
	if not ray_ahead:
		snapped_to_stairs_last_frame = true
	if not entity.is_on_floor() and not snapped_to_stairs_last_frame:
		return false
	if entity.velocity.y > 0 or (entity.velocity * Vector3(1,0,1)).length() == 0:
		return false
	var expected_move_motion = entity.velocity * Vector3(1,0,1) * delta
	var step_pos_with_clearance = entity.global_transform.translated(expected_move_motion + Vector3(0, MAX_STEP_HEIGHT*2, 0))
	var down_check_result = PhysicsTestMotionResult3D.new()
	if _run_body_test_motion(step_pos_with_clearance, Vector3(0, -MAX_STEP_HEIGHT*2, 0), down_check_result) and is_valid_collider(down_check_result):
		var step_height = ((step_pos_with_clearance.origin + down_check_result.get_travel()) - entity.global_position).y
		if step_height > MAX_STEP_HEIGHT or step_height <= 0.01 or (down_check_result.get_collision_point() - entity.global_position).y > MAX_STEP_HEIGHT:
			return false
		ray_ahead.global_position = down_check_result.get_collision_point() + Vector3(0, MAX_STEP_HEIGHT, 0) + expected_move_motion.normalized() * 0.1
		ray_ahead.force_raycast_update()
		if ray_ahead.is_colliding() and not _is_surface_too_steep(ray_ahead.get_collision_normal()):
			entity.global_position = step_pos_with_clearance.origin + down_check_result.get_travel()
			entity.apply_floor_snap()
			snapped_to_stairs_last_frame = true
			return true
	return false


func _is_surface_too_steep(normal: Vector3) -> bool:
	return normal.angle_to(Vector3.UP) > entity.floor_max_angle


func _run_body_test_motion(from: Transform3D, motion: Vector3, result = null) -> bool:
	if not result: result = PhysicsTestMotionResult3D.new()
	var params = PhysicsTestMotionParameters3D.new()
	params.from = from
	params.motion = motion
	return PhysicsServer3D.body_test_motion(entity.get_rid(), params, result)


func is_valid_collider(down_check_result: PhysicsTestMotionResult3D) -> bool:
	for collider_class in valid_collider_classes:
		if _down_check_collider(down_check_result, collider_class):
			return true
	return false


func _down_check_collider(down_check_result: PhysicsTestMotionResult3D, classname: StringName) -> bool:
	return down_check_result.get_collider().is_class(classname)

#endregion
