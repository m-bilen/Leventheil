extends Node3D
const EnemyScene = preload("res://enemy.tscn")
const BossScene = preload("res://boss.tscn")
const HeavyEnemyScene = preload("res://heavy_enemy.tscn")
const CasterScene = preload("res://caster.tscn")
const SPAWN_RADIUS = 12.0
const FIRST_SPAWN_DELAY = 1.5
const WAVE_BREAK = 4.0
const WAVES = [
	{"basic": 5, "heavy": 0, "interval": 1.2},
	{"basic": 12, "heavy": 0, "interval": 0.6},
	{"basic": 0, "heavy": 1, "interval": 0.0},
	{"basic": 14, "heavy": 2, "caster": 2, "interval": 0.5},
	{"basic": 4, "heavy": 0, "boss": 1, "caster": 2, "interval": 1.5},
]
var wave_index = 0
var spawn_queue: Array = []
var spawn_timer = 0.0
var enemies_alive = 0
func _ready() -> void:
	Engine.time_scale = 1.0
	Events.enemy_died.connect(_on_enemy_died)
	wave_index = GameState.current_wave
	start_wave()
func start_wave() -> void:
	GameState.current_wave = wave_index
	Events.wave_started.emit(wave_index + 1)
	var wave = WAVES[wave_index]
	spawn_queue.clear()
	for i in wave["basic"]:
		spawn_queue.append(EnemyScene)
	for i in wave["heavy"]:
		spawn_queue.append(HeavyEnemyScene)
	for i in wave.get("caster", 0):
		spawn_queue.append(CasterScene)
	spawn_queue.shuffle()
	for i in wave.get("boss", 0):
		spawn_queue.append(BossScene)
	spawn_timer = FIRST_SPAWN_DELAY
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
	enemy.position = Vector3(cos(angle) * SPAWN_RADIUS, 2.5, sin(angle) * SPAWN_RADIUS)
	enemies_alive += 1
func _on_enemy_died(_enemy: Node3D) -> void:
	enemies_alive -= 1
	if enemies_alive <= 0 and spawn_queue.is_empty():
		wave_cleared()
func wave_cleared() -> void: 
	wave_index += 1
	if wave_index >= WAVES.size():
		return
	await get_tree().create_timer(WAVE_BREAK).timeout
	start_wave()
