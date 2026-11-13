extends Node3D

const ParryBurstScene = preload("res://effects/parry_burst.tscn")

func _ready() -> void:
	Events.parry_landed.connect(_on_parry_landed)

func _on_parry_landed(point: Vector3) -> void:
	spawn(ParryBurstScene, point)

func spawn(scene: PackedScene, point: Vector3) -> void:
	var effect = scene.instantiate()
	add_child(effect)
	effect.global_position = point
