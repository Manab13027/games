extends Node3D

enum ArenaTheme { NEON_CYBER, SPACE_STATION, REACTOR_CORE }

@onready var _env: WorldEnvironment = $Environment
@onready var _camera: Camera3D = $Camera

var _shake_strength: float = 0.0
@export var shake_decay: float = 5.0
var _camera_origin: Vector3 = Vector3.ZERO

func _ready() -> void:
	_camera_origin = _camera.position

func _process(delta: float) -> void:
	if _shake_strength > 0.0:
		_shake_strength = maxf(_shake_strength - shake_decay * delta, 0.0)
		_camera.position = _camera_origin + Vector3(
			randf_range(-_shake_strength, _shake_strength),
			randf_range(-_shake_strength, _shake_strength),
			0.0
		)
	else:
		_camera.position = _camera_origin

func update_camera_fov(ball_speed: float, max_speed: float) -> void:
	if max_speed <= 0.0:
		return
	_camera.fov = lerpf(70.0, 90.0, clampf(ball_speed / max_speed, 0.0, 1.0))

func shake(strength: float) -> void:
	if strength <= 0.0:
		return
	_shake_strength = maxf(_shake_strength, strength)

func apply_theme(theme: ArenaTheme) -> void:
	match theme:
		ArenaTheme.NEON_CYBER:
			_env.environment.ambient_light_color = Color(0.1, 0.1, 0.3)
			_env.environment.glow_intensity = 0.8
		ArenaTheme.SPACE_STATION:
			_env.environment.ambient_light_color = Color(0.05, 0.05, 0.15)
			_env.environment.glow_intensity = 0.6
		ArenaTheme.REACTOR_CORE:
			_env.environment.ambient_light_color = Color(0.3, 0.1, 0.0)
			_env.environment.glow_intensity = 1.2
		_:
			push_warning("Arena.apply_theme: unhandled theme %d" % theme)

func get_theme_from_string(theme_str: String) -> ArenaTheme:
	match theme_str:
		"space_station": return ArenaTheme.SPACE_STATION
		"reactor_core": return ArenaTheme.REACTOR_CORE
		_: return ArenaTheme.NEON_CYBER
