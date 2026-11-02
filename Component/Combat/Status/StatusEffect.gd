class_name StatusEffect extends Resource

@export var uuid := UUID.new_uuid()
@export var id: String = ""
@export var duration: float = 0.0
@export var max_stacks: int = 1
@export var instant_tick: bool = true
@export var is_disabling: bool = false
@export var is_crowd_control: bool = false
@export var blocks_crowd_control: bool = false
@export var blocks_disabling: bool = false
@export var blocks_damage_of_type: Array[StringName] = []
@export var tick_rate: float = 1.0

## Se true, todo dano/cura gerado pelos ticks deste efeito compartilha o
## mesmo uuid do efeito — o HUD de números de dano acumula no mesmo texto
## em vez de criar um novo a cada tick. Se false, cada tick gera um número
## novo e independente.
@export var aggregate_hud_numbers: bool = true

func _on_apply(_target: Entity3D, _source: Entity3D) -> void:
	pass
func _on_tick(_target: Entity3D, _source: Entity3D) -> void:
	pass
func _on_remove(_target: Entity3D, _source: Entity3D) -> void:
	pass
