# framework
class_name ProjectileCast extends AbilityCast

@export var speed: float = 15.0
@export var max_distance: float = 50.0
@export var ability_cast_animation_library_name: StringName = &""

var direction: Vector3 = Vector3.ZERO
var _traveled: float = 0.0
var _collided: bool = false
var _casted: bool = false

@onready var collision_area: Area3D = %Collision
@onready var animation_player: AnimationPlayer = %AnimationPlayer


func setup(p_ability: Ability, target: Vector3) -> void:
	super.setup(p_ability, target)
	global_position = caster.global_position + Vector3.UP
	direction = caster.global_position.direction_to(target)
	look_at(global_position + direction, Vector3.UP)
	if collision_area:
		collision_area.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if not _casted: return
	if _collided: return
	var step = speed * delta
	global_position += direction * step
	_traveled += step
	if _traveled >= max_distance:
		end()


func _play_animation(animation_name: StringName) -> void:
	if animation_player and animation_player.get_animation_library_list().has(ability_cast_animation_library_name):
		animation_player.play("%s/%s"%[ability_cast_animation_library_name, animation_name])


func _cast_projectile() -> void:
	cast_started.emit()
	_casted = true


func _on_body_entered(body: Node3D) -> void:
	if _collided: return
	_on_hit(body)


## Ponto de extensão — cada projeto/projétil decide o que "acertar" significa.
func _on_hit(_body: Node3D) -> void:
	pass
