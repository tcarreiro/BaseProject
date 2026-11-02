class_name AnimationSkinData extends Resource

@export var id: StringName
@export var state_machine: AnimationNodeStateMachine
@export var library: AnimationLibrary
@export var library_name: StringName
@export var movement_library: Dictionary[StringName, AnimationLibrary] = {}
@export var node_overrides: Dictionary[StringName, AnimationNode] = {}
