extends CanvasLayer

var world: Node2D
var move_joystick: VirtualJoystick
var aim_joystick: VirtualJoystick

@onready var fire_button: Button = $FireButton

func _ready() -> void:
	move_joystick = _create_joystick("LeftJoystick")
	aim_joystick = _create_joystick("RightJoystick")
	if fire_button:
		fire_button.pressed.connect(_on_fire_pressed)

func setup(world_ref: Node2D) -> void:
	world = world_ref

func _create_joystick(node_name: String) -> VirtualJoystick:
	var node: Control = get_node_or_null(node_name)
	if node:
		var joystick: VirtualJoystick = VirtualJoystick.new()
		joystick.name = node_name + "_Virtual"
		joystick.size = node.size
		joystick.position = node.position
		joystick.direction_changed.connect(_on_direction_changed.bind(node_name))
		add_child(joystick)
		_build_joystick_visuals(joystick)
		return joystick
	return null

func _build_joystick_visuals(joystick: VirtualJoystick) -> void:
	var bg: ColorRect = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(1, 1, 1, 0.15)
	bg.size = joystick.size
	bg.position = Vector2.ZERO
	joystick.add_child(bg)
	var knob: ColorRect = ColorRect.new()
	knob.name = "Knob"
	knob.color = Color(1, 1, 1, 0.5)
	knob.size = Vector2(40, 40)
	knob.position = joystick.size / 2.0 - Vector2(20, 20)
	joystick.add_child(knob)

func _on_direction_changed(direction: Vector2, joystick_name: String) -> void:
	if not world:
		return
	var ship: Ship = world.get_local_ship()
	if not ship:
		return
	if joystick_name == "LeftJoystick":
		ship.set_move_input(direction)
	elif joystick_name == "RightJoystick":
		if direction.length() > 0.1:
			ship.set_aim_direction(direction)

func _on_fire_pressed() -> void:
	if not world:
		return
	var ship: Ship = world.get_local_ship()
	if ship:
		ship.try_fire()
