class_name Loot extends Resource

signal collected(loot: Loot)
signal spawned(loot: Loot)

const KIND_PREFIX := &"kind."
const KIND_LOOT := StringName(KIND_PREFIX+"loot")

static var _kind_tags_by_script: Dictionary = {}

## INFO: if an descendent includes an uuid: UUID, ItemStack keeps every instance cached.
## See comments at ItemStack.gd
@export var id: StringName
@export var display_name: StringName
@export var description: String
@export var icon: Texture2D
@export var max_stack: int:
	set(v):
		max_stack = maxi(v, 0)
@export var extra_tags: Array[StringName] = []

# Support to modding
var on_collect: Callable
var on_spawn: Callable

var _tag_cache: Array[StringName] = []
var _tag_cache_valid: bool = false # false if _tag_cache needs to be updated

func spawn() -> void:
	spawned.emit(self)
	if on_spawn.is_valid():
		on_spawn.call(id)


func collect() -> void:
	collected.emit(self)
	if on_collect.is_valid():
		on_collect.call(id)


func can_stack() -> bool:
	return max_stack != 1


func get_max_stack() -> int:
	return max_stack


#region Tags
func has_tag(p_tag: StringName) -> bool:
	return get_tag_set().has(p_tag)


## Every tag of this item: class tags + content tags, no duplicates.
## Read-only by convention: use add_tag() to change it.
func get_tag_set() -> Array[StringName]:
	if not _tag_cache_valid:
		_tag_cache = get_kind_tags().duplicate()
		for tag in extra_tags:
			if not _tag_cache.has(tag):
				_tag_cache.append(tag)
		_tag_cache_valid = true
	return _tag_cache


func add_tag(tag: StringName) -> void:
	if extra_tags.has(tag):
		return
	extra_tags.append(tag)
	_tag_cache_valid = false


func get_kind_tags() -> Array[StringName]:
	var script: Script = get_script()
	if _kind_tags_by_script.has(script):
		return _kind_tags_by_script[script]
	var kind_tags: Array[StringName] = []
	var current: Script = script
	while current != null:
		var global_name := current.get_global_name()
		if not global_name.is_empty():
			kind_tags.append(StringName(get("KIND_"+String(global_name).to_snake_case().to_upper())))
		current = current.get_base_script()
	_kind_tags_by_script[script] = kind_tags
	return kind_tags
#endregion
