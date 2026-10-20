extends Node3D
const EnemyScene = preload("res://enemy.tscn")
const SPAWN_INTERVAL = 3.0
const SPAWN_RADIUS = 12.0
const HeavyEnemyScene = preload("res://heavy_enemy.tscn")
const HEAVY_CHANCE = 0.4
var spawn_timer = SPAWN_INTERVAL
func _process(delta: float) -> void:
	spawn_timer -=delta
	if spawn_timer <= 0.0:
		spawn_enemy()
		spawn_timer = SPAWN_INTERVAL
func spawn_enemy() -> void:
	var enemy 
	if randf() < HEAVY_CHANCE:
		enemy = HeavyEnemyScene.instantiate()
	else: 
		enemy = EnemyScene.instantiate()
	add_child(enemy)
	var angle = randf() * TAU
	enemy.position = Vector3(cos(angle) * SPAWN_RADIUS ,1.0, sin(angle) * SPAWN_RADIUS)
