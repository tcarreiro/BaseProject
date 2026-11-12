class_name MovementComponent extends EntityComponent3D

signal hard_landing(impact_velocity: float)
signal step_landed(member_name: StringName)
signal foot_landed(step: StepEvent)

const MAX_STEP_HEIGHT = 0.3
const HARD_LANDING_THRESHOLD = 8.0

@export var move_speed: float = 5.0
@export var valid_collider_classes: Array[StringName] = [
	"StaticBody3D", "CSGShape3D"
]
@export var raycast_feet:Dictionary[StringName, RayCast3D] = {}
@export var watch_steps: bool = true
@export var intensity_multiplier: float = 1.0
@export var vertical_component_weight: float = 1.2
@export var raycast_length: float = 0.25

var raycast_feet_on_ground:Dictionary[StringName, bool] = {}

var action_provider_component: ActionProviderComponent

var disable_movement: bool = false
var snapped_to_stairs_last_frame: bool = false
var moving: bool = false
var last_frame_was_on_floor: float = -INF
var last_frame_was_on_air: float = -INF
var vertical_velocity_before_impact: float = 0.0
var last_vertical_impact_velocity = 0.0
var last_horizontal_velocity = 0.0


class StepEvent:
	var uuid := UUID.new_uuid()
	var entity: Entity3D
	var member_name: StringName
	var position: Vector3
	var intensity: float
	var direction: Vector3

var current_step_velocity :Vector3 = Vector3.ZERO

func setup(p_entity: Entity3D) -> void:
	super.setup(p_entity)
	if not get_parent() is VisualComponent:
		push_error("MovementComponent must be child of a VisualComponent")
	action_provider_component = entity.get_component(ActionProviderComponent) as ActionProviderComponent


func _on_step_landed() -> void:
	if not watch_steps:
		return
	
	current_step_velocity = entity.velocity
	current_step_velocity.y = last_vertical_impact_velocity
	
	for member_name in raycast_feet.keys():
		if not raycast_feet.has(member_name):
			continue
		if not raycast_feet_on_ground.has(member_name):
			raycast_feet_on_ground[member_name] = false
		var ray := raycast_feet[member_name]
		
		var from := ray.to_global(Vector3.ZERO)
		var ray_dir := (ray.to_global(ray.target_position) - from).normalized()
		var to := from + ray_dir * raycast_length
		
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = ray.collision_mask
		query.collide_with_areas = ray.collide_with_areas
		query.collide_with_bodies = ray.collide_with_bodies
		query.exclude = [entity]
		
		var result := entity.get_world_3d().direct_space_state.intersect_ray(query)

		if result.is_empty():
			raycast_feet_on_ground[member_name] = false
			continue
		
		if result.collider is StaticBody3D:
			if ray.global_position.distance_squared_to(result.position) < 0.041:
				if not raycast_feet_on_ground[member_name]:
					_emit_step(member_name, result.position, _get_impact_intensity(current_step_velocity))
			else:
				raycast_feet_on_ground[member_name] = false


func _emit_step(member_name: StringName, step_position: Vector3, intensity: float) -> void:
	var step := StepEvent.new()
	step.entity = entity
	step.member_name = member_name
	step.position = step_position
	step.intensity = intensity
	step.direction = entity.get_forward()
	raycast_feet_on_ground[member_name] = true
	foot_landed.emit(step)


func _get_impact_intensity(_current_step_velocity :Vector3) -> float:
	return intensity_multiplier * (_current_step_velocity.length() + (abs(_current_step_velocity.y) * vertical_component_weight))


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

	var horizontal_velocity := Vector3(entity.velocity)
	horizontal_velocity.y = 0
	var horizontal_speed := horizontal_velocity.length()
	
	if horizontal_speed > 0.01:
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
			# falling steps
			_check_steps(_get_impact_intensity(Vector3(0, vertical_velocity_before_impact, 0)))
			vertical_velocity_before_impact = 0.0
		last_frame_was_on_floor = Engine.get_physics_frames()
	
	if horizontal_speed > 0.01:
		_on_step_landed()
	else:
		if last_horizontal_velocity > 0.01:
			# catch intermitent input movement
			_check_steps(_get_impact_intensity(current_step_velocity))
	last_horizontal_velocity = horizontal_speed


func _check_steps(intensity: float) -> void:
	if not watch_steps:
		return
	for member_name in raycast_feet:
		_emit_step(member_name, raycast_feet[member_name].global_position, intensity)


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
