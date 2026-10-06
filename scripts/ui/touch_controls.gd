extends CanvasLayer

var world: Node2D
var move_joystick: VirtualJoystick
var aim_joystick: VirtualJoystick

func setup(world_ref: Node2D) -> void:
	world = world_ref
	_build_controls()

func _build_controls() -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size

	move_joystick = _create_joystick("MoveJoystick", Vector2(100, screen_size.y - 100), 120)
	aim_joystick = _create_joystick("AimJoystick", Vector2(screen_size.x - 100, screen_size.y - 100), 120)
	_create_fire_button(Vector2(screen_size.x - 70, screen_size.y - 250), 80)

func _create_joystick(name: String, center_pos: Vector2, size: float) -> VirtualJoystick:
	var joystick: VirtualJoystick = VirtualJoystick.new()
	joystick.name = name
	joystick.size = Vector2(size, size)
	joystick.position = center_pos - Vector2(size/2, size/2)
	joystick.direction_changed.connect(_on_direction_changed.bind(name))
	add_child(joystick)

	var bg: ColorRect = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(1, 1, 1, 0.15)
	bg.size = Vector2(size, size)
	bg.position = Vector2.ZERO
	joystick.add_child(bg)

	var knob: ColorRect = ColorRect.new()
	knob.name = "Knob"
	knob.color = Color(1, 1, 1, 0.5)
	knob.size = Vector2(size*0.4, size*0.4)
	knob.position = Vector2(size*0.3, size*0.3)
	joystick.add_child(knob)

	var label: Label = Label.new()
	label.text = "MOVE" if name == "MoveJoystick" else "AIM"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(size, size)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	label.add_theme_font_size_override("font_size", 16)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick.add_child(label)

	return joystick

func _create_fire_button(pos: Vector2, size: float) -> void:
	var btn: Button = Button.new()
	btn.name = "FireButton"
	btn.text = "FIRE"
	btn.size = Vector2(size, size)
	btn.position = pos - Vector2(size/2, size/2)
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(_on_fire_pressed)
	add_child(btn)

func _on_direction_changed(direction: Vector2, joystick_name: String) -> void:
	if not world:
		return
	var ship: Ship = world.get_local_ship()
	if not ship:
		return
	if joystick_name == "MoveJoystick":
		ship.set_move_input(direction)
	elif joystick_name == "AimJoystick":
		if direction.length() > 0.1:
			ship.set_aim_direction(direction)

func _on_fire_pressed() -> void:
	if not world:
		return
	var ship: Ship = world.get_local_ship()
	if ship:
		ship.try_fire()
