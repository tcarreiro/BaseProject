class_name MouseCaptureComponent extends Area3DDupe

var _blocking_checks: Dictionary[StringName, Callable] = {}

func is_mouse_targetable() -> bool:
	if !is_visible_in_tree():
		return false
	for check_name in _blocking_checks:
		var check: Callable = _blocking_checks[check_name]
		if check.is_valid() and check.call():
			return false
	return true


func add_mouse_targetable_check(check_name: StringName, blocking_condition: Callable) -> void:
	_blocking_checks[check_name] = blocking_condition


func remove_mouse_targetable_check(check_name: StringName) -> void:
	_blocking_checks.erase(check_name)
