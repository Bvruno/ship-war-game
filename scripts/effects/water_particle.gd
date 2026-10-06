extends Sprite2D

var lifetime: float = 1.5
var timer: float = 0.0
var fade_speed: float = 1.0

func _process(delta: float) -> void:
	timer += delta
	var alpha: float = 1.0 - (timer / lifetime)
	modulate.a = maxf(0.0, alpha)
	
	if timer >= lifetime:
		queue_free()
	
	var scale_factor: float = 1.0 - (timer / lifetime) * 0.5
	scale = Vector2(6, 6) * scale_factor
