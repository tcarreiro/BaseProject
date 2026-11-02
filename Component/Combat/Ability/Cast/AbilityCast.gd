class_name AbilityCast extends Node3D

signal cast_hit(target: Node3D)
signal cast_started()
signal cast_tick()
signal finished()

var ability: Ability
var caster: Entity3D


func setup(p_ability: Ability, target: Vector3) -> void:
	ability = p_ability
	caster = p_ability.caster
	global_position = target


## Encerra este cast de forma "limpa" (fim natural, não interrompido).
## Sobrescreva para acionar animação de saída antes do queue_free, se precisar.
func end() -> void:
	finished.emit()
	queue_free()


## Contrato — cada AbilityCast concreto decide como tocar suas próprias animações (VFX, mesh, partícula).
func _play_animation(_animation_name: StringName) -> void:
	pass
