class_name EntityComponent3D extends Node3D

## Identificador opcional para componentes endereçáveis por "papel"
## (ex: "belt", "backpack"). Deixe vazio se não precisar.
@export var component_id: StringName = &""

var entity: Entity3D

## Chamado uma vez, depois que TODOS os componentes irmãos já estão
## registrados (mas não necessariamente com setup() já chamado).
func setup(p_entity: Entity3D) -> void:
	entity = p_entity


## Chamado antes da remoção. Desconecte sinais e limpe estado aqui.
func teardown() -> void:
	pass


## Ganchos reativos opcionais — sobrescreva só se precisar reagir
## à entrada/saída de outros componentes na mesma entidade.
func _on_sibling_component_added(_component: EntityComponent3D) -> void:
	pass


func _on_sibling_component_removed(_component: EntityComponent3D) -> void:
	pass
