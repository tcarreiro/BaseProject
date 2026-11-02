class_name ProjectAbilityExample extends Ability # with BlendTreeAnimationComponent

@export var animation_library: AnimationLibrary
@export var animation_library_name: StringName
@export var cast_animation_node: AnimationNodeAnimation
@export var aim_animation_node: AnimationNodeBlendSpace2D
@export var cast_moving_animation_node: AnimationNodeBlendSpace2D
var action_provider_component: ActionProviderComponent


func setup(p_definition: AbilityDefinition, p_caster: Entity3D) -> void:
	super(p_definition, p_caster)
	action_provider_component = caster.get_component(ActionProviderComponent)


func _register_animation_lib_on_caster() -> void:
	if not animation_library or animation_library_name == &"": return
	var blend_tree_component := animation_component as BlendTreeAnimationComponent
	if blend_tree_component:
		blend_tree_component.add_lib(animation_library_name, animation_library)


func _configure_caster_animation_nodes() -> void:
	var blend_tree_component := animation_component as BlendTreeAnimationComponent
	if not blend_tree_component: return
	if cast_animation_node:
		blend_tree_component.swap_internal_node(BlendTreeAnimationComponent.STANDING_CAST, cast_animation_node)
	if aim_animation_node:
		blend_tree_component.swap_internal_node(BlendTreeAnimationComponent.STANDING_AIM, aim_animation_node)
	if cast_moving_animation_node:
		blend_tree_component.swap_internal_node(BlendTreeAnimationComponent.STANDING_CAST_MOVING, cast_moving_animation_node)


#func _get_cast_container() -> Node:
	#return GameManager.current_map # example for Luminara
