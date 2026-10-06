extends Node2D

@export var follow_node: Node2D
@export var particle_scene: PackedScene
@export var spawn_interval: float = 0.1
@export var max_particles: int = 20

var spawn_timer: float = 0.0
var particles: Array[Node2D] = []

func _ready() -> void:
	if particle_scene == null:
		particle_scene = preload("res://scenes/effects/water_particle.tscn")

func _process(delta: float) -> void:
	if not follow_node:
		return
	
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_particle()
		spawn_timer = spawn_interval
	
	_cleanup_particles()

func _spawn_particle() -> void:
	if not follow_node.velocity or follow_node.velocity.length() < 10.0:
		return
	
	var particle: Node2D = particle_scene.instantiate()
	particle.global_position = follow_node.global_position - follow_node.velocity.normalized() * 20
	particle.global_position += Vector2(randf_range(-5, 5), randf_range(-5, 5))
	
	get_parent().add_child(particle)
	particles.append(particle)
	
	if particles.size() > max_particles:
		var old: Node2D = particles.pop_front()
		if old and is_instance_valid(old):
			old.queue_free()

func _cleanup_particles() -> void:
	var to_remove: Array[Node2D] = []
	for particle in particles:
		if not is_instance_valid(particle):
			to_remove.append(particle)
	for particle in to_remove:
		particles.erase(particle)
