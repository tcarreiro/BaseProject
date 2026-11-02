# framework
class_name AbilityDefinition extends Resource

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var ability_scene: PackedScene
@export var base_cooldown: float = 3.0
@export var blocks_other_casts: bool = true
@export var cast_end_event: StringName = &"CastEnd"
@export var cast_start_event: StringName = &"CastStart"
@export var cast_end_timeout: float = 3.0  # 0.0 = for no failsafe. Forces cast_end_event after timeout
