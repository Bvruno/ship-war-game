extends Control
class_name VirtualJoystick

signal direction_changed(direction: Vector2)

var _active: bool = false
var _touch_index: int = -1
var _center: Vector2
var _max_distance: float = 50.0
var _current_direction: Vector2 = Vector2.ZERO

@onready var background: ColorRect = $Background
@onready var knob: ColorRect = $Knob

func _ready() -> void:
	if background:
		_max_distance = background.size.x * 0.4
	_center = size / 2.0

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			if get_global_rect().has_point(touch.position):
				_active = true
				_touch_index = touch.index
				_update_direction(touch.position - global_position)
		else:
			if touch.index == _touch_index:
				_active = false
				_touch_index = -1
				_current_direction = Vector2.ZERO
				if knob:
					knob.position = _center - knob.size / 2.0
				direction_changed.emit(Vector2.ZERO)
	elif event is InputEventScreenDrag and _active:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if drag.index == _touch_index:
			_update_direction(drag.position - global_position)
	elif event is InputEventMouseMotion and _active:
		_update_direction(get_global_mouse_position() - global_position)
	elif event is InputEventMouseButton and _active:
		var button: InputEventMouseButton = event as InputEventMouseButton
		if not button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			_active = false
			_current_direction = Vector2.ZERO
			if knob:
				knob.position = _center - knob.size / 2.0
			direction_changed.emit(Vector2.ZERO)

func _update_direction(local_pos: Vector2) -> void:
	var diff: Vector2 = local_pos - _center
	var distance: float = diff.length()
	if distance > _max_distance:
		diff = diff.normalized() * _max_distance
	_current_direction = diff / _max_distance
	if knob:
		knob.position = _center + diff - knob.size / 2.0
	direction_changed.emit(_current_direction)

func get_direction() -> Vector2:
	return _current_direction
