extends Area3D

const ROOT_DURATION = 2.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	Events.wave_started.connect(_on_wave_started)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("root"):
		body.root(ROOT_DURATION)
		queue_free()

func _on_wave_started(_number: int) -> void:
	queue_free()
