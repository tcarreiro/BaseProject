class_name PersistentAreaCast extends AbilityCast

signal entity_entered(entity: Entity3D)
signal entity_exited(entity: Entity3D)

@export var ability_cast_animation_library_name: StringName = &""
@export var lifetime: float = 5.0
@export var tick_rate: float = 0.5

@onready var collision_area: Area3D = %Collision
@onready var animation_player: AnimationPlayer = %AnimationPlayer

var entities_inside: Array[Entity3D] = []

var _lifetime_remaining: float = 0.0
var _tick_timer: float = 0.0


func setup(p_ability: Ability, target: Vector3) -> void:
	super.setup(p_ability, target)
	_lifetime_remaining = lifetime
	_tick_timer = tick_rate
	if collision_area:
		collision_area.body_entered.connect(_on_body_entered)
		collision_area.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	_lifetime_remaining -= delta
	if _lifetime_remaining <= 0.0:
		_on_expire()
		finished.emit()
		queue_free()
		return

	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer += tick_rate
		_on_tick()
		cast_tick.emit()


func _on_body_entered(body: Node3D) -> void:
	var target := _find_entity(body)
	if target and not entities_inside.has(target):
		entities_inside.append(target)
		entity_entered.emit(target)


func _on_body_exited(body: Node3D) -> void:
	var target := _find_entity(body)
	if target:
		entities_inside.erase(target)
		entity_exited.emit(target)


func _find_entity(node: Node3D) -> Entity3D:
	var current: Node = node
	while current:
		if current is Entity3D:
			return current
		current = current.get_parent()
	return null


func _play_animation(animation_name: StringName) -> void:
	if animation_player and animation_player.get_animation_library_list().has(ability_cast_animation_library_name):
		animation_player.play("%s/%s"%[ability_cast_animation_library_name, animation_name])


## Ponto de extensão — chamado a cada tick_rate segundos enquanto a área existe.
func _on_tick() -> void:
	pass

## Ponto de extensão — chamado quando o lifetime esgota.
func _on_expire() -> void:
	pass

## Ponto de extensão — chamado pela Ability enquanto o jogador segura a mira.
func enter_aim_phase() -> void:
	pass


## Ponto de extensão — chamado pela Ability enquanto em estado de mira
func update_aim(_clamped_target: Vector3, _ring_progress:float) -> void:
	pass


## Ponto de extensão — chamado pela Ability quando a o evento "castStart" é disparado — inicia lifetime/tick a partir daqui.
func enter_cast_phase(_p_lifetime: float, _p_tick_rate: float) -> void:
	pass


## Ponto de extensão — chamado pela Ability quando a mira é confirmada — inicia lifetime/tick a partir daqui.
func end_aim_phase() -> void:
	pass
