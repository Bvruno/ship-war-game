extends Control
class_name VirtualJoystick

signal direction_changed(direction: Vector2)

var _active: bool = false
var _touch_index: int = -1
var _center: Vector2
var _max_distance: float = 50.0
var _current_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	_center = size / 2.0
	_max_distance = size.x * 0.35

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var mouse_global: Vector2 = get_global_mouse_position()
				if get_global_rect().has_point(mouse_global):
					_active = true
					_update_direction(mouse_global - global_position)
			else:
				if _active:
					_reset()
	elif event is InputEventMouseMotion:
		if _active:
			var mouse_global: Vector2 = get_global_mouse_position()
			_update_direction(mouse_global - global_position)
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			if not _active:
				if get_global_rect().has_point(touch.position):
					_active = true
					_touch_index = touch.index
					_update_direction(touch.position - global_position)
		elif touch.index == _touch_index:
			_reset()
	elif event is InputEventScreenDrag:
		if _active and event.index == _touch_index:
			var drag: InputEventScreenDrag = event as InputEventScreenDrag
			_update_direction(drag.position - global_position)

func _update_direction(local_pos: Vector2) -> void:
	var diff: Vector2 = local_pos - _center
	var distance: float = diff.length()
	if distance > _max_distance:
		diff = diff.normalized() * _max_distance
	_current_direction = diff / _max_distance
	if _current_direction.length() > 1.0:
		_current_direction = _current_direction.normalized()
	direction_changed.emit(_current_direction)

func _reset() -> void:
	_active = false
	_touch_index = -1
	_current_direction = Vector2.ZERO
	direction_changed.emit(Vector2.ZERO)

func get_direction() -> Vector2:
	return _current_direction
