class_name HealResultData extends Resource

@export var uuid := UUID.new_uuid()
@export var amount: int          # cura efetivamente aplicada (já com heal_power e clamp de max_hp)
@export var raw_amount: int      # cura antes de aplicar heal_power
@export var overheal: int        # quanto excedeu o max_hp e foi descartado
@export var heal_cut: bool       # effective_heal_power < 1.0
@export var heal_amplified: bool # effective_heal_power > 1.0

func _init(_amount: int, _raw_amount: int, _overheal: int, _heal_cut: bool, _heal_amplified: bool) -> void:
	amount = _amount
	raw_amount = _raw_amount
	overheal = _overheal
	heal_cut = _heal_cut
	heal_amplified = _heal_amplified
