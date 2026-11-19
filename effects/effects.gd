extends Node3D

const DeathBurstScene = preload("res://effects/death_burst.tscn")
const ParryBurstScene = preload("res://effects/parry_burst.tscn")

func _ready() -> void:
	Events.parry_landed.connect(_on_parry_landed)
	Events.enemy_died.connect(_on_enemy_died)

func _on_parry_landed(point: Vector3) -> void:
	spawn(ParryBurstScene, point)

func spawn(scene: PackedScene, point: Vector3) -> void:
	var effect = scene.instantiate()
	add_child(effect)
	effect.global_position = point

func _on_enemy_died(enemy: Node3D) -> void:
	var burst = DeathBurstScene.instantiate()
	burst.color = enemy.spirit_color
	burst.size = enemy.death_scale
	burst.position = enemy.global_position
	add_child(burst)
