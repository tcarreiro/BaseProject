class_name Area3DDupe extends Area3D

@export var shapes_to_duplicate: Array[Node3D] = []

func _ready():
	if shapes_to_duplicate.is_empty():
		push_error("Area3DDupe: shapes_to_duplicate is empty")
		return
	
	for shape in shapes_to_duplicate:
		if not (shape is CollisionShape3D or shape is CollisionPolygon3D or shape is CSGShape3D):
			push_error("Area3DDupe: only accepts CollisionShape3D or CollisionPolygon3D or CSGShape3D. Got: ", shape.get_class())
			continue
		
		var dupe: Node
		
		if shape is CSGShape3D:
			# Cria um CollisionShape3D a partir do CSGShape3D
			var collision_shape := CollisionShape3D.new()
			collision_shape.shape = (shape as CSGShape3D).bake_collision_shape()
			collision_shape.transform = shape.transform
			dupe = collision_shape
		else:
			dupe = shape.duplicate()
		add_child(dupe)
