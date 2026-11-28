extends Node

@export_group("Player")
@export var parry_sound: AudioStream
@export var vine_lash_sound: AudioStream
@export_group("Boss")
@export var boss_roar_sound: AudioStream


func _ready() -> void:
	Events.parry_landed.connect(_on_parry_landed)
	Events.hit_landed.connect(_on_hit_landed)
	Events.enemy_died.connect(_on_enemy_died)
	Events.vine_lashed.connect(_on_vine_lashed)
	Events.boss_spawned.connect(_on_boss_spawned)


func play_at(stream: AudioStream, point: Vector3, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var player = AudioStreamPlayer3D.new()
	player.stream = stream
	player.bus = "SFX"
	player.volume_db = volume_db
	add_child(player)
	player.global_position = point
	player.finished.connect(player.queue_free)
	player.play()


func play_flat(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "SFX"
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _on_parry_landed(point: Vector3) -> void:
	play_at(parry_sound, point)


func _on_hit_landed(point: Vector3, _direction: Vector3, target: Node3D) -> void:
	play_at(target.get("hit_sound"), point)


func _on_enemy_died(enemy: Node3D) -> void:
	play_at(enemy.death_sound, enemy.global_position)


func _on_vine_lashed(_source: Node3D, origin: Vector3, _target: Vector3, _hit: bool) -> void:
	play_at(vine_lash_sound, origin)


func _on_boss_spawned(_boss_name: String) -> void:
	play_flat(boss_roar_sound)
