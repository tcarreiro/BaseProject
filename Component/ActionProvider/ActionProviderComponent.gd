class_name ActionProviderComponent extends EntityComponent3D

## Resultado da última resolve_movement_action(), guardado para outros
## componentes consultarem sem precisar re-resolver a cada frame.
var action_data: ActionData
var _disabled: bool = false

func resolve_movement_action() -> ActionData:
	return null


## Chamado uma vez por frame de física para obter o vetor 3D final
## a ser aplicado como velocidade horizontal da entidade.
func resolve_movement_direction() -> Vector3:
	return Vector3.ZERO


func resolve_move_action(_event: InputEvent) -> ActionData.Move:
	return null


func enable_process() -> void:
	_disabled = false


func disable_process() -> void:
	_disabled = true
