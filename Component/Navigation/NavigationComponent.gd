class_name NavigationComponent extends EntityComponent3D

@onready var nav_agent: NavigationAgent3D = %NavigationAgent3D

func move_to(target: Vector3) -> void:
	if not nav_agent or not target: return
	nav_agent.target_position = target

func stop() -> void:
	if not nav_agent: return
	nav_agent.target_position = entity.global_position

func is_finished() -> bool:
	return not nav_agent or nav_agent.is_navigation_finished()

func get_next_position() -> Vector3:
	return nav_agent.get_next_path_position() if nav_agent else entity.global_position
