extends Node3D

@onready var player: OrchestratorEntityExample = %Player

func _ready() -> void:
	var ability_component := player.get_component(AbilityComponent) as AbilityComponent

	var fireball_definition := AbilityDefinition.new()
	fireball_definition.id = &"fireball"
	fireball_definition.display_name = "Fireball"
	fireball_definition.ability_scene = preload("uid://b4lmc8er0kpla")
	fireball_definition.base_cooldown = 1.5
	fireball_definition.blocks_other_casts = true

	ability_component.learn_ability(fireball_definition)
	ability_component.equip_ability(&"fireball", &"primary_click")
	
	var scorched_ground_definition := AbilityDefinition.new()
	scorched_ground_definition.id = &"scorched_ground"
	scorched_ground_definition.display_name = "Scorched Ground"
	scorched_ground_definition.ability_scene = preload("uid://biqd1vhm33ntr")
	scorched_ground_definition.base_cooldown = 8.0
	scorched_ground_definition.blocks_other_casts = true
	
	ability_component.learn_ability(scorched_ground_definition)
	ability_component.equip_ability(&"scorched_ground", &"secondary_click")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var att = AttackData.new()
		att.amount = 100
		player.combat_component.receive_hit(att)
