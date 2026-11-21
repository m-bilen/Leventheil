extends Node3D

const DeathBurstScene = preload("res://effects/death_burst.tscn")
const ParryBurstScene = preload("res://effects/parry_burst.tscn")
const HitChipsScene = preload("res://effects/hit_chips.tscn")
const VineLashScene = preload("res://effects/vine_lash.tscn")



func _ready() -> void:
	Events.parry_landed.connect(_on_parry_landed)
	Events.enemy_died.connect(_on_enemy_died)
	Events.hit_landed.connect(_on_hit_landed)
	Events.vine_lashed.connect(_on_vine_lashed)

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

func _on_hit_landed(point: Vector3, direction: Vector3) -> void:
	var chips = HitChipsScene.instantiate()
	chips.direction = direction
	chips.position = point
	add_child(chips)

func _on_vine_lashed(origin: Vector3, target: Vector3, _hit: bool) -> void:
	var lash = VineLashScene.instantiate()
	lash.target = target
	lash.position = origin
	add_child(lash)
