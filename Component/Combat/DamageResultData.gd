class_name DamageResultData extends Resource

@export var uuid := UUID.new_uuid()
@export var amount: int
@export var damage_type: StringName
@export var mitigated_amount: int
@export var blocked_amount: int

func _init(_amount: int, _damage_type: StringName, _mitigated_amount: int, _blocked_amount: int) -> void:
	amount = _amount
	damage_type = _damage_type
	mitigated_amount = _mitigated_amount
	blocked_amount = _blocked_amount
