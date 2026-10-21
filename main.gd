extends Node3D
const EnemyScene = preload("res://enemy.tscn")
const SPAWN_RADIUS = 12.0
const HeavyEnemyScene = preload("res://heavy_enemy.tscn")
const WAVES = [
	{"basic": 5, "heavy": 0, "interval": 1.2},
	{"basic": 12, "heavy": 0, "interval": 0.6},
	{"basic": 0, "heavy": 1, "interval": 0.0},
	{"basic": 14, "heavy": 2, "interval": 0.5},
	{"basic": 6, "heavy": 3, "interval": 1.0},
]
var wave_index = 0
var spawn_queue: Array = []
var spawn_timer = 0.0
var enemies_alive = 0
func _ready() -> void:
	Events.enemy_died.connect(_on_enemy_died)
	start_wave()
func start_wave() -> void:
	var wave = WAVES[wave_index]
	spawn_queue.clear()
	for i in wave["basic"]:
		spawn_queue.append(EnemyScene)
	for i in wave["heavy"]:
		spawn_queue.append(HeavyEnemyScene)
	spawn_queue.shuffle()
	spawn_timer = 0.0
func _process(delta: float) -> void:
	if spawn_queue.is_empty():
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_enemy(spawn_queue.pop_back())
		spawn_timer = WAVES[wave_index]["interval"]
func spawn_enemy(scene: PackedScene) -> void:
	var enemy = scene.instantiate()
	add_child(enemy)
	var angle = randf() * TAU
	enemy.position = Vector3(cos(angle) * SPAWN_RADIUS, 1.0, sin(angle) * SPAWN_RADIUS)
	enemies_alive += 1
func _on_enemy_died(_enemy: Node3D) -> void:
	enemies_alive -= 1
	if enemies_alive <= 0 and spawn_queue.is_empty():
		wave_cleared()
func wave_cleared() -> void: 
	wave_index += 1
	if wave_index >= WAVES.size():
		return
	start_wave()
