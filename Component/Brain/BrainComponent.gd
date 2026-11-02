class_name BrainComponent extends EntityComponent3D

enum BTState {
	IDLE, WANDER, CHASE, ATTACK, INVESTIGATE, LOOK_AT
}

var bt_state: BTState = BTState.IDLE

var current_target: Entity3D
var last_seen_position: Vector3 = Vector3.INF
var can_see_target: bool = false
var destination: Vector3 = Vector3.INF

#var current_step: StepNode
#var current_scent: ScentNode
#var current_noise: NoiseNode

var use_slot_id: StringName

func set_state(state: BTState) -> void:
	bt_state = state


func is_target_in_attack_range() -> bool:
	if not has_target():
		return false
	if not can_see_target:
		return false
	var distance = entity.global_position.distance_to(current_target.global_position)
	return distance <= entity.combat_stats.effective_attack_range


func set_use_slot_id(slot_id: StringName) -> void:
	use_slot_id = slot_id


func _process(_delta: float) -> void:
	if can_see_target and current_target:
		last_seen_position = current_target.global_position


func set_target(new_target: Entity3D) -> void:
	current_target = new_target
	if current_target:
		last_seen_position = current_target.global_position
		can_see_target = true


func lose_target() -> void:
	can_see_target = false
	set_destination(last_seen_position)


func clear_target() -> void:
	current_target = null
	last_seen_position = Vector3.INF


func has_target() -> bool:
	return is_instance_valid(current_target) or last_seen_position != Vector3.INF


func update_target_position() -> void:
	if not has_target(): return
	last_seen_position = current_target.global_position


func set_destination(pos: Vector3) -> void:
	destination = pos


func has_destination() -> bool:
	return destination != Vector3.INF


func clear_destination() -> void:
	destination = Vector3.INF


func get_aim_location() -> Vector3:
	return current_target.global_position if current_target else last_seen_position


func clear_all() -> void:
	current_target = null
	#current_step = null
	#current_scent = null
	#current_noise = null
	last_seen_position = Vector3.INF
	clear_destination()
