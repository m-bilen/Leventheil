extends Node3D

const TreeScene = preload("res://world/tree_trunk.tscn")

@export var  count: int = 14
@export var radius: float = 21.0
@export var jitter: float = 1.5
@export var min_scale: float = 0.8
@export var max_scale: float = 1.4

func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	for i in count:
		var angle = TAU / count * i + rng.randf_range(-0.15, 0.15)
		var dist = radius + rng.randf_range(-jitter, jitter)
		var tree = TreeScene.instantiate()
		add_child(tree)
		tree.position = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		tree.rotation.y = rng.randf() * TAU
		var s = rng.randf_range(min_scale, max_scale)
		tree.scale = Vector3(s, 1.0 + rng.randf_range(0.0, 0.3), s)
