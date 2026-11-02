# framework
class_name MouseTargetingComponent extends EntityComponent3D

@export var collision_mask: int = 1
@export var max_distance: float = 1000.0
@export var collide_with_bodies: bool = false
@export var collide_with_areas: bool = true

var _world_position: Vector3 = Vector3.INF
var _world_normal: Vector3 = Vector3.ZERO

func _process(_delta: float) -> void:
	var camera := entity.get_viewport().get_camera_3d()
	if not camera:
		_world_position = Vector3.INF
		return

	var space_state := entity.get_world_3d().direct_space_state
	var mouse_pos := entity.get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse_pos)
	var direction := camera.project_ray_normal(mouse_pos)

	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * max_distance, collision_mask)
	query.collide_with_areas = collide_with_areas
	query.collide_with_bodies = collide_with_bodies

	var hit := space_state.intersect_ray(query)
	if hit and _is_valid_hit(hit):
		_world_position = hit.position
		_world_normal = hit.normal
	else:
		_world_position = Vector3.INF
		_world_normal = Vector3.INF


func get_target_position() -> Vector3:
	return _world_position


func get_target_normal() -> Vector3:
	return _world_normal


## Ponto de extensão: projeto decide o que conta como alvo válido.
func _is_valid_hit(_hit: Dictionary) -> bool:
	return true
