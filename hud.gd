extends CanvasLayer
@onready var  health_bar = $HealthBar
@onready var spike_label = $SpikeLabel

func _ready() -> void:
	Events.player_health_changed.connect(_on_player_health_changed)
	Events.spikes_changed.connect(_on_spikes_changed)

func _on_player_health_changed(health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = health

func _on_spikes_changed(count: int) -> void:
	spike_label.text = "Spikes: " + str(count)
