class_name OrchestratorEntityExample extends Entity3D

var movement_component: MovementComponent
var visual_component: VisualComponent
var navigation_component: NavigationComponent
var combat_component: CombatComponent
var status_component: StatusComponent
var action_provider_component: ActionProviderComponent
var state_machine: StateMachine
var mouse_targeting_component: MouseTargetingComponent


func _ready() -> void:
	super._ready() 
	movement_component = get_component(MovementComponent) as MovementComponent
	visual_component = get_component(VisualComponent) as VisualComponent
	navigation_component = get_component(NavigationComponent) as NavigationComponent
	combat_component = get_component(CombatComponent) as CombatComponent
	status_component = get_component(StatusComponent) as StatusComponent
	action_provider_component = get_component(ActionProviderComponent) as ActionProviderComponent
	state_machine = get_component(StateMachine) as StateMachine
	mouse_targeting_component = get_component(MouseTargetingComponent) as MouseTargetingComponent
	
	if not visual_component:
		push_error("OrchestratorEntityExample: Missing VisualComponent")
	
	if not action_provider_component:
		push_error("OrchestratorEntityExample: Missing ActionProviderComponent")
	
	if not state_machine:
		push_error("OrchestratorEntityExample: Missing StateMachine")
	
	if combat_component:
		combat_component.died.connect(_on_died)


func _on_died() -> void:
	if state_machine: state_machine.transition_to(StateId.DEAD)


func _destroy(_timer: float = 0.0) -> void:
	if _timer > 0.0:
		get_tree().create_timer(_timer).timeout.connect(queue_free)
	else:
		queue_free()


#region Facade: MouseTargetingComponent
func get_target_position() -> Vector3:
	return mouse_targeting_component.get_target_position() if mouse_targeting_component else Vector3.INF

#endregion


#region Facade: ActionProviderComponent
func lock_action_provider() -> void:
	if action_provider_component:
		action_provider_component.disable_process()


func unlock_action_provider() -> void:
	if action_provider_component:
		action_provider_component.enable_process()
#endregion


#region Facade: MovementComponent
func disable_movement() -> void:
	if movement_component:
		movement_component.lock_movement()


func enable_movement() -> void:
	if movement_component:
		movement_component.unlock_movement()


func update_movement(delta: float, action_data: ActionData, state: BaseState) -> void:
	if movement_component:
		movement_component.update_movement(delta, action_data, state)


func on_floor() -> bool:
	if movement_component:
		return movement_component.on_floor()
	else:
		return super.on_floor()
#endregion


#region Facade: VisualComponent
func get_global_transform_basis() -> Basis:
	if visual_component:
		return visual_component.global_transform.basis
	return super.get_global_transform_basis()


func ray_ahead() -> RayCast3D:
	if visual_component:
		return visual_component.stairs_ahead_ray_cast_3d
	return null


func ray_below() -> RayCast3D:
	if visual_component:
		return visual_component.stairs_below_ray_cast_3d
	return null


func look_at_target(target_position: Vector3, rotation_amount: float = 0.0) -> void:
	if visual_component:
		visual_component.look_at_target(target_position, rotation_amount)


func get_forward() -> Vector3:
	return visual_component.get_forward() if visual_component else -global_transform.basis.z.normalized()


func get_right() -> Vector3:
	return visual_component.get_right() if visual_component else global_transform.basis.x.normalized()
#endregion


#region Facade: NavigationComponent
func move_to(target: Vector3) -> void:
	if navigation_component:
		navigation_component.move_to(target)


func stop_nav_agent_movement() -> void:
	if navigation_component:
		navigation_component.stop()

#endregion
