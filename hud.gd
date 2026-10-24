extends CanvasLayer
@onready var  health_bar = $HealthBar
@onready var spike_label = $SpikeLabel
@onready var wave_label = $WaveLabel
var banner_tween: Tween

func _ready() -> void:
	Events.player_health_changed.connect(_on_player_health_changed)
	Events.spikes_changed.connect(_on_spikes_changed)
	Events.wave_started.connect(_on_wave_started)
	Events.boss_spawned.connect(_on_boss_spawned)

func _on_player_health_changed(health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = health

func _on_spikes_changed(count: int) -> void:
	spike_label.text = "Spikes: " + str(count)

func _on_wave_started(number: int) -> void:
	show_banner("Wave " + str(number))

func _on_boss_spawned(boss_name: String) -> void:
	show_banner(boss_name)

func show_banner(text: String) -> void:
	if banner_tween:
		banner_tween.kill()
	wave_label.modulate.a = 1.0
	banner_tween = create_tween()
	banner_tween.tween_interval(1.5)
	banner_tween.tween_property(wave_label, "modulate: a", 0.0, 0.8)
