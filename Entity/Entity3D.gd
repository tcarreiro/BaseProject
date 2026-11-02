class_name Entity3D extends CharacterBody3D

signal component_added(component: EntityComponent3D)
signal component_removed(component: EntityComponent3D)

var _components: Array[EntityComponent3D] = []
var _components_by_id: Dictionary = {}  # StringName -> EntityComponent3D


func _ready() -> void:
	var found: Array[EntityComponent3D] = []
	_collect_components(self, found)

	for component in found:
		_register(component)

	for component in found:
		add_component(component, false)


func _collect_components(node: Node, out: Array[EntityComponent3D]) -> void:
	for child in node.get_children():
		if child is Entity3D:
			continue  # não atravessa para dentro de uma entidade aninhada
		if child is EntityComponent3D:
			out.append(child)
		_collect_components(child, out)


## Ponto único de entrada para adicionar um componente, na cena ou em runtime.
## Se `add_as_child` for true, faz o add_child por você.
func add_component(component: EntityComponent3D, add_as_child: bool = true) -> void:
	if add_as_child:
		add_child(component)
	if not _components.has(component):
		_register(component)
	component.setup(self)
	component_added.emit(component)
	for existing in _components:
		if existing != component:
			existing._on_sibling_component_added(component)


func remove_component(component: EntityComponent3D, free_node: bool = true) -> void:
	if not _components.has(component):
		return

	component.teardown()
	_unregister(component)
	component_removed.emit(component)

	for existing in _components:
		existing._on_sibling_component_removed(component)

	if free_node:
		component.queue_free()
	elif component.get_parent() == self:
		remove_child(component)


func get_component(component_class) -> EntityComponent3D:
	for c in _components:
		if is_instance_of(c, component_class):
			return c
	return null


func get_components(component_class) -> Array[EntityComponent3D]:
	return _components.filter(func(c): return is_instance_of(c, component_class))


func get_component_by_id(id: StringName) -> EntityComponent3D:
	return _components_by_id.get(id)


func has_component(component_class) -> bool:
	return get_component(component_class) != null


func _register(component: EntityComponent3D) -> void:
	_components.append(component)
	if component.component_id != &"":
		assert(not _components_by_id.has(component.component_id),
			"component_id duplicado na entidade %s: %s" % [name, component.component_id])
		_components_by_id[component.component_id] = component


func _unregister(component: EntityComponent3D) -> void:
	_components.erase(component)
	if component.component_id != &"":
		_components_by_id.erase(component.component_id)


#region Pontos de extensao
func _on_died() -> void:
	pass


func _destroy(_timer: float = 0.0) -> void:
	pass


func get_target_position() -> Vector3:
	return Vector3.INF


func lock_action_provider() -> void:
	pass


func unlock_action_provider() -> void:
	pass


func _disable_movement() -> void:
	pass


func _enable_movement() -> void:
	pass


func on_floor() -> bool:
	return is_on_floor()


func update_movement(_delta: float, _action_data: ActionData, _state: BaseState) -> void:
	pass


func ray_ahead() -> RayCast3D:
	return null


func ray_below() -> RayCast3D:
	return null


func get_global_transform_basis() -> Basis:
	return global_transform.basis


func get_forward() -> Vector3:
	return Vector3.INF


func get_backward() -> Vector3:
	return -get_forward()


func get_right() -> Vector3:
	return Vector3.INF


func get_left() -> Vector3:
	return -get_right()
