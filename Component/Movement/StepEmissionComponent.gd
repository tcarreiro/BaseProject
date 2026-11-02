class_name StepEmissionComponent extends EntityComponent3D

class StepEvent:
	var uuid := UUID.new_uuid()
	var entity: Entity3D
	var member_name: StringName
	var position: Vector3
	var intensity: float
	var direction: Vector3

signal foot_landed(step: StepEvent)

@export var raycast_feet:Dictionary[StringName, RayCast3D] = {}
@export var intensity_multiplier: float = 1.0
@export var vertical_component_weight: float = 1.2
@export var raycast_length: float = 0.25

var current_step_velocity :Vector3 = Vector3.ZERO
var movement_component: MovementComponent

func setup(p_entity: Entity3D) -> void:
	super.setup(p_entity)
	if not get_parent() is VisualComponent:
		push_error("StepEmissionComponent must be child of a VisualComponent")
	movement_component = entity.get_component(MovementComponent) as MovementComponent
	if not movement_component:
		push_error("StepEmissionComponent's Entity must have a MovementComponent")
	movement_component.step_landed.connect(_on_step_landed)


# TODO: how to prevent intermitent movement input hiding steps?
func _on_step_landed(member_name: StringName) -> void:
	await get_tree().physics_frame

	current_step_velocity = entity.velocity
	current_step_velocity.y = movement_component.last_vertical_impact_velocity

	var ray := raycast_feet[member_name]

	var from := ray.to_global(Vector3.ZERO)
	var direction := (ray.to_global(ray.target_position) - from).normalized()
	var to := from + direction * raycast_length

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = ray.collision_mask
	query.collide_with_areas = ray.collide_with_areas
	query.collide_with_bodies = ray.collide_with_bodies
	query.exclude = [entity]

	var result := entity.get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		return

	var footstep_position: Vector3 = result.position

	var step := StepEvent.new()
	step.entity = entity
	step.member_name = member_name
	step.position = footstep_position
	step.intensity = _get_impact_intensity(current_step_velocity)
	step.direction = entity.get_forward()
	foot_landed.emit(step)


func _get_impact_intensity(_current_step_velocity :Vector3) -> float:
	return intensity_multiplier * (_current_step_velocity.length() + (abs(_current_step_velocity.y) * vertical_component_weight))
