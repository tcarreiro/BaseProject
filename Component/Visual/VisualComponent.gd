@tool
class_name VisualComponent extends EntityComponent3D

@onready var body_parts: Node3D = %BodyParts
@onready var skeleton: Skeleton3D = %GeneralSkeleton

@onready var stairs_ahead_ray_cast_3d: RayCast3D = %StairsAheadRayCast3D
@onready var stairs_below_ray_cast_3d: RayCast3D = %StairsBelowRayCast3D

@onready var head_top: Marker3D = %Top
@onready var eye: Marker3D = %Eye
@onready var knee: Marker3D = %Knee
@onready var feet: Marker3D = %Feet
@onready var left_hand: Marker3D = %LeftHand
@onready var right_hand: Marker3D = %RightHand
@onready var left_foot: Marker3D = %LeftFoot
@onready var right_foot: Marker3D = %RightFoot

@export var markers: Dictionary[StringName, Marker3D] = {}


func _enter_tree() -> void:
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()
	
	var has_valid_child := false
	for part in body_parts.get_children():
		if part is MeshInstance3D:
			has_valid_child = true
			break
	
	if not has_valid_child:
		warnings.append("At least 1 MeshInstance3D is needed as BodyParts' child")
	
	return warnings

func setup(p_entity: Entity3D) -> void:
	super(p_entity)
	if Engine.is_editor_hint():
		return
	accept_skeleton(skeleton)


func get_marker(marker_name: StringName) -> Marker3D:
	return markers.get(marker_name)


func accept_skeleton(_skeleton: Skeleton3D) -> void:
	for part in body_parts.get_children():
		if part is MeshInstance3D:
			part.skeleton = _skeleton.get_path()


func look_at_target(target_position: Vector3, rotation_amount: float = 0.0) -> void:
	var flat_target := Vector3(target_position.x, global_position.y, target_position.z)
	if rotation_amount <= 0.01:
		if flat_target == global_position: return
		look_at(flat_target, Vector3.UP)
		return

	var direction = flat_target - global_position
	if direction.length_squared() < 0.1:
		return

	var nbasis = Transform3D.IDENTITY.looking_at(direction, Vector3.UP).basis
	var target_yaw = nbasis.get_euler().y

	rotation.y = lerp_angle(rotation.y, target_yaw, rotation_amount)


func get_forward() -> Vector3:
	return -global_transform.basis.z.normalized()


func get_backward() -> Vector3:
	return -get_forward()


func get_right() -> Vector3:
	return global_transform.basis.x.normalized()


func get_left() -> Vector3:
	return -get_right()
