class_name ActionData

class Move:
	const PRESSED : StringName = &"Pressed"
	const RELEASED : StringName = &"Released"
	var slot: StringName
	var action_move: StringName
	var time: float
	var priority: int


var actions: Array[StringName] = []
var queued_moves: Array[Move] = []
var movement_direction: Vector2 = Vector2.ZERO
var is_sneaking: bool = false
var is_on_floor: bool = true


func has_action(action: StringName) -> bool:
	return action in actions


func has_any_action(action_list: Array[StringName]) -> bool:
	for action in action_list:
		if has_action(action):
			return true
	return false
