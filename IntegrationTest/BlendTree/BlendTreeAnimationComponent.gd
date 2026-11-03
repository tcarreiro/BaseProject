class_name BlendTreeAnimationComponent extends AnimationComponent

# specifics animation events
signal cast_animation_started()
signal cast_animation_ended()
signal cast_impact()

#region Event Types
const CAST_START = &"CastStart"
const CAST_END = &"CastEnd"
const IMPACT = &"Impact"
#endregion

#region Node Names
const IDLE = &"Idle"
const STANDING_LOCOMOTION = &"StandingLocomotion"
const STANDING_AIM = &"StandingAim"
const STANDING_CAST = &"StandingCast"
const STANDING_CAST_MOVING = &"StandingCastMoving"
const JUMP = &"Jump"
const FALLING = &"Falling"
const LANDING = &"Landing"
const DEATH = &"Death"
#endregion


@export var base_blend_tree: AnimationNodeBlendTree
@export var skin: AnimationSkinData

@onready var animation_tree: AnimationTree = %AnimationTree
@onready var animation_player: AnimationPlayer = %AnimationPlayer

var state_machine_node: AnimationNodeStateMachine
var playback: AnimationNodeStateMachinePlayback
var _cached_speed: float = 1.0

func _ready() -> void:
	animation_tree.tree_root = base_blend_tree.duplicate(true)
	if skin:
		swap_state_machine_node(skin.state_machine.duplicate(true))
		_register_animations()

# play_animation / pause_animation / resume_animation / is_paused
# passam a sobrescrever o contrato da base:
#region ANIMATION FLOW
## Travels to a state and optionally changes playback speed.
func play_animation(animation_node_name: StringName, speed: float = 1.0) -> void:
	if not _validate_animation_node(animation_node_name):
		return
	if not playback:
		return
	playback.travel(animation_node_name)
	set_animation_speed(speed)


func is_paused() -> bool:
	return get_animation_speed() == 0.0


## Pauses every animation by setting the root TimeScale to zero.
##
## The previous playback speed is cached and restored by
## resume_animation().
func pause_animation() -> void:
	_cached_speed = get_animation_speed()
	set_animation_speed(0.0)


## Restores playback speed cached by pause_animation().
func resume_animation() -> void:
	set_animation_speed(_cached_speed)
	_cached_speed = 1.0


func set_allow_travel_to_self(flag: bool) -> void:
	state_machine_node.allow_transition_to_self = flag


## Sets the global playback speed.
##
## This affects every animation state because all of them
## pass through the root TimeScale node.
func set_animation_speed(speed:float)->void:
	animation_tree.set("parameters/TimeScale/scale", speed)


func get_animation_speed()->float:
	return animation_tree.get("parameters/TimeScale/scale")

#endregion
# swap_state_machine_node, swap_internal_node, register_event, emit_event,
# get_animation_events etc. permanecem quase idênticos — só troca chamadas
# tipo self.set("parameters/...") por animation_tree.set("parameters/...")

func _register_animations() -> void:
	for library_key in skin.movement_library:
		add_lib(library_key, skin.movement_library[library_key])

	if skin.library:
		add_lib(skin.library_name, skin.library)

	for node_name in skin.node_overrides:
		var animation_node: AnimationNode = skin.node_overrides[node_name]
		if animation_node:
			swap_internal_node(node_name, animation_node)


#region NODE HANDLING
#func register_ability_animations(definition: AbilityDefinition) -> void:
	#if definition.animation_library:
		#add_lib(definition.animation_library_name, definition.animation_library)

## Replaces the current Skin State Machine.
##
## Each entity skin provides its own AnimationNodeStateMachine.
## This is usually called only during initialization.
func swap_state_machine_node(animation_node_res: AnimationNodeStateMachine)->void:
	var blend_tree := animation_tree.tree_root as AnimationNodeBlendTree
	if blend_tree.has_node("StateMachine"):
		blend_tree.disconnect_node("TimeScale", 0)
		blend_tree.remove_node("StateMachine")
	blend_tree.add_node("StateMachine", animation_node_res)
	blend_tree.connect_node("TimeScale", 0, "StateMachine")
	state_machine_node = blend_tree.get_node("StateMachine") as AnimationNodeStateMachine
	playback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback


## Replaces one internal node of the current Skin State Machine.
##
## Supports:
## - AnimationNodeAnimation
## - AnimationNodeBlendSpace1D
## - AnimationNodeBlendSpace2D
## - AnimationNodeBlendTree
##
## Used to inject skin-specific or ability-specific animation nodes.
func swap_internal_node(animation_node_name: StringName, animation_node_res: Resource) -> void:
	if not _validate_animation_node(animation_node_name):
		return
	if animation_node_res is AnimationNodeAnimation:
		_swap_animation_node_animation(animation_node_name, animation_node_res)
	elif animation_node_res is AnimationNodeBlendSpace1D:
		_swap_animation_blend_space_1d(animation_node_name, animation_node_res)
	elif animation_node_res is AnimationNodeBlendSpace2D:
		_swap_animation_blend_space_2d(animation_node_name, animation_node_res)
	elif animation_node_res is AnimationNodeBlendTree:
		_swap_animation_blend_tree(animation_node_name, animation_node_res)


func _swap_animation_node_animation(animation_node_name: StringName, animation_node_res: AnimationNodeAnimation) -> void:
	var animation_node = state_machine_node.get_node(animation_node_name)
	if not animation_node is AnimationNodeAnimation:
		return
	state_machine_node.replace_node(animation_node_name, animation_node_res)


func _swap_animation_blend_tree(animation_node_name: StringName, animation_node_res: AnimationNodeBlendTree) -> void:
	var animation_node = state_machine_node.get_node(animation_node_name)
	if not animation_node is AnimationNodeBlendTree:
		return
	state_machine_node.replace_node(animation_node_name, animation_node_res)


func _swap_animation_blend_space_1d(animation_node_name: StringName, animation_node_res: AnimationNodeBlendSpace1D) -> void:
	var animation_node = state_machine_node.get_node(animation_node_name)
	if not animation_node is AnimationNodeBlendSpace1D:
		return
	state_machine_node.replace_node(animation_node_name, animation_node_res)


func _swap_animation_blend_space_2d(animation_node_name: StringName, animation_node_res: AnimationNodeBlendSpace2D) -> void:	
	var animation_node = state_machine_node.get_node(animation_node_name)
	if not animation_node is AnimationNodeBlendSpace2D:
		return
	state_machine_node.replace_node(animation_node_name, animation_node_res)

#endregion

#region ANIMATION LIBRARY HANDLING
func add_lib(animation_lib_name: StringName, animation_lib: AnimationLibrary) -> void:
	if not animation_lib:
		return
	if animation_lib_name in animation_player.get_animation_library_list():
		return
	animation_player.add_animation_library(animation_lib_name, animation_lib)

#endregion

#region NODE BLEND HANDLING
func set_animation_blendspace2d_blend_position(animation_node_name: StringName, blend:Vector2)->void:
	if not _validate_animation_node(animation_node_name):
		return
	var animation_node = state_machine_node.get_node(animation_node_name)
	if animation_node is AnimationNodeBlendSpace2D:
		animation_tree.set("parameters/StateMachine/%s/blend_position"%animation_node_name, blend)


func set_animation_blendspace1d_blend_position(animation_node_name: StringName, blend:float)->void:
	if not _validate_animation_node(animation_node_name):
		return
	var animation_node = state_machine_node.get_node(animation_node_name)
	if animation_node is AnimationNodeBlendSpace1D:
		animation_tree.set("parameters/StateMachine/%s/blend_position"%animation_node_name, blend)
	
#endregion

#region EVENT EMISSION
## Emits a gameplay animation event.
##
## This method is intended to be called exclusively by
## Animation method tracks.
##
## Specific events are mapped to strongly-typed signals while
## every event is also forwarded through animation_event.
func emit_event(event: StringName, args: Array = []) -> void:
	match event:
		END_DEATH:
			death_animation_ended.emit()
		CAST_START:
			cast_animation_started.emit()
		CAST_END:
			cast_animation_ended.emit()
		IMPACT:
			cast_impact.emit()
		_:
			animation_event.emit(event, args)


#endregion

#region REGISTER EVENT
## Removes every AnimationComponent Method Track from
## the specified state node.
##
## BlendSpaces are traversed automatically.
func clear_method_track(state_node_name: StringName) -> void:
	var node := state_machine_node.get_node(state_node_name)
	if not node:
		return

	if node is AnimationNodeAnimation:
		_clear_animation_method_track(node.animation)

	elif node is AnimationNodeBlendSpace1D:
		for i in node.get_blend_point_count():
			var anim_node = node.get_blend_point_node(i)
			if anim_node is AnimationNodeAnimation:
				_clear_animation_method_track(anim_node.animation)

	elif node is AnimationNodeBlendSpace2D:
		for i in node.get_blend_point_count():
			var anim_node = node.get_blend_point_node(i)
			if anim_node is AnimationNodeAnimation:
				_clear_animation_method_track(anim_node.animation)


func _clear_animation_method_track(animation_name: StringName) -> void:
	var animation := animation_player.get_animation(animation_name)
	if not animation:
		return

	for i in range(animation.get_track_count() - 1, -1, -1):
		if animation.track_get_type(i) != Animation.TYPE_METHOD:
			continue

		if animation.track_get_path(i) != ^"AnimationComponent":
			continue

		animation.remove_track(i)

	ResourceSaver.save(animation)


func get_state_animations(state_node_name: StringName) -> Array[StringName]:
	var node := state_machine_node.get_node(state_node_name)
	if not node:
		return []

	var animations: Array[StringName] = []

	if node is AnimationNodeAnimation:
		animations.append(node.animation)

	elif node is AnimationNodeBlendSpace1D:
		for i in node.get_blend_point_count():
			var anim_node = node.get_blend_point_node(i)
			if anim_node is AnimationNodeAnimation:
				animations.append(anim_node.animation)

	elif node is AnimationNodeBlendSpace2D:
		for i in node.get_blend_point_count():
			var anim_node = node.get_blend_point_node(i)
			if anim_node is AnimationNodeAnimation:
				animations.append(anim_node.animation)

	return animations

## Returns every registered AnimationComponent event
## contained in the specified state node.
##
## BlendSpaces are traversed automatically.
func get_animation_events(state_node_name: StringName) -> Array[Dictionary]:
	var node := state_machine_node.get_node(state_node_name)
	if not node:
		return []

	var events: Array[Dictionary] = []

	if node is AnimationNodeAnimation:
		events.append_array(_get_events_from_animation(node.animation))

	if node is AnimationNodeBlendSpace1D:
		for i in node.get_blend_point_count():
			var anim_node = node.get_blend_point_node(i)
			if anim_node is AnimationNodeAnimation:
				events.append_array(_get_events_from_animation(anim_node.animation))

	if node is AnimationNodeBlendSpace2D:
		for i in node.get_blend_point_count():
			var anim_node = node.get_blend_point_node(i)
			if anim_node is AnimationNodeAnimation:
				events.append_array(_get_events_from_animation(anim_node.animation))

	return events


func _get_events_from_animation(animation_name: StringName) -> Array[Dictionary]:
	var animation := animation_player.get_animation(animation_name)
	if not animation:
		return []

	var track := -1

	for i in animation.get_track_count():
		if animation.track_get_type(i) != Animation.TYPE_METHOD:
			continue
		if animation.track_get_path(i) != ^"AnimationComponent":
			continue

		track = i
		break

	if track == -1:
		return []

	var events: Array[Dictionary] = []

	for key in animation.track_get_key_count(track):
		var value: Dictionary = animation.track_get_key_value(track, key)

		if value.get("method") != &"emit_event":
			continue

		var method_args: Array = value.get("args", [])

		events.append({
			"animation": animation_name,
			"time": animation.track_get_key_time(track, key),
			"event": method_args[0] if method_args.size() > 0 else &"",
			"args": method_args[1] if method_args.size() > 1 else []
		})

	return events

## Registers an animation event at the current playback position.
##
## If the animation does not already contain a Method Track,
## one is automatically created.
##
## The event can later be received through emit_event().
func register_event(animation_name: StringName, event: StringName, args: Array = []) -> void:
	var animation := animation_player.get_animation(animation_name)
	if not animation:
		return

	var track := -1

	for i in range(animation.get_track_count()):
		if animation.track_get_type(i) != Animation.TYPE_METHOD:
			continue
		if animation.track_get_path(i) != ^"AnimationComponent":
			continue

		track = i
		break

	if track == -1:
		track = animation.add_track(Animation.TYPE_METHOD)
		animation.track_set_path(track, ^"AnimationComponent")

	var method_args: Array = [event]
	if not args.is_empty():
		method_args.append(args)

	animation.track_insert_key(
		track,
		get_current_animation_time(),
		{
			"method": &"emit_event",
			"args": method_args
		}
	)
	ResourceSaver.save(animation)


func register_cast_end_event(animation_name: StringName) -> void:
	register_event(animation_name, CAST_END)


func register_end_death_event(animation_name: StringName) -> void:
	register_event(animation_name, END_DEATH)


func register_impact_event(animation_name: StringName) -> void:
	register_event(animation_name, IMPACT)

func get_current_animation_time() -> float:
	return playback.get_current_play_position()

#endregion

#region VALIDATION
func _validate_animation_node(animation_node_name: StringName) -> bool:
	if not state_machine_node is AnimationNodeStateMachine:
		return false
	if not state_machine_node.has_node(animation_node_name):
		return false
	return true


func _validate_lib_and_animation(lib_name: StringName, animation_name: StringName) -> bool:
	if not lib_name in animation_tree.get_animation_library_list():
		return false
	if not animation_name in animation_tree.get_animation_list():
		return false
	return true

#endregion

# ============================================================================
# DESIGN NOTES
#
# AnimationComponent owns the animation flow.
#
# AnimationNodeStateMachine owns state transitions.
#
# AnimationNodeTimeScale own animation speed
#
# AnimationNodes own animation assets.
#
# Method Tracks own gameplay timing.
#
# AnimationLibraries own animation resources.
#
# ============================================================================
