# projeto — filtro específico do projeto
class_name ProjectMouseTargetingExample extends MouseTargetingComponent

func _is_valid_hit(hit: Dictionary) -> bool:
	var collider = hit.get("collider")
	return collider is MouseCaptureComponent and collider.is_mouse_targetable()
