extends Node

var sfx_fire: AudioStream
var sfx_explosion: AudioStream
var sfx_shield_hit: AudioStream
var sfx_hull_hit: AudioStream
var sfx_upgrade: AudioStream

var fire_player: AudioStreamPlayer
var explosion_player: AudioStreamPlayer
var shield_player: AudioStreamPlayer
var hull_player: AudioStreamPlayer
var upgrade_player: AudioStreamPlayer

var master_volume: float = 0.7
var sfx_volume: float = 0.8

func _ready() -> void:
	_generate_sounds()
	_setup_players()

func _generate_sounds() -> void:
	sfx_fire = _generate_fire_sound()
	sfx_explosion = _generate_explosion_sound()
	sfx_shield_hit = _generate_shield_hit_sound()
	sfx_hull_hit = _generate_hull_hit_sound()
	sfx_upgrade = _generate_upgrade_sound()

func _setup_players() -> void:
	fire_player = _create_player()
	explosion_player = _create_player()
	shield_player = _create_player()
	hull_player = _create_player()
	upgrade_player = _create_player()
	add_child(fire_player)
	add_child(explosion_player)
	add_child(shield_player)
	add_child(hull_player)
	add_child(upgrade_player)

func _create_player() -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.volume_db = linear_to_db(master_volume * sfx_volume)
	return player

func _generate_fire_sound() -> AudioStream:
	var sound: AudioStreamGenerator = AudioStreamGenerator.new()
	sound.mix_rate = 22050.0
	var playback: AudioStreamGeneratorPlayback = sound.get_playback()
	
	var duration: float = 0.1
	var samples: int = int(sound.mix_rate * duration)
	
	for i in samples:
		var t: float = float(i) / float(samples)
		var freq: float = lerp(800.0, 200.0, t)
		var sample: float = sin(t * freq * TAU) * (1.0 - t) * 0.5
		playback.push_frame(Vector2(sample, sample))
	
	return sound

func _generate_explosion_sound() -> AudioStream:
	var sound: AudioStreamGenerator = AudioStreamGenerator.new()
	sound.mix_rate = 22050.0
	var playback: AudioStreamGeneratorPlayback = sound.get_playback()
	
	var duration: float = 0.5
	var samples: int = int(sound.mix_rate * duration)
	
	for i in samples:
		var t: float = float(i) / float(samples)
		var noise: float = randf_range(-1.0, 1.0)
		var envelope: float = (1.0 - t) * (1.0 - t)
		var freq: float = lerp(100.0, 30.0, t)
		var sample: float = (noise * 0.7 + sin(t * freq * TAU) * 0.3) * envelope * 0.8
		playback.push_frame(Vector2(sample, sample))
	
	return sound

func _generate_shield_hit_sound() -> AudioStream:
	var sound: AudioStreamGenerator = AudioStreamGenerator.new()
	sound.mix_rate = 22050.0
	var playback: AudioStreamGeneratorPlayback = sound.get_playback()
	
	var duration: float = 0.15
	var samples: int = int(sound.mix_rate * duration)
	
	for i in samples:
		var t: float = float(i) / float(samples)
		var freq: float = lerp(1200.0, 800.0, t)
		var sample: float = sin(t * freq * TAU) * (1.0 - t * t) * 0.4
		playback.push_frame(Vector2(sample, sample))
	
	return sound

func _generate_hull_hit_sound() -> AudioStream:
	var sound: AudioStreamGenerator = AudioStreamGenerator.new()
	sound.mix_rate = 22050.0
	var playback: AudioStreamGeneratorPlayback = sound.get_playback()
	
	var duration: float = 0.2
	var samples: int = int(sound.mix_rate * duration)
	
	for i in samples:
		var t: float = float(i) / float(samples)
		var noise: float = randf_range(-1.0, 1.0)
		var envelope: float = (1.0 - t)
		var sample: float = noise * envelope * 0.6
		playback.push_frame(Vector2(sample, sample))
	
	return sound

func _generate_upgrade_sound() -> AudioStream:
	var sound: AudioStreamGenerator = AudioStreamGenerator.new()
	sound.mix_rate = 22050.0
	var playback: AudioStreamGeneratorPlayback = sound.get_playback()
	
	var duration: float = 0.3
	var samples: int = int(sound.mix_rate * duration)
	
	for i in samples:
		var t: float = float(i) / float(samples)
		var freq: float = lerp(400.0, 800.0, t)
		var sample: float = sin(t * freq * TAU) * (1.0 - abs(t - 0.5) * 2.0) * 0.5
		playback.push_frame(Vector2(sample, sample))
	
	return sound

func play_fire() -> void:
	fire_player.stream = sfx_fire
	fire_player.play()

func play_explosion() -> void:
	explosion_player.stream = sfx_explosion
	explosion_player.play()

func play_shield_hit() -> void:
	shield_player.stream = sfx_shield_hit
	shield_player.play()

func play_hull_hit() -> void:
	hull_player.stream = sfx_hull_hit
	hull_player.play()

func play_upgrade() -> void:
	upgrade_player.stream = sfx_upgrade
	upgrade_player.play()

func set_master_volume(volume: float) -> void:
	master_volume = clampf(volume, 0.0, 1.0)
	_update_volumes()

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clampf(volume, 0.0, 1.0)
	_update_volumes()

func _update_volumes() -> void:
	var db: float = linear_to_db(master_volume * sfx_volume)
	fire_player.volume_db = db
	explosion_player.volume_db = db
	shield_player.volume_db = db
	hull_player.volume_db = db
	upgrade_player.volume_db = db
